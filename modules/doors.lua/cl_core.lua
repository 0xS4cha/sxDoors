local Token = nil
TriggerEvent("core:RequestTokenAcces", "yCore", function(t)
    Token = t
end)


local doorsList = {}
local closetDoors = {}
local doorsInRange = {}
local isLoaded = nil

RegisterNetEvent('ESX:playerLoaded')
AddEventHandler('ESX:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
  isLoaded = true
  doorsList = TriggerServerCallbackSync("sxDoors:getDoors")
end)

Citizen.CreateThread(function()
    while isLoaded == nil do Wait(1) end
    while json.encode(doorsList) == '[]' do Wait(1) end
    while true do
        local pCoords = GetEntityCoords(PlayerPedId())
        for k, v in pairs(doorsList) do
            v.coords = vector3(v.coords.x, v.coords.y, v.coords.z)
            local dst = #(v.coords.xyz - pCoords)
            if dst < v.distance then
     
                closetDoors[k] = v
            else
                if closetDoors[k] ~= nil then
                    closetDoors[k] = nil
                end

                if dst <= 50.0 then
                    doorsInRange[k] = v
                else
                    if doorsInRange[k] ~= nil then
                        doorsInRange[k] = nil
                    end
                end
            end
        end

        Wait(500)
    end
end)

local function HasRequiredJob(jobList)
    if not jobList or next(jobList) == nil then
        return true
    end
    local playerJob = GetPlayer().Job
    return jobList[playerJob] == true
end

local function CheckPin(pin, cb)
    if not pin or pin == 0 then
        cb(true)
        return
    end

    AskEntry(function(results)
        if results and string.len(results) == 4 then
            results = tonumber(results)
            cb(results == pin)
        else
            cb(false)
        end
    end, "pin", 4)
end

Citizen.CreateThread(function()
    while true do
        local count = 0
        local playerCoords = GetEntityCoords(PlayerPedId())

        for k, v in pairs(closetDoors) do
            if #(playerCoords - v.coords.xyz) < v.distance then
                DrawLine(playerCoords, vector3(v.coords.x, v.coords.y, v.coords.z + 0.5), 255, 255, 255, 170)
                
                Utils.DrawSprite3d({
                    pos = vector3(v.coords.x, v.coords.y, v.coords.z),
                    textureDict = 'core_ui',
                    textureName = v.status and 'key_green' or 'key_red',
                    width = 0.0185,
                    height = 0.0333
                }, false)

                if IsControlJustPressed(0, 38) then
                    if HasRequiredJob(v.jobs) then
                        CheckPin(v.pin, function(pinOk)
                            if pinOk then
                                local players = {}
                                for _, id in pairs(GetActivePlayers()) do 
                                    table.insert(players, GetPlayerServerId(id))
                                end
                                TriggerServerEvent("sxDoors:ChangeDoorState", Token, k, not v.status, players)
                            end
                        end)
                    end
                end
                count = count + 1
            end
        end

        Wait(count > 0 and 1 or 500)
    end
end)

Citizen.CreateThread(function()
    while true do

        for k, v in pairs(doorsInRange) do
            for z,c in pairs(v.doors) do
                local entity = GetClosestObjectOfType(c.coords.x, c.coords.y, c.coords.z, 5.0, c.model, false, 0, 0)
 
                if not v.status then
                    SetEntityHeading(entity, c.heading)
                    FreezeEntityPosition(entity, true)
                else
                    FreezeEntityPosition(entity, false)
                end
            end
        end

        Wait(1500)
    end
end)

function changeDoorLockStatus(door, state)
    if #(doorsList[door].coords.xyz - GetEntityCoords(PlayerPedId())) < 2.5 then
        for i = 1, #doorsList[door].doors do
            local entity = GetClosestObjectOfType(doorsList[door].doors[i].coords.x, doorsList[door].doors[i].coords.y, doorsList[door].doors[i].coords.z, 5.0, doorsList[door].doors[i].model, false, 0, 0)
            if not state then
                SetEntityHeading(entity, doorsList[door].doors[i].heading)
                FreezeEntityPosition(entity, true)
            else
                FreezeEntityPosition(entity, false)
            end
        end
    end
end

RegisterNetEvent("sxDoors:ChangeDoorState")
AddEventHandler("sxDoors:ChangeDoorState", function(door, state)
    if doorsList ~= nil and doorsList[door] ~= nil then
        doorsList[door].status = state
        changeDoorLockStatus(door, state)
    end
end)