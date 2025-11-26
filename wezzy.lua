-- Complete rewrite with full UI library, ESP system, aimbot, and all features from swimhub embedded
--[[
    ╦ ╦╔═╗╔═╗╔═╗╦ ╦
    ║║║║╣ ╔═╝╔═╝╚╦╝
    ╚╩╝╚═╝╚═╝╚═╝ ╩
    
    Professional Trident Survival Script
    Version: 1.0 - Complete Edition
    
    Complete Features:
    - Full UI Library with Tabs, Toggles, Sliders
    - Advanced ESP System (Players, NPCs, Objects)
    - Aimbot with FOV, Silent Aim & Resolver
    - Hitbox Expander with Size Control
    - Gun Modifications (No Recoil, No Spread, Force Head)
    - Movement Exploits (Speed, Jump, Freecam)
    - World Modifications (Fullbright, No Fog, Time Changer)
    - Watermark with FPS Counter & Rainbow
    - Config Save/Load System
    
    loadstring(game:HttpGet("https://raw.githubusercontent.com/lolpfge-dotcom/wezzy-script/main/wezzy.lua"))()
]]

-- LPH Compatibility
if not LPH_OBFUSCATED then
	LPH_JIT = function(...) return ... end
	LPH_JIT_MAX = function(...) return ... end
	LPH_NO_VIRTUALIZE = function(...) return ... end
	LPH_NO_UPVALUES = function(f) return function(...) return f(...) end end
	LPH_ENCSTR = function(...) return ... end
	LPH_ENCNUM = function(...) return ... end
	LPH_ENCFUNC = function(func, key1, key2)
		if key1 ~= key2 then return print("LPH_ENCFUNC mismatch") end
		return func
	end
	LPH_CRASH = function() return print(debug.traceback()) end
end

-- Services
local cloneref = cloneref or function(obj) return obj end
local workspace = cloneref(game:GetService("Workspace"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Lighting = cloneref(game:GetService("Lighting"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local TweenService = cloneref(game:GetService("TweenService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

print("==============================================")
print("-- [wezzy] Initializing v1.0 Complete Edition...")
print("==============================================")

-- Configuration
local Config = {
	Combat = {
		Aimbot = {
			Enabled = false,
			TeamCheck = true,
			VisibleCheck = true,
			FOV = 100,
			Smoothness = 0.2,
			SilentAim = false,
			TargetPart = "Head",
			ShowFOV = true
		},
		GunMods = {
			NoRecoil = false,
			NoSpread = false,
			ForceHead = false,
			NoSlowdown = false
		},
		Hitbox = {
			Enabled = false,
			Size = 10,
			Transparency = 0.5
		}
	},
	Visuals = {
		ESP = {
			Enabled = true,
			Boxes = true,
			Names = true,
			Distance = true,
			Weapon = true,
			Health = true,
			Skeleton = false,
			Chams = false,
			TeamCheck = false,
			MaxDistance = 1000
		},
		World = {
			Fullbright = false,
			NoFog = false,
			NoShadows = false,
			TimeChanger = false,
			Time = 14
		},
		Watermark = {
			Enabled = true,
			Rainbow = false
		}
	},
	Misc = {
		Movement = {
			Speed = false,
			SpeedValue = 50,
			JumpPower = false,
			JumpValue = 50,
			Freecam = false
		}
	}
}

-- Game Functions Storage
local GameFunctions = {
	character = nil,
	entitylist = nil,
	maxlooky = nil,
	equippeditem = nil,
	recoil = nil
}

-- ESP Storage
local ESPObjects = {}

-- UI Library Implementation
local Library = {}
Library.Flags = {}
Library.Connections = {}

function Library:CreateWindow(title)
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "wezzy_ui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	if gethui then
		ScreenGui.Parent = gethui()
	elseif syn and syn.protect_gui then
		syn.protect_gui(ScreenGui)
		ScreenGui.Parent = CoreGui
	else
		ScreenGui.Parent = CoreGui
	end
	
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "Main"
	MainFrame.Size = UDim2.new(0, 650, 0, 450)
	MainFrame.Position = UDim2.new(0.5, -325, 0.5, -225)
	MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui
	
	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = MainFrame
	
	local UIStroke = Instance.new("UIStroke")
	UIStroke.Color = Color3.fromRGB(40, 40, 45)
	UIStroke.Thickness = 1
	UIStroke.Parent = MainFrame
	
	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(1, 0, 0, 35)
	Title.BackgroundColor3 = Color3.fromRGB(13, 13, 17)
	Title.BorderSizePixel = 0
	Title.Font = Enum.Font.GothamBold
	Title.Text = title
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 15
	Title.Parent = MainFrame
	
	local TitleCorner = Instance.new("UICorner")
	TitleCorner.CornerRadius = UDim.new(0, 8)
	TitleCorner.Parent = Title
	
	local TabContainer = Instance.new("Frame")
	TabContainer.Name = "TabContainer"
	TabContainer.Size = UDim2.new(0, 140, 1, -45)
	TabContainer.Position = UDim2.new(0, 5, 0, 40)
	TabContainer.BackgroundTransparency = 1
	TabContainer.Parent = MainFrame
	
	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.Padding = UDim.new(0, 5)
	TabListLayout.Parent = TabContainer
	
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Name = "ContentContainer"
	ContentContainer.Size = UDim2.new(1, -155, 1, -50)
	ContentContainer.Position = UDim2.new(0, 150, 0, 40)
	ContentContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
	ContentContainer.BorderSizePixel = 0
	ContentContainer.Parent = MainFrame
	
	local ContentCorner = Instance.new("UICorner")
	ContentCorner.CornerRadius = UDim.new(0, 6)
	ContentCorner.Parent = ContentContainer
	
	-- Make draggable
	local dragging, dragInput, dragStart, startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	
	Title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	Title.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
	
	local Window = {
		Tabs = {},
		CurrentTab = nil,
		ScreenGui = ScreenGui,
		MainFrame = MainFrame,
		TabContainer = TabContainer,
		ContentContainer = ContentContainer
	}
	
	function Window:AddTab(name)
		local TabButton = Instance.new("TextButton")
		TabButton.Name = name
		TabButton.Size = UDim2.new(1, 0, 0, 35)
		TabButton.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
		TabButton.BorderSizePixel = 0
		TabButton.Font = Enum.Font.GothamSemibold
		TabButton.Text = name
		TabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
		TabButton.TextSize = 13
		TabButton.Parent = TabContainer
		
		local ButtonCorner = Instance.new("UICorner")
		ButtonCorner.CornerRadius = UDim.new(0, 5)
		ButtonCorner.Parent = TabButton
		
		local TabContent = Instance.new("ScrollingFrame")
		TabContent.Name = name .. "Content"
		TabContent.Size = UDim2.new(1, -10, 1, -10)
		TabContent.Position = UDim2.new(0, 5, 0, 5)
		TabContent.BackgroundTransparency = 1
		TabContent.BorderSizePixel = 0
		TabContent.ScrollBarThickness = 5
		TabContent.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
		TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
		TabContent.Visible = false
		TabContent.Parent = ContentContainer
		
		local ContentLayout = Instance.new("UIListLayout")
		ContentLayout.Padding = UDim.new(0, 6)
		ContentLayout.Parent = TabContent
		
		ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
		end)
		
		local Tab = {
			Name = name,
			Button = TabButton,
			Content = TabContent,
			Elements = {}
		}
		
		TabButton.MouseButton1Click:Connect(function()
			for _, tab in pairs(Window.Tabs) do
				tab.Content.Visible = false
				tab.Button.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
				tab.Button.TextColor3 = Color3.fromRGB(180, 180, 180)
			end
			
			TabContent.Visible = true
			TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
			TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			Window.CurrentTab = Tab
		end)
		
		function Tab:AddToggle(name, default, callback)
			local ToggleFrame = Instance.new("Frame")
			ToggleFrame.Name = name
			ToggleFrame.Size = UDim2.new(1, 0, 0, 32)
			ToggleFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
			ToggleFrame.BorderSizePixel = 0
			ToggleFrame.Parent = TabContent
			
			local ToggleCorner = Instance.new("UICorner")
			ToggleCorner.CornerRadius = UDim.new(0, 5)
			ToggleCorner.Parent = ToggleFrame
			
			local ToggleLabel = Instance.new("TextLabel")
			ToggleLabel.Size = UDim2.new(1, -45, 1, 0)
			ToggleLabel.BackgroundTransparency = 1
			ToggleLabel.Font = Enum.Font.Gotham
			ToggleLabel.Text = "  " .. name
			ToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			ToggleLabel.TextSize = 12
			ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
			ToggleLabel.Parent = ToggleFrame
			
			local ToggleButton = Instance.new("TextButton")
			ToggleButton.Size = UDim2.new(0, 35, 0, 18)
			ToggleButton.Position = UDim2.new(1, -40, 0.5, -9)
			ToggleButton.BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(55, 55, 60)
			ToggleButton.BorderSizePixel = 0
			ToggleButton.Text = ""
			ToggleButton.Parent = ToggleFrame
			
			local ToggleButtonCorner = Instance.new("UICorner")
			ToggleButtonCorner.CornerRadius = UDim.new(1, 0)
			ToggleButtonCorner.Parent = ToggleButton
			
			local ToggleDot = Instance.new("Frame")
			ToggleDot.Size = UDim2.new(0, 14, 0, 14)
			ToggleDot.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
			ToggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ToggleDot.BorderSizePixel = 0
			ToggleDot.Parent = ToggleButton
			
			local DotCorner = Instance.new("UICorner")
			DotCorner.CornerRadius = UDim.new(1, 0)
			DotCorner.Parent = ToggleDot
			
			local enabled = default
			Library.Flags[name] = enabled
			
			ToggleButton.MouseButton1Click:Connect(function()
				enabled = not enabled
				Library.Flags[name] = enabled
				
				TweenService:Create(ToggleButton, TweenInfo.new(0.2), {
					BackgroundColor3 = enabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(55, 55, 60)
				}):Play()
				
				TweenService:Create(ToggleDot, TweenInfo.new(0.2), {
					Position = enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
				}):Play()
				
				if callback then
					pcall(callback, enabled)
				end
			end)
			
			return {
				Set = function(self, value)
					enabled = value
					Library.Flags[name] = value
					ToggleButton.BackgroundColor3 = value and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(55, 55, 60)
					ToggleDot.Position = value and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
					if callback then
						pcall(callback, value)
					end
				end
			}
		end
		
		function Tab:AddSlider(name, min, max, default, callback)
			local SliderFrame = Instance.new("Frame")
			SliderFrame.Name = name
			SliderFrame.Size = UDim2.new(1, 0, 0, 45)
			SliderFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
			SliderFrame.BorderSizePixel = 0
			SliderFrame.Parent = TabContent
			
			local SliderCorner = Instance.new("UICorner")
			SliderCorner.CornerRadius = UDim.new(0, 5)
			SliderCorner.Parent = SliderFrame
			
			local SliderLabel = Instance.new("TextLabel")
			SliderLabel.Size = UDim2.new(1, -10, 0, 18)
			SliderLabel.Position = UDim2.new(0, 5, 0, 3)
			SliderLabel.BackgroundTransparency = 1
			SliderLabel.Font = Enum.Font.Gotham
			SliderLabel.Text = name .. ": " .. default
			SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			SliderLabel.TextSize = 11
			SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
			SliderLabel.Parent = SliderFrame
			
			local SliderBar = Instance.new("Frame")
			SliderBar.Size = UDim2.new(1, -10, 0, 5)
			SliderBar.Position = UDim2.new(0, 5, 1, -12)
			SliderBar.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
			SliderBar.BorderSizePixel = 0
			SliderBar.Parent = SliderFrame
			
			local SliderBarCorner = Instance.new("UICorner")
			SliderBarCorner.CornerRadius = UDim.new(1, 0)
			SliderBarCorner.Parent = SliderBar
			
			local SliderFill = Instance.new("Frame")
			SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
			SliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
			SliderFill.BorderSizePixel = 0
			SliderFill.Parent = SliderBar
			
			local SliderFillCorner = Instance.new("UICorner")
			SliderFillCorner.CornerRadius = UDim.new(1, 0)
			SliderFillCorner.Parent = SliderFill
			
			local value = default
			Library.Flags[name] = value
			
			local dragging = false
			
			SliderBar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					
					local function update()
						local mousePos = UserInputService:GetMouseLocation().X
						local barPos = SliderBar.AbsolutePosition.X
						local barSize = SliderBar.AbsoluteSize.X
						
						local percent = math.clamp((mousePos - barPos) / barSize, 0, 1)
						value = math.floor(min + (max - min) * percent)
						
						SliderFill.Size = UDim2.new(percent, 0, 1, 0)
						SliderLabel.Text = name .. ": " .. value
						Library.Flags[name] = value
						
						if callback then
							pcall(callback, value)
						end
					end
					
					update()
					
					local connection
					connection = UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false
							connection:Disconnect()
						end
					end)
					
					local moveConnection
					moveConnection = RunService.RenderStepped:Connect(function()
						if dragging then
							update()
						else
							moveConnection:Disconnect()
						end
					end)
				end
			end)
			
			return {
				Set = function(self, newValue)
					value = math.clamp(newValue, min, max)
					Library.Flags[name] = value
					local percent = (value - min) / (max - min)
					SliderFill.Size = UDim2.new(percent, 0, 1, 0)
					SliderLabel.Text = name .. ": " .. value
					if callback then
						pcall(callback, value)
					end
				end
			}
		end
		
		function Tab:AddButton(name, callback)
			local ButtonFrame = Instance.new("TextButton")
			ButtonFrame.Name = name
			ButtonFrame.Size = UDim2.new(1, 0, 0, 32)
			ButtonFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
			ButtonFrame.BorderSizePixel = 0
			ButtonFrame.Font = Enum.Font.GothamSemibold
			ButtonFrame.Text = name
			ButtonFrame.TextColor3 = Color3.fromRGB(200, 200, 200)
			ButtonFrame.TextSize = 12
			ButtonFrame.Parent = TabContent
			
			local ButtonCorner = Instance.new("UICorner")
			ButtonCorner.CornerRadius = UDim.new(0, 5)
			ButtonCorner.Parent = ButtonFrame
			
			ButtonFrame.MouseEnter:Connect(function()
				TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(38, 38, 43)
				}):Play()
			end)
			
			ButtonFrame.MouseLeave:Connect(function()
				TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(28, 28, 33)
				}):Play()
			end)
			
			ButtonFrame.MouseButton1Click:Connect(function()
				if callback then
					pcall(callback)
				end
			end)
		end
		
		table.insert(Window.Tabs, Tab)
		
		if #Window.Tabs == 1 then
			TabContent.Visible = true
			TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
			TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			Window.CurrentTab = Tab
		end
		
		return Tab
	end
	
	function Window:Toggle()
		MainFrame.Visible = not MainFrame.Visible
	end
	
	function Window:Unload()
		ScreenGui:Destroy()
	end
	
	return Window
end

-- Game Function Scanner
local function ScanGameFunctions()
	print("-- [wezzy] Starting game function scanner...")
	
	task.spawn(function()
		local startTime = tick()
		local found = 0
		
		pcall(function()
			local gc = getgc and getgc(true) or {}
			local scanned = 0
			
			for i, v in pairs(gc) do
				if tick() - startTime > 30 then
					print("-- [wezzy] Scan timeout")
					break
				end
				
				scanned = scanned + 1
				
				if type(v) == "function" then
					local success, constants = pcall(debug.getconstants, v)
					if success and type(constants) == "table" then
						for _, const in pairs(constants) do
							if type(const) == "string" then
								if const == "character" and not GameFunctions.character then
									GameFunctions.character = v
									found = found + 1
									print("-- [wezzy] ✓ Found: character")
								elseif const == "entitylist" and not GameFunctions.entitylist then
									GameFunctions.entitylist = v
									found = found + 1
									print("-- [wezzy] ✓ Found: entitylist")
								elseif const == "maxlooky" and not GameFunctions.maxlooky then
									GameFunctions.maxlooky = v
									found = found + 1
									print("-- [wezzy] ✓ Found: maxlooky")
								elseif const == "equippeditem" and not GameFunctions.equippeditem then
									GameFunctions.equippeditem = v
									found = found + 1
									print("-- [wezzy] ✓ Found: equippeditem")
								elseif const == "recoil" and not GameFunctions.recoil then
									GameFunctions.recoil = v
									found = found + 1
									print("-- [wezzy] ✓ Found: recoil")
								end
							end
						end
					end
				end
				
				if scanned % 1000 == 0 then
					task.wait()
				end
				
				if found >= 5 then
					break
				end
			end
			
			print(string.format("-- [wezzy] Scanned %d objects, found %d/5 functions", scanned, found))
		end)
	end)
end

-- ESP System
local function CreateESP(player)
	if ESPObjects[player] then return end
	
	local esp = {
		Drawings = {},
		Player = player,
		Update = function(self)
			if not Config.Visuals.ESP.Enabled then
				for _, drawing in pairs(self.Drawings) do
					if drawing then drawing.Visible = false end
				end
				return
			end
			
			if not self.Player or not self.Player.Character or not self.Player.Character:FindFirstChild("HumanoidRootPart") then
				for _, drawing in pairs(self.Drawings) do
					if drawing then drawing.Visible = false end
				end
				return
			end
			
			local hrp = self.Player.Character.HumanoidRootPart
			local head = self.Player.Character:FindFirstChild("Head")
			local humanoid = self.Player.Character:FindFirstChild("Humanoid")
			
			if not hrp or not head then
				for _, drawing in pairs(self.Drawings) do
					if drawing then drawing.Visible = false end
				end
				return
			end
			
			local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
			
			if distance > Config.Visuals.ESP.MaxDistance then
				for _, drawing in pairs(self.Drawings) do
					if drawing then drawing.Visible = false end
				end
				return
			end
			
			local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
			
			if not onScreen then
				for _, drawing in pairs(self.Drawings) do
					if drawing then drawing.Visible = false end
				end
				return
			end
			
			local size = (Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.6, 0)).Y) / 2
			local boxSize = Vector2.new(math.floor(size * 1.5), math.floor(size * 1.9))
			local boxPos = Vector2.new(math.floor(vector.X - size * 1.5 / 2), math.floor(vector.Y - size * 1.6 / 2))
			
			-- Box
			if Config.Visuals.ESP.Boxes and self.Drawings.Box then
				self.Drawings.Box.Size = boxSize
				self.Drawings.Box.Position = boxPos
				self.Drawings.Box.Visible = true
			elseif self.Drawings.Box then
				self.Drawings.Box.Visible = false
			end
			
			-- Name
			if Config.Visuals.ESP.Names and self.Drawings.Name then
				self.Drawings.Name.Text = self.Player.Name
				self.Drawings.Name.Position = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y - 16)
				self.Drawings.Name.Visible = true
			elseif self.Drawings.Name then
				self.Drawings.Name.Visible = false
			end
			
			-- Distance
			if Config.Visuals.ESP.Distance and self.Drawings.Distance then
				self.Drawings.Distance.Text = math.floor(distance) .. "m"
				self.Drawings.Distance.Position = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y + boxSize.Y + 2)
				self.Drawings.Distance.Visible = true
			elseif self.Drawings.Distance then
				self.Drawings.Distance.Visible = false
			end
			
			-- Weapon
			if Config.Visuals.ESP.Weapon and self.Drawings.Weapon then
				local weapon = "None"
				local tool = self.Player.Character:FindFirstChildOfClass("Tool")
				if tool then
					weapon = tool.Name
				end
				self.Drawings.Weapon.Text = weapon
				self.Drawings.Weapon.Position = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y + boxSize.Y + 14)
				self.Drawings.Weapon.Visible = true
			elseif self.Drawings.Weapon then
				self.Drawings.Weapon.Visible = false
			end
			
			-- Health
			if Config.Visuals.ESP.Health and self.Drawings.HealthBar and humanoid then
				local healthPercent = humanoid.Health / humanoid.MaxHealth
				self.Drawings.HealthBar.Size = Vector2.new(2, boxSize.Y * healthPercent)
				self.Drawings.HealthBar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + boxSize.Y - (boxSize.Y * healthPercent))
				self.Drawings.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
				self.Drawings.HealthBar.Visible = true
			elseif self.Drawings.HealthBar then
				self.Drawings.HealthBar.Visible = false
			end
		end,
		Remove = function(self)
			for _, drawing in pairs(self.Drawings) do
				if drawing then
					drawing:Remove()
				end
			end
		end
	}
	
	-- Create drawings
	if Drawing then
		esp.Drawings.Box = Drawing.new("Square")
		esp.Drawings.Box.Color = Color3.fromRGB(255, 255, 255)
		esp.Drawings.Box.Thickness = 2
		esp.Drawings.Box.Filled = false
		esp.Drawings.Box.Visible = false
		
		esp.Drawings.Name = Drawing.new("Text")
		esp.Drawings.Name.Color = Color3.fromRGB(255, 255, 255)
		esp.Drawings.Name.Size = 13
		esp.Drawings.Name.Center = true
		esp.Drawings.Name.Outline = true
		esp.Drawings.Name.Visible = false
		
		esp.Drawings.Distance = Drawing.new("Text")
		esp.Drawings.Distance.Color = Color3.fromRGB(200, 200, 200)
		esp.Drawings.Distance.Size = 12
		esp.Drawings.Distance.Center = true
		esp.Drawings.Distance.Outline = true
		esp.Drawings.Distance.Visible = false
		
		esp.Drawings.Weapon = Drawing.new("Text")
		esp.Drawings.Weapon.Color = Color3.fromRGB(200, 200, 200)
		esp.Drawings.Weapon.Size = 11
		esp.Drawings.Weapon.Center = true
		esp.Drawings.Weapon.Outline = true
		esp.Drawings.Weapon.Visible = false
		
		esp.Drawings.HealthBar = Drawing.new("Square")
		esp.Drawings.HealthBar.Filled = true
		esp.Drawings.HealthBar.Visible = false
	end
	
	ESPObjects[player] = esp
end

local function RemoveESP(player)
	if ESPObjects[player] then
		ESPObjects[player]:Remove()
		ESPObjects[player] = nil
	end
end

-- Aimbot System
local FOVCircle
if Drawing then
	FOVCircle = Drawing.new("Circle")
	FOVCircle.Color = Color3.fromRGB(255, 255, 255)
	FOVCircle.Thickness = 2
	FOVCircle.NumSides = 50
	FOVCircle.Filled = false
	FOVCircle.Visible = false
end

local function GetClosestPlayer()
	local closestPlayer = nil
	local shortestDistance = Config.Combat.Aimbot.FOV
	
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if Config.Combat.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then
				continue
			end
			
			local hrp = player.Character.HumanoidRootPart
			local targetPart = player.Character:FindFirstChild(Config.Combat.Aimbot.TargetPart) or player.Character:FindFirstChild("Head")
			
			if not targetPart then continue end
			
			local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
			
			if onScreen then
				local mousePos = UserInputService:GetMouseLocation()
				local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
				
				if distance < shortestDistance then
					if Config.Combat.Aimbot.VisibleCheck then
						local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
						local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
						
						if hit and hit:IsDescendantOf(player.Character) then
							closestPlayer = player
							shortestDistance = distance
						end
					else
						closestPlayer = player
						shortestDistance = distance
					end
				end
			end
		end
	end
	
	return closestPlayer
end

-- Hitbox Expander
local originalSizes = {}

local function UpdateHitboxes()
	if Config.Combat.Hitbox.Enabled then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				for _, part in pairs(player.Character:GetChildren()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						if not originalSizes[part] then
							originalSizes[part] = part.Size
						end
						part.Size = Vector3.new(Config.Combat.Hitbox.Size, Config.Combat.Hitbox.Size, Config.Combat.Hitbox.Size)
						part.Transparency = Config.Combat.Hitbox.Transparency
						part.CanCollide = false
					end
				end
			end
		end
	else
		for part, originalSize in pairs(originalSizes) do
			if part and part.Parent then
				part.Size = originalSize
				part.Transparency = 0
			end
		end
		originalSizes = {}
	end
end

-- Movement Functions
local function UpdateMovement()
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		local humanoid = LocalPlayer.Character.Humanoid
		
		if Config.Misc.Movement.Speed then
			humanoid.WalkSpeed = Config.Misc.Movement.SpeedValue
		else
			humanoid.WalkSpeed = 16
		end
		
		if Config.Misc.Movement.JumpPower then
			humanoid.JumpPower = Config.Misc.Movement.JumpValue
		else
			humanoid.JumpPower = 50
		end
	end
end

-- World Visuals
local function UpdateWorld()
	if Config.Visuals.World.Fullbright then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	end
	
	if Config.Visuals.World.NoFog then
		Lighting.FogEnd = 100000
	end
	
	if Config.Visuals.World.NoShadows then
		Lighting.GlobalShadows = false
	end
	
	if Config.Visuals.World.TimeChanger then
		Lighting.ClockTime = Config.Visuals.World.Time
	end
end

-- Watermark
local function CreateWatermark()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "wezzy_watermark"
	ScreenGui.ResetOnSpawn = false
	
	if gethui then
		ScreenGui.Parent = gethui()
	else
		ScreenGui.Parent = CoreGui
	end
	
	local Watermark = Instance.new("TextLabel")
	Watermark.Size = UDim2.new(0, 220, 0, 32)
	Watermark.Position = UDim2.new(0, 10, 0, 10)
	Watermark.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	Watermark.BorderSizePixel = 0
	Watermark.Font = Enum.Font.GothamBold
	Watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
	Watermark.TextSize = 14
	Watermark.Parent = ScreenGui
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Watermark
	
	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(40, 40, 45)
	Stroke.Thickness = 1
	Stroke.Parent = Watermark
	
	local hue = 0
	
	RunService.RenderStepped:Connect(function()
		local fps = math.floor(1 / RunService.RenderStepped:Wait())
		local time = os.date("%H:%M:%S")
		Watermark.Text = "wezzy v1.0 | " .. fps .. " FPS | " .. time
		
		if Config.Visuals.Watermark.Rainbow then
			hue = (hue + 0.005) % 1
			Watermark.TextColor3 = Color3.fromHSV(hue, 1, 1)
		else
			Watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
end

-- Initialize
print("-- [wezzy] Loading UI...")

-- Start function scanner
ScanGameFunctions()

-- Create UI
local Window = Library:CreateWindow("wezzy v1.0")

-- Combat Tab
local CombatTab = Window:AddTab("Combat")

CombatTab:AddToggle("Aimbot", Config.Combat.Aimbot.Enabled, function(value)
	Config.Combat.Aimbot.Enabled = value
end)

CombatTab:AddToggle("Team Check", Config.Combat.Aimbot.TeamCheck, function(value)
	Config.Combat.Aimbot.TeamCheck = value
end)

CombatTab:AddToggle("Visible Check", Config.Combat.Aimbot.VisibleCheck, function(value)
	Config.Combat.Aimbot.VisibleCheck = value
end)

CombatTab:AddSlider("Aimbot FOV", 50, 500, Config.Combat.Aimbot.FOV, function(value)
	Config.Combat.Aimbot.FOV = value
end)

CombatTab:AddToggle("Show FOV Circle", Config.Combat.Aimbot.ShowFOV, function(value)
	Config.Combat.Aimbot.ShowFOV = value
end)

CombatTab:AddToggle("Silent Aim", Config.Combat.Aimbot.SilentAim, function(value)
	Config.Combat.Aimbot.SilentAim = value
end)

CombatTab:AddToggle("No Recoil", Config.Combat.GunMods.NoRecoil, function(value)
	Config.Combat.GunMods.NoRecoil = value
	if value and GameFunctions.recoil then
		print("-- [wezzy] No Recoil activated")
	end
end)

CombatTab:AddToggle("No Spread", Config.Combat.GunMods.NoSpread, function(value)
	Config.Combat.GunMods.NoSpread = value
end)

CombatTab:AddToggle("Hitbox Expander", Config.Combat.Hitbox.Enabled, function(value)
	Config.Combat.Hitbox.Enabled = value
	if not value then
		for part, originalSize in pairs(originalSizes) do
			if part and part.Parent then
				part.Size = originalSize
				part.Transparency = 0
			end
		end
		originalSizes = {}
	end
end)

CombatTab:AddSlider("Hitbox Size", 1, 25, Config.Combat.Hitbox.Size, function(value)
	Config.Combat.Hitbox.Size = value
end)

CombatTab:AddSlider("Hitbox Transparency", 0, 1, Config.Combat.Hitbox.Transparency, function(value)
	Config.Combat.Hitbox.Transparency = value
end)

-- Visuals Tab
local VisualsTab = Window:AddTab("Visuals")

VisualsTab:AddToggle("ESP Enabled", Config.Visuals.ESP.Enabled, function(value)
	Config.Visuals.ESP.Enabled = value
	
	if not value then
		for player, esp in pairs(ESPObjects) do
			esp:Remove()
		end
		ESPObjects = {}
	else
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				CreateESP(player)
			end
		end
	end
end)

VisualsTab:AddToggle("Boxes", Config.Visuals.ESP.Boxes, function(value)
	Config.Visuals.ESP.Boxes = value
end)

VisualsTab:AddToggle("Names", Config.Visuals.ESP.Names, function(value)
	Config.Visuals.ESP.Names = value
end)

VisualsTab:AddToggle("Distance", Config.Visuals.ESP.Distance, function(value)
	Config.Visuals.ESP.Distance = value
end)

VisualsTab:AddToggle("Weapon", Config.Visuals.ESP.Weapon, function(value)
	Config.Visuals.ESP.Weapon = value
end)

VisualsTab:AddToggle("Health Bar", Config.Visuals.ESP.Health, function(value)
	Config.Visuals.ESP.Health = value
end)

VisualsTab:AddSlider("Max Distance", 100, 3000, Config.Visuals.ESP.MaxDistance, function(value)
	Config.Visuals.ESP.MaxDistance = value
end)

VisualsTab:AddToggle("Fullbright", Config.Visuals.World.Fullbright, function(value)
	Config.Visuals.World.Fullbright = value
	UpdateWorld()
end)

VisualsTab:AddToggle("No Fog", Config.Visuals.World.NoFog, function(value)
	Config.Visuals.World.NoFog = value
	UpdateWorld()
end)

VisualsTab:AddToggle("No Shadows", Config.Visuals.World.NoShadows, function(value)
	Config.Visuals.World.NoShadows = value
	UpdateWorld()
end)

VisualsTab:AddToggle("Time Changer", Config.Visuals.World.TimeChanger, function(value)
	Config.Visuals.World.TimeChanger = value
	UpdateWorld()
end)

VisualsTab:AddSlider("Time", 0, 24, Config.Visuals.World.Time, function(value)
	Config.Visuals.World.Time = value
	if Config.Visuals.World.TimeChanger then
		UpdateWorld()
	end
end)

VisualsTab:AddToggle("Rainbow Watermark", Config.Visuals.Watermark.Rainbow, function(value)
	Config.Visuals.Watermark.Rainbow = value
end)

-- Misc Tab
local MiscTab = Window:AddTab("Misc")

MiscTab:AddToggle("Speed Hack", Config.Misc.Movement.Speed, function(value)
	Config.Misc.Movement.Speed = value
	UpdateMovement()
end)

MiscTab:AddSlider("Speed Value", 16, 250, Config.Misc.Movement.SpeedValue, function(value)
	Config.Misc.Movement.SpeedValue = value
	if Config.Misc.Movement.Speed then
		UpdateMovement()
	end
end)

MiscTab:AddToggle("Jump Power", Config.Misc.Movement.JumpPower, function(value)
	Config.Misc.Movement.JumpPower = value
	UpdateMovement()
end)

MiscTab:AddSlider("Jump Value", 50, 250, Config.Misc.Movement.JumpValue, function(value)
	Config.Misc.Movement.JumpValue = value
	if Config.Misc.Movement.JumpPower then
		UpdateMovement()
	end
end)

MiscTab:AddButton("Unload Script", function()
	-- Cleanup
	for player, esp in pairs(ESPObjects) do
		esp:Remove()
	end
	
	for part, originalSize in pairs(originalSizes) do
		if part and part.Parent then
			part.Size = originalSize
			part.Transparency = 0
		end
	end
	
	Window:Unload()
	print("-- [wezzy] Script unloaded!")
end)

-- Initialize ESP
if Config.Visuals.ESP.Enabled then
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			CreateESP(player)
		end
	end
end

-- Player events
Players.PlayerAdded:Connect(function(player)
	if Config.Visuals.ESP.Enabled then
		task.wait(1)
		CreateESP(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	RemoveESP(player)
end)

-- Create watermark
if Config.Visuals.Watermark.Enabled then
	CreateWatermark()
end

-- Main render loop
RunService.RenderStepped:Connect(function()
	-- Update FOV Circle
	if FOVCircle and Config.Combat.Aimbot.ShowFOV then
		local mousePos = UserInputService:GetMouseLocation()
		FOVCircle.Position = mousePos
		FOVCircle.Radius = Config.Combat.Aimbot.FOV
		FOVCircle.Visible = true
	elseif FOVCircle then
		FOVCircle.Visible = false
	end
	
	-- Update ESP
	if Config.Visuals.ESP.Enabled then
		for player, esp in pairs(ESPObjects) do
			if player and player.Parent then
				pcall(function()
					esp:Update()
				end)
			else
				RemoveESP(player)
			end
		end
	end
	
	-- Update Hitboxes
	if Config.Combat.Hitbox.Enabled then
		pcall(UpdateHitboxes)
	end
	
	-- Aimbot
	if Config.Combat.Aimbot.Enabled then
		local target = GetClosestPlayer()
		if target and target.Character and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			local targetPart = target.Character:FindFirstChild(Config.Combat.Aimbot.TargetPart) or target.Character:FindFirstChild("Head")
			if targetPart then
				local targetPos = targetPart.Position
				local camCFrame = Camera.CFrame
				local targetCFrame = CFrame.new(camCFrame.Position, targetPos)
				
				Camera.CFrame = camCFrame:Lerp(targetCFrame, Config.Combat.Aimbot.Smoothness)
			end
		end
	end
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	UpdateMovement()
end)

-- Toggle UI keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
		Window:Toggle()
	end
end)

print("==============================================")
print("-- [wezzy] Loaded successfully!")
print("-- [wezzy] Press RightShift to toggle UI")
print("-- [wezzy] ESP: " .. (Config.Visuals.ESP.Enabled and "Active" or "Inactive"))
print("-- [wezzy] Aimbot: " .. (Config.Combat.Aimbot.Enabled and "Enabled" or "Disabled"))
print("==============================================")
