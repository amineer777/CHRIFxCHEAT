-- // Settings \\ --
local InfiniteJumpEnabled = true

-- // Services \\ --
local UserInputService = game:GetService("UserInputService")

-- // Function \\ --
UserInputService.JumpRequest:Connect(function()
    -- التحقق مما إذا كان السكريبت مفعلاً وأن اللاعب المحلي موجود
    if InfiniteJumpEnabled and game.Players.LocalPlayer and game.Players.LocalPlayer.Character then
        local Character = game.Players.LocalPlayer.Character
        
        -- العثور على الـ Humanoid (المسؤول عن الحركة والقفز)
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        
        -- التحقق من وجود الـ Humanoid
        if Humanoid then
            -- تغيير حالة الـ Humanoid ليسمح بالقفز مجدداً (هذا هو السر)
            Humanoid:ChangeState("Jumping")
        end
    end
end)

-- رسالة للتأكد من تشغيل السكريبت (ستظهر في الـ Console)
print("CHRIFxCHEAT: Infinite Jump Script Loaded!")
