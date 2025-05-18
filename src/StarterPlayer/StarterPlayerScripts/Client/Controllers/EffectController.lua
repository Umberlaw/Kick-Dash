local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
--local Promise = require(Knit.Util.Promise)

local EffectController = Knit.CreateController({ Name = "EffectController" })

function EffectController:EnableEffect() end

function EffectController:DiseableEffect() end

function EffectController:PlayOnServer() end

function EffectController:KnitInit() end

function EffectController:KnitStart() end

return EffectController
