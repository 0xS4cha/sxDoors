local function serialize(door)
    if not door then return nil end

    return {
        id = door.id,
        label = door.label,
        type = door.type,
        coords = door.coords,
        distance = door.distance,
        entities = door.entities,
        locked = door.locked,
        lockpick = door.lockpick,
        hasPin = door.hasPin,
    }
end

exports("GetDoor", function(id)
    return serialize(SX.Doors:Get(id))
end)

exports("GetDoors", function()
    local list = {}
    for _, door in pairs(SX.Doors:GetAll()) do
        list[#list + 1] = serialize(door)
    end
    return list
end)

exports("GetClosestDoor", function(maxDistance)
    local door, distance = SX.Doors:GetClosest(maxDistance)
    return serialize(door), distance
end)

exports("IsDoorLocked", function(id)
    local door = SX.Doors:Get(id)
    if not door then return nil end
    return door.locked
end)

exports("UseDoor", function(id)
    return SX.Doors:Use(id)
end)

exports("ToggleClosestDoor", function(maxDistance)
    local door = SX.Doors:GetClosest(maxDistance or 3.0)
    if not door then return false end
    return SX.Doors:Use(door.id)
end)

exports("LockpickClosestDoor", function()
    return SX.Lockpick:Start()
end)

exports("OpenAdminPanel", function()
    CreateThread(function()
        SX.Admin:Open()
    end)
end)

exports("ClosePanel", function()
    SX.UI:Close()
end)

exports("IsPanelOpen", function()
    return SX.UI:IsOpen()
end)
