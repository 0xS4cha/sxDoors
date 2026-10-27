Utils = {}

local DOOR_TYPES = { single = true, double = true, sliding = true, garage = true }

function Utils.Round(value, decimals)
    local mult = 10 ^ (decimals or 2)
    return math.floor((tonumber(value) or 0) * mult + 0.5) / mult
end

function Utils.ToVector(coords)
    if not coords then return nil end
    return vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
end

function Utils.ToCoords(coords)
    if not coords then return nil end
    return {
        x = Utils.Round(coords.x),
        y = Utils.Round(coords.y),
        z = Utils.Round(coords.z),
    }
end

function Utils.Trim(value)
    if type(value) ~= "string" then return "" end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function Utils.IsDoorType(value)
    return DOOR_TYPES[value] == true
end

function Utils.ToModel(model)
    if type(model) == "number" then return model end
    if type(model) ~= "string" or model == "" then return nil end

    local asNumber = tonumber(model)
    if asNumber then return asNumber end

    return joaat(model)
end

-- Center of every door entity, used as interaction point when none is given
function Utils.GetCenter(entities)
    local x, y, z, count = 0.0, 0.0, 0.0, 0
    for _, entity in ipairs(entities or {}) do
        if entity.coords then
            x = x + entity.coords.x
            y = y + entity.coords.y
            z = z + entity.coords.z
            count = count + 1
        end
    end

    if count == 0 then return nil end

    return { x = x / count, y = y / count, z = z / count }
end

function Utils.StringList(list, max)
    local result = {}
    local seen = {}
    if type(list) ~= "table" then return result end

    for _, value in pairs(list) do
        value = Utils.Trim(tostring(value))
        if value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
            if max and #result >= max then break end
        end
    end

    return result
end
