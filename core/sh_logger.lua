Logger = {}
Logger.Debug = GetConvarInt("sx_doors_debug", 0) == 1
Logger.LogLevel = GetConvarInt("sx_doors_log_level", Logger.Debug and 3 or 2)

local LOG_LEVELS = {
    ERROR = 0,
    WARN = 1,
    INFO = 2,
    TRACE = 3
}

local function parseArguments(...)
    local arguments = { ... }
    local parsedArguments = {}

    for i = 1, select("#", ...) do
        local v = arguments[i]
        if type(v) == "table" then
            parsedArguments[#parsedArguments + 1] = json.encode(v)
        else
            parsedArguments[#parsedArguments + 1] = tostring(v)
        end
    end

    return parsedArguments
end

local function log(level, color, tag, module, ...)
    if Logger.LogLevel < level then return end

    print(color .. "[" .. tag .. "] ^6[" .. string.upper(module) .. "] > ^5" .. table.concat(parseArguments(...), " ") .. "^0")
end

function Logger:error(module, ...)
    log(LOG_LEVELS.ERROR, "^1", "ERROR", module, ...)
end

function Logger:warn(module, ...)
    log(LOG_LEVELS.WARN, "^3", "WARN", module, ...)
end

function Logger:info(module, ...)
    log(LOG_LEVELS.INFO, "^2", "INFO", module, ...)
end

function Logger:trace(module, ...)
    log(LOG_LEVELS.TRACE, "^8", "TRACE", module, ...)
end
