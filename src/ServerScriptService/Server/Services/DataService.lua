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

	player.AncestryChanged:Connect(function()
		if player.Parent == nil then
			profile:Release()
		end
	end)
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

function DataService:UpdatePlayerProfile(player, ComingDatas)
	if self.PlayerDatas[player.UserId] then
		local profile = self.PlayerDatas[player.UserId]
		profile.Data.EquippedAura = ComingDatas.Aura
		profile.Data.EquippedKickStyle = ComingDatas.KickStyle
		profile.Data.Inventory = ComingDatas.Inventory or profile.Data.Inventory
		profile.Data.Stats = ComingDatas.Stats or profile.Data.Stats
		profile.Data.Currencies.Coin = ComingDatas.Coins or profile.Data.Currencies.Coin
		profile.Data.Currencies.Emerald = ComingDatas.Emerald or profile.Data.Currencies.Emerald
		profile.Data.EquippedWish = ComingDatas.EquippedWish or profile.Data.EquippedWish
	end
end

function DataService:SavePlayersData(player, ComingDatas)
	if self.PlayerDatas[player.UserId] then
		local profile = self.PlayerDatas[player.UserId]
		profile.Data.EquippedAura = ComingDatas.Aura
		profile.Data.EquippedKickStyle = ComingDatas.KickStyle
		profile.Data.Inventory = ComingDatas.Inventory or profile.Data.Inventory
		profile.Data.Stats = ComingDatas.Stats or profile.Data.Stats
		profile.Data.Currencies.Coin = ComingDatas.Coins or profile.Data.Currencies.Coin
		profile.Data.Currencies.Emerald = ComingDatas.Emerald or profile.Data.Currencies.Emerald
		profile.Data.EquippedWish = ComingDatas.EquippedWish or profile.Data.EquippedWish
		profile:Release()
	end
end

function DataService:KnitInit() end

function DataService:KnitStart()
	self.ProfileStore = ProfileService.GetProfileStore("PlayersData1", profileTemplate)
end

return DataService
