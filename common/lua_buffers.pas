unit lua_buffers;

interface

uses  windows, math, 
      LuaLib53;

const LUA_TINTEGER  =  LUA_NUMTAGS + 1;

type  tLuaCodec     = class(tObject)
      private
        fbuffer     : pAnsiChar;
        fbufstart   : pAnsiChar;
        fbufend     : pAnsiChar;
      protected
        function  check_size(asize: longint): boolean;
      public
        procedure startcodec(abuffer: pAnsiChar; amaxlen: longint);
        function  peek: longint;
        function  read(avalue: pAnsiChar; amaxlen: longint; var alen: longint): longint;
        function  readint(adef: longint): longint;
        function  write(atype: longint; avalue: pAnsiChar; alen: longint): boolean;
        function  writenumber(const avalue: double): boolean;
        function  writeinteger(const avalue: int64): boolean;
        function  writestring(const avalue: ansistring): boolean;
        function  writeboolean(avalue: boolean): boolean;
        function  stopcodec: longint;
      end;

procedure buf2stack(astate: Lua_State; acodec: tLuaCodec; abuf: pAnsiChar; abufsize: longint);
procedure stack2buf(astate: Lua_State; aindex: longint; acodec: tLuaCodec);

implementation

{ tLuaCodec }

function  tLuaCodec.check_size(asize: longint): boolean;
begin result:= assigned(fbuffer) and (fbuffer + asize <= fbufend); end;

procedure tLuaCodec.startcodec(abuffer: pAnsiChar; amaxlen: longint);
begin fbuffer:= abuffer; fbufstart:= fbuffer; fbufend:= abuffer + amaxlen; end;

function tLuaCodec.peek: longint;
begin
  if check_size(sizeof(longint)) then result:= plongint(fbuffer)^
                                 else result:= LUA_TNONE;
end;

function tLuaCodec.read(avalue: pAnsiChar; amaxlen: longint; var alen: longint): longint;
var slen : longint;
begin
  alen:= 0;
  if check_size(sizeof(longint)) then begin
    result:= plongint(fbuffer)^;
    inc(fbuffer, sizeof(longint));
    case result of
      LUA_TBOOLEAN          : if check_size(sizeof(longint)) and (amaxlen >= sizeof(longint)) then begin
                                plongint(avalue)^:= plongint(fbuffer)^;
                                alen:= sizeof(longint);
                                inc(fbuffer, alen);
                              end else result:= LUA_TNONE;
      LUA_TNUMBER           : if check_size(sizeof(double)) and (amaxlen >= sizeof(double)) then begin
                                pdouble(avalue)^:= pdouble(fbuffer)^;
                                alen:= sizeof(double);
                                inc(fbuffer, alen);
                              end else result:= LUA_TNONE;
      LUA_TSTRING           : if check_size(sizeof(longint)) then begin
                                slen:= plongint(fbuffer)^;
                                inc(fbuffer, sizeof(longint));
                                if check_size(slen) then begin
                                  alen:= min(slen, amaxlen - 1);
                                  system.move(fbuffer^, avalue^, alen);
                                  avalue[alen]:= #0;
                                end else begin
                                  alen:= 0;
                                  result:= LUA_TNIL;
                                end;
                                inc(fbuffer, slen);
                              end else result:= LUA_TNONE;
      LUA_TINTEGER          : if check_size(sizeof(int64)) and (amaxlen >= sizeof(int64)) then begin
                                pint64(avalue)^:= pint64(fbuffer)^;
                                alen:= sizeof(int64);
                                inc(fbuffer, alen);
                              end else result:= LUA_TNONE;
      LUA_TTABLE, LUA_TNONE : ;
      else                    result:= LUA_TNIL;
    end;
  end else result:= LUA_TNONE;
end;

function tLuaCodec.readint(adef: longint): longint;
var tmpd : double;
    tmpi : int64;
    len  : longint;
begin
  if (peek = LUA_TNUMBER) then begin
    read(@tmpd, sizeof(tmpd), len);
    result:= round(tmpd);
  end else
  if (peek = LUA_TINTEGER) then begin
    read(@tmpi, sizeof(tmpi), len);
    result:= tmpi;
  end else result:= adef;
end;

function tLuaCodec.write(atype: longint; avalue: pAnsiChar; alen: longint): boolean;
begin
  result:= check_size(2 * sizeof(longint) + alen);
  if result then begin
    plongint(fbuffer)^:= atype;
    inc(fbuffer, sizeof(longint));
    case atype of
      LUA_TBOOLEAN  : begin
                        plongint(fbuffer)^:= plongint(avalue)^;
                        inc(fbuffer, sizeof(longint));
                      end;
      LUA_TNUMBER   : begin
                        pdouble(fbuffer)^:= pdouble(avalue)^;
                        inc(fbuffer, sizeof(double));
                      end;
      LUA_TSTRING   : begin
                        plongint(fbuffer)^:= alen;
                        inc(fbuffer, sizeof(longint));
                        system.move(avalue^, fbuffer^, alen);
                        inc(fbuffer, alen);
                      end;
      LUA_TINTEGER  : begin
                        pint64(fbuffer)^:= pint64(avalue)^;
                        inc(fbuffer, sizeof(int64));
                      end;
    end;
  end;
end;

function tLuaCodec.writeboolean(avalue: boolean): boolean;
begin result:= write(LUA_TBOOLEAN, @avalue, sizeof(avalue)); end;

function tLuaCodec.writenumber(const avalue: double): boolean;
begin result:= write(LUA_TNUMBER, @avalue, sizeof(avalue)); end;

function tLuaCodec.writeinteger(const avalue: int64): boolean;
begin result:= write(LUA_TINTEGER, @avalue, sizeof(avalue)); end;

function tLuaCodec.writestring(const avalue: ansistring): boolean;
begin result:= write(LUA_TSTRING, pAnsiChar(avalue), length(avalue)); end;

function tLuaCodec.stopcodec: longint;
begin result:= longint(fbuffer - fbufstart); end;

{ misc functions }

procedure buf2stack(astate: Lua_State; acodec: tLuaCodec; abuf: pAnsiChar; abufsize: longint);
var len: longint;
begin
  case acodec.read(abuf, abufsize, len) of
    LUA_TBOOLEAN : lua_pushboolean(astate, longbool(plongint(abuf)^));
    LUA_TNUMBER  : lua_pushnumber(astate, pdouble(abuf)^);
    LUA_TSTRING  : lua_pushstring(astate, abuf);
    LUA_TTABLE   : begin
                     lua_newtable(astate);
                     while (acodec.peek <> LUA_TNONE) do begin
                       buf2stack(astate, acodec, abuf, abufsize);
                       buf2stack(astate, acodec, abuf, abufsize);
                       lua_settable(astate, -3);
                     end;
                     acodec.read(abuf, abufsize, len); // read table terminator
                   end;
    LUA_TINTEGER : lua_pushinteger(astate, pint64(abuf)^);
    else           lua_pushnil(astate);
  end;
end;

procedure stack2buf(astate: Lua_State; aindex: longint; acodec: tLuaCodec);
var tmpb : longbool;
    tmpd : double;
    tmpi : int64;
    tmps : pAnsiChar;
    len  : size_t;
begin
  case lua_type(astate, aindex) of
    LUA_TBOOLEAN : begin
                     tmpb:= lua_toboolean(astate, aindex);
                     acodec.write(LUA_TBOOLEAN, @tmpb, sizeof(tmpb));
                   end;
    LUA_TNUMBER  : if lua_isinteger(astate, aindex) then begin
                     tmpd:= lua_tonumber(astate, aindex);
                     acodec.write(LUA_TNUMBER, @tmpd, sizeof(tmpd));
                   end else begin
                     tmpi:= lua_tointeger(astate, aindex);
                     acodec.write(LUA_TINTEGER, @tmpi, sizeof(tmpi));
                   end;
    LUA_TSTRING  : begin
                     tmps:= lua_tolstring(astate, aindex, len);
                     acodec.write(LUA_TSTRING, tmps, len);
                   end;
    LUA_TTABLE   : begin
                     acodec.write(LUA_TTABLE, nil, 0);
                     lua_pushvalue(astate, aindex);
                     lua_pushnil(astate);
                     while (lua_next(astate, -2) <> 0) do begin
                       stack2buf(astate, -2, acodec);
                       stack2buf(astate, -1, acodec);
                       lua_pop(astate, 1);
                     end;
                     lua_pop(astate, 1);
                     acodec.write(LUA_TNONE, nil, 0);
                   end;
    else           acodec.write(LUA_TNIL, nil, 0);
  end;
end;

end.