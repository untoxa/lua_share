package.cpath = getScriptPath() .. "\\lua_share.dll"
sh = require "share"

function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0
    local tmp = string.rep(" ", depth)
    if name then tmp = tmp .. tostring(name) .. " = " end
    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")
        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end
        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end
    return tmp
end

function main()
    sh["test"] = {["foo"] = "bar", [123] = 456, {1,2,3}, {4,5,6}, [{1,2,3}] = "tblkey"}
    local tmp = sh["test"]
    message("ns:" .. sh["__namespace"] .. " tmp:" .. serializeTable(tmp), 1)

    local tmp2 = sh["test2"]
    sh["test2"] = "data2"
    message("tmp2:" .. tostring(tmp2), 1)
    tmp2 = sh["test2"]
    message("tmp2 second time:" .. tostring(tmp2), 1)

    local ns = sh.GetNameSpace("additional_name_space")
    message("created ns:" .. tostring(ns), 1)
    ns["test3"] = {["key"] = "value", 1, 2, 3, 4, {5, 6, 7}}
    local tmp3 = ns["test3"]
    message("ns:" .. ns["__namespace"] .. " tmp3:" .. serializeTable(tmp3), 1)
end
