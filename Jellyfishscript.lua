-- =============================================================================
-- CAROL CO-PILOT SCRIPT (FISCH) - OPTIMIZED FOR DELTA EXECUTOR
-- =============================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Target Parent GUI (Delta/Mobile Compatibility)
local ParentGui = game:GetService("CoreGui")
if gethui then ParentGui = gethui() end

-- =============================================================================
-- STATE CHANGER & VARIABLES
-- =============================================================================
local Variables = {
    rod_1 = nil, -- Farming Rod
    rod_2 = nil, -- Disturbance Rod
    autoSwapEnabled = false,
    syncEnabled = false,
    hideNameEnabled = false,
    selectedScript = nil,
    isRiskActive = false,
    originalDisplayName = LocalPlayer.DisplayName,
    originalName = LocalPlayer.Name
}

local RunningScriptsList = {}

-- =============================================================================
-- LOG SYSTEM FUNCTION
-- =============================================================================
local function createLog(text)
    local timestamp = os.date("%X")
    local logText = string.format("[%s] %s", timestamp, text)
    print(logText)
    
    if _G.LogContainer then
        local logLabel = Instance.new("TextLabel")
        logLabel.Size = UDim2.new(1, -10, 0, 20)
        logLabel.BackgroundTransparency = 1
        logLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        logLabel.TextXAlignment = Enum.TextXAlignment.Left
        logLabel.Font = Enum.Font.SourceSans
        logLabel.TextSize = 14
        logLabel.Text = logText
        logLabel.Parent = _G.LogContainer
        _G.LogContainer.CanvasSize = UDim2.new(0, 0, 0, _G.LogContainer.UIListLayout.AbsoluteContentSize.Y + 25)
    end
end

-- =============================================================================
-- CORE LOGIC: DETEKSI RISK / HUNT SPAWN & SWAP SYSTEM
-- =============================================================================

-- Fungsi Deteksi Hunt Spawn (Sesuaikan dengan nama object/event spesifik Fisch jika berubah)
local function checkHuntSpawn()
    -- Mengendus keberadaan zona berisiko atau event Hunt di Workspace
    -- Biasanya Fisch memunculkan part khusus atau penanda di area laut
    local huntFound = false
    
    -- Contoh logika universal: mencari object bernama "Hunt" atau mengandung kata "Risk" / "Meteor"
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:find("Hunt") or obj.Name:find("Risk") or obj.Name:find("Zone") and obj:GetAttribute("IsRisk") then
            huntFound = true
            break
        end
    end
    
    return huntFound
end

-- Fungsi Mekanisme Swap & Freeze Paksa
local function handleSwap(targetRodName)
    if not targetRodName then 
        createLog("Gagal Swap: Rod belum dikunci!")
        return 
    end

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local backpack = LocalPlayer.Backpack
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    -- 1. Deteksi dan 'Freeze' script utama jika fitur Sinkronisasi aktif
    local scriptToFreeze = nil
    if Variables.syncEnabled and Variables.selectedScript then
        if getrunningscripts then
            for _, scr in pairs(getrunningscripts()) do
                if scr.Name == Variables.selectedScript then
                    scriptToFreeze = scr
                    scriptToFreeze.Disabled = true
                    createLog("Menghentikan paksa script utama: " .. scr.Name)
                    break
                end
            end
        end
    end

    -- 2. Proses Unequip rod saat ini
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Tool") then
            item.Parent = backpack
        end
    end
    task.wait(0.2)

    -- 3. Cari dan Equip Rod baru
    local targetRod = backpack:FindFirstChild(targetRodName)
    if targetRod and humanoid then
        humanoid:EquipTool(targetRod)
        createLog("Berhasil menggunakan: " .. targetRodName)
    else
        createLog("Rod tidak ditemukan di Backpack: " .. targetRodName)
    end
    
    task.wait(0.3)

    -- 4. Unfreeze script utama kembali
    if scriptToFreeze then
        scriptToFreeze.Disabled = false
        createLog("Melanjutkan kembali script utama: " .. scriptToFreeze.Name)
    end
end

-- Loop Utama Co-Pilot
task.spawn(function()
    while task.wait(1) do
        if Variables.autoSwapEnabled then
            local currentRiskStatus = checkHuntSpawn()
            
            -- Jika ada perubahan status dari deteksi sebelumnya
            if currentRiskStatus ~= Variables.isRiskActive then
                Variables.isRiskActive = currentRiskStatus
                
                -- Jeda acak 0.5 sampai 10 detik sebelum eksekusi
                local randomDelay = math.random(5, 100) / 10
                createLog("Perubahan situasi terdeteksi! Menunggu jeda acak: " .. tostring(randomDelay) .. " detik.")
                task.wait(randomDelay)
                
                if Variables.isRiskActive then
                    createLog("Kondisi: Hunt Spawn Aktif. Bersiap menukar ke Rod 1.")
                    handleSwap(Variables.rod_1)
                else
                    createLog("Kondisi: Hunt Spawn Selesai/Aman. Bersiap menukar ke Rod 2.")
                    handleSwap(Variables.rod_2)
                end
            end
        end
    end
end)

-- =============================================================================
-- REFRESH SCRIPTS FOR DROP-DOWN (Delta compatibility code)
-- =============================================================================
local function refreshRunningScripts()
    table.clear(RunningScriptsList)
    if getrunningscripts then
        for _, scr in pairs(getrunningscripts()) do
            if scr.Name and scr.Name ~= "Carol" and not table.find(RunningScriptsList, scr.Name) then
                table.insert(RunningScriptsList, scr.Name)
            end
        end
    else
        -- Fallback jika executor tidak mendukung getrunningscripts
        table.insert(RunningScriptsList, "AutoFishingScriptDemo")
    end
end

-- =============================================================================
-- UI DESIGN (Blurry Dark-Orange Glass Interface - Scale 1/5 Mobile)
-- =============================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CarolGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentGui

-- Main Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.25, 0, 0.45, 0) -- Proporsional ~1/5 ukuran layar HP
MainFrame.Position = UDim2.new(0.375, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.25 -- Transparansi tinggi (simulasi Blurry Glass)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0) -- Neon Orange Border
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Header
local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundTransparency = 1
Header.Text = "Carol"
Header.TextColor3 = Color3.fromRGB(255, 100, 0)
Header.Font = Enum.Font.BebasNeue
Header.TextSize = 20
Header.Parent = MainFrame

-- Window Controls (Minimize & Close)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -25, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 12
CloseBtn.Parent = MainFrame

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 20, 0, 20)
MinBtn.Position = UDim2.new(1, -50, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 12
MinBtn.Parent = MainFrame

-- Container for content
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -10, 1, -40)
ContentFrame.Position = UDim2.new(0, 5, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 320)
ContentFrame.ScrollBarThickness = 4
ContentFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ContentFrame

-- Helper UI Function to update color toggles
local function updateToggleVisual(button, status)
    if status then
        button.TextColor3 = Color3.fromRGB(255, 100, 0) -- Oranye Menyala
    else
        button.TextColor3 = Color3.fromRGB(255, 255, 255) -- Putih Nonaktif
    end
end

-- =============================================================================
-- TAB I: AUTO DISTURBANCE
-- =============================================================================

local Section1Title = Instance.new("TextLabel")
Section1Title.Size = UDim2.new(1, 0, 0, 18)
Section1Title.Text = "--- AUTO DISTURBANCE ---"
Section1Title.TextColor3 = Color3.fromRGB(180, 180, 180)
Section1Title.Font = Enum.Font.SourceSansBold
Section1Title.TextSize = 14
Section1Title.BackgroundTransparency = 1
Section1Title.Parent = ContentFrame

-- Button Farming Rod
local FarmingRodBtn = Instance.new("TextButton")
FarmingRodBtn.Size = UDim2.new(1, -10, 0, 25)
FarmingRodBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FarmingRodBtn.Text = "Lock Farming Rod (rod_1): None"
FarmingRodBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmingRodBtn.Font = Enum.Font.SourceSans
FarmingRodBtn.TextSize = 12
FarmingRodBtn.Parent = ContentFrame

FarmingRodBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local equippedTool = char and char:FindFirstChildOfClass("Tool")
    if equippedTool then
        Variables.rod_1 = equippedTool.Name
        FarmingRodBtn.Text = "Lock Farming Rod: " .. Variables.rod_1
        createLog("Rod 1 dikunci ke: " .. Variables.rod_1)
    else
        createLog("Peringatan: Pegang/Equip Fishing Rod Anda terlebih dahulu!")
    end
end)

-- Button Disturbance Rod
local DisturbanceRodBtn = Instance.new("TextButton")
DisturbanceRodBtn.Size = UDim2.new(1, -10, 0, 25)
DisturbanceRodBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DisturbanceRodBtn.Text = "Lock Disturbance Rod (rod_2): None"
DisturbanceRodBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DisturbanceRodBtn.Font = Enum.Font.SourceSans
DisturbanceRodBtn.TextSize = 12
DisturbanceRodBtn.Parent = ContentFrame

DisturbanceRodBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local equippedTool = char and char:FindFirstChildOfClass("Tool")
    if equippedTool then
        Variables.rod_2 = equippedTool.Name
        DisturbanceRodBtn.Text = "Lock Disturbance: " .. Variables.rod_2
        createLog("Rod 2 dikunci ke: " .. Variables.rod_2)
    else
        createLog("Peringatan: Pegang/Equip Fishing Rod Anda terlebih dahulu!")
    end
end)

-- Toggle Auto Swap Rod!
local SwapToggleBtn = Instance.new("TextButton")
SwapToggleBtn.Size = UDim2.new(1, -10, 0, 25)
SwapToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SwapToggleBtn.Text = "Auto Swap Rod!"
SwapToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SwapToggleBtn.Font = Enum.Font.BebasNeue
SwapToggleBtn.TextSize = 14
SwapToggleBtn.Parent = ContentFrame

SwapToggleBtn.MouseButton1Click:Connect(function()
    Variables.autoSwapEnabled = not Variables.autoSwapEnabled
    updateToggleVisual(SwapToggleBtn, Variables.autoSwapEnabled)
    createLog("Auto Swap Rod diubah ke: " .. tostring(Variables.autoSwapEnabled))
end)

-- =============================================================================
-- TAB II: SCRIPT SYNCHRONIZE
-- =============================================================================

local Section2Title = Instance.new("TextLabel")
Section2Title.Size = UDim2.new(1, 0, 0, 18)
Section2Title.Text = "--- SCRIPT SYNCHRONIZE ---"
Section2Title.TextColor3 = Color3.fromRGB(180, 180, 180)
Section2Title.Font = Enum.Font.SourceSansBold
Section2Title.TextSize = 14
Section2Title.BackgroundTransparency = 1
Section2Title.Parent = ContentFrame

-- Bar Pilihan / Dropdown Simpel (Mendeteksi Script Running)
local ScriptSelectBtn = Instance.new("TextButton")
ScriptSelectBtn.Size = UDim2.new(1, -10, 0, 25)
ScriptSelectBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScriptSelectBtn.Text = "Target Script: Tap to Scan/Select"
ScriptSelectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScriptSelectBtn.Font = Enum.Font.SourceSans
ScriptSelectBtn.TextSize = 12
ScriptSelectBtn.Parent = ContentFrame

local currentIdx = 0
ScriptSelectBtn.MouseButton1Click:Connect(function()
    refreshRunningScripts()
    if #RunningScriptsList == 0 then
        ScriptSelectBtn.Text = "Target Script: No External Script Found"
        Variables.selectedScript = nil
        return
    end
    currentIdx = currentIdx + 1
    if currentIdx > #RunningScriptsList then currentIdx = 1 end
    
    Variables.selectedScript = RunningScriptsList[currentIdx]
    ScriptSelectBtn.Text = "Target Script: " .. Variables.selectedScript
    createLog("Target Sinkronisasi diatur ke: " .. Variables.selectedScript)
end)

-- Toggle Sync Script
local SyncToggleBtn = Instance.new("TextButton")
SyncToggleBtn.Size = UDim2.new(1, -10, 0, 25)
SyncToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SyncToggleBtn.Text = "Sync Script (Freeze Otoritas)"
SyncToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SyncToggleBtn.Font = Enum.Font.SourceSans
SyncToggleBtn.TextSize = 12
SyncToggleBtn.Parent = ContentFrame

SyncToggleBtn.MouseButton1Click:Connect(function()
    Variables.syncEnabled = not Variables.syncEnabled
    updateToggleVisual(SyncToggleBtn, Variables.syncEnabled)
    createLog("Sinkronisasi Otoritas diubah ke: " .. tostring(Variables.syncEnabled))
end)

-- Toggle Hide Name
local HideNameToggleBtn = Instance.new("TextButton")
HideNameToggleBtn.Size = UDim2.new(1, -10, 0, 25)
HideNameToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
HideNameToggleBtn.Text = "Hide Name Account"
HideNameToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HideNameToggleBtn.Font = Enum.Font.SourceSans
HideNameToggleBtn.TextSize = 12
HideNameToggleBtn.Parent = ContentFrame

HideNameToggleBtn.MouseButton1Click:Connect(function()
    Variables.hideNameEnabled = not Variables.hideNameEnabled
    updateToggleVisual(HideNameToggleBtn, Variables.hideNameEnabled)
    
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if Variables.hideNameEnabled then
        if humanoid then humanoid.DisplayName = " " end
        createLog("Nama lokal disembunyikan.")
    else
        if humanoid then humanoid.DisplayName = Variables.originalDisplayName end
        createLog("Nama lokal dimunculkan kembali.")
    end
end)

-- Log Box System
local LogFrame = Instance.new("ScrollingFrame")
LogFrame.Size = UDim2.new(1, -10, 0, 80)
LogFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
LogFrame.BorderSizePixel = 1
LogFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
LogFrame.Parent = ContentFrame

local LogListLayout = Instance.new("UIListLayout")
LogListLayout.Parent = LogFrame
_G.LogContainer = LogFrame

-- =============================================================================
-- WINDOW ACTIONS & FLOATING BUTTON
-- =============================================================================

-- Open Floating Button Creation
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "CarolOpenBtn"
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
OpenBtn.BorderSizePixel = 2
OpenBtn.BorderColor3 = Color3.fromRGB(255, 120, 0)
OpenBtn.Text = "OPEN"
OpenBtn.TextColor3 = Color3.fromRGB(255, 120, 0)
OpenBtn.Font = Enum.Font.SourceSansBold
OpenBtn.TextSize = 14
OpenBtn.Visible = false
OpenBtn.Active = true
OpenBtn.Draggable = true
OpenBtn.Parent = ScreenGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = OpenBtn

-- Minimize Logic
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    OpenBtn.Visible = false
    MainFrame.Visible = true
end)

-- Close Logic
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

createLog("Carol Script Co-Pilot Berhasil Diinjeksi!")
