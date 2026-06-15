--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                     JELLYFISH v1.0                            ║
    ║           Rod Switcher untuk Fisch (Delta Executor)           ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║  Fitur:                                                       ║
    ║  • Auto-switch rod berdasarkan proximity ke Risk/Hunt Spawn   ║
    ║  • UI minimalis dengan tema hitam-oranye neon                 ║
    ║  • Non-blocking, aman dijalankan bersama script lain          ║
    ╚═══════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════════════════════
-- KONFIGURASI (UBAH SESUAI KEBUTUHAN)
-- ═══════════════════════════════════════════════════════════════════

local CONFIG = {
    maxDistance = 50,           -- Radius deteksi Risk (dalam studs)
    checkInterval = 0.5,        -- Interval pengecekan (dalam detik)
    rodSwitchCooldown = 120,      -- Cooldown antar pergantian rod (detik)
}

-- ═══════════════════════════════════════════════════════════════════
-- SERVICES & VARIABEL UTAMA
-- ═══════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Variabel state untuk rod
local rod_1 = nil               -- Farming Rod (kondisi normal)
local rod_2 = nil               -- Disturbance Rod (kondisi bahaya)
local currentRodType = "farming" -- Tipe rod yang sedang aktif
local isAutoSwitchEnabled = false
local isScriptRunning = true
local lastSwitchTime = 0

-- ═══════════════════════════════════════════════════════════════════
-- WARNA TEMA UI
-- ═══════════════════════════════════════════════════════════════════

local COLORS = {
    background = Color3.fromRGB(18, 18, 22),
    backgroundSecondary = Color3.fromRGB(25, 25, 30),
    accent = Color3.fromRGB(255, 140, 50),          -- Oranye neon
    accentGlow = Color3.fromRGB(255, 165, 80),      -- Oranye lebih terang
    accentDim = Color3.fromRGB(180, 100, 35),       -- Oranye redup
    textPrimary = Color3.fromRGB(240, 240, 240),
    textSecondary = Color3.fromRGB(160, 160, 165),
    success = Color3.fromRGB(80, 200, 120),
    danger = Color3.fromRGB(220, 80, 80),
    toggleOff = Color3.fromRGB(60, 60, 65),
}

-- ═══════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════

-- Update referensi karakter ketika respawn
local function updateCharacterReference()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
end)

-- Fungsi untuk membuat corner radius
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

-- Fungsi untuk membuat stroke/border
local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or COLORS.accent
    stroke.Thickness = thickness or 1
    stroke.Transparency = 0.5
    stroke.Parent = parent
    return stroke
end

-- Fungsi untuk animasi hover
local function addHoverEffect(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = hoverColor
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = normalColor
        }):Play()
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- FUNGSI DETEKSI ROD YANG SEDANG DIPEGANG
-- ═══════════════════════════════════════════════════════════════════

local function getEquippedRod()
    if not Character then return nil end
    
    -- Cek tool yang sedang dipegang di Character
    for _, tool in ipairs(Character:GetChildren()) do
        if tool:IsA("Tool") then
            -- Cek apakah ini adalah fishing rod (biasanya memiliki "Rod" di nama)
            local toolName = tool.Name:lower()
            if toolName:find("rod") or toolName:find("pole") or toolName:find("fishing") then
                return tool.Name
            end
        end
    end
    
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
-- FUNGSI EQUIP ROD DARI BACKPACK
-- ═══════════════════════════════════════════════════════════════════

local function equipRod(rodName)
    if not rodName then return false end
    if not Character then 
        updateCharacterReference()
    end
    
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    -- Cek cooldown untuk mencegah spam switching
    local currentTime = tick()
    if currentTime - lastSwitchTime < CONFIG.rodSwitchCooldown then
        return false
    end
    
    -- Cari rod di Backpack
    local rod = Backpack:FindFirstChild(rodName)
    
    -- Jika rod sudah di-equip (ada di Character), skip
    if Character:FindFirstChild(rodName) then
        return true
    end
    
    if rod and rod:IsA("Tool") then
        -- Unequip tool yang sedang dipegang terlebih dahulu
        for _, tool in ipairs(Character:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = Backpack
            end
        end
        
        -- Equip rod yang diinginkan dengan delay kecil
        task.defer(function()
            rod.Parent = Character
        end)
        
        lastSwitchTime = currentTime
        return true
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════════════
-- FUNGSI DETEKSI RISK/HUNT SPAWN DI WORKSPACE
-- ═══════════════════════════════════════════════════════════════════

local function findNearbyRisks()
    if not Character then return false end
    
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local playerPosition = hrp.Position
    
    -- Daftar keyword untuk mendeteksi Risk/Hunt Spawn
    local riskKeywords = {
        "whirlpool", "meteor", "tornado", "storm", "hunt", 
        "risk", "event", "spawn", "disturbance", "anomaly",
        "vortex", "danger", "hazard"
    }
    
    -- Fungsi rekursif untuk mencari di seluruh descendants
    local function searchInDescendants(parent)
        for _, obj in ipairs(parent:GetDescendants()) do
            -- Cek nama object apakah mengandung keyword Risk
            local objName = obj.Name:lower()
            
            for _, keyword in ipairs(riskKeywords) do
                if objName:find(keyword) then
                    -- Cek apakah object memiliki posisi (Part/Model)
                    local objPosition = nil
                    
                    if obj:IsA("BasePart") then
                        objPosition = obj.Position
                    elseif obj:IsA("Model") then
                        local primaryPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if primaryPart then
                            objPosition = primaryPart.Position
                        end
                    end
                    
                    -- Hitung jarak menggunakan Magnitude
                    if objPosition then
                        local distance = (playerPosition - objPosition).Magnitude
                        
                        if distance <= CONFIG.maxDistance then
                            return true, obj.Name, distance
                        end
                    end
                end
            end
        end
        
        return false
    end
    
    -- Cari di Workspace
    return searchInDescendants(workspace)
end

-- ═══════════════════════════════════════════════════════════════════
-- MEMBUAT UI UTAMA
-- ═══════════════════════════════════════════════════════════════════

local function createUI()
    -- Hapus UI lama jika ada
    local existingUI = LocalPlayer.PlayerGui:FindFirstChild("JellyfishUI")
    if existingUI then existingUI:Destroy() end
    
    -- ScreenGui utama
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "JellyfishUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer.PlayerGui
    
    -- ═══════════════════════════════════════════════════════════════
    -- MAIN FRAME
    -- ═══════════════════════════════════════════════════════════════
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 280, 0, 320)
    MainFrame.Position = UDim2.new(0, 20, 0.5, -160)
    MainFrame.BackgroundColor3 = COLORS.background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    createCorner(MainFrame, 12)
    createStroke(MainFrame, COLORS.accent, 1.5)
    
    -- Drop shadow effect
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.6
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    Shadow.ZIndex = -1
    Shadow.Parent = MainFrame
    
    -- ═══════════════════════════════════════════════════════════════
    -- HEADER BAR
    -- ═══════════════════════════════════════════════════════════════
    
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 45)
    Header.BackgroundColor3 = COLORS.backgroundSecondary
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    createCorner(Header, 12)
    
    -- Fix corner di bagian bawah header
    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 15)
    HeaderFix.Position = UDim2.new(0, 0, 1, -15)
    HeaderFix.BackgroundColor3 = COLORS.backgroundSecondary
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header
    
    -- Title "Jellyfish"
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 120, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🪼 Jellyfish"
    Title.TextColor3 = COLORS.accent
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- ═══════════════════════════════════════════════════════════════
    -- TOMBOL MINIMIZE
    -- ═══════════════════════════════════════════════════════════════
    
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -75, 0.5, -15)
    MinimizeBtn.BackgroundColor3 = COLORS.toggleOff
    MinimizeBtn.BorderSizePixel = 0
    MinimizeBtn.Text = "−"
    MinimizeBtn.TextColor3 = COLORS.textPrimary
    MinimizeBtn.TextSize = 20
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Parent = Header
    createCorner(MinimizeBtn, 6)
    addHoverEffect(MinimizeBtn, COLORS.toggleOff, COLORS.accent)
    
    -- ═══════════════════════════════════════════════════════════════
    -- TOMBOL CLOSE
    -- ═══════════════════════════════════════════════════════════════
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.BackgroundColor3 = COLORS.danger
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = COLORS.textPrimary
    CloseBtn.TextSize = 22
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = Header
    createCorner(CloseBtn, 6)
    addHoverEffect(CloseBtn, COLORS.danger, Color3.fromRGB(255, 100, 100))
    
    -- ═══════════════════════════════════════════════════════════════
    -- CONTENT AREA
    -- ═══════════════════════════════════════════════════════════════
    
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -30, 1, -60)
    Content.Position = UDim2.new(0, 15, 0, 50)
    Content.BackgroundTransparency = 1
    Content.Parent = MainFrame
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 12)
    ContentLayout.Parent = Content
    
    -- ═══════════════════════════════════════════════════════════════
    -- STATUS DISPLAY
    -- ═══════════════════════════════════════════════════════════════
    
    local StatusFrame = Instance.new("Frame")
    StatusFrame.Name = "StatusFrame"
    StatusFrame.Size = UDim2.new(1, 0, 0, 50)
    StatusFrame.BackgroundColor3 = COLORS.backgroundSecondary
    StatusFrame.BorderSizePixel = 0
    StatusFrame.LayoutOrder = 1
    StatusFrame.Parent = Content
    createCorner(StatusFrame, 8)
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -20, 0, 20)
    StatusLabel.Position = UDim2.new(0, 10, 0, 5)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Status: Idle"
    StatusLabel.TextColor3 = COLORS.textSecondary
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = StatusFrame
    
    local CurrentRodLabel = Instance.new("TextLabel")
    CurrentRodLabel.Name = "CurrentRodLabel"
    CurrentRodLabel.Size = UDim2.new(1, -20, 0, 20)
    CurrentRodLabel.Position = UDim2.new(0, 10, 0, 25)
    CurrentRodLabel.BackgroundTransparency = 1
    CurrentRodLabel.Text = "Current: None"
    CurrentRodLabel.TextColor3 = COLORS.accent
    CurrentRodLabel.TextSize = 13
    CurrentRodLabel.Font = Enum.Font.GothamSemibold
    CurrentRodLabel.TextXAlignment = Enum.TextXAlignment.Left
    CurrentRodLabel.Parent = StatusFrame
    
    -- ═══════════════════════════════════════════════════════════════
    -- TOGGLE AUTO SWITCH
    -- ═══════════════════════════════════════════════════════════════
    
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = "ToggleFrame"
    ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
    ToggleFrame.BackgroundColor3 = COLORS.backgroundSecondary
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.LayoutOrder = 2
    ToggleFrame.Parent = Content
    createCorner(ToggleFrame, 8)
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(0.65, 0, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = "Auto Switch Rod"
    ToggleLabel.TextColor3 = COLORS.textPrimary
    ToggleLabel.TextSize = 14
    ToggleLabel.Font = Enum.Font.GothamSemibold
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = ToggleFrame
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ToggleBtn"
    ToggleBtn.Size = UDim2.new(0, 50, 0, 26)
    ToggleBtn.Position = UDim2.new(1, -60, 0.5, -13)
    ToggleBtn.BackgroundColor3 = COLORS.toggleOff
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = ""
    ToggleBtn.Parent = ToggleFrame
    createCorner(ToggleBtn, 13)
    
    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Name = "Circle"
    ToggleCircle.Size = UDim2.new(0, 20, 0, 20)
    ToggleCircle.Position = UDim2.new(0, 3, 0.5, -10)
    ToggleCircle.BackgroundColor3 = COLORS.textPrimary
    ToggleCircle.BorderSizePixel = 0
    ToggleCircle.Parent = ToggleBtn
    createCorner(ToggleCircle, 10)
    
    -- ═══════════════════════════════════════════════════════════════
    -- BUTTON: SET FARMING ROD
    -- ═══════════════════════════════════════════════════════════════
    
    local FarmingRodBtn = Instance.new("TextButton")
    FarmingRodBtn.Name = "FarmingRodBtn"
    FarmingRodBtn.Size = UDim2.new(1, 0, 0, 45)
    FarmingRodBtn.BackgroundColor3 = COLORS.backgroundSecondary
    FarmingRodBtn.BorderSizePixel = 0
    FarmingRodBtn.Text = ""
    FarmingRodBtn.LayoutOrder = 3
    FarmingRodBtn.Parent = Content
    createCorner(FarmingRodBtn, 8)
    createStroke(FarmingRodBtn, COLORS.success, 1)
    addHoverEffect(FarmingRodBtn, COLORS.backgroundSecondary, Color3.fromRGB(35, 45, 40))
    
    local FarmingIcon = Instance.new("TextLabel")
    FarmingIcon.Size = UDim2.new(0, 30, 1, 0)
    FarmingIcon.Position = UDim2.new(0, 10, 0, 0)
    FarmingIcon.BackgroundTransparency = 1
    FarmingIcon.Text = "🎣"
    FarmingIcon.TextSize = 20
    FarmingIcon.Parent = FarmingRodBtn
    
    local FarmingLabel = Instance.new("TextLabel")
    FarmingLabel.Size = UDim2.new(1, -50, 0, 20)
    FarmingLabel.Position = UDim2.new(0, 45, 0, 5)
    FarmingLabel.BackgroundTransparency = 1
    FarmingLabel.Text = "Set Farming Rod"
    FarmingLabel.TextColor3 = COLORS.success
    FarmingLabel.TextSize = 13
    FarmingLabel.Font = Enum.Font.GothamSemibold
    FarmingLabel.TextXAlignment = Enum.TextXAlignment.Left
    FarmingLabel.Parent = FarmingRodBtn
    
    local FarmingValue = Instance.new("TextLabel")
    FarmingValue.Name = "Value"
    FarmingValue.Size = UDim2.new(1, -50, 0, 15)
    FarmingValue.Position = UDim2.new(0, 45, 0, 25)
    FarmingValue.BackgroundTransparency = 1
    FarmingValue.Text = "Not Set"
    FarmingValue.TextColor3 = COLORS.textSecondary
    FarmingValue.TextSize = 11
    FarmingValue.Font = Enum.Font.Gotham
    FarmingValue.TextXAlignment = Enum.TextXAlignment.Left
    FarmingValue.Parent = FarmingRodBtn
    
    -- ═══════════════════════════════════════════════════════════════
    -- BUTTON: SET DISTURBANCE ROD
    -- ═══════════════════════════════════════════════════════════════
    
    local DisturbanceRodBtn = Instance.new("TextButton")
    DisturbanceRodBtn.Name = "DisturbanceRodBtn"
    DisturbanceRodBtn.Size = UDim2.new(1, 0, 0, 45)
    DisturbanceRodBtn.BackgroundColor3 = COLORS.backgroundSecondary
    DisturbanceRodBtn.BorderSizePixel = 0
    DisturbanceRodBtn.Text = ""
    DisturbanceRodBtn.LayoutOrder = 4
    DisturbanceRodBtn.Parent = Content
    createCorner(DisturbanceRodBtn, 8)
    createStroke(DisturbanceRodBtn, COLORS.accent, 1)
    addHoverEffect(DisturbanceRodBtn, COLORS.backgroundSecondary, Color3.fromRGB(45, 35, 30))
    
    local DisturbanceIcon = Instance.new("TextLabel")
    DisturbanceIcon.Size = UDim2.new(0, 30, 1, 0)
    DisturbanceIcon.Position = UDim2.new(0, 10, 0, 0)
    DisturbanceIcon.BackgroundTransparency = 1
    DisturbanceIcon.Text = "⚡"
    DisturbanceIcon.TextSize = 20
    DisturbanceIcon.Parent = DisturbanceRodBtn
    
    local DisturbanceLabel = Instance.new("TextLabel")
    DisturbanceLabel.Size = UDim2.new(1, -50, 0, 20)
    DisturbanceLabel.Position = UDim2.new(0, 45, 0, 5)
    DisturbanceLabel.BackgroundTransparency = 1
    DisturbanceLabel.Text = "Set Disturbance Rod"
    DisturbanceLabel.TextColor3 = COLORS.accent
    DisturbanceLabel.TextSize = 13
    DisturbanceLabel.Font = Enum.Font.GothamSemibold
    DisturbanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    DisturbanceLabel.Parent = DisturbanceRodBtn
    
    local DisturbanceValue = Instance.new("TextLabel")
    DisturbanceValue.Name = "Value"
    DisturbanceValue.Size = UDim2.new(1, -50, 0, 15)
    DisturbanceValue.Position = UDim2.new(0, 45, 0, 25)
    DisturbanceValue.BackgroundTransparency = 1
    DisturbanceValue.Text = "Not Set"
    DisturbanceValue.TextColor3 = COLORS.textSecondary
    DisturbanceValue.TextSize = 11
    DisturbanceValue.Font = Enum.Font.Gotham
    DisturbanceValue.TextXAlignment = Enum.TextXAlignment.Left
    DisturbanceValue.Parent = DisturbanceRodBtn
    
    -- ═══════════════════════════════════════════════════════════════
    -- RADIUS INFO
    -- ═══════════════════════════════════════════════════════════════
    
    local RadiusInfo = Instance.new("TextLabel")
    RadiusInfo.Name = "RadiusInfo"
    RadiusInfo.Size = UDim2.new(1, 0, 0, 25)
    RadiusInfo.BackgroundTransparency = 1
    RadiusInfo.Text = "📍 Detection Radius: " .. CONFIG.maxDistance .. " studs"
    RadiusInfo.TextColor3 = COLORS.textSecondary
    RadiusInfo.TextSize = 11
    RadiusInfo.Font = Enum.Font.Gotham
    RadiusInfo.LayoutOrder = 5
    RadiusInfo.Parent = Content
    
    -- ═══════════════════════════════════════════════════════════════
    -- FLOATING BUTTON (MUNCUL SAAT MINIMIZE)
    -- ═══════════════════════════════════════════════════════════════
    
    local FloatingBtn = Instance.new("TextButton")
    FloatingBtn.Name = "FloatingBtn"
    FloatingBtn.Size = UDim2.new(0, 50, 0, 50)
    FloatingBtn.Position = UDim2.new(0, 20, 0.5, -25)
    FloatingBtn.BackgroundColor3 = COLORS.background
    FloatingBtn.BorderSizePixel = 0
    FloatingBtn.Text = "🪼"
    FloatingBtn.TextSize = 28
    FloatingBtn.Visible = false
    FloatingBtn.Parent = ScreenGui
    createCorner(FloatingBtn, 25)
    createStroke(FloatingBtn, COLORS.accent, 2)
    
    -- Glow effect untuk floating button
    local FloatingGlow = Instance.new("ImageLabel")
    FloatingGlow.Size = UDim2.new(1, 20, 1, 20)
    FloatingGlow.Position = UDim2.new(0, -10, 0, -10)
    FloatingGlow.BackgroundTransparency = 1
    FloatingGlow.Image = "rbxassetid://5554236805"
    FloatingGlow.ImageColor3 = COLORS.accent
    FloatingGlow.ImageTransparency = 0.7
    FloatingGlow.ScaleType = Enum.ScaleType.Slice
    FloatingGlow.SliceCenter = Rect.new(23, 23, 277, 277)
    FloatingGlow.ZIndex = -1
    FloatingGlow.Parent = FloatingBtn
    
    -- ═══════════════════════════════════════════════════════════════
    -- DRAG FUNCTIONALITY
    -- ═══════════════════════════════════════════════════════════════
    
    local function makeDraggable(frame)
        local dragging, dragInput, dragStart, startPos
        
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end
    
    makeDraggable(MainFrame)
    makeDraggable(FloatingBtn)
    
    -- ═══════════════════════════════════════════════════════════════
    -- EVENT HANDLERS
    -- ═══════════════════════════════════════════════════════════════
    
    -- Toggle Auto Switch
    ToggleBtn.MouseButton1Click:Connect(function()
        isAutoSwitchEnabled = not isAutoSwitchEnabled
        
        local targetPos = isAutoSwitchEnabled and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        local targetColor = isAutoSwitchEnabled and COLORS.accent or COLORS.toggleOff
        
        TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        
        StatusLabel.Text = isAutoSwitchEnabled and "Status: Active" or "Status: Idle"
        StatusLabel.TextColor3 = isAutoSwitchEnabled and COLORS.success or COLORS.textSecondary
    end)
    
    -- Set Farming Rod
    FarmingRodBtn.MouseButton1Click:Connect(function()
        local equippedRod = getEquippedRod()
        if equippedRod then
            rod_1 = equippedRod
            FarmingValue.Text = equippedRod
            FarmingValue.TextColor3 = COLORS.success
        else
            FarmingValue.Text = "No rod equipped!"
            FarmingValue.TextColor3 = COLORS.danger
            task.delay(2, function()
                if rod_1 then
                    FarmingValue.Text = rod_1
                    FarmingValue.TextColor3 = COLORS.success
                else
                    FarmingValue.Text = "Not Set"
                    FarmingValue.TextColor3 = COLORS.textSecondary
                end
            end)
        end
    end)
    
    -- Set Disturbance Rod
    DisturbanceRodBtn.MouseButton1Click:Connect(function()
        local equippedRod = getEquippedRod()
        if equippedRod then
            rod_2 = equippedRod
            DisturbanceValue.Text = equippedRod
            DisturbanceValue.TextColor3 = COLORS.accent
        else
            DisturbanceValue.Text = "No rod equipped!"
            DisturbanceValue.TextColor3 = COLORS.danger
            task.delay(2, function()
                if rod_2 then
                    DisturbanceValue.Text = rod_2
                    DisturbanceValue.TextColor3 = COLORS.accent
                else
                    DisturbanceValue.Text = "Not Set"
                    DisturbanceValue.TextColor3 = COLORS.textSecondary
               end
           end)
        end
    end)
    
    -- Minimize
    MinimizeBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        FloatingBtn.Visible = true
    end)
    
    -- Restore dari minimize
    FloatingBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        FloatingBtn.Visible = false
    end)
    
    -- Close & Cleanup
    CloseBtn.MouseButton1Click:Connect(function()
        isScriptRunning = false
        isAutoSwitchEnabled = false
        ScreenGui:Destroy()
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    -- RETURN UI ELEMENTS FOR EXTERNAL ACCESS
    -- ═══════════════════════════════════════════════════════════════
    
    return {
        ScreenGui = ScreenGui,
        StatusLabel = StatusLabel,
        CurrentRodLabel = CurrentRodLabel,
    }
end
-- ═══════════════════════════════════════════════════════════════════
-- MAIN LOOP - DETEKSI DAN AUTO SWITCH
-- ═══════════════════════════════════════════════════════════════════
local function startMainLoop(uiElements)
    task.spawn(function()
        while isScriptRunning do
            task.wait(CONFIG.checkInterval)
            
            if not isAutoSwitchEnabled then
                continue
            end
            
            -- Pastikan kedua rod sudah di-set
            if not rod_1 or not rod_2 then
                uiElements.StatusLabel.Text = "Status: Set both rods first!"
                uiElements.StatusLabel.TextColor3 = COLORS.danger
                continue
            end
            
            -- Deteksi Risk di sekitar player
            local riskDetected, riskName, riskDistance = findNearbyRisks()
            
            if riskDetected then
                -- Ada Risk dalam radius - gunakan Disturbance Rod
                if currentRodType ~= "disturbance" then
            local success = equipRod(rod_2)
                    if success then
                        currentRodType = "disturbance"
                        uiElements.CurrentRodLabel.Text = "Current: " .. rod_2 .. " (Risk!)"
                        uiElements.CurrentRodLabel.TextColor3 = COLORS.accent
                        uiElements.StatusLabel.Text = "⚠️ " .. (riskName or "Risk") .. " nearby!"
                        uiElements.StatusLabel.TextColor3 = COLORS.accent
                    end
                end
            else
                -- Tidak ada Risk - gunakan Farming Rod
                if currentRodType ~= "farming" then
                    local success = equipRod(rod_1)
                    if success then
                        currentRodType = "farming"
                        uiElements.CurrentRodLabel.Text = "Current: " .. rod_1
                        uiElements.CurrentRodLabel.TextColor3 = COLORS.success
                        uiElements.StatusLabel.Text = "Status: Farming Mode"
                        uiElements.StatusLabel.TextColor3 = COLORS.success
                    end
                end
            end
        end
    end)
end
-- ═══════════════════════════════════════════════════════════════════
-- INISIALISASI SCRIPT
-- ═══════════════════════════════════════════════════════════════════
local function init()
    local uiElements = createUI()
    startMainLoop(uiElements)
    
    print("═══════════════════════════════════════")
    print("   🪼 Jellyfish v1.0 Loaded!")
    print("   Rod Switcher for Fisch")
    print("═══════════════════════════════════════")
end
-- Jalankan script
init()
