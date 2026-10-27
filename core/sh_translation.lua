local registeredLanguages = {}
local defaultPhrases = {}
local mainLanguage = "en"

local langToId = { "en", "fr", "de", "it", "es", "pt", "pl", "ru", "ko", "zh", "ja", "me", "fa", "br", "sv", "ar", "tr" }

if not GetCurrentLanguage then
    function GetCurrentLanguage()
        return 0
    end

    function GetLabelText(label)
        return label
    end
end


local forcedLanguage = GetConvar("sx_locale", "")
local autoLanguage = forcedLanguage ~= "" and forcedLanguage or langToId[GetCurrentLanguage() + 1]
local selectedLanguage = autoLanguage

function RegisterDefaultPhrases(phrases)
    defaultPhrases = phrases
    Logger:info('TRANSLATION', "Register default translation")
end

function UpdateDefaultPhrase(key, name)
    defaultPhrases[key] = name
end

exports("UpdateDefaultPhrase", UpdateDefaultPhrase)

function AddLanguage(name, tbl)
    local old = registeredLanguages[name] or {}
    registeredLanguages[name] = tbl
    -- Merge the language with the translations added by AddPhrase
    for k, v in pairs(old) do
        if not registeredLanguages[name][k] then
            registeredLanguages[name][k] = v
        end
    end

    Logger:info('TRANSLATION', "Register", name, 'translation')
end

function AddPhrase(lang, name, phrase)
    registeredLanguages[lang] = registeredLanguages[lang] or {}
    registeredLanguages[lang][name] = phrase
end

exports("AddPhrase", AddPhrase)

function GetPreferredLanguageId()
    return selectedLanguage or mainLanguage
end

exports("GetPreferredLanguageId", GetPreferredLanguageId)

function GetPhrase(name, ...)
    if not name then return end

    local langTable = registeredLanguages[selectedLanguage] or {}
    local mainLangTable = registeredLanguages[mainLanguage] or {}

    local arguments = { ... }
    for k, v in pairs(arguments) do
        if type(v) == "string" then
            arguments[k] = GetPhrase(v)
        end
    end

    local phrase = langTable[name] or mainLangTable[name] or defaultPhrases[name]

    if phrase then
        return string.format(phrase, table.unpack(arguments))
    end

    return #arguments > 0 and string.format(name, table.unpack(arguments)) or name
end

function IsPhraseRegistered(name)
    return registeredLanguages[mainLanguage][name] and true or false
end

exports("IsPhraseRegistered", IsPhraseRegistered)

function GetMissingPhrases(lang)
    lang = lang or selectedLanguage
    local res = {}
    local format = "%s = \"%s\","

    for k, v in pairs(registeredLanguages[mainLanguage]) do
        if not registeredLanguages[lang][k] then
            table.insert(res, string.format(format, k, v))
        end
    end

    return #res == 0 and "No language strings missing!" or table.concat(res, "\n")
end

exports("GetPhrase", GetPhrase)


local function getMissingPhrases(ply, args, cmd)
    if not args[1] then
        Logger:info('TRANSLATIOn',
            "Please run the command with a language code e.g. darkrp_getphrases \"" .. mainLanguage .. "\"")
        return
    end
    local lang = registeredLanguages[args[1]]
    if not lang then
        Logger:warn('TRANSLATION', "This language does not exist! Make sure the casing is right.")
        Logger:info('TRANSLATION', "Available languages:")
        for k in pairs(registeredLanguages) do print(k) end
        return
    end

    Logger:info('TRANSLATION', GetMissingPhrases(args[1]))
end


if not SendNUIMessage then return end

-- Utils
function GetVehicleNameFromModel(modelHash)
    local displayName = GetDisplayNameFromVehicleModel(modelHash)
    local labelName = GetLabelText(displayName)
    if labelName ~= "NULL" then
        return labelName
    end

    if displayName ~= "CARNOTFOUND" then
        return displayName
    end

    return modelHash
end

-- Get system languages
CreateThread(function()
    SetTimeout(1000, function()
        SendNUIMessage({ type = "getSystemLanguages" })
    end)
end)



function SetGameLanguage(language)
    if not language or language == "auto" then
        language = autoLanguage
    end

    selectedLanguage = language
    TriggerEvent("setGameMenuLanguage", selectedLanguage)
end

exports("SetGameLanguage", SetGameLanguage)

function GetLanguageTable(lang)
    lang = lang or selectedLanguage or mainLanguage
    local result = {}
    local mainLangTable = registeredLanguages[mainLanguage] or {}
    local selectedTable = registeredLanguages[lang] or {}

    for k, v in pairs(defaultPhrases) do
        result[k] = v
    end

    for k, v in pairs(mainLangTable) do
        result[k] = v
    end

    for k, v in pairs(selectedTable) do
        result[k] = v
    end

    return result
end

exports("GetLanguageTable", GetLanguageTable)
