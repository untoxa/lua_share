{$include lua_share_defs.pas}

unit lua_share_main;

interface

uses  windows, classes, sysutils, math,
      LuaLib, LuaHelpers;

const package_name       = 'share';
      datatable_name     = '__default_namespace';
      metatable_name     = '__default_namespace_metatable';
      namespace_item     = '__namespace';
      data_item          = '__data';
      bootstrap_name     = 'lua_share_boot.lua';

const lua_supported_libs : array[0..1] of pAnsiChar = ('Lua5.1.dll', 'qlua.dll');

type  tLuaShare          = class(TLuaClass)
      private
        procedure   __deepcopy(sour, dest: TLuaState);
        procedure   __deepcopyvalue(sour, dest: TLuaState; avalueindex: integer);
      public
        function    __index(AContext: TLuaContext): integer;
        function    __newindex(AContext: TLuaContext): integer;

        function    DeepCopy(AContext: TLuaContext): integer;
        function    GetNameSpace(AContext: TLuaContext): integer;

        function    ShowMessageBox(AContext: TLuaContext): integer;

        function    selfregister(ALuaState: TLuaState; ANameSpace: pAnsiChar): integer;
      end;

function  initialize_share(ALuaInstance: TLuaState): integer;

implementation

var   lua_lock           : TRTLCriticalSection;

const lua_storage_state  : TLuaState = nil;
      lua_share_instance : tLuaShare = nil;

{ tLuaShare }

procedure tLuaShare.__deepcopy(sour, dest: TLuaState);
var len : cardinal;
begin
  case lua_type(sour, -1) of
    LUA_TBOOLEAN : lua_pushboolean(dest, lua_toboolean(sour, -1));
    LUA_TNUMBER  : lua_pushnumber(dest, lua_tonumber(sour, -1));
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
        end else lua_pushnil(CurrentState);
        lua_pop(lua_storage_state, 2);
        result:= 1;
      end;
    finally LeaveCriticalSection(lua_lock); end;
  except on e: exception do messagebox(0, pAnsiChar(e.message), 'ERROR', 0); end;
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
  except on e: exception do messagebox(0, pAnsiChar(e.message), 'ERROR', 0); end;
  result:= 0;
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
          if lua_getmetatable(lua_storage_state, -1) then begin       // if metatable defined, then we have a __data container
             lua_pop(lua_storage_state, 1);                           // dont need metatable, only check if exists
             lua_pushstring(lua_storage_state, data_item);
             lua_gettable(lua_storage_state, -2);                     // get __data table from namespace container
             __deepcopy(lua_storage_state, CurrentState);
             lua_pop(lua_storage_state, 1);                           // pop __data table
          end else __deepcopy(lua_storage_state, CurrentState)
        end else lua_pushnil(CurrentState);                           // if not, then copy table itself
        lua_pop(lua_storage_state, 1);
        result:= 1;
      end;
    finally LeaveCriticalSection(lua_lock); end;
  except on e: exception do messagebox(0, pAnsiChar(e.message), 'ERROR', 0); end;
end;

function tLuaShare.ShowMessageBox(AContext: TLuaContext): integer;
begin
  with AContext do
    messagebox(0, pAnsiChar(Stack[1].AsString), pAnsiChar(Stack[2].AsString('Message')), MB_ICONINFORMATION);
  result:= 0;
end;

function tLuaShare.GetNameSpace(AContext: TLuaContext): integer;
begin
  with AContext do
    result:= selfregister(CurrentState, pAnsiChar(Stack[1].AsString(datatable_name)));
end;

function tLuaShare.selfregister(ALuaState: TLuaState; ANameSpace: pAnsiChar): integer;
begin
  lua_newtable(ALuaState);                                            // result table
    lua_pushstring(ALuaState, 'DeepCopy');
    PushMethod(ALuaState, DeepCopy);
  lua_settable(ALuaState, -3);
    lua_pushstring(ALuaState, 'GetNameSpace');
    PushMethod(ALuaState, GetNameSpace);
  lua_settable(ALuaState, -3);
    lua_pushstring(ALuaState, namespace_item);
    lua_pushstring(ALuaState, ANameSpace);
  lua_settable(ALuaState, -3);
    lua_newtable(ALuaState);                                          // metatable
      lua_pushstring(ALuaState, '__index');
      PushMethod(ALuaState, __index);
    lua_settable(ALuaState, -3);
      lua_pushstring(ALuaState, '__newindex');
      PushMethod(ALuaState, __newindex);
    lua_settable(ALuaState, -3);
  lua_setmetatable(ALuaState, -2);
  result:= 1;
end;

{ lua atpanic handler }

function LuaAtPanic(astate: Lua_State): Integer; cdecl;
var len: cardinal;
    err: ansistring;
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
var hLib : HMODULE;
    tmp  : ansistring;
begin
  result:= 0;
  if not assigned(lua_share_instance) then begin
    hLib:= get_lua_library;
    if (hLib <> 0) then begin
      // force lua unit initialization:
      InitializeLuaLib(hLib);
      // initialize lua storage state:
      if not assigned(lua_storage_state) then begin
        lua_storage_state:= luaL_newstate;
        if assigned(lua_storage_state) then begin
          lua_atpanic(lua_storage_state, LuaAtPanic);
          luaL_openlibs(lua_storage_state);
        end;
      end;
      // initialize lua wrapper instance:
      lua_share_instance:= tLuaShare.Create(hLib);
      // execute bootstrap if exists
      tmp:= ExtractFilePath(ExpandFileName(get_module_name(HInstance))) + bootstrap_name;
      if fileexists(tmp) then begin
        with lua_share_instance do
          RegisterGlobalMethod(lua_storage_state, 'MessageBox', ShowMessageBox);  // register MessageBox() function for bootstrap
        with TLuaContext.create(lua_storage_state) do try
          if not ExecuteFileSafe(tmp, 0, tmp) then
            messagebox(0, pAnsiChar(format('Error loading %s: %s', [bootstrap_name, tmp])), 'ERROR', 0);
        finally free; end;
      end;
    end else messagebox(0, pAnsiChar(format('Failed to find LUA library: %s', [lua_supported_libs[low(lua_supported_libs)]])), 'ERROR', 0);
  end;
  if assigned(lua_share_instance) then begin
    result:= lua_share_instance.selfregister(ALuaInstance, datatable_name);
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
