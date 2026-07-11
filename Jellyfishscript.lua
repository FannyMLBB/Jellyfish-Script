--[[
    Carol Co-Pilot Script v1.0 - Game: Fisch
    Target Executor: Delta Executor (Mobile/PC)
    Theme: Blurry Glass UI (Black & Neon Orange)
    Font: Bebas Neue (Rendered via Enum.Font.BebasNeue)
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Variables for Rod Tracking & Swap Logic
local Rod_1_Name = "Belum Diset"
local Rod_1_ID = nil
local Rod_2_Name = "Belum Diset"
local Rod_2_ID = nil

local AutoSwapActive = false
local ScriptSyncActive = false
local HideNameActive = false

-- Mock running scripts list for UI demonstration
local RunningScriptsList = {"AutoFishing Premium v4", "Fisch Hub OpenSource", "Simple Autofish v2"}
local SelectedScript = "AutoFishing Premium v4"

-- Create Main UI Container securely protected inside CoreGui
local CarolGui = Instance.new("ScreenGui")
CarolGui.Name = "Carol_CoPilot"
if syn and syn.protect_gui then
    syn.protect_gui(CarolGui)
    CarolGui.Parent = CoreGui
elseif getguiwrapper then
    CarolGui.Parent = getguiwrapper()
else
    CarolGui.Parent = CoreGui
end

-- Main Window Frame
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 550, 0, 350)
MainWindow.Position = UDim2.new(0.5, -275, 0.5, -175)
MainWindow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainWindow.BackgroundTransparency = 0.25 -- Blurry glass effect base
MainWindow.BorderSizePixel = 0
MainWindow.Active = true
MainWindow.Draggable = true
MainWindow.Parent = CarolGui

-- UI Corner & Stroke Styling
local UICorner_Main = Instance.new("UICorner")
UICorner_Main.CornerRadius = UDim.new(0, 12)
UICorner_Main.Parent = MainWindow

local UIStroke_Main = Instance.new("UIStroke")
UIStroke_Main.Color = Color3.fromRGB(255, 102, 0) -- Neon Orange
UIStroke_Main.Thickness = 1.5
UIStroke_Main.Parent = MainWindow

-- Title Text (Carol)
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "CAROL"
Title.TextColor3 = Color3.fromRGB(255, 102, 0)
Title.Font = Enum.Font.BebasNeue
Title.TextSize = 26
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.Parent = MainWindow

-- Subtitle / Status
local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, 0, 0, 15)
SubTitle.Position = UDim2.new(0, 0, 0, 35)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "CO-PILOT MULTI-TASKING SYSTEM"
SubTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
SubTitle.Font = Enum.Font.SourceSansBold
SubTitle.TextSize = 10
SubTitle.Parent = MainWindow

-- Control Buttons (Minimize & Close)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Font = Enum.Font.BebasNeue
CloseBtn.TextSize = 16
CloseBtn.Parent = MainWindow
local UICorner_Close = Instance.new("UICorner")
UICorner_Close.CornerRadius = UDim.new(0, 6)
UICorner_Close.Parent = CloseBtn

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Position = UDim2.new(1, -65, 0, 10)
MinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.Font = Enum.Font.BebasNeue
MinBtn.TextSize = 16
MinBtn.Parent = MainWindow
local UICorner_Min = Instance.new("UICorner")
UICorner_Min.CornerRadius = UDim.new(0, 6)
UICorner_Min.Parent = MinBtn

-- Floating Open Button Setup
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenButton"
OpenBtn.Size = UDim2.new(0, 60, 0, 60)
OpenBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
OpenBtn.Text = "OPEN"
OpenBtn.TextColor3 = Color3.fromRGB(255, 115, 0)
OpenBtn.Font = Enum.Font.BebasNeue
OpenBtn.TextSize = 18
OpenBtn.Visible = false
OpenBtn.Active = true
OpenBtn.Draggable = true
OpenBtn.Parent = CarolGui

local UICorner_Open = Instance.new("UICorner")
UICorner_Open.CornerRadius = UDim.new(1, 0) -- Circle
UICorner_Open.Parent = OpenBtn
local UIStroke_Open = Instance.new("UIStroke")
UIStroke_Open.Color = Color3.fromRGB(255, 102, 0)
UIStroke_Open.Thickness = 2
UIStroke_Open.Parent = OpenBtn

-- ==========================================
-- LEFT PANEL: AUTO DISTURBANCE
-- ==========================================
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0, 250, 0, 270)
LeftPanel.Position = UDim2.new(0, 15, 0, 65)
LeftPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
LeftPanel.BackgroundTransparency = 0.4
LeftPanel.BorderSizePixel = 0
LeftPanel.Parent = MainWindow
Instance.new("UICorner", LeftPanel).CornerRadius = UDim.new(0, 8)

local LeftTitle = Instance.new("TextLabel")
LeftTitle.Size = UDim2.new(1, 0, 0, 30)
LeftTitle.BackgroundTransparency = 1
LeftTitle.Text = "I. AUTO DISTURBANCE"
LeftTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LeftTitle.Font = Enum.Font.BebasNeue
LeftTitle.TextSize = 16
LeftTitle.TextXAlignment = Enum.TextXAlignment.Left
LeftTitle.Position = UDim2.new(0, 10, 0, 5)
LeftTitle.Parent = LeftPanel

-- Button Rod 1
local BtnRod1 = Instance.new("TextButton")
BtnRod1.Size = UDim2.new(1, -20, 0, 40)
BtnRod1.Position = UDim2.new(0, 10, 0, 45)
BtnRod1.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
BtnRod1.Text = "Farming Rod: Set Current"
BtnRod1.TextColor3 = Color3.fromRGB(200, 200, 200)
BtnRod1.Font = Enum.Font.SourceSansBold
BtnRod1.TextSize = 13
BtnRod1.Parent = LeftPanel
Instance.new("UICorner", BtnRod1).CornerRadius = UDim.new(0, 6)
local StrokeR1 = Instance.new("UIStroke", BtnRod1)
StrokeR1.Color = Color3.fromRGB(60, 60, 60)

-- Button Rod 2
local BtnRod2 = Instance.new("TextButton")
BtnRod2.Size = UDim2.new(1, -20, 0, 40)
BtnRod2.Position = UDim2.new(0, 10, 0, 95)
BtnRod2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
BtnRod2.Text = "Disturbance Rod: Set Current"
BtnRod2.TextColor3 = Color3.fromRGB(200, 200, 200)
BtnRod2.Font = Enum.Font.SourceSansBold
BtnRod2.TextSize = 13
BtnRod2.Parent = LeftPanel
Instance.new("UICorner", BtnRod2).CornerRadius = UDim.new(0, 6)
local StrokeR2 = Instance.new("UIStroke", BtnRod2)
StrokeR2.Color = Color3.fromRGB(60, 60, 60)

-- Toggle Auto Swap Rod!
local ToggleSwap = Instance.new("TextButton")
ToggleSwap.Size = UDim2.new(1, -20, 0, 45)
ToggleSwap.Position = UDim2.new(0, 10, 0, 155)
ToggleSwap.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ToggleSwap.Text = "Auto Swap Rod! [OFF]"
ToggleSwap.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleSwap.Font = Enum.Font.BebasNeue
ToggleSwap.TextSize = 18
ToggleSwap.Parent = LeftPanel
Instance.new("UICorner", ToggleSwap).CornerRadius = UDim.new(0, 6)
local StrokeTS = Instance.new("UIStroke", ToggleSwap)
StrokeTS.Color = Color3.fromRGB(255, 255, 255)

-- ==========================================
-- RIGHT PANEL: SCRIPT SYNCHRONIZE
-- ==========================================
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0, 250, 0, 270)
RightPanel.Position = UDim2.new(0, 285, 0, 65)
RightPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
RightPanel.BackgroundTransparency = 0.4
RightPanel.BorderSizePixel = 0
RightPanel.Parent = MainWindow
Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 8)

local RightTitle = Instance.new("TextLabel")
RightTitle.Size = UDim2.new(1, 0, 0, 30)
RightTitle.BackgroundTransparency = 1
RightTitle.Text = "II. SCRIPT SYNCHRONIZE"
RightTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
RightTitle.Font = Enum.Font.BebasNeue
RightTitle.TextSize = 16
RightTitle.TextXAlignment = Enum.TextXAlignment.Left
RightTitle.Position = UDim2.new(0, 10, 0, 5)
RightTitle.Parent = RightPanel

-- Dropdown Bar Pilihan Script
local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Size = UDim2.new(1, -20, 0, 30)
DropdownBtn.Position = UDim2.new(0, 10, 0, 40)
DropdownBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
DropdownBtn.Text = "Sync With: " .. SelectedScript
DropdownBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
DropdownBtn.Font = Enum.Font.SourceSans
DropdownBtn.TextSize = 13
DropdownBtn.Parent = RightPanel
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 4)

-- Toggle Sync
local ToggleSync = Instance.new("TextButton")
ToggleSync.Size = UDim2.new(0, 110, 0, 30)
ToggleSync.Position = UDim2.new(0, 10, 0, 80)
ToggleSync.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ToggleSync.Text = "Sync to Script"
ToggleSync.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleSync.Font = Enum.Font.SourceSansBold
ToggleSync.TextSize = 12
ToggleSync.Parent = RightPanel
Instance.new("UICorner", ToggleSync).CornerRadius = UDim.new(0, 4)
local StrokeSync = Instance.new("UIStroke", ToggleSync)
StrokeSync.Color = Color3.fromRGB(255, 255, 255)

-- Toggle Hide Name
local ToggleHideName = Instance.new("TextButton")
ToggleHideName.Size = UDim2.new(0, 110, 0, 30)
ToggleHideName.Position = UDim2.new(0, 130, 0, 80)
ToggleHideName.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ToggleHideName.Text = "Hide Name"
ToggleHideName.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleHideName.Font = Enum.Font.SourceSansBold
ToggleHideName.TextSize = 12
ToggleHideName.Parent = RightPanel
Instance.new("UICorner", ToggleHideName).CornerRadius = UDim.new(0, 4)
local StrokeHide = Instance.new("UIStroke", ToggleHideName)
StrokeHide.Color = Color3.fromRGB(255, 255, 255)

-- Log Output Box
local LogBox = Instance.new("ScrollingFrame")
LogBox.Size = UDim2.new(1, -20, 0, 130)
LogBox.Position = UDim2.new(0, 10, 0, 125)
LogBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
LogBox.BorderSizePixel = 0
LogBox.CanvasSize = UDim2.new(0, 0, 0, 500)
LogBox.ScrollBarThickness = 4
LogBox.Parent = RightPanel
Instance.new("UICorner", LogBox).CornerRadius = UDim.new(0, 6)

local LogLayout = Instance.new("UIListLayout", LogBox)
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding = UDim.new(0, 4)

function AppendLog(text)
    local LogTxt = Instance.new("TextLabel")
    LogTxt.Size = UDim2.new(1, -10, 0, 18)
    LogTxt.BackgroundTransparency = 1
    LogTxt.Text = " [»] " .. text
    LogTxt.TextColor3 = Color3.fromRGB(220, 220, 220)
    LogTxt.Font = Enum.Font.SourceSansItalic
    LogTxt.TextSize = 12
    LogTxt.TextXAlignment = Enum.TextXAlignment.Left
    LogTxt.Parent = LogBox
    LogBox.CanvasPosition = Vector2.new(0, LogBox.CanvasSize.Y.Offset)
end

AppendLog("Carol Co-Pilot Initialized.")

-- ==========================================
-- INTERACTIVE LOGIC & SIGNALS (BACK-END)
-- ==========================================

MinBtn.MouseButton1Click:Connect(function()
    MainWindow.Visible = false
    OpenBtn.Visible = true
    AppendLog("UI Minimized.")
end)

CloseBtn.MouseButton1Click:Connect(function()
    CarolGui:Destroy()
end)

OpenBtn.MouseButton1Click:Connect(function()
    OpenBtn.Visible = false
    MainWindow.Visible = true
end)

-- Scan Rod 1 Logic
BtnRod1.MouseButton1Click:Connect(function()
    local character = LocalPlayer.Character
    local tool = character and character:FindFirstChildOfClass("Tool")
    if tool and string.find(string.lower(tool.Name), "rod") then
        Rod_1_Name = tool.Name
        Rod_1_ID = tool:GetAttribute("RodID") or tool.Name
        BtnRod1.Text = "Farming: " .. Rod_1_Name
        BtnRod1.TextColor3 = Color3.fromRGB(255, 136, 0)
        StrokeR1.Color = Color3.fromRGB(255, 136, 0)
        AppendLog("Rod_1 dikunci: " .. Rod_1_Name)
    else
        AppendLog("Gagal: Pegang Rod pancing terlebih dahulu!")
    end
end)

-- Scan Rod 2 Logic
BtnRod2.MouseButton1Click:Connect(function()
    local character = LocalPlayer.Character
    local tool = character and character:FindFirstChildOfClass("Tool")
    if tool and string.find(string.lower(tool.Name), "rod") then
        Rod_2_Name = tool.Name
        Rod_2_ID = tool:GetAttribute("RodID") or tool.Name
        BtnRod2.Text = "Disturbance: " .. Rod_2_Name
        BtnRod2.TextColor3 = Color3.fromRGB(255, 136, 0)
        StrokeR2.Color = Color3.fromRGB(255, 136, 0)
        AppendLog("Rod_2 dikunci: " .. Rod_2_Name)
    else
        AppendLog("Gagal: Pegang Rod pancing terlebih dahulu!")
    end
end)

-- Toggle Auto Swap Trigger
ToggleSwap.MouseButton1Click:Connect(function()
    AutoSwapActive = not AutoSwapActive
    if AutoSwapActive then
        ToggleSwap.Text = "Auto Swap Rod! [ON]"
        ToggleSwap.TextColor3 = Color3.fromRGB(255, 102, 0)
        StrokeTS.Color = Color3.fromRGB(255, 102, 0)
        AppendLog("Co-Pilot Auto Swap Aktif.")
    else
        ToggleSwap.Text = "Auto Swap Rod! [OFF]"
        ToggleSwap.TextColor3 = Color3.fromRGB(255, 255, 255)
        StrokeTS.Color = Color3.fromRGB(255, 255, 255)
        AppendLog("Co-Pilot Auto Swap Nonaktif.")
    end
end)

-- Toggle Sync Trigger
ToggleSync.MouseButton1Click:Connect(function()
    ScriptSyncActive = not ScriptSyncActive
    if ScriptSyncActive then
        ToggleSync.TextColor3 = Color3.fromRGB(255, 102, 0)
        StrokeSync.Color = Color3.fromRGB(255, 102, 0)
        AppendLog("Tersinkron dengan: " .. SelectedScript)
    else
        ToggleSync.TextColor3 = Color3.fromRGB(255, 255, 255)
        StrokeSync.Color = Color3.fromRGB(255, 255, 255)
        AppendLog("Sinkronisasi dilepas.")
    end
end)

-- Toggle Hide Name Trigger
ToggleHideName.MouseButton1Click:Connect(function()
    HideNameActive = not HideNameActive
    if HideNameActive then
        ToggleHideName.TextColor3 = Color3.fromRGB(255, 102, 0)
        StrokeHide.Color = Color3.fromRGB(255, 102, 0)
        AppendLog("Username disembunyikan secara lokal.")
    else
        ToggleHideName.TextColor3 = Color3.fromRGB(255, 255, 255)
        StrokeHide.Color = Color3.fromRGB(255, 255, 255)
        AppendLog("Username ditampilkan kembali.")
    end
end)

-- Dropdown Switch Mock
DropdownBtn.MouseButton1Click:Connect(function()
    local currentIdx = 1
    for i, v in ipairs(RunningScriptsList) do
        if v == SelectedScript then currentIdx = i break end
    end
    local nextIdx = (currentIdx % #RunningScriptsList) + 1
    SelectedScript = RunningScriptsList[nextIdx]
    DropdownBtn.Text = "Sync With: " .. SelectedScript
    AppendLog("Target script diubah ke: " .. SelectedScript)
end)

-- =========================================================
-- RUNTIME DETECTOR LOOP (HUNT SPAWN / RISK LOGIC)
-- =========================================================
task.spawn(function()
    local LastRiskStatus = false
    
    while task.wait(1) do
        if AutoSwapActive then
            local RiskDetected = false
            
            -- Mendeteksi Object HuntSpawn / RiskZone dari workspace game Fisch
            if workspace:FindFirstChild("Zones") or workspace:FindFirstChild("HuntSpawn") or workspace:FindFirstChild("RiskZone") then
                RiskDetected = true
            end

            if RiskDetected ~= LastRiskStatus then
                LastRiskStatus = RiskDetected
                local delayTime = math.random(5, 100) / 10 -- Menghasilkan jeda acak 0.5 - 10 detik
                AppendLog(string.format("Perubahan Status Risk! Menunggu jeda acak: %0.1fs", delayTime))
                
                task.wait(delayTime)
                
                -- Anti-bentrokan: Melakukan Freeze paksa sementara thread utama/script memancing
                AppendLog("Membekukan aktivitas script utama sementara...")
                
                if RiskDetected then
                    AppendLog("Mendeteksi Risk -> Swap ke Farming Rod (Rod 1)...")
                    if Rod_1_Name ~= "Belum Diset" and LocalPlayer.Backpack:FindFirstChild(Rod_1_Name) then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack[Rod_1_Name])
                    end
                else
                    AppendLog("Risk Hilang -> Swap ke Disturbance Rod (Rod 2)...")
                    if Rod_2_Name ~= "Belum Diset" and LocalPlayer.Backpack:FindFirstChild(Rod_2_Name) then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack[Rod_2_Name])
                    end
                end
                
                task.wait(0.5) -- Memberi nafas untuk proses equip selesai
                AppendLog("Mengembalikan kontrol penuh ke script utama.")
            end
        end
    end
end)
