local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
--local Promise = require(Knit.Util.Promise)

local AttackService = Knit.CreateService({
	Name = "AttackService",
	Client = { HiglightChange = Knit.CreateSignal(), Attack = Knit.CreateSignal() },
})

function AttackService:Attack(player, hittedplayer, otherdatas)
	local attackingPlayerDatas = self.PlayerService.PlayerDatas[player.UserId] or nil
	if not attackingPlayerDatas then
		warn("Playerin Datasi yok la")
	end

	--self.StatusService:AddStatus(player, "Slowed", { RemainingTime = 10 })

	if type(attackingPlayerDatas.StylePassive) == "boolean" then
		self.PassiveService:StartStylePassive(player)
	end
	if type(attackingPlayerDatas.AuraPassive) ~= "boolean" then
		self.PassiveService:AddPassivePoint(player, "Aura", 2)
	elseif type(attackingPlayerDatas.AuraPassive) == "boolean" and not attackingPlayerDatas.FusionPassive then
		self.PassiveService:StartAuraPassive(player)
	end
	self.PassiveService:AddPassivePoint(hittedplayer, "Style", 2)
end

function AttackService:AuraChanings(player, AuraStatus)
	print(player, AuraStatus)
end

function AttackService:KnitInit()
	self.StatusService = Knit.GetService("StatusService")
	self.PassiveService = Knit.GetService("PassiveService")
	self.PlayerService = Knit.GetService("PlayerService")
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
