local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local NotificationService = Knit.CreateService({
	Name = "NotificationService",
	Client = { CreateIndicator = Knit.CreateSignal() },
})

function NotificationService:CreateLeftInfo(targetplayer, infoDetails)
	self.Client.CreateIndicator:Fire(targetplayer, infoDetails)
end

function NotificationService:KnitInit() end

function NotificationService:KnitStart() end

return NotificationService
