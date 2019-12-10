--   __script_path             - absolute path to this script
--   MesssageBox(text, title)  - shows messagebox

-- function compares two tables by contents
function __deepcompare(t1, t2, ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not __deepcompare(v1, v2) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not __deepcompare(v1, v2) then return false end
    end
    return true
end

-- function finds the key in table and returns an original key
function __findkey(t, k)
    if type(t) ~= 'table' or type(k) ~= 'table' then return nil end
    for idx,val in pairs(t) do
        if type(idx) == "table" then
            if __deepcompare(idx, k) then return idx end
        end
    end
    return nil
end

-- dataspace metatable implemantation
-- assume that self.__data is a container for actual table data
__default_namespace_metatable = {
    __newindex = function(self, key, value)
        if type(key)~="table" then
            self.__data[key] = value
        else
            local idx = __findkey(self.__data, key)
            if idx then
                self.__data[idx] = value
            else
                self.__data[key] = value
            end
        end
    end,
    __index = function(self, key)
        if type(key)~="table" then
            return self.__data[key]
        else
            local idx = __findkey(self.__data, key)
            if idx then return self.__data[idx] end
        end
        return nil
    end
}

-- predefined "queues" namespace implementation
-----------------------------------------------
queues = {
    __data = {},
    __new = function()
        return {first = 0, last = -1}
    end,
    __push = function(list, value)
        local last = list.last
        if last == nil then
            list.last = 0
            list.first = 0
            list[0] = value
        else
            list.last = last + 1
            list[last + 1] = value
        end
    end,
    __pop = function(list)
        local first = list.first
        if first == nil then
            list.last = -1
            list.first = 0
            return nil
        end
        if first > list.last then return nil end
        local value = list[first]
        list[first] = nil
        list.first = first + 1
        return value
    end
}

setmetatable(queues, {
    __newindex = function(self, key, value)
        local idx = nil
        if type(key)~="table" then
            idx = key
        else
            idx = __findkey(self.__data, key)
            if idx == nil then idx = key end
        end
        local queue = self.__data[idx]
        if queue == nil then
            queue = self.__new()
            self.__data[idx] = queue
        end;
        self.__push(queue, value)
    end,
    __index = function(self, key)
        local idx = nil
        if type(key)~="table" then
            idx = key
        else
            idx = __findkey(self.__data, key)
        end
        if idx ~= nil then
            local queue = self.__data[idx]
            if queue ~= nil then
                return self.__pop(queue)
            end
        end
        return nil
    end
})

-- predefined "eventlists" namespace implementation
-- "queue" of unique values
---------------------------------------------------
eventlists = {
    __data = {},
    __new = function()
        return {}
    end,
    __push = function(list, key, value)
        local idx = nil
        if type(key)~="table" then
            idx = key
        else
            idx = __findkey(list, key)
            if idx == nil then idx = key end
        end
        list[idx] = value
    end,
    __pop = function(list)
        local key, value = next(list, nil)
        if key ~= nil then list[key] = nil end
        return key, value
    end
}

setmetatable(eventlists, {
    __newindex = function(self, key, value)
        local idx = nil
        if type(key)~="table" then
            idx = key
        else
            idx = __findkey(self.__data, key)
            if idx == nil then idx = key end
        end
        local queue = self.__data[idx]
        if queue == nil then
            queue = self.__new()
            self.__data[idx] = queue
        end;
        self.__push(queue, value, 1) -- use value as key
    end,
    __index = function(self, key)
        local idx = nil
        if type(key)~="table" then
            idx = key
        else
            idx = __findkey(self.__data, key)
        end
        if idx ~= nil then
            local queue = self.__data[idx]
            if queue ~= nil then
                local k, v = self.__pop(queue)
                return k
            end
        end
        return nil
    end
})

-- predefined "collapsing_queues" namespace implementation
-- "queue" of unique values by value.__key
----------------------------------------------------------
collapsing_queues = {
    __data = {},
    __new = function()
        return {}
    end,
    __push = function(list, key, value)
        local idx = nil
        if type(key)~="table" then
            idx = key
        else
            idx = __findkey(list, key)
            if idx == nil then idx = key end
        end
        list[idx] = value
    end,
    __pop = function(list)
        local key, value = next(list, nil)
        if key ~= nil then list[key] = nil end
        return key, value
    end
}

setmetatable(collapsing_queues, {
    __newindex = function(self, key, value)
        local idx = nil
        if type(key)~="table" then
            idx = key
        else
            idx = __findkey(self.__data, key)
            if idx == nil then idx = key end
        end
        local queue = self.__data[idx]
        if queue == nil then
            queue = self.__new()
            self.__data[idx] = queue
        end;
        local val_key = value["__key"]
        if val_key == nil then val_key = value end        
        self.__push(queue, val_key, value) -- use value[__key] as key or value itself if not defined
    end,
    __index = function(self, key)
        local idx = nil
        if type(key)~="table" then
            idx = key
        else
            idx = __findkey(self.__data, key)
        end
        if idx ~= nil then
            local queue = self.__data[idx]
            if queue ~= nil then
                local k, v = self.__pop(queue)
                return v
            end
        end
        return nil
    end
})

-- predefined "fixed_queues" namespace implementation
-- queues with fixed maximum length
-----------------------------------------------------
__max_fixed_queue_length = 100
fixed_queues = {
    __data = {},
    __new = function()
        return {first = 0, last = -1, max_len = __max_fixed_queue_length}
    end,
    __push = function(list, value)
        local last = list.last
        if last == nil then
            list.last = 0
            list.first = 0
            list.max_len = __max_fixed_queue_length
            list[0] = value
        else
            list.last = last + 1
            list[last + 1] = value
            while list.last - list.first > list.max_len do
              list:__pop()
            end
        end
    end,
    __pop = function(list)
        local first = list.first
        if first == nil then
            list.last = -1
            list.first = 0
            list.max_len = __max_fixed_queue_length
            return nil
        end
        if first > list.last then return nil end
        local value = list[first]
        list[first] = nil
        list.first = first + 1
        return value
    end
}

setmetatable(fixed_queues, {
    __newindex = function(self, key, value)
        local idx = nil
        if type(key)~="table" then
            idx = key
        else
            idx = __findkey(self.__data, key)
            if idx == nil then idx = key end
        end
        local queue = self.__data[idx]
        if queue == nil then
            queue = self.__new()
            self.__data[idx] = queue
        end;
        self.__push(queue, value)
    end,
    __index = function(self, key)
        local idx = nil
        if type(key)~="table" then
            idx = key
        else
            idx = __findkey(self.__data, key)
        end
        if idx ~= nil then
            local queue = self.__data[idx]
            if queue ~= nil then
                return self.__pop(queue)
            end
        end
        return nil
    end
})

-- predefined "permanent" namespace implementation
-- namespace with load/save
--------------------------------------------------
function table.val_to_str(v)
    if "string" == type(v) then
        v = string.gsub(v, "\n", "\\n")
        if string.match(string.gsub(v,"[^'\"]",""), '^"+$') then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v,'"', '\\"') .. '"'
    end
    return "table" == type(v) and table.tostring(v) or tostring(v)
end
function table.key_to_str(k)
    if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
        return k
    end
    return "[" .. table.val_to_str(k) .. "]"
end
function table.tostring(tbl)
    if type(tbl)~='table' then return table.val_to_str(tbl) end
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
        table.insert(result, table.val_to_str(v))
        done[k] = true
    end
    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result, table.key_to_str(k) .. "=" .. table.val_to_str(v))
        end
    end
    return "{" .. table.concat(result, ",") .. "}"
end
function table.load(fname)
    local f, err = io.open(fname, "r")
    if f == nil then return {} end
    local fn, err = loadstring("return "..f:read("*a"))
    f:close()
    if type(fn) == "function" then
        local succ, res = pcall(fn)
        if succ and type(res) == "table" then return res end
    end
    return {}
end
function table.save(fname, tbl)
    local f, err = io.open(fname, "w")
    if f ~= nil then
        f:write(table.tostring(tbl))
        f:close()
    end
end

__permanent_file_name = __script_path .. "lua_share.permanent.dat"
permanent = {
    __data = table.load(__permanent_file_name),
}
__permanent_metatable = {
    __newindex = __default_namespace_metatable.__newindex,
    __index = __default_namespace_metatable.__index,
    __gc = function(self)
        if (self.__data ~= nil) and (next(self.__data) ~= nil) then
            table.save(__permanent_file_name, self.__data)
        else
            os.remove(__permanent_file_name)
        end
    end
}
if _VERSION == "Lua 5.1" then
    local t = permanent
    local proxy = newproxy(true)
    getmetatable(proxy).__gc = function(self) __permanent_metatable.__gc(t) end
    permanent[proxy] = true
end
setmetatable(permanent, __permanent_metatable)

