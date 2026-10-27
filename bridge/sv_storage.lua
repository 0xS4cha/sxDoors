Storage = {}
Storage.Name = 'json'

local JSON_FILE = 'data/doors.json'
local resourceName = GetCurrentResourceName()

local function detectStorage()
    if Config.Storage == 'json' then return 'json' end

    if Config.Storage == 'mysql' or GetResourceState('oxmysql') ~= 'missing' then
        return 'mysql'
    end

    return 'json'
end

Storage.Name = detectStorage()

local function query(sql, params)
    local p = promise.new()
    exports.oxmysql:query(sql, params or {}, function(result)
        p:resolve(result)
    end)
    return Citizen.Await(p)
end

local function execute(sql, params)
    exports.oxmysql:query(sql, params or {})
end

local jsonRecords = {}
local jsonDirty = false

local function readJson()
    local content = LoadResourceFile(resourceName, JSON_FILE)
    if not content or content == '' then return {} end

    local ok, decoded = pcall(json.decode, content)
    if not ok or type(decoded) ~= 'table' then
        Logger:error('STORAGE', JSON_FILE, "is not valid JSON, starting with an empty list")
        return {}
    end

    local records = {}
    for _, record in pairs(decoded) do
        if type(record) == 'table' and record.id then
            records[record.id] = record
        end
    end
    return records
end

local function writeJson()
    local list = {}
    for _, record in pairs(jsonRecords) do
        list[#list + 1] = record
    end
    table.sort(list, function(a, b) return a.id < b.id end)

    if not SaveResourceFile(resourceName, JSON_FILE, json.encode(list, { indent = true }), -1) then
        Logger:error('STORAGE', "Unable to write", JSON_FILE)
    end
    jsonDirty = false
end

local function scheduleJsonWrite()
    if jsonDirty then return end
    jsonDirty = true
    SetTimeout(250, writeJson)
end


function Storage.Init()
    if Storage.Name == 'mysql' then
        local timeout = GetGameTimer() + 30000
        while GetResourceState('oxmysql') ~= 'started' and GetGameTimer() < timeout do Wait(100) end

        query([[
            CREATE TABLE IF NOT EXISTS `sx_doors` (
                `id` varchar(50) NOT NULL,
                `label` varchar(100) NOT NULL,
                `data` longtext NOT NULL,
                `locked` tinyint(1) NOT NULL DEFAULT 1,
                `created_at` datetime NOT NULL DEFAULT current_timestamp(),
                `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ]])
    else
        jsonRecords = readJson()
    end

    Logger:info('STORAGE', "Storage:", Storage.Name)
end
function Storage.LoadAll()
    local records = {}

    if Storage.Name == 'mysql' then
        for _, row in ipairs(query('SELECT `id`, `label`, `data`, `locked` FROM `sx_doors`') or {}) do
            local ok, data = pcall(json.decode, row.data or '{}')
            if ok and type(data) == 'table' then
                records[#records + 1] = {
                    id = row.id,
                    label = row.label,
                    data = data,
                    locked = tonumber(row.locked) == 1 or row.locked == true,
                }
            else
                Logger:warn('STORAGE', "Skipping door", row.id, "invalid data")
            end
        end
    else
        for _, record in pairs(jsonRecords) do
            records[#records + 1] = {
                id = record.id,
                label = record.label,
                data = record.data or {},
                locked = record.locked == true,
            }
        end
    end

    return records
end

function Storage.Save(id, label, data, locked)
    if Storage.Name == 'mysql' then
        execute([[
            INSERT INTO `sx_doors` (`id`, `label`, `data`, `locked`) VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `data` = VALUES(`data`), `locked` = VALUES(`locked`)
        ]], { id, label, json.encode(data), locked and 1 or 0 })
    else
        jsonRecords[id] = { id = id, label = label, data = data, locked = locked }
        scheduleJsonWrite()
    end
end

function Storage.SaveState(id, locked)
    if Storage.Name == 'mysql' then
        execute('UPDATE `sx_doors` SET `locked` = ? WHERE `id` = ?', { locked and 1 or 0, id })
    elseif jsonRecords[id] then
        jsonRecords[id].locked = locked
        scheduleJsonWrite()
    end
end

function Storage.Delete(id)
    if Storage.Name == 'mysql' then
        execute('DELETE FROM `sx_doors` WHERE `id` = ?', { id })
    else
        jsonRecords[id] = nil
        scheduleJsonWrite()
    end
end

function Storage.LoadLegacy()
    if Storage.Name ~= 'mysql' then return nil end

    local exists = query("SHOW TABLES LIKE 'doors'")
    if not exists or #exists == 0 then return nil end

    return query('SELECT * FROM `doors`') or {}
end

function Storage.Flush()
    if Storage.Name == 'json' and jsonDirty then
        writeJson()
    end
end
