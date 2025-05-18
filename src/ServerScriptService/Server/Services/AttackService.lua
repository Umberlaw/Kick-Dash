local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
--local Promise = require(Knit.Util.Promise)

local AttackService = Knit.CreateService({
	Name = "AttackService",
	Client = { HiglightChange = Knit.CreateSignal(), Attack = Knit.CreateSignal() },
})

function AttackService:Attack(player, hittedplayer, otherdatas)
	print(player, hittedplayer, otherdatas)
	self.StatusService:AddStatus(player, "Slowed", { RemainingTime = 10 })
end

function AttackService:AuraChanings(player, AuraStatus)
	print(player, AuraStatus)
end

function AttackService:KnitInit()
	self.StatusService = Knit.GetService("StatusService")
end

function AttackService:KnitStart()
	self.Client.HiglightChange:Connect(function(player, AuraStatus)
		self:AuraChanings(player, AuraStatus)
	end)
	self.Client.Attack:Connect(function(player, AttackingPlayer, otherdatas)
		self:Attack(player, AttackingPlayer, otherdatas)
	end)
end

return AttackService
