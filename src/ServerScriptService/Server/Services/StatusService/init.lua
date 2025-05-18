local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)

--local Promise = require(Knit.Util.Promise)
local StatusData = require(script.Status)

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

function StatusService:AddStatus(player, StatuName, StatusDetails)
	if not StatusData[StatuName] then
		warn("Not find any status like that")
		return
	end
	self.PlayerService:UpdateDebuffData(player, StatuName, StatusDetails)
end

function StatusService:ActivateDebuff(player, debufName)
	if not StatusData[debufName] then
		warn("Not find any status like that")
		return
	end
	StatusData[debufName]:Active(player, debufName)
end

function StatusService:KnitInit()
	self.PlayerService = Knit.GetService("PlayerService")
	self.AttackService = Knit.GetService("AttackService")
end

function StatusService:KnitStart() end

return StatusService
