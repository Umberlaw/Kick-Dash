local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)
local Knit = require(ReplicatedStorage.Packages.knit)
--local Promise = require(Knit.Util.Promise)

local AttackService = Knit.CreateService({
	Name = "AttackService",
	Client = {
		HiglightChange = Knit.CreateSignal(),
		Attack = Knit.CreateSignal(),
		PassiveRelease = Knit.CreateSignal(),
	},
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
		self.PassiveService:AddPassivePoint(player, "Aura", 1)
	elseif type(attackingPlayerDatas.AuraPassive) == "boolean" and not attackingPlayerDatas.FusionPassive then
		self.PassiveService:StartAuraPassive(player)
	end
	self.PassiveService:AddPassivePoint(hittedplayer, "Style", 2)
	self:GiveAttackBonuses(player)
	self:GiveHitBonusses(player, hittedplayer)
end

function AttackService:StylePassiveRelease(player)
	self.PassiveService:StartStyleReleasePassive(player)
end

function AttackService:GiveAttackBonuses(player) -- For HItting playerBonusses mostly +
	local playerDatas = self.PlayerService.PlayerDatas[player.UserId]
	if not playerDatas then
		warn("pLayerin data eksik baba")
		return
	end
	self.PlayerService:UpdatePlayerData(
		player,
		{ Stamina = math.clamp(playerDatas.Stamina + 20, 0, playerDatas.MaximumStamina) }
	)
end

function AttackService:GiveHitBonusses(hittingplayer, hittedplayer) -- For Beating Player bonusses mostly -
	local playerDatas = self.PlayerService.PlayerDatas[hittingplayer.UserId]
	if not playerDatas then
		warn("pLayerin data eksik baba")
		return
	end
	local KickDamage = if KickStyleDatas.Kicks[playerDatas.KickStyle]
		then KickStyleDatas.Kicks[playerDatas.KickStyle].Stats.Damage
		else nil

	if KickDamage then
		local LeftingOverHealth = math.clamp(playerDatas.OverHealth - KickDamage, 0, 100)
		if LeftingOverHealth == 0 then
			self.PlayerService:UpdatePlayerData(hittedplayer, {
				Health = math.clamp(
					playerDatas.Health - (KickDamage - playerDatas.OverHealth),
					0,
					playerDatas.MaximumHealth
				),
				Stamina = math.clamp(playerDatas.Stamina - 20, 0, playerDatas.MaximumStamina),
			})
		elseif LeftingOverHealth ~= 0 then
			self.PlayerService:UpdatePlayerData(hittedplayer, {
				OverHealth = math.clamp(LeftingOverHealth, 0, 100),
				Stamina = math.clamp(playerDatas.Stamina - 20, 0, playerDatas.MaximumStamina),
			})
		end
	end
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
	self.Client.PassiveRelease:Connect(function(player)
		self:StylePassiveRelease(player)
	end)
end

return AttackService
