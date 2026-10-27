SX.Lockpick = {}
SX.Modules:Register("Lockpick", 30)

local Lockpicking = false

local ANIM_DICT = 'mini@safe_cracking'
local ANIM_NAME = 'idle_base'

local function loadDict(dict)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
end

---Lockpicks the closest lockpickable door, returns false when no door can be lockpicked
function SX.Lockpick:Start()
    if Lockpicking or not Config.Lockpick.enabled then return false end

    local door = SX.Doors:GetClosest(3.0)
    if not door or not door.lockpick or not door.locked then
        Bridge.Notify(GetPhrase('notify_no_lockpickable_door'), 'error')
        return false
    end

    Lockpicking = true

    CreateThread(function()
        local start = TriggerServerCallback('sxDoors:lockpick:start', door.id)
        if not start or not start.ok then
            Bridge.Notify(GetPhrase('reason_' .. tostring(start and start.reason or 'timeout')), 'error')
            Lockpicking = false
            return
        end

        local ped = PlayerPedId()
        local origin = GetEntityCoords(ped)
        loadDict(ANIM_DICT)
        TaskTurnPedToFaceCoord(ped, door.vector.x, door.vector.y, door.vector.z, 600)
        Wait(600)
        TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 8.0, -8.0, -1, 1, 0.0, false, false, false)

        local endTime = GetGameTimer() + start.duration
        local cancelled = false

        while GetGameTimer() < endTime do
            local progress = 1.0 - (endTime - GetGameTimer()) / start.duration
            Bridge.ShowHelp(GetPhrase('lockpick_progress', math.floor(progress * 100)))

            if #(GetEntityCoords(ped) - origin) > 1.0 or IsPedRagdoll(ped) or IsControlJustPressed(0, 194) then
                cancelled = true
                break
            end
            Wait(0)
        end

        ClearPedTasks(ped)
        RemoveAnimDict(ANIM_DICT)

        if cancelled then
            Bridge.Notify(GetPhrase('notify_lockpick_cancelled'), 'error')
        else
            local result = TriggerServerCallback('sxDoors:lockpick:finish', door.id)
            if result and result.ok then
                Bridge.Notify(GetPhrase('notify_lockpick_success'), 'success')
            else
                Bridge.Notify(GetPhrase('reason_' .. tostring(result and result.reason or 'timeout')), 'error')
            end
        end

        Lockpicking = false
    end)

    return true
end

function SX.Lockpick:IsBusy()
    return Lockpicking
end

function SX.Lockpick:Initialize()
    RegisterNetEvent('sxDoors:lockpick:use', function()
        self:Start()
    end)
end
