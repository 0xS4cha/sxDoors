Bridge = {}
Bridge.Name = 'standalone'

local ESX = nil

if Config.Framework ~= 'standalone' and (Config.Framework == 'esx' or GetResourceState('es_extended') ~= 'missing') then
    local ok, obj = pcall(function()
        return exports.es_extended:getSharedObject()
    end)
    if ok and obj then
        ESX = obj
        Bridge.Name = 'esx'
    end
end

function Bridge.IsESX()
    return Bridge.Name == 'esx'
end

function Bridge.Notify(message, kind)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(message, kind)
        return
    end

    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

function Bridge.ShowHelp(message)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

RegisterNetEvent('sxDoors:notify', function(message, kind)
    Bridge.Notify(message, kind)
end)
