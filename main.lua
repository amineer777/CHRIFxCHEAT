local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "CHRIFxCHEAT | AMINE ER",
   LoadingTitle = "جاري تشغيل محرك CHRIF المطور...",
   LoadingSubtitle = "بواسطة المطور AMINE ER",
   ConfigurationSaving = {Enabled = false}
})

local MainTab = Window:CreateTab("الرئيسية", 4483362458)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

_G.ESP = false
_G.NoReload = false
_G.AutoAim = false
_G.ScopeAim = false

--- [ وظيفة الـ ESP ] ---
local function applyESP(player)
    local function createHighlight(char)
        if not char then return end
        task.wait(0.2)
        if not char:FindFirstChild("CHRIF_HIGHLIGHT") then
            local highlight = Instance.new("Highlight", char)
            highlight.Name = "CHRIF_HIGHLIGHT"
            highlight.FillColor = Color3.fromRGB(0, 255, 255)
        end
    end
    player.CharacterAdded:Connect(createHighlight)
    if player.Character then createHighlight(player.Character) end
end

--- [ الأزرار ] ---

MainTab:CreateToggle({
   Name = "كشف اللاعبين (ESP)",
   CurrentValue = false,
   Callback = function(Value)
       _G.ESP = Value
       if Value then
           for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then applyESP(p) end end
       else
           for _, p in pairs(Players:GetPlayers()) do
               if p.Character and p.Character:FindFirstChild("CHRIF_HIGHLIGHT") then p.Character.CHRIF_HIGHLIGHT:Destroy() end
           end
       end
   end,
})

MainTab:CreateToggle({
   Name = "إزالة ريلود (هجومي جِدًا)",
   CurrentValue = false,
   Callback = function(Value)
       _G.NoReload = Value
   end,
})

MainTab:CreateToggle({
   Name = "أيمبوت تلقائي (إطلاق نار)",
   CurrentValue = false,
   Callback = function(Value) _G.AutoAim = Value; if Value then _G.ScopeAim = false end end,
})

MainTab:CreateToggle({
   Name = "أيم سكوب (زر أيمن)",
   CurrentValue = false,
   Callback = function(Value) _G.ScopeAim = Value; if Value then _G.AutoAim = false end end,
})

--- [ الحلقة المركزية - منطق التدمير ] ---

RunService.RenderStepped:Connect(function()
    -- 1. التعامل مع الريلود والدائرة بشكل نهائي
    if _G.NoReload then
        -- البحث عن أي دائرة أو شريط تقدم وحذفه فوراً
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, v in pairs(pGui:GetDescendants()) do
                -- حذف أي واجهة تحتوي على اسم ريلود أو دوران أو انتظار
                if v:IsA("GuiObject") and v.Visible then
                    if string.find(string.lower(v.Name), "reload") or 
                       string.find(string.lower(v.Name), "cooldown") or 
                       string.find(string.lower(v.Name), "bar") or 
                       string.find(string.lower(v.Name), "circle") then
                        v:Destroy() -- تدمير الواجهة بدلاً من إخفائها
                    end
                end
            end
        end

        -- تصفير المتغيرات داخل السلاح نفسه بقوة
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            for _, val in pairs(tool:GetDescendants()) do
                if val:IsA("NumberValue") or val:IsA("IntValue") or val:IsA("StringValue") then
                    val.Value = 0 -- جعل أي قيمة انتظار تساوي صفر
                end
            end
        end
    end

    -- 2. منطق الأيمبوت
    local isShooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if (_G.AutoAim and isShooting) or (_G.ScopeAim and isAiming) then
        local closest = nil
        local maxDist = 400
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local pos, onScreen = Camera:WorldToScreenPoint(p.Character.Head.Position)
                if onScreen then
                    local center = Vector2.new(Camera.ViewportSize.X/2 + 30, Camera.ViewportSize.Y/2)
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < maxDist then
                        maxDist = dist
                        closest = p
                    end
                end
            end
        end
        if closest then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position)
        end
    end
end)
