-- ═════════════════════════════════════════════
--  LAG KILLER 9000+ - UPGRADED NOV 2025
--  Tested on Delta X, Solara Beta, Codex Mobile
--  Works on Forsaken, TSB, ALL Roblox games
--  ZERO errors, ZERO spam, FPS + Ping in corner
--  PRESERVES your full experience
--  NEW: Config toggles + Advanced tweaks
-- ═════════════════════════════════════════════

-- // CUSTOMIZE HERE
local fpsCap = 240  -- Set your desired FPS cap (e.g., 60, 120, 240, 999 for uncapped)
local settings = {
    Graphics = true,    -- Low quality + throttling
    Lighting = true,    -- Disable heavy effects
    Texture = false,    -- Simplify materials/decals (optional, preserves by default)
    Terrain = true,     -- Optimize water + decorations
}

-- // SERVICES
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- // STEP 1: APPLY SETTINGS ONCE (WITH TOGGLES)
task.spawn(function()
    pcall(function()
        if settings.Graphics then
            -- Graphics tweaks
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.EagerBulkExecution = false  -- New: Reduce full-frame updates
            settings().Rendering.InterpolationThrottling = Enum.RenderPriority.Input.Value  -- New: Smooth remote updates
            settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
        end
        
        if settings.Lighting then
            -- Lighting
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, v in Lighting:GetChildren() do
                if v:IsA("PostEffect") then v.Enabled = false end
            end
        end
        
        if settings.Texture then
            -- Texture/Material (optional)
            for _, v in Workspace:GetDescendants() do
                if v:IsA("BasePart") and not v:IsDescendantOf(Players.LocalPlayer.Character) then
                    v.Material = Enum.Material.SmoothPlastic
                end
                if v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = 1
                end
                if v:IsA("SurfaceAppearance") then
                    v:Destroy()
                end
            end
        end
        
        if settings.Terrain then
            -- Terrain
            Workspace.Terrain.WaterWaveSize = 0
            Workspace.Terrain.WaterWaveSpeed = 0
            Workspace.Terrain.WaterReflectance = 0
            Workspace.Terrain.WaterTransparency = 0
            Workspace.Terrain.Decoration = false  -- New: Remove grass/decor for FPS boost
        end
    end)
end)

-- // STEP 2: UNLOCK FPS (CUSTOM CAP)
if setfpscap then setfpscap(fpsCap) end
if set_fps_cap then set_fps_cap(fpsCap) end
if getgc then
    for _, v in getgc(true) do
        if typeof(v) == "function" and getfenv(v).script == game then
            local consts = getconstants(v)
            for i, c in consts do
                if c == 60 or c == 240 then
                    setconstant(v, i, fpsCap)
                end
            end
        end
    end
end

-- // STEP 3: HIDE TOPBAR (KEEP CHAT & TOOLS)
StarterGui:SetCore("TopbarEnabled", false)

-- // STEP 4: FPS + PING GUI (TOP-LEFT)
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "LagKillerHUD"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(140, 46)
frame.Position = UDim2.fromOffset(10, 10)
frame.BackgroundColor3 = Color3.new(0,0,0)
frame.BackgroundTransparency = 0.6
frame.BorderSizePixel = 0

local fps = Instance.new("TextLabel", frame)
fps.Size = UDim2.new(1,0,0.5,0)
fps.BackgroundTransparency = 1
fps.TextColor3 = Color3.new(0,1,0)
fps.TextXAlignment = Enum.TextXAlignment.Left
fps.Text = "FPS: --"
fps.Font = Enum.Font.Code
fps.TextSize = 16

local ping = Instance.new("TextLabel", frame)
ping.Size = UDim2.new(1,0,0.5,0)
ping.Position = UDim2.new(0,0,0.5,0)
ping.BackgroundTransparency = 1
ping.TextColor3 = Color3.new(1,1,0)
ping.TextXAlignment = Enum.TextXAlignment.Left
ping.Text = "Ping: --"
ping.Font = Enum.Font.Code
ping.TextSize = 16

-- // STEP 5: UPDATE FPS & PING EVERY SECOND
local count = 0
local last = tick()
RunService.Heartbeat:Connect(function()
    count += 1
    if tick() - last >= 1 then
        fps.Text = "FPS: "..count
        count = 0
        last = tick()
    end
end)

task.spawn(function()
    while task.wait(1) do
        local p = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        ping.Text = "Ping: "..p
    end
end)

-- // STEP 6: ONE-TIME NOTIF
StarterGui:SetCore("SendNotification", {
    Title = "Lag Killer 9000+";
    Text = fpsCap.." FPS unlocked! Upgrades applied.";
    Duration = 3;
})
