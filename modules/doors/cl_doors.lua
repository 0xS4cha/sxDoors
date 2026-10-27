SX.Doors = {}
SX.Modules:Register("Doors", 10)

local DoorsList = {}
local ClosestDoor = nil
local ClosestDistance = nil
local Busy = false
local Loaded = false

local INTERACT_COMMAND = 'sxdoors_interact'
local AUTOMATIC_TYPES = { sliding = true, garage = true }

------------------------------------------------------------------------
-- Door system
------------------------------------------------------------------------

local function getEntityHash(id, index)
    return joaat(('sxdoors:%s:%d'):format(id, index))
end

local function applyState(door)
    local state = door.locked and 1 or 0
    for _, hash in ipairs(door.hashes or {}) do
        DoorSystemSetDoorState(hash, state, false, false)
    end
end

local function unregisterDoor(door)
    for _, hash in ipairs(door.hashes or {}) do
        if IsDoorRegisteredWithSystem(hash) then
            RemoveDoorFromSystem(hash)
        end
    end
    door.hashes = nil
end

local function registerDoor(door)
    local existing = DoorsList[door.id]
    if existing then unregisterDoor(existing) end

    door.hashes = {}
    door.vector = vector3(door.coords.x, door.coords.y, door.coords.z)

    for index, entity in ipairs(door.entities) do
        local hash = getEntityHash(door.id, index)
        AddDoorToSystem(hash, entity.model, entity.coords.x, entity.coords.y, entity.coords.z, false, false, false)

        if AUTOMATIC_TYPES[door.type] then
            DoorSystemSetAutomaticRate(hash, Config.AutomaticRate, false, false)
            DoorSystemSetAutomaticDistance(hash, math.max(door.distance, 5.0), false, false)
        end

        -- Forces the door back to its closed position before applying the real state
        DoorSystemSetDoorState(hash, 4, false, false)
        door.hashes[#door.hashes + 1] = hash
    end

    DoorsList[door.id] = door
    applyState(door)
end

local function clearDoors()
    for _, door in pairs(DoorsList) do
        unregisterDoor(door)
    end
    DoorsList = {}
    ClosestDoor = nil
end

local function syncDoors(list)
    clearDoors()
    for _, door in ipairs(list or {}) do
        registerDoor(door)
    end
    Loaded = true
end

------------------------------------------------------------------------
-- Feedback
------------------------------------------------------------------------

local function playSound(name)
    local sound = Config.Interaction.sounds[name]
    if sound then
        PlaySoundFrontend(-1, sound.name, sound.set, true)
    end
end

local function playKeyAnimation()
    if not Config.Interaction.animation then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end

    local dict = 'anim@heists@keycard@'
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 1000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end

    TaskPlayAnim(ped, dict, 'exit', 8.0, -8.0, 800, 48, 0.0, false, false, false)
    RemoveAnimDict(dict)
end

local function getKeyLabel()
    local hash = (joaat(INTERACT_COMMAND) & 0xFFFFFFFF) | 0x80000000
    local label = GetControlInstructionalButton(0, hash, true)
    if label and label:sub(1, 2) == 't_' then
        return label:sub(3)
    end
    return Config.Interaction.key
end

local function drawText3D(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextScale(0.0, 0.32)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

------------------------------------------------------------------------
-- Interaction
------------------------------------------------------------------------

local function handleResult(door, result)
    if not result then
        Bridge.Notify(GetPhrase('notify_server_timeout'), 'error')
        return
    end

    if result.ok then
        playSound(result.locked and 'lock' or 'unlock')
        return
    end

    if result.reason ~= 'pin_required' and result.reason ~= 'cooldown' then
        playSound('denied')
        Bridge.Notify(GetPhrase('reason_' .. tostring(result.reason)), 'error')
    end
end

---Toggles a door, asking for the pin code when the server requires it
function SX.Doors:Use(id)
    local door = DoorsList[id]
    if not door or Busy then return false end
    Busy = true

    CreateThread(function()
        playKeyAnimation()
        local result = TriggerServerCallback('sxDoors:toggle', door.id)

        if result and result.reason == 'pin_required' then
            SX.UI:OpenKeypad(door)
        else
            handleResult(door, result)
        end

        Busy = false
    end)

    return true
end

---Sends a pin from the keypad, returns the server answer to the interface
function SX.Doors:SubmitPin(id, pin)
    local door = DoorsList[id]
    if not door then return { ok = false, reason = 'not_found' } end

    local result = TriggerServerCallback('sxDoors:toggle', door.id, pin)
    if result and result.ok then
        playSound(result.locked and 'lock' or 'unlock')
    elseif result and result.reason == 'pin_wrong' then
        playSound('denied')
    else
        handleResult(door, result)
    end

    return result or { ok = false, reason = 'timeout' }
end

function SX.Doors:GetClosest(maxDistance)
    local coords = GetEntityCoords(PlayerPedId())
    local closest, closestDistance = nil, maxDistance or math.huge

    for _, door in pairs(DoorsList) do
        local distance = #(coords - door.vector)
        if distance < closestDistance then
            closest, closestDistance = door, distance
        end
    end

    return closest, closest and closestDistance or nil
end

function SX.Doors:Get(id)
    return DoorsList[id]
end

function SX.Doors:GetAll()
    return DoorsList
end

function SX.Doors:IsLoaded()
    return Loaded
end

------------------------------------------------------------------------
-- Threads
------------------------------------------------------------------------

local function closestThread()
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        local closest, closestDistance = nil, math.huge

        for _, door in pairs(DoorsList) do
            local distance = #(coords - door.vector)
            if distance <= door.distance and distance < closestDistance then
                closest, closestDistance = door, distance
            end
        end

        ClosestDoor = closest
        ClosestDistance = closest and closestDistance or nil
        Wait(closest and 150 or 400)
    end
end

local function promptThread()
    local mode = Config.Interaction.prompt
    local keyLabel = getKeyLabel()
    local lastKeyRefresh = 0

    while true do
        local door = ClosestDoor
        if door and mode ~= 'none' and not door.hidePrompt and not SX.UI:IsOpen() then
            if GetGameTimer() - lastKeyRefresh > 5000 then
                keyLabel = getKeyLabel()
                lastKeyRefresh = GetGameTimer()
            end

            local state = door.locked and GetPhrase('prompt_locked') or GetPhrase('prompt_unlocked')
            local action = door.locked and GetPhrase('prompt_action_unlock') or GetPhrase('prompt_action_lock')

            if mode == 'help' then
                Bridge.ShowHelp(('%s~n~~INPUT_%X~ %s'):format(state, (joaat(INTERACT_COMMAND) & 0xFFFFFFFF) | 0x80000000, action))
            else
                drawText3D(door.vector, ('%s~n~~w~[~y~%s~w~] %s'):format(state, keyLabel, action))
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

function SX.Doors:Initialize()
    RegisterCommand(INTERACT_COMMAND, function()
        if ClosestDoor and not SX.UI:IsOpen() and not IsPauseMenuActive() then
            self:Use(ClosestDoor.id)
        end
    end, false)

    RegisterKeyMapping(INTERACT_COMMAND, GetPhrase('keymap_interact'), 'keyboard', Config.Interaction.key)

    RegisterNetEvent('sxDoors:sync', syncDoors)

    RegisterNetEvent('sxDoors:upsert', function(door)
        if not Loaded then return end
        registerDoor(door)
    end)

    RegisterNetEvent('sxDoors:remove', function(id)
        local door = DoorsList[id]
        if door then
            unregisterDoor(door)
            DoorsList[id] = nil
            if ClosestDoor and ClosestDoor.id == id then ClosestDoor = nil end
        end
    end)

    RegisterNetEvent('sxDoors:setState', function(id, locked)
        local door = DoorsList[id]
        if not door then return end

        door.locked = locked
        applyState(door)
        TriggerEvent('sxDoors:stateChanged', id, locked)
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then
            clearDoors()
        end
    end)
end

function SX.Doors:InitializeAsync()
    while not NetworkIsSessionStarted() do Wait(250) end

    while not Loaded do
        local list = TriggerServerCallback('sxDoors:getDoors')
        if list and not Loaded then
            syncDoors(list)
        elseif not Loaded then
            Wait(2000)
        end
    end

    CreateThread(closestThread)
    promptThread()
end
