Logger = {}
Logger.Enabled = GetConvarInt("sh_dev", 1) == 1 and true or false

Logger.LogLevel = GetConvarInt("sh_log_level", Logger.Enabled and 3 or 0)

local LOG_LEVELS = {
    ERROR = 0,
    WARN = 1,
    INFO = 2,
    TRACE = 3
}

local function parseArguments(...)
    local arguments = {...}
    local parsedArguments = {}

    for _,v in pairs(arguments) do
        if type(v) == "table" then
            parsedArguments[#parsedArguments + 1] = table.ToString(v)
        else
            parsedArguments[#parsedArguments + 1] = tostring(v)
        end
    end

    return parsedArguments
end

function Logger:error(module, ...)
    if not self.Enabled then return end
    if self.LogLevel < LOG_LEVELS.ERROR then return end

    print("^1[ERROR] ^6[" .. string.upper(module) .. "] > ^5" .. table.concat(parseArguments(...), " ") .. "^0")
end

function Logger:info(module, ...)
    if not self.Enabled then return end
    if self.LogLevel < LOG_LEVELS.INFO then return end

    print("^2[INFO] ^6[" .. string.upper(module) .. "] > ^5" .. table.concat(parseArguments(...), " ") .. "^0")
end

function Logger:warn(module, ...)
    if not self.Enabled then return end
    if self.LogLevel < LOG_LEVELS.WARN then return end

    print("^3[WARN] ^6[" .. string.upper(module) .. "] > ^5" .. table.concat(parseArguments(...), " ") .. "^0")
end

function Logger:trace(module, ...)

    print("^8[TRACE] ^6[" .. string.upper(module) .. "] > ^5" .. table.concat(parseArguments(...), " ") .. "^0")
end