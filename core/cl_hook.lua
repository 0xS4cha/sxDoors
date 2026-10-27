local pairs = pairs
local setmetatable = setmetatable
local CreateThreadNow = Citizen.CreateThreadNow

hook = {}
local HookTable = {}
local HookMeta = { __index = HookTable }

local function CreateHookTable()
    return setmetatable({ n = 0, keys = {} }, HookMeta)
end

function HookTable:Add(name, func, obj)
    local index = self.keys[name]
    if index then
        self[index + 1] = func
        self[index + 2] = obj
    else
        local n = self.n
        self[n + 1] = name
        self[n + 2] = func
        self[n + 3] = obj
        self.keys[name] = n + 1
        self.n = n + 3
    end
end

function HookTable:Remove(name)
    local index = self.keys[name]
    if index then
        self[index] = nil
        self[index + 1] = nil
        self[index + 2] = nil
        self.keys[name] = nil
    end
end

function HookTable:GetHooks()
    local hooks = {}
    local i = 1
    local n = self.n
    while i <= n do
        local name = self[i]
        if name then
            hooks[name] = self[i + 1]
        end
        i = i + 3
    end
    return hooks
end

local function IsString(val)
    return type(val) == "string"
end

local function IsFunction(val)
    return type(val) == "function"
end

local Hooks = {}

function hook.Add(eventName, name, func)
    if not IsString(eventName) then error("Event name incorrect") end
    if not IsFunction(func) then error("Hook function not a function") end
    if not name then error("Hook name missing") end

    local obj = false
    if not IsString(name) then
        obj = name
    end

    if not Hooks[eventName] then
        Hooks[eventName] = CreateHookTable()
    end

    Hooks[eventName]:Add(name, func, obj)
end

function hook.Remove(eventName, name)
    if Hooks[eventName] then
        Hooks[eventName]:Remove(name)
    end
end

function hook.GetTable()
    local table = {}
    for eventName, hookTable in pairs(Hooks) do
        table[eventName] = hookTable:GetHooks()
    end
    return table
end

function hook.Call(eventName, ...)
    local hookTable = Hooks[eventName]
    if hookTable then
        local i = 1
        local n = hookTable.n
        while i <= n do
            local name = hookTable[i]
            if name then
                local func = hookTable[i + 1]
                local obj = hookTable[i + 2]
                
                if obj then
                    if obj.IsValid and obj:IsValid() then
                        local a, b, c, d, e, f = func(obj, ...)
                        if a ~= nil then
                            return a, b, c, d, e, f
                        end
                    else
                        hookTable:Remove(name)
                    end
                else
                    local a, b, c, d, e, f = func(...)
                    if a ~= nil then
                        return a, b, c, d, e, f
                    end
                end
                i = i + 3
            else
                local currentN = hookTable.n
                local skip = false
                
                if currentN ~= n then
                    n = currentN
                    skip = true
                else
                    n = n - 3
                end
                
                local lastIndex = hookTable.n - 2
                local lastName = hookTable[lastIndex]
                
                if lastName then
                    hookTable[i] = lastName
                    hookTable[i+1] = hookTable[lastIndex+1]
                    hookTable[i+2] = hookTable[lastIndex+2]
                    
                    hookTable.keys[lastName] = i
                    
                    hookTable[lastIndex] = nil
                    hookTable[lastIndex+1] = nil
                    hookTable[lastIndex+2] = nil
                    
                    hookTable.n = hookTable.n - 3
                end
                
                if hookTable.n == 0 then
                    Hooks[eventName] = nil
                end
                
                if skip then
                    i = i + 3
                end
            end
        end
    end
end

function hook.CallAsync(eventName, ...)
    local args = {...}
    CreateThreadNow(function()
        hook.Call(eventName, table.unpack(args))
    end)
end