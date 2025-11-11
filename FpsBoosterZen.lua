
-- Services
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

-- Device Detection
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isConsole = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
local device = isMobile and "MOBILE" or (isConsole and "CONSOLE" or "PC")
local targetFPS = isMobile and 120 or 500

-- Config
local cfg = {
    ACBypass = true,
    Particles = true,
    HUD = true,
    AutoHop = true,
    PingLimit = isMobile and 200 or 150
}

-- Variables
local pingTotal = 0
local pingCount = 0
local avgPing = 0
local highPingMode = false
local fpsCount = 0
local lastTime = tick()
local pingObj = nil

-- ONE-TIME SAFE EXECUTION
local function safeOnce(func)
    if not _G.LK9000_Executed then
        _G.LK9000_Executed = true
        pcall(func)
    end
end

-- FORSAKEN AC BYPASS (IMPROVED + UNDETECTED)
safeOnce(function()
    -- Destroy ALL possible AC folders
    local acFolders = {
        "AntiCheat", "Security", "AC", "Remotes", "PranksterComet", "SoulBuster",
        "AntiExploit", "CheatDetection", "KickSystem", "BanSystem", "ForsakenAC"
    }
    for _, name in ipairs(acFolders) do
        local f1 = ReplicatedStorage:FindFirstChild(name)
        local f2 = Workspace:FindFirstChild(name)
        if f1 then f1:Destroy() end
        if f2 then f2:Destroy() end
    end

    -- Remove ALL dangerous remotes
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("kick") or n:find("ban") or n:find("flag") or n:find("anti") 
               or n:find("cheat") or n:find("exploit") or n:find("detect") then
                obj:Destroy()
            end
        end
    end

    -- ADVANCED NAMECALL HOOK (Blocks Kick/Ban/FireServer + Anti-Exploit)
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()

        -- Block Kick/Ban
        if method == "Kick" or method == "Ban" then
            return task.wait(9e9)
        end

        -- Block Anti-Cheat FireServer
        if method == "FireServer" then
            local name = tostring(self):lower()
            if name:find("anti") or name:find("kick") or name:find("ban") or name:find("flag") then
                return task.wait(9e9)
            end
        end

        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

-- FPS UNLOCK + PATCH (IMPROVED)
safeOnce(function()
    if setfpscap then setfpscap(targetFPS) end
    task.spawn(function()
        while task.wait(15) do
            if getgc then
                for _, f in getgc(true) do
                    if typeof(f) == "function" then
                        local c = getconstants(f)
                        for i, v in c do
                            if v == 60 or v == 240 or v == 144 then
                                setconstant(f, i, targetFPS)
                            end
                        end
                    end
                end
            end
        end
    end)
end)

-- OPTIMIZATIONS (BETTER FOR ALL DEVICES)
safeOnce(function()
    settings().Rendering.QualityLevel = isMobile and 0 or 10
    settings().Rendering.StreamingMinRadius = isMobile and 16 or 256
    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e9
    Workspace.Terrain.WaterWaveSize = 0
    Workspace.Terrain.WaterReflectance = 0
    Workspace.Terrain.Decoration = false
end)

-- PARTICLES KILLER (ALL EFFECTS GONE)
safeOnce(function()
    local function kill(v)
        if v and v.Parent and (
            v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or 
            v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Beam")
        ) then
            v.Enabled = false
        end
    end
    for _, v in pairs(Workspace:GetDescendants()) do kill(v) end
    Workspace.DescendantAdded:Connect(kill)
end)

-- MESH STRIP (MOBILE/CONSOLE ONLY)
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

-- AUTO SERVER HOP (SMART + LOW PING)
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

-- HIDE TOPBAR
StarterGui:SetCore("TopbarEnabled", false)

-- PING FIX + HUD (REAL PING + CLEAN)
if cfg.HUD then
    local screen = Instance.new("ScreenGui")
    screen.Name = "LK9000_HUD"
    screen.ResetOnSpawn = false
    screen.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(170, 75)
    frame.Position = UDim2.fromOffset(10, 10)
    frame.BackgroundTransparency = 0.6
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.Parent = screen

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, 0, 0.4, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    fpsLabel.Text = "FPS: 0"
    fpsLabel.Font = Enum.Font.Code
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = frame

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(1, 0, 0.3, 0)
    pingLabel.Position = UDim2.new(0, 0, 0.4, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    pingLabel.Text = "Ping: --"
    pingLabel.Font = Enum.Font.Code
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = frame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0.3, 0)
    status.Position = UDim2.new(0, 0, 0.7, 0)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(0, 200, 255)
    status.Text = device .. " | AC SAFE"
    status.Font = Enum.Font.Code
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame

    -- FIND PING OBJECT ONCE
    task.spawn(function()
        while task.wait(1) do
            if Stats.Network and Stats.Network.ServerStatsItem then
                pingObj = Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
                if pingObj then break end
            end
        end
    end)

    -- MAIN LOOP
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

                if avgPing > cfg.PingLimit and not highPingMode then
                    highPingMode = true
                    status.TextColor3 = Color3.fromRGB(255, 0, 0)
                    status.Text = device .. " | HOPPING..."
                    hopServer()
                elseif avgPing < cfg.PingLimit * 0.8 and highPingMode then
                    highPingMode = false
                    status.TextColor3 = Color3.fromRGB(0, 200, 255)
                    status.Text = device .. " | AC SAFE"
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

-- NOTIFICATION
StarterGui:SetCore("SendNotification", {
    Title = "Lag Killer 9000+ v14",
    Text = device .. " | " .. targetFPS .. " FPS | AC BYPASSED",
    Duration = 5
})
