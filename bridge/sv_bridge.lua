Bridge = {}
Bridge.Name = 'standalone'

local ESX = nil

local function detectFramework()
    if Config.Framework == 'standalone' then return 'standalone' end

    if Config.Framework == 'esx' or GetResourceState('es_extended') ~= 'missing' then
        local ok, obj = pcall(function()
            return exports.es_extended:getSharedObject()
        end)
        if ok and obj then
            ESX = obj
            return 'esx'
        end

        if Config.Framework == 'esx' then
            Logger:error('BRIDGE', "Config.Framework is 'esx' but es_extended could not be loaded")
        end
    end

    return 'standalone'
end

Bridge.Name = detectFramework()
Logger:info('BRIDGE', "Framework:", Bridge.Name)

function Bridge.IsESX()
    return Bridge.Name == 'esx'
end

local function getPlayer(source)
    if not ESX then return nil end
    return ESX.GetPlayerFromId(source)
end

function Bridge.GetIdentifiers(source)
    local identifiers = {}
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        identifiers[identifier] = true
    end

    local xPlayer = getPlayer(source)
    if xPlayer and xPlayer.identifier then
        identifiers[xPlayer.identifier] = true
    end

    return identifiers
end

function Bridge.GetMainIdentifier(source)
    local xPlayer = getPlayer(source)
    if xPlayer and xPlayer.identifier then
        return xPlayer.identifier
    end

    return GetPlayerIdentifierByType(source, 'license') or ('player:' .. tostring(source))
end

function Bridge.GetPlayerName(source)
    local xPlayer = getPlayer(source)
    if xPlayer and xPlayer.getName then
        local ok, name = pcall(xPlayer.getName)
        if ok and name then return name end
    end

    return GetPlayerName(source) or ('#' .. tostring(source))
end

function Bridge.GetJob(source)
    local xPlayer = getPlayer(source)
    if not xPlayer then return nil end

    local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job
    if not job then return nil end

    return job.name, tonumber(job.grade) or 0
end

function Bridge.HasItem(source, item)
    local xPlayer = getPlayer(source)
    if not xPlayer then return false end

    local data = xPlayer.getInventoryItem(item)
    return data ~= nil and (tonumber(data.count) or 0) > 0
end

function Bridge.RemoveItem(source, item, count)
    local xPlayer = getPlayer(source)
    if not xPlayer then return false end

    xPlayer.removeInventoryItem(item, count or 1)
    return true
end

function Bridge.RegisterUsableItem(item, cb)
    if not ESX or not item then return false end

    ESX.RegisterUsableItem(item, cb)
    return true
end

function Bridge.GetJobs()
    if not ESX or not ESX.GetJobs then return {} end

    local result = {}
    for name, job in pairs(ESX.GetJobs() or {}) do
        local grades = {}
        for _, grade in pairs(job.grades or {}) do
            grades[#grades + 1] = { grade = tonumber(grade.grade) or 0, label = grade.label or grade.name or tostring(grade.grade) }
        end
        table.sort(grades, function(a, b) return a.grade < b.grade end)
        result[#result + 1] = { name = name, label = job.label or name, grades = grades }
    end

    table.sort(result, function(a, b) return a.label < b.label end)
    return result
end

function Bridge.IsAdmin(source)
    if not source or source <= 0 then return true end

    if Config.Admin.ace and IsPlayerAceAllowed(source, Config.Admin.ace) then
        return true
    end

    local xPlayer = getPlayer(source)
    if xPlayer then
        local group = xPlayer.getGroup and xPlayer.getGroup()
        for _, allowed in ipairs(Config.Admin.groups or {}) do
            if group == allowed then return true end
        end
    end

    return false
end

function Bridge.Notify(source, message, kind)
    TriggerClientEvent('sxDoors:notify', source, message, kind or 'info')
end
