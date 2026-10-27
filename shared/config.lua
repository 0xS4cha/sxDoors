Config = {}

-- 'auto' detects es_extended, otherwise the resource runs standalone
-- 'esx' forces ESX, 'standalone' never touches ESX
Config.Framework = 'auto'

-- 'auto' uses oxmysql when it is started, otherwise the JSON file in data/doors.json
-- 'mysql' forces oxmysql, 'json' always uses the JSON file
Config.Storage = 'auto'

-- Keep the lock state of every door across restarts. When false, doors go back to their default state
Config.PersistState = true

-- Players allowed to open the admin panel
Config.Admin = {
    -- ESX groups, ignored in standalone
    groups = { 'admin', 'superadmin' },
    -- ACE permission, works with every framework: add_ace group.admin sxdoors.admin allow
    ace = 'sxdoors.admin',
    -- Admins can open every door, whatever its access rules
    bypass = true,
}

Config.Interaction = {
    -- Default key, players can change it in the FiveM key bindings settings
    key = 'E',
    -- '3d' draws the state above the door, 'help' uses the GTA help notification, 'none' hides the prompt
    prompt = '3d',
    -- Interaction distance used when a door has none
    defaultDistance = 2.0,
    -- Extra distance tolerated by the server before refusing a request
    serverTolerance = 3.0,
    -- Delay in ms between two interactions of the same player
    cooldown = 600,
    -- Plays a key animation when toggling a door
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
    -- Wrong codes allowed before the player is blocked
    maxAttempts = 5,
    -- Seconds the player stays blocked after too many wrong codes
    lockout = 60,
}

Config.Lockpick = {
    enabled = true,
    -- ESX usable item, set to false to only use the LockpickClosestDoor export
    item = 'lockpick',
    -- Chance (0-100) to unlock the door
    successChance = 60,
    -- Chance (0-100) to lose the item, on success or failure
    breakChance = 35,
    -- Duration of the lockpick animation in ms
    duration = 6000,
}

-- Speed of sliding and garage doors when they move automatically
Config.AutomaticRate = 1.0

-- Number of entries kept in the admin activity feed
Config.ActivityLimit = 100

-- Discord logs, set the webhook with the convar: set sx_doors_webhook "https://discord.com/api/webhooks/..."
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
