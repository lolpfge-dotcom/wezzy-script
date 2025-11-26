--[[
    wezzy v1.0 - Trident Survival Script
    Loadstring: loadstring(game:HttpGet("your-github-url"))()
]]

print("-- [wezzy] Initializing v1.0...")

-- Services
local cloneref = cloneref or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(game:GetService("Workspace"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Lighting = cloneref(game:GetService("Lighting"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

print("-- [wezzy] Services loaded")

-- Compatibility
local getgc = getgc or debug.getgc or function() return {} end
local getconstants = getconstants or debug.getconstants or function() return {} end
local getupvalues = getupvalues or debug.getupvalues or function() return {} end

-- Configuration
local Config = {
    ESP = {
        Enabled = true,
        Boxes = true,
        Names = true,
        Distance = true,
        MaxDistance = 500,
        TeamCheck = false
    },
    Aimbot = {
        Enabled = false,
        FOV = 100,
        Smoothness = 0.5,
        VisibleCheck = true
    },
    Visuals = {
        Fullbright = false,
        NoFog = false,
        TimeChanger = false,
        CustomTime = 12
    },
    Watermark = {
        Enabled = true
    }
}

-- Game Functions
local GameFunctions = {
    character = nil,
    entitylist = nil,
    maxlooky = nil,
    equippeditem = nil,
    recoil = nil
}

-- ESP Storage
local ESPObjects = {}

-- Async Game Function Scanner
spawn(function()
    print("-- [wezzy] Starting game function scanner (async)...")
    
    local startTime = tick()
    local timeout = 10
    local found = {}
    
    local success, gc = pcall(getgc, true)
    if not success or not gc then
        print("-- [wezzy] Warning: getgc not available")
        return
    end
    
    print("-- [wezzy] Scanning " .. tostring(#gc) .. " objects...")
    
    for i, v in pairs(gc) do
        if tick() - startTime > timeout then
            print("-- [wezzy] Scan timeout after " .. tostring(timeout) .. "s")
            break
        end
        
        if type(v) == "function" then
            local success2, constants = pcall(getconstants, v)
            if success2 and type(constants) == "table" then
                for _, const in pairs(constants) do
                    if type(const) == "string" then
                        if const == "character" and not found.character then
                            GameFunctions.character = v
                            found.character = true
                            print("-- [wezzy] Found: character")
                        elseif const == "entitylist" and not found.entitylist then
                            GameFunctions.entitylist = v
                            found.entitylist = true
                            print("-- [wezzy] Found: entitylist")
                        elseif const == "maxlooky" and not found.maxlooky then
                            GameFunctions.maxlooky = v
                            found.maxlooky = true
                            print("-- [wezzy] Found: maxlooky")
                        elseif const == "equippeditem" and not found.equippeditem then
                            GameFunctions.equippeditem = v
                            found.equippeditem = true
                            print("-- [wezzy] Found: equippeditem")
                        elseif const == "recoil" and not found.recoil then
                            GameFunctions.recoil = v
                            found.recoil = true
                            print("-- [wezzy] Found: recoil")
                        end
                    end
                end
            end
        end
        
        if i % 1000 == 0 then
            wait()
        end
    end
    
    local foundCount = 0
    for k, v in pairs(found) do
        if v then foundCount = foundCount + 1 end
    end
    
    print("-- [wezzy] Scan complete! Found " .. tostring(foundCount) .. "/5 functions")
    
    if foundCount >= 3 then
        print("-- [wezzy] Aimbot features available!")
    else
        print("-- [wezzy] Aimbot disabled (requires game functions)")
    end
end)

-- ESP Functions
local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line")
    }
    
    esp.Box.Thickness = 2
    esp.Box.Filled = false
    esp.Box.Color = Color3.fromRGB(255, 0, 0)
    esp.Box.Visible = false
    esp.Box.ZIndex = 2
    
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Size = 14
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Visible = false
    esp.Name.ZIndex = 2
    
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Size = 13
    esp.Distance.Color = Color3.fromRGB(255, 255, 255)
    esp.Distance.Visible = false
    esp.Distance.ZIndex = 2
    
    esp.Tracer.Thickness = 1
    esp.Tracer.Color = Color3.fromRGB(255, 0, 0)
    esp.Tracer.Visible = false
    esp.Tracer.ZIndex = 1
    
    ESPObjects[player] = esp
end

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, drawing in pairs(ESPObjects[player]) do
            drawing:Remove()
        end
        ESPObjects[player] = nil
    end
end

local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, esp in pairs(ESPObjects) do
            for _, drawing in pairs(esp) do
                drawing.Visible = false
            end
        end
        return
    end
    
    for player, esp in pairs(ESPObjects) do
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head")
            
            local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
            
            if distance <= Config.ESP.MaxDistance then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    
                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height / 2
                    
                    if Config.ESP.Boxes then
                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
                        esp.Box.Visible = true
                    else
                        esp.Box.Visible = false
                    end
                    
                    if Config.ESP.Names then
                        esp.Name.Text = player.Name
                        esp.Name.Position = Vector2.new(screenPos.X, screenPos.Y - height / 2 - 15)
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    if Config.ESP.Distance then
                        esp.Distance.Text = math.floor(distance) .. "m"
                        esp.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + height / 2 + 5)
                        esp.Distance.Visible = true
                    else
                        esp.Distance.Visible = false
                    end
                else
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                    esp.Distance.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
        end
    end
end

-- Initialize ESP for all players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Watermark
local WatermarkText = Drawing.new("Text")
WatermarkText.Text = "wezzy v1.0 | FPS: 0"
WatermarkText.Size = 16
WatermarkText.Center = false
WatermarkText.Outline = true
WatermarkText.Position = Vector2.new(10, 10)
WatermarkText.Color = Color3.fromRGB(255, 255, 255)
WatermarkText.Visible = Config.Watermark.Enabled
WatermarkText.ZIndex = 999

local lastUpdate = tick()
local fps = 60

-- Visuals Functions
local function ApplyFullbright()
    if Config.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end
end

local function ApplyNoFog()
    if Config.Visuals.NoFog then
        Lighting.FogEnd = 100000
    end
end

-- Simple GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WezzyGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Title.BorderSizePixel = 0
Title.Text = "wezzy v1.0"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, -20, 1, -60)
ContentFrame.Position = UDim2.new(0, 10, 0, 50)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 6
ContentFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ContentFrame

-- Function to create toggles
local function CreateToggle(name, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = name
    ToggleFrame.Size = UDim2.new(1, -10, 0, 35)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = ContentFrame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleFrame
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, -45, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = name
    ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleLabel.Font = Enum.Font.Gotham
    ToggleLabel.TextSize = 14
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = ToggleFrame
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 50, 0, 25)
    ToggleButton.Position = UDim2.new(1, -60, 0.5, -12.5)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    ToggleButton.Text = "OFF"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 12
    ToggleButton.Parent = ToggleFrame
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 4)
    ButtonCorner.Parent = ToggleButton
    
    local enabled = false
    
    ToggleButton.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            ToggleButton.Text = "ON"
        else
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
            ToggleButton.Text = "OFF"
        end
        callback(enabled)
    end)
    
    return ToggleFrame
end

-- Create toggles
CreateToggle("ESP Boxes", function(enabled)
    Config.ESP.Boxes = enabled
end)

CreateToggle("ESP Names", function(enabled)
    Config.ESP.Names = enabled
end)

CreateToggle("ESP Distance", function(enabled)
    Config.ESP.Distance = enabled
end)

CreateToggle("Enable Aimbot", function(enabled)
    Config.Aimbot.Enabled = enabled
    if enabled and not GameFunctions.entitylist then
        print("-- [wezzy] Aimbot requires game functions!")
    end
end)

CreateToggle("Fullbright", function(enabled)
    Config.Visuals.Fullbright = enabled
    ApplyFullbright()
end)

CreateToggle("No Fog", function(enabled)
    Config.Visuals.NoFog = enabled
    ApplyNoFog()
end)

CreateToggle("Watermark", function(enabled)
    Config.Watermark.Enabled = enabled
    WatermarkText.Visible = enabled
end)

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Toggle GUI with RightShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    UpdateESP()
    
    -- Update FPS
    if tick() - lastUpdate >= 1 then
        fps = math.floor(1 / RunService.RenderStepped:Wait())
        WatermarkText.Text = "wezzy v1.0 | FPS: " .. tostring(fps)
        lastUpdate = tick()
    end
    
    -- Apply visuals
    if Config.Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    end
    
    if Config.Visuals.NoFog then
        Lighting.FogEnd = 100000
    end
end)

print("-- [wezzy] Loaded successfully!")
print("-- [wezzy] ESP is now active!")
print("-- [wezzy] Press RightShift to toggle GUI")
print("==========================================")
print("-- wezzy v1.0")
print("-- ESP: Active")
print("-- Aimbot: " .. (GameFunctions.entitylist and "Active" or "Disabled (requires game functions)"))
print("-- Watermark: Visible")
print("-- Game Functions: " .. (GameFunctions.entitylist and "Connected" or "Scanning in background..."))
print("==========================================")
