--[[
    LUNA
    Steal an Egg — Cherry Blossom Automation
    github.com/YOURNAME/luna
    RightShift to stop
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- CONFIG
-- ============================================================

local Config = {
    AutoSteal = true,
    AutoEvent = true,
    AutoHatch = true,
    AutoTreadmill = true,
    AutoCombat = true,
    SoundsEnabled = true,
    WalkSpeedCap = 45,
    ActionDelayMin = 0.2,
    ActionDelayMax = 0.8,
    KillSwitch = Enum.KeyCode.RightShift,
    CombatRange = 18,
    BossRetreatHealth = 30,
}

local State = {
    Running = true,
    CurrentTask = "idle",
    InSafeZone = false,
    InCombat = false,
    CurrentTarget = nil,
    BossRef = nil,
}

-- ============================================================
-- SOUND ENGINE
-- ============================================================

local SoundBank = {
    Click = "rbxassetid://6895079853",
    ToggleOn = "rbxassetid://12221967",
    ToggleOff = "rbxassetid://12221961",
    Burst = "rbxassetid://9114362738",
    Kill = "rbxassetid://5152722786",
    BossHit = "rbxassetid://9114362738",
    Ready = "rbxassetid://6895079853",
}

local function playSound(id, volume, pitch)
    if not Config.SoundsEnabled then return end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 0.4
    s.PlaybackSpeed = pitch or 1
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
    task.delay(3, function()
        if s.Parent then s:Destroy() end
    end)
end

-- ============================================================
-- UTILITY
-- ============================================================

local function randDelay()
    return math.random() * (Config.ActionDelayMax - Config.ActionDelayMin) + Config.ActionDelayMin
end

local function getHRP()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

local function walkTo(position, timeout)
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return false end
    if (hrp.Position - position).Magnitude > 500 then return false end
    hum:MoveTo(position)
    local startTime = tick()
    local limit = timeout or 8
    while tick() - startTime < limit do
        if not State.Running then return false end
        local h = getHRP()
        if not h then return false end
        if (h.Position - position).Magnitude < 5 then return true end
        task.wait(0.1)
    end
    return false
end

local function firePrompt(prompt)
    pcall(function() fireproximityprompt(prompt) end)
end

-- ============================================================
-- EGG DATABASE
-- ============================================================

local EggDatabase = {
    { name = "Chicken Egg", rarity = "Common", biome = "Forest" },
    { name = "Dog Egg", rarity = "Common", biome = "Forest" },
    { name = "Bird Egg", rarity = "Uncommon", biome = "Forest" },
    { name = "Burrowing Owl Egg", rarity = "Rare", biome = "Forest" },
    { name = "Raccoon Egg", rarity = "Rare", biome = "Forest" },
    { name = "Fox Egg", rarity = "Epic", biome = "Forest" },
    { name = "Bear Egg", rarity = "Epic", biome = "Forest" },
    { name = "Brr Brr Patapim Egg", rarity = "Legendary", biome = "Forest" },
    { name = "Frog Egg", rarity = "Common", biome = "Lake" },
    { name = "Duckling Egg", rarity = "Common", biome = "Lake" },
    { name = "Catfish Egg", rarity = "Uncommon", biome = "Lake" },
    { name = "Turtle Egg", rarity = "Rare", biome = "Lake" },
    { name = "Trulimero Trulicina Egg", rarity = "Epic", biome = "Lake" },
    { name = "Swan Egg", rarity = "Epic", biome = "Lake" },
    { name = "Axolotl Egg", rarity = "Legendary", biome = "Lake" },
    { name = "Leviathan Egg", rarity = "Cosmic", biome = "Lake" },
    { name = "Jerboa Egg", rarity = "Common", biome = "Desert" },
    { name = "Fennec Egg", rarity = "Uncommon", biome = "Desert" },
    { name = "Camel Egg", rarity = "Rare", biome = "Desert" },
    { name = "Tob Tobi Tob Tob Egg", rarity = "Epic", biome = "Desert" },
    { name = "Snake Egg", rarity = "Legendary", biome = "Desert" },
    { name = "Sand Spider Egg", rarity = "Mythic", biome = "Desert" },
    { name = "Scorpion Egg", rarity = "Mythic", biome = "Desert" },
    { name = "Royal Sphinx Egg", rarity = "Cosmic", biome = "Desert" },
    { name = "Toucan Egg", rarity = "Rare", biome = "Jungle" },
    { name = "Chimpanzee Egg", rarity = "Rare", biome = "Jungle" },
    { name = "Crocodile Egg", rarity = "Epic", biome = "Jungle" },
    { name = "Gorilla Egg", rarity = "Legendary", biome = "Jungle" },
    { name = "Orangutini Ananassini Egg", rarity = "Legendary", biome = "Jungle" },
    { name = "Spider Egg", rarity = "Mythic", biome = "Jungle" },
    { name = "Tiger Egg", rarity = "Mythic", biome = "Jungle" },
    { name = "King Snake Egg", rarity = "Secret", biome = "Jungle" },
    { name = "Penguin Egg", rarity = "Rare", biome = "Snow" },
    { name = "Walrus Egg", rarity = "Epic", biome = "Snow" },
    { name = "Polar Bear Egg", rarity = "Legendary", biome = "Snow" },
    { name = "Sabertooth Tiger Egg", rarity = "Mythic", biome = "Snow" },
    { name = "Mammoth Egg", rarity = "Mythic", biome = "Snow" },
    { name = "King Mammoth Egg", rarity = "Cosmic", biome = "Snow" },
    { name = "Yeti Egg", rarity = "Secret", biome = "Snow" },
    { name = "Ice Dragon Egg", rarity = "Eternal", biome = "Snow" },
    { name = "Lava Gecko Egg", rarity = "Rare", biome = "Volcano" },
    { name = "Lava Frog Egg", rarity = "Epic", biome = "Volcano" },
    { name = "Flaming Bull Egg", rarity = "Legendary", biome = "Volcano" },
    { name = "Lava Iguana Egg", rarity = "Legendary", biome = "Volcano" },
    { name = "Chillin Chilli Egg", rarity = "Mythic", biome = "Volcano" },
    { name = "Cerberus Egg", rarity = "Secret", biome = "Volcano" },
    { name = "Phoenix Egg", rarity = "Eternal", biome = "Volcano" },
    { name = "Lava Dragon Egg", rarity = "Eternal", biome = "Volcano" },
    { name = "Parrotfish Egg", rarity = "Rare", biome = "Abyss Ocean" },
    { name = "Swordfish Egg", rarity = "Epic", biome = "Abyss Ocean" },
    { name = "Shark Egg", rarity = "Legendary", biome = "Abyss Ocean" },
    { name = "Orca Egg", rarity = "Mythic", biome = "Abyss Ocean" },
    { name = "Whale Shark Egg", rarity = "Cosmic", biome = "Abyss Ocean" },
    { name = "Beluga Whale Egg", rarity = "Cosmic", biome = "Abyss Ocean" },
    { name = "Kraken Egg", rarity = "Secret", biome = "Abyss Ocean" },
    { name = "El Maja Egg", rarity = "Eternal", biome = "Abyss Ocean" },
    { name = "Dodo Egg", rarity = "Rare", biome = "Prehistoric" },
    { name = "Pterodactyl Egg", rarity = "Legendary", biome = "Prehistoric" },
    { name = "Ankylosaurus Egg", rarity = "Mythic", biome = "Prehistoric" },
    { name = "Triceratops Egg", rarity = "Cosmic", biome = "Prehistoric" },
    { name = "Bronto Egg", rarity = "Cosmic", biome = "Prehistoric" },
    { name = "Tralaledon Egg", rarity = "Secret", biome = "Prehistoric" },
    { name = "T-Rex Egg", rarity = "Secret", biome = "Prehistoric" },
    { name = "Mosasaurus Egg", rarity = "Eternal", biome = "Prehistoric" },
    { name = "Centapede Egg", rarity = "Epic", biome = "Cosmic" },
    { name = "Cosmic Gecko Egg", rarity = "Legendary", biome = "Cosmic" },
    { name = "Cosmic Gorilla Egg", rarity = "Mythic", biome = "Cosmic" },
    { name = "La Vacca Saturno Saturnita Egg", rarity = "Cosmic", biome = "Cosmic" },
    { name = "Cosmic Skeleton Boss Egg", rarity = "Secret", biome = "Cosmic" },
    { name = "Cosmic Dragon Egg", rarity = "Secret", biome = "Cosmic" },
    { name = "Eternal Lunar Dragon Egg", rarity = "Eternal", biome = "Cosmic" },
    { name = "Unicorn Egg", rarity = "Divine", biome = "Cosmic" },
    { name = "Crane Egg", rarity = "Epic", biome = "Cherry Blossom" },
    { name = "Salamander Egg", rarity = "Legendary", biome = "Cherry Blossom" },
    { name = "Red Panda Egg", rarity = "Mythic", biome = "Cherry Blossom" },
    { name = "Snowy Owl Egg", rarity = "Cosmic", biome = "Cherry Blossom" },
    { name = "Koi Egg", rarity = "Cosmic", biome = "Cherry Blossom" },
    { name = "Stag Egg", rarity = "Secret", biome = "Cherry Blossom" },
    { name = "Kitsune Egg", rarity = "Divine", biome = "Cherry Blossom" },
    { name = "Spideron Egg", rarity = "Legendary", biome = "Titan Temple" },
    { name = "Crustacia Egg", rarity = "Legendary", biome = "Titan Temple" },
    { name = "Bladehide Egg", rarity = "Mythic", biome = "Titan Temple" },
    { name = "Mantaris Egg", rarity = "Cosmic", biome = "Titan Temple" },
    { name = "Rhinotaur Egg", rarity = "Cosmic", biome = "Titan Temple" },
    { name = "Mutant Shark Egg", rarity = "Secret", biome = "Titan Temple" },
    { name = "Gorilla King Egg", rarity = "Eternal", biome = "Titan Temple" },
    { name = "Nightflame Egg", rarity = "Divine", biome = "Titan Temple" },
    { name = "Flame Sprite Egg", rarity = "Legendary", biome = "Angels & Demons" },
    { name = "Light Dove Egg", rarity = "Legendary", biome = "Angels & Demons" },
    { name = "Toro Egg", rarity = "Mythic", biome = "Angels & Demons" },
    { name = "Winged Lamb Egg", rarity = "Mythic", biome = "Angels & Demons" },
    { name = "Imp Egg", rarity = "Cosmic", biome = "Angels & Demons" },
    { name = "Demon Hound Egg", rarity = "Cosmic", biome = "Angels & Demons" },
    { name = "Sacred Moth Egg", rarity = "Cosmic", biome = "Angels & Demons" },
    { name = "Holy Peacock Egg", rarity = "Cosmic", biome = "Angels & Demons" },
    { name = "Gargoyle Egg", rarity = "Secret", biome = "Angels & Demons" },
    { name = "RazorFang Egg", rarity = "Secret", biome = "Angels & Demons" },
    { name = "Pure Jellyfish Egg", rarity = "Secret", biome = "Angels & Demons" },
    { name = "Centaur Egg", rarity = "Secret", biome = "Angels & Demons" },
    { name = "Skeleton Horse Egg", rarity = "Eternal", biome = "Angels & Demons" },
    { name = "Pegasus Egg", rarity = "Eternal", biome = "Angels & Demons" },
    { name = "World Burner Egg", rarity = "Divine", biome = "Angels & Demons" },
    { name = "ArchAngel Egg", rarity = "Divine", biome = "Angels & Demons" },
    { name = "Tung Tung Tung Sahur Egg", rarity = "Rare", biome = "Brainrot" },
    { name = "Bananita Dolphinita Egg", rarity = "Epic", biome = "Brainrot" },
    { name = "Belula Beluga Egg", rarity = "Mythic", biome = "Brainrot" },
    { name = "Mangolini Parrochini Egg", rarity = "Cosmic", biome = "Brainrot" },
    { name = "Bomboclat Crocolat Egg", rarity = "Secret", biome = "Brainrot" },
    { name = "Strawberry Elephant Egg", rarity = "Eternal", biome = "Brainrot" },
    { name = "Rifborn Egg", rarity = "Event", biome = "Rift" },
    { name = "Riftbeasts Egg", rarity = "Event", biome = "Rift" },
    { name = "Shattered Rift Egg", rarity = "Event", biome = "Rift" },
    { name = "Shattered Colossus Egg", rarity = "Divine", biome = "Rift" },
    { name = "Extinction Egg", rarity = "Legendary", biome = "Store" },
}

-- ============================================================
-- HOP CONFIG
-- ============================================================

local HopPresets = {
    passive = { HopAfterEmptyCycles = 4, MinPlayersToHop = 6, HopCooldown = 90, PreferLowPop = true, MaxPages = 3 },
    balanced = { HopAfterEmptyCycles = 2, MinPlayersToHop = 4, HopCooldown = 45, PreferLowPop = true, MaxPages = 4 },
    aggressive = { HopAfterEmptyCycles = 1, MinPlayersToHop = 2, HopCooldown = 20, PreferLowPop = false, MaxPages = 6 },
}

local HopConfig = {}
for k, v in pairs(HopPresets.balanced) do HopConfig[k] = v end
HopConfig.Enabled = true
HopConfig.CurrentPreset = "balanced"

local HopState = {
    LastHop = 0,
    EmptyCycles = 0,
    LastRareAlert = "",
    RareAlertTime = 0,
}

-- ============================================================
-- HUNT CONFIG
-- ============================================================

local HuntConfig = {
    Enabled = false,
    TargetName = "",
    ScanTimeout = 12,
    PostHopWait = 6,
    MaxHopsPerCycle = 999,
    StopWhenFound = true,
}

local HuntState = {
    Active = false,
    HopsThisCycle = 0,
    Found = false,
    FoundEgg = nil,
    LastScanStart = 0,
    TargetLower = "",
}

local function setHuntTarget(name)
    HuntConfig.TargetName = name or ""
    HuntState.TargetLower = string.lower(HuntConfig.TargetName)
end

-- ============================================================
-- BASE CONFIG
-- ============================================================

local BaseConfig = {
    Position = nil,
    AutoReturn = true,
    ReturnMethod = "hybrid",
    SafeOffset = 60,
    PostStealDelay = 0.8,
    PostReturnCooldown = 2,
    MarkerEnabled = true,
}

local BaseState = {
    MarkerPart = nil,
    MarkerRing = nil,
    LastReturn = 0,
    Returning = false,
}

-- ============================================================
-- PETAL / BLOSSOM ENGINE
-- ============================================================

local function createPetal(parent, originX, originY, opts)
    opts = opts or {}
    local size = opts.size or math.random(5, 10)
    local life = opts.life or math.random(0.8, 1.6)
    local spreadX = opts.spreadX or math.random(-80, 80)
    local spreadY = opts.spreadY or math.random(-120, -20)
    local color = opts.color or Color3.fromRGB(
        math.random(240, 255), math.random(160, 200), math.random(190, 220))
    local petal = Instance.new("Frame")
    petal.Size = UDim2.fromOffset(size, size)
    petal.Position = UDim2.new(0, originX - size / 2, 0, originY - size / 2)
    petal.BackgroundColor3 = color
    petal.BorderSizePixel = 0
    petal.ZIndex = 100
    petal.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = petal
    local startRot = math.random(0, 360)
    petal.Rotation = startRot
    local tween = TweenService:Create(petal, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(petal.Position.X.Scale, petal.Position.X.Offset + spreadX,
            petal.Position.Y.Scale, petal.Position.Y.Offset + spreadY),
        Rotation = startRot + math.random(-360, 360),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size * 0.2, size * 0.2),
    })
    tween:Play()
    tween.Completed:Connect(function() petal:Destroy() end)
end

local function blossomBurst(parent, x, y, count, opts)
    opts = opts or {}
    count = count or 14
    for i = 1, count do
        task.wait(math.random(0, 3) / 100)
        createPetal(parent, x, y, {
            size = opts.size or math.random(6, 12),
            life = opts.life or math.random(0.7, 1.4),
            spreadX = opts.spreadX or math.random(-100, 100),
            spreadY = opts.spreadY or math.random(-160, -40),
        })
    end
end

local function clickRipple(parent, x, y, color)
    local ring = Instance.new("Frame")
    ring.Size = UDim2.fromOffset(4, 4)
    ring.Position = UDim2.new(0, x - 2, 0, y - 2)
    ring.BackgroundColor3 = color or Color3.fromRGB(255, 190, 210)
    ring.BackgroundTransparency = 0.2
    ring.BorderSizePixel = 0
    ring.ZIndex = 99
    ring.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 200, 220)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = ring
    local tween = TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(70, 70),
        Position = UDim2.new(0, x - 35, 0, y - 35),
        BackgroundTransparency = 1,
    })
    TweenService:Create(stroke, TweenInfo.new(0.6), { Transparency = 1 }):Play()
    tween:Play()
    tween.Completed:Connect(function() ring:Destroy() end)
end

-- ============================================================
-- DETECTION HELPERS
-- ============================================================

local function findNearestEgg()
    local hrp = getHRP()
    if not hrp then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if not State.Running then return nil end
        local name = obj.Name:lower()
        if (name:find("egg") or name:find("rift") or name:find("sakura"))
            and obj:IsA("BasePart") and obj.Parent
            and not obj.Parent:FindFirstChild("Owner") then
            local dist = (hrp.Position - obj.Position).Magnitude
            if dist < nearestDist and dist < 300 then
                nearestDist = dist
                nearest = obj
            end
        end
    end
    return nearest
end

local function findTargetEgg()
    if HuntState.TargetLower == "" then return nil end
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if not State.Running then return nil end
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = string.lower(obj.Name)
            if n:find(HuntState.TargetLower, 1, true) then
                local root = obj:IsA("BasePart") and obj
                    or (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart)
                if root then
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        best = root
                    end
                end
            end
        end
    end
    return best
end

local function findBoss()
    local hrp = getHRP()
    if not hrp then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if not State.Running then break end
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            local isBoss = name:find("boss") or name:find("rift")
                or name:find("abyss") or name:find("overlord")
                or name:find("mech") or name:find("scramble")
                or name:find("crystal") or name:find("bloom")
            if isBoss then
                local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart")
                local bossHum = obj:FindFirstChildOfClass("Humanoid")
                if head and bossHum and bossHum.Health > 0 then
                    local dist = (hrp.Position - head.Position).Magnitude
                    if dist < nearestDist and dist < 400 then
                        nearestDist = dist
                        nearest = obj
                    end
                end
            end
        end
    end
    return nearest
end

local function findCrystalTree()
    local hrp = getHRP()
    if not hrp then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if not State.Running then break end
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if (name:find("crystal") or name:find("bloom tree") or name:find("sakura tree"))
                and not name:find("egg") then
                local dist = (hrp.Position - obj.Position).Magnitude
                if dist < nearestDist and dist < 300 then
                    nearestDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

local function isHealthLow()
    local hum = getHumanoid()
    if not hum then return true end
    return (hum.Health / hum.MaxHealth) * 100 < Config.BossRetreatHealth
end

-- ============================================================
-- SERVER HOP
-- ============================================================

local function getServers(cursor)
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
        .. "/servers/Public?sortOrder=Asc&limit=100"
    if cursor then url = url .. "&cursor=" .. cursor end
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not ok or not res then return nil end
    return res
end

local function findHopTarget()
    local pagesChecked = 0
    local cursor = nil
    local best, bestScore = nil, math.huge
    repeat
        local res = getServers(cursor)
        if not res or not res.data then break end
        for _, srv in pairs(res.data) do
            if not State.Running then return nil end
            if srv.id == game.JobId then continue end
            if srv.playing >= srv.maxPlayers then continue end
            local score = srv.playing
            if srv.playing == 0 then score = -1 end
            if srv.playing == 1 then score = 0 end
            if HopConfig.PreferLowPop and srv.playing > 3 then score = score + 10 end
            if score < bestScore then
                bestScore = score
                best = srv
            end
        end
        cursor = res.nextPageCursor
        pagesChecked = pagesChecked + 1
        task.wait(0.15)
    until not cursor or pagesChecked >= HopConfig.MaxPages
    return best
end

local function hopToServer(server)
    if not server then return false end
    task.wait(math.random(200, 600) / 100)
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
    end)
    return ok
end

local function tryHop(reason)
    if not HopConfig.Enabled then return false end
    if tick() - HopState.LastHop < HopConfig.HopCooldown then return false end
    if tick() - HopState.RareAlertTime < 30 then
        ui.setStatus("rare active — not hopping")
        return false
    end
    local target = findHopTarget()
    if not target then
        ui.setStatus("hop: no servers")
        return false
    end
    local success = hopToServer(target)
    if success then
        HopState.LastHop = tick()
        HopState.EmptyCycles = 0
        ui.setStatus("hopping — " .. reason)
    end
    return success
end

local function huntHop()
    local target = findHopTarget()
    if not target then return false end
    ui.setStatus("hunt hop → " .. target.playing .. "p")
    task.wait(math.random(150, 400) / 100)
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, LocalPlayer)
    end)
    if ok then
        HopState.LastHop = tick()
        HuntState.HopsThisCycle = HuntState.HopsThisCycle + 1
    end
    return ok
end

-- ============================================================
-- BASE RETURN
-- ============================================================

local function refreshBaseMarker()
    if BaseState.MarkerPart then BaseState.MarkerPart:Destroy() end
    if BaseState.MarkerRing then BaseState.MarkerRing:Destroy() end
    BaseState.MarkerPart = nil
    BaseState.MarkerRing = nil
    if not BaseConfig.Position or not BaseConfig.MarkerEnabled then return end

    local marker = Instance.new("Part")
    marker.Name = "LunaBaseMarker"
    marker.Size = Vector3.new(4, 0.2, 4)
    marker.Position = BaseConfig.Position + Vector3.new(0, 0.1, 0)
    marker.Anchored = true
    marker.CanCollide = false
    marker.Material = Enum.Material.Neon
    marker.Color = Color3.fromRGB(255, 160, 195)
    marker.Transparency = 0.5
    marker.Parent = workspace

    local ring = Instance.new("Part")
    ring.Name = "LunaBaseRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.2, 8, 8)
    ring.Position = BaseConfig.Position + Vector3.new(0, 0.2, 0)
    ring.Anchored = true
    ring.CanCollide = false
    ring.Material = Enum.Material.Neon
    ring.Color = Color3.fromRGB(255, 190, 215)
    ring.Transparency = 0.7
    ring.Orientation = Vector3.new(0, 0, 90)
    ring.Parent = workspace

    BaseState.MarkerPart = marker
    BaseState.MarkerRing = ring

    task.spawn(function()
        while marker.Parent do
            TweenService:Create(ring, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.9, Size = Vector3.new(0.2, 10, 10),
            }):Play()
            task.wait(1.2)
            if not marker.Parent then break end
            TweenService:Create(ring, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.7, Size = Vector3.new(0.2, 8, 8),
            }):Play()
            task.wait(1.2)
        end
    end)
end

local function setBasePoint(pos)
    BaseConfig.Position = pos
    refreshBaseMarker()
end

local function walkAwayFrom(point, distance)
    local hrp = getHRP()
    if not hrp then return false end
    local dir = (hrp.Position - point)
    if dir.Magnitude < 1 then
        dir = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
    end
    local target = hrp.Position + dir.Unit * distance
    return walkTo(target, 6)
end

local function teleportTo(pos)
    local hrp = getHRP()
    if not hrp then return false end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    return true
end

local function returnToBase(stealOrigin)
    if State.InCombat then
        ui.setStatus("in combat — deferring return")
        return false
    end
    if not BaseConfig.Position then
        ui.setStatus("no base set")
        return false
    end
    if BaseState.Returning then return false end
    if tick() - BaseState.LastReturn < BaseConfig.PostReturnCooldown then return false end

    BaseState.Returning = true
    ui.setStatus("returning")

    local method = BaseConfig.ReturnMethod
    if method == "hybrid" and stealOrigin then
        walkAwayFrom(stealOrigin, BaseConfig.SafeOffset)
        task.wait(math.random(10, 30) / 10)
        teleportTo(BaseConfig.Position)
    elseif method == "teleport" then
        task.wait(BaseConfig.PostStealDelay)
        teleportTo(BaseConfig.Position)
    elseif method == "walk" then
        task.wait(BaseConfig.PostStealDelay)
        walkTo(BaseConfig.Position, 30)
    end

    task.wait(0.4)
    BaseState.LastReturn = tick()
    BaseState.Returning = false
    ui.setStatus("at base")
    return true
end

-- ============================================================
-- UI
-- ============================================================

local ui

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LunaScript"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local ambientLayer = Instance.new("Frame")
    ambientLayer.Size = UDim2.fromScale(1, 1)
    ambientLayer.BackgroundTransparency = 1
    ambientLayer.ZIndex = 1
    ambientLayer.Parent = screenGui

    local main = Instance.new("Frame")
    main.Size = UDim2.fromOffset(300, 740)
    main.Position = UDim2.new(0.5, -150, 0.5, -370)
    main.BackgroundColor3 = Color3.fromRGB(28, 16, 26)
    main.BackgroundTransparency = 0.08
    main.BorderSizePixel = 0
    main.ZIndex = 10
    main.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(255, 160, 195)
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.35
    mainStroke.Parent = main

    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1, 60, 1, 60)
    glow.Position = UDim2.new(0, -30, 0, -30)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://5028857084"
    glow.ImageColor3 = Color3.fromRGB(255, 150, 190)
    glow.ImageTransparency = 0.85
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(24, 24, 276, 276)
    glow.ZIndex = 9
    glow.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 54)
    title.BackgroundTransparency = 1
    title.Text = "LUNA"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 32
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.ZIndex = 12
    title.Parent = main

    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 230, 245)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 200)),
    })
    titleGradient.Parent = title

    task.spawn(function()
        while title.Parent do
            titleGradient.Rotation = (titleGradient.Rotation + 1.2) % 360
            task.wait(0.03)
        end
    end)

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 16)
    subtitle.Position = UDim2.new(0, 0, 0, 46)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "cherry blossom automation"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextColor3 = Color3.fromRGB(210, 170, 190)
    subtitle.ZIndex = 12
    subtitle.Parent = main

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0.8, 0, 0, 1)
    divider.Position = UDim2.new(0.1, 0, 0, 70)
    divider.BackgroundColor3 = Color3.fromRGB(255, 170, 200)
    divider.BackgroundTransparency = 0.3
    divider.BorderSizePixel = 0
    divider.ZIndex = 12
    divider.Parent = main

    local dividerGradient = Instance.new("UIGradient")
    dividerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    dividerGradient.Parent = divider

    task.spawn(function()
        while divider.Parent do
            dividerGradient.Offset = Vector2.new(math.sin(tick()) * 1.5, 0)
            task.wait(0.03)
        end
    end)

    local toggles = {}

    local function createToggle(name, yPos, default, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0.85, 0, 0, 32)
        container.Position = UDim2.new(0.075, 0, 0, yPos)
        container.BackgroundTransparency = 1
        container.ZIndex = 12
        container.Parent = main

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 12
        label.TextColor3 = Color3.fromRGB(235, 215, 225)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 12
        label.Parent = container

        local toggleBg = Instance.new("Frame")
        toggleBg.Size = UDim2.fromOffset(44, 22)
        toggleBg.Position = UDim2.new(1, -44, 0.5, -11)
        toggleBg.BackgroundColor3 = default and Color3.fromRGB(255, 160, 195) or Color3.fromRGB(60, 40, 55)
        toggleBg.BorderSizePixel = 0
        toggleBg.ZIndex = 12
        toggleBg.Parent = container

        local tc = Instance.new("UICorner")
        tc.CornerRadius = UDim.new(1, 0)
        tc.Parent = toggleBg

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(18, 18)
        knob.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 13
        knob.Parent = toggleBg

        local kc = Instance.new("UICorner")
        kc.CornerRadius = UDim.new(1, 0)
        kc.Parent = knob

        local enabled = default

        local function setState(newState, silent)
            enabled = newState
            TweenService:Create(toggleBg, TweenInfo.new(0.18), {
                BackgroundColor3 = enabled and Color3.fromRGB(255, 160, 195) or Color3.fromRGB(60, 40, 55)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = enabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            }):Play()
            if not silent then
                playSound(enabled and SoundBank.ToggleOn or SoundBank.ToggleOff, 0.35, 1.1)
                local abs = toggleBg.AbsolutePosition
                local absSize = toggleBg.AbsoluteSize
                local relX = abs.X - main.AbsolutePosition.X + absSize.X / 2
                local relY = abs.Y - main.AbsolutePosition.Y + absSize.Y / 2
                clickRipple(main, relX, relY)
                blossomBurst(main, relX, relY, enabled and 16 or 8)
            end
            if callback then callback(enabled) end
        end

        toggleBg.MouseEnter:Connect(function()
            playSound(SoundBank.Click, 0.06, 1.4)
            TweenService:Create(toggleBg, TweenInfo.new(0.15), {
                BackgroundColor3 = enabled and Color3.fromRGB(255, 180, 210) or Color3.fromRGB(85, 55, 75)
            }):Play()
            TweenService:Create(label, TweenInfo.new(0.15), {
                TextColor3 = Color3.fromRGB(255, 220, 235)
            }):Play()
        end)
        toggleBg.MouseLeave:Connect(function()
            TweenService:Create(toggleBg, TweenInfo.new(0.15), {
                BackgroundColor3 = enabled and Color3.fromRGB(255, 160, 195) or Color3.fromRGB(60, 40, 55)
            }):Play()
            TweenService:Create(label, TweenInfo.new(0.15), {
                TextColor3 = Color3.fromRGB(235, 215, 225)
            }):Play()
        end)
        toggleBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                setState(not enabled)
            end
        end)

        return { setState = setState, getState = function() return enabled end }
    end

    toggles.steal = createToggle("Auto Steal", 80, Config.AutoSteal, function(v) Config.AutoSteal = v end)
    toggles.event = createToggle("Auto Event", 114, Config.AutoEvent, function(v) Config.AutoEvent = v end)
    toggles.hatch = createToggle("Auto Hatch", 148, Config.AutoHatch, function(v) Config.AutoHatch = v end)
    toggles.treadmill = createToggle("Auto Treadmill", 182, Config.AutoTreadmill, function(v) Config.AutoTreadmill = v end)
    toggles.combat = createToggle("Auto Combat", 216, Config.AutoCombat, function(v) Config.AutoCombat = v end)
    toggles.sounds = createToggle("Sounds", 250, Config.SoundsEnabled, function(v) Config.SoundsEnabled = v end)

    -- TARGET HUNT PANEL
    local huntContainer = Instance.new("Frame")
    huntContainer.Size = UDim2.new(0.85, 0, 0, 100)
    huntContainer.Position = UDim2.new(0.075, 0, 0, 288)
    huntContainer.BackgroundColor3 = Color3.fromRGB(38, 22, 36)
    huntContainer.BackgroundTransparency = 0.3
    huntContainer.BorderSizePixel = 0
    huntContainer.ZIndex = 12
    huntContainer.Parent = main

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 8)
    hc.Parent = huntContainer

    local hcs = Instance.new("UIStroke")
    hcs.Color = Color3.fromRGB(255, 160, 195)
    hcs.Thickness = 1
    hcs.Transparency = 0.6
    hcs.Parent = huntContainer

    local hLabel = Instance.new("TextLabel")
    hLabel.Size = UDim2.new(1, -12, 0, 16)
    hLabel.Position = UDim2.new(0, 6, 0, 4)
    hLabel.BackgroundTransparency = 1
    hLabel.Text = "target hunt"
    hLabel.Font = Enum.Font.GothamBold
    hLabel.TextSize = 11
    hLabel.TextColor3 = Color3.fromRGB(255, 200, 220)
    hLabel.TextXAlignment = Enum.TextXAlignment.Left
    hLabel.ZIndex = 13
    hLabel.Parent = huntContainer

    -- egg dropdown
    local eggBox = Instance.new("Frame")
    eggBox.Size = UDim2.new(0.66, -8, 0, 24)
    eggBox.Position = UDim2.new(0, 6, 0, 24)
    eggBox.BackgroundColor3 = Color3.fromRGB(25, 14, 23)
    eggBox.BackgroundTransparency = 0.15
    eggBox.BorderSizePixel = 0
    eggBox.ZIndex = 13
    eggBox.Parent = huntContainer

    local ebCorner = Instance.new("UICorner")
    ebCorner.CornerRadius = UDim.new(0, 5)
    ebCorner.Parent = eggBox

    local eggDisplay = Instance.new("TextLabel")
    eggDisplay.Size = UDim2.new(1, -24, 1, 0)
    eggDisplay.Position = UDim2.new(0, 8, 0, 0)
    eggDisplay.BackgroundTransparency = 1
    eggDisplay.Text = "select egg…"
    eggDisplay.Font = Enum.Font.Gotham
    eggDisplay.TextSize = 11
    eggDisplay.TextColor3 = Color3.fromRGB(255, 215, 230)
    eggDisplay.TextXAlignment = Enum.TextXAlignment.Left
    eggDisplay.ZIndex = 14
    eggDisplay.Parent = eggBox

    local eggArrow = Instance.new("TextLabel")
    eggArrow.Size = UDim2.fromOffset(20, 24)
    eggArrow.Position = UDim2.new(1, -22, 0, 0)
    eggArrow.BackgroundTransparency = 1
    eggArrow.Text = "▾"
    eggArrow.Font = Enum.Font.GothamBold
    eggArrow.TextSize = 12
    eggArrow.TextColor3 = Color3.fromRGB(255, 160, 195)
    eggArrow.ZIndex = 14
    eggArrow.Parent = eggBox

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(1, 0, 0, 160)
    listFrame.Position = UDim2.new(0, 0, 1, 4)
    listFrame.BackgroundColor3 = Color3.fromRGB(20, 12, 18)
    listFrame.BackgroundTransparency = 0.05
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 4
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 160, 195)
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.Visible = false
    listFrame.ZIndex = 22
    listFrame.Parent = eggBox

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, 0, 0, 24)
    searchBox.BackgroundColor3 = Color3.fromRGB(35, 20, 32)
    searchBox.BackgroundTransparency = 0.2
    searchBox.BorderSizePixel = 0
    searchBox.Text = ""
    searchBox.PlaceholderText = "search…"
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 10
    searchBox.TextColor3 = Color3.fromRGB(255, 215, 230)
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 95, 110)
    searchBox.ZIndex = 23
    searchBox.LayoutOrder = 0
    searchBox.Parent = listFrame

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 4)
    searchCorner.Parent = searchBox

    local eggButtons = {}
    local function rebuildEggList(filter)
        for _, b in pairs(eggButtons) do b:Destroy() end
        eggButtons = {}
        local filterLower = string.lower(filter or "")
        for i, egg in ipairs(EggDatabase) do
            if filterLower == "" or string.lower(egg.name):find(filterLower, 1, true)
                or string.lower(egg.biome):find(filterLower, 1, true) then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -4, 0, 22)
                btn.BackgroundColor3 = Color3.fromRGB(30, 18, 28)
                btn.BackgroundTransparency = 0.2
                btn.BorderSizePixel = 0
                btn.Text = "  " .. egg.name .. "  (" .. egg.rarity .. ")"
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 10
                btn.TextColor3 = Color3.fromRGB(220, 195, 210)
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.ZIndex = 23
                btn.LayoutOrder = i
                btn.Parent = listFrame

                btn.MouseEnter:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.1), {
                        BackgroundColor3 = Color3.fromRGB(60, 35, 55)
                    }):Play()
                end)
                btn.MouseLeave:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.1), {
                        BackgroundColor3 = Color3.fromRGB(30, 18, 28)
                    }):Play()
                end)
                btn.MouseButton1Click:Connect(function()
                    eggDisplay.Text = egg.name
                    setHuntTarget(egg.name)
                    listFrame.Visible = false
                    playSound(SoundBank.Click, 0.2, 1.3)
                end)
                table.insert(eggButtons, btn)
            end
        end
        listFrame.CanvasSize = UDim2.new(0, 0, 0, #eggButtons * 24 + 30)
    end
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        rebuildEggList(searchBox.Text)
    end)
    eggBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            listFrame.Visible = not listFrame.Visible
            if listFrame.Visible then
                rebuildEggList("")
                playSound(SoundBank.Click, 0.15, 1.2)
            end
        end
    end)
    rebuildEggList("")

    local huntBtn = Instance.new("TextButton")
    huntBtn.Size = UDim2.new(0.32, -6, 0, 24)
    huntBtn.Position = UDim2.new(0.68, 2, 0, 24)
    huntBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 55)
    huntBtn.Text = "hunt"
    huntBtn.Font = Enum.Font.GothamBold
    huntBtn.TextSize = 11
    huntBtn.TextColor3 = Color3.fromRGB(255, 220, 235)
    huntBtn.BorderSizePixel = 0
    huntBtn.ZIndex = 13
    huntBtn.Parent = huntContainer

    local hbCorner = Instance.new("UICorner")
    hbCorner.CornerRadius = UDim.new(0, 5)
    hbCorner.Parent = huntBtn

    local huntHint = Instance.new("TextLabel")
    huntHint.Size = UDim2.new(1, -12, 0, 14)
    huntHint.Position = UDim2.new(0, 6, 0, 52)
    huntHint.BackgroundTransparency = 1
    huntHint.Text = "auto-hops until target egg is found"
    huntHint.Font = Enum.Font.Gotham
    huntHint.TextSize = 9
    huntHint.TextColor3 = Color3.fromRGB(160, 130, 145)
    huntHint.TextXAlignment = Enum.TextXAlignment.Left
    huntHint.ZIndex = 13
    huntHint.Parent = huntContainer

    local huntStatus = Instance.new("TextLabel")
    huntStatus.Size = UDim2.new(1, -12, 0, 16)
    huntStatus.Position = UDim2.new(0, 6, 0, 70)
    huntStatus.BackgroundTransparency = 1
    huntStatus.Text = "hunting: —"
    huntStatus.Font = Enum.Font.Gotham
    huntStatus.TextSize = 10
    huntStatus.TextColor3 = Color3.fromRGB(255, 190, 215)
    huntStatus.TextXAlignment = Enum.TextXAlignment.Left
    huntStatus.ZIndex = 13
    huntStatus.Parent = huntContainer

    local isHunting = false
    local function setHunt(newState, silent)
        isHunting = newState
        HuntConfig.Enabled = newState
        if newState then
            if HuntState.TargetLower == "" then
                setHuntTarget(eggDisplay.Text ~= "select egg…" and eggDisplay.Text or "")
            end
            if HuntState.TargetLower == "" then
                ui.setStatus("pick an egg first")
                isHunting = false
                HuntConfig.Enabled = false
                return
            end
            HuntState.HopsThisCycle = 0
            huntStatus.Text = "hunting: " .. HuntConfig.TargetName
            TweenService:Create(huntBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(255, 160, 195),
                TextColor3 = Color3.fromRGB(30, 15, 25),
            }):Play()
            if not silent then
                playSound(SoundBank.ToggleOn, 0.4, 1.2)
                blossomBurst(huntContainer, 200, 36, 18)
            end
        else
            huntStatus.Text = "hunting: —"
            TweenService:Create(huntBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(60, 40, 55),
                TextColor3 = Color3.fromRGB(255, 220, 235),
            }):Play()
            if not silent then
                playSound(SoundBank.ToggleOff, 0.3, 0.9)
                blossomBurst(huntContainer, 200, 36, 8)
            end
        end
    end
    huntBtn.MouseButton1Click:Connect(function() setHunt(not isHunting) end)
    toggles.hunt = { setState = function(v, silent) setHunt(v, silent) end }

    -- AGGRESSION SLIDER
    local aggressionContainer = Instance.new("Frame")
    aggressionContainer.Size = UDim2.new(0.85, 0, 0, 44)
    aggressionContainer.Position = UDim2.new(0.075, 0, 0, 396)
    aggressionContainer.BackgroundTransparency = 1
    aggressionContainer.ZIndex = 12
    aggressionContainer.Parent = main

    local aggLabel = Instance.new("TextLabel")
    aggLabel.Size = UDim2.new(1, 0, 0, 14)
    aggLabel.BackgroundTransparency = 1
    aggLabel.Text = "hop aggression"
    aggLabel.Font = Enum.Font.Gotham
    aggLabel.TextSize = 10
    aggLabel.TextColor3 = Color3.fromRGB(200, 170, 185)
    aggLabel.TextXAlignment = Enum.TextXAlignment.Left
    aggLabel.ZIndex = 12
    aggLabel.Parent = aggressionContainer

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 26)
    track.Position = UDim2.new(0, 0, 0, 16)
    track.BackgroundColor3 = Color3.fromRGB(40, 24, 38)
    track.BorderSizePixel = 0
    track.ZIndex = 12
    track.Parent = aggressionContainer

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local trackStroke = Instance.new("UIStroke")
    trackStroke.Color = Color3.fromRGB(255, 160, 195)
    trackStroke.Thickness = 1
    trackStroke.Transparency = 0.7
    trackStroke.Parent = track

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.fromOffset(74, 22)
    indicator.Position = UDim2.new(1/3, 2, 0.5, -11)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 160, 195)
    indicator.BackgroundTransparency = 0.15
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 13
    indicator.Parent = track

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator

    local aggOptions = { "passive", "balanced", "aggressive" }
    local aggButtons = {}
    for i, name in ipairs(aggOptions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/3, 0, 1, 0)
        btn.Position = UDim2.new((i-1)/3, 0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = name
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 10
        btn.TextColor3 = (i == 2) and Color3.fromRGB(30, 15, 25) or Color3.fromRGB(180, 150, 165)
        btn.ZIndex = 14
        btn.Parent = track

        btn.MouseButton1Click:Connect(function()
            local preset = HopPresets[name]
            if not preset then return end
            HopConfig.CurrentPreset = name
            for k, v in pairs(preset) do HopConfig[k] = v end
            TweenService:Create(indicator, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new((i-1)/3, 2, 0.5, -11)
            }):Play()
            for j, other in ipairs(aggButtons) do
                TweenService:Create(other, TweenInfo.new(0.2), {
                    TextColor3 = (j == i) and Color3.fromRGB(30, 15, 25) or Color3.fromRGB(180, 150, 165)
                }):Play()
            end
            playSound(SoundBank.ToggleOn, 0.35, 1 + i * 0.05)
            blossomBurst(aggressionContainer, btn.AbsolutePosition.X - aggressionContainer.AbsolutePosition.X + 40, 25, 12)
        end)
        table.insert(aggButtons, btn)
    end

    -- BASE PANEL
    local baseContainer = Instance.new("Frame")
    baseContainer.Size = UDim2.new(0.85, 0, 0, 86)
    baseContainer.Position = UDim2.new(0.075, 0, 0, 450)
    baseContainer.BackgroundColor3 = Color3.fromRGB(38, 22, 36)
    baseContainer.BackgroundTransparency = 0.3
    baseContainer.BorderSizePixel = 0
    baseContainer.ZIndex = 12
    baseContainer.Parent = main

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = baseContainer

    local bcs = Instance.new("UIStroke")
    bcs.Color = Color3.fromRGB(255, 160, 195)
    bcs.Thickness = 1
    bcs.Transparency = 0.6
    bcs.Parent = baseContainer

    local bLabel = Instance.new("TextLabel")
    bLabel.Size = UDim2.new(1, -12, 0, 16)
    bLabel.Position = UDim2.new(0, 6, 0, 4)
    bLabel.BackgroundTransparency = 1
    bLabel.Text = "base return"
    bLabel.Font = Enum.Font.GothamBold
    bLabel.TextSize = 11
    bLabel.TextColor3 = Color3.fromRGB(255, 200, 220)
    bLabel.TextXAlignment = Enum.TextXAlignment.Left
    bLabel.ZIndex = 13
    bLabel.Parent = baseContainer

    local setBtn = Instance.new("TextButton")
    setBtn.Size = UDim2.new(0.48, -6, 0, 22)
    setBtn.Position = UDim2.new(0, 6, 0, 24)
    setBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 55)
    setBtn.Text = "set base here"
    setBtn.Font = Enum.Font.GothamBold
    setBtn.TextSize = 10
    setBtn.TextColor3 = Color3.fromRGB(255, 220, 235)
    setBtn.BorderSizePixel = 0
    setBtn.ZIndex = 13
    setBtn.Parent = baseContainer

    local sbc = Instance.new("UICorner")
    sbc.CornerRadius = UDim.new(0, 5)
    sbc.Parent = setBtn

    local baseStatus = Instance.new("TextLabel")
    baseStatus.Size = UDim2.new(1, -12, 0, 14)
    baseStatus.Position = UDim2.new(0, 6, 0, 52)
    baseStatus.BackgroundTransparency = 1
    baseStatus.Text = "base: not set"
    baseStatus.Font = Enum.Font.Gotham
    baseStatus.TextSize = 9
    baseStatus.TextColor3 = Color3.fromRGB(190, 160, 175)
    baseStatus.TextXAlignment = Enum.TextXAlignment.Left
    baseStatus.ZIndex = 13
    baseStatus.Parent = baseContainer

    setBtn.MouseButton1Click:Connect(function()
        local hrp = getHRP()
        if hrp then
            setBasePoint(hrp.Position)
            baseStatus.Text = string.format("base: %.0f, %.0f, %.0f",
                hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
            playSound(SoundBank.ToggleOn, 0.4, 1.2)
            blossomBurst(baseContainer, 60, 36, 14)
        end
    end)

    local methodBtn = Instance.new("TextButton")
    methodBtn.Size = UDim2.new(0.48, -6, 0, 22)
    methodBtn.Position = UDim2.new(0.52, 0, 0, 24)
    methodBtn.BackgroundColor3 = Color3.fromRGB(45, 28, 42)
    methodBtn.Text = "hybrid"
    methodBtn.Font = Enum.Font.GothamBold
    methodBtn.TextSize = 10
    methodBtn.TextColor3 = Color3.fromRGB(255, 200, 140)
    methodBtn.BorderSizePixel = 0
    methodBtn.ZIndex = 13
    methodBtn.Parent = baseContainer

    local mbc = Instance.new("UICorner")
    mbc.CornerRadius = UDim.new(0, 5)
    mbc.Parent = methodBtn

    local methods = { "teleport", "hybrid", "walk" }
    local methodIdx = 2
    methodBtn.MouseButton1Click:Connect(function()
        methodIdx = methodIdx + 1
        if methodIdx > #methods then methodIdx = 1 end
        BaseConfig.ReturnMethod = methods[methodIdx]
        methodBtn.Text = methods[methodIdx]
        playSound(SoundBank.Click, 0.2, 1.2)
        methodBtn.TextColor3 = methods[methodIdx] == "teleport" and Color3.fromRGB(255, 140, 140)
            or methods[methodIdx] == "hybrid" and Color3.fromRGB(255, 200, 140)
            or Color3.fromRGB(140, 255, 180)
    end)

    local autoRetBtn = Instance.new("TextButton")
    autoRetBtn.Size = UDim2.new(1, -12, 0, 16)
    autoRetBtn.Position = UDim2.new(0, 6, 0, 66)
    autoRetBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 195)
    autoRetBtn.Text = "auto-return: ON"
    autoRetBtn.Font = Enum.Font.Gotham
    autoRetBtn.TextSize = 9
    autoRetBtn.TextColor3 = Color3.fromRGB(30, 15, 25)
    autoRetBtn.BorderSizePixel = 0
    autoRetBtn.ZIndex = 13
    autoRetBtn.Parent = baseContainer

    local arc = Instance.new("UICorner")
    arc.CornerRadius = UDim.new(0, 4)
    arc.Parent = autoRetBtn

    autoRetBtn.MouseButton1Click:Connect(function()
        BaseConfig.AutoReturn = not BaseConfig.AutoReturn
        autoRetBtn.Text = "auto-return: " .. (BaseConfig.AutoReturn and "ON" or "OFF")
        autoRetBtn.BackgroundColor3 = BaseConfig.AutoReturn and Color3.fromRGB(255, 160, 195) or Color3.fromRGB(60, 40, 55)
        autoRetBtn.TextColor3 = BaseConfig.AutoReturn and Color3.fromRGB(30, 15, 25) or Color3.fromRGB(255, 220, 235)
        playSound(BaseConfig.AutoReturn and SoundBank.ToggleOn or SoundBank.ToggleOff, 0.3, 1.1)
    end)

    -- STATUS BAR
    local statusBg = Instance.new("Frame")
    statusBg.Size = UDim2.new(0.85, 0, 0, 26)
    statusBg.Position = UDim2.new(0.075, 0, 0, 556)
    statusBg.BackgroundColor3 = Color3.fromRGB(40, 24, 38)
    statusBg.BackgroundTransparency = 0.3
    statusBg.BorderSizePixel = 0
    statusBg.ZIndex = 12
    statusBg.Parent = main

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusBg

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.fromOffset(6, 6)
    statusDot.Position = UDim2.new(0, 10, 0.5, -3)
    statusDot.BackgroundColor3 = Color3.fromRGB(120, 255, 140)
    statusDot.BorderSizePixel = 0
    statusDot.ZIndex = 13
    statusDot.Parent = statusBg

    local sdc = Instance.new("UICorner")
    sdc.CornerRadius = UDim.new(1, 0)
    sdc.Parent = statusDot

    task.spawn(function()
        while statusDot.Parent do
            TweenService:Create(statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.6
            }):Play()
            task.wait(0.8)
            TweenService:Create(statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0
            }):Play()
            task.wait(0.8)
        end
    end)

    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -26, 1, 0)
    statusText.Position = UDim2.new(0, 22, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "ready"
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 11
    statusText.TextColor3 = Color3.fromRGB(215, 195, 205)
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.ZIndex = 13
    statusText.Parent = statusBg

    -- HOP BUTTON
    local hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(0.85, 0, 0, 24)
    hopBtn.Position = UDim2.new(0.075, 0, 0, 590)
    hopBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 50)
    hopBtn.Text = "hop now"
    hopBtn.Font = Enum.Font.Gotham
    hopBtn.TextSize = 11
    hopBtn.TextColor3 = Color3.fromRGB(255, 190, 210)
    hopBtn.BorderSizePixel = 0
    hopBtn.ZIndex = 12
    hopBtn.Parent = main

    local hopCorner = Instance.new("UICorner")
    hopCorner.CornerRadius = UDim.new(0, 6)
    hopCorner.Parent = hopBtn

    hopBtn.MouseButton1Click:Connect(function()
        clickRipple(main, 150, 602)
        blossomBurst(main, 150, 602, 12)
        tryHop("manual")
    end)

    local killHint = Instance.new("TextLabel")
    killHint.Size = UDim2.new(1, 0, 0, 14)
    killHint.Position = UDim2.new(0, 0, 0, 620)
    killHint.BackgroundTransparency = 1
    killHint.Text = "RightShift — stop all"
    killHint.Font = Enum.Font.Gotham
    killHint.TextSize = 9
    killHint.TextColor3 = Color3.fromRGB(140, 105, 120)
    killHint.ZIndex = 12
    killHint.Parent = main

    -- DRAG
    local dragging = false
    local dragStart, startPos
    local lastTrail = 0

    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            local rel = input.Position - main.AbsolutePosition
            playSound(SoundBank.Click, 0.25, math.random(10, 14) / 10)
            clickRipple(main, rel.X, rel.Y)
            blossomBurst(main, rel.X, rel.Y, 10)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            if tick() - lastTrail > 0.06 then
                lastTrail = tick()
                local rel = input.Position - main.AbsolutePosition
                createPetal(main, rel.X, rel.Y, {
                    size = math.random(4, 8), life = 0.9,
                    spreadX = math.random(-40, 40), spreadY = math.random(-60, 20),
                })
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- AMBIENT PETALS
    task.spawn(function()
        while screenGui.Parent do
            createPetal(ambientLayer, math.random(0, 1920), -10, {
                size = math.random(4, 9),
                life = math.random(4, 7),
                spreadX = math.random(-120, 120),
                spreadY = math.random(700, 1100),
            })
            task.wait(math.random(20, 70) / 100)
        end
    end)

    return {
        setStatus = function(text) statusText.Text = text end,
        setDotColor = function(c) statusDot.BackgroundColor3 = c end,
        screenGui = screenGui,
        main = main,
        toggles = toggles,
        refreshBaseStatus = function()
            if BaseConfig.Position then
                baseStatus.Text = string.format("base: %.0f, %.0f, %.0f",
                    BaseConfig.Position.X, BaseConfig.Position.Y, BaseConfig.Position.Z)
            end
        end,
    }
end

-- ============================================================
-- ANTI-DETECTION
-- ============================================================

local function enforceSpeedCap()
    local hum = getHumanoid()
    if hum and hum.WalkSpeed > Config.WalkSpeedCap then
        hum.WalkSpeed = Config.WalkSpeedCap
    end
end

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ============================================================
-- COMBAT LOOP
-- ============================================================

local function attackTarget(boss)
    if not boss or not boss.Parent then return end
    local bossHum = boss:FindFirstChildOfClass("Humanoid")
    if not bossHum or bossHum.Health <= 0 then return end
    local head = boss:FindFirstChild("Head") or boss:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local hrp = getHRP()
    if not hrp then return end
    if (hrp.Position - head.Position).Magnitude > Config.CombatRange then
        walkTo(head.Position, 5)
    end
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        playSound(SoundBank.BossHit, 0.2, math.random(9, 12) / 10)
    end
    local prompt = boss:FindFirstChildOfClass("ProximityPrompt")
        or (head and head:FindFirstChildOfClass("ProximityPrompt"))
    if prompt then firePrompt(prompt) end
end

local function combatLoop()
    while State.Running do
        task.wait(0.15)
        if not State.Running then break end
        if not Config.AutoCombat then State.InCombat = false; continue end
        local boss = findBoss()
        if boss then
            State.InCombat = true
            State.BossRef = boss
            ui.setStatus("combat: " .. boss.Name)
            if isHealthLow() then
                local spawnLoc = workspace:FindFirstChild("SpawnLocation")
                if spawnLoc then
                    walkTo(spawnLoc.Position, 8)
                    State.InCombat = false
                    ui.setStatus("retreating")
                    task.wait(1)
                    continue
                end
            end
            attackTarget(boss)
        else
            State.InCombat = false
            State.BossRef = nil
        end
    end
end

-- ============================================================
-- HUNT LOOP
-- ============================================================

local function chatMentionsTarget()
    if HuntState.TargetLower == "" then return false end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local chat = playerGui:FindFirstChild("Chat")
    if not chat then return false end
    for _, msg in pairs(chat:GetDescendants()) do
        if msg:IsA("TextLabel") and msg.Text then
            if string.lower(msg.Text):find(HuntState.TargetLower, 1, true) then
                return true
            end
        end
    end
    return false
end

local function huntLoop()
    while State.Running do
        task.wait(0.5)
        if not State.Running then break end
        if not HuntConfig.Enabled or HuntState.TargetLower == "" then
            HuntState.Active = false
            continue
        end
        HuntState.Active = true
        HuntState.Found = false

        local waited = 0
        while not getHRP() and waited < HuntConfig.PostHopWait do
            task.wait(0.5)
            waited = waited + 0.5
            if not State.Running then return end
        end
        if not getHRP() then continue end

        ui.setStatus("hunting: " .. HuntConfig.TargetName)
        HuntState.LastScanStart = tick()

        local found = nil
        while tick() - HuntState.LastScanStart < HuntConfig.ScanTimeout do
            if not State.Running then return end
            found = findTargetEgg()
            if found then break end
            if chatMentionsTarget() then
                ui.setStatus("alert! staying")
                playSound(SoundBank.Ready, 0.5, 1.4)
                task.wait(1)
            end
            task.wait(0.25)
        end

        if found then
            HuntState.Found = true
            HuntState.FoundEgg = found
            ui.setStatus("found: " .. HuntConfig.TargetName)
            playSound(SoundBank.Ready, 0.6, 1.6)
            blossomBurst(ui.main, 150, 200, 24, { spreadX = 140, life = 1.6 })

            local ok = walkTo(found.Position, 10)
            if ok and State.Running then
                task.wait(randDelay())
                local h = getHRP()
                if h and (h.Position - found.Position).Magnitude < 10 then
                    local origin = found.Position
                    local prompt = found:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then firePrompt(prompt) end
                    local parentModel = found.Parent
                    if parentModel then
                        local pm = parentModel:FindFirstChildOfClass("ProximityPrompt")
                        if pm then firePrompt(pm) end
                    end
                    task.wait(0.3)
                    if BaseConfig.AutoReturn and BaseConfig.Position then
                        returnToBase(origin)
                    end
                end
            end

            if HuntConfig.StopWhenFound then
                HuntConfig.Enabled = false
                if ui.toggles.hunt then
                    pcall(function() ui.toggles.hunt.setState(false, true) end)
                end
                ui.setStatus("hunt complete")
            end
            task.wait(5)
        else
            if HuntState.HopsThisCycle < HuntConfig.MaxHopsPerCycle then
                ui.setStatus("not here — hopping")
                huntHop()
                task.wait(3)
            else
                ui.setStatus("hunt limit reached")
                HuntConfig.Enabled = false
                if ui.toggles.hunt then
                    pcall(function() ui.toggles.hunt.setState(false, true) end)
                end
            end
        end
    end
end

-- ============================================================
-- BOOT
-- ============================================================

ui = createUI()
playSound(SoundBank.Ready, 0.3, 1.2)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Config.KillSwitch then
        State.Running = false
        ui.setStatus("stopped")
        ui.setDotColor(Color3.fromRGB(255, 90, 90))
        playSound(SoundBank.Kill, 0.5, 0.8)
        blossomBurst(ui.main, ui.main.AbsoluteSize.X / 2, ui.main.AbsoluteSize.Y / 2, 30, {
            spreadX = 200, spreadY = 200, life = 1.8
        })
    end
end)

-- ============================================================
-- MAIN LOOP
-- ============================================================

task.spawn(function()
    while State.Running do
        task.wait(randDelay())
        if not State.Running then break end
        if HuntState.Active then continue end
        enforceSpeedCap()

        local hrp = getHRP()
        local inSpawn = hrp and hrp.Position.Magnitude < 100
        State.InSafeZone = inSpawn

        if not State.InCombat then
            if Config.AutoSteal and not inSpawn then
                local egg = findNearestEgg()
                if egg then
                    HopState.EmptyCycles = 0
                    ui.setStatus("stealing")
                    local ok = walkTo(egg.Position)
                    if ok and State.Running then
                        task.wait(randDelay())
                        local h = getHRP()
                        if h and (h.Position - egg.Position).Magnitude < 8 then
                            local origin = egg.Position
                            local prompt = egg:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then firePrompt(prompt) end
                            task.wait(0.3)
                            if BaseConfig.AutoReturn and BaseConfig.Position then
                                returnToBase(origin)
                            end
                        end
                    end
                else
                    ui.setStatus("searching")
                    HopState.EmptyCycles = HopState.EmptyCycles + 1
                    if #Players:GetPlayers() >= HopConfig.MinPlayersToHop then
                        tryHop("crowded")
                    elseif HopState.EmptyCycles >= HopConfig.HopAfterEmptyCycles then
                        tryHop("empty cycles")
                    end
                end
            end

            if Config.AutoTreadmill and inSpawn then
                ui.setStatus("training")
                for _, obj in pairs(workspace:GetDescendants()) do
                    if not State.Running then break end
                    if obj.Name:lower():find("treadmill") and obj:IsA("BasePart") then
                        walkTo(obj.Position)
                        task.wait(2)
                        break
                    end
                end
            end

            if Config.AutoEvent then
                local tree = findCrystalTree()
                if tree then
                    ui.setStatus("crystal farming")
                    walkTo(tree.Position, 6)
                    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        pcall(function() tool:Activate() end)
                        playSound(SoundBank.BossHit, 0.15, math.random(10, 13) / 10)
                    end
                    task.wait(randDelay())
                end
            end

            if Config.AutoHatch and inSpawn then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if not State.Running then break end
                    if obj.Name:lower():find("hatch") and obj:IsA("BasePart") then
                        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            local h = getHRP()
                            if h and (h.Position - obj.Position).Magnitude < 15 then
                                firePrompt(prompt)
                                task.wait(randDelay())
                            end
                        end
                    end
                end
            end
        end
    end
    ui.setStatus("offline")
    ui.setDotColor(Color3.fromRGB(120, 120, 120))
end)

task.spawn(combatLoop)
task.spawn(huntLoop)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    enforceSpeedCap()
end)

print("[Luna] bloomed.")
ui.setStatus("ready")
