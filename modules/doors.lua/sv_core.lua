local DoorsLis = {}

function GetDoorFromId(id)
    return DoorsLis[id]
end

function GetAllDoors()
    return DoorsLis
end

function RemoveDoor(id)
    DoorsLis[id] = nil
    return true
end


Door = newClass()

function Door:new(data)
    if not data.doors then return end
    local self = setmetatable({}, doors)
    self.id = data.id or Generate.Code({ includeNumbers = true, includeLetters = true, length = 6 })
    self.coords = data.coords or vector3(0.0, 0.0, 0.0)
    self.distance = data.distance or {}
    self.label = data.label or ""
    self.doors = data.doors or {}
    self.pin = data.pin or 0
    self.jobs = data.jobs or {}
    self.default_status = data.default_status or false
    self.status = self.default_status
    self.needSave = false
    self.coordsChanged = false
    self.doorsChanged = false
    self.jobsChanged = false
    self.distanceChanged = false
    self.labelChanged = false
    self.startChanged = false
    self.pinChanged = false
    self.default_statusChanged = false
    DoorsList[self.id] = self
    return self
end

function doors:setState(state)
    self.status = state
    return true
end

function doors:getState(state)
    return self.status
end

function doors:setLabel(label)
    self.label = label
    self.labelChanged = true
    self.needSave = true
    return true
end

function doors:getLabel()
    return self.label
end

function doors:setDistance(distance)
    self.distance = distance
    self.distanceChanged = true
    self.needSave = true
    return true
end

function doors:getDistance()
    return self.distance
end

function doors:setJobs(jobs)
    self.jobs = jobs
    self.jobsChanged = true
    self.needSave = true
    return true
end

function doors:getJobs()
    return self.jobs
end

function doors:setNeedSave(needSave)
    self.needSave = needSave
end

function doors:getNeedSave()
    return self.needSave
end


function doors:saveDoor()
    local updates = {}
    local params = {}

    if self.coordsChanged then
        table.insert(updates, "coords = ?")
        table.insert(params, json.encode(self.coords))
    end

    if self.doorsChanged then
        table.insert(updates, "doors = ?")
        table.insert(params, json.encode(self.doors))
    end

    if self.jobsChanged then
        table.insert(updates, "jobs = ?")
        table.insert(params, json.encode(self.jobs))
    end

    if self.distanceChanged then
        table.insert(updates, "distance = ?")
        table.insert(params, self.distance)
    end

    if self.labelChanged then
        table.insert(updates, "label = ?")
        table.insert(params, self.label)
    end

    if self.pinChanged then
        table.insert(updates, "pin = ?")
        table.insert(params, self.pin)
    end

    if self.default_statusChanged then
        table.insert(updates, "default_status = ?")
        table.insert(params, self.default_status)
    end

    self:setNeedSave(false)
    self.coordsChanged = false
    self.doorsChanged = false
    self.jobsChanged = false
    self.distanceChanged = false
    self.labelChanged = false
    self.startChanged = false
    self.pinChanged = false
    self.default_statusChanged = false

    if #updates > 0 then
        table.insert(params, self.id)
        local query = ("UPDATE doors SET %s WHERE id = ?"):format(table.concat(updates, ", "))
        MySQL.Async.execute(query, params)
    end
end



local function ConvertToBool(number)
    local number = tonumber(number)
    if number == 1 then return true else return false end
end

local function LoadAllDoors()
    MySQL.Async.fetchAll('SELECT * FROM doors', {}, function(result)
        for _, v in pairs(result) do
            doors:new({
                id = v.id,
                coords = json.decode(v.coords),
                distance = v.distance,
                label = v.label,
                pin = v.pin,
                doors = json.decode(v.doors),
                jobs = json.decode(v.jobs),
                default_status = ConvertToBool(v.default_status)
            })
        end
    end)
    Logger:info('LOAD', "All doors have been loaded.")
end

local function SaveDoors()
    for _, data in pairs(GetAllDoors()) do
        if data:getNeedSave() then
            data:saveDoor()
        end
    end
end


MySQL.ready(function()
    LoadAllDoors()

    CreateThread(function()
        while true do
            Wait(DOORS.SaveInterval * 60 * 1000)
            SaveDoors()
        end
    end)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        Logger:info('SAVE', "Resource stopping, saving doors.")
        SaveDoors()
    end
end)


yCore.RegisterServerCallback('sxDoors:getDoors', function(source, cb, f)
    while not DoorsLoaded do Wait(100) end
    cb(GetAllDoors())
end)

TriggerClientEvents = function(name, ids, ...)
    if type(ids) == "table" then
        if next(ids) then
            for i,v in ipairs(ids) do
                TriggerClientEvent(name, v, ...)
            end
        end
    else
        if ids and ids == -1 then
            TriggerClientEvent(name, -1, ...)
        end
    end
end

RegisterNetEvent("sxDoors:ChangeDoorState")
AddEventHandler("sxDoors:ChangeDoorState", function(token, id, state, plys)
    local source = source
    if CheckPlayerToken(source, token) then
        local door = GetDoorsFromId(id)
        door:setState(state)
        TriggerClientEvents("core:ChangeDoorState", plys, id, door:getState())
    end
end)