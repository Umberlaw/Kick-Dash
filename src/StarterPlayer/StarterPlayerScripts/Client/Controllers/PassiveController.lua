local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local LocalPlayer = Players.LocalPlayer

local PassiveController = Knit.CreateController({
	Name = "PassiveController",
	MainHud = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("CoreHUD"),
})

function PassiveController:SetPassiveIndicators(PassiveType, Count)
	local passiveIndicatorArea = self.MainHud
		:FindFirstChild("Bottom")
		:FindFirstChild("PassiveRelatives")
		:FindFirstChild(PassiveType .. "PassiveBar")
		:FindFirstChild("Points") or nil
	if passiveIndicatorArea and Count > 0 then
		for i = 1, Count do
			local targetIndicator = passiveIndicatorArea:FindFirstChild("Point_" .. tostring(i)) or nil
			if targetIndicator then
				local targetPont = targetIndicator:FindFirstChild("PassivePoint_" .. PassiveType)
				if targetPont then
					targetPont.Visible = true
				end
			end
		end
	elseif passiveIndicatorArea and Count <= 0 then
		for _, allPassivePoints in passiveIndicatorArea:GetChildren() do
			allPassivePoints:FindFirstChild("PassivePoint_" .. PassiveType).Visible = false
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
