local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)
local SoundService = Knit.CreateService({
	Name = "SoundService",
	Client = {},
})

function SoundService:KnitInit() end

function SoundService:KnitStart() end

return SoundService
