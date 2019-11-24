package.cpath = getScriptPath() .. "/?.dll"
sh = require "lua_share"

function main()
    local ns = sh.GetNameSpace("queues")
    
    i = ns["queue1"]
    while i ~= nil do
      message("pop: "..tostring(i), 1)
      i = ns["queue1"]
    end
end
