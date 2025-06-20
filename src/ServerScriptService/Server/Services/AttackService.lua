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

function AttackService:Attack(player, hittedplayer, otherdatas, ragdollDatas)
	local attackingPlayerDatas = self.PlayerService.PlayerDatas[player.UserId] or nil
	local HittedPlayerDatas = self.PlayerService.PlayerDatas[hittedplayer.UserId] or nil
	if not attackingPlayerDatas or not HittedPlayerDatas then
		warn("Playerin Datasi yok la")
	end

	if HittedPlayerDatas.Knocked then
		warn("Knockedli birine vurdun")
		return
	end
	print(attackingPlayerDatas, "BU VURANIN", HittedPlayerDatas, "Buda Vurulanin")
	--self.StatusService:AddStatus(player, "Slowed", { RemainingTime = 10 })

	if type(attackingPlayerDatas.StylePassive) == "boolean" then
		self.PassiveService:StartStylePassive(
			player,
			{ hittingplayer = hittedplayer, otherDatas = otherdatas, ragdollData = ragdollDatas }
		)
	end
	if type(attackingPlayerDatas.AuraPassive) ~= "boolean" then
		self.PassiveService:AddPassivePoint(player, "Aura", 1)
	elseif type(attackingPlayerDatas.AuraPassive) == "boolean" and not attackingPlayerDatas.FusionPassive then
		self.PassiveService:StartAuraPassive(player, { HittedPlayer = hittedplayer, otherDatas = otherdatas })
	end
	self.PassiveService:AddPassivePoint(hittedplayer, "Style", 2)
	self:GiveAttackBonuses(player, hittedplayer)
	self:GiveHitBonusses(player, hittedplayer, ragdollDatas)
end

function AttackService:NPCAttack(player, HittedNPC, otherDatas, ragdollDatas)
	local attackingPlayerDatas = self.PlayerService.PlayerDatas[player.UserId] or nil
	if not attackingPlayerDatas then
		warn("Playerin Datasi yok la")
	end
	if type(attackingPlayerDatas.StylePassive) == "boolean" then
		self.PassiveService:StartStylePassive(
			player,
			{ hittingplayer = HittedNPC, otherdatas = otherDatas, ragdollData = ragdollDatas }
		)
	end
	if type(attackingPlayerDatas.AuraPassive) ~= "boolean" then
		self.PassiveService:AddPassivePoint(player, "Aura", 2)
	elseif type(attackingPlayerDatas.AuraPassive) == "boolean" and not attackingPlayerDatas.FusionPassive then
		self.PassiveService:StartAuraPassive(player, { HittedPlayer = HittedNPC, otherDatas = otherDatas })
	end
	--self:GiveAttackBonuses(player, HittedNPC)
end

function AttackService:StylePassiveRelease(player)
	self.PassiveService:StartStyleReleasePassive(player)
end

function AttackService:AuraPassiveRelease(player)
	self.PassiveService:StartAuraReleasePassive(player)
end

function AttackService:GiveAttackBonuses(player, HittedPlayer) -- For HItting playerBonusses mostly +stamina
	local playerDatas = self.PlayerService.PlayerDatas[player.UserId]
	if not playerDatas then
		warn("pLayerin data eksik baba")
		return
	end
	self.PlayerService:UpdatePlayerData(
		player,
		{ Stamina = math.clamp(playerDatas.Stamina + 20, 0, playerDatas.MaximumStamina) }
	)
	local KickDamage = if KickStyleDatas.Kicks[playerDatas.KickStyle]
		then KickStyleDatas.Kicks[playerDatas.KickStyle].Stats.Damage
		else nil
	self.NotificationService:CreateLeftInfo(
		player,
		{ IndicatorType = "KickHit", HittedPlayer = HittedPlayer, ComingStamina = 20, GivingDamage = KickDamage }
	)
end

function AttackService:GiveHitBonusses(hittingplayer, hittedplayer, RagdollDatas) -- For Beating Player bonusses mostly -stamina and hp
	local playerDatas = self.PlayerService.PlayerDatas[hittedplayer.UserId]
	local HittingPlayerDatas = self.PlayerService.PlayerDatas[hittingplayer.UserId]
	if not playerDatas then
		warn("pLayerin data eksik baba")
		return
	end
	local KickDamage = if KickStyleDatas.Kicks[HittingPlayerDatas.KickStyle]
		then KickStyleDatas.Kicks[HittingPlayerDatas.KickStyle].Stats.Damage
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
				Health = math.clamp(playerDatas.Health - KickDamage, 0, playerDatas.MaximumHealth),
				Stamina = math.clamp(playerDatas.Stamina - 20, 0, playerDatas.MaximumStamina),
			})
			local remainingHP = math.clamp(playerDatas.Health - KickDamage, 0, playerDatas.MaximumHealth)
			if remainingHP <= 0 then
				print("Buradan aldin KickHiti", remainingHP, KickDamage, playerDatas.Health)
				self:Knockout(hittingplayer, hittedplayer, math.floor((KickDamage / playerDatas.MaximumHealth) * 100))
			elseif remainingHP > 0 then
				print(
					"BEN BUNA RAGDOLL VERECEGIM",
					remainingHP,
					"bu kalan can",
					playerDatas.Health,
					"bu da guncel caniydi"
				)
				self.RagdollService:RagdollStatus(hittedplayer, true, RagdollDatas)

				self.NotificationService:CreateLeftInfo(hittedplayer, {
					IndicatorType = "HitTaken",
					HittingPlayer = hittingplayer,
					LosingDamage = KickDamage,
					LosingStamina = 20,
					HittingPlayerData = HittingPlayerDatas,
				})
			end
		end
	end
end

function AttackService:GiveDamage(DamagingPlayer, comingDamage)
	local playerDatas = self.PlayerService.PlayerDatas[DamagingPlayer.UserId]
	if not playerDatas then
		return
	end

	if playerDatas.OverHealth ~= 0 then
		local LeftingOverHealth = math.clamp(playerDatas.OverHealth - comingDamage, 0, 100)
		if LeftingOverHealth == 0 then
			self.PlayerService:UpdatePlayerData(DamagingPlayer, {
				OverHealth = 0,
			})
		end
	elseif playerDatas.OverHealth <= 0 then
		local remainingHP = math.clamp(playerDatas.Health - comingDamage, 0, playerDatas.MaximumHealth)
		self.PlayerService:UpdatePlayerData(DamagingPlayer, {
			Health = math.clamp(playerDatas.Health - comingDamage, 0, playerDatas.MaximumHealth),
		})
		if remainingHP <= 0 then
			print("Buradan aldin KickHiti", remainingHP, comingDamage, playerDatas.Health)
			self:Knockout(nil, DamagingPlayer, math.floor((comingDamage / playerDatas.MaximumHealth) * 100))
		elseif remainingHP > 0 then
			print("BEN BUNA RAGDOLL VERECEGIM", remainingHP, "bu kalan can", playerDatas.Health, "bu da guncel caniydi")

			self.NotificationService:CreateLeftInfo(DamagingPlayer, {
				IndicatorType = "HitTaken",
				HittingPlayer = DamagingPlayer,
				LosingDamage = comingDamage,
				LosingStamina = 20,
				HittingPlayerData = playerDatas,
			})
		end
	end
end

function AttackService:Knockout(hittingplayer, KnockedPlayer, KickDamage)
	if hittingplayer then
		local hittingPlayerData = self.PlayerService.PlayerDatas[hittingplayer.UserId]
		local KnockedPlayerData = self.PlayerService.PlayerDatas[KnockedPlayer.UserId]
		if not hittingPlayerData or not KnockedPlayerData then
			warn("A data didnt find")
			return
		end
		--TO DO  LAST WISH SIDE AND  KNOCKED PHASE AREA WILL ADD THERE
		self.RagdollService:RagdollStatus(KnockedPlayer, false, nil)
		self.PlayerService:Knocked(KnockedPlayer)
		self.NotificationService:CreateLeftInfo(hittingplayer, {
			HittingPlayer = hittingplayer,
			KnockedPlayer = KnockedPlayer,
			IndicatorType = "Wipeout",
			LosingHealth = KickDamage,
		})

		self.NotificationService:CreateLeftInfo(KnockedPlayer, {
			HittingPlayer = hittingplayer,
			KnockedPlayer = KnockedPlayer,
			IndicatorType = "Knockout",
			ComingCoin = 200,
		})

		self.PlayerService:UpdatePlayerData(hittingplayer, { Coin = hittingPlayerData.Coin + 200 })
	elseif not hittingplayer then
		local KnockedPlayerData = self.PlayerService.PlayerDatas[KnockedPlayer.UserId]
		self.RagdollService:RagdollStatus(KnockedPlayer, false, nil)
		self.PlayerService:Knocked(KnockedPlayer)
		self.NotificationService:CreateLeftInfo(KnockedPlayer, {
			HittingPlayer = KnockedPlayer,
			KnockedPlayer = KnockedPlayer,
			IndicatorType = "Wipeout",
			LosingHealth = KickDamage,
		})
	end
end

function AttackService:AuraChanings(player, AuraStatus)
	print(player, AuraStatus)
end

function AttackService:KnitInit()
	self.StatusService = Knit.GetService("StatusService")
	self.PassiveService = Knit.GetService("PassiveService")
	self.PlayerService = Knit.GetService("PlayerService")
	self.NotificationService = Knit.GetService("NotificationService")
	self.RagdollService = Knit.GetService("RagdollService")
end

function AttackService:KnitStart()
	self.Client.HiglightChange:Connect(function(player, AuraStatus)
		self:AuraChanings(player, AuraStatus)
	end)
	self.Client.Attack:Connect(function(player, AttackingPlayer, otherdatas, RagdollDatas)
		self:Attack(player, AttackingPlayer, otherdatas, RagdollDatas)
	end)
	self.Client.PassiveRelease:Connect(function(player, ComingPassive)
		if ComingPassive == "Style" then
			self:StylePassiveRelease(player)
		elseif ComingPassive == "Aura" then
			self:AuraPassiveRelease(player)
		end
	end)
	self.Client.NPCAttack:Connect(function(player, HittedNPC, otherdatas)
		self:NPCAttack(player, HittedNPC, otherdatas)
	end)
end

return AttackService
