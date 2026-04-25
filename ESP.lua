local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- وظيفة إضافة الـ ESP لكل لاعب
local function applyESP(player)
    local function createHighlight(char)
        if not char then return end
        
        -- انتظار بسيط لضمان تحميل الشخصية بالكامل
        task.wait(0.2)
        
        -- التأكد من عدم تكرار الـ ESP على نفس اللاعب
        if not char:FindFirstChild("CHRIF_HIGHLIGHT") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "CHRIF_HIGHLIGHT"
            highlight.Parent = char
            
            -- إعدادات الألوان (يمكنك تغييرها حسب ذوقك)
            highlight.FillColor = Color3.fromRGB(0, 255, 255) -- لون الجسم (Cyan)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- لون الحدود (أبيض)
            highlight.FillTransparency = 0.5 -- شفافية اللون الداخلي
            highlight.OutlineTransparency = 0 -- شفافية الحدود
        end
    end

    -- تشغيل الـ ESP عند ظهور اللاعب أو إعادة إحيائه
    player.CharacterAdded:Connect(createHighlight)
    if player.Character then
        createHighlight(player.Character)
    end
end

-- تفعيل الـ ESP لجميع اللاعبين الموجودين حالياً
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        applyESP(p)
    end
end

-- تفعيل الـ ESP لأي لاعب جديد يدخل السيرفر
Players.PlayerAdded:Connect(applyESP)
