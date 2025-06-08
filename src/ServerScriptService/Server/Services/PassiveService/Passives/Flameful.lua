local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Flameful = {}
local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

Flameful.Services = {}

function Flameful:StartRelease(player)
	print(player.Name, "ReleasedThe Mouse")
end

function Flameful:Start(player, otherdatas)
	print(otherdatas)
	self.Services["PlayerService"] = self.Services["PlayerService"] or Knit.GetService("PlayerService")
	self.Services["StatusService"] = self.Services["StatusService"] or Knit.GetService("StatusService")
	self.Services["EffectService"] = self.Services["EffectService"] or Knit.GetService("EffectService")

	self.Services["StatusService"]:AddStatus(otherdatas.HittedPlayer, "Burned", { RemainingTime = 10 })
end

return Flameful
