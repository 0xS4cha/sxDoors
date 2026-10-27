SX.Admin = {}
SX.Modules:Register("Admin", 20)

local function adminCallback(name, handler)
    RegisterServerCallback(name, function(source, ...)
        if not Bridge.IsAdmin(source) then
            return { ok = false, error = 'no_permission' }
        end
        return handler(source, ...)
    end)
end

local function getAdminDoors()
    local list = {}
    for _, door in pairs(GetAllDoors()) do
        list[#list + 1] = door:toAdmin()
    end
    table.sort(list, function(a, b) return a.label:lower() < b.label:lower() end)
    return list
end

function SX.Admin:Initialize()
    RegisterServerCallback('sxDoors:isAdmin', function(source)
        return Bridge.IsAdmin(source)
    end)

    adminCallback('sxDoors:admin:getData', function()
        return {
            ok = true,
            doors = getAdminDoors(),
            activity = Activity.GetAll(),
            jobs = Bridge.GetJobs(),
            framework = Bridge.Name,
            storage = Storage.Name,
            settings = {
                pinMinLength = Config.Pin.minLength,
                pinMaxLength = Config.Pin.maxLength,
                defaultDistance = Config.Interaction.defaultDistance,
                persistState = Config.PersistState,
                lockpick = Config.Lockpick.enabled,
            },
        }
    end)

    adminCallback('sxDoors:admin:create', function(source, payload)
        local door, err = CreateDoor(payload, source)
        if not door then return { ok = false, error = err } end

        Bridge.Notify(source, GetPhrase('notify_door_created', door.label), 'success')
        return { ok = true, door = door:toAdmin() }
    end)

    adminCallback('sxDoors:admin:update', function(source, id, payload)
        local door, err = UpdateDoor(id, payload, source)
        if not door then return { ok = false, error = err } end

        Bridge.Notify(source, GetPhrase('notify_door_updated', door.label), 'success')
        return { ok = true, door = door:toAdmin() }
    end)

    adminCallback('sxDoors:admin:delete', function(source, id)
        local door = GetDoorFromId(id)
        if not door or not DeleteDoor(id, source) then return { ok = false, error = 'not_found' } end

        Bridge.Notify(source, GetPhrase('notify_door_deleted', door.label), 'info')
        return { ok = true }
    end)

    adminCallback('sxDoors:admin:setState', function(source, id, locked)
        local door = GetDoorFromId(id)
        if not door then return { ok = false, error = 'not_found' } end

        door:setState(locked == true, source, 'admin')
        return { ok = true, locked = door.locked }
    end)

    adminCallback('sxDoors:admin:resetStates', function(source)
        local count = 0
        for _, door in pairs(GetAllDoors()) do
            if door:setState(door.defaultLocked, source, 'admin') then
                count = count + 1
            end
        end

        Bridge.Notify(source, GetPhrase('notify_doors_reset', count), 'info')
        return { ok = true, count = count }
    end)
end
