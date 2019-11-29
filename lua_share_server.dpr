{$apptype console}

uses  windows, sysutils,
      LuaLib, LuaHelpers,
      lua_buffers, mmf_ipc;

const transmission_buffer_size = 512 * 1024; // 512K
      max_transmission_size    = transmission_buffer_size - sizeof(longint);

type  tLuaCommon    = class;

      tServer       = class(tIPCServer)
      private
        fOwner      : tLuaCommon;
      protected
        constructor create(AOwner: tLuaCommon; adatalen: longint);
        function    processdata(input: pAnsiChar; inputsize: longint; output: pAnsiChar; var outputsize: longint): boolean; override;
      end;

      tLuaCommon    = class(TLuaClass)
      private
        fContext    : TLuaContext;
        fServer     : tServer;
        fTerminated : boolean;
        fCodec      : tLuaCodec;
      protected
        procedure   writeoutput(const astr: ansistring); virtual;
        function    processdata(input: pAnsiChar; inputsize: longint; output: pAnsiChar; var outputsize: longint): boolean;
      public
        constructor create(hLib: HMODULE; AContext: TLuaContext);
        destructor  destroy; override;

        procedure   terminate;

        function    print(AContext: TLuaContext): integer;
        function    ProcessIPC(AContext: TLuaContext): integer;
      end;

const hLib          : HMODULE      = 0;
      luastate      : TLuaState    = nil;
      luacommon     : tLuaCommon   = nil;
      luacontext    : tLuaContext  = nil;

{ tLuaCommon }

constructor tLuaCommon.create(hLib: HMODULE; AContext: TLuaContext);
begin
  inherited create(hLib);
  fContext:= AContext;
  fServer:= nil;
  fTerminated:= false;
  fCodec:= tLuaCodec.create;
end;

destructor tLuaCommon.destroy;
begin
  if assigned(fServer) then freeandnil(fServer);
  if assigned(fCodec) then freeandnil(fCodec);
  inherited destroy;
end;

procedure tLuaCommon.terminate;
begin fterminated:= true; end;

procedure tLuaCommon.writeoutput(const astr: ansistring);
begin writeln(astr); end;

function tLuaCommon.print(AContext: TLuaContext): integer;
begin
  writeoutput(AContext.Stack[1].AsString);
  result:= 0;
end;

function tLuaCommon.ProcessIPC(AContext: TLuaContext): integer;
var res : boolean;
begin
  with AContext do
    if not fterminated then begin
      if not assigned(fServer) then fServer:= tServer.create(Self, Stack[2].AsInteger(transmission_buffer_size));
      if assigned(fServer) then with fServer do begin
        res:= opened or open; // try open if not opened
        if res then begin
          res:= process(Stack[1].AsInteger(100));
          if res then result:= PushArgs([res])
                 else result:= PushArgs([res, 'ProcessIPC error'])
        end else begin
          result:= PushArgs([false, 'Unable to open IPC server']);
        end;
      end else result:= PushArgs([false, 'Internal error']);
    end else result:= PushArgs([false, 'IPC Server terminated']);
end;

function tLuaCommon.processdata(input: pAnsiChar; inputsize: longint; output: pAnsiChar; var outputsize: longint): boolean;
var buffer   : array[0..16384] of ansichar;
    fname    : ansistring;
    argcount : longint;
    luastate : TLuaState;
    len, i   : longint;
    tmpd     : double;
begin
  result:= assigned(fContext) and assigned(fcodec);
  if result then begin
    luastate:= fContext.CurrentState;
    fcodec.startcodec(input, inputsize);
    if (fcodec.read(@buffer, sizeof(buffer), len) = LUA_TSTRING) then begin
      setstring(fname, buffer, len);
      lua_getglobal(luastate, pAnsiChar(fname));
      if (lua_type(luastate, -1) = LUA_TFUNCTION) then begin
        if (fcodec.read(@buffer, sizeof(buffer), len) = LUA_TNUMBER) then argcount:= round(pdouble(@buffer)^)
                                                                     else argcount:= 0;     
        for i:= 0 to argcount - 1 do
          buf2stack(luastate, fcodec, @buffer, sizeof(buffer));
          
        result:= (lua_pcall(luastate, argcount, 1, 0) = 0);
        if result then begin
          tmpd:= 1;
          fcodec.startcodec(output, fServer.maxdatalen);
          fcodec.write(LUA_TNUMBER, @tmpd, sizeof(tmpd));
          stack2buf(luastate, -1, fcodec);
          outputsize:= fcodec.stopcodec;
          lua_pop(luastate, 1);
        end else begin
          len:= 0;
          SetString(fname, lua_tolstring(luastate, -1, cardinal(len)), len);
          writeoutput(format('lua error: %s', [fname]));
          lua_pop(luastate, 1);
        end;
      end else begin
        lua_pop(luastate, 1);
        result:= false;
      end;
    end else result:= false;
  end;
  if not result then outputsize:= 0;
end;

{ tServer }

constructor tServer.create(AOwner: tLuaCommon; adatalen: longint);
begin
  inherited create(adatalen);
  fOwner:= AOwner;
end;

function tServer.processdata(input: pAnsiChar; inputsize: longint; output: pAnsiChar; var outputsize: longint): boolean;
begin result:= assigned(fOwner) and fOwner.processdata(input, inputsize, output, outputsize); end;

{ main }

function get_module_name(Module: HMODULE): ansistring;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;

function CtrlHandler(CtrlType: Longint): bool; stdcall;
const reasons : array[0..6] of pAnsiChar = ('ctrl-C', 'ctrl-break', 'close', nil, nil, 'logoff', 'shutdown');
begin
  result:= true;
  if ((CtrlType >= low(reasons)) and (CtrlType <= high(reasons))) then
    writeln(format('shutting down... reason: %s code: %d', [reasons[CtrlType], CtrlType]));
  if assigned(luacommon) then luacommon.terminate;
end;

var fname, err : ansistring;
    hMutex     : THandle;
begin
  SetConsoleCtrlHandler(@CtrlHandler, true);
  writeln('ipc server started');

  hMutex:= CreateMutex(nil, true, '{F58C5448-FB40-4808-9128-D0BC99705E1E}');
  if (GetLastError = 0) then begin
    fname:= expandfilename(changefileext(get_module_name(HInstance), '.lua'));
    if fileexists(fname) then begin
      hLib:= LoadLuaLib('lua5.1.dll');
      if (hLib <> 0) then begin
        luastate:= luaL_newstate;
        luaL_openlibs(luastate);
        try
          luacontext:= TLuaContext.create(luastate);
          luacommon:= tLuaCommon.Create(hLib, luacontext);
          try
            luacommon.RegisterGlobalMethod(luastate, 'print', luacommon.print);
            luacommon.RegisterGlobalMethod(luastate, 'ProcessIPC', luacommon.ProcessIPC);
            if not luacontext.ExecuteFileSafe(fname, 0, err) then writeln('error: script loading failed: ', err);
          finally
            freeandnil(luacommon);
            freeandnil(luacontext);
          end;
        finally lua_close(luastate) end;
        writeln('done!');
      end else writeln('error: unable to load lua5.1.dll');
    end else writeln('error: filename "', fname, '" not found!');
    CloseHandle(hMutex);
  end else writeln('error: only one instance allowed!');
end.
