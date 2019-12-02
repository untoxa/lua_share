{$apptype console}

program lua_share_server;

uses  windows, sysutils,
      LuaLib, LuaHelpers;

const platform_string          = {$ifdef CPUX64} 'x64' {$else} 'x86' {$endif};

const hLib          : HMODULE      = 0;
      luastate      : TLuaState    = nil;

{$R *.res}

{ main }

function get_module_name(Module: HMODULE): ansistring;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;

function CtrlHandler(CtrlType: Longint): bool; stdcall;
type  tTerminateProc = procedure; cdecl;
const reasons        : array[0..6] of pAnsiChar = ('ctrl-C', 'ctrl-break', 'close', nil, nil, 'logoff', 'shutdown');
var   hLib           : HMODULE;
      terminate_proc : tTerminateProc;
begin
  result:= false;
  if ((CtrlType >= low(reasons)) and (CtrlType <= high(reasons))) then
    writeln(format('shutting down... reason: %s code: %d', [reasons[CtrlType], CtrlType]));
  hLib:= GetModuleHandle('lua_share_rpc.dll');
  if (hLib <> 0) then begin
    terminate_proc := GetProcAddress(hLib, 'terminate_rpc_server');
    if assigned(terminate_proc) then terminate_proc();
    result:= true;
  end;
end;

var   fname, err : ansistring;
begin
  SetConsoleCtrlHandler(@CtrlHandler, true);
  writeln('IPC ', platform_string, ' server started');

  fname:= expandfilename(changefileext(get_module_name(HInstance), '.lua'));
  if fileexists(fname) then begin
    hLib:= LoadLuaLib('lua5.1.dll');
    if (hLib <> 0) then begin
      luastate:= luaL_newstate;
      luaL_openlibs(luastate);
      try
        with TLuaContext.create(luastate) do try
          if not ExecuteFileSafe(fname, 0, err) then writeln('error: script loading failed: ', err);
        finally free; end;
      finally lua_close(luastate) end;
      writeln('done!');
    end else writeln('error: unable to load lua5.1.dll');
  end else writeln('error: filename "', fname, '" not found!');
end.
