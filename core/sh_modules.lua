SX = SX or {}

SX.Modules = {}
SX.Modules.List = {}
SX.Modules.HasFunction = { Think = {} }
SX.Modules.Disabled = { }

function SX.Modules:Register(name, priority, submodules)
    table.insert(self.List, {
        name = name,
        priority = priority or 50,
        submodules = submodules
    })
end

function SX:InitializeModules()
    table.sort(self.Modules.List, function(a, b)
        return a.priority < b.priority
    end)

    TriggerEvent("onGamemodeInitialize")

    local startTime = GetGameTimer()

    for _, module in pairs(self.Modules.List) do
        local name = module.name
        if not self.Modules.Disabled[name] and self[name] then
            if self[name].Initialize then
                Logger:info("Module", "Initializing", name)
                ProfilerEnterScope(name)
                self[name]:Initialize()
                ProfilerExitScope()
            end

            if self[name].InitializeAsync then
                CreateThread(function()
                    self[name]:InitializeAsync()
                end)
            end

            if module.submodules then
                for _, submodule in pairs(module.submodules) do
                    if self[name][submodule] then
                        if self[name][submodule].Initialize then
                            ProfilerEnterScope(name .. "." .. submodule)
                            self[name][submodule]:Initialize()
                            ProfilerExitScope()
                        end

                        if self[name][submodule].InitializeAsync then
                            CreateThread(function()
                                self[name][submodule]:InitializeAsync()
                            end)
                        end
                    end
                end
            end

            local timeTaken = GetGameTimer() - startTime
            local timeStr = tostring(timeTaken)
            if timeTaken > 1 then
                timeStr = "^1" .. timeStr
            end
            Logger:info("Module", "Initialized " .. name .. " in " .. timeStr .. "ms")

            if not self.State.IsDuplicity then
                if self[name].Think then
                    table.insert(SX.Modules.HasFunction.Think, name)
                end
            end
        end
    end

    TriggerEvent("onGamemodeInitialized")
end