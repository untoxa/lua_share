package.cpath = getScriptPath() .. "/?.dll"
sh = require "lua_share"

exitflag = false

function main()
    local ns = sh.GetNameSpace("queues")
    local i = 0
    while not exitflag do
      i = i + 1
      ns["queue1"] = i
      sleep(1000)
    end
end

function OnStop()
  exitflag = true
end