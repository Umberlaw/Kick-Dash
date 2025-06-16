local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)

--local Promise = require(Knit.Util.Promise)
local StatusData = require(script.Status)
local StatusConfig = require(ReplicatedStorage.Shared.configs.StatusDatas)

local StatusService = Knit.CreateService({
	Name = "StatusService",
	Client = {},
})

function StatusService:RemoveStatus(player, StatuName)
	if not StatusData[StatuName] then
		warn("Not find any status like that")
		return
	end
	StatusData[StatuName]:Remove(player)
end

function StatusService:AddStatus(player, StatuName, StatusDetails, DebuffName, DebuffType)
	if not StatusData[StatuName] then
		warn("Not find any status like that")
		return
	end
	local targetPlayerData = self.PlayerService.PlayerDatas[player.UserId]
	if not targetPlayerData then
		warn("Datasi yok vurulan arkadasin")
	end
	local currentStatusConfigs = StatusConfig[StatuName]
	print(currentStatusConfigs)
	local IsImmune = if table.find(currentStatusConfigs.ImmunePassives, targetPlayerData.Aura) then true else false
	if not IsImmune then
		self.PlayerService:UpdateDebuffData(player, StatuName, StatusDetails)
		self.EffectService:CreateDebuffIndicator(player, DebuffName, DebuffType, StatuName)
	else
		print("Bu adam zaten immune")
	end
end

function StatusService:ActivateDebuff(player, debufName, details)
	if not StatusData[debufName] then
		warn("Not find any status like that")
		return
	end
	StatusData[debufName]:Active(player, details)
end

function StatusService:KnitInit()
	self.PlayerService = Knit.GetService("PlayerService")
	self.AttackService = Knit.GetService("AttackService")
	self.EffectService = Knit.GetService("EffectService")
end

function StatusService:KnitStart() end

return StatusService
