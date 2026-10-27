Activity = {}

local entries = {}
local counter = 0

local SEVERITY = {
    lock = 'info',
    unlock = 'info',
    create = 'success',
    update = 'info',
    delete = 'warning',
    lockpick = 'warning',
    pin_failed = 'warning',
    denied = 'warning',
}

local WEBHOOK_COLORS = {
    info = 3447003,
    success = 5763719,
    warning = 16705372,
}

local WEBHOOK_EVENTS = {
    lock = 'toggle',
    unlock = 'toggle',
    create = 'create',
    update = 'update',
    delete = 'delete',
    lockpick = 'lockpick',
    pin_failed = 'pin_failed',
}

local webhookUrl = GetConvar('sx_doors_webhook', '')

local function sendWebhook(entry)
    if not Config.Webhook.enabled or webhookUrl == '' then return end

    local event = WEBHOOK_EVENTS[entry.type]
    if not event or not Config.Webhook.events[event] then return end

    local fields = {
        { name = GetPhrase('webhook_door'), value = ('%s (`%s`)'):format(entry.doorLabel, entry.doorId), inline = true },
    }

    if entry.player then
        fields[#fields + 1] = { name = GetPhrase('webhook_player'), value = ('%s (%s)\n`%s`'):format(entry.player, entry.playerId, entry.identifier or '-'), inline = true }
    end

    PerformHttpRequest(webhookUrl, function() end, 'POST', json.encode({
        username = Config.Webhook.username,
        embeds = { {
            title = GetPhrase('webhook_' .. entry.type),
            color = WEBHOOK_COLORS[entry.severity] or WEBHOOK_COLORS.info,
            fields = fields,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', entry.time),
            footer = { text = 'sxDoors' },
        } },
    }), { ['Content-Type'] = 'application/json' })
end

function Activity.Add(kind, door, source)
    counter = counter + 1

    local entry = {
        id = counter,
        time = os.time(),
        type = kind,
        severity = SEVERITY[kind] or 'info',
        doorId = door.id,
        doorLabel = door.label,
    }

    if source and source > 0 then
        entry.player = Bridge.GetPlayerName(source)
        entry.playerId = source
        entry.identifier = Bridge.GetMainIdentifier(source)
    end

    table.insert(entries, 1, entry)
    if #entries > Config.ActivityLimit then
        table.remove(entries)
    end

    sendWebhook(entry)
    TriggerEvent('sxDoors:activity', entry)
end

function Activity.GetAll()
    return entries
end
