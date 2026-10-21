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
h
