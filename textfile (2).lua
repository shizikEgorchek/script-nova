--[[
    NOVA HUB v126 - MODERN UI + SPEED/JUMPPOWER/INFJUMP EDITION
    Features: Speed Changer, JumpPower Changer, Infinite Jump + All Original Features
    FIXED: MODERNIZED TITLE BAR WITH "NOVA HUB" TITLE
]]

-----------------------------------------------------------
-- GLOBAL CONFIGURATION
-----------------------------------------------------------
_G.FarmSpeed = 30
_G.CollectDelay = 0 
_G.ESPTextSize = 18
_G.GUITextSize = 16
_G.FlingDistance = 5
_G.BagLimit = 25
_G.SafeZoneOffset = -30 
_G.VoidThreshold = -200 
_G.HitboxSize = 15
_G.WalkSpeed = 16 -- NEW: Default walk speed
_G.JumpPower = 50 -- NEW: Default jump power

-----------------------------------------------------------
-- SERVICE DEFINITIONS
-----------------------------------------------------------
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-----------------------------------------------------------
-- TOGGLE STATES
-----------------------------------------------------------
local activeFarms = {
    Coins = false, 
    Clover = false, 
    Beans = false, 
    Snatcher = false, 
    LoopBring = false,
    BringSheriff = false, 
    BringMurderer = false, 
    AntiVoid = false, 
    AntiAFK = false, 
    RobloxAntiAFK = false, 
    NightMode = false, 
    AntiSeat = false, 
    LMSAutoDie = false,
    HitboxExpander = false,
    AutoKillAll = false,
    SpeedEnabled = false, -- NEW
    JumpPowerEnabled = false, -- NEW
    InfJump = false -- NEW
}

local espEnabled = false
local noclipEnabled = false
local currentTween = nil
local ignoreList = {}
local isInSafeZone = false
local touchedSignal = false 

-----------------------------------------------------------
-- CHARACTER INITIALIZATION
-----------------------------------------------------------
player.CharacterAdded:Connect(function(newChar) 
    character = newChar 
    ignoreList = {}
    isInSafeZone = false
    
    newChar.ChildAdded:Connect(function(child)
        if child:IsA("BasePart") then
            child.Touched:Connect(function(hit)
                if hit ~= nil then
                    if hit.Parent ~= nil then
                        if hit.Name == "GoldCoin" or hit.Name == "DankCoin" or hit.Name == "Clover" or hit.Name == "Bean" then
                            touchedSignal = true 
                        end
                        if hit.Parent.Name == "CoinHolder" then
                            touchedSignal = true
                        end
                    end
                end
            end)
        end
    end)
end)

if character ~= nil then
    local children = character:GetChildren()
    for i = 1, #children do
        local part = children[i]
        if part:IsA("BasePart") then
            part.Touched:Connect(function(hit)
                if hit ~= nil then
                    if hit.Parent ~= nil then
                        if hit.Name == "GoldCoin" or hit.Name == "DankCoin" or hit.Name == "Clover" or hit.Name == "Bean" then
                            touchedSignal = true
                        end
                        if hit.Parent.Name == "CoinHolder" then
                            touchedSignal = true
                        end
                    end
                end
            end)
        end
    end
end

-----------------------------------------------------------
-- ROLE DETECTION LOGIC
-----------------------------------------------------------
local function getPlayerRole(p)
    local char = p.Character
    local backpack = p:FindFirstChild("Backpack")
    
    local function searchContainer(container)
        if container == nil then 
            return nil
        end
        local knife = container:FindFirstChild("Knife")
        if knife ~= nil then 
            return "M" 
        end
        local gun = container:FindFirstChild("Gun")
        if gun ~= nil then 
            return "S" 
        end
        local rev = container:FindFirstChild("Revolver")
        if rev ~= nil then 
            return "S" 
        end
        return nil
    end
    
    local roleResult = searchContainer(char)
    if roleResult == nil then 
        roleResult = searchContainer(backpack) 
    end
    
    if roleResult == nil then
        return "I" 
    else 
        return roleResult 
    end
end

-----------------------------------------------------------
-- NEW: SPEED SYSTEM
-----------------------------------------------------------
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if activeFarms.SpeedEnabled == true and character ~= nil then
            local hum = character:FindFirstChild("Humanoid")
            if hum ~= nil then
                hum.WalkSpeed = _G.WalkSpeed
            end
        end
    end
end)

-----------------------------------------------------------
-- NEW: JUMPPOWER SYSTEM
-----------------------------------------------------------
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if activeFarms.JumpPowerEnabled == true and character ~= nil then
            local hum = character:FindFirstChild("Humanoid")
            if hum ~= nil then
                hum.JumpPower = _G.JumpPower
            end
        end
    end
end)

-----------------------------------------------------------
-- NEW: INFINITE JUMP SYSTEM
-----------------------------------------------------------
UserInputService.JumpRequest:Connect(function()
    if activeFarms.InfJump == true and character ~= nil then
        local hum = character:FindFirstChild("Humanoid")
        if hum ~= nil then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-----------------------------------------------------------
-- HYPER FARM ENGINE
-----------------------------------------------------------
local function getCoinValue()
    local collected = player:FindFirstChild("CoinsCollected")
    if collected ~= nil and (collected:IsA("IntValue") or collected:IsA("NumberValue")) then
        return collected.Value
    end

    local stats = player:FindFirstChild("leaderstats")
    if stats ~= nil then
        local c1 = stats:FindFirstChild("Coins")
        if c1 ~= nil then return c1.Value end
        local c2 = stats:FindFirstChild("Coin")
        if c2 ~= nil then return c2.Value end
        local c3 = stats:FindFirstChild("Gold")
        if c3 ~= nil then return c3.Value end
        local c4 = stats:FindFirstChild("C")
        if c4 ~= nil then return c4.Value end
    end
    
    local coinData = player:FindFirstChild("CoinData")
    if coinData ~= nil then
        local v1 = coinData:FindFirstChild("Coins")
        if v1 ~= nil then return v1.Value end
        local v2 = coinData:FindFirstChild("Coin")
        if v2 ~= nil then return v2.Value end
        local v3 = coinData:FindFirstChild("Gold")
        if v3 ~= nil then return v3.Value end
    end

    return 0
end

local function getFarmTarget()
    local holder = Workspace:FindFirstChild("CoinHolder")
    if holder ~= nil then
        local children = holder:GetDescendants()
        for i = 1, #children do
            local item = children[i]
            if item:IsA("BasePart") and not ignoreList[item] then
                local name = item.Name
                local pName = ""
                if item.Parent ~= nil then pName = item.Parent.Name end
                
                if activeFarms.Coins == true then
                    if name == "GoldCoin" then return item end
                    if name == "DankCoin" then return item end
                    if pName == "GoldCoin" then return item end
                    if pName == "DankCoin" then return item end
                end
                
                if activeFarms.Clover == true then
                    if name == "Clover" or pName == "Clover" then return item end
                end
                
                if activeFarms.Beans == true then
                    if name == "Bean" or pName == "Bean" then return item end
                end
            end
        end
    end
    return nil
end

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        
        local isAnyFarmActive = false
        if activeFarms.Coins == true then isAnyFarmActive = true end
        if activeFarms.Clover == true then isAnyFarmActive = true end
        if activeFarms.Beans == true then isAnyFarmActive = true end
        
        if isAnyFarmActive == true and character ~= nil then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root ~= nil then
                local currentCoins = getCoinValue()
                local target = getFarmTarget()
                
                if currentCoins >= _G.BagLimit or target == nil then
                    if isInSafeZone == false then
                        local plat = Workspace:FindFirstChild("NovaSafePlatform")
                        if plat == nil then
                            plat = Instance.new("Part", Workspace)
                            plat.Name = "NovaSafePlatform"
                            plat.Size = Vector3.new(25, 1, 25)
                            plat.Anchored = true
                            plat.Transparency = 0.5
                            plat.Color = Color3.fromRGB(0, 255, 150)
                        end
                        local targetSafePos = root.CFrame * CFrame.new(0, _G.SafeZoneOffset, 0)
                        plat.CFrame = targetSafePos
                        root.CFrame = plat.CFrame + Vector3.new(0, 5, 0)
                        isInSafeZone = true
                    end
                else
                    isInSafeZone = false
                    if target ~= nil then
                        touchedSignal = false
                        
                        local conn;
                        conn = target.Touched:Connect(function(hit)
                            if hit ~= nil and hit.Parent == character then touchedSignal = true end
                        end)
                        
                        local targetCFrame = CFrame.new(target.Position.X, target.Position.Y, target.Position.Z) * root.CFrame.Rotation
                        
                        if targetCFrame ~= nil then
                            local distance = (root.Position - target.Position).Magnitude
                            local tweenTime = distance / _G.FarmSpeed
                            local info = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
                            
                            currentTween = TweenService:Create(root, info, {CFrame = targetCFrame})
                            currentTween:Play()
                            
                            local waitStart = tick()
                            while (tick() - waitStart) < (tweenTime + 0.1) do
                                RunService.Heartbeat:Wait()
                                
                                root.Velocity = Vector3.new(0, 0, 0)
                                root.RotVelocity = Vector3.new(0, 0, 0)
                                
                                local midTweenCheck = getCoinValue()
                                if midTweenCheck >= _G.BagLimit then
                                    if currentTween ~= nil then currentTween:Cancel() end
                                    break
                                end

                                local distCheck = (root.Position - target.Position).Magnitude
                                if distCheck < 1.6 or touchedSignal == true then 
                                    ignoreList[target] = true
                                    task.delay(3.5, function() ignoreList[target] = nil end)
                                    if currentTween ~= nil then currentTween:Cancel() end
                                    break 
                                end
                                
                                if target.Parent == nil then break end 
                            end
                            
                            if currentTween ~= nil then currentTween:Cancel() end
                            if conn ~= nil then conn:Disconnect() end
                        end
                    end
                end
            end
        end
    end
end)

-----------------------------------------------------------
-- HITBOX EXPANDER LOGIC
-----------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.5)
        if activeFarms.HitboxExpander == true then
            local pList = Players:GetPlayers()
            for i = 1, #pList do
                local v = pList[i]
                if v ~= player and v.Character ~= nil then
                    local hrp = v.Character:FindFirstChild("HumanoidRootPart")
                    if hrp ~= nil then
                        hrp.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                        hrp.Transparency = 0.7
                        hrp.BrickColor = BrickColor.new("Really blue")
                        hrp.Material = Enum.Material.Neon
                        hrp.CanCollide = false
                    end
                end
            end
        else
            local pList = Players:GetPlayers()
            for i = 1, #pList do
                local v = pList[i]
                if v ~= player and v.Character ~= nil then
                    local hrp = v.Character:FindFirstChild("HumanoidRootPart")
                    if hrp ~= nil then
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.Transparency = 1
                        hrp.CanCollide = false
                    end
                end
            end
        end
    end
end)

-----------------------------------------------------------
-- AUTO KILL EVERYONE LOGIC
-----------------------------------------------------------
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if activeFarms.AutoKillAll == true then
            if character ~= nil then
                local knife = character:FindFirstChild("Knife")
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if knife ~= nil and hrp ~= nil then
                    local pList = Players:GetPlayers()
                    for i = 1, #pList do
                        local p = pList[i]
                        if p ~= player and p.Character ~= nil then
                            local vHrp = p.Character:FindFirstChild("HumanoidRootPart")
                            if vHrp ~= nil then
                                vHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
                            end
                        end
                    end
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(0,0))
                    task.wait(0.5)
                    activeFarms.AutoKillAll = false
                end
            end
        end
    end
end)

-----------------------------------------------------------
-- NIGHT MODE
-----------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.5)
        if activeFarms.NightMode == true then
            Lighting.ClockTime = 0
            Lighting.Brightness = 0
            Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
            Lighting.GlobalShadows = true
        else
            Lighting.ClockTime = 12
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
        end
    end
end)

-----------------------------------------------------------
-- COMBAT UTILITIES
-----------------------------------------------------------
local function tpToMap()
    local currentMapFolder = Workspace:FindFirstChild("CurrentMap")
    if currentMapFolder ~= nil then
        local mapModel = currentMapFolder:FindFirstChildOfClass("Model")
        if mapModel ~= nil then
            local spawnsFolder = mapModel:FindFirstChild("Spawns")
            if spawnsFolder ~= nil then
                local spawns = spawnsFolder:GetChildren()
                if #spawns > 0 then
                    local randomSpawn = spawns[math.random(1, #spawns)]
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if rootPart ~= nil then rootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0) end
                end
            end
        end
    end
end

local function performFling(targetRole)
    local targetPlayer = nil
    local playerList = Players:GetPlayers()
    for i = 1, #playerList do
        local p = playerList[i]
        if p ~= player then
            local role = getPlayerRole(p)
            if role == targetRole then targetPlayer = p break end
        end
    end
    local hum = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if targetPlayer ~= nil and targetPlayer.Character ~= nil then
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot ~= nil and root ~= nil and hum ~= nil then
            local oldPos = root.CFrame
            noclipEnabled = true
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            local flingStartTime = tick()
            while tick() - flingStartTime < 1.5 do
                RunService.Heartbeat:Wait()
                if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local victimRoot = targetPlayer.Character.HumanoidRootPart
                    local flingOffset = CFrame.new(0, 0, -_G.FlingDistance)
                    local flingPos = victimRoot.CFrame * flingOffset
                    root.CFrame = flingPos * CFrame.Angles(math.rad(math.random(0, 360)), math.rad(math.random(0, 360)), math.rad(math.random(0, 360)))
                    root.Velocity = Vector3.new(0, -1000, 0)
                    root.RotVelocity = Vector3.new(0, 10000, 0)
                end
            end
            root.Anchored = true
            root.Velocity = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)
            root.CFrame = oldPos
            task.wait(0.2)
            root.Anchored = false
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            noclipEnabled = false
        end
    end
end

-----------------------------------------------------------
-- GUI CREATION (MODERNIZED WITH NOVA HUB TITLE)
-----------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Nova_v126"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Parent = ScreenGui
Main.Size = UDim2.new(0, 700, 0, 500) 
Main.Position = UDim2.new(0.5, -350, 0.5, -250)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 10) 
Main.Active = true 
Main.Draggable = true
Main.Visible = true
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

-- TITLE BAR
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TitleBar.BorderSizePixel = 0

local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 12)

local TitlePatch = Instance.new("Frame", TitleBar)
TitlePatch.Size = UDim2.new(1, 0, 0, 25)
TitlePatch.Position = UDim2.new(0, 0, 1, -25)
TitlePatch.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TitlePatch.BorderSizePixel = 0

local TitleAccent = Instance.new("Frame", TitleBar)
TitleAccent.Size = UDim2.new(1, 0, 0, 2)
TitleAccent.Position = UDim2.new(0, 0, 1, -2)
TitleAccent.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
TitleAccent.BorderSizePixel = 0

local TitleGlow = Instance.new("Frame", TitleBar)
TitleGlow.Size = UDim2.new(0, 10, 0, 10)
TitleGlow.Position = UDim2.new(0, 15, 0.5, -5)
TitleGlow.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
TitleGlow.BorderSizePixel = 0
Instance.new("UICorner", TitleGlow).CornerRadius = UDim.new(1, 0)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 35, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "NOVA HUB"
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 20
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- CLOSE BUTTON
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseButton"
CloseBtn.Parent = TitleBar
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -45, 0.5, -17.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 10
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- OPEN BUTTON (SHOWN WHEN MINIMIZED)
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenButton"
OpenBtn.Parent = ScreenGui
OpenBtn.Size = UDim2.new(0, 120, 0, 45)
OpenBtn.Position = UDim2.new(0, 10, 0.5, -22.5)
OpenBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
OpenBtn.BorderSizePixel = 0
OpenBtn.Text = "SHOW NOVA HUB"
OpenBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 11
OpenBtn.Visible = false
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 8)
local OpenStroke = Instance.new("UIStroke", OpenBtn)
OpenStroke.Color = Color3.fromRGB(0, 255, 150)
OpenStroke.Thickness = 2

-- HIDE BUTTON
local HideBtn = Instance.new("TextButton")
HideBtn.Name = "HideButton"
HideBtn.Parent = TitleBar
HideBtn.Size = UDim2.new(0, 35, 0, 35)
HideBtn.Position = UDim2.new(1, -85, 0.5, -17.5)
HideBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
HideBtn.Text = "_"
HideBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
HideBtn.TextSize = 20
HideBtn.Font = Enum.Font.GothamBold
HideBtn.ZIndex = 10
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 8)
HideBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenBtn.Visible = false
end)

-----------------------------------------------------------
-- SIDEBAR
-----------------------------------------------------------
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 200, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Sidebar.BorderSizePixel = 0

local SidebarPatch = Instance.new("Frame", Sidebar)
SidebarPatch.Size = UDim2.new(0, 10, 1, 0)
SidebarPatch.Position = UDim2.new(1, -10, 0, 0)
SidebarPatch.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
SidebarPatch.BorderSizePixel = 0

local SidebarCorner = Instance.new("UICorner", Sidebar)
SidebarCorner.CornerRadius = UDim.new(0, 12)

local Separator = Instance.new("Frame", Main)
Separator.Size = UDim2.new(0, 1, 1, -50)
Separator.Position = UDim2.new(0, 200, 0, 50)
Separator.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Separator.BorderSizePixel = 0

local ContentArea = Instance.new("Frame", Main)
ContentArea.Size = UDim2.new(1, -210, 1, -60)
ContentArea.Position = UDim2.new(0, 205, 0, 55)
ContentArea.BackgroundTransparency = 1

local ButtonsTitle = Instance.new("TextLabel", ContentArea)
ButtonsTitle.Size = UDim2.new(1, 0, 0, 40)
ButtonsTitle.Position = UDim2.new(0, 10, 0, 0)
ButtonsTitle.Text = "CONTROLS"
ButtonsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
ButtonsTitle.Font = Enum.Font.GothamBold
ButtonsTitle.TextSize = 18
ButtonsTitle.TextXAlignment = Enum.TextXAlignment.Left
ButtonsTitle.BackgroundTransparency = 1

-----------------------------------------------------------
-- TABS LOGIC
-----------------------------------------------------------
local function createModernTabButton(txt, yOffset, parent)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -20, 0, 48)
    btn.Position = UDim2.new(0, 10, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BackgroundTransparency = 0.5
    btn.Text = txt
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextXAlignment = Enum.TextXAlignment.Left
    
    local padding = Instance.new("UIPadding", btn)
    padding.PaddingLeft = UDim.new(0, 15)
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 10)
    
    btn.MouseEnter:Connect(function()
        if btn.TextColor3 ~= Color3.fromRGB(255, 255, 255) then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40), BackgroundTransparency = 0.2}):Play()
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if btn.TextColor3 ~= Color3.fromRGB(255, 255, 255) then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30), BackgroundTransparency = 0.5}):Play()
            TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
        end
    end)
    
    return btn
end

local TabCombatBtn = createModernTabButton("COMBAT", 15, Sidebar)
local TabVisualBtn = createModernTabButton("VISUAL", 75, Sidebar)
local TabFarmBtn = createModernTabButton("AUTO - FARM", 135, Sidebar)

local CombatCol = Instance.new("ScrollingFrame", ContentArea)
CombatCol.Size = UDim2.new(1, -20, 1, -50)
CombatCol.Position = UDim2.new(0, 10, 0, 40)
CombatCol.BackgroundTransparency = 1
CombatCol.CanvasSize = UDim2.new(0, 0, 4, 0)
CombatCol.ScrollBarThickness = 4
CombatCol.Visible = true
Instance.new("UIListLayout", CombatCol).Padding = UDim.new(0, 8)

local VisualCol = Instance.new("ScrollingFrame", ContentArea)
VisualCol.Size = UDim2.new(1, -20, 1, -50)
VisualCol.Position = UDim2.new(0, 10, 0, 40)
VisualCol.BackgroundTransparency = 1
VisualCol.CanvasSize = UDim2.new(0, 0, 1.5, 0)
VisualCol.ScrollBarThickness = 4
VisualCol.Visible = false
Instance.new("UIListLayout", VisualCol).Padding = UDim.new(0, 8)

local FarmCol = Instance.new("ScrollingFrame", ContentArea)
FarmCol.Size = UDim2.new(1, -20, 1, -50)
FarmCol.Position = UDim2.new(0, 10, 0, 40)
FarmCol.BackgroundTransparency = 1
FarmCol.CanvasSize = UDim2.new(0, 0, 2.5, 0)
FarmCol.ScrollBarThickness = 4
FarmCol.Visible = false
Instance.new("UIListLayout", FarmCol).Padding = UDim.new(0, 8)

local function resetTabColors()
    TweenService:Create(TabCombatBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30), BackgroundTransparency = 0.5, TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    TweenService:Create(TabVisualBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30), BackgroundTransparency = 0.5, TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    TweenService:Create(TabFarmBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30), BackgroundTransparency = 0.5, TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
end

TabCombatBtn.MouseButton1Click:Connect(function()
    resetTabColors()
    TweenService:Create(TabCombatBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 255, 150), BackgroundTransparency = 0.85, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    CombatCol.Visible = true; VisualCol.Visible = false; FarmCol.Visible = false
end)

TabVisualBtn.MouseButton1Click:Connect(function()
    resetTabColors()
    TweenService:Create(TabVisualBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 255, 150), BackgroundTransparency = 0.85, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    CombatCol.Visible = false; VisualCol.Visible = true; FarmCol.Visible = false
end)

TabFarmBtn.MouseButton1Click:Connect(function()
    resetTabColors()
    TweenService:Create(TabFarmBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 255, 150), BackgroundTransparency = 0.85, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    CombatCol.Visible = false; VisualCol.Visible = false; FarmCol.Visible = true
end)

resetTabColors()
TabCombatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TabCombatBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
TabCombatBtn.BackgroundTransparency = 0.85

-----------------------------------------------------------
-- UI FACTORY
-----------------------------------------------------------
local function createHeader(txt, parent)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, 0, 0, 30)
    l.Text = "-- " .. txt .. " --"
    l.TextColor3 = Color3.fromRGB(150, 150, 150)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
end

local function createToggle(txt, key, parent)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -10, 0, 40)
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    b.Text = txt 
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(200, 200, 200)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(function()
        if key == "ESP" then espEnabled = not espEnabled else activeFarms[key] = not activeFarms[key] end
        local check = (key == "ESP") and espEnabled or activeFarms[key]
        b.BackgroundColor3 = check and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(20, 20, 20)
    end)
    
    task.spawn(function()
        while true do
            task.wait(0.1)
            if key ~= "ESP" then
                local check = activeFarms[key]
                b.BackgroundColor3 = check and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(20, 20, 20)
            end
        end
    end)
end

local function createSlider(name, min, max, default, parent, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 60)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, 0, 0, 25); l.Text = name .. ": " .. default; l.TextColor3 = Color3.new(1, 1, 1);
    l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold; l.TextSize = 12
    local b = Instance.new("TextButton", f); b.Size = UDim2.new(0.8, 0, 0, 6); b.Position = UDim2.new(0.1, 0, 0.6, 0); b.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
    b.Text = ""
    local fill = Instance.new("Frame", b); fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 255, 150);
    fill.BorderSizePixel = 0
    b.MouseButton1Down:Connect(function()
        local move; move = RunService.RenderStepped:Connect(function()
            local mouse = UserInputService:GetMouseLocation()
            local rel = mouse.X - b.AbsolutePosition.X
            local per = math.clamp(rel / b.AbsoluteSize.X, 0, 1)
            local val = (min + (per * (max - min)))
            val = (max <= 10) and math.floor(val * 10) / 10 or math.floor(val)
            l.Text = name .. ": " .. val; fill.Size = UDim2.new(per, 0, 1, 0); callback(val)
        end)
        local stop; stop = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then if move then move:Disconnect() end if stop then stop:Disconnect() end end
        end)
    end)
end

local function createButton(txt, color, parent, callback)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -10, 0, 40)
    b.BackgroundColor3 = color
    b.Text = txt
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(callback)
end

-- NEW: Text Input Factory
local function createTextInput(labelText, defaultValue, parent, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -10, 0, 70)
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(30, 30, 30)
    stroke.Thickness = 1
    
    local padding = Instance.new("UIPadding", container)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, 0, 0, 15)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(0, 255, 150)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    
    local textBox = Instance.new("TextBox", container)
    textBox.Size = UDim2.new(1, 0, 0, 35)
    textBox.Position = UDim2.new(0, 0, 0, 20)
    textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    textBox.Text = tostring(defaultValue)
    textBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    textBox.Font = Enum.Font.GothamBold
    textBox.TextSize = 14
    textBox.PlaceholderText = tostring(defaultValue)
    textBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)
    local boxStroke = Instance.new("UIStroke", textBox)
    boxStroke.Color = Color3.fromRGB(50, 50, 50)
    boxStroke.Thickness = 2
    
    textBox.FocusLost:Connect(function()
        callback(tonumber(textBox.Text) or defaultValue)
    end)
    
    return container
end

-----------------------------------------------------------
-- POPULATING BUTTONS BY CATEGORY
-----------------------------------------------------------
-- COMBAT TAB
createHeader("HITBOX EXPANDER", CombatCol)
createToggle("ENABLE HITBOX EXPANDER", "HitboxExpander", CombatCol)
createSlider("HITBOX SIZE", 1, 100, _G.HitboxSize, CombatCol, function(v) _G.HitboxSize = v end)

createHeader("AUTO KILL", CombatCol)
createToggle("AUTO KILL EVERYONE", "AutoKillAll", CombatCol)

createHeader("MOVEMENT & TP", CombatCol)
createButton("TP TO MAP", Color3.fromRGB(50, 50, 50), CombatCol, tpToMap)
createToggle("ANTI-VOID", "AntiVoid", CombatCol)

-- NEW: SPEED CONTROLS
createTextInput("⚡ SPEED", _G.WalkSpeed, CombatCol, function(v) _G.WalkSpeed = v end)
createToggle("ENABLE SPEED", "SpeedEnabled", CombatCol)

-- NEW: JUMPPOWER CONTROLS
createTextInput("🚀 JUMP POWER", _G.JumpPower, CombatCol, function(v) _G.JumpPower = v end)
createToggle("ENABLE JUMP POWER", "JumpPowerEnabled", CombatCol)

-- NEW: INFINITE JUMP
createToggle("∞ INFINITE JUMP", "InfJump", CombatCol)

createHeader("COMBAT CHEATS", CombatCol)
createToggle("GUN SNATCHER (GUNSPAWN)", "Snatcher", CombatCol)
createToggle("FORCED LMS AUTO DIE", "LMSAutoDie", CombatCol)

createHeader("FLING PHYSICS", CombatCol)
createSlider("FLING DISTANCE", 0, 20, _G.FlingDistance, CombatCol, function(v) _G.FlingDistance = v end)
createButton("S-FLING", Color3.fromRGB(0, 60, 120), CombatCol, function() performFling("S") end)
createButton("M-FLING", Color3.fromRGB(120, 0, 0), CombatCol, function() performFling("M") end)

createHeader("BRING SYSTEMS", CombatCol)
createToggle("LOOP BRING ALL", "LoopBring", CombatCol)
createToggle("LOOP BRING SHERIFF", "BringSheriff", CombatCol)
createToggle("LOOP BRING MURDERER", "BringMurderer", CombatCol)

-- VISUAL TAB
createHeader("VISUAL MODS", VisualCol)
createToggle("MASTER DUAL ESP", "ESP", VisualCol)
createToggle("NIGHT MODE", "NightMode", VisualCol)

-- AUTO-FARM TAB
createHeader("FARM CONFIG", FarmCol)
createSlider("FARM SPEED", 10, 150, _G.FarmSpeed, FarmCol, function(v) _G.FarmSpeed = v end)
createSlider("COLLECT DELAY", 0, 5, _G.CollectDelay, FarmCol, function(v) _G.CollectDelay = v end)

createHeader("FARM SELECTION", FarmCol)
createToggle("COIN FARM", "Coins", FarmCol)
createToggle("CLOVER FARM", "Clover", FarmCol)
createToggle("BEAN FARM", "Beans", FarmCol)

createHeader("AFK & UTILITY", FarmCol)
createToggle("ANTI-SEAT", "AntiSeat", FarmCol)
createToggle("MENU ANTI-AFK", "AntiAFK", FarmCol)
createToggle("ROBLOX ANTI-AFK", "RobloxAntiAFK", FarmCol)

-----------------------------------------------------------
-- CORE RECURRING SYSTEMS
-----------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if activeFarms.Snatcher == true and character ~= nil then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local spawnFolder = Workspace:FindFirstChild("GunSpawn")
            if hrp ~= nil and spawnFolder ~= nil then
                local gunPart = spawnFolder:FindFirstChildOfClass("Part") or spawnFolder:FindFirstChildOfClass("MeshPart")
                if gunPart ~= nil then
                    local oldCFrame = hrp.CFrame
                    noclipEnabled = true
                    hrp.CFrame = gunPart.CFrame + Vector3.new(0, 1, 0)
                    task.wait(0.2)
                    hrp.CFrame = oldCFrame
                    noclipEnabled = false
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if character ~= nil then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp ~= nil then
                local bPos = hrp.CFrame * CFrame.new(0, 0, -5)
                local pList = Players:GetPlayers()
                for i = 1, #pList do
                    local p = pList[i]
                    if p ~= player and p.Character ~= nil then
                        local vHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if vHrp ~= nil then
                            local role = getPlayerRole(p)
                            local check = (activeFarms.LoopBring) or (activeFarms.BringSheriff and role == "S") or (activeFarms.BringMurderer and role == "M")
                            if check == true then vHrp.CFrame = bPos end
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if activeFarms.LMSAutoDie == true and character ~= nil then
            local hum = character:FindFirstChild("Humanoid")
            if hum ~= nil then
                local alive = 0
                local pList = Players:GetPlayers()
                for i = 1, #pList do
                    local p = pList[i]
                    if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then alive = alive + 1 end
                end
                if alive == 2 and getPlayerRole(player) == "I" then character:BreakJoints() end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if activeFarms.AntiVoid == true then
        local antiVoidPart = Workspace:FindFirstChild("NovaAntiVoidPart")
        if antiVoidPart == nil then
            antiVoidPart = Instance.new("Part", Workspace)
            antiVoidPart.Name = "NovaAntiVoidPart"
            antiVoidPart.Size = Vector3.new(5000, 10, 5000)
            antiVoidPart.Position = Vector3.new(0, -250, 0)
            antiVoidPart.Anchored = true
            antiVoidPart.Transparency = 0.5
            antiVoidPart.Color = Color3.fromRGB(0, 255, 150)
            antiVoidPart.CanCollide = true
        end
        antiVoidPart.Anchored = true
        antiVoidPart.CanCollide = true
        
        if character ~= nil then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root ~= nil then
                if root.Position.Y < _G.VoidThreshold then
                    local safePlat = Workspace:FindFirstChild("NovaSafePlatform")
                    if safePlat ~= nil then
                        root.CFrame = safePlat.CFrame + Vector3.new(0, 5, 0)
                    else
                        root.CFrame = CFrame.new(0, 50, 0)
                    end
                end
            end
        end
    elseif Workspace:FindFirstChild("NovaAntiVoidPart") then 
        Workspace.NovaAntiVoidPart:Destroy() 
    end

    if espEnabled == true then
        local players = Players:GetPlayers()
        for i = 1, #players do
            local p = players[i]
            if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                local tag = head:FindFirstChild("Nova_Tag") or Instance.new("BillboardGui", head)
                if tag.Name ~= "Nova_Tag" then
                    tag.Name = "Nova_Tag"; tag.AlwaysOnTop = true; tag.Size = UDim2.new(0, 200, 0, 50); tag.StudsOffset = Vector3.new(0, 3, 0)
                    local l = Instance.new("TextLabel", tag); l.Name = "Label"; l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold; l.TextSize = _G.ESPTextSize;
                    Instance.new("UIStroke", l).Thickness = 2
                end
                local role, l = getPlayerRole(p), tag.Label
                if role == "M" then l.Text = "[MURDERER]"; l.TextColor3 = Color3.new(1, 0, 0)
                elseif role == "S" then l.Text = "[SHERIFF]"; l.TextColor3 = Color3.new(0, 0.5, 1)
                else l.Text = "[INNOCENT]"; l.TextColor3 = Color3.new(0, 1, 0) end
            end
        end
    end

    local isFarming = (activeFarms.Coins or activeFarms.Clover or activeFarms.Beans)
    if noclipEnabled or isInSafeZone or activeFarms.LoopBring or isFarming then
        if character then 
            local parts = character:GetDescendants()
            for i = 1, #parts do
                local v = parts[i]
                if v:IsA("BasePart") then v.CanCollide = false end 
            end 
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        if activeFarms.AntiAFK == true then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0))
            end)
            
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightShift, false, game)
        end
    end
end)

player.Idled:Connect(function()
    if activeFarms.RobloxAntiAFK == true then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
    end
end)
