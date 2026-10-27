SX.Lockpick = {}
SX.Modules:Register("Lockpick", 30)

local Pending = {}

function LockpickDoor(source, id, skipItem)
    local door = GetDoorFromId(id)
    if not door then return false, 'not_found' end
    if not door.lockpick then return false, 'not_lockpickable' end
    if not door.locked then return false, 'already_unlocked' end
    if not IsPlayerNearDoor(source, door) then return false, 'too_far' end

    local item = Config.Lockpick.item
    local useItem = not skipItem and item and Bridge.IsESX()
    if useItem and not Bridge.HasItem(source, item) then
        return false, 'missing_item'
    end

    if useItem and math.random(100) <= Config.Lockpick.breakChance then
        Bridge.RemoveItem(source, item, 1)
        Bridge.Notify(source, GetPhrase('notify_lockpick_broken'), 'error')
    end

    if math.random(100) > Config.Lockpick.successChance then
        return false, 'lockpick_failed'
    end

    door:setState(false, source, 'lockpick')
    return true
end

function SX.Lockpick:Initialize()
    if not Config.Lockpick.enabled then return end

    RegisterServerCallback('sxDoors:lockpick:start', function(source, id)
        local door = GetDoorFromId(id)
        if not door or not door.lockpick or not door.locked then return { ok = false, reason = 'not_lockpickable' } end
        if not IsPlayerNearDoor(source, door) then return { ok = false, reason = 'too_far' } end

        Pending[source] = { id = id, time = GetGameTimer() }
        return { ok = true, duration = Config.Lockpick.duration }
    end)

    RegisterServerCallback('sxDoors:lockpick:finish', function(source, id)
        local pending = Pending[source]
        Pending[source] = nil

        if not pending or pending.id ~= id or GetGameTimer() - pending.time < Config.Lockpick.duration - 500 then
            return { ok = false, reason = 'denied' }
        end

        local ok, reason = LockpickDoor(source, id)
        return { ok = ok, reason = reason }
    end)

    if Config.Lockpick.item then
        Bridge.RegisterUsableItem(Config.Lockpick.item, function(source)
            TriggerClientEvent('sxDoors:lockpick:use', source)
        end)
    end

    AddEventHandler('playerDropped', function()
        Pending[source] = nil
    end)
end
