local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local SoundController = Knit.CreateController({
	Name = "SoundController",
})

function SoundController:CloseTheSound() end

function SoundController:PlaySoundInServer() end

function SoundController:PlaySoundOnlyClient() end

function SoundController:KnitInit() end

function SoundController:KnitStart() end

return SoundController
