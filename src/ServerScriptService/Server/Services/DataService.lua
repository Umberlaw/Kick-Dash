local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)
local ProfileService = require(ServerScriptService.Server.Modules.ProfileService)
local profileTemplate = require(ReplicatedStorage.Shared.configs.ProfileTemplate)

local DataService = Knit.CreateService({
	Name = "DataService",
	Client = { UpdateData = Knit.CreateSignal() },
	PlayerDatas = {},
	ProfileStore = {},
})

function DataService:LoadPlayersData(player)
	local profile = self.ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		self.PlayerDatas[player.UserId] = profile
		profile:AddUserId(player.UserId)
		profile:Reconcile()
	else
		player:Kick("U dont have any profile")
	end
end

function DataService:GetPlayersData(player)
	return Promise.new(function(resolve, reject)
		if self.PlayerDatas[player.UserId] then
			resolve(self.PlayerDatas[player.UserId].Data)
		else
			reject("Player dont have  any data")
		end
	end)
end

function DataService:KnitInit() end

function DataService:KnitStart()
	self.ProfileStore = ProfileService.GetProfileStore("PlayersData1", profileTemplate)
end

return DataService
