function SX.Admin:Initialize()
    if self.initialized then return end
    self.initialized = true
    RegisterNUICallback('getAdminGroups', function(_, cb)
        local groups = TriggerServerCallback('sxAdmin:getGroups')
        cb(groups or {})
    end)

    RegisterNUICallback('getAdminTerritories', function(_, cb)
        local territories = TriggerServerCallback('sxAdmin:getTerritories')
        cb(territories or {})
    end)

    RegisterNUICallback('getAdminStats', function(data, cb)
        local timeframe = data and data.timeframe or '24h'
        local stats = TriggerServerCallback('sxAdmin:getStats', timeframe)
        cb(stats or {})
    end)

    RegisterNUICallback('toggleGroupOfficial', function(data, cb)
        if data and data.groupId then
            TriggerServerEvent('sxAdmin:toggleGroupOfficial', data)
        end
        cb({ ok = true })
    end)

    RegisterNUICallback('deleteGroup', function(data, cb)
        if data and data.groupId then
            TriggerServerEvent('sxAdmin:deleteGroup', data)
        end
        cb({ ok = true })
    end)

    RegisterNUICallback('createGroup', function(data, cb)
        if data and data.name then
            TriggerServerEvent('sxAdmin:createGroup', data)
        end
        cb({ ok = true })
    end)

    RegisterNUICallback('updateGroup', function(data, cb)
        if data and data.id then
            TriggerServerEvent('sxAdmin:updateGroup', data)
        end
        cb({ ok = true })
    end)

    RegisterNUICallback('resetTerritoryInfluence', function(data, cb)
        if data and data.territoryId then
            TriggerServerEvent('sxAdmin:resetTerritoryInfluence', data)
        end
        cb({ ok = true })
    end)

    RegisterNUICallback('teleportToCoords', function(coords, cb)
        if coords and coords.x and coords.y and coords.z then
            local ped = PlayerPedId()
            DoScreenFadeOut(500)
            while not IsScreenFadedOut() do
                Wait(0)
            end
            SetEntityCoords(ped, coords.x, coords.y, coords.z + 1.0, false, false, false, true)
            Wait(500)
            DoScreenFadeIn(500)
        end
        cb({ ok = true })
    end)

    RegisterNUICallback('getCurrentCoords', function(_, cb)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        cb({ x = coords.x, y = coords.y, z = coords.z })
    end)

    RegisterNUICallback('createTerritory', function(data, cb)
        if data and data.label and data.coords and #data.coords >= 3 then
            TriggerServerEvent('sxGroup:RegisterTerritory', data)
        end
        cb({ ok = true })
    end)

    RegisterNUICallback('getAdminLabs', function(_, cb)
        local labs = TriggerServerCallback('sxAdmin:getLabs')
        cb(labs or {})
    end)

    RegisterNUICallback('createLaboratory', function(data, cb)
        if data and data.label and data.type and data.coords then
            TriggerServerEvent('sxGroup:RegisterLaboratory', data)
        end
        cb({ ok = true })
    end)
end

function SX.Admin:Think(lp)
end
