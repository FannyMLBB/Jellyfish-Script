-- Carol Co-Pilot Working Tool
local Carol = {}
Carol.enabled = false
Carol.minimized = false
Carol.rods = {rod_1 = nil, rod_2 = nil}
Carol.activeRod = "rod_1"
Carol.syncTarget = nil

-- UI Components
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CarolUI"
screenGui.ResetOnSpawn = false

-- Main Window
local window = Instance.new("Frame")
window.Size = UDim2.new(0.2, 0, 0.3, 0) -- 1/5 screen size
window.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
window.BackgroundTransparency = 0.6
window.BorderSizePixel = 0
window.Position = UDim2.new(0.5, -window.AbsoluteSize.X/2, 0.5, -window.AbsoluteSize.Y/2)

-- Header
local header = Instance.new("TextLabel")
header.Text = "Carol"
header.Font = Enum.Font.BebasNeue
header.TextSize = 30
header.TextColor3 = Color3.fromRGB(255, 255, 255)
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, 0, 0.2, 0)
header.Position = UDim2.new(0, 0, 0, 0)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.BebasNeue
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.BackgroundTransparency = 0.5
closeBtn.BorderSizePixel = 0
closeBtn.Size = UDim2.new(0.1, 0, 0.1, 0)
closeBtn.Position = UDim2.new(0.9, -closeBtn.AbsoluteSize.X, 0, 0)
closeBtn.MouseButton1Click:Connect(function()
    Carol.enabled = false
    screenGui.Parent = nil
end)

-- Minimize Button
local minBtn = Instance.new("TextButton")
minBtn.Text = "-"
minBtn.Font = Enum.Font.BebasNeue
minBtn.TextSize = 20
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
minBtn.BackgroundTransparency = 0.5
minBtn.BorderSizePixel = 0
minBtn.Size = UDim2.new(0.1, 0, 0.1, 0)
minBtn.Position = UDim2.new(0.8, -minBtn.AbsoluteSize.X, 0, 0)
minBtn.MouseButton1Click:Connect(function()
    Carol.minimized = true
    window.Visible = false
    if not Carol.minBtn then
        Carol.minBtn = Instance.new("TextButton")
        Carol.minBtn.Text = "OPEN"
        Carol.minBtn.Font = Enum.Font.BebasNeue
        Carol.minBtn.TextSize = 16
        Carol.minBtn.TextColor3 = Color3.fromRGB(255, 100, 0)
        Carol.minBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Carol.minBtn.BackgroundTransparency = 0.7
        Carol.minBtn.BorderSizePixel = 0
        Carol.minBtn.Size = UDim2.new(0.2, 0, 0.2, 0)
        Carol.minBtn.Position = UDim2.new(0.8, -Carol.minBtn.AbsoluteSize.X, 0.8, -Carol.minBtn.AbsoluteSize.Y)
        Carol.minBtn.Parent = screenGui
        Carol.minBtn.MouseButton1Click:Connect(function()
            Carol.minimized = false
            window.Visible = true
            Carol.minBtn.Parent = nil
            Carol.minBtn = nil
        end)
    end
end)

-- Auto Disturbance Section
local autoDisturbance = Instance.new("Frame")
autoDisturbance.Size = UDim2.new(0.5, 0, 0.7, 0)
autoDisturbance.Position = UDim2.new(0, 0, 0.2, 0)
autoDisturbance.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
autoDisturbance.BackgroundTransparency = 0.8

local scanFarmingBtn = Instance.new("TextButton")
scanFarmingBtn.Text = "Scan Farming Rod"
scanFarmingBtn.Font = Enum.Font.BebasNeue
scanFarmingBtn.TextSize = 16
scanFarmingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanFarmingBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
scanFarmingBtn.BackgroundTransparency = 0.7
scanFarmingBtn.BorderSizePixel = 0
scanFarmingBtn.Size = UDim2.new(1, 0, 0.2, 0)
scanFarmingBtn.Position = UDim2.new(0, 0, 0, 0)
scanFarmingBtn.MouseButton1Click:Connect(function()
    Carol.scanRod("rod_1")
end)

local scanDisturbanceBtn = Instance.new("TextButton")
scanDisturbanceBtn.Text = "Scan Disturbance Rod"
scanDisturbanceBtn.Font = Enum.Font.BebasNeue
scanDisturbanceBtn.TextSize = 16
scanDisturbanceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanDisturbanceBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
scanDisturbanceBtn.BackgroundTransparency = 0.7
scanDisturbanceBtn.BorderSizePixel = 0
scanDisturbanceBtn.Size = UDim2.new(1, 0, 0.2, 0)
scanDisturbanceBtn.Position = UDim2.new(0, 0, 0.25, 0)
scanDisturbanceBtn.MouseButton1Click:Connect(function()
    Carol.scanRod("rod_2")
end)

local toggleAutoSwap = Instance.new("TextButton")
toggleAutoSwap.Text = "Active Auto Swap Rod!"
toggleAutoSwap.Font = Enum.Font.BebasNeue
toggleAutoSwap.TextSize = 16
toggleAutoSwap.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleAutoSwap.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
toggleAutoSwap.BackgroundTransparency = 0.7
toggleAutoSwap.BorderSizePixel = 0
toggleAutoSwap.Size = UDim2.new(1, 0, 0.2, 0)
toggleAutoSwap.Position = UDim2.new(0, 0, 0.5, 0)
toggleAutoSwap.MouseButton1Click:Connect(function()
    Carol.enabled = not Carol.enabled
    toggleAutoSwap.TextColor3 = Carol.enabled and Color3.fromRGB(255, 100, 0) or Color3.fromRGB(255, 255, 255)
end)

-- Script Synchronize Section
local scriptSync = Instance.new("Frame")
scriptSync.Size = UDim2.new(0.5, 0, 0.7, 0)
scriptSync.Position = UDim2.new(0.5, 0, 0.2, 0)
scriptSync.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scriptSync.BackgroundTransparency = 0.8

local scriptSelector = Instance.new("TextButton")
scriptSelector.Text = "Select Running Script"
scriptSelector.Font = Enum.Font.BebasNeue
scriptSelector.TextSize = 16
scriptSelector.TextColor3 = Color3.fromRGB(255, 255, 255)
scriptSelector.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
scriptSelector.BackgroundTransparency = 0.7
scriptSelector.BorderSizePixel = 0
scriptSelector.Size = UDim2.new(1, 0, 0.2, 0)
scriptSelector.Position = UDim2.new(0, 0, 0, 0)

local syncToggle = Instance.new("TextButton")
syncToggle.Text = "Sync to Script"
syncToggle.Font = Enum.Font.BebasNeue
syncToggle.TextSize = 16
syncToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
syncToggle.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
syncToggle.BackgroundTransparency = 0.7
syncToggle.BorderSizePixel = 0
syncToggle.Size = UDim2.new(1, 0, 0.2, 0)
syncToggle.Position = UDim2.new(0, 0, 0.25, 0)

local hideNameToggle = Instance.new("TextButton")
hideNameToggle.Text = "Hide Name"
hideNameToggle.Font = Enum.Font.BebasNeue
hideNameToggle.TextSize = 16
hideNameToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
hideNameToggle.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
hideNameToggle.BackgroundTransparency = 0.7
hideNameToggle.BorderSizePixel = 0
hideNameToggle.Size = UDim2.new(1, 0, 0.2, 0)
hideNameToggle.Position = UDim2.new(0, 0, 0.5, 0)

-- Log Window
local logBox = Instance.new("ScrollingFrame")
logBox.Size = UDim2.new(1, 0, 0.3, 0)
logBox.Position = UDim2.new(0, 0, 0.7, 0)
logBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
logBox.BackgroundTransparency = 0.8
logBox.BorderSizePixel = 0

local logLabel = Instance.new("TextLabel")
logLabel.Text = ""
logLabel.Font = Enum.Font.SourceSans
logLabel.TextSize = 14
logLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
logLabel.BackgroundTransparency = 1
logLabel.Size = UDim2.new(1, 0, 1, 0)
logLabel.Position = UDim2.new(0, 0, 0, 0)
logBox.CanvasSize = UDim2.new(0, 0, 0, 0)
logBox.ChildAdded:Connect(function(child)
    child.TextWrapped = true
    child.TextScaled = true
    logBox.CanvasSize = UDim2.new(0, 0, 0, logBox.CanvasSize.Y.Offset + child.TextBounds.Y)
end)

-- Event Connections
local eventConnections = {}

-- Core Functions
function Carol:log(message)
    logLabel.Text = logLabel.Text .. message .. "\n"
    logBox.CanvasPosition = Vector2.new(0, logBox.CanvasSize.Y.Offset)
end

function Carol:scanRod(rodId)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local tool = character:FindFirstChild("Tool") or character:FindFirstChild("tool")
    if tool then
        Carol.rods[rodId] = {
            name = tool.Name,
            id = tool:GetAttribute("ID")
        }
        Carol:log(string.format("[LOG] %s rod set to %s | ID %d", rodId, tool.Name, tool:GetAttribute("ID")))
    else
        Carol:log("[ERROR] No tool found!")
    end
end

function Carol:freezeScript(script, freeze)
    if script then
        if freeze then
            script.Enabled = false
        else
            script.Enabled = true
        end
    end
end

function Carol:equipRod(rodId)
    if Carol.rods[rodId] then
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local tool = character:FindFirstChild(Carol.rods[rodId].name)
        if tool then
            Carol:log(string.format("[LOG] Equipped %s", Carol.rods[rodId].name))
            -- Equip logic would go here
        end
    end
end

function Carol:start()
    Carol:log("[START] Carol Co-Pilot started")
    Carol.enabled = true
    
    -- Setup event detection
    local huntSpawnConnection = workspace.ChildAdded:Connect(function(child)
        if child.Name == "Hunt Spawn" then
            Carol:log("[LOG] Hunt Spawn detected - Freezing script")
            Carol:freezeScript(Carol.syncTarget, true)
            wait(math.random(0.5, 10))
            Carol:equipRod("rod_1")
            Carol:freezeScript(Carol.syncTarget, false)
            Carol:log("[LOG] Hunt Spawn resolved - Resumed script")
        elseif child.Name == "Risk" then
            Carol:log("[LOG] Risk detected - Freezing script")
            Carol:freezeScript(Carol.syncTarget, true)
            wait(math.random(0.5, 10))
            Carol:equipRod("rod_2")
            Carol:freezeScript(Carol.syncTarget, false)
            Carol:log("[LOG] Risk resolved - Resumed script")
        end
    end)
    
    table.insert(eventConnections, huntSpawnConnection)
end

function Carol:stop()
    Carol:log("[STOP] Carol Co-Pilot stopped")
    Carol.enabled = false
    
    -- Cleanup event connections
    for _, conn in ipairs(eventConnections) do
        conn:Disconnect()
    end
    eventConnections = {}
end

-- Initialize UI
function Carol:init()
    window.Parent = screenGui
    header.Parent = window
    closeBtn.Parent = window
    minBtn.Parent = window
    autoDisturbance.Parent = window
    scriptSync.Parent = window
    logBox.Parent = window
    
    scanFarmingBtn.Parent = autoDisturbance
    scanDisturbanceBtn.Parent = autoDisturbance
    toggleAutoSwap.Parent = autoDisturbance
    
    scriptSelector.Parent = scriptSync
    syncToggle.Parent = scriptSync
    hideNameToggle.Parent = scriptSync
    
    logBox.CanvasSize = UDim2.new(0, 0, 0, 0)
    logLabel.Parent = logBox
    
    -- Detect running scripts
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("ModuleScript") and obj ~= Carol then
            local scriptObj = Instance.new("TextButton")
            scriptObj.Text = obj.Name
            scriptObj.Font = Enum.Font.SourceSans
            scriptObj.TextSize = 14
            scriptObj.TextColor3 = Color3.fromRGB(255, 255, 255)
            scriptObj.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
            scriptObj.BackgroundTransparency = 0.7
            scriptObj.BorderSizePixel = 0
            scriptObj.Size = UDim2.new(1, 0, 0.1, 0)
            scriptObj.Position = UDim2.new(0, 0, #scriptSync:GetChildren() * 0.1, 0)
            scriptObj.Parent = scriptSync
            scriptObj.MouseButton1Click:Connect(function()
                Carol.syncTarget = obj
                Carol:log(string.format("[LOG] Targeted script: %s", obj.Name))
            end)
        end
    end
    
    -- Start monitoring
    Carol:start()
end

-- Start the tool
Carol:init()
