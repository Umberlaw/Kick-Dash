local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)

local PassiveService =
	Knit.CreateService({ Name = "PassiveService", Client = { PassiveActivate = Knit.CreateSignal() } })

function PassiveService:AddPassivePoint(player, PassiveType, IncreaseAmount)
	print(player, PassiveType, IncreaseAmount)
	print(self.PlayerService, self.PlayerService.PlayerDatas[player.UserId]["FusionPassive"])
	if
		self.PlayerService.PlayerDatas[player.UserId]
		and self.PlayerService.PlayerDatas[player.UserId]["FusionPassive"]
	then
		warn("Player Coktan Full set olmus")
		return
	end
	local PlayerKickPassive = self.PlayerService.PlayerDatas[player.UserId].KickPassive or nil
	local PlayerAuraPassive = self.PlayerService.PlayerDatas[player.UserId].AuraPassive or nil
	local PlayerKickPassiveProgress, PlayerAuraPassiveProgress = PlayerKickPassive, PlayerAuraPassive
	local fusionPassive = false
	if PassiveType == "Kick" then
		if type(PlayerKickPassive) == "boolean" then
			print("Kick Passive Active Zaten")
		elseif PlayerKickPassive then
			local newPlayerPassiveProgress = math.clamp(PlayerKickPassive + IncreaseAmount, 0, 3)
			if newPlayerPassiveProgress >= 3 then
				PlayerKickPassiveProgress = true
				self.EffectService:CreateSymbols(player, "Kick")
			elseif newPlayerPassiveProgress < 3 then
				PlayerKickPassiveProgress = newPlayerPassiveProgress
			end
			self.Client.PassiveActivate:Fire(player, PassiveType, newPlayerPassiveProgress)
		end
	end
	if PassiveType == "Aura" then
		print("AURA PASIF TETIKLENECEK LO")
		if type(PlayerAuraPassive) == "boolean" then
			print("Aura Pasif Aktif Zaten")
		elseif PlayerAuraPassive then
			local newPlayerPassiveProgress = math.clamp(PlayerAuraPassive + IncreaseAmount, 0, 3)
			if newPlayerPassiveProgress >= 3 then
				PlayerAuraPassiveProgress = true
				self.EffectService:CreateSymbols(player, "Aura")
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
		print(fusionPassive)
		self.PlayerService:UpdatePlayerData(player, {
			KickPassive = PlayerKickPassiveProgress,
			AuraPassive = PlayerAuraPassiveProgress,
			FusionPassive = fusionPassive,
		})
	else
		self.PlayerService:UpdatePlayerData(player, {
			KickPassive = PlayerKickPassiveProgress,
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
