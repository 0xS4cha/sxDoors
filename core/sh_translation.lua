local registeredLanguages = {}
local mainLanguage = "en"

local langToId = { "en", "fr", "de", "it", "es", "pt", "pl", "ru", "ko", "zh", "ja", "me", "fa", "br", "sv", "ar", "tr" }

local forcedLanguage = GetConvar("sx_locale", "")
local autoLanguage = mainLanguage

if forcedLanguage ~= "" then
    autoLanguage = forcedLanguage
elseif GetCurrentLanguage then
    autoLanguage = langToId[GetCurrentLanguage() + 1] or mainLanguage
end

local selectedLanguage = autoLanguage

function AddLanguage(name, tbl)
    local old = registeredLanguages[name] or {}
    registeredLanguages[name] = tbl
    -- Keep the phrases added through AddPhrase before the language file was loaded
    for k, v in pairs(old) do
        if not registeredLanguages[name][k] then
            registeredLanguages[name][k] = v
        end
    end

    Logger:trace('TRANSLATION', "Register", name, 'translation')
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
    local phrase = langTable[name] or mainLangTable[name]

    if select("#", ...) > 0 then
        return string.format(phrase or name, ...)
    end

    return phrase or name
end

exports("GetPhrase", GetPhrase)

function IsPhraseRegistered(name)
    return (registeredLanguages[mainLanguage] or {})[name] ~= nil
end

exports("IsPhraseRegistered", IsPhraseRegistered)

function GetLanguageTable(lang)
    lang = lang or selectedLanguage or mainLanguage
    local result = {}

    for k, v in pairs(registeredLanguages[mainLanguage] or {}) do
        result[k] = v
    end

    for k, v in pairs(registeredLanguages[lang] or {}) do
        result[k] = v
    end

    return result
end

exports("GetLanguageTable", GetLanguageTable)

if IsDuplicityVersion() then return end

function SetGameLanguage(language)
    if not language or language == "auto" then
        language = autoLanguage
    end

    selectedLanguage = language
end

exports("SetGameLanguage", SetGameLanguage)
