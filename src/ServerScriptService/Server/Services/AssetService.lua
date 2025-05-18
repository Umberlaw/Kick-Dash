local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local AssetService = Knit.CreateService({
	Name = "AssetService",
	Client = {},
})

function AssetService:KnitInit() end

function AssetService:KnitStart() end

return AssetService
