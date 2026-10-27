Config = {}

Config.Framework = 'auto'

Config.Storage = 'auto'

Config.PersistState = true

Config.Admin = {
    groups = { 'admin', 'superadmin' },
    ace = 'sxdoors.admin',
    bypass = true,
}

Config.Interaction = {
    key = 'E',
    prompt = 'sprite', -- help, 3d, sprite
    defaultDistance = 2.0,
    serverTolerance = 3.0,
    cooldown = 600,
    animation = true,
    sounds = {
        lock = { name = 'Remote_Control_Close', set = 'PI_Menu_Sounds' },
        unlock = { name = 'Remote_Control_Open', set = 'PI_Menu_Sounds' },
        denied = { name = 'ERROR', set = 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    },
}

Config.Pin = {
    minLength = 4,
    maxLength = 8,
    maxAttempts = 5,
    lockout = 60,
}

Config.Lockpick = {
    enabled = true,
    item = 'lockpick',
    successChance = 60,
    breakChance = 35,
    duration = 6000,
}

Config.AutomaticRate = 1.0

Config.ActivityLimit = 100

Config.Webhook = {
    enabled = true,
    username = 'sxDoors',
    events = {
        toggle = false,
        create = true,
        update = true,
        delete = true,
        lockpick = true,
        pin_failed = true,
    },
}
