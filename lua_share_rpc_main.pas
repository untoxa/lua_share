{$include lua_share_defs.pas}

unit lua_share_rpc_main;

interface

uses  windows, sysutils, math,
      LuaLib, LuaHelpers,
      lua_buffers, mmf_ipc;

const transmission_buffer_size = 512 * 1024; // 512K
      max_transmission_size    = transmission_buffer_size - sizeof(longint);

const global_mutex_name  = '{F58C5448-FB40-4808-9128-D0BC99705E1E}';

const package_name       = 'lua_share_rpc';

const lua_supported_libs : array[0..1] of pAnsiChar = ('Lua5.1.dll', 'qlua.dll');

type  tLuaRPCServer      = class;

      tServer            = class(tIPCServer)
      private
        fOwner           : tLuaRPCServer;
      public
        constructor create(AOwner: tLuaRPCServer; adatalen: longint);
        function    processdata(input: pAnsiChar; inputsize: longint; output: pAnsiChar; var outputsize: longint; aref: pointer): boolean; override;
      end;

      tLuaRPCServer      = class(TLuaClass)
      private
        fServer          : tServer;
        fTerminated      : boolean;
        fCodec           : tLuaCodec;
        fLastError       : ansistring;
      protected
        function    processdata(input: pAnsiChar; inputsize: longint; output: pAnsiChar; var outputsize: longint; aref: pointer): boolean;
      public
        constructor create(hLib: HMODULE);
        destructor  destroy; override;

        procedure   terminate;

        function    ProcessRPC(AContext: TLuaContext): integer;
      end;

procedure terminate_rpc_server; cdecl;
function  initialize_share_rpc(ALuaInstance: Lua_State): integer;

implementation

const lua_share_rpc_instance : tLuaRPCServer = nil;
      GlobalMutex            : THandle       = 0;

{ tLuaRPCServer }

constructor tLuaRPCServer.create(hLib: HMODULE);
begin
  inherited create(hLib);
  fServer:= nil;
  fTerminated:= false;
  fCodec:= tLuaCodec.create;
  setlength(fLastError, 0);
end;

destructor tLuaRPCServer.destroy;
begin
  if assigned(fServer) then freeandnil(fServer);
  if assigned(fCodec) then freeandnil(fCodec);
  inherited destroy;
end;

procedure tLuaRPCServer.terminate;
begin fterminated:= true; end;

function tLuaRPCServer.ProcessRPC(AContext: TLuaContext): integer;
var res : boolean;
begin
  with AContext do
    if not fterminated then begin
      if not assigned(fServer) then fServer:= tServer.create(Self, Stack[2].AsInteger(transmission_buffer_size));
      if assigned(fServer) then with fServer do begin
        res:= opened or open; // try open if not opened
        if res then begin
          res:= process(Stack[1].AsInteger(100), AContext);
          if res then result:= PushArgs([true])
                 else result:= PushArgs([false, fLastError]);
        end else begin
          result:= PushArgs([false, 'Unable to open IPC server']);
        end;
      end else result:= PushArgs([false, 'Internal error']);
    end else result:= PushArgs([false, 'IPC Server terminated']);
end;

function tLuaRPCServer.processdata(input: pAnsiChar; inputsize: longint; output: pAnsiChar; var outputsize: longint; aref: pointer): boolean;
var buffer        : array[0..16384] of ansichar;
    fname         : ansistring;
    argcount      : longint;
    luastate      : TLuaState;
    ssize, len, i : longint;
    tmpd          : double;
begin
  result:= assigned(aref) and assigned(fcodec);
  if result then begin
    luastate:= TLuaContext(aref).CurrentState;
    fcodec.startcodec(input, inputsize);
    result:= (fcodec.read(@buffer, sizeof(buffer), len) = LUA_TSTRING);
    if result then begin
      setstring(fname, buffer, len);
      ssize:= lua_gettop(luastate);            // saving stack size before call

      lua_getglobal(luastate, pAnsiChar(fname));
      result:= (lua_type(luastate, -1) = LUA_TFUNCTION);
      if result then begin
        if (fcodec.read(@buffer, sizeof(buffer), len) = LUA_TNUMBER) then argcount:= round(pdouble(@buffer)^)
                                                                     else argcount:= 0;
        for i:= 0 to argcount - 1 do
          buf2stack(luastate, fcodec, @buffer, sizeof(buffer));

        result:= (lua_pcall(luastate, argcount, LUA_MULTRET, 0) = 0);
        if result then begin
          len:= lua_gettop(luastate) - ssize;  // len contains number of results returned
          fcodec.startcodec(output, fServer.maxdatalen);
          tmpd:= len; fcodec.write(LUA_TNUMBER, @tmpd, sizeof(tmpd));
          for i:= len downto 1 do
            stack2buf(luastate, - i, fcodec);
          outputsize:= fcodec.stopcodec;
          lua_pop(luastate, len);              // pop results from stack
        end else begin
          len:= 0;
          SetString(fLastError, lua_tolstring(luastate, -1, cardinal(len)), len);
          lua_pop(luastate, 1);
        end;
      end else begin
        fLastError:= format('%s is not a function!', [fname]);
        lua_pop(luastate, 1);
      end;
    end else fLastError:= 'IPC buffer error!';
  end else fLastError:= 'Internal error!';
  if not result then outputsize:= 0;
end;

{ tServer }

constructor tServer.create(AOwner: tLuaRPCServer; adatalen: longint);
begin
  inherited create(adatalen);
  fOwner:= AOwner;
end;

function tServer.processdata(input: pAnsiChar; inputsize: longint; output: pAnsiChar; var outputsize: longint; aref: pointer): boolean;
begin result:= assigned(fOwner) and fOwner.processdata(input, inputsize, output, outputsize, aref); end;

{ main functions }

procedure terminate_rpc_server;
begin if assigned(lua_share_rpc_instance) then lua_share_rpc_instance.terminate; end;

function initialize_lua_library: HMODULE;
var i : integer;
begin
  result:= 0;
  i:= low(lua_supported_libs);
  while (i <= high(lua_supported_libs)) do begin
    result:= GetModuleHandle(lua_supported_libs[i]);
    if (result <> 0) then i:= high(lua_supported_libs) + 1
                     else inc(i);
  end;
end;

function get_module_name(Module: HMODULE): ansistring;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;

function initialize_share_rpc(ALuaInstance: Lua_State): integer;
var hLib : HMODULE;
begin
  result:= 0;
  if not assigned(lua_share_rpc_instance) then begin
    GlobalMutex:= CreateMutex(nil, true, '{F58C5448-FB40-4808-9128-D0BC99705E1E}');
    if (GetLastError = 0) then begin
      hLib:= initialize_lua_library;
      if (hLib <> 0) then begin
        lua_share_rpc_instance:= tLuaRPCServer.Create(hLib);
        with lua_share_rpc_instance do begin
          StartRegister;
          RegisterMethod('ProcessRPC', ProcessRPC);
          result:= min(StopRegister(ALuaInstance, package_name, true), 1);
        end;
      end else messagebox(0, pAnsiChar(format('ERROR: failed to find LUA library: %s', [lua_supported_libs[0]])), 'Error', 0);
    end else messagebox(0, 'ERROR: Server already running!', 'Error', 0);
  end;
end;

initialization

finalization
  if assigned(lua_share_rpc_instance) then freeandnil(lua_share_rpc_instance);
  if (GlobalMutex <> 0) then CloseHandle(GlobalMutex);
  GlobalMutex:= 0;

end.
