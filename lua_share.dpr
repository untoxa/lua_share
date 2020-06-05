{$include lua_share_defs.pas}

library lua_share;

uses  windows, sysutils,
      LuaLib53,
      lua_share_main;

{$R *.res}

function luaopen_lua_share(ALuaInstance: Lua_State): longint; cdecl;
begin result:= initialize_share(ALuaInstance); end;

exports  luaopen_lua_share name 'luaopen_lua_share';

begin
  IsMultiThread:= true;
  {$ifdef FPC}
  DefaultFormatSettings.DecimalSeparator:= '.';
  {$else}
  DecimalSeparator:= '.';
  {$endif}
end.
