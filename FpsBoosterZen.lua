-- Zen Fps Booster (fuck that guy try skid my source)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- EXEC GUARD
if _G.ZEN_GLOBAL then return end
_G.ZEN_GLOBAL = true

-- DEVICE DETECT
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isConsole = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
local device = isMobile and "MOBILE" or (isConsole and "CONSOLE" or "PC")
local targetFPS = isMobile and 120 or 999

-- CONFIG
local cfg = {
    ACBypass = true,
    Particles = true,
    HUD = true,
    AutoHop = true,
    PingLimit = isMobile and 200 or 150,
    JitterThreshold = 22
}

-- VARIABLES
local pingTotal = 0
local pingCount = 0
local avgPing = 0
local highPingMode = false
local fpsCount = 0
local lastTime = tick()
local pingObj = nil
local pingHistory = {}
local jitterSum = 0
local jitterCount = 0
local lastAvg = 0

-- ONE-TIME SAFE EXECUTION
local function safeOnce(func)
    if not _G.ZEN_Executed then
        _G.ZEN_Executed = true
        pcall(func)
    end
end

-- FULL ANTI-BAN + AC BYPASS
safeOnce(function()
    local acFolders = {
        "AntiCheat", "Security", "AC", "Remotes", "PranksterComet", "SoulBuster",
        "AntiExploit", "CheatDetection", "KickSystem", "BanSystem", "ForsakenAC", "Adonis"
    }
    for _, name in ipairs(acFolders) do
        pcall(function()
            local f1 = ReplicatedStorage:FindFirstChild(name)
            local f2 = Workspace:FindFirstChild(name)
            if f1 then f1:Destroy() end
            if f2 then f2:Destroy() end
        end)
    end

    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("kick") or n:find("ban") or n:find("flag") or n:find("anti") 
               or n:find("cheat") or n:find("exploit") or n:find("detect") or n:find("spy") then
                pcall(function() obj:Destroy() end)
            end
        end
    end

    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" or method == "Ban" then
            return task.wait(9e9)
        end
        if method == "FireServer" or method == "InvokeServer" then
            local name = tostring(self):lower()
            if name:find("anti") or name:find("kick") or name:find("ban") or name:find("flag") or name:find("detect") or name:find("spy") then
                return task.wait(9e9)
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

-- MAX FPS UNLOCK + GC PATCH
safeOnce(function()
    if setfpscap then setfpscap(targetFPS) end

    task.spawn(function()
        while task.wait(8) do
            if getgc then
                for _, f in getgc(true) do
                    if typeof(f) == "function" then
                        local c = getconstants(f)
                        for i, v in c do
                            if type(v) == "number" and v >= 30 and v <= 300 then
                                setconstant(f, i, targetFPS)
                            end
                        end
                    end
                end
            end
        end
    end)
end)

-- ULTRA RENDER OPTIMIZATION
safeOnce(function()
    settings().Rendering.QualityLevel = isMobile and 0 or 1
    settings().Rendering.StreamingMinRadius = isMobile and 8 or 64
    settings().Rendering.StreamingTargetRadius = isMobile and 32 or 128
    settings().Rendering.StreamingEnabled = true
    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e9
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Workspace.Terrain.WaterWaveSize = 0
    Workspace.Terrain.WaterReflectance = 0
    Workspace.Terrain.Decoration = false
end)

-- PARTICLES + EFFECTS KILLER
safeOnce(function()
    local function kill(v)
        if v and v.Parent then
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or 
               v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Beam") or v:IsA("Light") then
                v.Enabled = false
            end
            if v:IsA("MeshPart") then
                v.RenderFidelity = Enum.RenderFidelity.Performance
            end
        end
    end
    for _, v in pairs(Workspace:GetDescendants()) do kill(v) end
    Workspace.DescendantAdded:Connect(kill)
end)

-- MESH STRIP (MOBILE/CONSOLE)
if isMobile or isConsole then
    safeOnce(function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("MeshPart") or v:IsA("SpecialMesh") then
                v.TextureID = ""
                v.MeshId = ""
            end
        end
    end)
end

-- AUTO SERVER HOP
local function hopServer()
    if not cfg.AutoHop then return end
    spawn(function()
        local success, res = pcall(function()
            return HttpService:GetAsync(
                "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            )
        end)
        if success then
            local data = HttpService:JSONDecode(res)
            if data and data.data then
                for _, svr in ipairs(data.data) do
                    if svr.playing and svr.maxPlayers and svr.ping and svr.id then
                        if svr.playing < svr.maxPlayers * 0.7 and svr.ping < cfg.PingLimit then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, svr.id)
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- 4G + JITTER + PING FIX (OPTIMIZED)
task.spawn(function()
    while task.wait(1) do
        if Stats.Network and Stats.Network.ServerStatsItem then
            pingObj = Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
            if pingObj then break end
        end
    end
end)

-- HUD + MAIN LOOP
if cfg.HUD then
    local screen = Instance.new("ScreenGui")
    screen.Name = "ZEN_HUD"
    screen.ResetOnSpawn = false
    screen.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(190, 90)
    frame.Position = UDim2.fromOffset(10, 10)
    frame.BackgroundTransparency = 0.65
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.Parent = screen

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, 0, 0.3, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    fpsLabel.Text = "FPS: 0"
    fpsLabel.Font = Enum.Font.Code
    fpsLabel.TextSize = 15
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = frame

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(1, 0, 0.25, 0)
    pingLabel.Position = UDim2.new(0, 0, 0.3, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    pingLabel.Text = "Ping: --"
    pingLabel.Font = Enum.Font.Code
    pingLabel.TextSize = 14
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = frame

    local jitterLabel = Instance.new("TextLabel")
    jitterLabel.Size = UDim2.new(1, 0, 0.25, 0)
    jitterLabel.Position = UDim2.new(0, 0, 0.55, 0)
    jitterLabel.BackgroundTransparency = 1
    jitterLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
    jitterLabel.Text = "Jitter: OK"
    jitterLabel.Font = Enum.Font.Code
    jitterLabel.TextSize = 13
    jitterLabel.TextXAlignment = Enum.TextXAlignment.Left
    jitterLabel.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0.2, 0)
    status.Position = UDim2.new(0, 0, 0.8, 0)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(0, 200, 255)
    status.Text = device .. " | ZEN ACTIVE"
    status.Font = Enum.Font.Code
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame

    RunService.Heartbeat:Connect(function()
        fpsCount += 1
        if tick() - lastTime >= 1 then
            fpsLabel.Text = "FPS: " .. fpsCount
            fpsCount = 0
            lastTime = tick()
        end

        if pingObj then
            local success, ping = pcall(function() return pingObj.Value end)
            if success and ping then
                pingTotal += ping
                pingCount += 1
                avgPing = math.floor(pingTotal / pingCount)
                pingLabel.Text = "Ping: " .. avgPing .. "ms"

                table.insert(pingHistory, ping)
                if #pingHistory > 15 then
                    local old = table.remove(pingHistory, 1)
                    jitterSum = jitterSum - (old - lastAvg)^2
                    jitterCount -= 1
                end
                jitterSum += (ping - lastAvg)^2
                jitterCount += 1
                lastAvg = avgPing

                local jitter = jitterCount > 0 and math.sqrt(jitterSum / jitterCount) or 0
                jitter = math.floor(jitter)
                jitterLabel.Text = "Jitter: " .. jitter .. "ms"
                jitterLabel.TextColor3 = jitter > cfg.JitterThreshold and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)

                if (avgPing > cfg.PingLimit or jitter > cfg.JitterThreshold) and not highPingMode then
                    highPingMode = true
                    status.TextColor3 = Color3.fromRGB(255, 0, 0)
                    status.Text = device .. " | HOPPING..."
                    hopServer()
                elseif (avgPing < cfg.PingLimit * 0.8 and jitter < cfg.JitterThreshold * 0.8) and highPingMode then
                    highPingMode = false
                    status.TextColor3 = Color3.fromRGB(0, 200, 255)
                    status.Text = device .. " | ZEN ACTIVE"
                end
            end
        end
    end)
end

-- CONTROLS
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F2 then
        hopServer()
    elseif input.KeyCode == Enum.KeyCode.F3 then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        StarterGui:SetCore("TopbarEnabled", true)
    end
end)

-- NOTIFY
StarterGui:SetCore("TopbarEnabled", false)
StarterGui:SetCore("SendNotification", {
    Title = "ZEN FPS BOOSTER v2",
    Text = "Hello! Zen Update His script So here what's New!:\n• Optimization For all devices\n• 4G/Jitter\n• Optimization For low-end mobile and pc\n• etc",
    Duration = 8
})
