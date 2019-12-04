__script_path = './scripts/'

package.path = "./?.lua;./scripts/?.lua"
package.cpath = "./?.dll;./scripts/?.dll"

rpc = require "lua_share_rpc"
require "lua_share_boot"

function GetIPC(ns, key)
    local __ns = _G[ns]
        if type(__ns) == 'table' then
        return __ns[key]
    end	
    return nil
end

function SetIPC(ns, key, value)
    local __ns = _G[ns]
    if type(__ns) ~= 'table' then
        __ns = {}
        __ns.__data = {}
        setmetatable(__ns, __default_namespace_metatable)
        _G[ns] = __ns
    end
    __ns[key] = value
end

function DumpIPC(ns)
    local __ns = _G[ns]
    if type(__ns) == 'table' then
        if getmetatable(__ns) ~= nil then 
            return __ns.__data
        else
            return __ns
        end
    end
end

function testfunc(...)
    return ...
end

run = true

function main()
    while run and not exitflag do
        run, err = rpc.ProcessRPC(100)
        if not run then message('error: '..tostring(err)) end 
    end
end

function OnStop()
    exitflag = true
end

if type(isConnected) ~= 'function' then
    message = function(msg, code)
      io.write(tostring(msg) .. '\r\n')
    end
    main()
end