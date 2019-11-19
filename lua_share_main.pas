{$include lua_share_defs.pas}

unit lua_share_main;

interface

uses  windows, classes, sysutils, math,
      LuaLib, LuaHelpers;

const package_name       = 'share';
      datatable_name     = '__default_namespace';
      namespace_item     = '__namespace';

const lua_supported_libs : array[0..1] of pAnsiChar = ('Lua5.1.dll', 'qlua.dll');

type  tLuaShare          = class(TLuaClass)
      private
        procedure   deepcopy(sour, dest: TLuaState);
        procedure   deepcopyvalue(sour, dest: TLuaState; avalueindex: integer);
      public
        function    __index(AContext: TLuaContext): integer;
        function    __newindex(AContext: TLuaContext): integer;

        function    GetNameSpace(AContext: TLuaContext): integer;

        function    selfregister(ALuaState: TLuaState; ANameSpace: pAnsiChar): integer;
      end;

function  initialize_share(ALuaInstance: TLuaState): integer;

implementation

var   lua_lock           : TRTLCriticalSection;

const lua_storage_state  : TLuaState = nil;
      lua_share_instance : tLuaShare = nil;

{ tLuaShare }

procedure tLuaShare.deepcopy(sour, dest: TLuaState);
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
                       deepcopyvalue(sour, dest, -2);
                       deepcopyvalue(sour, dest, -1);
                       lua_settable(dest, -3);
                       lua_pop(sour, 1);
                     end;
                   end;
    else           lua_pushnil(dest);
  end;
end;

procedure tLuaShare.deepcopyvalue(sour, dest: TLuaState; avalueindex: integer);
begin
  lua_pushvalue(sour, avalueindex);
  deepcopy(sour, dest);
  lua_pop(sour, 1);
end;

function tLuaShare.__index(AContext: TLuaContext): integer;
var namespace_name : ansistring;
begin
  result:= 0;
  if assigned(lua_storage_state) then begin
    EnterCriticalSection(lua_lock);
    try
      with AContext do begin
        namespace_name:= Stack[1].AsTable[namespace_item].AsString(datatable_name);
        lua_getglobal(lua_storage_state, pAnsiChar(namespace_name));
        if (lua_type(lua_storage_state, -1) = LUA_TTABLE) then begin
          deepcopyvalue(CurrentState, lua_storage_state, 2);
          lua_gettable(lua_storage_state, -2);
          deepcopy(lua_storage_state, CurrentState);
        end else lua_pushnil(CurrentState);
        lua_pop(lua_storage_state, 2);
        result:= 1;
      end;
    finally LeaveCriticalSection(lua_lock); end;
  end;
end;

function tLuaShare.__newindex(AContext: TLuaContext): integer;
var namespace_name : ansistring;
begin
  if assigned(lua_storage_state) then begin
    EnterCriticalSection(lua_lock);
    try
      with AContext do begin
        namespace_name:= Stack[1].AsTable[namespace_item].AsString(datatable_name);
        lua_getglobal(lua_storage_state, pAnsiChar(namespace_name));
        if (lua_type(lua_storage_state, -1) <> LUA_TTABLE) then begin // create table if not exist
          lua_pop(lua_storage_state, 1);
          lua_newtable(lua_storage_state);
          lua_pushvalue(lua_storage_state, -1);
          lua_setglobal(lua_storage_state, pAnsiChar(namespace_name));
        end;
        deepcopyvalue(CurrentState, lua_storage_state, 2);
        deepcopyvalue(CurrentState, lua_storage_state, 3);
        lua_settable(lua_storage_state, -3);
        lua_pop(lua_storage_state, 1); // pop table
      end;
    finally LeaveCriticalSection(lua_lock); end;
  end;
  result:= 0;
end;

function tLuaShare.GetNameSpace(AContext: TLuaContext): integer;
begin
  with AContext do
    result:= selfregister(CurrentState, pAnsiChar(Stack[1].AsString(datatable_name)));
end;

function tLuaShare.selfregister(ALuaState: TLuaState; ANameSpace: pAnsiChar): integer;
begin
  // create result table
  lua_newtable(ALuaState); // result table
    lua_pushstring(ALuaState, 'GetNameSpace');
    PushMethod(ALuaState, GetNameSpace);
  lua_settable(ALuaState, -3);
    lua_pushstring(ALuaState, namespace_item);
    lua_pushstring(ALuaState, ANameSpace);
  lua_settable(ALuaState, -3);
    lua_newtable(ALuaState); // metatable
      // __index
      lua_pushstring(ALuaState, '__index');
      PushMethod(ALuaState, __index);
    lua_settable(ALuaState, -3);
      // __newindex
      lua_pushstring(ALuaState, '__newindex');
      PushMethod(ALuaState, __newindex);
    lua_settable(ALuaState, -3);
  lua_setmetatable(ALuaState, -2);
  // indicate that 1 table object is on lua stack
  result:= 1;
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

function initialize_share(ALuaInstance: TLuaState): integer;
var hLib : HMODULE;
begin
  result:= 0;
  if not assigned(lua_share_instance) then begin
    hLib:= get_lua_library;
    if (hLib <> 0) then begin
      // force lua unit initialization:
      InitializeLuaLib(hLib);
      // initialize lua storage state:
      if not assigned(lua_storage_state) then lua_storage_state:= luaL_newstate;
      // initialize lua wrapper instance:
      lua_share_instance:= tLuaShare.Create(hLib);
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
