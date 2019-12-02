package.cpath = "./?.dll;./scripts/?.dll"
sh = require "lua_share"
rpc = require "lua_share_rpc"

function GetIPC(ns, key)
    local ns = sh.GetNameSpace(ns)
    return ns[key]
end

function SetIPC(ns, key, value)
    local ns = sh.GetNameSpace(ns)
    ns[key] = value
end

function DumpIPC(ns)
    local ns = sh.GetNameSpace(ns)
    return ns:DeepCopy()
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