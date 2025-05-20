local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local LocalPlayer = Players.LocalPlayer

local PassiveController = Knit.CreateController({
	Name = "PassiveController",
	MainHud = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainHUD"),
})

function PassiveController:SetPassiveIndicators(PassiveType, Count)
	print(PassiveType)
	local passiveIndicatorArea = self.MainHud:FindFirstChild("BottomSide"):FindFirstChild(PassiveType .. "PassiveBar")
		or nil
	if passiveIndicatorArea then
		for i = 1, Count do
			local targetIndicator = passiveIndicatorArea.Bars:FindFirstChild(tostring(i)) or nil
			if targetIndicator then
				targetIndicator.ImageColor3 = Color3.fromRGB(0, 255, 0)
			end
		end
	end
end

function PassiveController:KnitInit()
	self.PassiveService = Knit.GetService("PassiveService")
end

function PassiveController:KnitStart()
	self.PassiveService.PassiveActivate:Connect(function(PassiveType, Count)
		self:SetPassiveIndicators(PassiveType, Count)
	end)
end

return PassiveController
