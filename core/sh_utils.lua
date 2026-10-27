function GetSexFromModel(model)
    local hash = GetSafeHashKey(model)
    if hash == GetHashKey("mp_m_freemode_01") then
        return 0
    elseif hash == GetHashKey("mp_f_freemode_01") then
        return 1
    else
        return 2
    end
end

function GetGridZoneId(x, y)
    local min = -8000
    local max = 8000
    local step = (max - min) / 32 -- 500

    local xIdx = math.floor((x - min) / step)
    local yIdx = math.floor((y - min) / step)

    return xIdx + (yIdx * 100)
end

function GetGridsSurroundingPosition(pos)
    local grids = {}
    local offsets = { -75, 0, 75 }

    for i = 1, 3 do
        for j = 1, 3 do
            local x = pos.x + offsets[i]
            local y = pos.y + offsets[j]
            grids[GetGridZoneId(x, y)] = true
        end
    end

    return grids
end

function TeleportTopCoords(pos, ent, trustPos)
    if not pos or not pos.x or not pos.y or not pos.z or (ent and not DoesEntityExist(ent)) then return true end
    local x, y, z = pos.x, pos.y, pos.z + 1.0
    ent = ent or GetPlayerPed(-1)

    RequestCollisionAtCoord(x, y, z)

    local tempTimer = GetGameTimer()
    while not IsNewLoadSceneLoaded() do
        if GetGameTimer() - tempTimer > 3000 then
            break
        end

        Citizen.Wait(0)
    end

    SetEntityCoordsNoOffset(ent, x, y, z)

    tempTimer = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ent) do
        if GetGameTimer() - tempTimer > 3000 then
            break
        end

        Citizen.Wait(0)
    end

    local foundNewZ, newZ
    if not trustPos then
        foundNewZ, newZ = GetGroundZCoordWithOffsets(x, y, z)
        tempTimer = GetGameTimer()
        while not foundNewZ do
            z = z + 10.0
            foundNewZ, newZ = GetGroundZCoordWithOffsets(x, y, z)
            Wait(0)

            if GetGameTimer() - tempTimer > 2000 then
                break
            end
        end
    end

    LastCoords = vector3(x, y, foundNewZ and newZ or z)
    SetEntityCoordsNoOffset(ent, x, y, foundNewZ and newZ or z)

    if type(pos) ~= "vector3" and pos.w then SetEntityHeading(ent, pos.w) end
    return true
end

if IsDuplicityVersion() then
    function Notify(source, message)
        TriggerClientEvent("esx:showNotification", source, message)
    end

    function GetItemLabel(item)
        return ESX.GetItemLabel(item) or item
    end
else
    function ShowNotification(message)
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end

    function ShowHelpNotification(message)
        BeginTextCommandDisplayHelp("STRING")
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandDisplayHelp(0, false, true, -1)
    end
end
