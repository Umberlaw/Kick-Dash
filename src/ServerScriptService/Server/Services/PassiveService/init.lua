local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)

local PassiveService = Knit.CreateService({ Name = "PassiveService", Client = {} })

function PassiveService:KnitInit() end

function PassiveService:AddPassivePoint(player, PassiveType, IncreaseAmount)
	if self.PlayerService.PlayersData[player.UserId] and self.PlayerService.PlayersData[player.UserId] then
		warn("Player Coktan Full set olmus")
		return
	end
	local PlayerKickPassive = self.PlayerService.PlayersData[player.UserId].KickPassive or nil
	local PlayerAuraPassive = self.PlayerService.PlayersData[player.UserId].AuraPassive or nil
	local PlayerKickPassiveProgress, PlayerAuraPassiveProgress = PlayerKickPassive, PlayerAuraPassive
	local fusionPassive = false
	if PassiveType == "Kick" then
		if PlayerKickPassive == "true" then
			warn("Pasif Coktan etkinlestirilmis")
		elseif PlayerKickPassive then
			local newPlayerPassiveProgress = math.clamp(PlayerKickPassive + IncreaseAmount, 0, 3)
			if newPlayerPassiveProgress >= 3 then
				PlayerKickPassiveProgress = true
			elseif newPlayerPassiveProgress < 3 then
				PlayerKickPassiveProgress = newPlayerPassiveProgress
			end
		end
	end
	if PassiveType == "Aura" then
		if PlayerAuraPassive == "true" then
			warn("Pasif Coktan etkinlestirilmis")
		elseif PlayerAuraPassive then
			local newPlayerPassiveProgress = math.clamp(PlayerAuraPassive + IncreaseAmount, 0, 3)
			if newPlayerPassiveProgress >= 3 then
				PlayerKickPassiveProgress = true
			elseif newPlayerPassiveProgress < 3 then
				PlayerAuraPassiveProgress = newPlayerPassiveProgress
			end
		end
	end

	if PlayerKickPassiveProgress == "true" and PlayerAuraPassiveProgress == "true" then
		fusionPassive = true
	end

	if fusionPassive then
		self.PlayerService:UpdatePlayerData(player, {
			KickPassive = PlayerKickPassiveProgress,
			AuraPassive = PlayerAuraPassiveProgress,
			FusionPassive = fusionPassive,
		})
	end
end

function PassiveService:KnitStart()
	self.EffectService = Knit.GetService("EffectService")
	self.PlayerService = Knit.GetService("PlayerService")
	self.AttackService = Knit.GetService("AttackService")
end

return PassiveService
