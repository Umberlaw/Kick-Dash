local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
--local Promise = require(Knit.Util.Promise)

local AssetController = Knit.CreateController({
	Name = "AssetController",
})

function AssetController:KnitInit() end

function AssetController:KnitStart() end

return AssetController
