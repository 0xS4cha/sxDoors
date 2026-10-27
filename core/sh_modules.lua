SX = SX or {}

SX.Modules = {}
SX.Modules.List = {}
SX.Modules.Disabled = {}

function SX.Modules:Register(name, priority)
    table.insert(self.List, {
        name = name,
        priority = priority or 50
    })
end

function SX:InitializeModules()
    table.sort(self.Modules.List, function(a, b)
        return a.priority < b.priority
    end)

    for _, module in ipairs(self.Modules.List) do
        local name = module.name
        local mod = self[name]
        if not self.Modules.Disabled[name] and mod then
            local startTime = GetGameTimer()

            if mod.Initialize then
                local ok, err = pcall(mod.Initialize, mod)
                if not ok then
                    Logger:error("Module", name, err)
                end
            end

            if mod.InitializeAsync then
                CreateThread(function()
                    mod:InitializeAsync()
                end)
            end

            Logger:trace("Module", ("Initialized %s in %dms"):format(name, GetGameTimer() - startTime))
        end
    end

    TriggerEvent("sxDoors:initialized")
end
