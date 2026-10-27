local function serialize(door)
    return door and door:toExport() or nil
end

exports("GetDoor", function(id)
    return serialize(GetDoorFromId(id))
end)

exports("GetDoors", function()
    local list = {}
    for _, door in pairs(GetAllDoors()) do
        list[#list + 1] = door:toExport()
    end
    return list
end)

exports("GetClosestDoor", function(coords, maxDistance)
    local door, distance = GetClosestDoorFromCoords(coords, maxDistance)
    return serialize(door), distance
end)

exports("IsDoorLocked", function(id)
    local door = GetDoorFromId(id)
    if not door then return nil end
    return door:isLocked()
end)

exports("SetDoorState", function(id, locked, source)
    local door = GetDoorFromId(id)
    if not door then return false end
    door:setState(locked == true, source, 'export')
    return true
end)

exports("ToggleDoor", function(id, source)
    local door = GetDoorFromId(id)
    if not door then return nil end
    door:setState(not door.locked, source, 'export')
    return door.locked
end)

exports("CanPlayerUseDoor", function(source, id, pin)
    local door = GetDoorFromId(id)
    if not door then return false, 'not_found' end
    return CanPlayerUseDoor(source, door, pin)
end)

exports("CreateDoor", function(data)
    local door, err = CreateDoor(data)
    return door and door.id or nil, err
end)

exports("UpdateDoor", function(id, data)
    local door, err = UpdateDoor(id, data)
    return door ~= nil, err
end)

exports("SetDoorAccess", function(id, access)
    local door, err = UpdateDoor(id, { access = access })
    return door ~= nil, err
end)

exports("DeleteDoor", function(id)
    return DeleteDoor(id)
end)

exports("LockpickDoor", function(source, id, skipItem)
    return LockpickDoor(source, id, skipItem)
end)

exports("GetActivity", function()
    return Activity.GetAll()
end)

exports("IsAdmin", function(source)
    return Bridge.IsAdmin(source)
end)
