local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local NotificationFrame = PlayerGui:WaitForChild("CoreHUD"):WaitForChild("Left")

local InterfaceTweens = require(ReplicatedStorage.Shared.configs.InterfaceTweens)
local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local NotificationController = Knit.CreateController({
	Name = "NotificationController",
})

function NotificationController:CreateIndicator(infodetails)
	local KickTemplate = if infodetails.IndicatorType == "KickHit" or infodetails.IndicatorType == "AuraHit"
		then NotificationFrame.NotificationTemplates.KickHit:Clone()
		elseif infodetails.IndicatorType == "Knockout" then NotificationFrame.NotificationTemplates.Knockout:Clone()
		elseif infodetails.IndicatorType == "Wipeout" then NotificationFrame.NotificationTemplates.Wipeout:Clone()
		elseif infodetails.IndicatorType == "Hit" then NotificationFrame.NotificationTemplates.Hit:Clone()
		else nil
	if not KickTemplate then
		warn("Kick Template Data didnt find")
		return
	end
	KickTemplate.Parent = NotificationFrame.NotificationConteyner
	KickTemplate.Visible = true
	KickTemplate.LayoutOrder = #NotificationFrame.NotificationConteyner:GetChildren()
	task.delay(3, function()
		KickTemplate:Destroy()
	end)
end

function NotificationController:KnitInit()
	self.NotificationService = Knit.GetService("NotificationService")
end

function NotificationController:KnitStart()
	self.NotificationService.CreateIndicator:Connect(function(infodetails)
		self:CreateIndicator(infodetails)
	end)
end

return NotificationController
