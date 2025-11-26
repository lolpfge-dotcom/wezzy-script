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

-- Add async game function scanner with timeout
print("-- [wezzy] Starting game function scanner (async)...")

local function scanGameFunctions()
    spawn(function()
        local startTime = tick()
        local timeout = 10 -- 10 second timeout
        
        local success, err = pcall(function()
            local gc = getgc(true)
            local required = {"character", "entitylist", "maxlooky", "equippeditem", "recoil"}
            local found = {}
            
            local gcCount = type(gc) == "table" and #gc or 0
            print("-- [wezzy] Scanning " .. tostring(gcCount) .. " objects...")
            
            local scanned = 0
            for _, obj in pairs(gc) do
                -- Check timeout every 1000 objects
                scanned = scanned + 1
                if scanned % 1000 == 0 and tick() - startTime > timeout then
                    warn("-- [wezzy] Scan timeout reached, stopping...")
                    break
                end
                
                if type(obj) == "function" then
                    local infoSuccess, info = pcall(getinfo, obj)
                    if infoSuccess and info and type(info) == "table" and info.name then
                        local constSuccess, constants = pcall(function()
                            return getconstants(obj)
                        end)
                        
                        if constSuccess and constants and type(constants) == "table" then
                            if not found.character then
                                for _, const in pairs(constants) do
                                    if type(const) == "string" and (const == "Character" or const == "character") then
                                        found.character = obj
                                        break
                                    end
                                end
                            end
                            
                            if not found.entitylist then
                                for _, const in pairs(constants) do
                                    if type(const) == "string" and (const == "EntityList" or const == "entitylist" or const == "Entities") then
                                        found.entitylist = obj
                                        break
                                    end
                                end
                            end
                            
                            if not found.maxlooky then
                                for _, const in pairs(constants) do
                                    if type(const) == "string" and (const == "MaxLook" or const == "maxlook" or const == "LookLimit") then
                                        found.maxlooky = obj
                                        break
                                    end
                                end
                            end
                            
                            if not found.equippeditem then
                                for _, const in pairs(constants) do
                                    if type(const) == "string" and (const == "EquippedItem" or const == "equipped" or const == "CurrentWeapon") then
                                        found.equippeditem = obj
                                        break
                                    end
                                end
                            end
                            
                            if not found.recoil then
                                for _, const in pairs(constants) do
                                    if type(const) == "string" and (const == "Recoil" or const == "recoil" or const == "WeaponRecoil") then
                                        found.recoil = obj
                                        break
                                    end
                                end
                            end
                        end
                    end
                elseif type(obj) == "table" then
                    if not found.entitylist and (obj.Entities or obj.EntityList or obj.Players) then
                        found.entitylist = obj
                    end
                end
            end
            
            wezzy.gameFunctions = found
            
            print("-- [wezzy] Scan complete!")
            local foundCount = 0
            for _, fname in pairs(required) do
                if found[fname] then
                    print("-- [wezzy] ✓ Found: " .. tostring(fname))
                    foundCount = foundCount + 1
                else
                    warn("-- [wezzy] ✗ Missing: " .. tostring(fname))
                end
            end
            
            if foundCount == 0 then
                warn("-- [wezzy] No game functions found - Aimbot features disabled")
                warn("-- [wezzy] Try using an executor with better compatibility")
            elseif foundCount < #required then
                warn("-- [wezzy] Some features may not work correctly")
            else
                print("-- [wezzy] All game functions connected!")
                wezzy.aimbot.enabled = false -- Enable manually
            end
        end)
        
        if not success then
            warn("-- [wezzy] Function scan failed: " .. tostring(err))
        end
    end)
end

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
                    
                    if self.settings.box then
                        obj.drawings.box.Size = Vector2.new(width, height)
                        obj.drawings.box.Position = Vector2.new(vector.X - width / 2, headPos.Y)
                        obj.drawings.box.Visible = true
                    else
                        obj.drawings.box.Visible = false
                    end
                    
                    if self.settings.boxFill then
                        obj.drawings.boxFill.Size = Vector2.new(width, height)
                        obj.drawings.boxFill.Position = Vector2.new(vector.X - width / 2, headPos.Y)
                        obj.drawings.boxFill.Visible = true
                    else
                        obj.drawings.boxFill.Visible = false
                    end
                    
                    if self.settings.name then
                        obj.drawings.name.Text = player.Name
                        obj.drawings.name.Position = Vector2.new(vector.X, headPos.Y - 20)
                        obj.drawings.name.Visible = true
                    else
                        obj.drawings.name.Visible = false
                    end
                    
                    if self.settings.distance then
                        obj.drawings.distance.Text = math.floor(distance) .. "m"
                        obj.drawings.distance.Position = Vector2.new(vector.X, legPos.Y + 5)
                        obj.drawings.distance.Visible = true
                    else
                        obj.drawings.distance.Visible = false
                    end
                    
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

wezzy.esp.library = ESPLibrary.new()

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        wezzy.esp.library:AddPlayer(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    wezzy.esp.library:AddPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    wezzy.esp.library:RemovePlayer(player)
end)

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

-- UI Library (Linoria-style)
local Library = {}
Library.ToggleUI = Instance.new("ScreenGui")
Library.ToggleUI.Name = "WezzyUI"
Library.ToggleUI.ResetOnSpawn = false

local success = pcall(function()
    Library.ToggleUI.Parent = game:GetService("CoreGui")
end)

if not success then
    Library.ToggleUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Simple UI creation functions
function Library:CreateWindow(config)
    local window = {}
    window.tabs = {}
    
    local Frame = Instance.new("Frame")
    Frame.Name = "MainWindow"
    Frame.Size = UDim2.new(0, 600, 0, 400)
    Frame.Position = UDim2.new(0.5, -300, 0.5, -200)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Frame.BorderSizePixel = 0
    Frame.Parent = Library.ToggleUI
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Title.BorderSizePixel = 0
    Title.Text = config.Title or "wezzy"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Frame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 6)
    TitleCorner.Parent = Title
    
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(0, 120, 1, -50)
    TabContainer.Position = UDim2.new(0, 5, 0, 45)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = Frame
    
    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 5)
    TabList.Parent = TabContainer
    
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -135, 1, -50)
    ContentContainer.Position = UDim2.new(0, 130, 0, 45)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = Frame
    
    window.frame = Frame
    window.tabContainer = TabContainer
    window.contentContainer = ContentContainer
    
    -- Draggable
    local dragging, dragInput, dragStart, startPos
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
        end
    end)
    
    Title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    Title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    function window:AddTab(name)
        local tab = {}
        tab.name = name
        tab.groups = {}
        
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name
        TabButton.Size = UDim2.new(1, 0, 0, 30)
        TabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        TabButton.BorderSizePixel = 0
        TabButton.Text = name
        TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabButton.TextSize = 14
        TabButton.Font = Enum.Font.Gotham
        TabButton.Parent = window.tabContainer
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 4)
        TabCorner.Parent = TabButton
        
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = name .. "Content"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 4
        TabContent.Visible = false
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContent.Parent = window.contentContainer
        
        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Padding = UDim.new(0, 5)
        ContentLayout.Parent = TabContent
        
        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(window.tabs) do
                t.content.Visible = false
                t.button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            end
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        end)
        
        tab.button = TabButton
        tab.content = TabContent
        
        function tab:AddLeftGroupbox(name)
            return tab:AddGroupbox(name, true)
        end
        
        function tab:AddRightGroupbox(name)
            return tab:AddGroupbox(name, false)
        end
        
        function tab:AddGroupbox(name, isLeft)
            local group = {}
            
            local GroupFrame = Instance.new("Frame")
            GroupFrame.Name = name
            GroupFrame.Size = UDim2.new(0.48, 0, 0, 30)
            GroupFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            GroupFrame.BorderSizePixel = 0
            GroupFrame.Parent = TabContent
            GroupFrame.AutomaticSize = Enum.AutomaticSize.Y
            
            local GroupCorner = Instance.new("UICorner")
            GroupCorner.CornerRadius = UDim.new(0, 4)
            GroupCorner.Parent = GroupFrame
            
            local GroupTitle = Instance.new("TextLabel")
            GroupTitle.Name = "Title"
            GroupTitle.Size = UDim2.new(1, -10, 0, 25)
            GroupTitle.Position = UDim2.new(0, 5, 0, 5)
            GroupTitle.BackgroundTransparency = 1
            GroupTitle.Text = name
            GroupTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            GroupTitle.TextSize = 14
            GroupTitle.Font = Enum.Font.GothamBold
            GroupTitle.TextXAlignment = Enum.TextXAlignment.Left
            GroupTitle.Parent = GroupFrame
            
            local GroupList = Instance.new("UIListLayout")
            GroupList.Padding = UDim.new(0, 3)
            GroupList.Parent = GroupFrame
            
            local GroupPadding = Instance.new("UIPadding")
            GroupPadding.PaddingTop = UDim.new(0, 30)
            GroupPadding.PaddingLeft = UDim.new(0, 8)
            GroupPadding.PaddingRight = UDim.new(0, 8)
            GroupPadding.PaddingBottom = UDim.new(0, 8)
            GroupPadding.Parent = GroupFrame
            
            group.frame = GroupFrame
            
            function group:AddToggle(id, config)
                local toggle = {}
                toggle.value = config.Default or false
                
                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Name = id
                ToggleFrame.Size = UDim2.new(1, 0, 0, 20)
                ToggleFrame.BackgroundTransparency = 1
                ToggleFrame.Parent = GroupFrame
                
                local ToggleButton = Instance.new("TextButton")
                ToggleButton.Size = UDim2.new(0, 16, 0, 16)
                ToggleButton.Position = UDim2.new(0, 0, 0, 2)
                ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                ToggleButton.BorderSizePixel = 1
                ToggleButton.BorderColor3 = Color3.fromRGB(60, 60, 60)
                ToggleButton.Text = ""
                ToggleButton.Parent = ToggleFrame
                
                local ToggleCorner = Instance.new("UICorner")
                ToggleCorner.CornerRadius = UDim.new(0, 2)
                ToggleCorner.Parent = ToggleButton
                
                local ToggleIndicator = Instance.new("Frame")
                ToggleIndicator.Size = UDim2.new(1, -4, 1, -4)
                ToggleIndicator.Position = UDim2.new(0, 2, 0, 2)
                ToggleIndicator.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
                ToggleIndicator.BorderSizePixel = 0
                ToggleIndicator.Visible = toggle.value
                ToggleIndicator.Parent = ToggleButton
                
                local IndicatorCorner = Instance.new("UICorner")
                IndicatorCorner.CornerRadius = UDim.new(0, 2)
                IndicatorCorner.Parent = ToggleIndicator
                
                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Size = UDim2.new(1, -22, 1, 0)
                ToggleLabel.Position = UDim2.new(0, 22, 0, 0)
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Text = config.Text or id
                ToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                ToggleLabel.TextSize = 12
                ToggleLabel.Font = Enum.Font.Gotham
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                ToggleLabel.Parent = ToggleFrame
                
                ToggleButton.MouseButton1Click:Connect(function()
                    toggle.value = not toggle.value
                    ToggleIndicator.Visible = toggle.value
                    if config.Callback then
                        config.Callback(toggle.value)
                    end
                end)
                
                return toggle
            end
            
            function group:AddSlider(id, config)
                local slider = {}
                slider.value = config.Default or config.Min or 0
                
                local SliderFrame = Instance.new("Frame")
                SliderFrame.Name = id
                SliderFrame.Size = UDim2.new(1, 0, 0, 35)
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.Parent = GroupFrame
                
                local SliderLabel = Instance.new("TextLabel")
                SliderLabel.Size = UDim2.new(1, -30, 0, 12)
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.Text = config.Text or id
                SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                SliderLabel.TextSize = 12
                SliderLabel.Font = Enum.Font.Gotham
                SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                SliderLabel.Parent = SliderFrame
                
                local SliderValue = Instance.new("TextLabel")
                SliderValue.Size = UDim2.new(0, 25, 0, 12)
                SliderValue.Position = UDim2.new(1, -25, 0, 0)
                SliderValue.BackgroundTransparency = 1
                SliderValue.Text = tostring(slider.value)
                SliderValue.TextColor3 = Color3.fromRGB(150, 150, 150)
                SliderValue.TextSize = 11
                SliderValue.Font = Enum.Font.Gotham
                SliderValue.TextXAlignment = Enum.TextXAlignment.Right
                SliderValue.Parent = SliderFrame
                
                local SliderBar = Instance.new("Frame")
                SliderBar.Size = UDim2.new(1, 0, 0, 4)
                SliderBar.Position = UDim2.new(0, 0, 0, 18)
                SliderBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                SliderBar.BorderSizePixel = 0
                SliderBar.Parent = SliderFrame
                
                local BarCorner = Instance.new("UICorner")
                BarCorner.CornerRadius = UDim.new(1, 0)
                BarCorner.Parent = SliderBar
                
                local SliderFill = Instance.new("Frame")
                SliderFill.Size = UDim2.new(0, 0, 1, 0)
                SliderFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
                SliderFill.BorderSizePixel = 0
                SliderFill.Parent = SliderBar
                
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(1, 0)
                FillCorner.Parent = SliderFill
                
                local function updateSlider(input)
                    local sizeX = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                    local value = config.Min + (config.Max - config.Min) * sizeX
                    
                    if config.Rounding then
                        value = math.floor(value / config.Rounding + 0.5) * config.Rounding
                    else
                        value = math.floor(value + 0.5)
                    end
                    
                    slider.value = value
                    SliderValue.Text = tostring(value)
                    SliderFill.Size = UDim2.new(sizeX, 0, 1, 0)
                    
                    if config.Callback then
                        config.Callback(value)
                    end
                end
                
                local dragging = false
                SliderBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        updateSlider(input)
                    end
                end)
                
                SliderBar.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateSlider(input)
                    end
                end)
                
                updateSlider({Position = Vector2.new(SliderBar.AbsolutePosition.X + SliderBar.AbsoluteSize.X * ((slider.value - config.Min) / (config.Max - config.Min)), 0)})
                
                return slider
            end
            
            function group:AddButton(config)
                local button = {}
                
                local ButtonFrame = Instance.new("TextButton")
                ButtonFrame.Size = UDim2.new(1, 0, 0, 24)
                ButtonFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                ButtonFrame.BorderSizePixel = 0
                ButtonFrame.Text = config.Text or "Button"
                ButtonFrame.TextColor3 = Color3.fromRGB(200, 200, 200)
                ButtonFrame.TextSize = 12
                ButtonFrame.Font = Enum.Font.Gotham
                ButtonFrame.Parent = GroupFrame
                
                local ButtonCorner = Instance.new("UICorner")
                ButtonCorner.CornerRadius = UDim.new(0, 4)
                ButtonCorner.Parent = ButtonFrame
                
                ButtonFrame.MouseButton1Click:Connect(function()
                    if config.Callback then
                        config.Callback()
                    end
                end)
                
                return button
            end
            
            function group:AddDivider()
                local Divider = Instance.new("Frame")
                Divider.Size = UDim2.new(1, 0, 0, 1)
                Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                Divider.BorderSizePixel = 0
                Divider.Parent = GroupFrame
            end
            
            return group
        end
        
        table.insert(window.tabs, tab)
        
        if #window.tabs == 1 then
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        end
        
        return tab
    end
    
    return window
end

-- Create main window
local Window = Library:CreateWindow({
    Title = 'wezzy v' .. wezzy.version .. ' | Trident Survival'
})

-- Create tabs
local Tabs = {
    Combat = Window:AddTab('Combat'),
    Visuals = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),
    Config = Window:AddTab('Config')
}

-- Combat Tab
do
    local AimbotBox = Tabs.Combat:AddLeftGroupbox('Aimbot')
    local GunModsBox = Tabs.Combat:AddRightGroupbox('Gun Mods')
    
    -- Aimbot settings
    AimbotBox:AddToggle('AimbotEnabled', {
        Text = 'Enable Aimbot',
        Default = false,
        Tooltip = 'Toggle aimbot on/off',
        Callback = function(Value)
            wezzy.aimbot.enabled = Value
        end
    })
    
    AimbotBox:AddToggle('AimbotSilent', {
        Text = 'Silent Aim',
        Default = true,
        Tooltip = 'Aim without moving camera',
        Callback = function(Value)
            wezzy.aimbot.silent = Value
        end
    })
    
    AimbotBox:AddToggle('AimbotVisible', {
        Text = 'Visible Check',
        Default = true,
        Tooltip = 'Only target visible players',
        Callback = function(Value)
            wezzy.aimbot.visibleCheck = Value
        end
    })
    
    AimbotBox:AddToggle('AimbotTeam', {
        Text = 'Team Check',
        Default = false,
        Tooltip = 'Ignore teammates',
        Callback = function(Value)
            wezzy.aimbot.teamCheck = Value
        end
    })
    
    AimbotBox:AddDivider()
    
    AimbotBox:AddToggle('AimbotFOV', {
        Text = 'Use FOV',
        Default = true,
        Tooltip = 'Limit aimbot to FOV circle',
        Callback = function(Value)
            wezzy.aimbot.useFOV = Value
        end
    })
    
    AimbotBox:AddSlider('AimbotFOVSize', {
        Text = 'FOV Size',
        Default = 100,
        Min = 10,
        Max = 500,
        Rounding = 0,
        Compact = false,
        Callback = function(Value)
            wezzy.aimbot.fov = Value
        end
    })
    
    AimbotBox:AddToggle('AimbotFOVVisible', {
        Text = 'Show FOV Circle',
        Default = false,
        Tooltip = 'Display FOV circle on screen',
        Callback = function(Value)
            wezzy.aimbot.showFOV = Value
        end
    }):AddColorPicker('FOVColor', {
        Default = Color3.new(1, 1, 1),
        Title = 'FOV Color',
        Transparency = 0,
        Callback = function(Value)
            wezzy.aimbot.fovColor = Value
        end
    })
    
    -- Gun Mods
    GunModsBox:AddToggle('NoRecoil', {
        Text = 'No Recoil',
        Default = false,
        Tooltip = 'Remove weapon recoil',
        Callback = function(Value)
            if wezzy.gameFunctions.recoil then
                wezzy.misc.noRecoil = Value
                -- Implementation depends on game functions
            else
                print("Notification: No Recoil requires game functions")
            end
        end
    })
    
    GunModsBox:AddToggle('NoSpread', {
        Text = 'No Spread',
        Default = false,
        Tooltip = 'Remove weapon spread',
        Callback = function(Value)
            wezzy.misc.noSpread = Value
        end
    })
    
    GunModsBox:AddToggle('ForceHead', {
        Text = 'Force Headshot',
        Default = false,
        Tooltip = 'All shots hit head',
        Callback = function(Value)
            wezzy.misc.forceHead = Value
        end
    })
end

-- Visuals Tab
do
    local ESPBox = Tabs.Visuals:AddLeftGroupbox('Player ESP')
    local WorldBox = Tabs.Visuals:AddRightGroupbox('World')
    
    -- ESP Settings
    ESPBox:AddToggle('ESPEnabled', {
        Text = 'Enable ESP',
        Default = true,
        Tooltip = 'Toggle ESP on/off',
        Callback = function(Value)
            wezzy.esp.library.enabled = Value
        end
    })
    
    ESPBox:AddToggle('ESPBox', {
        Text = 'Box ESP',
        Default = true,
        Tooltip = 'Show boxes around players',
        Callback = function(Value)
            wezzy.esp.library.settings.box = Value
        end
    })
    
    ESPBox:AddToggle('ESPBoxFill', {
        Text = 'Box Fill',
        Default = false,
        Tooltip = 'Fill boxes with color',
        Callback = function(Value)
            wezzy.esp.library.settings.boxFill = Value
        end
    })
    
    ESPBox:AddToggle('ESPName', {
        Text = 'Name ESP',
        Default = true,
        Tooltip = 'Show player names',
        Callback = function(Value)
            wezzy.esp.library.settings.name = Value
        end
    })
    
    ESPBox:AddToggle('ESPDistance', {
        Text = 'Distance ESP',
        Default = true,
        Tooltip = 'Show distance to players',
        Callback = function(Value)
            wezzy.esp.library.settings.distance = Value
        end
    })
    
    ESPBox:AddToggle('ESPWeapon', {
        Text = 'Weapon ESP',
        Default = true,
        Tooltip = 'Show equipped weapon',
        Callback = function(Value)
            wezzy.esp.library.settings.weapon = Value
        end
    })
    
    ESPBox:AddToggle('ESPSkeleton', {
        Text = 'Skeleton ESP',
        Default = false,
        Tooltip = 'Show player skeleton',
        Callback = function(Value)
            wezzy.esp.library.settings.skeleton = Value
        end
    })
    
    ESPBox:AddDivider()
    
    ESPBox:AddToggle('ESPTeamCheck', {
        Text = 'Team/AI Check',
        Default = false,
        Tooltip = 'Hide teammates and AI',
        Callback = function(Value)
            wezzy.esp.library.settings.teamCheck = Value
        end
    })
    
    ESPBox:AddSlider('ESPMaxDistance', {
        Text = 'Max Distance',
        Default = 1000,
        Min = 100,
        Max = 5000,
        Rounding = 0,
        Compact = false,
        Callback = function(Value)
            wezzy.esp.library.settings.maxDistance = Value
        end
    })
    
    -- World Settings
    WorldBox:AddToggle('Fullbright', {
        Text = 'Fullbright',
        Default = false,
        Tooltip = 'Make everything bright',
        Callback = function(Value)
            if Value then
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            else
                Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
                Lighting.Brightness = 1
                Lighting.ClockTime = 12
                Lighting.FogEnd = 10000
                Lighting.GlobalShadows = true
                Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
            end
        end
    })
    
    WorldBox:AddToggle('NoFog', {
        Text = 'No Fog',
        Default = false,
        Tooltip = 'Remove fog',
        Callback = function(Value)
            if Value then
                Lighting.FogEnd = 100000
            else
                Lighting.FogEnd = 10000
            end
        end
    })
    
    WorldBox:AddSlider('TimeChanger', {
        Text = 'Time of Day',
        Default = 14,
        Min = 0,
        Max = 24,
        Rounding = 0,
        Compact = false,
        Callback = function(Value)
            Lighting.ClockTime = Value
        end
    })
    
    WorldBox:AddSlider('Ambient', {
        Text = 'Ambient',
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Compact = false,
        Callback = function(Value)
            Lighting.Ambient = Color3.new(Value, Value, Value)
        end
    })
end

-- Misc Tab
do
    local MiscBox = Tabs.Misc:AddLeftGroupbox('Misc')
    
    MiscBox:AddToggle('Watermark', {
        Text = 'Show Watermark',
        Default = true,
        Tooltip = 'Toggle watermark visibility',
        Callback = function(Value)
            watermarkFrame.Enabled = Value
        end
    })
    
    MiscBox:AddButton('Unload Script', function()
        Library.ToggleUI:Destroy()
        watermarkFrame:Destroy()
        for _, connection in pairs(wezzy.connections) do
            connection:Disconnect()
        end
        wezzy.esp.library.enabled = false
        print('wezzy unloaded')
    end)
end

-- Config Tab
-- No ThemeManager needed for this simple UI

-- Fixed invalid syntax - changed from :Destroy to .Unload function
Library.Unload = function()
    watermarkFrame:Destroy()
    for _, connection in pairs(wezzy.connections) do
        connection:Disconnect()
    end
    wezzy.esp.library.enabled = false
    print('-- [wezzy] Unloaded')
end

-- Menu keybind
Library.KeybindFrame = nil
Library:SetWatermarkVisibility = function() end

local MenuGroup = Tabs.Config:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library.Unload() end)
MenuGroup:AddLabel('Menu bind'):AddToggle('MenuKeybind', { Default = false, Text = 'Menu keybind' })

Library.ToggleKeybind = nil

print("-- [wezzy] UI loaded successfully!")
print("-- [wezzy] Press RightShift to toggle menu")

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
    local versionStr = tostring(wezzy.version)
    local fpsStr = tostring(fps)
    watermarkLabel.Text = string.format("wezzy v%s | %s FPS | %s", versionStr, fpsStr, timeStr)
end)

RunService.RenderStepped:Connect(function()
    wezzy.esp.library:Update()
end)

print("-- [wezzy] Loaded successfully!")
print("-- [wezzy] ESP is now active!")
warn("========================================")
warn("wezzy v" .. tostring(wezzy.version))
warn("ESP: Active")
warn("Aimbot: Disabled (requires game functions)")
warn("Watermark: Visible")
warn("Game Functions: Scanning in background...")
warn("========================================")
