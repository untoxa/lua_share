package.cpath = getScriptPath() .. "/?.dll"
sh = require "lua_share"

exitflag = false

function main()
    local ns = sh.GetNameSpace("eventlists") -- get predefined "eventlists" namespace
    local i = 0
    while not exitflag do
        i = i + 1
        ns["queue1"] = math.random(5)        -- queue some payload
        sleep(100 + math.random(100))      
    end
end

function OnStop()
    exitflag = true
end