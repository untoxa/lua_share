package.cpath = getScriptPath() .. "\\lua_share.dll"
sh = require "share"

exitflag = false

function main()
    local ns = sh.GetNameSpace("additional_name_space")
    local tmp = {["foo"] = "bar", [123] = 456, {1,2,3}, {4,5,6}, [{1,2,3}] = "tblkey"}
    local i = 0
    while not exitflag do
      i = i + 1
      tmp["iteration"] = i
      ns["test"] = tmp
      sleep(1000)
    end
end

function OnStop()
  exitflag = true
end