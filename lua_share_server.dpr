{$apptype console}

program lua_share_server;

uses  windows, classes, sysutils,
      LuaLib, LuaHelpers;

const platform_string              = {$ifdef CPUX64} 'x64' {$else} 'x86' {$endif};

type  tRunnerThread = class;

      tRunnerList   = class(tThreadList)
        function    addrunner(arunner: tRunnerThread): tRunnerThread;
        function    removerunner(arunner: tRunnerThread): tRunnerThread;
        function    getfirstrunner: tRunnerThread;
      end;

      tRunnerApi    = class(TLuaClass)
      private
        fOwner      : tRunnerThread;
        flualib     : HMODULE;
      public
        constructor create(hLib: HMODULE; AOwner: tRunnerThread);
        function    Terminated(AContext: TLuaContext): integer;
        function    RunThread(AContext: TLuaContext): integer;
      end;

      tRunnerThread = class(tThread)
      private
        ffilename   : ansistring;
        fluastate   : TLuaState;
        flualib     : HMODULE;
      public
        constructor create(alib: HMODULE; const afilename: ansistring);
        procedure   execute; override;
      end;

const runner_list   : tRunnerList  = nil;

{$R *.res}

{ tRunnerList }

function tRunnerList.addrunner(arunner: tRunnerThread): tRunnerThread;
begin
  with locklist do try
    result:= arunner;
    add(result);
  finally unlocklist; end;
end;

function tRunnerList.removerunner(arunner: tRunnerThread): tRunnerThread;
begin
  with locklist do try
    result:= extract(arunner);
  finally unlocklist; end;
end;

function tRunnerList.getfirstrunner: tRunnerThread;
begin
  with locklist do try
    if (count > 0) then result:= tRunnerThread(items[0])
                   else result:= nil;
  finally unlocklist; end;
end;

{ tRunnerApi }

constructor tRunnerApi.create(hLib: HMODULE; AOwner: tRunnerThread);
begin
  inherited create(hLib, '');
  flualib:= hLib;
  fOwner:= AOwner;
end;

function tRunnerApi.RunThread(AContext: TLuaContext): integer;
begin
  runner_list.addrunner(tRunnerThread.create(flualib, AContext.Stack[1].AsString));
  result:= 0;
end;

function tRunnerApi.Terminated(AContext: TLuaContext): integer;
begin result:= AContext.PushArgs([not (assigned(fOwner) and not fOwner.Terminated)]); end;

{ tRunnerThread }

constructor tRunnerThread.create(alib: HMODULE; const afilename: ansistring);
begin
  flualib:= alib;
  ffilename:= afilename;
  inherited create(false);
end;

procedure tRunnerThread.execute;
var api : tRunnerApi;
    err : ansistring;
begin
  freeonterminate:= false;
  fluastate:= luaL_newstate;
  luaL_openlibs(fluastate);
  try
    api:= tRunnerApi.create(flualib, Self);
    try
      with api do begin
        RegisterGlobalMethod(fluastate, 'Terminated', Terminated);
        RegisterGlobalMethod(fluastate, 'RunThread', RunThread);
      end;
      with TLuaContext.create(fluastate) do try
        if not ExecuteFileSafe(ffilename, 0, err) then writeln('error: script loading failed: ', err);
      finally free; end;
    finally freeandnil(api); end;  
  finally lua_close(fluastate) end;
end;

{ main }

function get_module_name(Module: HMODULE): ansistring;
var ModName: array[0..MAX_PATH] of char;
begin SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName))); end;

function CtrlHandler(CtrlType: Longint): bool; stdcall;
type  tTerminateProc = procedure; cdecl;
const reasons        : array[0..6] of pAnsiChar = ('ctrl-C', 'ctrl-break', 'close', nil, nil, 'logoff', 'shutdown');
var   hLib           : HMODULE;
      terminate_proc : tTerminateProc;
      trd            : tRunnerThread;
      i              : longint;
begin
  result:= true;
  if ((CtrlType >= low(reasons)) and (CtrlType <= high(reasons))) then
    writeln(format('shutting down... reason: %s code: %d', [reasons[CtrlType], CtrlType]));
  // signal rpc library to terminate
  hLib:= GetModuleHandle('lua_share_rpc.dll');
  if (hLib <> 0) then begin
    terminate_proc := GetProcAddress(hLib, 'terminate_rpc_server');
    if assigned(terminate_proc) then terminate_proc();
    result:= true;
  end;
  // signal threads to terminate
  if assigned(runner_list) then
    with runner_list.locklist do try
      for i:= 0 to count - 1 do begin
        trd:= tRunnerThread(items[i]);
        if assigned(trd) then trd.terminate;
      end;
    finally runner_list.unlocklist; end;
  if (CtrlType = 1) then halt; // force kill with ctrl-break
end;

const hLib            : HMODULE         = 0;
      main_terminated : boolean         = false;
var   fname           : ansistring;
      trd             : tRunnerThread;

begin
  IsMultiThread:= true;
  SetConsoleCtrlHandler(@CtrlHandler, true);
  writeln('IPC ', platform_string, ' server started');
  fname:= expandfilename(changefileext(get_module_name(HInstance), '.lua'));
  if fileexists(fname) then begin
    hLib:= LoadLuaLib('lua5.1.dll');
    if (hLib <> 0) then begin
      runner_list:= tRunnerList.create;
      try
        runner_list.addrunner(tRunnerThread.create(hLib, fname));
        repeat
          trd:= runner_list.getfirstrunner;
          if assigned(trd) then try
            if main_terminated then trd.terminate;
            trd.waitfor;
            runner_list.removerunner(trd);
          finally trd.free; end;
          main_terminated:= true;
        until not assigned(trd);
      finally freeandnil(runner_list); end;
      writeln('done!');
    end else writeln('error: unable to load lua5.1.dll');
  end else writeln('error: filename "', fname, '" not found!');
end.
