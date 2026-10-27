SX = SX or {}
SX.UI = SX.UI or {}

local isOpen = false
local currentPanel = nil

function SX.UI:Send(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

function SX.UI:Open(panel)
    if isOpen then
        self:Send('setRoute', { route = panel })
        return
    end

    local locale = GetPreferredLanguageId()

    currentPanel = panel
    isOpen = true
    SetNuiFocus(true, true)
    self:Send('setTranslations', {
        locale = locale,
        translations = GetLanguageTable(locale)
    })
    self:Send('setLocale', { locale = locale })
    self:Send('setRoute', { route = panel })
    self:Send('setVisible', { visible = true })
end

function SX.UI:Close()
    if not isOpen then
        return
    end

    isOpen = false
    currentPanel = nil
    SetNuiFocus(false, false)
    self:Send('setVisible', { visible = false })
end

function SX.UI:IsOpen()
    return isOpen
end

function SX.UI:GetCurrentPanel()
    return currentPanel
end

RegisterNUICallback('nuiReady', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    SX.UI:Close()
    cb({ ok = true })
end)

RegisterNUICallback('debugLog', function(data, cb)
    if data and data.message then
        Logger:info('NUI', tostring(data.message))
    end
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if isOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)
