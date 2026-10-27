SX = SX or {}

FrameTime = GetFrameTime()
NetworkTimeMSec = GetNetworkTimeAccurate()
GameTime = GetGameTimer()
local lastTick = GameTime

function SX:Think()
    local localPlayer = LocalPlayer()
    local vehicle = localPlayer:GetVehicle()

    self.ProfilerEnabled = ProfilerIsRecording()

    if GameTime - lastTick > 1000 then
        lastTick = GameTimes
        self.TickSecond = true
    end

    for _, moduleName in pairs(SX.Modules.HasFunction.Think) do
        if self.ProfilerEnabled then
            ProfilerEnterScope(moduleName)
        end

        self[moduleName]:Think(localPlayer, vehicle)

        if self.ProfilerEnabled then
            ProfilerExitScope()
        end
    end

    if self.TickSecond then
        self.TickSecond = nil
    end
end

CreateThread(function()
    for _, module in pairs(SX.Modules.List) do
        local name = module.name
        if SX[name] and SX[name].onResourceStart then
            SX[name]:onResourceStart()
        end

        if module.submodules then
            for _, submodule in pairs(module.submodules) do
                if SX[name][submodule] and SX[name][submodule].onResourceStart then
                    SX[name][submodule]:onResourceStart()
                end
            end
        end
    end
    while true do
        Wait(0)
        SX:Think()
    end
end)
