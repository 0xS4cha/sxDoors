SX.Doors = {}
SX.Modules:Register("Doors", 10)

local DoorsList = {}
local DoorsLoaded = false
local Cooldowns = {}
local PinAttempts = {}

local MAX_ENTITIES = 4

------------------------------------------------------------------------
-- Door class
------------------------------------------------------------------------

Door = newClass()

function Door:init(id, data, locked)
    self.id = id
    self.autoLockToken = 0
    self.uses = 0
    self.lastUse = nil
    self:apply(data)

    if locked == nil or not Config.PersistState then
        self.locked = self.defaultLocked
    else
        self.locked = locked
    end
end

-- data must be sanitized with SanitizeDoorData before
function Door:apply(data)
    self.label = data.label
    self.type = data.type
    self.entities = data.entities
    self.coords = data.coords
    self.distance = data.distance
    self.defaultLocked = data.defaultLocked
    self.autoLock = data.autoLock
    self.lockpick = data.lockpick
    self.hidePrompt = data.hidePrompt
    self.pin = data.pin
    self.access = data.access
    self.createdAt = data.createdAt or os.time()
    self.updatedAt = data.updatedAt or os.time()
end

function Door:toData()
    return {
        type = self.type,
        entities = self.entities,
        coords = self.coords,
        distance = self.distance,
        defaultLocked = self.defaultLocked,
        autoLock = self.autoLock,
        lockpick = self.lockpick,
        hidePrompt = self.hidePrompt,
        pin = self.pin,
        access = self.access,
        createdAt = self.createdAt,
        updatedAt = self.updatedAt,
    }
end

-- What every client receives: no pin and no access list
function Door:toClient()
    return {
        id = self.id,
        label = self.label,
        type = self.type,
        entities = self.entities,
        coords = self.coords,
        distance = self.distance,
        locked = self.locked,
        lockpick = self.lockpick,
        hidePrompt = self.hidePrompt,
        hasPin = self.pin ~= nil,
    }
end

function Door:toAdmin()
    local data = self:toData()
    data.id = self.id
    data.label = self.label
    data.locked = self.locked
    data.uses = self.uses
    data.lastUse = self.lastUse
    data.hasPin = self.pin ~= nil
    return data
end

function Door:toExport()
    local data = self:toClient()
    data.defaultLocked = self.defaultLocked
    data.autoLock = self.autoLock
    data.access = self.access
    data.uses = self.uses
    return data
end

function Door:save()
    Storage.Save(self.id, self.label, self:toData(), self.locked)
end

function Door:isLocked()
    return self.locked
end

---@param locked boolean
---@param source number|nil player that changed the state, nil for the server
---@param reason string|nil toggle, lockpick, autolock, admin, export
function Door:setState(locked, source, reason)
    locked = locked == true
    if self.locked == locked then return false end

    self.locked = locked
    self.autoLockToken = self.autoLockToken + 1
    TriggerClientEvent('sxDoors:setState', -1, self.id, locked)

    if Config.PersistState then
        Storage.SaveState(self.id, locked)
    end

    if not locked and self.autoLock > 0 then
        local token = self.autoLockToken
        SetTimeout(self.autoLock * 1000, function()
            if DoorsList[self.id] == self and self.autoLockToken == token and not self.locked then
                self:setState(true, nil, 'autolock')
            end
        end)
    end

    if source and source > 0 then
        self.uses = self.uses + 1
        self.lastUse = { time = os.time(), player = Bridge.GetPlayerName(source) }
    end

    TriggerEvent('sxDoors:stateChanged', self.id, locked, source, reason or 'export')

    if reason ~= 'autolock' then
        Activity.Add(reason == 'lockpick' and 'lockpick' or (locked and 'lock' or 'unlock'), self, source)
    end

    return true
end

------------------------------------------------------------------------
-- Validation
------------------------------------------------------------------------

local function sanitizeEntities(entities)
    local result = {}
    if type(entities) ~= 'table' then return result end

    for _, entity in ipairs(entities) do
        local model = Utils.ToModel(entity.model)
        if model and type(entity.coords) == 'table' then
            result[#result + 1] = {
                model = model,
                coords = Utils.ToCoords(entity.coords),
                heading = Utils.Round(entity.heading or 0.0),
            }
        end
        if #result >= MAX_ENTITIES then break end
    end

    return result
end

local function sanitizeAccess(access)
    access = type(access) == 'table' and access or {}
    local jobs = {}

    if type(access.jobs) == 'table' then
        for key, value in pairs(access.jobs) do
            -- Accepts { police = 0 }, { "police" } and { { name = "police", grade = 0 } }
            local name, grade
            if type(key) == 'string' then
                name, grade = key, value
            elseif type(value) == 'table' then
                name, grade = value.name, value.grade
            else
                name, grade = value, 0
            end

            name = Utils.Trim(tostring(name or ''))
            if name ~= '' then
                jobs[name] = math.max(0, math.floor(tonumber(grade) or 0))
            end
        end
    end

    return {
        jobs = jobs,
        aces = Utils.StringList(access.aces, 32),
        identifiers = Utils.StringList(access.identifiers, 128),
        items = Utils.StringList(access.items, 32),
    }
end

---Validates any door payload coming from the admin panel or an export
---@return table|nil data, string|nil error
function SanitizeDoorData(input, current)
    if type(input) ~= 'table' then return nil, 'invalid_data' end
    current = current or {}

    local label = Utils.Trim(input.label or current.label or '')
    if label == '' then return nil, 'missing_label' end
    if #label > 100 then label = label:sub(1, 100) end

    local entities = input.entities and sanitizeEntities(input.entities) or current.entities
    if not entities or #entities == 0 then return nil, 'missing_entities' end

    local doorType = input.type or current.type
    if not Utils.IsDoorType(doorType) then
        doorType = #entities >= 2 and 'double' or 'single'
    end

    local coords = input.coords and Utils.ToCoords(input.coords) or current.coords or Utils.ToCoords(Utils.GetCenter(entities))

    local pin = current.pin
    if input.pin ~= nil then
        pin = Utils.Trim(tostring(input.pin))
        if pin == '' or pin == '0' then
            pin = nil
        elseif not pin:match('^%d+$') or #pin < Config.Pin.minLength or #pin > Config.Pin.maxLength then
            return nil, 'invalid_pin'
        end
    end

    local function pick(key, default)
        if input[key] ~= nil then return input[key] end
        if current[key] ~= nil then return current[key] end
        return default
    end

    return {
        label = label,
        type = doorType,
        entities = entities,
        coords = coords,
        distance = math.min(math.max(tonumber(pick('distance', Config.Interaction.defaultDistance)) or 2.0, 0.5), 30.0),
        defaultLocked = pick('defaultLocked', true) == true,
        autoLock = math.min(math.max(math.floor(tonumber(pick('autoLock', 0)) or 0), 0), 3600),
        lockpick = pick('lockpick', false) == true,
        hidePrompt = pick('hidePrompt', false) == true,
        pin = pin,
        access = input.access and sanitizeAccess(input.access) or current.access or sanitizeAccess({}),
        createdAt = current.createdAt,
        updatedAt = os.time(),
    }
end

------------------------------------------------------------------------
-- Registry
------------------------------------------------------------------------

function GetDoorFromId(id)
    return DoorsList[id]
end

function GetAllDoors()
    return DoorsList
end

function AreDoorsLoaded()
    return DoorsLoaded
end

function GenerateDoorId()
    local id
    repeat
        id = 'DOOR-' .. Generate.Code({ includeNumbers = true, includeLetters = true, length = 6 }):upper()
    until not DoorsList[id]
    return id
end

---@return Door|nil door, string|nil error
function CreateDoor(input, source)
    local data, err = SanitizeDoorData(input)
    if not data then return nil, err end

    local id = input.id and tostring(input.id) or GenerateDoorId()
    if DoorsList[id] then return nil, 'duplicate_id' end

    local door = Door(id, data)
    DoorsList[id] = door
    door:save()

    TriggerClientEvent('sxDoors:upsert', -1, door:toClient())
    TriggerEvent('sxDoors:doorCreated', id, source)
    Activity.Add('create', door, source)

    return door
end

---@return Door|nil door, string|nil error
function UpdateDoor(id, input, source)
    local door = DoorsList[id]
    if not door then return nil, 'not_found' end

    local current = door:toData()
    current.label = door.label

    local data, err = SanitizeDoorData(input, current)
    if not data then return nil, err end

    local defaultChanged = data.defaultLocked ~= door.defaultLocked
    door:apply(data)
    door:save()

    TriggerClientEvent('sxDoors:upsert', -1, door:toClient())
    TriggerEvent('sxDoors:doorUpdated', id, source)
    Activity.Add('update', door, source)

    if defaultChanged and door.locked ~= door.defaultLocked then
        door:setState(door.defaultLocked, source, 'admin')
    end

    return door
end

function DeleteDoor(id, source)
    local door = DoorsList[id]
    if not door then return false end

    DoorsList[id] = nil
    door.autoLockToken = door.autoLockToken + 1
    Storage.Delete(id)

    TriggerClientEvent('sxDoors:remove', -1, id)
    TriggerEvent('sxDoors:doorDeleted', id, source)
    Activity.Add('delete', door, source)

    return true
end

function GetClosestDoorFromCoords(coords, maxDistance)
    local closest, closestDistance = nil, maxDistance or math.huge
    coords = Utils.ToVector(coords)

    for _, door in pairs(DoorsList) do
        local distance = #(coords - Utils.ToVector(door.coords))
        if distance < closestDistance then
            closest, closestDistance = door, distance
        end
    end

    return closest, closest and closestDistance or nil
end

------------------------------------------------------------------------
-- Access
------------------------------------------------------------------------

local function hasAccessRules(access)
    return next(access.jobs) ~= nil or #access.aces > 0 or #access.identifiers > 0 or #access.items > 0
end

local function matchesAccess(source, access)
    local jobName, jobGrade = Bridge.GetJob(source)
    if jobName and access.jobs[jobName] and jobGrade >= access.jobs[jobName] then
        return true
    end

    for _, ace in ipairs(access.aces) do
        if IsPlayerAceAllowed(source, ace) then return true end
    end

    if #access.identifiers > 0 then
        local identifiers = Bridge.GetIdentifiers(source)
        for _, identifier in ipairs(access.identifiers) do
            if identifiers[identifier] then return true end
        end
    end

    for _, item in ipairs(access.items) do
        if Bridge.HasItem(source, item) then return true end
    end

    return false
end

local function isPinBlocked(source)
    local attempts = PinAttempts[source]
    return attempts and attempts.blockedUntil and attempts.blockedUntil > os.time()
end

local function registerWrongPin(source, door)
    local attempts = PinAttempts[source] or { count = 0 }
    attempts.count = attempts.count + 1

    if attempts.count >= Config.Pin.maxAttempts then
        attempts.count = 0
        attempts.blockedUntil = os.time() + Config.Pin.lockout
    end

    PinAttempts[source] = attempts
    Activity.Add('pin_failed', door, source)

    return Config.Pin.maxAttempts - attempts.count
end

---@return boolean allowed, string|nil reason
function CanPlayerUseDoor(source, door, pin)
    if Config.Admin.bypass and Bridge.IsAdmin(source) then return true end

    local rules = hasAccessRules(door.access)
    if not rules and not door.pin then return true end
    if rules and matchesAccess(source, door.access) then return true end

    if door.pin then
        if pin == nil then return false, 'pin_required' end
        if isPinBlocked(source) then return false, 'pin_blocked' end
        if tostring(pin) == door.pin then
            PinAttempts[source] = nil
            return true
        end
        return false, 'pin_wrong'
    end

    return false, 'denied'
end

function IsPlayerNearDoor(source, door, tolerance)
    -- Without OneSync the server does not know the player position and cannot check it
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return true end

    local coords = GetEntityCoords(ped)
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then return true end

    return #(coords - Utils.ToVector(door.coords)) <= door.distance + (tolerance or Config.Interaction.serverTolerance)
end

local function isOnCooldown(source)
    local now = GetGameTimer()
    if Cooldowns[source] and now - Cooldowns[source] < Config.Interaction.cooldown then
        return true
    end
    Cooldowns[source] = now
    return false
end

------------------------------------------------------------------------
-- Loading
------------------------------------------------------------------------

local function loadDoors()
    Storage.Init()

    local count = 0
    for _, record in ipairs(Storage.LoadAll()) do
        local input = record.data
        input.label = record.label
        -- The stored pin is trusted even if Config.Pin lengths changed since
        local pin = input.pin
        input.pin = nil
        local data, err = SanitizeDoorData(input, { createdAt = input.createdAt, pin = pin })
        if data then
            data.updatedAt = input.updatedAt or data.updatedAt
            DoorsList[record.id] = Door(record.id, data, record.locked)
            count = count + 1
        else
            Logger:warn('DOORS', "Skipping door", record.id, err)
        end
    end

    DoorsLoaded = true
    Logger:info('DOORS', ("%d doors loaded"):format(count))
    TriggerClientEvent('sxDoors:sync', -1, SX.Doors:GetClientList())
end

function SX.Doors:GetClientList()
    local list = {}
    for _, door in pairs(DoorsList) do
        list[#list + 1] = door:toClient()
    end
    return list
end

function SX.Doors:Initialize()
    RegisterServerCallback('sxDoors:getDoors', function()
        while not DoorsLoaded do Wait(100) end
        return self:GetClientList()
    end)

    RegisterServerCallback('sxDoors:toggle', function(source, id, pin)
        local door = DoorsList[id]
        if not door then return { ok = false, reason = 'not_found' } end
        if isOnCooldown(source) then return { ok = false, reason = 'cooldown' } end
        if not IsPlayerNearDoor(source, door) then return { ok = false, reason = 'too_far' } end

        local allowed, reason = CanPlayerUseDoor(source, door, pin)
        if not allowed then
            local result = { ok = false, reason = reason }
            if reason == 'pin_wrong' then
                result.attemptsLeft = registerWrongPin(source, door)
                if result.attemptsLeft == Config.Pin.maxAttempts then
                    result.reason = 'pin_blocked'
                end
            elseif reason == 'denied' then
                Activity.Add('denied', door, source)
            end
            return result
        end

        door:setState(not door.locked, source, 'toggle')
        return { ok = true, locked = door.locked }
    end)

    AddEventHandler('playerDropped', function()
        Cooldowns[source] = nil
        PinAttempts[source] = nil
    end)

    AddEventHandler('onResourceStop', function(resource)
        if resource == GetCurrentResourceName() then
            Storage.Flush()
        end
    end)
end

function SX.Doors:InitializeAsync()
    loadDoors()
end

------------------------------------------------------------------------
-- Legacy import
------------------------------------------------------------------------

RegisterCommand('sxdoors_migrate', function(source)
    if source > 0 then return end

    CreateThread(function()
        local rows = Storage.LoadLegacy()
        if not rows then
            Logger:warn('MIGRATE', "No legacy `doors` table found (requires oxmysql)")
            return
        end

        local imported = 0
        for _, row in ipairs(rows) do
            local id = 'LEGACY-' .. tostring(row.id)
            if not DoorsList[id] then
                local ok, entities = pcall(json.decode, row.doors or '[]')
                local okJobs, jobs = pcall(json.decode, row.jobs or '{}')
                local okCoords, coords = pcall(json.decode, row.coords or 'null')
                local pin = tonumber(row.pin) or 0

                local door, err = CreateDoor({
                    id = id,
                    label = row.label ~= '' and row.label or id,
                    entities = ok and entities or {},
                    coords = okCoords and coords or nil,
                    distance = tonumber(row.distance),
                    pin = pin > 0 and tostring(pin) or nil,
                    -- The legacy status was true when the door was open
                    defaultLocked = not (tonumber(row.default_status) == 1),
                    access = { jobs = okJobs and jobs or {} },
                })

                if door then
                    imported = imported + 1
                else
                    Logger:warn('MIGRATE', "Door", row.id, "skipped:", err)
                end
            end
        end

        Logger:info('MIGRATE', ("%d legacy doors imported"):format(imported))
    end)
end, true)
