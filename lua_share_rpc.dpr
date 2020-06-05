{$include lua_share_defs.pas}

library lua_share_rpc;

uses  windows, sysutils,
      LuaLib53,
      lua_share_rpc_main;

{$R *.res}

function luaopen_lua_share_rpc(ALuaInstance: Lua_State): longint; cdecl;
begin result:= initialize_share_rpc(ALuaInstance); end;

exports  luaopen_lua_share_rpc name 'luaopen_lua_share_rpc',
         terminate_rpc_server  name 'terminate_rpc_server';

begin
  IsMultiThread:= true;
  {$ifdef FPC}
  DefaultFormatSettings.DecimalSeparator:= '.';
  {$else}
  DecimalSeparator:= '.';
  {$endif}
end.
