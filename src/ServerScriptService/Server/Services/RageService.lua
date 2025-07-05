local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local RageService = Knit.CreateService({
	Name = "RageService",
	Client = {},
	Taskes = {},
})

--[[local UpdatingDataTable = {
				KickStyle = comingData.EquippedKickStyle,
				Aura = comingData.EquippedAura,
				MaxPower = 100,
				Health = StatsPoints.MaximumHealth,
				MaximumHealth = StatsPoints.MaximumHealth,
				Rage = 0,
				Ragdoll = 0,
				MaximumRage = StatsPoints.MaximumRage,
				Stamina = StatsPoints.MaximumStamina,
				MaximumStamina = StatsPoints.MaximumStamina,
				Coin = comingData.Currencies.Coin,
				Emerald = comingData.Currencies.Emerald,
				WalkSpeed = 25,
				OverHealth = 0,
				StylePassive = 0,
				AuraPassive = 0,
				Debuffes = {},
				FusionPassive = false,
				Knocked = false,
				RageActive = false,
				InSafeZone = true,
				StaminaRecharge = false,
			}]]

function RageService:RageAdd(player, ...)
	local targetPlayersData = self.PlayerService.PlayerDatas[player.UserId] or nil
	if not targetPlayersData then
		warn("Not have player any data")
		return
	end
	local addingrage = targetPlayersData.Rage + 10
	self.PlayerService:UpdatePlayerData(player, { Rage = addingrage })
end

function RageService:KnitInit()
	self.PlayerService = Knit.GetService("PlayerService")
	self.AttackService = Knit.GetService("AttackService")
	self.EffectService = Knit.GetService("EffectService")
end

function RageService:KnitStart() end

return RageService
