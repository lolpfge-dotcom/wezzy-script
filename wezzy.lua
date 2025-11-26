--[[
    ╦ ╦╔═╗╔═╗╔═╗╦ ╦
    ║║║║╣ ╔═╝╔═╝╚╦╝
    ╚╩╝╚═╝╚═╝╚═╝ ╩  v1.0
    
    Trident Survival Script - Full Version
    Load with: loadstring(game:HttpGet("YOUR_GITHUB_URL"))()
]]

-- Complete wezzy script with all features from original swimhub base

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

-- Compatibility layer
local getgc = getgc or debug.getgc or function() return {} end
local getupvalues = getupvalues or debug.getupvalues or function() return {} end
local getconstants = getconstants or debug.getconstants or function() return {} end
local getinfo = getinfo or debug.getinfo or function() return {} end

-- Configuration
local wezzy = {
    version = "1.0",
    folder = "wezzy/files/",
    ui = {},
    esp = {},
    aimbot = {},
    misc = {},
    connections = {},
    gameFunctions = {}
}

-- Game function scanner
print("-- [wezzy] Scanning for game functions...")

local function scanGameFunctions()
    local success, err = pcall(function()
        local gc = getgc(true)
        local required = {"character", "entitylist", "maxlooky", "equippeditem", "recoil"}
        local found = {}
        
        for _, obj in pairs(gc) do
            if type(obj) == "function" then
                local info = getinfo(obj)
                if info and info.name then
                    local constants = getconstants(obj)
                    
                    -- Scan for character function
                    if not found.character then
                        for _, const in pairs(constants) do
                            if const == "Character" or const == "character" then
                                found.character = obj
                                break
                            end
                        end
                    end
                    
                    -- Scan for entitylist
                    if not found.entitylist then
                        for _, const in pairs(constants) do
                            if const == "EntityList" or const == "entitylist" or const == "Entities" then
                                found.entitylist = obj
                                break
                            end
                        end
                    end
                    
                    -- Scan for maxlooky (camera constraints)
                    if not found.maxlooky then
                        for _, const in pairs(constants) do
                            if const == "MaxLook" or const == "maxlook" or const == "LookLimit" then
                                found.maxlooky = obj
                                break
                            end
                        end
                    end
                    
                    -- Scan for equipped item
                    if not found.equippeditem then
                        for _, const in pairs(constants) do
                            if const == "EquippedItem" or const == "equipped" or const == "CurrentWeapon" then
                                found.equippeditem = obj
                                break
                            end
                        end
                    end
                    
                    -- Scan for recoil
                    if not found.recoil then
                        for _, const in pairs(constants) do
                            if const == "Recoil" or const == "recoil" or const == "WeaponRecoil" then
                                found.recoil = obj
                                break
                            end
                        end
                    end
                end
            elseif type(obj) == "table" then
                -- Scan tables for entity lists and character data
                if not found.entitylist and (obj.Entities or obj.EntityList or obj.Players) then
                    found.entitylist = obj
                end
            end
        end
        
        wezzy.gameFunctions = found
        
        -- Report findings
        for _, fname in pairs(required) do
            if found[fname] then
                print("-- [wezzy] ✓ Found:", fname)
            else
                warn("-- [wezzy] ✗ Missing:", fname)
            end
        end
        
        return found
    end)
    
    if not success then
        warn("-- [wezzy] Function scan failed:", err)
    end
end

-- Run the scan
scanGameFunctions()

-- ESP System
local ESPLibrary = {}
ESPLibrary.__index = ESPLibrary

function ESPLibrary.new()
    local self = setmetatable({}, ESPLibrary)
    self.objects = {}
    self.enabled = true
    self.settings = {
        box = true,
        boxFill = false,
        name = true,
        distance = true,
        weapon = true,
        skeleton = false,
        chams = false,
        teamCheck = false,
        sleeper = true,
        maxDistance = 1000
    }
    return self
end

function ESPLibrary:CreateDrawing(type)
    local drawing = Drawing.new(type)
    return drawing
end

function ESPLibrary:AddPlayer(player)
    if self.objects[player] then return end
    
    local obj = {
        player = player,
        drawings = {},
        chams = nil
    }
    
    -- Create drawings
    obj.drawings.box = self:CreateDrawing("Square")
    obj.drawings.box.Thickness = 2
    obj.drawings.box.Filled = false
    obj.drawings.box.Color = Color3.fromRGB(255, 255, 255)
    obj.drawings.box.Visible = false
    obj.drawings.box.ZIndex = 2
    
    obj.drawings.boxFill = self:CreateDrawing("Square")
    obj.drawings.boxFill.Thickness = 1
    obj.drawings.boxFill.Filled = true
    obj.drawings.boxFill.Color = Color3.fromRGB(255, 255, 255)
    obj.drawings.boxFill.Transparency = 0.3
    obj.drawings.boxFill.Visible = false
    obj.drawings.boxFill.ZIndex = 1
    
    obj.drawings.name = self:CreateDrawing("Text")
    obj.drawings.name.Size = 16
    obj.drawings.name.Center = true
    obj.drawings.name.Outline = true
    obj.drawings.name.Color = Color3.fromRGB(255, 255, 255)
    obj.drawings.name.Visible = false
    obj.drawings.name.ZIndex = 3
    
    obj.drawings.distance = self:CreateDrawing("Text")
    obj.drawings.distance.Size = 14
    obj.drawings.distance.Center = true
    obj.drawings.distance.Outline = true
    obj.drawings.distance.Color = Color3.fromRGB(200, 200, 200)
    obj.drawings.distance.Visible = false
    obj.drawings.distance.ZIndex = 3
    
    obj.drawings.weapon = self:CreateDrawing("Text")
    obj.drawings.weapon.Size = 14
    obj.drawings.weapon.Center = true
    obj.drawings.weapon.Outline = true
    obj.drawings.weapon.Color = Color3.fromRGB(255, 200, 100)
    obj.drawings.weapon.Visible = false
    obj.drawings.weapon.ZIndex = 3
    
    self.objects[player] = obj
end

function ESPLibrary:RemovePlayer(player)
    local obj = self.objects[player]
    if not obj then return end
    
    for _, drawing in pairs(obj.drawings) do
        drawing:Remove()
    end
    
    if obj.chams then
        obj.chams:Destroy()
    end
    
    self.objects[player] = nil
end

function ESPLibrary:Update()
    if not self.enabled then return end
    
    for player, obj in pairs(self.objects) do
        local success = pcall(function()
            if not player or not player.Parent or not player.Character then
                self:RemovePlayer(player)
                return
            end
            
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if not humanoid or not rootPart or humanoid.Health <= 0 then
                for _, drawing in pairs(obj.drawings) do
                    drawing.Visible = false
                end
                return
            end
            
            local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) 
                and (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude or 9999
            
            if distance > self.settings.maxDistance then
                for _, drawing in pairs(obj.drawings) do
                    drawing.Visible = false
                end
                return
            end
            
            local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                local head = character:FindFirstChild("Head")
                local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                
                if headPos and legPos then
                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height / 2
                    
                    -- Box
                    if self.settings.box then
                        obj.drawings.box.Size = Vector2.new(width, height)
                        obj.drawings.box.Position = Vector2.new(vector.X - width / 2, headPos.Y)
                        obj.drawings.box.Visible = true
                    else
                        obj.drawings.box.Visible = false
                    end
                    
                    -- Box Fill
                    if self.settings.boxFill then
                        obj.drawings.boxFill.Size = Vector2.new(width, height)
                        obj.drawings.boxFill.Position = Vector2.new(vector.X - width / 2, headPos.Y)
                        obj.drawings.boxFill.Visible = true
                    else
                        obj.drawings.boxFill.Visible = false
                    end
                    
                    -- Name
                    if self.settings.name then
                        obj.drawings.name.Text = player.Name
                        obj.drawings.name.Position = Vector2.new(vector.X, headPos.Y - 20)
                        obj.drawings.name.Visible = true
                    else
                        obj.drawings.name.Visible = false
                    end
                    
                    -- Distance
                    if self.settings.distance then
                        obj.drawings.distance.Text = math.floor(distance) .. "m"
                        obj.drawings.distance.Position = Vector2.new(vector.X, legPos.Y + 5)
                        obj.drawings.distance.Visible = true
                    else
                        obj.drawings.distance.Visible = false
                    end
                    
                    -- Weapon
                    if self.settings.weapon then
                        local tool = character:FindFirstChildOfClass("Tool")
                        if tool then
                            obj.drawings.weapon.Text = tool.Name
                            obj.drawings.weapon.Position = Vector2.new(vector.X, legPos.Y + 20)
                            obj.drawings.weapon.Visible = true
                        else
                            obj.drawings.weapon.Visible = false
                        end
                    else
                        obj.drawings.weapon.Visible = false
                    end
                end
            else
                for _, drawing in pairs(obj.drawings) do
                    drawing.Visible = false
                end
            end
        end)
        
        if not success then
            self:RemovePlayer(player)
        end
    end
end

-- Initialize ESP
wezzy.esp.library = ESPLibrary.new()

-- Add all players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        wezzy.esp.library:AddPlayer(player)
    end
end

-- Player connections
Players.PlayerAdded:Connect(function(player)
    wezzy.esp.library:AddPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    wezzy.esp.library:RemovePlayer(player)
end)

-- Aimbot System
wezzy.aimbot.enabled = false
wezzy.aimbot.fov = 100
wezzy.aimbot.silent = true
wezzy.aimbot.visibleCheck = true
wezzy.aimbot.teamCheck = false

function wezzy.aimbot:GetClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local head = character:FindFirstChild("Head")
            
            if humanoid and head and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    if distance < self.fov and distance < shortestDistance then
                        if self.visibleCheck then
                            local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 500)
                            local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
                            
                            if hit and hit:IsDescendantOf(character) then
                                closest = player
                                shortestDistance = distance
                            end
                        else
                            closest = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

-- Watermark System
local watermarkFrame = Instance.new("ScreenGui")
watermarkFrame.Name = "wezzyWatermark"
watermarkFrame.ResetOnSpawn = false
watermarkFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local watermarkLabel = Instance.new("TextLabel")
watermarkLabel.Size = UDim2.new(0, 200, 0, 30)
watermarkLabel.Position = UDim2.new(0, 10, 0, 10)
watermarkLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
watermarkLabel.BackgroundTransparency = 0.3
watermarkLabel.BorderSizePixel = 0
watermarkLabel.Font = Enum.Font.Code
watermarkLabel.TextSize = 14
watermarkLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
watermarkLabel.TextStrokeTransparency = 0.5
watermarkLabel.Parent = watermarkFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 4)
corner.Parent = watermarkLabel

watermarkFrame.Parent = CoreGui

-- Update watermark
local fps = 0
local lastTime = tick()
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    if tick() - lastTime >= 1 then
        fps = frameCount
        frameCount = 0
        lastTime = tick()
    end
    
    local timeStr = os.date("%H:%M:%S")
    watermarkLabel.Text = string.format("wezzy v%s | %d FPS | %s", wezzy.version, fps, timeStr)
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    wezzy.esp.library:Update()
end)

print("-- [wezzy] Loaded successfully!")
print("-- [wezzy] All features active")
warn("========================================")
warn("wezzy v" .. wezzy.version)
warn("ESP: Active")
warn("Aimbot: " .. (wezzy.aimbot.enabled and "Enabled" or "Disabled"))
warn("Watermark: Visible")
warn("Game Functions: " .. (wezzy.gameFunctions.character and "Connected" or "Searching..."))
warn("========================================")
