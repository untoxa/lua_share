package.cpath = getScriptPath() .. "/?.dll"
sh = require "lua_share"

function main()
    local ns = sh.GetNameSpace("eventlists") -- get predefined "eventlists" namespace
    
    while not exitflag do
        local data = "{"
        local i = ns["queue1"]
        while i ~= nil do
            data = data .. tostring(i) .. ","
            i = ns["queue1"]
        end
        data = data .. "}"
        message("Received: " .. data, 1)
        sleep(1000)
    end
end

function OnStop()
    exitflag = true
end