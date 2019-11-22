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
    sh["test"] = {["foo"] = "bar", [123] = 456, {1,2,3}, {4,5,6}, [{1,2,3}] = "tblkey"}
    local tmp = sh["test"]
    message("ns:" .. sh["__namespace"] .. " tmp:" .. table.tostring(tmp), 1)

    local tmp2 = sh["test2"]
    sh["test2"] = "data2"
    message("tmp2:" .. tostring(tmp2), 1)
    tmp2 = sh["test2"]
    message("tmp2 second time:" .. tostring(tmp2), 1)

    local ns = sh.GetNameSpace("additional_name_space")
    message("created ns:" .. table.tostring(ns), 1)
    ns["test3"] = {["key"] = "value", 1, 2, 3, 4, {5, 6, 7}}
    local tmp3 = ns["test3"]
    message("ns:" .. ns["__namespace"] .. " tmp3:" .. table.tostring(tmp3), 1)

    sh["test2"] = "test2"
    sh["test3"] = "test3"
    message("DeepCopy:" .. table.tostring(sh:DeepCopy()), 1)

end

