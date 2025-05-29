local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kick = {}
local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

Kick.Services = {}

function Kick:StartRelease(player)
	print(player.Name, "ReleasedThe Mouse")
end

function Kick:Start(player)
	self.Services["PlayerService"] = self.Services["PlayerService"] or Knit.GetService("PlayerService")
	self.Services["StatusService"] = self.Services["StatusService"] or Knit.GetService("StatusService")
	self.Services["EffectService"] = self.Services["EffectService"] or Knit.GetService("EffectService")
	print(player.Name, " Kick Passifi tetikledi", "50 can overhealth olarak eklenecek")
	self.Services["StatusService"]:ActivateDebuff(player, "OverHealth", 100)
end

return Kick
