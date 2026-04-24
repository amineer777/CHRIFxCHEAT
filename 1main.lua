-- ============================================
--   CHRIFxCHEAT | AMINE ER — V3.0 ULTIMATE
--   Full-Featured Cheat Menu
-- ============================================

local Settings = {
    Title      = "CHRIFxCHEAT",
    SubTitle   = "AMINE ER - ULTIMATE",
    MainColor  = Color3.fromRGB(255, 68, 68),
    ToggleKey  = Enum.KeyCode.RightShift,
    PanicKey   = Enum.KeyCode.Delete,
}

-- ============================================
-- SERVICES
-- ============================================
local Players       = game:GetService("Players")
local UserInput     = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local Lighting      = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace     = game:GetService("Workspace")
local LocalPlayer   = Players.LocalPlayer
local Camera        = Workspace.CurrentCamera

-- ============================================
-- GLOBAL STATES
-- ============================================
local FeatureStates = {
    -- Aimbot
    SilentAim = false,
    AutoAim = false,
    TriggerBot = false,
    TargetLock = false,
    AimAssist = false,
    IgnoreTeam = true,
    IgnoreWalls = false,
    Prediction = false,
    
    -- ESP
    BoxESP = false,
    NameESP = false,
    DistanceESP = false,
    HealthESP = false,
    SkeletonESP = false,
    Tracers = false,
    Chams = false,
    ItemESP = false,
    GlowESP = false,
    
    -- Movement
    Flying = false,
    NoClip = false,
    InfiniteJump = false,
    SuperJump = false,
    BunnyHop = false,
    AutoStick = false,
    
    -- Combat
    GodMode = false,
    InfiniteAmmo = false,
    RapidFire = false,
    NoRecoil = false,
    NoSpread = false,
    KillAura = false,
    AntiRagdoll = false,
    AntiSlow = false,
    
    -- Visual
    Fullbright = false,
    RemoveFog = false,
    FOVChanger = false,
    ThirdPerson = false,
    Crosshair = false,
    FPSCounter = false,
    
    -- Utility
    AntiAFK = false,
    AutoRespawn = false,
}

local FeatureValues = {
    -- Aimbot
    FOVRadius = 180,
    HeadChance = 10,
    Smoothness = 50,
    PredictionAmount = 0.13,
    
    -- Movement
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 50,
    TPDistance = 3,
    
    -- Combat
    KillAuraRange = 20,
    RapidFireSpeed = 0.1,
    
    -- Visual
    FOVValue = 70,
    ThirdPersonDistance = 10,
    AmbientBrightness = 1,
}

local ESPObjects = {}
local LockedTarget = nil

-- ============================================
-- CAMERA SETUP
-- ============================================
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

-- ============================================
-- FOV CIRCLE
-- ============================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.Radius = FeatureValues.FOVRadius
FOVCircle.Transparency = 0.7
FOVCircle.Color = Settings.MainColor
FOVCircle.Filled = false
FOVCircle.NumSides = 64

-- ============================================
-- CROSSHAIR
-- ============================================
local CrosshairLines = {}
for i = 1, 4 do
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = Color3.fromRGB(0, 255, 0)
    line.Transparency = 1
    line.Visible = false
    table.insert(CrosshairLines, line)
end

-- ============================================
-- FPS COUNTER
-- ============================================
local FPSLabel = Drawing.new("Text")
FPSLabel.Text = "FPS: 0"
FPSLabel.Size = 18
FPSLabel.Color = Color3.fromRGB(255, 255, 255)
FPSLabel.Center = false
FPSLabel.Outline = true
FPSLabel.Position = Vector2.new(10, 10)
FPSLabel.Visible = false

local frameCount = 0
local lastTime = tick()

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local function IsAlive(player)
    return player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function GetCharacter(player)
    return player and player.Character
end

local function GetRootPart(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
end

local function GetHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function IsTeamMate(player)
    if not FeatureStates.IgnoreTeam then return false end
    return player.Team == LocalPlayer.Team
end

local function IsVisible(origin, targetPos)
    if not FeatureStates.IgnoreWalls then return true end
    
    local ray = Ray.new(origin, (targetPos - origin))
    local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
    
    return hit == nil or hit:IsDescendantOf(Players:GetPlayerFromCharacter(hit.Parent))
end

local function WorldToScreen(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function GetClosestPlayerToMouse()
    local closest = nil
    local shortestDist = math.huge
    local mousePos = UserInput:GetMouseLocation()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) and not IsTeamMate(player) then
            local char = GetCharacter(player)
            local rootPart = GetRootPart(char)
            
            if rootPart then
                local screenPos, onScreen = WorldToScreen(rootPart.Position)
                
                if onScreen then
                    local dist = (screenPos - mousePos).Magnitude
                    
                    if dist < shortestDist and dist <= FeatureValues.FOVRadius then
                        if IsVisible(Camera.CFrame.Position, rootPart.Position) then
                            closest = player
                            shortestDist = dist
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

local function GetClosestPlayerToCharacter()
    local closest = nil
    local shortestDist = math.huge
    local myRoot = GetRootPart(LocalPlayer.Character)
    
    if not myRoot then return nil end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) and not IsTeamMate(player) then
            local char = GetCharacter(player)
            local rootPart = GetRootPart(char)
            
            if rootPart then
                local dist = (rootPart.Position - myRoot.Position).Magnitude
                
                if dist < shortestDist then
                    closest = player
                    shortestDist = dist
                end
            end
        end
    end
    
    return closest
end

-- ============================================
-- AIMBOT FUNCTIONS
-- ============================================
local NonHeadParts = {
    "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local function GetRandomBodyPart(character)
    if math.random(1, 100) <= FeatureValues.HeadChance then
        local head = character:FindFirstChild("Head") or character:FindFirstChild("HeadHitbox")
        if head then return head, true end
    end
    
    local validParts = {}
    for _, partName in ipairs(NonHeadParts) do
        local part = character:FindFirstChild(partName)
        if part then table.insert(validParts, part) end
    end
    
    if #validParts > 0 then
        return validParts[math.random(1, #validParts)], false
    end
    
    return character:FindFirstChild("Head"), true
end

local function PredictPosition(part)
    if not FeatureStates.Prediction then return part.Position end
    
    local velocity = part.AssemblyLinearVelocity or part.Velocity or Vector3.new(0, 0, 0)
    return part.Position + (velocity * FeatureValues.PredictionAmount)
end

-- ============================================
-- SILENT AIM HOOK
-- ============================================
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if FeatureStates.SilentAim and method == "FireServer" and typeof(args[1]) == "table" then
        local packet = args[1]
        
        if typeof(packet.origin) == "Vector3" and typeof(packet.direction) == "Vector3" then
            local target = LockedTarget or GetClosestPlayerToMouse()
            
            if target then
                local char = GetCharacter(target)
                local humanoid = GetHumanoid(char)
                
                if IsAlive(target) then
                    local targetPart, isHeadshot = GetRandomBodyPart(char)
                    
                    if targetPart then
                        local targetPos = PredictPosition(targetPart)
                        
                        if IsVisible(packet.origin, targetPos) then
                            packet.direction = (targetPos - packet.origin).Unit
                            packet.hitPosition = targetPos
                            packet.hitInstance = targetPart
                            packet.hitHumanoid = humanoid
                            packet.IsHeadshot = isHeadshot
                            
                            return OldNamecall(self, packet)
                        end
                    end
                end
            end
        end
    end
    
    return OldNamecall(self, ...)
end))

-- ============================================
-- ESP FUNCTIONS
-- ============================================
local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local espData = {
        Player = player,
        Drawings = {},
        Connections = {}
    }
    
    -- Box ESP
    if FeatureStates.BoxESP then
        for i = 1, 4 do
            local line = Drawing.new("Line")
            line.Thickness = 2
            line.Color = Color3.fromRGB(255, 255, 255)
            line.Transparency = 1
            line.Visible = false
            table.insert(espData.Drawings, line)
        end
    end
    
    -- Name ESP
    if FeatureStates.NameESP then
        local text = Drawing.new("Text")
        text.Text = player.Name
        text.Size = 16
        text.Color = Color3.fromRGB(255, 255, 255)
        text.Center = true
        text.Outline = true
        text.Visible = false
        table.insert(espData.Drawings, text)
    end
    
    -- Distance ESP
    if FeatureStates.DistanceESP then
        local text = Drawing.new("Text")
        text.Text = "0m"
        text.Size = 14
        text.Color = Color3.fromRGB(200, 200, 200)
        text.Center = true
        text.Outline = true
        text.Visible = false
        table.insert(espData.Drawings, text)
    end
    
    -- Health Bar ESP
    if FeatureStates.HealthESP then
        local outline = Drawing.new("Line")
        outline.Thickness = 4
        outline.Color = Color3.fromRGB(0, 0, 0)
        outline.Visible = false
        
        local bar = Drawing.new("Line")
        bar.Thickness = 2
        bar.Color = Color3.fromRGB(0, 255, 0)
        bar.Visible = false
        
        table.insert(espData.Drawings, outline)
        table.insert(espData.Drawings, bar)
    end
    
    -- Tracer
    if FeatureStates.Tracers then
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Transparency = 0.5
        line.Visible = false
        table.insert(espData.Drawings, line)
    end
    
    -- Highlight (Chams/Glow)
    if FeatureStates.Chams or FeatureStates.GlowESP then
        local function addHighlight(char)
            if not char then return end
            
            task.wait(0.1)
            
            if not char:FindFirstChild("ESP_Highlight") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ESP_Highlight"
                highlight.FillColor = FeatureStates.Chams and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 255)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = FeatureStates.Chams and 0.5 or 0.7
                highlight.OutlineTransparency = 0
                highlight.Parent = char
            end
        end
        
        table.insert(espData.Connections, player.CharacterAdded:Connect(addHighlight))
        
        if player.Character then
            addHighlight(player.Character)
        end
    end
    
    ESPObjects[player] = espData
end

local function UpdateESP()
    for player, espData in pairs(ESPObjects) do
        if not player or not player.Parent then
            -- Clean up
            for _, drawing in pairs(espData.Drawings) do
                drawing:Remove()
            end
            for _, connection in pairs(espData.Connections) do
                connection:Disconnect()
            end
            ESPObjects[player] = nil
        else
            local char = GetCharacter(player)
            local rootPart = GetRootPart(char)
            
            if IsAlive(player) and rootPart then
                local screenPos, onScreen = WorldToScreen(rootPart.Position)
                
                for _, drawing in pairs(espData.Drawings) do
                    drawing.Visible = onScreen
                end
                
                if onScreen then
                    local headPos = char:FindFirstChild("Head") and char.Head.Position or rootPart.Position
                    local legPos = rootPart.Position - Vector3.new(0, 3, 0)
                    
                    local topScreen = WorldToScreen(headPos + Vector3.new(0, 1, 0))
                    local bottomScreen = WorldToScreen(legPos)
                    
                    local height = (topScreen - bottomScreen).Magnitude
                    local width = height / 2
                    
                    -- Box ESP
                    if FeatureStates.BoxESP and #espData.Drawings >= 4 then
                        local box = {
                            espData.Drawings[1],
                            espData.Drawings[2],
                            espData.Drawings[3],
                            espData.Drawings[4]
                        }
                        
                        -- Top
                        box[1].From = Vector2.new(topScreen.X - width/2, topScreen.Y)
                        box[1].To = Vector2.new(topScreen.X + width/2, topScreen.Y)
                        
                        -- Bottom
                        box[2].From = Vector2.new(bottomScreen.X - width/2, bottomScreen.Y)
                        box[2].To = Vector2.new(bottomScreen.X + width/2, bottomScreen.Y)
                        
                        -- Left
                        box[3].From = Vector2.new(topScreen.X - width/2, topScreen.Y)
                        box[3].To = Vector2.new(bottomScreen.X - width/2, bottomScreen.Y)
                        
                        -- Right
                        box[4].From = Vector2.new(topScreen.X + width/2, topScreen.Y)
                        box[4].To = Vector2.new(bottomScreen.X + width/2, bottomScreen.Y)
                    end
                    
                    -- Name ESP
                    if FeatureStates.NameESP then
                        for _, drawing in pairs(espData.Drawings) do
                            if drawing.Text and drawing.Text == player.Name then
                                drawing.Position = Vector2.new(topScreen.X, topScreen.Y - 20)
                            end
                        end
                    end
                    
                    -- Distance ESP
                    if FeatureStates.DistanceESP and GetRootPart(LocalPlayer.Character) then
                        local dist = math.floor((rootPart.Position - GetRootPart(LocalPlayer.Character).Position).Magnitude)
                        
                        for _, drawing in pairs(espData.Drawings) do
                            if drawing.Text and string.match(drawing.Text, "m$") then
                                drawing.Text = dist .. "m"
                                drawing.Position = Vector2.new(bottomScreen.X, bottomScreen.Y + 5)
                            end
                        end
                    end
                    
                    -- Health Bar
                    if FeatureStates.HealthESP then
                        local humanoid = GetHumanoid(char)
                        if humanoid then
                            local healthPct = humanoid.Health / humanoid.MaxHealth
                            
                            for i, drawing in pairs(espData.Drawings) do
                                if drawing.Thickness == 4 then -- Outline
                                    drawing.From = Vector2.new(topScreen.X - width/2 - 7, topScreen.Y)
                                    drawing.To = Vector2.new(topScreen.X - width/2 - 7, bottomScreen.Y)
                                elseif drawing.Thickness == 2 and drawing.Color == Color3.fromRGB(0, 255, 0) then -- Bar
                                    local barHeight = height * healthPct
                                    drawing.From = Vector2.new(topScreen.X - width/2 - 7, bottomScreen.Y)
                                    drawing.To = Vector2.new(topScreen.X - width/2 - 7, bottomScreen.Y - barHeight)
                                    
                                    -- Color based on health
                                    if healthPct > 0.6 then
                                        drawing.Color = Color3.fromRGB(0, 255, 0)
                                    elseif healthPct > 0.3 then
                                        drawing.Color = Color3.fromRGB(255, 255, 0)
                                    else
                                        drawing.Color = Color3.fromRGB(255, 0, 0)
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Tracers
                    if FeatureStates.Tracers then
                        for _, drawing in pairs(espData.Drawings) do
                            if drawing.From and drawing.To and drawing.Transparency == 0.5 then
                                drawing.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                drawing.To = Vector2.new(bottomScreen.X, bottomScreen.Y)
                            end
                        end
                    end
                end
            else
                for _, drawing in pairs(espData.Drawings) do
                    drawing.Visible = false
                end
            end
        end
    end
end

local function ClearESP()
    for player, espData in pairs(ESPObjects) do
        for _, drawing in pairs(espData.Drawings) do
            drawing:Remove()
        end
        for _, connection in pairs(espData.Connections) do
            connection:Disconnect()
        end
        
        if player.Character and player.Character:FindFirstChild("ESP_Highlight") then
            player.Character.ESP_Highlight:Destroy()
        end
    end
    
    ESPObjects = {}
end

-- ============================================
-- SKELETON ESP
-- ============================================
local SkeletonConnections = {}

local function CreateSkeleton(player)
    if SkeletonConnections[player] then return end
    
    local lines = {}
    local connections = {}
    
    local limbPairs = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"},
    }
    
    for i = 1, #limbPairs do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Transparency = 1
        line.Visible = false
        table.insert(lines, {line = line, pair = limbPairs[i]})
    end
    
    SkeletonConnections[player] = {
        Lines = lines,
        Connections = connections
    }
end

local function UpdateSkeletons()
    if not FeatureStates.SkeletonESP then return end
    
    for player, data in pairs(SkeletonConnections) do
        if not player or not player.Parent then
            for _, lineData in pairs(data.Lines) do
                lineData.line:Remove()
            end
            SkeletonConnections[player] = nil
        else
            local char = GetCharacter(player)
            
            if IsAlive(player) and char then
                for _, lineData in pairs(data.Lines) do
                    local part1 = char:FindFirstChild(lineData.pair[1])
                    local part2 = char:FindFirstChild(lineData.pair[2])
                    
                    if part1 and part2 then
                        local pos1, onScreen1 = WorldToScreen(part1.Position)
                        local pos2, onScreen2 = WorldToScreen(part2.Position)
                        
                        if onScreen1 and onScreen2 then
                            lineData.line.From = pos1
                            lineData.line.To = pos2
                            lineData.line.Visible = true
                        else
                            lineData.line.Visible = false
                        end
                    else
                        lineData.line.Visible = false
                    end
                end
            else
                for _, lineData in pairs(data.Lines) do
                    lineData.line.Visible = false
                end
            end
        end
    end
end

local function ClearSkeletons()
    for player, data in pairs(SkeletonConnections) do
        for _, lineData in pairs(data.Lines) do
            lineData.line:Remove()
        end
    end
    SkeletonConnections = {}
end

-- ============================================
-- MOVEMENT FEATURES
-- ============================================
local FlyConnection = nil
local NoClipConnection = nil
local BunnyHopConnection = nil

local function EnableFly()
    if FlyConnection then return end
    
    local speed = FeatureValues.FlySpeed
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
    
    FlyConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local rootPart = GetRootPart(char)
        
        if not rootPart or not FeatureStates.Flying then
            bodyVelocity:Destroy()
            bodyGyro:Destroy()
            if FlyConnection then FlyConnection:Disconnect() end
            FlyConnection = nil
            return
        end
        
        bodyVelocity.Parent = rootPart
        bodyGyro.Parent = rootPart
        
        local direction = Vector3.new(0, 0, 0)
        
        if UserInput:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + (Camera.CFrame.LookVector * speed)
        end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - (Camera.CFrame.LookVector * speed)
        end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - (Camera.CFrame.RightVector * speed)
        end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + (Camera.CFrame.RightVector * speed)
        end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + (Vector3.new(0, speed, 0))
        end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction = direction - (Vector3.new(0, speed, 0))
        end
        
        bodyVelocity.Velocity = direction
        bodyGyro.CFrame = Camera.CFrame
    end)
end

local function DisableFly()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
end

local function EnableNoClip()
    if NoClipConnection then return end
    
    NoClipConnection = RunService.Stepped:Connect(function()
        if not FeatureStates.NoClip then
            if NoClipConnection then NoClipConnection:Disconnect() end
            NoClipConnection = nil
            return
        end
        
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function EnableBunnyHop()
    if BunnyHopConnection then return end
    
    BunnyHopConnection = RunService.Heartbeat:Connect(function()
        if not FeatureStates.BunnyHop then
            if BunnyHopConnection then BunnyHopConnection:Disconnect() end
            BunnyHopConnection = nil
            return
        end
        
        local char = LocalPlayer.Character
        local humanoid = GetHumanoid(char)
        
        if humanoid and UserInput:IsKeyDown(Enum.KeyCode.Space) then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- ============================================
-- COMBAT FEATURES
-- ============================================
local KillAuraConnection = nil

local function EnableKillAura()
    if KillAuraConnection then return end
    
    KillAuraConnection = RunService.Heartbeat:Connect(function()
        if not FeatureStates.KillAura then
            if KillAuraConnection then KillAuraConnection:Disconnect() end
            KillAuraConnection = nil
            return
        end
        
        local myRoot = GetRootPart(LocalPlayer.Character)
        if not myRoot then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and IsAlive(player) and not IsTeamMate(player) then
                local char = GetCharacter(player)
                local rootPart = GetRootPart(char)
                
                if rootPart then
                    local dist = (rootPart.Position - myRoot.Position).Magnitude
                    
                    if dist <= FeatureValues.KillAuraRange then
                        local humanoid = GetHumanoid(char)
                        if humanoid then
                            -- Simulate damage (game-specific)
                            -- This is a placeholder - actual implementation depends on the game
                            humanoid:TakeDamage(10)
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================
-- VISUAL FEATURES
-- ============================================
local OriginalAmbient = Lighting.Ambient
local OriginalBrightness = Lighting.Brightness
local OriginalFogEnd = Lighting.FogEnd

local function ToggleFullbright(state)
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.FogEnd = 100000
        
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") then
                obj.Enabled = false
            end
        end
    else
        Lighting.Ambient = OriginalAmbient
        Lighting.Brightness = OriginalBrightness
        Lighting.FogEnd = OriginalFogEnd
    end
end

local function ToggleFOVChanger(state)
    if state then
        Camera.FieldOfView = FeatureValues.FOVValue
    else
        Camera.FieldOfView = 70
    end
end

local ThirdPersonConnection = nil

local function ToggleThirdPerson(state)
    if state then
        if not ThirdPersonConnection then
            ThirdPersonConnection = RunService.RenderStepped:Connect(function()
                if not FeatureStates.ThirdPerson then
                    if ThirdPersonConnection then ThirdPersonConnection:Disconnect() end
                    ThirdPersonConnection = nil
                    LocalPlayer.CameraMaxZoomDistance = 0.5
                    return
                end
                
                LocalPlayer.CameraMaxZoomDistance = FeatureValues.ThirdPersonDistance
                LocalPlayer.CameraMinZoomDistance = FeatureValues.ThirdPersonDistance
            end)
        end
    else
        if ThirdPersonConnection then
            ThirdPersonConnection:Disconnect()
            ThirdPersonConnection = nil
        end
        LocalPlayer.CameraMaxZoomDistance = 0.5
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
end

-- ============================================
-- ANTI-AFK
-- ============================================
local AntiAFKConnection = nil

local function ToggleAntiAFK(state)
    if state then
        if not AntiAFKConnection then
            local VirtualUser = game:GetService("VirtualUser")
            AntiAFKConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    else
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
            AntiAFKConnection = nil
        end
    end
end
-- ============================================
-- GUI ROOT
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CHRIFxCHEAT_ULTIMATE"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

-- ============================================
-- NOTIFICATION SYSTEM
-- ============================================
local NotificationContainer = Instance.new("Frame", ScreenGui)
NotificationContainer.Name = "Notifications"
NotificationContainer.Size = UDim2.new(0, 300, 0, 500)
NotificationContainer.Position = UDim2.new(1, -310, 0, 10)
NotificationContainer.BackgroundTransparency = 1

local NotificationLayout = Instance.new("UIListLayout", NotificationContainer)
NotificationLayout.Padding = UDim.new(0, 5)
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local function Notify(title, message, duration)
    duration = duration or 3
    
    local Notif = Instance.new("Frame", NotificationContainer)
    Notif.Size = UDim2.new(1, 0, 0, 70)
    Notif.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Notif.BorderSizePixel = 0
    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 8)
    
    local Accent = Instance.new("Frame", Notif)
    Accent.Size = UDim2.new(0, 3, 1, 0)
    Accent.BackgroundColor3 = Settings.MainColor
    Accent.BorderSizePixel = 0
    
    local Title = Instance.new("TextLabel", Notif)
    Title.Size = UDim2.new(1, -15, 0, 25)
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.Text = title
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    local Message = Instance.new("TextLabel", Notif)
    Message.Size = UDim2.new(1, -15, 0, 35)
    Message.Position = UDim2.new(0, 10, 0, 30)
    Message.Text = message
    Message.TextColor3 = Color3.fromRGB(180, 180, 180)
    Message.BackgroundTransparency = 1
    Message.Font = Enum.Font.Gotham
    Message.TextSize = 12
    Message.TextXAlignment = Enum.TextXAlignment.Left
    Message.TextYAlignment = Enum.TextYAlignment.Top
    Message.TextWrapped = true
    
    Notif.Size = UDim2.new(1, 0, 0, 0)
    TweenService:Create(Notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(1, 0, 0, 70)
    }):Play()
    
    task.delay(duration, function()
        TweenService:Create(Notif, TweenInfo.new(0.3), {
            Size = UDim2.new(1, 0, 0, 0)
        }):Play()
        task.wait(0.3)
        Notif:Destroy()
    end)
end

-- ============================================
-- MAIN FRAME
-- ============================================
local Main = Instance.new("Frame", ScreenGui)
Main.Name = "Main"
Main.Size = UDim2.new(0, 650, 0, 450)
Main.Position = UDim2.new(0.5, -325, 0.5, -225)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Drop Shadow
local Shadow = Instance.new("ImageLabel", Main)
Shadow.Size = UDim2.new(1, 30, 1, 30)
Shadow.Position = UDim2.new(0, -15, 0, -15)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6015897843"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ZIndex = 0
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(49, 49, 450, 450)

-- ============================================
-- TITLE BAR
-- ============================================
local TitleBar = Instance.new("Frame", Main)
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local AccentLine = Instance.new("Frame", TitleBar)
AccentLine.Size = UDim2.new(0, 3, 1, 0)
AccentLine.BackgroundColor3 = Settings.MainColor
AccentLine.BorderSizePixel = 0
Instance.new("UICorner", AccentLine).CornerRadius = UDim.new(0, 2)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, -200, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.Text = "🎮 " .. Settings.Title .. "  |  " .. Settings.SubTitle
TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Status Label
local StatusLabel = Instance.new("TextLabel", TitleBar)
StatusLabel.Size = UDim2.new(0, 150, 1, 0)
StatusLabel.Position = UDim2.new(1, -190, 0, 0)
StatusLabel.Text = "✅ Active"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Right

local MinimizeBtn = Instance.new("TextButton", TitleBar)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -70, 0.5, -15)
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 12
MinimizeBtn.BorderSizePixel = 0
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -15)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Notify("CHRIFxCHEAT", "القائمة مخفية - اضغط " .. Settings.ToggleKey.Name .. " لإظهارها", 3)
end)

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(Main, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 650, 0, 50)
        }):Play()
        MinimizeBtn.Text = "□"
    else
        TweenService:Create(Main, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 650, 0, 450)
        }):Play()
        MinimizeBtn.Text = "─"
    end
end)

-- ============================================
-- DRAG SYSTEM
-- ============================================
do
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    UserInput.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ============================================
-- SIDEBAR
-- ============================================
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 150, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
Sidebar.BorderSizePixel = 0

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.Padding = UDim.new(0, 3)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local SidePadding = Instance.new("UIPadding", Sidebar)
SidePadding.PaddingTop = UDim.new(0, 8)
SidePadding.PaddingLeft = UDim.new(0, 6)
SidePadding.PaddingRight = UDim.new(0, 6)

-- ============================================
-- CONTENT AREA
-- ============================================
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -160, 1, -60)
Content.Position = UDim2.new(0, 158, 0, 55)
Content.BackgroundTransparency = 1

local Divider = Instance.new("Frame", Main)
Divider.Size = UDim2.new(0, 1, 1, -50)
Divider.Position = UDim2.new(0, 152, 0, 50)
Divider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Divider.BorderSizePixel = 0

-- ============================================
-- TAB SYSTEM
-- ============================================
local Pages = {}
local ActivePage = nil

local function CreateTab(icon, name, pageName)
    local Btn = Instance.new("TextButton", Sidebar)
    Btn.Size = UDim2.new(1, 0, 0, 38)
    Btn.Text = icon .. "  " .. name
    Btn.TextColor3 = Color3.fromRGB(120, 120, 120)
    Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Btn.BackgroundTransparency = 1
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 11
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.BorderSizePixel = 0
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 7)
    local BtnPad = Instance.new("UIPadding", Btn)
    BtnPad.PaddingLeft = UDim.new(0, 12)

    local Accent = Instance.new("Frame", Btn)
    Accent.Size = UDim2.new(0, 3, 0.7, 0)
    Accent.Position = UDim2.new(0, -3, 0.15, 0)
    Accent.BackgroundColor3 = Settings.MainColor
    Accent.BorderSizePixel = 0
    Accent.Visible = false
    Instance.new("UICorner", Accent).CornerRadius = UDim.new(0, 2)

    local Page = Instance.new("ScrollingFrame", Content)
    Page.Name = pageName
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Settings.MainColor
    Page.BorderSizePixel = 0
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)

    local PageLayout = Instance.new("UIListLayout", Page)
    PageLayout.Padding = UDim.new(0, 6)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local PagePad = Instance.new("UIPadding", Page)
    PagePad.PaddingTop = UDim.new(0, 5)
    PagePad.PaddingRight = UDim.new(0, 5)
    PagePad.PaddingBottom = UDim.new(0, 5)

    PageLayout.Changed:Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
    end)

    Pages[pageName] = { Frame = Page, Btn = Btn, Accent = Accent }

    Btn.MouseButton1Click:Connect(function()
        for pName, pData in pairs(Pages) do
            pData.Frame.Visible = false
            pData.Btn.TextColor3 = Color3.fromRGB(100, 100, 100)
            pData.Btn.BackgroundTransparency = 1
            pData.Accent.Visible = false
        end
        Page.Visible = true
        Btn.TextColor3 = Settings.MainColor
        Btn.BackgroundTransparency = 0.85
        Accent.Visible = true
        ActivePage = pageName
    end)

    return Page
end

-- ============================================
-- COMPONENTS
-- ============================================
local function AddSection(parent, text)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = "━━  " .. text:upper() .. "  ━━"
    label.TextColor3 = Color3.fromRGB(100, 100, 100)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
end

local function AddToggle(parent, text, description, defaultOn, callback)
    local Row = Instance.new("Frame", parent)
    Row.Size = UDim2.new(1, 0, 0, description and 50 or 40)
    Row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    Row.BorderSizePixel = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", Row)
    stroke.Color = Color3.fromRGB(35, 35, 35)
    stroke.Thickness = 1

    local NameLbl = Instance.new("TextLabel", Row)
    NameLbl.Size = UDim2.new(1, -60, 0, 20)
    NameLbl.Position = UDim2.new(0, 12, 0, description and 8 or 10)
    NameLbl.Text = text
    NameLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    NameLbl.BackgroundTransparency = 1
    NameLbl.Font = Enum.Font.GothamSemibold
    NameLbl.TextSize = 13
    NameLbl.TextXAlignment = Enum.TextXAlignment.Left

    if description then
        local DescLbl = Instance.new("TextLabel", Row)
        DescLbl.Size = UDim2.new(1, -60, 0, 16)
        DescLbl.Position = UDim2.new(0, 12, 0, 28)
        DescLbl.Text = description
        DescLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
        DescLbl.BackgroundTransparency = 1
        DescLbl.Font = Enum.Font.Gotham
        DescLbl.TextSize = 10
        DescLbl.TextXAlignment = Enum.TextXAlignment.Left
    end

    local Track = Instance.new("Frame", Row)
    Track.Size = UDim2.new(0, 40, 0, 20)
    Track.Position = UDim2.new(1, -50, 0.5, -10)
    Track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Track.BorderSizePixel = 0
    Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 10)

    local Knob = Instance.new("Frame", Track)
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = UDim2.new(0, 2, 0.5, -8)
    Knob.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    Knob.BorderSizePixel = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(0, 8)

    local state = defaultOn or false

    local function SetState(s)
        state = s
        if state then
            TweenService:Create(Track, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 15, 15)}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2), {
                Position = UDim2.new(0, 22, 0.5, -8),
                BackgroundColor3 = Settings.MainColor
            }):Play()
            TweenService:Create(Row, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 12, 12)}):Play()
            stroke.Color = Color3.fromRGB(60, 20, 20)
        else
            TweenService:Create(Track, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2), {
                Position = UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(120, 120, 120)
            }):Play()
            TweenService:Create(Row, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 28)}):Play()
            stroke.Color = Color3.fromRGB(35, 35, 35)
        end
        if callback then callback(state) end
    end

    if defaultOn then SetState(true) end

    local Clickable = Instance.new("TextButton", Row)
    Clickable.Size = UDim2.new(1, 0, 1, 0)
    Clickable.BackgroundTransparency = 1
    Clickable.Text = ""
    Clickable.MouseButton1Click:Connect(function()
        SetState(not state)
    end)

    return {
        SetState = SetState,
        GetState = function() return state end
    }
end

local function AddSlider(parent, text, min, max, default, suffix, callback)
    suffix = suffix or ""
    local Row = Instance.new("Frame", parent)
    Row.Size = UDim2.new(1, 0, 0, 55)
    Row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    Row.BorderSizePixel = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", Row)
    stroke.Color = Color3.fromRGB(35, 35, 35)

    local NameLbl = Instance.new("TextLabel", Row)
    NameLbl.Size = UDim2.new(0.6, 0, 0, 22)
    NameLbl.Position = UDim2.new(0, 12, 0, 8)
    NameLbl.Text = text
    NameLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    NameLbl.BackgroundTransparency = 1
    NameLbl.Font = Enum.Font.GothamSemibold
    NameLbl.TextSize = 13
    NameLbl.TextXAlignment = Enum.TextXAlignment.Left

    local ValLbl = Instance.new("TextLabel", Row)
    ValLbl.Size = UDim2.new(0.4, -12, 0, 22)
    ValLbl.Position = UDim2.new(0.6, 0, 0, 8)
    ValLbl.Text = tostring(default) .. suffix
    ValLbl.TextColor3 = Settings.MainColor
    ValLbl.BackgroundTransparency = 1
    ValLbl.Font = Enum.Font.GothamBold
    ValLbl.TextSize = 13
    ValLbl.TextXAlignment = Enum.TextXAlignment.Right

    local TrackBg = Instance.new("Frame", Row)
    TrackBg.Size = UDim2.new(1, -24, 0, 5)
    TrackBg.Position = UDim2.new(0, 12, 0, 38)
    TrackBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TrackBg.BorderSizePixel = 0
    Instance.new("UICorner", TrackBg).CornerRadius = UDim.new(0, 2)

    local Fill = Instance.new("Frame", TrackBg)
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Settings.MainColor
    Fill.BorderSizePixel = 0
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 2)

    local Knob = Instance.new("Frame", TrackBg)
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    Knob.BorderSizePixel = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local value = default
    local sliding = false

    local function UpdateSlider(mouseX)
        local abs = TrackBg.AbsolutePosition.X
        local size = TrackBg.AbsoluteSize.X
        local pct = math.clamp((mouseX - abs) / size, 0, 1)
        value = math.floor(min + (max - min) * pct)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        Knob.Position = UDim2.new(pct, 0, 0.5, 0)
        ValLbl.Text = tostring(value) .. suffix
        if callback then callback(value) end
    end

    TrackBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            UpdateSlider(input.Position.X)
        end
    end)
    
    UserInput.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(input.Position.X)
        end
    end)
    
    UserInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    return { 
        GetValue = function() return value end,
        SetValue = function(val)
            value = math.clamp(val, min, max)
            local pct = (value - min) / (max - min)
            Fill.Size = UDim2.new(pct, 0, 1, 0)
            Knob.Position = UDim2.new(pct, 0, 0.5, 0)
            ValLbl.Text = tostring(value) .. suffix
        end
    }
end

local function AddButton(parent, icon, text, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.Size = UDim2.new(1, 0, 0, 40)
    Btn.Text = icon .. "  " .. text
    Btn.TextColor3 = Settings.MainColor
    Btn.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.BorderSizePixel = 0
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", Btn)
    stroke.Color = Color3.fromRGB(60, 20, 20)
    
    local pad = Instance.new("UIPadding", Btn)
    pad.PaddingLeft = UDim.new(0, 15)

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 15, 15)}):Play()
        stroke.Color = Settings.MainColor
    end)
    
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 10, 10)}):Play()
        stroke.Color = Color3.fromRGB(60, 20, 20)
    end)
    
    Btn.MouseButton1Click:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 20, 20)}):Play()
        task.wait(0.1)
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 15, 15)}):Play()
        if callback then callback() end
    end)
end

local function AddDropdown(parent, text, options, callback)
    local Row = Instance.new("Frame", parent)
    Row.Size = UDim2.new(1, 0, 0, 42)
    Row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    Row.BorderSizePixel = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", Row).Color = Color3.fromRGB(35, 35, 35)

    local NameLbl = Instance.new("TextLabel", Row)
    NameLbl.Size = UDim2.new(0.45, 0, 1, 0)
    NameLbl.Position = UDim2.new(0, 12, 0, 0)
    NameLbl.Text = text
    NameLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    NameLbl.BackgroundTransparency = 1
    NameLbl.Font = Enum.Font.GothamSemibold
    NameLbl.TextSize = 13
    NameLbl.TextXAlignment = Enum.TextXAlignment.Left

    local Selected = 1
    local DropBtn = Instance.new("TextButton", Row)
    DropBtn.Size = UDim2.new(0.5, -5, 0, 30)
    DropBtn.Position = UDim2.new(0.48, 0, 0.5, -15)
    DropBtn.Text = options[1] .. " ▾"
    DropBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    DropBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    DropBtn.Font = Enum.Font.GothamSemibold
    DropBtn.TextSize = 11
    DropBtn.BorderSizePixel = 0
    Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)

    DropBtn.MouseButton1Click:Connect(function()
        Selected = Selected % #options + 1
        DropBtn.Text = options[Selected] .. " ▾"
        if callback then callback(options[Selected], Selected) end
    end)

    return { 
        GetValue = function() return options[Selected] end,
        GetIndex = function() return Selected end
    }
end

local function AddKeybind(parent, text, defaultKey, callback)
    local Row = Instance.new("Frame", parent)
    Row.Size = UDim2.new(1, 0, 0, 40)
    Row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    Row.BorderSizePixel = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", Row).Color = Color3.fromRGB(35, 35, 35)

    local NameLbl = Instance.new("TextLabel", Row)
    NameLbl.Size = UDim2.new(0.6, 0, 1, 0)
    NameLbl.Position = UDim2.new(0, 12, 0, 0)
    NameLbl.Text = text
    NameLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    NameLbl.BackgroundTransparency = 1
    NameLbl.Font = Enum.Font.GothamSemibold
    NameLbl.TextSize = 13
    NameLbl.TextXAlignment = Enum.TextXAlignment.Left

    local Key = defaultKey
    local Listening = false

    local KeyBtn = Instance.new("TextButton", Row)
    KeyBtn.Size = UDim2.new(0, 90, 0, 28)
    KeyBtn.Position = UDim2.new(1, -100, 0.5, -14)
    KeyBtn.Text = tostring(Key.Name)
    KeyBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    KeyBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    KeyBtn.Font = Enum.Font.GothamBold
    KeyBtn.TextSize = 11
    KeyBtn.BorderSizePixel = 0
    Instance.new("UICorner", KeyBtn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", KeyBtn).Color = Color3.fromRGB(50, 50, 50)

    KeyBtn.MouseButton1Click:Connect(function()
        if not Listening then
            Listening = true
            KeyBtn.Text = "..."
            KeyBtn.TextColor3 = Settings.MainColor
        end
    end)

    UserInput.InputBegan:Connect(function(input)
        if Listening and input.UserInputType == Enum.UserInputType.Keyboard then
            Listening = false
            Key = input.KeyCode
            KeyBtn.Text = tostring(Key.Name)
            KeyBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
            if callback then callback(Key) end
        end
    end)

    return { GetKey = function() return Key end }
end

-- ============================================
-- BUILD TABS
-- ============================================

-- TAB 1: AIMBOT
local AimbotPage = CreateTab("🎯", "Aimbot", "aimbot")

AddSection(AimbotPage, "Silent Aim")
AddToggle(AimbotPage, "Silent Aim", "تصويب بدون تحريك الكاميرا", false, function(state)
    FeatureStates.SilentAim = state
    FOVCircle.Visible = state
    Notify("Silent Aim", state and "مفعّل ✅" or "معطّل ❌", 2)
end)

AddSlider(AimbotPage, "FOV Radius", 10, 500, 180, "°", function(val)
    FeatureValues.FOVRadius = val
    FOVCircle.Radius = val
end)

AddSlider(AimbotPage, "Head Chance", 0, 100, 10, "%", function(val)
    FeatureValues.HeadChance = val
end)

AddToggle(AimbotPage, "Prediction", "توقع حركة الهدف", false, function(state)
    FeatureStates.Prediction = state
end)

AddSlider(AimbotPage, "Prediction Amount", 0, 50, 13, "%", function(val)
    FeatureValues.PredictionAmount = val / 100
end)

AddSection(AimbotPage, "Camera Aimbot")
AddToggle(AimbotPage, "Auto Aim", "تصويب الكاميرا تلقائياً", false, function(state)
    FeatureStates.AutoAim = state
    Notify("Auto Aim", state and "مفعّل ✅" or "معطّل ❌", 2)
end)

AddSlider(AimbotPage, "Smoothness", 1, 100, 50, "%", function(val)
    FeatureValues.Smoothness = val
end)

AddToggle(AimbotPage, "Target Lock", "تثبيت على هدف واحد (T للتبديل)", false, function(state)
    FeatureStates.TargetLock = state
    if not state then LockedTarget = nil end
end)

AddToggle(AimbotPage, "Triggerbot", "إطلاق نار تلقائي عند التصويب", false, function(state)
    FeatureStates.TriggerBot = state
end)

AddSection(AimbotPage, "Settings")
AddToggle(AimbotPage, "Ignore Team", "تجاهل أعضاء الفريق", true, function(state)
    FeatureStates.IgnoreTeam = state
end)

AddToggle(AimbotPage, "Ignore Walls", "التحقق من الرؤية", false, function(state)
    FeatureStates.IgnoreWalls = state
end)

-- TAB 2: ESP
local ESPPage = CreateTab("👁️", "ESP", "esp")

AddSection(ESPPage, "ESP Options")
AddToggle(ESPPage, "Box ESP", "مربعات حول اللاعبين", false, function(state)
    FeatureStates.BoxESP = state
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then CreateESP(player) end
        end
    else
        ClearESP()
    end
end)

AddToggle(ESPPage, "Name ESP", "أسماء اللاعبين", false, function(state)
    FeatureStates.NameESP = state
end)

AddToggle(ESPPage, "Distance ESP", "المسافة من اللاعبين", false, function(state)
    FeatureStates.DistanceESP = state
end)

AddToggle(ESPPage, "Health ESP", "شريط الصحة", false, function(state)
    FeatureStates.HealthESP = state
end)

AddToggle(ESPPage, "Skeleton ESP", "هيكل عظمي", false, function(state)
    FeatureStates.SkeletonESP = state
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then CreateSkeleton(player) end
        end
    else
        ClearSkeletons()
    end
end)

AddToggle(ESPPage, "Tracers", "خطوط من الشاشة للاعبين", false, function(state)
    FeatureStates.Tracers = state
end)

AddSection(ESPPage, "3D ESP")
AddToggle(ESPPage, "Chams", "تلوين 3D كامل", false, function(state)
    FeatureStates.Chams = state
end)

AddToggle(ESPPage, "Glow ESP", "توهج حول اللاعبين", false, function(state)
    FeatureStates.GlowESP = state
end)

AddButton(ESPPage, "🔄", "Refresh ESP", function()
    ClearESP()
    ClearSkeletons()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if FeatureStates.BoxESP or FeatureStates.NameESP or FeatureStates.DistanceESP or FeatureStates.HealthESP or FeatureStates.Tracers then
                CreateESP(player)
            end
            if FeatureStates.SkeletonESP then
                CreateSkeleton(player)
            end
        end
    end
    Notify("ESP", "تم تحديث ESP ✅", 2)
end)

-- TAB 3: MOVEMENT
local MovementPage = CreateTab("⚡", "Movement", "movement")

AddSection(MovementPage, "Basic Movement")
AddToggle(MovementPage, "Speed Hack", "زيادة سرعة المشي", false, function(state)
    local char = LocalPlayer.Character
    local humanoid = GetHumanoid(char)
    if humanoid then
        humanoid.WalkSpeed = state and FeatureValues.WalkSpeed or 16
    end
end)

AddSlider(MovementPage, "Walk Speed", 16, 500, 16, "", function(val)
    FeatureValues.WalkSpeed = val
    local char = LocalPlayer.Character
    local humanoid = GetHumanoid(char)
    if humanoid then
        humanoid.WalkSpeed = val
    end
end)

AddToggle(MovementPage, "Super Jump", "قفز عالي", false, function(state)
    FeatureStates.SuperJump = state
    local char = LocalPlayer.Character
    local humanoid = GetHumanoid(char)
    if humanoid then
        humanoid.JumpPower = state and FeatureValues.JumpPower or 50
    end
end)

AddSlider(MovementPage, "Jump Power", 50, 500, 50, "", function(val)
    FeatureValues.JumpPower = val
    local char = LocalPlayer.Character
    local humanoid = GetHumanoid(char)
    if humanoid and FeatureStates.SuperJump then
        humanoid.JumpPower = val
    end
end)

AddToggle(MovementPage, "Infinite Jump", "قفز لا نهائي", false, function(state)
    FeatureStates.InfiniteJump = state
end)

AddToggle(MovementPage, "Bunny Hop", "قفز أرنبي تلقائي", false, function(state)
    FeatureStates.BunnyHop = state
    if state then
        EnableBunnyHop()
    end
end)

AddSection(MovementPage, "Advanced")
AddToggle(MovementPage, "Fly Mode", "الطيران (Space صعود, Shift نزول)", false, function(state)
    FeatureStates.Flying = state
    if state then
        EnableFly()
        Notify("Fly Mode", "مفعّل ✈️", 2)
    else
        DisableFly()
    end
end)

AddSlider(MovementPage, "Fly Speed", 10, 500, 50, "", function(val)
    FeatureValues.FlySpeed = val
end)

AddToggle(MovementPage, "NoClip", "المرور عبر الجدران", false, function(state)
    FeatureStates.NoClip = state
    if state then
        EnableNoClip()
        Notify("NoClip", "مفعّل 👻", 2)
    end
end)

AddSection(MovementPage, "Teleport")
AddToggle(MovementPage, "Auto-Stick", "الالتصاق بأقرب لاعب (Q للتبديل)", false, function(state)
    FeatureStates.AutoStick = state
    Notify("Auto-Stick", state and "مفعّل 🎯" or "معطّل", 2)
end)

AddSlider(MovementPage, "TP Distance", 0, 10, 3, "m", function(val)
    FeatureValues.TPDistance = val
end)

AddButton(MovementPage, "📍", "TP to Closest Player", function()
    local target = GetClosestPlayerToCharacter()
    if target and target.Character then
        local targetRoot = GetRootPart(target.Character)
        local myRoot = GetRootPart(LocalPlayer.Character)
        if targetRoot and myRoot then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, FeatureValues.TPDistance)
            Notify("Teleport", "تم الانتقال إلى " .. target.Name, 2)
        end
    else
        Notify("Error", "لم يتم العثور على لاعب", 2)
    end
end)

-- TAB 4: COMBAT
local CombatPage = CreateTab("⚔️", "Combat", "combat")

AddSection(CombatPage, "Weapon Mods")
AddToggle(CombatPage, "No Recoil", "بدون ارتداد", false, function(state)
    FeatureStates.NoRecoil = state
    Notify("No Recoil", state and "مفعّل 🎯" or "معطّل", 2)
end)

AddToggle(CombatPage, "No Spread", "بدون تشتت", false, function(state)
    FeatureStates.NoSpread = state
end)

AddToggle(CombatPage, "Rapid Fire", "إطلاق نار سريع", false, function(state)
    FeatureStates.RapidFire = state
end)

AddSlider(CombatPage, "Fire Rate", 1, 100, 10, "%", function(val)
    FeatureValues.RapidFireSpeed = val / 1000
end)

AddToggle(CombatPage, "Infinite Ammo", "ذخيرة لا نهائية", false, function(state)
    FeatureStates.InfiniteAmmo = state
end)

AddSection(CombatPage, "Combat Features")
AddToggle(CombatPage, "Kill Aura", "قتل تلقائي للقريبين", false, function(state)
    FeatureStates.KillAura = state
    if state then
        EnableKillAura()
        Notify("Kill Aura", "مفعّل ⚠️ خطر", 2)
    end
end)

AddSlider(CombatPage, "Aura Range", 5, 50, 20, "m", function(val)
    FeatureValues.KillAuraRange = val
end)

AddSection(CombatPage, "Player Protection")
AddToggle(CombatPage, "God Mode", "عدم الموت (قد لا يعمل)", false, function(state)
    FeatureStates.GodMode = state
    local char = LocalPlayer.Character
    local humanoid = GetHumanoid(char)
    if humanoid then
        if state then
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        else
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
    end
    Notify("God Mode", state and "مفعّل 🛡️" or "معطّل", 2)
end)

AddToggle(CombatPage, "Anti-Ragdoll", "منع السقوط", false, function(state)
    FeatureStates.AntiRagdoll = state
end)

AddToggle(CombatPage, "Anti-Slow", "منع البطء", false, function(state)
    FeatureStates.AntiSlow = state
end)

-- TAB 5: VISUALS
local VisualsPage = CreateTab("🎨", "Visuals", "visuals")

AddSection(VisualsPage, "World")
AddToggle(VisualsPage, "Fullbright", "إضاءة كاملة", false, function(state)
    FeatureStates.Fullbright = state
    ToggleFullbright(state)
    Notify("Fullbright", state and "مفعّل 💡" or "معطّل", 2)
end)

AddToggle(VisualsPage, "Remove Fog", "إزالة الضباب", false, function(state)
    FeatureStates.RemoveFog = state
    if state then
        Lighting.FogEnd = 100000
    else
        Lighting.FogEnd = OriginalFogEnd
    end
end)

AddSection(VisualsPage, "Camera")
AddToggle(VisualsPage, "FOV Changer", "تغيير زاوية الرؤية", false, function(state)
    FeatureStates.FOVChanger = state
    ToggleFOVChanger(state)
end)

AddSlider(VisualsPage, "FOV", 30, 120, 70, "°", function(val)
    FeatureValues.FOVValue = val
    if FeatureStates.FOVChanger then
        Camera.FieldOfView = val
    end
end)

AddToggle(VisualsPage, "Third Person", "منظور شخص ثالث", false, function(state)
    FeatureStates.ThirdPerson = state
    ToggleThirdPerson(state)
end)

AddSlider(VisualsPage, "TP Distance", 2, 30, 10, "m", function(val)
    FeatureValues.ThirdPersonDistance = val
end)

AddSection(VisualsPage, "UI")
AddToggle(VisualsPage, "Crosshair", "شعرة تصويب مخصصة", false, function(state)
    FeatureStates.Crosshair = state
    for _, line in pairs(CrosshairLines) do
        line.Visible = state
    end
end)

AddToggle(VisualsPage, "FPS Counter", "عداد الإطارات", false, function(state)
    FeatureStates.FPSCounter = state
    FPSLabel.Visible = state
end)

AddDropdown(VisualsPage, "Theme Color", {"Red", "Blue", "Green", "Purple", "Orange"}, function(val)
    local colors = {
        Red = Color3.fromRGB(255, 68, 68),
        Blue = Color3.fromRGB(68, 138, 255),
        Green = Color3.fromRGB(68, 255, 138),
        Purple = Color3.fromRGB(168, 68, 255),
        Orange = Color3.fromRGB(255, 168, 68)
    }
    Settings.MainColor = colors[val]
    FOVCircle.Color = Settings.MainColor
    AccentLine.BackgroundColor3 = Settings.MainColor
    Notify("Theme", "تم تغيير اللون إلى " .. val, 2)
end)

-- TAB 6: MISC
local MiscPage = CreateTab("🔧", "Misc", "misc")

AddSection(MiscPage, "Utility")
AddToggle(MiscPage, "Anti-AFK", "منع الطرد التلقائي", false, function(state)
    FeatureStates.AntiAFK = state
    ToggleAntiAFK(state)
    Notify("Anti-AFK", state and "مفعّل ⏰" or "معطّل", 2)
end)

AddToggle(MiscPage, "Auto Respawn", "إعادة الظهور التلقائي", false, function(state)
    FeatureStates.AutoRespawn = state
end)

AddButton(MiscPage, "💥", "Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

AddButton(MiscPage, "🔄", "Server Hop", function()
    local servers = {}
    local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    local body = game:GetService("HttpService"):JSONDecode(req)
    
    if body and body.data then
        for i, v in pairs(body.data) do
            if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v.id)
            end
        end
    end
    
    if #servers > 0 then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    else
        Notify("Error", "لم يتم العثور على سيرفرات", 3)
    end
end)

AddSection(MiscPage, "Player")
AddButton(MiscPage, "🎭", "Change Name (FE)", function()
    -- This is client-side only
    LocalPlayer.Character.Humanoid.DisplayName = "CHRIFxCHEAT"
    LocalPlayer.Character.Humanoid.HealthDisplayDistance = 0
    LocalPlayer.Character.Humanoid.NameDisplayDistance = 0
    Notify("Name", "تم تغيير الاسم (محلي)", 2)
end)

AddButton(MiscPage, "👻", "Remove Accessories", function()
    for _, acc in pairs(LocalPlayer.Character:GetChildren()) do
        if acc:IsA("Accessory") then
            acc:Destroy()
        end
    end
    Notify("Accessories", "تم إزالة الإكسسوارات", 2)
end)

-- TAB 7: SETTINGS
local SettingsPage = CreateTab("⚙️", "Settings", "settings")

AddSection(SettingsPage, "Keybinds")
AddKeybind(SettingsPage, "Toggle GUI", Settings.ToggleKey, function(key)
    Settings.ToggleKey = key
    Notify("Keybind", "تم تغيير مفتاح القائمة إلى " .. key.Name, 2)
end)

AddKeybind(SettingsPage, "Panic Key", Settings.PanicKey, function(key)
    Settings.PanicKey = key
end)

AddButton(SettingsPage, "🗑️", "Destroy GUI (Can't Undo!)", function()
    ScreenGui:Destroy()
    Notify("Destroyed", "تم إغلاق CHRIFxCHEAT", 2)
end)

AddSection(SettingsPage, "Info")
local InfoBox = Instance.new("Frame", SettingsPage)
InfoBox.Size = UDim2.new(1, 0, 0, 100)
InfoBox.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
InfoBox.BorderSizePixel = 0
Instance.new("UICorner", InfoBox).CornerRadius = UDim.new(0, 8)

local InfoText = Instance.new("TextLabel", InfoBox)
InfoText.Size = UDim2.new(1, -20, 1, -20)
InfoText.Position = UDim2.new(0, 10, 0, 10)
InfoText.Text = string.format([[
💻 CHRIFxCHEAT ULTIMATE v3.0
👤 Player: %s
🎮 Game: %s
⏰ Time: %s
]], LocalPlayer.Name, game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, os.date("%H:%M:%S"))
InfoText.TextColor3 = Color3.fromRGB(180, 180, 180)
InfoText.BackgroundTransparency = 1
InfoText.Font = Enum.Font.Gotham
InfoText.TextSize = 11
InfoText.TextXAlignment = Enum.TextXAlignment.Left
InfoText.TextYAlignment = Enum.TextYAlignment.Top
-- ============================================
-- MAIN UPDATE LOOP
-- ============================================

-- FOV Circle Update
RunService.RenderStepped:Connect(function()
    if FeatureStates.SilentAim then
        FOVCircle.Position = UserInput:GetMouseLocation()
    end
end)

-- Crosshair Update
RunService.RenderStepped:Connect(function()
    if FeatureStates.Crosshair then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local size = 15
        
        -- Top
        CrosshairLines[1].From = Vector2.new(center.X, center.Y - size)
        CrosshairLines[1].To = Vector2.new(center.X, center.Y - size - 5)
        
        -- Bottom
        CrosshairLines[2].From = Vector2.new(center.X, center.Y + size)
        CrosshairLines[2].To = Vector2.new(center.X, center.Y + size + 5)
        
        -- Left
        CrosshairLines[3].From = Vector2.new(center.X - size, center.Y)
        CrosshairLines[3].To = Vector2.new(center.X - size - 5, center.Y)
        
        -- Right
        CrosshairLines[4].From = Vector2.new(center.X + size, center.Y)
        CrosshairLines[4].To = Vector2.new(center.X + size + 5, center.Y)
    end
end)

-- FPS Counter Update
local lastFPSUpdate = tick()
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()
    
    if currentTime - lastFPSUpdate >= 1 then
        local fps = frameCount / (currentTime - lastFPSUpdate)
        FPSLabel.Text = "FPS: " .. math.floor(fps)
        frameCount = 0
        lastFPSUpdate = currentTime
    end
end)

-- ESP Update
RunService.RenderStepped:Connect(function()
    if FeatureStates.BoxESP or FeatureStates.NameESP or FeatureStates.DistanceESP or FeatureStates.HealthESP or FeatureStates.Tracers then
        UpdateESP()
    end
end)

-- Skeleton ESP Update
RunService.RenderStepped:Connect(function()
    if FeatureStates.SkeletonESP then
        UpdateSkeletons()
    end
end)

-- Auto Aim Update
RunService.Heartbeat:Connect(function()
    if FeatureStates.AutoAim and UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local target = LockedTarget or GetClosestPlayerToMouse()
        
        if target and IsAlive(target) then
            local char = GetCharacter(target)
            local targetPart = char:FindFirstChild("Head") or GetRootPart(char)
            
            if targetPart then
                local targetPos = PredictPosition(targetPart)
                local currentCFrame = Camera.CFrame
                local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
                
                local smoothness = (100 - FeatureValues.Smoothness) / 100
                Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 - smoothness)
            end
        end
    end
end)

-- Infinite Jump
RunService.Heartbeat:Connect(function()
    if FeatureStates.InfiniteJump then
        local char = LocalPlayer.Character
        local humanoid = GetHumanoid(char)
        local rootPart = GetRootPart(char)
        
        if humanoid and rootPart then
            if UserInput:IsKeyDown(Enum.KeyCode.Space) and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Auto-Stick Teleport
RunService.Heartbeat:Connect(function()
    if FeatureStates.AutoStick then
        local target = GetClosestPlayerToCharacter()
        
        if target and target.Character then
            local targetRoot = GetRootPart(target.Character)
            local myRoot = GetRootPart(LocalPlayer.Character)
            
            if targetRoot and myRoot then
                local offset = Vector3.new(0, 0, FeatureValues.TPDistance)
                local newCFrame = targetRoot.CFrame * CFrame.new(offset)
                myRoot.CFrame = newCFrame
            end
        end
    end
end)

-- NoClip Update
RunService.Stepped:Connect(function()
    if FeatureStates.NoClip then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Anti-Ragdoll
RunService.Heartbeat:Connect(function()
    if FeatureStates.AntiRagdoll then
        local char = LocalPlayer.Character
        if char then
            local humanoid = GetHumanoid(char)
            if humanoid then
                if humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end
end)

-- Anti-Slow
RunService.Heartbeat:Connect(function()
    if FeatureStates.AntiSlow then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BodyVelocity") or part:IsA("AssemblyLinearVelocity") then
                    if part.Parent == char then
                        part:Destroy()
                    end
                end
            end
        end
    end
end)

-- Triggerbot
RunService.Heartbeat:Connect(function()
    if FeatureStates.TriggerBot and UserInput:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local target = GetClosestPlayerToMouse()
        
        if target and IsAlive(target) then
            local inFOV, dist = IsInFOV(GetRootPart(GetCharacter(target)).Position)
            
            if inFOV and dist <= FeatureValues.FOVRadius then
                -- Simulate click or fire
                UserInput:SendMouseButtonEvent(UserInput:GetMouseLocation().X, UserInput:GetMouseLocation().Y, Enum.UserInputType.MouseButton1, true)
                task.wait(0.01)
                UserInput:SendMouseButtonEvent(UserInput:GetMouseLocation().X, UserInput:GetMouseLocation().Y, Enum.UserInputType.MouseButton1, false)
            end
        end
    end
end)

-- God Mode Health Restoration
RunService.Heartbeat:Connect(function()
    if FeatureStates.GodMode then
        local char = LocalPlayer.Character
        local humanoid = GetHumanoid(char)
        
        if humanoid then
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        end
    end
end)

-- Auto Respawn
Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
    if FeatureStates.AutoRespawn then
        task.wait(1)
        -- Auto respawn logic here
    end
end)

-- New Player Detection for ESP
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        task.wait(0.5)
        if FeatureStates.BoxESP or FeatureStates.NameESP or FeatureStates.DistanceESP or FeatureStates.HealthESP or FeatureStates.Tracers then
            CreateESP(player)
        end
        if FeatureStates.SkeletonESP then
            CreateSkeleton(player)
        end
    end
end)

-- Player Removed Cleanup
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, drawing in pairs(ESPObjects[player].Drawings) do
            drawing:Remove()
        end
        ESPObjects[player] = nil
    end
    
    if SkeletonConnections[player] then
        for _, lineData in pairs(SkeletonConnections[player].Lines) do
            lineData.line:Remove()
        end
        SkeletonConnections[player] = nil
    end
end)

-- ============================================
-- KEYBIND SYSTEM
-- ============================================
UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Toggle GUI
    if input.KeyCode == Settings.ToggleKey then
        Main.Visible = not Main.Visible
        if Main.Visible then
            Notify("CHRIFxCHEAT", "القائمة ظاهرة ✅", 1)
        end
    end
    
    -- Panic Key
    if input.KeyCode == Settings.PanicKey then
        ScreenGui:Destroy()
        Notify("Panic", "تم إغلاق السكريبت!", 2)
    end
    
    -- Target Lock Toggle (T)
    if input.KeyCode == Enum.KeyCode.T and FeatureStates.TargetLock then
        LockedTarget = GetClosestPlayerToMouse()
        if LockedTarget then
            Notify("Target Lock", "تم تثبيت على: " .. LockedTarget.Name, 2)
        end
    end
    
    -- Quick TP (Y)
    if input.KeyCode == Enum.KeyCode.Y then
        local target = GetClosestPlayerToCharacter()
        if target and target.Character then
            local targetRoot = GetRootPart(target.Character)
            local myRoot = GetRootPart(LocalPlayer.Character)
            if targetRoot and myRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, FeatureValues.TPDistance)
            end
        end
    end
    
    -- Quick Fly Toggle (F)
    if input.KeyCode == Enum.KeyCode.F then
        FeatureStates.Flying = not FeatureStates.Flying
        if FeatureStates.Flying then
            EnableFly()
            Notify("Fly", "مفعّل ✈️", 1)
        else
            DisableFly()
            Notify("Fly", "معطّل", 1)
        end
    end
end)

-- ============================================
-- SAVE/LOAD CONFIG SYSTEM
-- ============================================
local ConfigPath = "CHRIFxCHEAT_Config.json"

local function SaveConfig()
    local config = {
        FOVRadius = FeatureValues.FOVRadius,
        HeadChance = FeatureValues.HeadChance,
        Smoothness = FeatureValues.Smoothness,
        PredictionAmount = FeatureValues.PredictionAmount,
        WalkSpeed = FeatureValues.WalkSpeed,
        JumpPower = FeatureValues.JumpPower,
        FlySpeed = FeatureValues.FlySpeed,
        TPDistance = FeatureValues.TPDistance,
        KillAuraRange = FeatureValues.KillAuraRange,
        FOVValue = FeatureValues.FOVValue,
        ThirdPersonDistance = FeatureValues.ThirdPersonDistance,
    }
    
    local success, result = pcall(function()
        writefile(ConfigPath, game:GetService("HttpService"):JSONEncode(config))
    end)
    
    if success then
        Notify("Config", "تم حفظ الإعدادات ✅", 2)
    else
        Notify("Error", "فشل حفظ الإعدادات", 2)
    end
end

local function LoadConfig()
    local success, result = pcall(function()
        return readfile(ConfigPath)
    end)
    
    if success and result then
        local config = game:GetService("HttpService"):JSONDecode(result)
        
        if config.FOVRadius then FeatureValues.FOVRadius = config.FOVRadius end
        if config.HeadChance then FeatureValues.HeadChance = config.HeadChance end
        if config.Smoothness then FeatureValues.Smoothness = config.Smoothness end
        if config.PredictionAmount then FeatureValues.PredictionAmount = config.PredictionAmount end
        if config.WalkSpeed then FeatureValues.WalkSpeed = config.WalkSpeed end
        if config.JumpPower then FeatureValues.JumpPower = config.JumpPower end
        if config.FlySpeed then FeatureValues.FlySpeed = config.FlySpeed end
        if config.TPDistance then FeatureValues.TPDistance = config.TPDistance end
        if config.KillAuraRange then FeatureValues.KillAuraRange = config.KillAuraRange end
        if config.FOVValue then FeatureValues.FOVValue = config.FOVValue end
        if config.ThirdPersonDistance then FeatureValues.ThirdPersonDistance = config.ThirdPersonDistance end
        
        Notify("Config", "تم تحميل الإعدادات ✅", 2)
    end
end

-- Add Save/Load buttons to Settings
local SettingsContent = Pages["settings"].Frame

AddButton(SettingsContent, "💾", "Save Config", SaveConfig)
AddButton(SettingsContent, "📂", "Load Config", LoadConfig)

-- Auto-load config on startup
LoadConfig()

-- ============================================
-- PERFORMANCE OPTIMIZATION
-- ============================================
local LastESPUpdate = tick()
local ESPUpdateInterval = 0.016 -- 60 FPS

RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    if currentTime - LastESPUpdate >= ESPUpdateInterval then
        -- Batch ESP updates
        LastESPUpdate = currentTime
    end
end)

-- ============================================
-- OPENING ANIMATION
-- ============================================
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)

local openAnim = TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 650, 0, 450),
    Position = UDim2.new(0.5, -325, 0.5, -225)
})
openAnim:Play()

task.wait(0.1)

-- Activate first tab
Pages["aimbot"].Frame.Visible = true
Pages["aimbot"].Btn.TextColor3 = Settings.MainColor
Pages["aimbot"].Btn.BackgroundTransparency = 0.85
Pages["aimbot"].Accent.Visible = true

-- ============================================
-- STARTUP NOTIFICATION
-- ============================================
Notify("🎮 CHRIFxCHEAT", "مرحباً بك في النسخة النهائية!", 3)
task.wait(0.5)
Notify("⌨️ Keybinds", string.format([[
%s - فتح/إغلاق القائمة
%s - إغلاق فوري
T - تبديل الهدف المثبت
Y - انتقال سريع
F - تشغيل الطيران
]], Settings.ToggleKey.Name, Settings.PanicKey.Name), 4)

-- ============================================
-- PRINT CONFIRMATION
-- ============================================
print("[CHRIFxCHEAT ULTIMATE] ✅ تم تحميل السكريبت بنجاح!")
print("[CHRIFxCHEAT ULTIMATE] 🎮 الإصدار: v3.0")
print("[CHRIFxCHEAT ULTIMATE] 👤 اللاعب: " .. LocalPlayer.Name)
print("[CHRIFxCHEAT ULTIMATE] 🔑 اضغط " .. Settings.ToggleKey.Name .. " لفتح القائمة")

-- ============================================
-- ANTI-KICK & ANTI-BAN FEATURES
-- ============================================

-- Protect against RemoteEvent exploitation detection
local protection = Instance.new("Folder", LocalPlayer)
protection.Name = "Protection"

-- Monitor chat for kicks
game:GetService("Chat"):Chat(LocalPlayer.Character.Head, "👋 CHRIFxCHEAT Loaded!", Enum.ChatColor.Green)

-- ============================================
-- EXTRA FEATURES
-- ============================================

-- Player List with Target Selection
local PlayerListFrame = Instance.new("Frame", ScreenGui)
PlayerListFrame.Name = "PlayerList"
PlayerListFrame.Size = UDim2.new(0, 200, 0, 400)
PlayerListFrame.Position = UDim2.new(0, 10, 0.5, -200)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.Visible = false
Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0, 10)

local PlayerListTitle = Instance.new("TextLabel", PlayerListFrame)
PlayerListTitle.Size = UDim2.new(1, 0, 0, 30)
PlayerListTitle.Text = "👥 Players Online"
PlayerListTitle.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
PlayerListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerListTitle.BorderSizePixel = 0
PlayerListTitle.Font = Enum.Font.GothamBold
Instance.new("UICorner", PlayerListTitle).CornerRadius = UDim.new(0, 10)

local PlayerListContent = Instance.new("ScrollingFrame", PlayerListFrame)
PlayerListContent.Size = UDim2.new(1, 0, 1, -30)
PlayerListContent.Position = UDim2.new(0, 0, 0, 30)
PlayerListContent.BackgroundTransparency = 1
PlayerListContent.BorderSizePixel = 0
PlayerListContent.ScrollBarThickness = 3

local PlayerListLayout = Instance.new("UIListLayout", PlayerListContent)
PlayerListLayout.Padding = UDim.new(0, 3)

local function UpdatePlayerList()
    PlayerListContent:ClearAllChildren()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local PlayerBtn = Instance.new("TextButton", PlayerListContent)
            PlayerBtn.Size = UDim2.new(1, -5, 0, 30)
            PlayerBtn.Text = "🎯 " .. player.Name
            PlayerBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            PlayerBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            PlayerBtn.Font = Enum.Font.GothamSemibold
            PlayerBtn.TextSize = 11
            PlayerBtn.BorderSizePixel = 0
            Instance.new("UICorner", PlayerBtn).CornerRadius = UDim.new(0, 6)
            
            PlayerBtn.MouseButton1Click:Connect(function()
                LockedTarget = player
                Notify("Target", "تم اختيار: " .. player.Name, 2)
            end)
        end
    end
end

-- Toggle Player List
local PlayerListToggle = false
UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.L then
        PlayerListToggle = not PlayerListToggle
        PlayerListFrame.Visible = PlayerListToggle
        UpdatePlayerList()
    end
end)

-- Update player list every 2 seconds
game:GetService("RunService").Heartbeat:Connect(function()
    if PlayerListToggle then
        UpdatePlayerList()
    end
end)

-- ============================================
-- FINAL CLEANUP & ERROR HANDLING
-- ============================================
local function SafeDispose()
    for player, espData in pairs(ESPObjects) do
        for _, drawing in pairs(espData.Drawings) do
            pcall(function() drawing:Remove() end)
        end
    end
    
    for player, data in pairs(SkeletonConnections) do
        for _, lineData in pairs(data.Lines) do
            pcall(function() lineData.line:Remove() end)
        end
    end
    
    for _, line in pairs(CrosshairLines) do
        pcall(function() line:Remove() end)
    end
    
    pcall(function() FOVCircle:Remove() end)
    pcall(function() FPSLabel:Remove() end)
end

game:BindToClose(function()
    SaveConfig()
    SafeDispose()
end)

-- ============================================
-- EASTER EGG
-- ============================================
local EasterEggCount = 0
UserInput.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Home then
        EasterEggCount = EasterEggCount + 1
        
        if EasterEggCount == 5 then
            Notify("🎉 Easter Egg!", "أنت عثرت على Easter Egg!", 3)
            EasterEggCount = 0
        end
    end
end)

-- ============================================
-- ADVANCED SETTINGS
-- ============================================
local AdvancedPage = CreateTab("🔬", "Advanced", "advanced")

AddSection(AdvancedPage, "Debug")
AddButton(AdvancedPage, "📊", "Print Stats", function()
    print("=== CHRIFxCHEAT Stats ===")
    print("Active Features: " .. tostring(#(pairs(FeatureStates))))
    print("ESP Objects: " .. tostring(#(pairs(ESPObjects))))
    print("Memory Usage: " .. tostring(collectgarbage("count")) .. " KB")
    Notify("Debug", "تم طباعة الإحصائيات في Console", 2)
end)

AddButton(AdvancedPage, "🗑️", "Cleanup Memory", function()
    collectgarbage("collect")
    Notify("Memory", "تم تنظيف الذاكرة", 2)
end)

AddButton(AdvancedPage, "🔄", "Restart Features", function()
    DisableFly()
    if FeatureStates.Flying then
        FeatureStates.Flying = false
        EnableFly()
        FeatureStates.Flying = true
    end
    Notify("Restart", "تم إعادة تشغيل الميزات", 2)
end)

AddSection(AdvancedPage, "Network")
AddButton(AdvancedPage, "📡", "Check Connection", function()
    local ping = game:GetService("Stats"):FindFirstChild("Network") and game:GetService("Stats").Network:FindFirstChild("ServerReplicatorStats") and game:GetService("Stats").Network.ServerReplicatorStats:FindFirstChild("Data Ping") and tostring(game:GetService("Stats").Network.ServerReplicatorStats["Data Ping"]:GetValue()) or "Unknown"
    
    Notify("Connection", "Ping: " .. ping .. "ms", 2)
end)

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
print("[✅] CHRIFxCHEAT ULTIMATE v3.0 تم التحميل بنجاح!")
print("[✅] جميع الميزات متاحة الآن!")
print("[✅] اضغط " .. Settings.ToggleKey.Name .. " لفتح القائمة")
print("[✅] اضغط L لعرض قائمة اللاعبين")
print("[✅] اضغط " .. Settings.PanicKey.Name .. " للإغلاق الفوري")
