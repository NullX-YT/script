--[[  
    LocalScript فقط (حطه في StarterPlayerScripts)

    Features:
    - Aimbot مباشر بدون سمووث (Direct)
    - Line من شخصيتك لأقرب لاعب داخل الـFOV
    - ESP (Highlight) + HealthBar + NameTag
    - FOV Circle UI يتحرك مع الماوس
    - GUI متقدم مع Tabs (شريط قابل للسحب):
        * ايم بوت (Aimbot Tab)
        * كشف اللاعبين (ESP Tab)
        * الصرافة (ATM ESP)
        * تجميع تلقائي (Cleaner Farm) + أوضاع مكنسة (Swiper)
        * تواصل (نسخ سيرفر الدسكورد)
    - Minimize / Resize / Close (بدون RightShift)
    - Aim Mode:
        * AUTO
        * HOLD (يضبط زر من Choose Aim Key)
    - Exclude players from Aimbot
--]]

-----------------------------
-- Services
-----------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-----------------------------
-- Character / Humanoid
-----------------------------
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
end)

-----------------------------
-- Config (Aimbot / ESP / ATM / Farm / Line)
-----------------------------
local config = {
    aimbotEnabled = true,
    teamCheck = true,

    fovEnabled = true,
    fovRadius = 150,       -- حجم دائرة الـ FOV
    aimSmoothness = 0,     -- 0 يعني مباشر بدون سمووث

    espColor = Color3.fromRGB(255, 0, 255),
    fovColor = Color3.fromRGB(0, 255, 255),

    aimPartName = "Head",

    aimMode = "AUTO",      -- "AUTO" or "HOLD"
    aimKeyType = "Mouse",  -- "Mouse" or "Key"
    aimKey = Enum.UserInputType.MouseButton2,

    atmEspEnabled = true,
    atmGreenColor = Color3.fromRGB(0, 255, 0),
    atmRedColor = Color3.fromRGB(255, 0, 0),

    -- خط من شخصيتك لأقرب لاعب داخل FOV
    lineEnabled = true,
    lineColor = Color3.fromRGB(0, 200, 255),
    lineThickness = 2,

    -- إعدادات المكنسة / الفارم
    cleanerMode = "Normal", -- "Normal", "Bronze", "Silver", "Gold", "Diamond"
    include5  = true,
    include10 = true,
    include15 = true,
    include20 = true,
}

-----------------------------
-- FARM CONFIG (Cleaner Farm الجديدة)
-----------------------------
local BASE_WALK_SPEED = 23
local WALK_SPEED = BASE_WALK_SPEED
local farming = false

local Points = {
    -- بداية من الخلف - 5 ث
    {pos = Vector3.new(104.32, 255.36, -294.06), waitTime = 5},
    {pos = Vector3.new(106.86, 255.36, -306.55), waitTime = 5},
    {pos = Vector3.new(119.42, 255.36, -298.90), waitTime = 5},
    {pos = Vector3.new(123.04, 255.36, -311.83), waitTime = 5},

    -- 10 ثواني
    {pos = Vector3.new(135.26, 255.37, -299.93), waitTime = 10},

    -- نزول خفيف - 5 ث
    {pos = Vector3.new(138.01, 255.39, -288.61), waitTime = 5},
    {pos = Vector3.new(128.83, 255.35, -282.62), waitTime = 5},
    {pos = Vector3.new(116.51, 255.35, -282.20), waitTime = 5},
    {pos = Vector3.new(118.64, 255.45, -271.68), waitTime = 5},
    {pos = Vector3.new(118.60, 255.45, -250.16), waitTime = 5},
    {pos = Vector3.new(123.54, 255.45, -263.63), waitTime = 5},

    -- انتقال سريع بدون انتظار
    {pos = Vector3.new(107.10, 255.45, -260.07), waitTime = 0},
    {pos = Vector3.new(106.96, 255.45, -254.94), waitTime = 0},
    {pos = Vector3.new(106.78, 255.45, -249.14), waitTime = 0},
    {pos = Vector3.new(106.67, 255.40, -245.55), waitTime = 0},

    -- قدام الماب - 20 ث
    {pos = Vector3.new(140.91, 255.33, -221.37), waitTime = 20},
    {pos = Vector3.new(171.13, 255.33, -220.99), waitTime = 20},

    -- رجوع لمنطقة ثانية بدون انتظار
    {pos = Vector3.new(115.07, 255.33, -228.34), waitTime = 0},
    {pos = Vector3.new(111.25, 255.45, -236.32), waitTime = 0},
    {pos = Vector3.new(108.48, 255.45, -241.11), waitTime = 0},
    {pos = Vector3.new(107.33, 255.45, -244.38), waitTime = 0},
    {pos = Vector3.new(107.57, 255.45, -250.88), waitTime = 0},

    -- لفة 5 ثواني على المساحة
    {pos = Vector3.new(136.32, 255.45, -265.95), waitTime = 5},
    {pos = Vector3.new(134.31, 255.45, -257.70), waitTime = 5},
    {pos = Vector3.new(146.07, 255.45, -258.82), waitTime = 5},
    {pos = Vector3.new(151.82, 255.45, -251.58), waitTime = 5},
    {pos = Vector3.new(157.98, 255.45, -261.94), waitTime = 5},
    {pos = Vector3.new(166.31, 255.45, -265.30), waitTime = 5},
    {pos = Vector3.new(177.39, 255.45, -270.20), waitTime = 5},

    -- 10 ثواني
    {pos = Vector3.new(168.27, 255.45, -258.07), waitTime = 10},

    -- انتقال بدون انتظار
    {pos = Vector3.new(170.23, 255.45, -269.15), waitTime = 0},
    {pos = Vector3.new(169.96, 255.45, -273.41), waitTime = 0},
    {pos = Vector3.new(169.38, 255.39, -276.21), waitTime = 0},
    {pos = Vector3.new(169.49, 255.39, -280.04), waitTime = 0},

    -- 15 ثانية
    {pos = Vector3.new(173.00, 255.39, -280.14), waitTime = 15},
    {pos = Vector3.new(159.26, 255.39, -283.40), waitTime = 15},
    {pos = Vector3.new(162.99, 255.39, -293.00), waitTime = 15},
    {pos = Vector3.new(173.62, 255.39, -287.46), waitTime = 15},

    -- رجوع بدون انتظار ثم بداية من الخلف مرة ثانية
    {pos = Vector3.new(169.83, 255.37, -279.31), waitTime = 0},
    {pos = Vector3.new(169.56, 255.39, -276.09), waitTime = 0},
    {pos = Vector3.new(168.50, 255.45, -271.69), waitTime = 0},
    {pos = Vector3.new(164.52, 255.45, -257.71), waitTime = 0},
}

-----------------------------
-- State
-----------------------------
local aimKeyHeld = false
local waitingForAimKey = false
local aimKeyButton

local excludedAimPlayers = {}
local excludeRowByPlayer = {}

-----------------------------
-- Utils
-----------------------------
local function isEnemyForESP(player)
    if player == LocalPlayer then return false end
    if not config.teamCheck then return true end
    if not player.Team or not LocalPlayer.Team then return true end
    return player.Team ~= LocalPlayer.Team
end

local function isEnemyForAimbot(player)
    if excludedAimPlayers[player] then return false end
    return isEnemyForESP(player)
end

local function getInputDisplayName(inputType, keyCode)
    if inputType == "Mouse" then
        if keyCode == Enum.UserInputType.MouseButton1 then
            return "Mouse1"
        elseif keyCode == Enum.UserInputType.MouseButton2 then
            return "Mouse2"
        elseif keyCode == Enum.UserInputType.MouseButton3 then
            return "Mouse3"
        else
            return tostring(keyCode)
        end
    elseif inputType == "Key" then
        return keyCode.Name
    end
    return "Unknown"
end

local function refreshCharacter()
    if not Character or not Character.Parent then
        Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        Humanoid = Character:WaitForChild("Humanoid")
        HRP = Character:WaitForChild("HumanoidRootPart")
    end
end

local function pressShift()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
end

local function releaseShift()
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
end

local function getCurrentWalkSpeed()
    return BASE_WALK_SPEED
end

local function getAdjustedWaitTime(orig)
    if orig <= 0 then
        return 0
    end

    local factor = 1

    if config.cleanerMode == "Bronze" then
        factor = 0.9      -- 10% أقل
    elseif config.cleanerMode == "Silver" then
        factor = 0.8      -- 20% أقل
    elseif config.cleanerMode == "Gold" then
        factor = 0.7      -- 30% أقل
    elseif config.cleanerMode == "Diamond" then
        factor = 0.6      -- 40% أقل
    end

    return orig * factor
end

local function isPointEnabled(waitTime)
    if waitTime <= 0 then
        return true
    end

    if waitTime >= 19 and waitTime <= 21 then
        return config.include20
    elseif waitTime >= 14 and waitTime <= 16 then
        return config.include15
    elseif waitTime >= 9 and waitTime <= 11 then
        return config.include10
    else
        return config.include5
    end
end

-----------------------------
-- GUI Creation (Main Panel)
-----------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedFPSGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 380, 0, 360)
mainFrame.Position = UDim2.new(0, 50, 0, 80)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 2
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Color = Color3.fromRGB(0, 180, 255)

local mainGradient = Instance.new("UIGradient", mainFrame)
mainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 5, 15)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 20, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 15)),
})
mainGradient.Rotation = 45

local padding = Instance.new("UIPadding", mainFrame)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 10)

local normalSize = UDim2.new(0, 380, 0, 360)
local largeSize = UDim2.new(0, 460, 0, 400)
local isLarge = false
local isMinimized = false

-- Draggable + Clamp
local dragging = false
local dragStart, startPos

local function clampToScreen(pos)
    local guiSize = screenGui.AbsoluteSize
    local frameSize = mainFrame.AbsoluteSize

    local minX = 0
    local minY = 0
    local maxX = guiSize.X - frameSize.X
    local maxY = guiSize.Y - frameSize.Y

    local x = math.clamp(pos.X.Offset, minX, math.max(minX, maxX))
    local y = math.clamp(pos.Y.Offset, minY, math.max(minY, maxY))

    return UDim2.new(0, x, 0, y)
end

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        mainFrame.Position = clampToScreen(newPos)
    end
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -150, 0, 26)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(230, 245, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "NULLX HUB - بلوك سبين"
title.Parent = mainFrame

local subTitle = Instance.new("TextLabel")
subTitle.Size = UDim2.new(1, -150, 0, 18)
subTitle.Position = UDim2.new(0, 8, 0, 28)
subTitle.BackgroundTransparency = 1
subTitle.Font = Enum.Font.Gotham
subTitle.TextSize = 13
subTitle.TextColor3 = Color3.fromRGB(160, 190, 230)
subTitle.TextXAlignment = Enum.TextXAlignment.Left
subTitle.Text = "ايم بوت • كشف اللاعبين • الصرافة • تجميع تلقائي • تواصل"
subTitle.Parent = mainFrame

-- Top Buttons
local topButtonsFrame = Instance.new("Frame")
topButtonsFrame.Size = UDim2.new(0, 100, 0, 24)
topButtonsFrame.Position = UDim2.new(1, -110, 0, 6)
topButtonsFrame.BackgroundTransparency = 1
topButtonsFrame.Parent = mainFrame

local buttonsLayout = Instance.new("UIListLayout", topButtonsFrame)
buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
buttonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonsLayout.Padding = UDim.new(0, 4)

local function createTopButton(txt, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 26, 0, 20)
    btn.BackgroundColor3 = color or Color3.fromRGB(25, 30, 60)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(240, 240, 255)
    btn.Text = txt
    btn.AutoButtonColor = true
    btn.Parent = topButtonsFrame
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(1, 0)
    return btn
end

local minimizeButton = createTopButton("-", Color3.fromRGB(30, 40, 70))
local resizeButton  = createTopButton("□", Color3.fromRGB(40, 60, 100))
local closeButton   = createTopButton("X", Color3.fromRGB(120, 40, 50))

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(0, 260, 0, 18)
hintLabel.Position = UDim2.new(0, 8, 0, 48)
hintLabel.BackgroundTransparency = 1
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextSize = 12
hintLabel.TextColor3 = Color3.fromRGB(150, 180, 220)
hintLabel.TextXAlignment = Enum.TextXAlignment.Left
hintLabel.Text = "استخدم الأزرار فوق عشان تصغر / تكبر / تقفل الهب"
hintLabel.Parent = mainFrame

-- Tabs Bar (Scrollable)
local tabBar = Instance.new("ScrollingFrame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -16, 0, 28)
tabBar.Position = UDim2.new(0, 8, 0, 72)
tabBar.BackgroundTransparency = 1
tabBar.ScrollBarThickness = 4
tabBar.ScrollingDirection = Enum.ScrollingDirection.X
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
tabBar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, 6)

-- Tabs Container
local container = Instance.new("Frame")
container.Name = "TabsContainer"
container.Size = UDim2.new(1, -16, 1, -118)
container.Position = UDim2.new(0, 8, 0, 104)
container.BackgroundTransparency = 1
container.Parent = mainFrame

local function createTabFrame()
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.Parent = container

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 6)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    return scroll
end

local aimbotTab   = createTabFrame()
local espTab      = createTabFrame()
local otherTab    = createTabFrame()
local farmTab     = createTabFrame()
local contactTab  = createTabFrame()
local currentTab  = nil

local function setTab(tabName)
    aimbotTab.Visible   = (tabName == "Aimbot")
    espTab.Visible      = (tabName == "ESP")
    otherTab.Visible    = (tabName == "Other")
    farmTab.Visible     = (tabName == "Farm")
    contactTab.Visible  = (tabName == "Contact")
    currentTab = tabName
end

local tabButtons = {}

local function createTabButton(tabName, displayText)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
    btn.AutoButtonColor = true
    btn.Parent = tabBar

    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(210, 220, 250)
    btn.Text = displayText
    btn.TextWrapped = false
    btn.TextScaled = true

    local textConstraint = Instance.new("UITextSizeConstraint", btn)
    textConstraint.MaxTextSize = 14
    textConstraint.MinTextSize = 8

    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(1, 0)

    local function refresh()
        if currentTab == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(0, 140, 220)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
            btn.TextColor3 = Color3.fromRGB(210, 220, 250)
        end
    end

    btn.MouseButton1Click:Connect(function()
        setTab(tabName)
        for _, info in ipairs(tabButtons) do
            info.refresh()
        end
    end)

    local info = {button = btn, refresh = refresh}
    table.insert(tabButtons, info)
    return info
end

local aimbotTabBtn  = createTabButton("Aimbot",  "ايم بوت")
local espTabBtn     = createTabButton("ESP",     "كشف اللاعبين")
local farmTabBtn    = createTabButton("Farm",    "تجميع تلقائي")
local otherTabBtn   = createTabButton("Other",   "الصرافة")
local contactTabBtn = createTabButton("Contact", "تواصل")

setTab("Aimbot")
for _, info in ipairs(tabButtons) do
    info.refresh()
end

-- Minimize / Resize / Close
local function applySize()
    if isMinimized then
        mainFrame.Size = UDim2.new(normalSize.X.Scale, normalSize.X.Offset, 0, 70)
        container.Visible = false
        tabBar.Visible = false
    else
        tabBar.Visible = true
        container.Visible = true
        if isLarge then
            mainFrame.Size = largeSize
        else
            mainFrame.Size = normalSize
        end
    end
    mainFrame.Position = clampToScreen(mainFrame.Position)
end

minimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    applySize()
end)

resizeButton.MouseButton1Click:Connect(function()
    isMinimized = false
    isLarge = not isLarge
    applySize()
end)

closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-----------------------------
-- GUI Helpers
-----------------------------
local function createSectionLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextColor3 = Color3.fromRGB(220, 230, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.Parent = parent
    return lbl
end

local function createSmallTip(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(160, 190, 230)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "TIP: " .. text
    lbl.Parent = parent
    return lbl
end

local function createToggle(parent, name, initialState, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(16, 20, 40)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(225, 230, 245)
    label.Text = name
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 22)
    btn.Position = UDim2.new(1, -80, 0.5, -11)
    btn.BackgroundColor3 = initialState and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(90, 35, 40)
    btn.Text = initialState and "متفعل" or "مو متفعل"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(245, 245, 255)
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(1, 0)

    btn.MouseButton1Click:Connect(function()
        initialState = not initialState
        if initialState then
            btn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
            btn.Text = "متفعل"
        else
            btn.BackgroundColor3 = Color3.fromRGB(90, 35, 40)
            btn.Text = "مو متفعل"
        end
        if callback then
            callback(initialState)
        end
    end)

    return {
        frame = frame,
        button = btn,
        set = function(state)
            initialState = state
            if initialState then
                btn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
                btn.Text = "متفعل"
            else
                btn.BackgroundColor3 = Color3.fromRGB(90, 35, 40)
                btn.Text = "مو متفعل"
            end
        end
    }
end

local function createSlider(parent, labelText, minValue, maxValue, defaultValue, formatFunc, callback)
    local value = math.clamp(defaultValue, minValue, maxValue)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = Color3.fromRGB(16, 20, 40)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, -10, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(225, 230, 245)
    label.Text = labelText
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, -10, 0, 18)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextColor3 = Color3.fromRGB(170, 200, 240)
    valueLabel.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 8)
    sliderBg.Position = UDim2.new(0, 10, 0, 28)
    sliderBg.BackgroundColor3 = Color3.fromRGB(10, 12, 24)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame
    local bgCorner = Instance.new("UICorner", sliderBg)
    bgCorner.CornerRadius = UDim.new(0, 100)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg
    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(0, 100)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = sliderBg
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)

    local draggingSlider = false

    local function formatValue(v)
        if formatFunc then
            return formatFunc(v)
        else
            return string.format("%.2f", v)
        end
    end

    local function updateVisual()
        local percent = (value - minValue) / (maxValue - minValue)
        percent = math.clamp(percent, 0, 1)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, 0, 0.5, 0)
        valueLabel.Text = formatValue(value)
    end

    local function setFromX(x)
        local absPos = sliderBg.AbsolutePosition.X
        local absSize = sliderBg.AbsoluteSize.X
        if absSize <= 0 then return end

        local percent = (x - absPos) / absSize
        percent = math.clamp(percent, 0, 1)
        value = minValue + (maxValue - minValue) * percent
        if callback then callback(value) end
        updateVisual()
    end

    updateVisual()
    if callback then callback(value) end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
        end
    end)

    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            setFromX(input.Position.X)
        end
    end)

    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)

    return {
        set = function(v)
            value = math.clamp(v, minValue, maxValue)
            updateVisual()
            if callback then callback(value) end
        end
    }
end

-----------------------------
-- FARM HELPERS + LOOP
-----------------------------
local function moveToPosition(targetPos)
    refreshCharacter()
    if not Humanoid or not HRP then return end

    WALK_SPEED = getCurrentWalkSpeed()
    Humanoid.WalkSpeed = WALK_SPEED

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true
    })

    path:ComputeAsync(HRP.Position, targetPos)

    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()

        for _, wp in ipairs(waypoints) do
            if not farming then return end

            if wp.Action == Enum.PathWaypointAction.Jump then
                Humanoid.Jump = true
            end

            Humanoid:MoveTo(wp.Position)

            local reached = false
            local conn
            conn = Humanoid.MoveToFinished:Connect(function()
                reached = true
                conn:Disconnect()
            end)

            local t = 0
            while not reached and t < 5 and farming do
                task.wait(0.1)
                t += 0.1
            end

            if conn and conn.Connected then
                conn:Disconnect()
            end

            if not reached and farming then
                break
            end
        end
    end

    if farming and Humanoid then
        Humanoid:MoveTo(targetPos)
        local reached = false
        local conn
        conn = Humanoid.MoveToFinished:Connect(function()
            reached = true
            conn:Disconnect()
        end)

        local t = 0
        while not reached and t < 6 and farming do
            task.wait(0.1)
            t += 0.1
        end

        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
end

local function farmLoop()
    farming = true
    refreshCharacter()
    pressShift()

    while farming do
        for _, data in ipairs(Points) do
            if not farming then break end
            if isPointEnabled(data.waitTime) then
                moveToPosition(data.pos)
                if not farming then break end

                local waitTime = getAdjustedWaitTime(data.waitTime)
                local t = 0
                while t < waitTime and farming do
                    task.wait(0.1)
                    t += 0.1
                end
            end
        end
    end

    releaseShift()
    if Humanoid then
        Humanoid:Move(Vector3.zero)
    end
    farming = false
end

-----------------------------
-- Build Tabs Content
-----------------------------
-----------------------------
-- AIMBOT TAB
-----------------------------
createSectionLabel(aimbotTab, "ايم بوت")

local aimbotToggle = createToggle(aimbotTab, "حالة الايمبوت", config.aimbotEnabled, function(state)
    config.aimbotEnabled = state
end)

local teamToggle = createToggle(aimbotTab, "اللي بتيمك مايم علية", config.teamCheck, function(state)
    config.teamCheck = state
end)

-- Aim Mode
local modeFrame = Instance.new("Frame")
modeFrame.Size = UDim2.new(1, 0, 0, 30)
modeFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 40)
modeFrame.BorderSizePixel = 0
modeFrame.Parent = aimbotTab
local modeCorner = Instance.new("UICorner", modeFrame)
modeCorner.CornerRadius = UDim.new(0, 10)

local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(1, -110, 1, 0)
modeLabel.Position = UDim2.new(0, 10, 0, 0)
modeLabel.BackgroundTransparency = 1
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextSize = 14
modeLabel.TextColor3 = Color3.fromRGB(225, 230, 245)
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Text = "نوع الايمبوت  بزر / تلقائي"
modeLabel.Parent = modeFrame

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(0, 100, 0, 22)
modeBtn.Position = UDim2.new(1, -110, 0.5, -11)
modeBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
modeBtn.Font = Enum.Font.GothamBold
modeBtn.TextSize = 13
modeBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
modeBtn.Parent = modeFrame
local modeBtnCorner = Instance.new("UICorner", modeBtn)
modeBtnCorner.CornerRadius = UDim.new(1, 0)

local function refreshAimModeButton()
    if config.aimMode == "AUTO" then
        modeBtn.Text = "تلقائي"
    else
        modeBtn.Text = "بزر (HOLD)"
    end
end
refreshAimModeButton()

modeBtn.MouseButton1Click:Connect(function()
    if config.aimMode == "AUTO" then
        config.aimMode = "HOLD"
    else
        config.aimMode = "AUTO"
    end
    refreshAimModeButton()
end)

-- Aim Key
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(1, 0, 0, 30)
keyFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 40)
keyFrame.BorderSizePixel = 0
keyFrame.Parent = aimbotTab
local keyCorner = Instance.new("UICorner", keyFrame)
keyCorner.CornerRadius = UDim.new(0, 10)

local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(1, -130, 1, 0)
keyLabel.Position = UDim2.new(0, 10, 0, 0)
keyLabel.BackgroundTransparency = 1
keyLabel.Font = Enum.Font.Gotham
keyLabel.TextSize = 14
keyLabel.TextColor3 = Color3.fromRGB(225, 230, 245)
keyLabel.TextXAlignment = Enum.TextXAlignment.Left
keyLabel.Text = "زر الايم بوت (للزر فقط)"
keyLabel.Parent = keyFrame

aimKeyButton = Instance.new("TextButton")
aimKeyButton.Size = UDim2.new(0, 120, 0, 22)
aimKeyButton.Position = UDim2.new(1, -130, 0.5, -11)
aimKeyButton.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
aimKeyButton.Font = Enum.Font.GothamBold
aimKeyButton.TextSize = 13
aimKeyButton.TextColor3 = Color3.fromRGB(245, 245, 255)
aimKeyButton.Parent = keyFrame
local keyBtnCorner = Instance.new("UICorner", aimKeyButton)
keyBtnCorner.CornerRadius = UDim.new(1, 0)

local function refreshAimKeyButtonText()
    aimKeyButton.Text = getInputDisplayName(config.aimKeyType, config.aimKey)
end
refreshAimKeyButtonText()

aimKeyButton.MouseButton1Click:Connect(function()
    waitingForAimKey = true
    aimKeyButton.Text = "اضغط أي زر..."
end)

createSectionLabel(aimbotTab, "إعدادات الايمبوت")

-- Slider FOV
local fovSlider = createSlider(
    aimbotTab,
    "كبر دائرة الايم",
    20,
    500,
    config.fovRadius,
    function(v) return string.format("R = %d", math.floor(v)) end,
    function(v) config.fovRadius = v end
)

createSmallTip(aimbotTab, "الايمبوت مباشر بدون سمووث (Direct Aim)")

-- Exclude players
createSectionLabel(aimbotTab, "استثنائات اللاعبين من الايمبوت")

local excludeFrame = Instance.new("Frame")
excludeFrame.Size = UDim2.new(1, 0, 0, 130)
excludeFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 28)
excludeFrame.BorderSizePixel = 0
excludeFrame.Parent = aimbotTab
local exCorner = Instance.new("UICorner", excludeFrame)
exCorner.CornerRadius = UDim.new(0, 10)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -10)
scroll.Position = UDim2.new(0, 5, 0, 5)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = excludeFrame

local scrollLayout = Instance.new("UIListLayout", scroll)
scrollLayout.FillDirection = Enum.FillDirection.Vertical
scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 4)

local function addExcludeRow(player)
    if excludeRowByPlayer[player] then return end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundColor3 = Color3.fromRGB(18, 22, 45)
    row.BorderSizePixel = 0
    row.Parent = scroll
    local rc = Instance.new("UICorner", row)
    rc.CornerRadius = UDim.new(0, 8)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -90, 1, 0)
    nameLabel.Position = UDim2.new(0, 8, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 13
    nameLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = player.Name
    nameLabel.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 20)
    btn.Position = UDim2.new(1, -88, 0.5, -10)
    btn.BackgroundColor3 = Color3.fromRGB(40, 70, 130)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(245, 245, 255)
    btn.Text = "استثناء"
    btn.Parent = row
    local bc = Instance.new("UICorner", btn)
    bc.CornerRadius = UDim.new(1, 0)

    local function refreshBtn()
        if excludedAimPlayers[player] then
            btn.Text = "إلغاء الاستثناء"
            btn.BackgroundColor3 = Color3.fromRGB(140, 60, 70)
        else
            btn.Text = "استثناء"
            btn.BackgroundColor3 = Color3.fromRGB(40, 70, 130)
        end
    end

    btn.MouseButton1Click:Connect(function()
        excludedAimPlayers[player] = not excludedAimPlayers[player]
        refreshBtn()
    end)

    refreshBtn()
    excludeRowByPlayer[player] = row
end

local function removeExcludeRow(player)
    local row = excludeRowByPlayer[player]
    if row then
        row:Destroy()
        excludeRowByPlayer[player] = nil
    end
    excludedAimPlayers[player] = nil
end

-----------------------------
-- ESP TAB
-----------------------------
createSectionLabel(espTab, "كشف اللاعبين + دائرة الايمبوت + خط الهدف")

local espToggle = createToggle(
    espTab,
    "كشف اللاعبين + يخلي لون عليهم وهيلث بار",
    true,
    function(state)
        config.espEnabled = state
    end
)

local fovToggle = createToggle(
    espTab,
    "دائرة الايمبوت حول الماوس",
    config.fovEnabled,
    function(state)
        config.fovEnabled = state
    end
)

local lineToggle = createToggle(
    espTab,
    "خط من شخصيتك لأقرب لاعب داخل الـFOV",
    config.lineEnabled,
    function(state)
        config.lineEnabled = state
    end
)

-----------------------------
-- OTHER TAB (ATM ESP)
-----------------------------
createSectionLabel(otherTab, "كشف الصرافات")

local atmToggle = createToggle(
    otherTab,
    "تفعيل كشف الصرافات (أخضر لو تقدر تتفاعل / أحمر لو مخفية)",
    config.atmEspEnabled,
    function(state)
        config.atmEspEnabled = state
    end
)

-----------------------------
-- FARM TAB
-----------------------------
createSectionLabel(farmTab, "تجميع تلقائي")

local cleanerFarmToggle
local include5Toggle, include10Toggle, include15Toggle, include20Toggle

local function ensureAtLeastOneCategory()
    if not (config.include5 or config.include10 or config.include15 or config.include20) then
        config.include5 = true
        if include5Toggle then
            include5Toggle.set(true)
        end
    end
end

cleanerFarmToggle = createToggle(
    farmTab,
    "تنظيف تلقائي : تفعيل / ايقاف",
    false,
    function(state)
        if state then
            if not farming then
                task.spawn(function()
                    farmLoop()
                    cleanerFarmToggle.set(false)
                end)
            end
        else
            farming = false
            releaseShift()
            if Humanoid then
                Humanoid:Move(Vector3.zero)
            end
        end
    end
)

createSmallTip(farmTab, "لازم تكون مشتغل بالتنظيف داخل اللعبة بعدها تسوي تشغيل من هنا")

-- وضع المكنسة / Swiper
local cleanerModeFrame = Instance.new("Frame")
cleanerModeFrame.Size = UDim2.new(1, 0, 0, 30)
cleanerModeFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 40)
cleanerModeFrame.BorderSizePixel = 0
cleanerModeFrame.Parent = farmTab
local cmCorner = Instance.new("UICorner", cleanerModeFrame)
cmCorner.CornerRadius = UDim.new(0, 10)

local cleanerModeLabel = Instance.new("TextLabel")
cleanerModeLabel.Size = UDim2.new(1, -130, 1, 0)
cleanerModeLabel.Position = UDim2.new(0, 10, 0, 0)
cleanerModeLabel.BackgroundTransparency = 1
cleanerModeLabel.Font = Enum.Font.Gotham
cleanerModeLabel.TextSize = 14
cleanerModeLabel.TextColor3 = Color3.fromRGB(225, 230, 245)
cleanerModeLabel.TextXAlignment = Enum.TextXAlignment.Left
cleanerModeLabel.Text = "نوع المكنسة (Swiper)"
cleanerModeLabel.Parent = cleanerModeFrame

local cleanerModeBtn = Instance.new("TextButton")
cleanerModeBtn.Size = UDim2.new(0, 150, 0, 22)
cleanerModeBtn.Position = UDim2.new(1, -160, 0.5, -11)
cleanerModeBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
cleanerModeBtn.Font = Enum.Font.GothamBold
cleanerModeBtn.TextSize = 13
cleanerModeBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
cleanerModeBtn.Parent = cleanerModeFrame
local cmBtnCorner = Instance.new("UICorner", cleanerModeBtn)
cmBtnCorner.CornerRadius = UDim.new(1, 0)

local function refreshCleanerModeButton()
    if config.cleanerMode == "Normal" then
        cleanerModeBtn.Text = "1- مساحة عادية (بدون تقليل)"
    elseif config.cleanerMode == "Bronze" then
        cleanerModeBtn.Text = "2- تنظيف برونز (-10% وقت)"
    elseif config.cleanerMode == "Silver" then
        cleanerModeBtn.Text = "3- تنظيف سيلفر (-20% وقت)"
    elseif config.cleanerMode == "Gold" then
        cleanerModeBtn.Text = "4- تنظيف قولد (-30% وقت)"
    elseif config.cleanerMode == "Diamond" then
        cleanerModeBtn.Text = "5- تنظيف دايموند (-40% وقت)"
    end
end
refreshCleanerModeButton()

cleanerModeBtn.MouseButton1Click:Connect(function()
    if config.cleanerMode == "Normal" then
        config.cleanerMode = "Bronze"
    elseif config.cleanerMode == "Bronze" then
        config.cleanerMode = "Silver"
    elseif config.cleanerMode == "Silver" then
        config.cleanerMode = "Gold"
    elseif config.cleanerMode == "Gold" then
        config.cleanerMode = "Diamond"
    else
        config.cleanerMode = "Normal"
    end
    refreshCleanerModeButton()
end)

createSmallTip(
    farmTab,
    "برونز: -10% من الانتظار • سيلفر: -20% • قولد: -30% • دايموند: -40% من وقت الانتظار"
)

-- اختيار أنواع النقاط
createSectionLabel(farmTab, "نوع نقاط الانتظار اللي يلف عليها")

include5Toggle = createToggle(
    farmTab,
    "تفعيل نقاط 5 ثواني (المساحة العادية)",
    config.include5,
    function(state)
        config.include5 = state
        ensureAtLeastOneCategory()
    end
)

include10Toggle = createToggle(
    farmTab,
    "تفعيل نقاط 10 ثواني",
    config.include10,
    function(state)
        config.include10 = state
        ensureAtLeastOneCategory()
    end
)

include15Toggle = createToggle(
    farmTab,
    "تفعيل نقاط 15 ثانية",
    config.include15,
    function(state)
        config.include15 = state
        ensureAtLeastOneCategory()
    end
)

include20Toggle = createToggle(
    farmTab,
    "تفعيل نقاط 20 ثانية (الوقوف الطويل)",
    config.include20,
    function(state)
        config.include20 = state
        ensureAtLeastOneCategory()
    end
)

createSmallTip(
    farmTab,
    "تقدر تشغل/تطفي أنواع مختلفة مع بعض، بس لازم نوع واحد على الأقل يكون شغال"
)

-----------------------------
-- CONTACT TAB (تواصل)
-----------------------------
createSectionLabel(contactTab, "تواصل")

local contactFrame = Instance.new("Frame")
contactFrame.Size = UDim2.new(1, 0, 0, 60)
contactFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 40)
contactFrame.BorderSizePixel = 0
contactFrame.Parent = contactTab
local contactCorner = Instance.new("UICorner", contactFrame)
contactCorner.CornerRadius = UDim.new(0, 10)

local contactLabel = Instance.new("TextLabel")
contactLabel.Size = UDim2.new(1, -10, 0, 20)
contactLabel.Position = UDim2.new(0, 5, 0, 5)
contactLabel.BackgroundTransparency = 1
contactLabel.Font = Enum.Font.Gotham
contactLabel.TextSize = 14
contactLabel.TextColor3 = Color3.fromRGB(225, 230, 245)
contactLabel.TextXAlignment = Enum.TextXAlignment.Left
contactLabel.Text = "سيرفر الدعم / المجتمع:"
contactLabel.Parent = contactFrame

local discordLink = "https://discord.gg/911HJ9k"

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, 180, 0, 24)
copyBtn.Position = UDim2.new(0, 10, 0, 30)
copyBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 150)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 13
copyBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
copyBtn.Text = "نسخ سيرفر الدسكورد"
copyBtn.AutoButtonColor = true
copyBtn.Parent = contactFrame
local copyCorner = Instance.new("UICorner", copyBtn)
copyCorner.CornerRadius = UDim.new(1, 0)

local contactStatus = Instance.new("TextLabel")
contactStatus.Size = UDim2.new(1, -200, 0, 20)
contactStatus.Position = UDim2.new(0, 200, 0, 30)
contactStatus.BackgroundTransparency = 1
contactStatus.Font = Enum.Font.Gotham
contactStatus.TextSize = 12
contactStatus.TextColor3 = Color3.fromRGB(170, 200, 240)
contactStatus.TextXAlignment = Enum.TextXAlignment.Left
contactStatus.Text = ""
contactStatus.Parent = contactFrame

copyBtn.MouseButton1Click:Connect(function()
    if typeof(setclipboard) == "function" then
        setclipboard(discordLink)
        contactStatus.Text = "تم نسخ رابط السيرفر للحافظة!"
    else
        contactStatus.Text = "انسخ الرابط يدويًا: " .. discordLink
    end
end)

-----------------------------
-- Player ESP + Highlights
-----------------------------
local espFolder = Instance.new("Folder")
espFolder.Name = "ESP_Highlights"
espFolder.Parent = Workspace

local playerESP = {}
local highlightsByPlayer = {}

local function setupBillboard(player, character)
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    local existing = playerESP[player]
    if existing and existing.billboard and existing.billboard.Parent == hrp then
        existing.humanoid = humanoid
        return
    end

    local bill = Instance.new("BillboardGui")
    bill.Name = "PlayerESP_GUI"
    bill.Size = UDim2.new(0, 120, 0, 40)
    bill.StudsOffset = Vector3.new(0, 4, 0)
    bill.AlwaysOnTop = true
    bill.Parent = hrp

    local rootFrame = Instance.new("Frame")
    rootFrame.Size = UDim2.new(1, 0, 1, 0)
    rootFrame.BackgroundTransparency = 1
    rootFrame.Parent = bill

    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(1, -10, 0, 8)
    healthBg.Position = UDim2.new(0, 5, 0, 0)
    healthBg.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = rootFrame
    local hbCorner = Instance.new("UICorner", healthBg)
    hbCorner.CornerRadius = UDim.new(0, 100)

    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBg
    local hfCorner = Instance.new("UICorner", healthFill)
    hfCorner.CornerRadius = UDim.new(0, 100)

    local smallBg = Instance.new("Frame")
    smallBg.Size = UDim2.new(0.6, 0, 0, 4)
    smallBg.Position = UDim2.new(0.2, 0, 0, 10)
    smallBg.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    smallBg.BorderSizePixel = 0
    smallBg.Parent = rootFrame
    local sbCorner = Instance.new("UICorner", smallBg)
    sbCorner.CornerRadius = UDim.new(0, 100)

    local smallFill = Instance.new("Frame")
    smallFill.Size = UDim2.new(1, 0, 1, 0)
    smallFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    smallFill.BorderSizePixel = 0
    smallFill.Parent = smallBg
    local sfCorner = Instance.new("UICorner", smallFill)
    sfCorner.CornerRadius = UDim.new(0, 100)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 16)
    nameLabel.Position = UDim2.new(0, 5, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Color3.fromRGB(230, 230, 255)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Text = player.Name
    nameLabel.Parent = rootFrame

    playerESP[player] = {
        billboard = bill,
        healthFill = healthFill,
        smallFill = smallFill,
        humanoid = humanoid
    }
end

local function createOrUpdateHighlight(player, character)
    if not character or not character:IsDescendantOf(Workspace) then return end
    if not isEnemyForESP(player) then
        if highlightsByPlayer[player] then
            highlightsByPlayer[player]:Destroy()
            highlightsByPlayer[player] = nil
        end
        return
    end

    local highlight = highlightsByPlayer[player]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight_" .. player.Name
        highlight.Parent = espFolder
        highlightsByPlayer[player] = highlight
    end

    highlight.Adornee = character
    highlight.FillColor = config.espColor
    highlight.OutlineColor = config.espColor
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0

    setupBillboard(player, character)
end

local function onCharacterAdded(player, character)
    character:WaitForChild("HumanoidRootPart", 5)
    createOrUpdateHighlight(player, character)
end

local function cleanupPlayerESP(player)
    if highlightsByPlayer[player] then
        highlightsByPlayer[player]:Destroy()
        highlightsByPlayer[player] = nil
    end
    if playerESP[player] then
        local data = playerESP[player]
        if data.billboard then data.billboard:Destroy() end
        playerESP[player] = nil
    end
    removeExcludeRow(player)
end

local function setupPlayer(player)
    if player == LocalPlayer then return end

    addExcludeRow(player)

    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)

    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    setupPlayer(plr)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayerESP)

-----------------------------
-- FOV Circle UI + Line to Target
-----------------------------
local fovFrame = Instance.new("Frame")
fovFrame.Name = "FOVCircle"
fovFrame.Size = UDim2.fromOffset(config.fovRadius * 2, config.fovRadius * 2)
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.BackgroundTransparency = 1
fovFrame.Parent = screenGui

local fovCircle = Instance.new("UICorner", fovFrame)
fovCircle.CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke", fovFrame)
fovStroke.Thickness = 2
fovStroke.LineJoinMode = Enum.LineJoinMode.Round
fovStroke.Color = config.fovColor

-- خط الهدف
local lineFrame = Instance.new("Frame")
lineFrame.Name = "LineToTarget"
lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
lineFrame.Size = UDim2.fromOffset(0, config.lineThickness or config.lineThickness)
lineFrame.BackgroundColor3 = config.lineColor
lineFrame.BorderSizePixel = 0
lineFrame.BackgroundTransparency = 0
lineFrame.Visible = false
lineFrame.Parent = screenGui

local function drawLine(fromPos: Vector2, toPos: Vector2)
    local midPoint = (fromPos + toPos) / 2
    local diff = toPos - fromPos
    local distance = diff.Magnitude
    local angle = math.deg(math.atan2(diff.Y, diff.X))

    lineFrame.Visible = true
    lineFrame.Size = UDim2.fromOffset(distance, config.lineThickness)
    lineFrame.Position = UDim2.fromOffset(midPoint.X, midPoint.Y)
    lineFrame.Rotation = angle
    lineFrame.BackgroundColor3 = config.lineColor
end

-----------------------------
-- Aimbot Target Selection
-----------------------------
local function getAimPart(character)
    if not character then return nil end
    local part = character:FindFirstChild(config.aimPartName)
    if not part then
        part = character:FindFirstChild("HumanoidRootPart")
    end
    return part
end

-- يرجع أقرب Part + اللاعب داخل الـFOV حوالين الماوس
local function getClosestEnemyInFOV()
    local mousePos = UserInputService:GetMouseLocation()
    local closestDist = math.huge
    local bestTargetPart = nil
    local bestPlayer = nil

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isEnemyForAimbot(plr) and plr.Character then
            local aimPart = getAimPart(plr.Character)
            if aimPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
                    local dist = (Vector2.new(mousePos.X, mousePos.Y) - screenPoint).Magnitude
                    if dist <= config.fovRadius and dist < closestDist then
                        closestDist = dist
                        bestTargetPart = aimPart
                        bestPlayer = plr
                    end
                end
            end
        end
    end

    return bestTargetPart, bestPlayer
end

-----------------------------
-- ATM ESP
-----------------------------
local atmParts = {}

local function isATMPart(obj)
    return obj:IsA("BasePart") and obj.Parent and obj.Parent.Name == "ATM"
end

local function getATMModelFromPart(part)
    if part.Parent and part.Parent:IsA("Model") and part.Parent.Name == "ATM" then
        return part.Parent
    end
    return nil
end

local function hasVisibleInteract(atmModel)
    if not atmModel or not atmModel:IsDescendantOf(Workspace) then
        return false
    end

    local foundAny = false
    for _, obj in ipairs(atmModel:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            foundAny = true
            if obj.Enabled == true then
                return true
            end
        end
    end

    if foundAny then
        return false
    else
        return false
    end
end

local function updateATMHighlight(part)
    local data = atmParts[part]
    if not data then return end
    local highlight = data.highlight
    local atmModel = data.atmModel

    if not highlight or not atmModel or not part:IsDescendantOf(Workspace) then
        atmParts[part] = nil
        if highlight then
            highlight:Destroy()
        end
        return
    end

    highlight.Enabled = config.atmEspEnabled
    if not config.atmEspEnabled then
        return
    end

    local visible = hasVisibleInteract(atmModel)

    if visible then
        highlight.FillColor = config.atmGreenColor
    else
        highlight.FillColor = config.atmRedColor
    end

    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
end

local function registerATMPart(part)
    if atmParts[part] then return end

    local atmModel = getATMModelFromPart(part)
    if not atmModel then return end

    local highlight = part:FindFirstChild("ATM_ESP")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ATM_ESP"
        highlight.Adornee = part
        highlight.Parent = part
    end

    atmParts[part] = {
        highlight = highlight,
        atmModel = atmModel
    }

    updateATMHighlight(part)
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    if isATMPart(obj) then
        registerATMPart(obj)
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if isATMPart(obj) then
        registerATMPart(obj)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        for part, _ in pairs(atmParts) do
            if part and part.Parent then
                updateATMHighlight(part)
            else
                atmParts[part] = nil
            end
        end
    end
end)

-----------------------------
-- Input Handling (Aim Key)
-----------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if waitingForAimKey then
        waitingForAimKey = false

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.MouseButton3 then

            config.aimKeyType = "Mouse"
            config.aimKey = input.UserInputType

        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            config.aimKeyType = "Key"
            config.aimKey = input.KeyCode
        else
            aimKeyButton.Text = "زر غير مدعوم"
            task.delay(1, function()
                refreshAimKeyButtonText()
            end)
            return
        end

        refreshAimKeyButtonText()
        return
    end

    if config.aimKeyType == "Mouse" then
        if input.UserInputType == config.aimKey then
            aimKeyHeld = true
        end
    elseif config.aimKeyType == "Key" then
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == config.aimKey then
            aimKeyHeld = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if config.aimKeyType == "Mouse" then
        if input.UserInputType == config.aimKey then
            aimKeyHeld = false
        end
    elseif config.aimKeyType == "Key" then
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == config.aimKey then
            aimKeyHeld = false
        end
    end
end)

-----------------------------
-- Main Render Loop
-----------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    -- تحديث ESP
    for player, highlight in pairs(highlightsByPlayer) do
        if highlight then
            highlight.Enabled = config.espEnabled and isEnemyForESP(player)
            highlight.FillColor = config.espColor
            highlight.OutlineColor = config.espColor
        end
    end

    for player, data in pairs(playerESP) do
        if data.humanoid and data.healthFill and data.smallFill then
            local hp = data.humanoid.Health
            local max = data.humanoid.MaxHealth > 0 and data.humanoid.MaxHealth or 100
            local ratio = math.clamp(hp / max, 0, 1)

            data.healthFill.Size = UDim2.new(ratio, 0, 1, 0)
            data.smallFill.Size = UDim2.new(ratio, 0, 1, 0)
        end
    end

    -- دائرة FOV حول الماوس
    local mousePos = UserInputService:GetMouseLocation()
    fovFrame.Visible = config.fovEnabled
    fovFrame.Size = UDim2.fromOffset(config.fovRadius * 2, config.fovRadius * 2)
    fovStroke.Color = config.fovColor
    fovFrame.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)

    -- اختيار الهدف
    local targetPart, targetPlayer = getClosestEnemyInFOV()

    -- Aimbot
    local shouldAim = false
    if config.aimbotEnabled then
        if config.aimMode == "AUTO" then
            shouldAim = true
        elseif config.aimMode == "HOLD" then
            shouldAim = aimKeyHeld
        end
    end

    if shouldAim and targetPart then
        -- Direct Aim بدون سمووث
        local camPos = Camera.CFrame.Position
        Camera.CFrame = CFrame.new(camPos, targetPart.Position)
    end

    -- خط من شخصيتك لأقرب لاعب داخل الـFOV
    if config.lineEnabled and targetPlayer and targetPlayer.Character and HRP and HRP.Parent then
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            local myScreenPos, myOnScreen = Camera:WorldToViewportPoint(HRP.Position)
            local targetScreenPos, targetOnScreen = Camera:WorldToViewportPoint(targetHRP.Position)
            if myOnScreen and targetOnScreen then
                local from2D = Vector2.new(myScreenPos.X, myScreenPos.Y)
                local to2D = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                drawLine(from2D, to2D)
            else
                lineFrame.Visible = false
            end
        else
            lineFrame.Visible = false
        end
    else
        lineFrame.Visible = false
    end
end)
