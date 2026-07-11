--[[
========================================
CAROL - CO-PILOT WORKING TOOL v1.0
Delta Environment | Lua Execution
Modular Automation Dashboard
========================================
]]

-- ==========================================
-- CORE INITIALIZATION & CONFIGURATION
-- ==========================================

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local screenSize = player:FindFirstChild("PlayerGui") and player.PlayerGui.AbsoluteSize or Vector2.new(1920, 1080)

-- UI Scaling for Mobile (1/5 of screen size)
local WINDOW_WIDTH = math.floor(screenSize.X / 5)
local WINDOW_HEIGHT = math.floor(screenSize.Y / 5)

-- Color Palette
local COLOR_PITCH_BLACK = Color3.fromRGB(0, 0, 0)
local COLOR_NEON_ORANGE = Color3.fromRGB(255, 100, 0)
local COLOR_WHITE = Color3.fromRGB(255, 255, 255)
local COLOR_DARK_TRANSLUCENT = Color3.fromRGB(20, 20, 20)

-- State Management
local state = {
	rod_1 = nil,
	rod_1_id = nil,
	rod_2 = nil,
	rod_2_id = nil,
	auto_swap_active = false,
	sync_to_script_active = false,
	hide_name_active = false,
	selected_script = nil,
	window_minimized = false,
	log_buffer = {},
	max_log_entries = 100,
	event_connections = {},
	hunt_spawn_detected = false,
	risk_detected = false,
	is_swapping = false,
}

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================

local function log_event(message)
	table.insert(state.log_buffer, "[LOG] " .. message)
	if #state.log_buffer > state.max_log_entries then
		table.remove(state.log_buffer, 1)
	end
	print("[CAROL] " .. message)
end

local function disconnect_all_events()
	for _, connection in ipairs(state.event_connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	state.event_connections = {}
end

local function get_tool_id(tool_instance)
	if not tool_instance then return nil end
	return tool_instance.Name
end

local function scan_current_tool()
	if not player or not player.Character then
		log_event("Character not found!")
		return nil, nil
	end
	
	local tool = player.Character:FindFirstChildOfClass("Tool")
	if tool then
		local tool_name = tool.Name
		local tool_id = get_tool_id(tool)
		return tool_name, tool_id
	end
	
	log_event("No tool equipped!")
	return nil, nil
end

local function equip_rod(rod_name)
	if not rod_name or not player or not player.Character then
		log_event("Cannot equip rod: Invalid parameters")
		return false
	end
	
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		log_event("Backpack not found!")
		return false
	end
	
	local rod = backpack:FindFirstChild(rod_name)
	if rod then
		rod.Parent = player.Character
		log_event("Equipped: " .. rod_name)
		return true
	else
		log_event("Rod not found in backpack: " .. rod_name)
		return false
	end
end

local function pause_script(script_ref)
	if script_ref and script_ref:IsA("LocalScript") or script_ref:IsA("Script") then
		pcall(function()
			script_ref.Disabled = true
		end)
		return true
	end
	return false
end

local function resume_script(script_ref)
	if script_ref and script_ref:IsA("LocalScript") or script_ref:IsA("Script") then
		pcall(function()
			script_ref.Disabled = false
		end)
		return true
	end
	return false
end

local function detect_scripts_in_workspace()
	local scripts = {}
	local function scan(parent)
		for _, child in ipairs(parent:GetChildren()) do
			if (child:IsA("LocalScript") or child:IsA("Script")) and child ~= script then
				table.insert(scripts, child)
			end
			scan(child)
		end
	end
	scan(workspace)
	return scripts
end

local function hide_player_name(should_hide)
	if not player then return end
	
	pcall(function()
		if should_hide then
			player.Name = "░░░░░░"
			player.DisplayName = "░░░░░░"
			log_event("Player name hidden")
		else
			player.DisplayName = player.UserId .. ""
			log_event("Player name revealed")
		end
	end)
end

-- ==========================================
-- CORE AUTO-SWAP LOGIC (CONCURRENT)
-- ==========================================

local function execute_rod_swap(target_rod, target_rod_id)
	if state.is_swapping or not state.auto_swap_active then return end
	
	state.is_swapping = true
	
	-- Pause primary script
	if state.selected_script and state.sync_to_script_active then
		pause_script(state.selected_script)
		log_event("Primary script PAUSED")
	end
	
	-- Random latency before action
	wait(math.random(5, 100) / 10)
	
	-- Equip rod
	equip_rod(target_rod)
	
	-- Resume primary script
	if state.selected_script and state.sync_to_script_active then
		resume_script(state.selected_script)
		log_event("Primary script RESUMED")
	end
	
	state.is_swapping = false
end

local function monitor_hunt_and_risk_events()
	local heartbeat_connection
	
	local function check_events()
		-- Simulate event detection in workspace/GUI
		-- (This is where you'd implement actual Hunt Spawn/Risk detection logic)
		
		local hunt_spawn = workspace:FindFirstChild("HuntSpawn") or CoreGui:FindFirstChild("HuntSpawn")
		local risk_event = workspace:FindFirstChild("Risk") or CoreGui:FindFirstChild("Risk")
		
		-- Hunt Spawn detected
		if hunt_spawn and not state.hunt_spawn_detected then
			state.hunt_spawn_detected = true
			log_event("Hunt Spawn DETECTED - Swapping to Rod_1")
			execute_rod_swap(state.rod_1, state.rod_1_id)
		elseif not hunt_spawn and state.hunt_spawn_detected then
			state.hunt_spawn_detected = false
			wait(math.random(5, 100) / 10)
			log_event("Hunt Spawn CLEARED - Swapping to Rod_2")
			execute_rod_swap(state.rod_2, state.rod_2_id)
		end
		
		-- Risk event detected
		if risk_event and not state.risk_detected then
			state.risk_detected = true
			log_event("Risk DETECTED - Swapping to Rod_1")
			execute_rod_swap(state.rod_1, state.rod_1_id)
		elseif not risk_event and state.risk_detected then
			state.risk_detected = false
			wait(math.random(5, 100) / 10)
			log_event("Risk CLEARED - Swapping to Rod_2")
			execute_rod_swap(state.rod_2, state.rod_2_id)
		end
	end
	
	if state.auto_swap_active then
		if not heartbeat_connection then
			heartbeat_connection = RunService.Heartbeat:Connect(function()
				if state.auto_swap_active then
					local success = pcall(check_events)
					if not success then
						log_event("Event monitoring error")
					end
				end
			end)
			table.insert(state.event_connections, heartbeat_connection)
		end
	else
		disconnect_all_events()
	end
end

-- ==========================================
-- UI CREATION (BLURRY GLASS THEME)
-- ==========================================

local function create_ui()
	-- Main Screen GUI
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "CarolUI"
	screen_gui.ResetOnSpawn = false
	screen_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen_gui.Parent = player:FindFirstChild("PlayerGui") or CoreGui
	
	-- Background Frame (Blurry Glass Effect)
	local main_frame = Instance.new("Frame")
	main_frame.Name = "MainFrame"
	main_frame.Size = UDim2.new(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT)
	main_frame.Position = UDim2.new(0.02, 0, 0.02, 0)
	main_frame.BackgroundColor3 = COLOR_DARK_TRANSLUCENT
	main_frame.BackgroundTransparency = 0.3
	main_frame.BorderSizePixel = 2
	main_frame.BorderColor3 = COLOR_NEON_ORANGE
	main_frame.Parent = screen_gui
	
	-- Add UICorner for rounded edges
	local ui_corner = Instance.new("UICorner")
	ui_corner.CornerRadius = UDim.new(0, 8)
	ui_corner.Parent = main_frame
	
	-- Header Bar
	local header_frame = Instance.new("Frame")
	header_frame.Name = "HeaderFrame"
	header_frame.Size = UDim2.new(1, 0, 0, WINDOW_HEIGHT * 0.15)
	header_frame.Position = UDim2.new(0, 0, 0, 0)
	header_frame.BackgroundColor3 = COLOR_PITCH_BLACK
	header_frame.BackgroundTransparency = 0.5
	header_frame.BorderSizePixel = 0
	header_frame.Parent = main_frame
	
	-- Header Title "Carol"
	local header_title = Instance.new("TextLabel")
	header_title.Name = "HeaderTitle"
	header_title.Size = UDim2.new(0.6, 0, 1, 0)
	header_title.Position = UDim2.new(0.2, 0, 0, 0)
	header_title.BackgroundTransparency = 1
	header_title.Text = "CAROL"
	header_title.TextColor3 = COLOR_NEON_ORANGE
	header_title.TextSize = 18
	header_title.Font = Enum.Font.BebasNeue
	header_title.Parent = header_frame
	
	-- Minimize Button
	local minimize_btn = Instance.new("TextButton")
	minimize_btn.Name = "MinimizeBtn"
	minimize_btn.Size = UDim2.new(0, 30, 0, 30)
	minimize_btn.Position = UDim2.new(1, -70, 0, 5)
	minimize_btn.BackgroundColor3 = COLOR_NEON_ORANGE
	minimize_btn.BackgroundTransparency = 0.6
	minimize_btn.Text = "-"
	minimize_btn.TextColor3 = COLOR_WHITE
	minimize_btn.TextSize = 16
	minimize_btn.Font = Enum.Font.BebasNeue
	minimize_btn.BorderSizePixel = 0
	minimize_btn.Parent = header_frame
	
	-- Close Button
	local close_btn = Instance.new("TextButton")
	close_btn.Name = "CloseBtn"
	close_btn.Size = UDim2.new(0, 30, 0, 30)
	close_btn.Position = UDim2.new(1, -35, 0, 5)
	close_btn.BackgroundColor3 = COLOR_NEON_ORANGE
	close_btn.BackgroundTransparency = 0.6
	close_btn.Text = "X"
	close_btn.TextColor3 = COLOR_WHITE
	close_btn.TextSize = 16
	close_btn.Font = Enum.Font.BebasNeue
	close_btn.BorderSizePixel = 0
	close_btn.Parent = header_frame
	
	-- Content Area
	local content_frame = Instance.new("Frame")
	content_frame.Name = "ContentFrame"
	content_frame.Size = UDim2.new(1, 0, 1, -WINDOW_HEIGHT * 0.15)
	content_frame.Position = UDim2.new(0, 0, 0, WINDOW_HEIGHT * 0.15)
	content_frame.BackgroundTransparency = 1
	content_frame.BorderSizePixel = 0
	content_frame.Parent = main_frame
	
	-- ==========================================
	-- LEFT PANEL: AUTO DISTURBANCE
	-- ==========================================
	
	local left_panel = Instance.new("Frame")
	left_panel.Name = "LeftPanel"
	left_panel.Size = UDim2.new(0.5, -2, 1, 0)
	left_panel.Position = UDim2.new(0, 0, 0, 0)
	left_panel.BackgroundTransparency = 1
	left_panel.BorderSizePixel = 0
	left_panel.Parent = content_frame
	
	-- Left Panel Title
	local left_title = Instance.new("TextLabel")
	left_title.Name = "LeftTitle"
	left_title.Size = UDim2.new(1, 0, 0, 20)
	left_title.Position = UDim2.new(0, 5, 0, 5)
	left_title.BackgroundTransparency = 1
	left_title.Text = "Auto Disturbance"
	left_title.TextColor3 = COLOR_NEON_ORANGE
	left_title.TextSize = 12
	left_title.Font = Enum.Font.BebasNeue
	left_title.TextXAlignment = Enum.TextXAlignment.Left
	left_title.Parent = left_panel
	
	-- Scan Rod_1 Button
	local scan_rod1_btn = Instance.new("TextButton")
	scan_rod1_btn.Name = "ScanRod1Btn"
	scan_rod1_btn.Size = UDim2.new(0.3, 0, 0, 25)
	scan_rod1_btn.Position = UDim2.new(0, 5, 0, 30)
	scan_rod1_btn.BackgroundColor3 = COLOR_NEON_ORANGE
	scan_rod1_btn.BackgroundTransparency = 0.7
	scan_rod1_btn.Text = "[Scan]"
	scan_rod1_btn.TextColor3 = COLOR_WHITE
	scan_rod1_btn.TextSize = 10
	scan_rod1_btn.Font = Enum.Font.BebasNeue
	scan_rod1_btn.BorderSizePixel = 1
	scan_rod1_btn.BorderColor3 = COLOR_NEON_ORANGE
	scan_rod1_btn.Parent = left_panel
	
	-- Rod_1 Display TextBox
	local rod1_textbox = Instance.new("TextBox")
	rod1_textbox.Name = "Rod1TextBox"
	rod1_textbox.Size = UDim2.new(0.65, 0, 0, 25)
	rod1_textbox.Position = UDim2.new(0.35, 0, 0, 30)
	rod1_textbox.BackgroundColor3 = COLOR_PITCH_BLACK
	rod1_textbox.BackgroundTransparency = 0.5
	rod1_textbox.Text = "Name of Rod_1 | ID"
	rod1_textbox.TextColor3 = COLOR_WHITE
	rod1_textbox.TextSize = 9
	rod1_textbox.Font = Enum.Font.BebasNeue
	rod1_textbox.TextEditable = false
	rod1_textbox.BorderSizePixel = 1
	rod1_textbox.BorderColor3 = COLOR_NEON_ORANGE
	rod1_textbox.Parent = left_panel
	
	-- Scan Rod_2 Button
	local scan_rod2_btn = Instance.new("TextButton")
	scan_rod2_btn.Name = "ScanRod2Btn"
	scan_rod2_btn.Size = UDim2.new(0.3, 0, 0, 25)
	scan_rod2_btn.Position = UDim2.new(0, 5, 0, 65)
	scan_rod2_btn.BackgroundColor3 = COLOR_NEON_ORANGE
	scan_rod2_btn.BackgroundTransparency = 0.7
	scan_rod2_btn.Text = "[Scan]"
	scan_rod2_btn.TextColor3 = COLOR_WHITE
	scan_rod2_btn.TextSize = 10
	scan_rod2_btn.Font = Enum.Font.BebasNeue
	scan_rod2_btn.BorderSizePixel = 1
	scan_rod2_btn.BorderColor3 = COLOR_NEON_ORANGE
	scan_rod2_btn.Parent = left_panel
	
	-- Rod_2 Display TextBox
	local rod2_textbox = Instance.new("TextBox")
	rod2_textbox.Name = "Rod2TextBox"
	rod2_textbox.Size = UDim2.new(0.65, 0, 0, 25)
	rod2_textbox.Position = UDim2.new(0.35, 0, 0, 65)
	rod2_textbox.BackgroundColor3 = COLOR_PITCH_BLACK
	rod2_textbox.BackgroundTransparency = 0.5
	rod2_textbox.Text = "Name of Rod_2 | ID"
	rod2_textbox.TextColor3 = COLOR_WHITE
	rod2_textbox.TextSize = 9
	rod2_textbox.Font = Enum.Font.BebasNeue
	rod2_textbox.TextEditable = false
	rod2_textbox.BorderSizePixel = 1
	rod2_textbox.BorderColor3 = COLOR_NEON_ORANGE
	rod2_textbox.Parent = left_panel
	
	-- Auto Swap Toggle Label
	local auto_swap_label = Instance.new("TextLabel")
	auto_swap_label.Name = "AutoSwapLabel"
	auto_swap_label.Size = UDim2.new(0.7, 0, 0, 20)
	auto_swap_label.Position = UDim2.new(0, 5, 0, 100)
	auto_swap_label.BackgroundTransparency = 1
	auto_swap_label.Text = "(Toggle) Active Auto Swap"
	auto_swap_label.TextColor3 = COLOR_WHITE
	auto_swap_label.TextSize = 9
	auto_swap_label.Font = Enum.Font.BebasNeue
	auto_swap_label.TextXAlignment = Enum.TextXAlignment.Left
	auto_swap_label.Parent = left_panel
	
	-- Auto Swap Toggle Button
	local auto_swap_toggle = Instance.new("TextButton")
	auto_swap_toggle.Name = "AutoSwapToggle"
	auto_swap_toggle.Size = UDim2.new(0.2, 0, 0, 20)
	auto_swap_toggle.Position = UDim2.new(0.75, 0, 0, 100)
	auto_swap_toggle.BackgroundColor3 = COLOR_WHITE
	auto_swap_toggle.BackgroundTransparency = 0.6
	auto_swap_toggle.Text = "OFF"
	auto_swap_toggle.TextColor3 = COLOR_PITCH_BLACK
	auto_swap_toggle.TextSize = 9
	auto_swap_toggle.Font = Enum.Font.BebasNeue
	auto_swap_toggle.BorderSizePixel = 1
	auto_swap_toggle.BorderColor3 = COLOR_WHITE
	auto_swap_toggle.Parent = left_panel
	
	-- ==========================================
	-- RIGHT PANEL: SCRIPT SYNCHRONIZE
	-- ==========================================
	
	local right_panel = Instance.new("Frame")
	right_panel.Name = "RightPanel"
	right_panel.Size = UDim2.new(0.5, -2, 1, 0)
	right_panel.Position = UDim2.new(0.5, 2, 0, 0)
	right_panel.BackgroundTransparency = 1
	right_panel.BorderSizePixel = 0
	right_panel.Parent = content_frame
	
	-- Right Panel Title
	local right_title = Instance.new("TextLabel")
	right_title.Name = "RightTitle"
	right_title.Size = UDim2.new(1, 0, 0, 20)
	right_title.Position = UDim2.new(0, 5, 0, 5)
	right_title.BackgroundTransparency = 1
	right_title.Text = "Script Synchronize"
	right_title.TextColor3 = COLOR_NEON_ORANGE
	right_title.TextSize = 12
	right_title.Font = Enum.Font.BebasNeue
	right_title.TextXAlignment = Enum.TextXAlignment.Left
	right_title.Parent = right_panel
	
	-- Script Dropdown
	local script_dropdown = Instance.new("TextButton")
	script_dropdown.Name = "ScriptDropdown"
	script_dropdown.Size = UDim2.new(1, -10, 0, 25)
	script_dropdown.Position = UDim2.new(0, 5, 0, 30)
	script_dropdown.BackgroundColor3 = COLOR_PITCH_BLACK
	script_dropdown.BackgroundTransparency = 0.5
	script_dropdown.Text = "Running Script ▼"
	script_dropdown.TextColor3 = COLOR_WHITE
	script_dropdown.TextSize = 9
	script_dropdown.Font = Enum.Font.BebasNeue
	script_dropdown.BorderSizePixel = 1
	script_dropdown.BorderColor3 = COLOR_NEON_ORANGE
	script_dropdown.Parent = right_panel
	
	-- Sync to Script Toggle Label
	local sync_label = Instance.new("TextLabel")
	sync_label.Name = "SyncLabel"
	sync_label.Size = UDim2.new(0.7, 0, 0, 15)
	sync_label.Position = UDim2.new(0, 5, 0, 65)
	sync_label.BackgroundTransparency = 1
	sync_label.Text = "(toggle) Sync to script"
	sync_label.TextColor3 = COLOR_WHITE
	sync_label.TextSize = 8
	sync_label.Font = Enum.Font.BebasNeue
	sync_label.TextXAlignment = Enum.TextXAlignment.Left
	sync_label.Parent = right_panel
	
	-- Sync to Script Toggle
	local sync_toggle = Instance.new("TextButton")
	sync_toggle.Name = "SyncToggle"
	sync_toggle.Size = UDim2.new(0.25, 0, 0, 15)
	sync_toggle.Position = UDim2.new(0.7, 0, 0, 65)
	sync_toggle.BackgroundColor3 = COLOR_WHITE
	sync_toggle.BackgroundTransparency = 0.6
	sync_toggle.Text = "OFF"
	sync_toggle.TextColor3 = COLOR_PITCH_BLACK
	sync_toggle.TextSize = 8
	sync_toggle.Font = Enum.Font.BebasNeue
	sync_toggle.BorderSizePixel = 1
	sync_toggle.BorderColor3 = COLOR_WHITE
	sync_toggle.Parent = right_panel
	
	-- Hide Name Toggle Label
	local hide_name_label = Instance.new("TextLabel")
	hide_name_label.Name = "HideNameLabel"
	hide_name_label.Size = UDim2.new(0.7, 0, 0, 15)
	hide_name_label.Position = UDim2.new(0, 5, 0, 83)
	hide_name_label.BackgroundTransparency = 1
	hide_name_label.Text = "(toggle) hide name"
	hide_name_label.TextColor3 = COLOR_WHITE
	hide_name_label.TextSize = 8
	hide_name_label.Font = Enum.Font.BebasNeue
	hide_name_label.TextXAlignment = Enum.TextXAlignment.Left
	hide_name_label.Parent = right_panel
	
	-- Hide Name Toggle
	local hide_name_toggle = Instance.new("TextButton")
	hide_name_toggle.Name = "HideNameToggle"
	hide_name_toggle.Size = UDim2.new(0.25, 0, 0, 15)
	hide_name_toggle.Position = UDim2.new(0.7, 0, 0, 83)
	hide_name_toggle.BackgroundColor3 = COLOR_WHITE
	hide_name_toggle.BackgroundTransparency = 0.6
	hide_name_toggle.Text = "OFF"
	hide_name_toggle.TextColor3 = COLOR_PITCH_BLACK
	hide_name_toggle.TextSize = 8
	hide_name_toggle.Font = Enum.Font.BebasNeue
	hide_name_toggle.BorderSizePixel = 1
	hide_name_toggle.BorderColor3 = COLOR_WHITE
	hide_name_toggle.Parent = right_panel
	
	-- Log Window Title
	local log_title = Instance.new("TextLabel")
	log_title.Name = "LogTitle"
	log_title.Size = UDim2.new(1, 0, 0, 15)
	log_title.Position = UDim2.new(0, 5, 0, 105)
	log_title.BackgroundTransparency = 1
	log_title.Text = "Log"
	log_title.TextColor3 = COLOR_NEON_ORANGE
	log_title.TextSize = 10
	log_title.Font = Enum.Font.BebasNeue
	log_title.TextXAlignment = Enum.TextXAlignment.Center
	log_title.Parent = right_panel
	
	-- Log Display TextBox (Scrollable)
	local log_box = Instance.new("TextBox")
	log_box.Name = "LogBox"
	log_box.Size = UDim2.new(1, -10, 0, 65)
	log_box.Position = UDim2.new(0, 5, 0, 122)
	log_box.BackgroundColor3 = COLOR_PITCH_BLACK
	log_box.BackgroundTransparency = 0.6
	log_box.Text = ""
	log_box.TextColor3 = COLOR_NEON_ORANGE
	log_box.TextSize = 8
	log_box.Font = Enum.Font.BebasNeue
	log_box.TextEditable = false
	log_box.TextWrapped = true
	log_box.TextYAlignment = Enum.TextYAlignment.Top
	log_box.BorderSizePixel = 1
	log_box.BorderColor3 = COLOR_NEON_ORANGE
	log_box.MultiLine = true
	log_box.ClearTextOnFocus = false
	log_box.Parent = right_panel
	
	-- ==========================================
	-- MINIMIZE STATE (Floating Button)
	-- ==========================================
	
	local float_btn = Instance.new("TextButton")
	float_btn.Name = "FloatOpenBtn"
	float_btn.Size = UDim2.new(0, 60, 0, 60)
	float_btn.Position = UDim2.new(0.02, 0, 0.02, 0)
	float_btn.BackgroundColor3 = COLOR_NEON_ORANGE
	float_btn.BackgroundTransparency = 0.4
	float_btn.Text = "OPEN"
	float_btn.TextColor3 = COLOR_WHITE
	float_btn.TextSize = 12
	float_btn.Font = Enum.Font.BebasNeue
	float_btn.BorderSizePixel = 2
	float_btn.BorderColor3 = COLOR_NEON_ORANGE
	float_btn.Visible = false
	float_btn.Parent = screen_gui
	
	-- Add UICorner to floating button
	local float_corner = Instance.new("UICorner")
	float_corner.CornerRadius = UDim.new(1, 0)
	float_corner.Parent = float_btn
	
	-- ==========================================
	-- EVENT HANDLERS
	-- ==========================================
	
	scan_rod1_btn.MouseButton1Click:Connect(function()
		local name, id = scan_current_tool()
		if name and id then
			state.rod_1 = name
			state.rod_1_id = id
			rod1_textbox.Text = name .. " | " .. id
			log_event("Rod_1 LOCKED: " .. name)
		end
	end)
	
	scan_rod2_btn.MouseButton1Click:Connect(function()
		local name, id = scan_current_tool()
		if name and id then
			state.rod_2 = name
			state.rod_2_id = id
			rod2_textbox.Text = name .. " | " .. id
			log_event("Rod_2 LOCKED: " .. name)
		end
	end)
	
	auto_swap_toggle.MouseButton1Click:Connect(function()
		state.auto_swap_active = not state.auto_swap_active
		
		if state.auto_swap_active then
			auto_swap_toggle.BackgroundColor3 = COLOR_NEON_ORANGE
			auto_swap_toggle.Text = "ON"
			auto_swap_toggle.TextColor3 = COLOR_WHITE
			log_event("Auto Swap ACTIVATED")
			monitor_hunt_and_risk_events()
		else
			auto_swap_toggle.BackgroundColor3 = COLOR_WHITE
			auto_swap_toggle.Text = "OFF"
			auto_swap_toggle.TextColor3 = COLOR_PITCH_BLACK
			log_event("Auto Swap DEACTIVATED")
			disconnect_all_events()
		end
	end)
	
	script_dropdown.MouseButton1Click:Connect(function()
		local scripts = detect_scripts_in_workspace()
		if #scripts > 0 then
			state.selected_script = scripts[1]
			script_dropdown.Text = (scripts[1].Name or "Script_1") .. " ▼"
			log_event("Script selected: " .. (scripts[1].Name or "Script_1"))
		else
			log_event("No scripts found in workspace")
		end
	end)
	
	sync_toggle.MouseButton1Click:Connect(function()
		state.sync_to_script_active = not state.sync_to_script_active
		
		if state.sync_to_script_active then
			sync_toggle.BackgroundColor3 = COLOR_NEON_ORANGE
			sync_toggle.Text = "ON"
			sync_toggle.TextColor3 = COLOR_WHITE
			log_event("Script Sync ACTIVATED")
		else
			sync_toggle.BackgroundColor3 = COLOR_WHITE
			sync_toggle.Text = "OFF"
			sync_toggle.TextColor3 = COLOR_PITCH_BLACK
			log_event("Script Sync DEACTIVATED")
		end
	end)
	
	hide_name_toggle.MouseButton1Click:Connect(function()
		state.hide_name_active = not state.hide_name_active
		
		if state.hide_name_active then
			hide_name_toggle.BackgroundColor3 = COLOR_NEON_ORANGE
			hide_name_toggle.Text = "ON"
			hide_name_toggle.TextColor3 = COLOR_WHITE
			hide_player_name(true)
		else
			hide_name_toggle.BackgroundColor3 = COLOR_WHITE
			hide_name_toggle.Text = "OFF"
			hide_name_toggle.TextColor3 = COLOR_PITCH_BLACK
			hide_player_name(false)
		end
	end)
	
	minimize_btn.MouseButton1Click:Connect(function()
		state.window_minimized = true
		main_frame.Visible = false
		float_btn.Visible = true
        log_event("Window MINIMIZED")
	end)
	
	close_btn.MouseButton1Click:Connect(function()
		disconnect_all_events()
		log_event("CAROL shutting down...")
		screen_gui:Destroy()
	end)
	
	float_btn.MouseButton1Click:Connect(function()
		state.window_minimized = false
		main_frame.Visible = true
		float_btn.Visible = false
		log_event("Window RESTORED")
	end)
	
	-- ==========================================
	-- LOG UPDATE LOOP
	-- ==========================================
	
	local log_update_connection
	log_update_connection = RunService.Heartbeat:Connect(function()
		local log_text = table.concat(state.log_buffer, "\n")
		log_box.Text = log_text
		-- Auto-scroll to bottom
		if #state.log_buffer > 10 then
			log_box.CursorPosition = #log_text
		end
	end)
	
	table.insert(state.event_connections, log_update_connection)
	
	-- ==========================================
	-- CLEANUP ON SCRIPT DESTROY
	-- ==========================================
	
	local cleanup_connection
	cleanup_connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not screen_gui.Parent then
			disconnect_all_events()
			cleanup_connection:Disconnect()
		end
	end)
	
	log_event("CAROL initialized successfully")
	return screen_gui
end

-- ==========================================
-- MAIN EXECUTION
-- ==========================================

local function main()
	log_event("Starting CAROL Co-Pilot Working Tool...")
	
	if not player or not player:FindFirstChild("PlayerGui") and not CoreGui then
		log_event("ERROR: PlayerGui or CoreGui not accessible")
		return
	end
	
	local success, result = pcall(function()
		return create_ui()
    end)
	
	if success then
		log_event("UI created successfully")
	else
		log_event("ERROR creating UI: " .. tostring(result))
	end
end

-- Execute
main()

--[[
========================================
END OF CAROL CO-PILOT TOOL v1.0
========================================
]]
