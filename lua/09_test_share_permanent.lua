package.cpath = getScriptPath() .. "/?.dll"
sh = require "lua_share"

function default(v, defv)
    if v ~= nil then return v end
    return defv
end

function main()
    local ns = sh.GetNameSpace("permanent")
    ns[{4, 5, 6}] = default(ns[{4, 5, 6}], 0) + 1
    message(tostring(ns[{4, 5, 6}]), 1)
end
