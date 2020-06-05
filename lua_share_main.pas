{$include lua_share_defs.pas}

unit lua_share_main;

interface

uses  windows, classes, sysutils, math,
      LuaLib53, LuaHelpers,
      lua_buffers, mmf_ipc;

const transmission_buffer_size = 512 * 1024; // 512K
      max_transmission_size    = transmission_buffer_size - sizeof(longint);
      max_single_value_size    = 64 * 1024;  // 64K

const max_RPC_timeout          = 10000;      // 10s

const package_name       = 'share';
      datatable_name     = '__default_namespace';
      metatable_name     = '__default_namespace_metatable';
      namespace_item     = '__namespace';
      data_item          = '__data';
      bootstrap_name     = 'lua_share_boot.lua';
      boot_script_path   = '__script_path';
      def_msgbox_title   = 'Lua_share';
      msgbox_err_title   = 'Lua_share ERROR';

const lua_supported_libs : array[0..0] of pAnsiChar = ('Lua53.dll');

type  tLuaShare          = class(TLuaClass)
      private
        fIPCClient       : tIPCClient;
        fCodec           : tLuaCodec;
        fDataBuffer      : pAnsiChar;

        function    IPCReady: boolean;

        procedure   __deepcopy(sour, dest: TLuaState);
        procedure   __deepcopyvalue(sour, dest: TLuaState; avalueindex: integer);
      protected
        function    RPCCallNS(AContext: TLuaContext; const afuncname, ansname: ansistring; const aargs: array of const; atimeout: integer): integer;
      public
        constructor create(hLib: HMODULE);
        destructor  destroy; override;

        function    __index(AContext: TLuaContext): integer;
        function    __newindex(AContext: TLuaContext): integer;
        function    __IPC_index(AContext: TLuaContext): integer;
        function    __IPC_newindex(AContext: TLuaContext): integer;
        function    __IPC_call(AContext: TLuaContext): integer;

        function    DeepCopy(AContext: TLuaContext): integer;
        function    IPCDeepCopy(AContext: TLuaContext): integer;

        function    GetNameSpace(AContext: TLuaContext): integer;
        function    GetIPCNameSpace(AContext: TLuaContext): integer;

        function    ShowMessageBox(AContext: TLuaContext): integer;

        function    selfregister(ALuaState: TLuaState; ANameSpace: pAnsiChar; adeepcpy, aidx, anewidx, acall: tLuaFunction): integer;
      end;

function  initialize_share(ALuaInstance: TLuaState): integer;

implementation

var   lua_lock           : TRTLCriticalSection;

const lua_storage_state  : TLuaState = nil;
      lua_share_instance : tLuaShare = nil;

{ tLuaShare }

constructor tLuaShare.create(hLib: HMODULE);
begin
  inherited create(hLib);
  fIPCClient:= nil;
  fCodec:= nil;
end;

destructor tLuaShare.destroy;
begin
  if assigned(fCodec) then freeandnil(fCodec);
  if assigned(fIPCClient) then freeandnil(fIPCClient);
  if assigned(fDataBuffer) then freemem(fDataBuffer);
  fDataBuffer:= nil;
  inherited destroy;
end;

function tLuaShare.IPCReady: boolean;
begin
  result:= assigned(fIPCClient) and assigned(fCodec);
  if result and not fIPCClient.opened then result:= fIPCClient.open;
end;

procedure tLuaShare.__deepcopy(sour, dest: TLuaState);
var len : size_t;
begin
  case lua_type(sour, -1) of
    LUA_TBOOLEAN : lua_pushboolean(dest, lua_toboolean(sour, -1));
    LUA_TNUMBER  : if lua_isinteger(sour, -1) then lua_pushinteger(dest, lua_tointeger(sour, -1))
                                              else lua_pushnumber(dest, lua_tonumber(sour, -1));
    LUA_TSTRING  : lua_pushstring(dest, lua_tolstring(sour, -1, len));
    LUA_TTABLE   : begin
                     lua_newtable(dest);
                     lua_pushnil(sour);
                     while (lua_next(sour, -2) <> 0) do begin
                       __deepcopyvalue(sour, dest, -2);
                       __deepcopyvalue(sour, dest, -1);
                       lua_settable(dest, -3);
                       lua_pop(sour, 1);
                     end;
                   end;
    else           lua_pushnil(dest);
  end;
end;

procedure tLuaShare.__deepcopyvalue(sour, dest: TLuaState; avalueindex: integer);
begin
  lua_pushvalue(sour, avalueindex);
  __deepcopy(sour, dest);
  lua_pop(sour, 1);
end;

function tLuaShare.__index(AContext: TLuaContext): integer;
var namespace_name : ansistring;
begin
  result:= 0;
  if assigned(lua_storage_state) then try
    EnterCriticalSection(lua_lock);
    try
      with AContext do begin
        namespace_name:= Stack[1].AsTable[namespace_item].AsString(datatable_name);
        lua_getglobal(lua_storage_state, pAnsiChar(namespace_name));
        if (lua_type(lua_storage_state, -1) = LUA_TTABLE) then begin
          __deepcopyvalue(CurrentState, lua_storage_state, 2);
          lua_gettable(lua_storage_state, -2);
          __deepcopy(lua_storage_state, CurrentState);
          lua_pop(lua_storage_state, 2);
        end else begin
          lua_pop(lua_storage_state, 1);
          lua_pushnil(CurrentState);
        end;
        result:= 1;
      end;
    finally LeaveCriticalSection(lua_lock); end;
  except on e: exception do messagebox(0, pAnsiChar(e.message), msgbox_err_title, MB_ICONERROR); end;
end;

function tLuaShare.__newindex(AContext: TLuaContext): integer;
var namespace_name : ansistring;
begin
  if assigned(lua_storage_state) then try
    EnterCriticalSection(lua_lock);
    try
      with AContext do begin
        namespace_name:= Stack[1].AsTable[namespace_item].AsString(datatable_name);
        lua_getglobal(lua_storage_state, pAnsiChar(namespace_name));
        if (lua_type(lua_storage_state, -1) <> LUA_TTABLE) then begin // create table if not exist
          lua_pop(lua_storage_state, 1);
          lua_newtable(lua_storage_state);
          lua_getglobal(lua_storage_state, metatable_name);           // if we have a metatable defined in bootstrap
          if (lua_type(lua_storage_state, -1) = LUA_TTABLE) then begin
            lua_pushstring(lua_storage_state, data_item);             // create a __data container for data
            lua_newtable(lua_storage_state);
            lua_settable(lua_storage_state, -4);
            lua_setmetatable(lua_storage_state, -2);                  // set this metatable
          end else lua_pop(lua_storage_state, 1);
          lua_pushvalue(lua_storage_state, -1);
          lua_setglobal(lua_storage_state, pAnsiChar(namespace_name));
        end;
        __deepcopyvalue(CurrentState, lua_storage_state, 2);
        __deepcopyvalue(CurrentState, lua_storage_state, 3);
        lua_settable(lua_storage_state, -3);
        lua_pop(lua_storage_state, 1);                                // pop table
      end;
    finally LeaveCriticalSection(lua_lock); end;
  except on e: exception do messagebox(0, pAnsiChar(e.message), msgbox_err_title, MB_ICONERROR); end;
  result:= 0;
end;

function tLuaShare.__IPC_index(AContext: TLuaContext): integer;
begin result:= RPCCallNS(AContext, 'GetIPC', AContext.Stack[1].AsTable[namespace_item].AsString(datatable_name), [2], AContext.Stack[3].AsInteger(max_RPC_timeout)); end;

function tLuaShare.__IPC_newindex(AContext: TLuaContext): integer;
begin result:= RPCCallNS(AContext, 'SetIPC', AContext.Stack[1].AsTable[namespace_item].AsString(datatable_name), [2, 3], AContext.Stack[4].AsInteger(max_RPC_timeout)); end;

function tLuaShare.__IPC_call(AContext: TLuaContext): integer;
var function_name  : ansistring;
    received_len   : longint;
    temp_buffer    : array[0..max_single_value_size - 1] of ansichar;
    ssize, i       : longint;
begin
  result:= 0;
  EnterCriticalSection(lua_lock);
  try
    if IPCReady then begin
      ssize:= AContext.StackSize;                                     // __call(self, function_name, ...)
      function_name:= AContext.Stack[2].AsString;
      if (length(function_name) > 0) then begin
        fCodec.startcodec(fDataBuffer, max_transmission_size);
        fCodec.writestring(function_name);
        fCodec.writenumber(max(0, ssize - 2));
        for i:= 3 to ssize do
          stack2buf(AContext.CurrentState, i, fCodec);
        if fIPCClient.send_receive(fDataBuffer, fCodec.stopcodec, fDataBuffer, received_len, max_RPC_timeout) then begin
          fCodec.startcodec(fDataBuffer, received_len);
          result:= fCodec.readint(0);
          for i:= 0 to result - 1 do
            buf2stack(AContext.CurrentState, fCodec, @temp_buffer, sizeof(temp_buffer));
        end;
      end;
    end;
  finally LeaveCriticalSection(lua_lock); end;
end;

function tLuaShare.DeepCopy(AContext: TLuaContext): integer;
var namespace_name : ansistring;
begin
  result:= 0;
  if assigned(lua_storage_state) then try
    EnterCriticalSection(lua_lock);
    try
      with AContext do begin
        namespace_name:= Stack[1].AsTable[namespace_item].AsString(datatable_name);
        lua_getglobal(lua_storage_state, pAnsiChar(namespace_name));
        if (lua_type(lua_storage_state, -1) = LUA_TTABLE) then begin
          if (lua_getmetatable(lua_storage_state, -1) = 1) then begin // if metatable defined, then we have a __data container
             lua_pop(lua_storage_state, 1);                           // dont need metatable, only check if exists
             lua_pushstring(lua_storage_state, data_item);
             lua_gettable(lua_storage_state, -2);                     // get __data table from namespace container
             __deepcopy(lua_storage_state, CurrentState);
             lua_pop(lua_storage_state, 1);                           // pop __data table
          end else __deepcopy(lua_storage_state, CurrentState);       // if not, then copy table
        end else lua_pushnil(CurrentState);
        lua_pop(lua_storage_state, 1);
        result:= 1;
      end;
    finally LeaveCriticalSection(lua_lock); end;
  except on e: exception do messagebox(0, pAnsiChar(e.message), msgbox_err_title, MB_ICONERROR); end;
end;

function tLuaShare.IPCDeepCopy(AContext: TLuaContext): integer;
begin result:= RPCCallNS(AContext, 'DumpIPC', AContext.Stack[1].AsTable[namespace_item].AsString(datatable_name), [], AContext.Stack[2].AsInteger(max_RPC_timeout)); end;

function tLuaShare.RPCCallNS(AContext: TLuaContext; const afuncname, ansname: ansistring; const aargs: array of const; atimeout: integer): integer;
var received_len   : longint;
    temp_buffer    : array[0..max_single_value_size - 1] of ansichar;
    i              : longint;
begin
  result:= 0;
  EnterCriticalSection(lua_lock);
  try
    if IPCReady then begin
      fCodec.startcodec(fDataBuffer, max_transmission_size);
      fCodec.writestring(afuncname);
      fCodec.writenumber(length(aargs) + 1);
      fCodec.writestring(ansname);
      for i:= 0 to length(aargs) - 1 do
        stack2buf(AContext.CurrentState, aargs[i].VInteger, fCodec);
      if fIPCClient.send_receive(fDataBuffer, fCodec.stopcodec, fDataBuffer, received_len, atimeout) then begin
        fCodec.startcodec(fDataBuffer, received_len);
        result:= fCodec.readint(0);
        for i:= 0 to result - 1 do
          buf2stack(AContext.CurrentState, fCodec, @temp_buffer, sizeof(temp_buffer));
      end;
    end;
  finally LeaveCriticalSection(lua_lock); end;
end;

function tLuaShare.ShowMessageBox(AContext: TLuaContext): integer;
begin
  with AContext do
    messagebox(0, pAnsiChar(Stack[1].AsString), pAnsiChar(Stack[2].AsString(def_msgbox_title)), MB_ICONINFORMATION);
  result:= 0;
end;

function tLuaShare.GetNameSpace(AContext: TLuaContext): integer;
begin with AContext do result:= selfregister(CurrentState, pAnsiChar(Stack[1].AsString(datatable_name)), DeepCopy, __index, __newindex, nil); end;

function tLuaShare.GetIPCNameSpace(AContext: TLuaContext): integer;
begin
  EnterCriticalSection(lua_lock);
  try
    if not assigned(fIPCClient) then fIPCClient:= tIPCClient.create(transmission_buffer_size);
    if not assigned(fCodec) then fCodec:= tLuaCodec.Create;
    if not assigned(fDataBuffer) then fDataBuffer:= allocmem(transmission_buffer_size);
  finally LeaveCriticalSection(lua_lock); end;
  with AContext do result:= selfregister(CurrentState, pAnsiChar(Stack[1].AsString(datatable_name)), IPCDeepCopy, __IPC_index, __IPC_newindex, __IPC_call);
end;

function tLuaShare.selfregister(ALuaState: TLuaState; ANameSpace: pAnsiChar; adeepcpy, aidx, anewidx, acall: tLuaFunction): integer;
begin
  lua_newtable(ALuaState);                                            // result table
    lua_pushstring(ALuaState, 'DeepCopy');
    PushMethod(ALuaState, adeepcpy);
  lua_settable(ALuaState, -3);
    lua_pushstring(ALuaState, 'GetNameSpace');
    PushMethod(ALuaState, GetNameSpace);
  lua_settable(ALuaState, -3);
    lua_pushstring(ALuaState, 'GetIPCNameSpace');
    PushMethod(ALuaState, GetIPCNameSpace);
  lua_settable(ALuaState, -3);
    lua_pushstring(ALuaState, namespace_item);
    lua_pushstring(ALuaState, ANameSpace);
  lua_settable(ALuaState, -3);
    lua_newtable(ALuaState);                                          // metatable
      lua_pushstring(ALuaState, '__index');
      PushMethod(ALuaState, aidx);
    lua_settable(ALuaState, -3);
      lua_pushstring(ALuaState, '__newindex');
      PushMethod(ALuaState, anewidx);
    lua_settable(ALuaState, -3);
    if assigned(acall) then begin
        lua_pushstring(ALuaState, '__call');
        PushMethod(ALuaState, acall);
      lua_settable(ALuaState, -3);
    end;
  lua_setmetatable(ALuaState, -2);
  result:= 1;
end;

{ lua atpanic handler }

function LuaAtPanic(astate: Lua_State): Integer; cdecl;
var err: ansistring;
    len: size_t;
begin
  SetString(err, lua_tolstring(astate, -1, len), len);
  raise Exception.CreateFmt('LUA ERROR: %s', [err]);
end;

{ main functions }

function get_lua_library: HMODULE;
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

function initialize_share(ALuaInstance: TLuaState): integer;
var hLib       : HMODULE;
    path, tmp  : ansistring;
begin
  result:= 0;
  if not assigned(lua_share_instance) then begin
    hLib:= get_lua_library;
    if (hLib <> 0) then begin
      // force lua unit initialization:
      InitializeLuaLib(hLib);
      // initialize lua storage state:
      if not assigned(lua_storage_state) then begin
        lua_storage_state:= luaL_newstate();
        if assigned(lua_storage_state) then begin
          lua_atpanic(lua_storage_state, LuaAtPanic);
          luaL_openlibs(lua_storage_state);
        end;
      end;
      // initialize lua wrapper instance:
      lua_share_instance:= tLuaShare.Create(hLib);
      // execute bootstrap if exists
      path:= ExtractFilePath(ExpandFileName(get_module_name(HInstance)));
      tmp:= path + bootstrap_name;
      if fileexists(tmp) then begin
        with lua_share_instance do begin
          // register __script_path global variable for bootstrap
          lua_pushstring(lua_storage_state, pAnsiChar(path));
          lua_setglobal(lua_storage_state, boot_script_path);
          // register MessageBox() function for bootstrap
          RegisterGlobalMethod(lua_storage_state, 'MessageBox', ShowMessageBox);
        end;
        with TLuaContext.create(lua_storage_state) do try
          if not ExecuteFileSafe(tmp, 0, tmp) then
            messagebox(0, pAnsiChar(format('Error loading %s: %s', [bootstrap_name, tmp])), msgbox_err_title, MB_ICONERROR);
        finally free; end;
      end else messagebox(0, pAnsiChar(format('Boot script not found: %s', [tmp])), def_msgbox_title, MB_ICONWARNING);
    end else messagebox(0, pAnsiChar(format('Failed to find LUA library: %s', [lua_supported_libs[low(lua_supported_libs)]])), msgbox_err_title, MB_ICONERROR);
  end;
  if assigned(lua_share_instance) then begin
    with lua_share_instance do result:= selfregister(ALuaInstance, datatable_name, DeepCopy, __index, __newindex, nil);
    // register result table as a global variable:
    lua_pushvalue(ALuaInstance, -1);
    lua_setglobal(ALuaInstance, package_name);
  end;
end;

initialization
  InitializeCriticalSection(lua_lock);

finalization
  if assigned(lua_share_instance) then freeandnil(lua_share_instance);
  if assigned(lua_storage_state) then lua_close(lua_storage_state);
  DeleteCriticalSection(lua_lock);

end.
