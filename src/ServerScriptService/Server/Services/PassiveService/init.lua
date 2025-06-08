local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)
local Passives = require(script.Passives)

local PassiveService =
	Knit.CreateService({ Name = "PassiveService", Client = { PassiveActivate = Knit.CreateSignal() } })

function PassiveService:StartAuraPassive(player, otherdatas)
	local playersData = self.PlayerService.PlayerDatas[player.UserId]
	if not playersData then
		warn("PlayerData yok")
	end
	local targetAuraPassive = Passives[playersData.Aura] or nil
	if not targetAuraPassive then
		warn("Boyle bi aura yokmus kral")
	else
		targetAuraPassive:Start(player, otherdatas)
		self.PlayerService:UpdatePlayerData(player, { AuraPassive = 0 })
		self.Client.PassiveActivate:Fire(player, "Aura", 0)
		self.EffectService:RemoveIndicator(player, "Aura")
	end
end

function PassiveService:StartStylePassive(player, hittingPerson, otherdatas, ragdollDatas)
	local playersData = self.PlayerService.PlayerDatas[player.UserId]
	if not playersData then
		warn("PlayerData yok")
	end
	local TargetStylePassive = Passives[playersData.KickStyle] or nil
	if not TargetStylePassive then
		warn("Boyle bi Style yokmus kral")
	else
		TargetStylePassive:Start(player, hittingPerson, otherdatas, ragdollDatas)
		self.PlayerService:UpdatePlayerData(player, { StylePassive = 0 })
		self.Client.PassiveActivate:Fire(player, "Style", 0)
		self.EffectService:RemoveIndicator(player, "Style")
	end
end

function PassiveService:StartStyleReleasePassive(player)
	local playersData = self.PlayerService.PlayerDatas[player.UserId]
	if not playersData then
		warn("PlayerData yok")
	end
	local TargetStylePassive = Passives[playersData.KickStyle] or nil
	if not TargetStylePassive then
		warn("Boyle bi Style yokmus kral")
	else
		TargetStylePassive:StartRelease(player)
	end
end

function PassiveService:AddPassivePoint(player, PassiveType, IncreaseAmount)
	if
		self.PlayerService.PlayerDatas[player.UserId]
		and self.PlayerService.PlayerDatas[player.UserId]["FusionPassive"]
	then
		warn("Player Coktan Full set olmus")
		return
	end
	local PlayerStylePassive = self.PlayerService.PlayerDatas[player.UserId].StylePassive or nil
	local PlayerAuraPassive = self.PlayerService.PlayerDatas[player.UserId].AuraPassive or nil
	local PlayerKickPassiveProgress, PlayerAuraPassiveProgress = PlayerStylePassive, PlayerAuraPassive
	local fusionPassive = false

	if PassiveType == "Style" then
		if type(PlayerStylePassive) == "boolean" then
			print("Kick Passive Active Zaten")
		elseif PlayerStylePassive then
			local newPlayerPassiveProgress = math.clamp(PlayerStylePassive + IncreaseAmount, 0, 3)
			if newPlayerPassiveProgress >= 3 then
				PlayerKickPassiveProgress = true
				self.EffectService:CreateSymbols(player, "Style")
				self.EffectService:SetIndicator(player, "Style")
			elseif newPlayerPassiveProgress < 3 then
				PlayerKickPassiveProgress = newPlayerPassiveProgress
			end
			self.Client.PassiveActivate:Fire(player, PassiveType, newPlayerPassiveProgress)
		end
	end
	if PassiveType == "Aura" then
		if type(PlayerAuraPassive) == "boolean" then
			print("Aura Pasif Aktif Zaten")
		elseif PlayerAuraPassive then
			local newPlayerPassiveProgress = math.clamp(PlayerAuraPassive + IncreaseAmount, 0, 3)
			if newPlayerPassiveProgress >= 3 then
				PlayerAuraPassiveProgress = true
				self.EffectService:CreateSymbols(player, "Aura")
				self.EffectService:SetIndicator(player, "Aura")
			elseif newPlayerPassiveProgress < 3 then
				PlayerAuraPassiveProgress = newPlayerPassiveProgress
			end
			self.Client.PassiveActivate:Fire(player, PassiveType, newPlayerPassiveProgress)
		end
	end

	if type(PlayerKickPassiveProgress) == "boolean" and type(PlayerAuraPassiveProgress) == "boolean" then
		print("Fusion Tetiklenebilir artik")
		fusionPassive = true
	end

	if fusionPassive then
		self.PlayerService:UpdatePlayerData(player, {
			StylePassive = PlayerKickPassiveProgress,
			AuraPassive = PlayerAuraPassiveProgress,
			FusionPassive = fusionPassive,
		})
	else
		self.PlayerService:UpdatePlayerData(player, {
			StylePassive = PlayerKickPassiveProgress,
			AuraPassive = PlayerAuraPassiveProgress,
		})
	end
end

function PassiveService:KnitInit()
	self.EffectService = Knit.GetService("EffectService")
end

function PassiveService:KnitStart()
	self.EffectService = Knit.GetService("EffectService")
	self.PlayerService = Knit.GetService("PlayerService")
	self.AttackService = Knit.GetService("AttackService")
end

return PassiveService
