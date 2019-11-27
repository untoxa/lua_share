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

function default(v, defv)
    if v~= nil then return v end
    return defv 
end

function main()
    local ns = sh.GetNameSpace("permanent")

    message("was: " .. table.tostring(ns:DeepCopy()), 1)

    ns[{1, 2, {3, 4}}] = "john"
    ns[{1, 2, {3, 4}}] = "doe"
    ns[{4, 5, 6}] = default(ns[{4, 5, 6}], 0) + 1
    ns["hello"] = "world"
    message("now: " .. table.tostring(ns:DeepCopy()), 1)
end
