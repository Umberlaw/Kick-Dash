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
		NPCAttack = Knit.CreateSignal(),
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
		self.PassiveService:StartAuraPassive(player, { HittedPlayer = hittedplayer, otherDatas = otherdatas })
	end
	self.PassiveService:AddPassivePoint(hittedplayer, "Style", 1)
	self:GiveAttackBonuses(player)
	self:GiveHitBonusses(player, hittedplayer)
end

function AttackService:NPCAttack(player, HittedNPC, otherDatas)
	local attackingPlayerDatas = self.PlayerService.PlayerDatas[player.UserId] or nil
	if not attackingPlayerDatas then
		warn("Playerin Datasi yok la")
	end
	if type(attackingPlayerDatas.StylePassive) == "boolean" then
		self.PassiveService:StartStylePassive(player)
	end
	if type(attackingPlayerDatas.AuraPassive) ~= "boolean" then
		self.PassiveService:AddPassivePoint(player, "Aura", 2)
	elseif type(attackingPlayerDatas.AuraPassive) == "boolean" and not attackingPlayerDatas.FusionPassive then
		self.PassiveService:StartAuraPassive(player, { HittedPlayer = HittedNPC, otherDatas = otherDatas })
	end
	self:GiveAttackBonuses(player)
end

function AttackService:StylePassiveRelease(player)
	self.PassiveService:StartStyleReleasePassive(player)
end

function AttackService:GiveAttackBonuses(player) -- For HItting playerBonusses mostly +stamina
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

function AttackService:GiveHitBonusses(hittingplayer, hittedplayer) -- For Beating Player bonusses mostly -stamina and hp
	local playerDatas = self.PlayerService.PlayerDatas[hittingplayer.UserId]
	if not playerDatas then
		warn("pLayerin data eksik baba")
		return
	end
	local KickDamage = if KickStyleDatas.Kicks[playerDatas.KickStyle]
		then KickStyleDatas.Kicks[playerDatas.KickStyle].Stats.Damage
		else nil

	if KickDamage then
		if playerDatas.OverHealth ~= 0 then
			local LeftingOverHealth = math.clamp(playerDatas.OverHealth - KickDamage, 0, 100)
			if LeftingOverHealth == 0 then
				self.PlayerService:UpdatePlayerData(hittedplayer, {
					OverHealth = 0,
					Stamina = math.clamp(playerDatas.Stamina - 20, 0, playerDatas.MaximumStamina),
				})
			end
		elseif playerDatas.OverHealth <= 0 then
			self.PlayerService:UpdatePlayerData(hittedplayer, {
				Health = math.clamp(playerDatas.Health - KickDamage * 20, 0, playerDatas.MaximumHealth),
				Stamina = math.clamp(playerDatas.Stamina - 20, 0, playerDatas.MaximumStamina),
			})
			local remainingHP = math.clamp(playerDatas.Health - KickDamage, 0, playerDatas.MaximumHealth)
			if remainingHP <= 0 then
				self:Knockout(hittingplayer, hittedplayer)
			end
		end
	end
end

function AttackService:Knockout(hittingplayer, KnockedPlayer)
	local hittingPlayerData = self.PlayerService.PlayerDatas[hittingplayer.UserId]
	local KnockedPlayerData = self.PlayerService.PlayerDatas[KnockedPlayer.UserId]
	if not hittingPlayerData or not KnockedPlayerData then
		warn("A data didnt find")
		return
	end
	--TO DO  LAST WISH SIDE AND  KNOCKED PHASE AREA WILL ADD THERE

	self.PlayerService:Knocked(KnockedPlayer)
	self.PlayerService:UpdatePlayerData(hittingplayer, { Coin = hittingPlayerData.Coin + 200 })
	self.NotificationService:CreateLeftInfo(KnockedPlayer, { IndicatorType = "Wipeout" })
	self.NotificationService:CreateLeftInfo(hittingplayer, { IndicatorType = "Knockout" })
end

function AttackService:AuraChanings(player, AuraStatus)
	print(player, AuraStatus)
end

function AttackService:KnitInit()
	self.StatusService = Knit.GetService("StatusService")
	self.PassiveService = Knit.GetService("PassiveService")
	self.PlayerService = Knit.GetService("PlayerService")
	self.NotificationService = Knit.GetService("NotificationService")
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
	self.Client.NPCAttack:Connect(function(player, HittedNPC, otherdatas)
		self:NPCAttack(player, HittedNPC, otherdatas)
	end)
end

return AttackService
