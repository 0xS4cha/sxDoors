SX.UI = {}
SX.Modules:Register("UI", 5)

local isOpen = false
local currentPanel = nil
local keypadDoor = nil

function SX.UI:Send(action, data)
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

local function sendTranslations()
    local locale = GetPreferredLanguageId()
    SX.UI:Send('setTranslations', {
        locale = locale,
        translations = GetLanguageTable(locale)
    })
end

function SX.UI:Open(panel, data)
    currentPanel = panel
    isOpen = true
    SetNuiFocus(true, true)
    sendTranslations()
    self:Send('setRoute', { route = panel, data = data })
    self:Send('setVisible', { visible = true })
end

function SX.UI:Close()
    if not isOpen then return end

    isOpen = false
    currentPanel = nil
    keypadDoor = nil
    SetNuiFocus(false, false)
    self:Send('setVisible', { visible = false })
end

function SX.UI:Hide()
    SetNuiFocus(false, false)
    self:Send('setVisible', { visible = false })
end

function SX.UI:Show()
    SetNuiFocus(true, true)
    self:Send('setVisible', { visible = true })
end

function SX.UI:IsOpen()
    return isOpen
end

function SX.UI:GetCurrentPanel()
    return currentPanel
end

function SX.UI:OpenKeypad(door)
    keypadDoor = door.id
    self:Open('keypad', {
        doorId = door.id,
        label = door.label,
        locked = door.locked,
        minLength = Config.Pin.minLength,
        maxLength = Config.Pin.maxLength,
    })
end

function SX.UI:Initialize()
    RegisterNUICallback('nuiReady', function(_, cb)
        cb({ ok = true })
    end)

    RegisterNUICallback('close', function(_, cb)
        SX.UI:Close()
        cb({ ok = true })
    end)

    RegisterNUICallback('submitPin', function(data, cb)
        if not keypadDoor or type(data) ~= 'table' or type(data.pin) ~= 'string' then
            cb({ ok = false, reason = 'invalid_data' })
            return
        end

        local doorId = keypadDoor
        local result = SX.Doors:SubmitPin(doorId, data.pin)
        cb(result)

        if result.ok then
            SetTimeout(600, function()
                if keypadDoor == doorId then SX.UI:Close() end
            end)
        elseif result.reason ~= 'pin_wrong' then
            SX.UI:Close()
        end
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
end
