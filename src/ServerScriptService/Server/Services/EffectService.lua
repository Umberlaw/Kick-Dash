local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local EffectService = Knit.CreateService({
	Name = "EffectService",
	Client = {},
})

function EffectService:KnitInit() end

function EffectService:KnitStart() end

return EffectService
