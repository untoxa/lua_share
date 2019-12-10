package.cpath = getScriptPath() .. "/?.dll"
sh = require "lua_share"

function table.val_to_str ( v )
    if "string" == type( v ) then
        v = string.gsub( v, "\n", "\\n" )
        if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
    end
    return "table" == type( v ) and table.tostring( v ) or tostring( v )
end
function table.key_to_str ( k )
    if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
        return k
    end
    return "[" .. table.val_to_str( k ) .. "]"
end
function table.tostring( tbl )
    if type(tbl)~='table' then return table.val_to_str(tbl) end
    local result, done = {}, {}
    for k, v in ipairs( tbl ) do
        table.insert( result, table.val_to_str( v ) )
        done[ k ] = true
    end
    for k, v in pairs( tbl ) do
        if not done[ k ] then
            table.insert( result, table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
        end
    end
    return "{" .. table.concat( result, "," ) .. "}"
end

function main()
    local ns = sh.GetNameSpace("collapsing_queues")
    ns["queue1"] = {["__key"]=1, 1, 2, 3}
    ns["queue1"] = {["__key"]=2, 4, 5, 6}
    ns["queue1"] = {["__key"]=1, 7, 8, 9}
    message(table.tostring(ns["queue1"]), 1)
    message(table.tostring(ns["queue1"]), 1)
    message(table.tostring(ns["queue1"]), 1)
end
