--[[
    LUNA — UI PREVIEW
    Full interface, no automation.
    RightShift to dismiss.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

local SoundBank = {
    Click = "rbxassetid://6895079853",
    ToggleOn = "rbxassetid://12221967",
    ToggleOff = "rbxassetid://12221961",
    Kill = "rbxassetid://5152722786",
}

local function playSound(id, volume, pitch)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 0.4
    s.PlaybackSpeed = pitch or 1
    s.Parent = SoundService
    s:Play()
    task.delay(3, function()
        if s.Parent then s:Destroy() end
    end)
end

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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LunaPreview"
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
main.Size = UDim2.fromOffset(300, 640)
main.Position = UDim2.new(0.5, -150, 0.5, -320)
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

local function createToggle(name, yPos, default)
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

    toggleBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            enabled = not enabled
            TweenService:Create(toggleBg, TweenInfo.new(0.18), {
                BackgroundColor3 = enabled and Color3.fromRGB(255, 160, 195) or Color3.fromRGB(60, 40, 55)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = enabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            }):Play()
            playSound(enabled and SoundBank.ToggleOn or SoundBank.ToggleOff, 0.35, 1.1)
            local abs = toggleBg.AbsolutePosition
            local absSize = toggleBg.AbsoluteSize
            local relX = abs.X - main.AbsolutePosition.X + absSize.X / 2
            local relY = abs.Y - main.AbsolutePosition.Y + absSize.Y / 2
            clickRipple(main, relX, relY)
            blossomBurst(main, relX, relY, enabled and 16 or 8)
        end
    end)

    toggleBg.MouseEnter:Connect(function()
        playSound(SoundBank.Click, 0.06, 1.4)
        TweenService:Create(toggleBg, TweenInfo.new(0.15), {
            BackgroundColor3 = enabled and Color3.fromRGB(255, 180, 210) or Color3.fromRGB(85, 55, 75)
        }):Play()
    end)
    toggleBg.MouseLeave:Connect(function()
        TweenService:Create(toggleBg, TweenInfo.new(0.15), {
            BackgroundColor3 = enabled and Color3.fromRGB(255, 160, 195) or Color3.fromRGB(60, 40, 55)
        }):Play()
    end)
end

createToggle("Auto Steal", 80, true)
createToggle("Auto Event", 114, true)
createToggle("Auto Hatch", 148, true)
createToggle("Auto Treadmill", 182, true)
createToggle("Auto Combat", 216, true)
createToggle("Sounds", 250, true)

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
eggDisplay.Text = "Secret Egg"
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

eggBox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        playSound(SoundBank.Click, 0.2, 1.2)
        clickRipple(huntContainer, 100, 36)
        blossomBurst(huntContainer, 100, 36, 8)
    end
end)

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

local huntActive = false
huntBtn.MouseButton1Click:Connect(function()
    huntActive = not huntActive
    huntBtn.BackgroundColor3 = huntActive and Color3.fromRGB(255, 160, 195) or Color3.fromRGB(60, 40, 55)
    huntBtn.TextColor3 = huntActive and Color3.fromRGB(30, 15, 25) or Color3.fromRGB(255, 220, 235)
    playSound(huntActive and SoundBank.ToggleOn or SoundBank.ToggleOff, 0.35, 1.1)
    blossomBurst(huntContainer, 200, 36, huntActive and 18 or 8)
    clickRipple(huntContainer, 200, 36)
end)

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
huntStatus.Text = "hunting: Secret Egg"
huntStatus.Font = Enum.Font.Gotham
huntStatus.TextSize = 10
huntStatus.TextColor3 = Color3.fromRGB(255, 190, 215)
huntStatus.TextXAlignment = Enum.TextXAlignment.Left
huntStatus.ZIndex = 13
huntStatus.Parent = huntContainer

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

setBtn.MouseButton1Click:Connect(function()
    playSound(SoundBank.ToggleOn, 0.4, 1.2)
    blossomBurst(baseContainer, 60, 36, 14)
    clickRipple(baseContainer, 60, 36)
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
    methodBtn.Text = methods[methodIdx]
    playSound(SoundBank.Click, 0.2, 1.2)
    methodBtn.TextColor3 = methods[methodIdx] == "teleport" and Color3.fromRGB(255, 140, 140)
        or methods[methodIdx] == "hybrid" and Color3.fromRGB(255, 200, 140)
        or Color3.fromRGB(140, 255, 180)
end)

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

local autoRetOn = true
autoRetBtn.MouseButton1Click:Connect(function()
    autoRetOn = not autoRetOn
    autoRetBtn.Text = "auto-return: " .. (autoRetOn and "ON" or "OFF")
    autoRetBtn.BackgroundColor3 = autoRetOn and Color3.fromRGB(255, 160, 195) or Color3.fromRGB(60, 40, 55)
    autoRetBtn.TextColor3 = autoRetOn and Color3.fromRGB(30, 15, 25) or Color3.fromRGB(255, 220, 235)
    playSound(autoRetOn and SoundBank.ToggleOn or SoundBank.ToggleOff, 0.3, 1.1)
end)

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
    playSound(SoundBank.Click, 0.25, 0.9)
end)

local killHint = Instance.new("TextLabel")
killHint.Size = UDim2.new(1, 0, 0, 14)
killHint.Position = UDim2.new(0, 0, 0, 620)
killHint.BackgroundTransparency = 1
killHint.Text = "RightShift — dismiss"
killHint.Font = Enum.Font.Gotham
killHint.TextSize = 9
killHint.TextColor3 = Color3.fromRGB(140, 105, 120)
killHint.ZIndex = 12
killHint.Parent = main

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

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        playSound(SoundBank.Kill, 0.5, 0.8)
        screenGui:Destroy()
    end
end)

playSound(SoundBank.ToggleOn, 0.3, 1.2)
print("[Luna] preview loaded. RightShift to dismiss.")
