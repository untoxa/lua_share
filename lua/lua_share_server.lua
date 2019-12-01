package.cpath = "/?.dll;./scripts/?.dll"
sh = require "lua_share"

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
while run do
    run, err = ProcessIPC(100)
    if not run then print('error: '..tostring(err)) end 
end