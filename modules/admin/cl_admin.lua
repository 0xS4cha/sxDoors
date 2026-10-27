SX.Admin = {}
SX.Modules:Register("Admin", 20)

local Picking = false
local DebugEnabled = false

local CONTROL_SELECT = 38
local CONTROL_CONFIRM = 191
local CONTROL_CANCEL = 194

local function rotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function raycastObject(distance)
    local camCoords = GetGameplayCamCoord()
    local destination = camCoords + rotationToDirection(GetGameplayCamRot(2)) * distance
    local handle = StartExpensiveSynchronousShapeTestLosProbe(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, 16, PlayerPedId(), 4)
    local _, hit, endCoords, _, entity = GetShapeTestResult(handle)

    if hit == 1 and entity and entity ~= 0 and GetEntityType(entity) == 3 then
        return entity, endCoords
    end

    return nil, hit == 1 and endCoords or nil
end

local function describeEntity(entity)
    local coords = GetEntityCoords(entity)
    return {
        model = GetEntityModel(entity),
        coords = { x = coords.x, y = coords.y, z = coords.z },
        heading = GetEntityHeading(entity),
    }
end

local function drawMarkerOn(entity, r, g, b)
    local coords = GetEntityCoords(entity)
    DrawMarker(0, coords.x, coords.y, coords.z + 1.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, r, g, b, 200, true, true, 2, false, nil, nil, false)
end

local function teleport(coords)
    local ped = PlayerPedId()
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    Wait(400)
    DoScreenFadeIn(400)
end


function SX.Admin:StartPicker(max)
    if Picking then return end
    Picking = true
    max = math.min(math.max(tonumber(max) or 1, 1), 4)

    SX.UI:Hide()

    CreateThread(function()
        local selected = {}
        local result = nil
        local hovered = nil

        while Picking do
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)

            local entity, hitCoords = raycastObject(15.0)

            if hovered and hovered ~= entity then
                SetEntityDrawOutline(hovered, false)
            end
            hovered = entity

            if entity then
                SetEntityDrawOutlineColor(255, 255, 255, 255)
                SetEntityDrawOutlineShader(1)
                SetEntityDrawOutline(entity, true)
            elseif hitCoords then
                DrawMarker(28, hitCoords.x, hitCoords.y, hitCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.05, 0.05, 0.05, 255, 80, 80, 180, false, false, 2, false, nil, nil, false)
            end

            for _, selectedEntity in ipairs(selected) do
                if DoesEntityExist(selectedEntity) then
                    drawMarkerOn(selectedEntity, 52, 211, 153)
                end
            end

            Bridge.ShowHelp(GetPhrase('picker_help', #selected, max))

            if entity and IsControlJustPressed(0, CONTROL_SELECT) then
                local index = nil
                for i, selectedEntity in ipairs(selected) do
                    if selectedEntity == entity then index = i break end
                end

                if index then
                    table.remove(selected, index)
                elseif #selected < max then
                    selected[#selected + 1] = entity
                end
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
            end

            if IsControlJustPressed(0, CONTROL_CONFIRM) and #selected > 0 then
                local entities = {}
                for _, selectedEntity in ipairs(selected) do
                    if DoesEntityExist(selectedEntity) then
                        entities[#entities + 1] = describeEntity(selectedEntity)
                    end
                end
                result = { entities = entities, coords = Utils.GetCenter(entities) }
                Picking = false
            elseif IsControlJustPressed(0, CONTROL_CANCEL) then
                result = { cancelled = true }
                Picking = false
            end

            Wait(0)
        end

        if hovered and DoesEntityExist(hovered) then
            SetEntityDrawOutline(hovered, false)
        end

        SX.UI:Send('pickerResult', result or { cancelled = true })
        if SX.UI:IsOpen() then
            SX.UI:Show()
        end
    end)
end

function SX.Admin:IsPicking()
    return Picking
end

function SX.Admin:Highlight(id, duration)
    local door = SX.Doors:Get(id)
    if not door then return end

    CreateThread(function()
        local endTime = GetGameTimer() + (duration or 6000)
        local entities = {}

        while GetGameTimer() < endTime do
            for index, data in ipairs(door.entities) do
                local entity = entities[index]
                if not entity or not DoesEntityExist(entity) then
                    entity = GetClosestObjectOfType(data.coords.x, data.coords.y, data.coords.z, 1.5, data.model, false, false, false)
                    entities[index] = entity ~= 0 and entity or nil
                end

                if entities[index] then
                    SetEntityDrawOutlineColor(52, 211, 153, 255)
                    SetEntityDrawOutline(entities[index], true)
                end
            end

            DrawMarker(0, door.vector.x, door.vector.y, door.vector.z + 1.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 52, 211, 153, 200, true, true, 2, false, nil, nil, false)
            Wait(0)
        end

        for _, entity in pairs(entities) do
            if DoesEntityExist(entity) then
                SetEntityDrawOutline(entity, false)
            end
        end
    end)
end


local function debugThread()
    while DebugEnabled do
        local coords = GetEntityCoords(PlayerPedId())

        for _, door in pairs(SX.Doors:GetAll()) do
            if #(coords - door.vector) < 25.0 then
                local color = door.locked and { 244, 63, 94 } or { 52, 211, 153 }
                DrawMarker(28, door.vector.x, door.vector.y, door.vector.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, door.distance * 2, door.distance * 2, door.distance * 2, color[1], color[2], color[3], 25, false, false, 2, false, nil, nil, false)

                SetDrawOrigin(door.vector.x, door.vector.y, door.vector.z + 0.6, 0)
                SetTextScale(0.0, 0.28)
                SetTextFont(0)
                SetTextCentre(true)
                SetTextOutline()
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName(('~b~%s~w~~n~%s~n~%s - %s'):format(door.id, door.label, door.type, door.locked and '~r~locked' or '~g~unlocked'))
                EndTextCommandDisplayText(0.0, 0.0)
                ClearDrawOrigin()
            end
        end

        Wait(0)
    end
end


local function adminCall(name, ...)
    return TriggerServerCallback(name, ...) or { ok = false, error = 'timeout' }
end

function SX.Admin:Open()
    local isAdmin = TriggerServerCallback('sxDoors:isAdmin')
    if isAdmin then
        SX.UI:Open('admin')
    else
        Bridge.Notify(GetPhrase('admin_no_permission'), 'error')
    end
end

function SX.Admin:Initialize()
    RegisterCommand('sxdoors', function()
        self:Open()
    end, false)

    RegisterKeyMapping('sxdoors', GetPhrase('keymap_admin_panel'), 'keyboard', '')

    RegisterCommand('sxdoors_debug', function()
        if not TriggerServerCallback('sxDoors:isAdmin') then
            Bridge.Notify(GetPhrase('admin_no_permission'), 'error')
            return
        end

        DebugEnabled = not DebugEnabled
        Bridge.Notify(GetPhrase(DebugEnabled and 'notify_debug_on' or 'notify_debug_off'), 'info')
        if DebugEnabled then CreateThread(debugThread) end
    end, false)

    RegisterNUICallback('getAdminData', function(_, cb)
        cb(adminCall('sxDoors:admin:getData'))
    end)

    RegisterNUICallback('createDoor', function(data, cb)
        cb(adminCall('sxDoors:admin:create', data))
    end)

    RegisterNUICallback('updateDoor', function(data, cb)
        cb(adminCall('sxDoors:admin:update', data and data.id, data))
    end)

    RegisterNUICallback('deleteDoor', function(data, cb)
        cb(adminCall('sxDoors:admin:delete', data and data.id))
    end)

    RegisterNUICallback('setDoorState', function(data, cb)
        cb(adminCall('sxDoors:admin:setState', data and data.id, data and data.locked))
    end)

    RegisterNUICallback('resetDoorStates', function(_, cb)
        cb(adminCall('sxDoors:admin:resetStates'))
    end)

    RegisterNUICallback('startPicker', function(data, cb)
        self:StartPicker(data and data.max)
        cb({ ok = true })
    end)

    RegisterNUICallback('getCurrentCoords', function(_, cb)
        local coords = GetEntityCoords(PlayerPedId())
        cb({ x = coords.x, y = coords.y, z = coords.z })
    end)

    RegisterNUICallback('teleportToDoor', function(data, cb)
        cb({ ok = true })
        if data and data.coords then
            SX.UI:Close()
            teleport(data.coords)
        end
    end)

    RegisterNUICallback('highlightDoor', function(data, cb)
        cb({ ok = true })
        if data and data.id then
            SX.UI:Close()
            self:Highlight(data.id)
        end
    end)
end
