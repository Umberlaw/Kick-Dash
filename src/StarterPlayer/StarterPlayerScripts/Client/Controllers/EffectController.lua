local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
--local Promise = require(Knit.Util.Promise)

local EffectController = Knit.CreateController({ Name = "EffectController", CurrentAtmospher = "Lobby" })

local LocalPlayer = Players.LocalPlayer

local AtmosphereProperties = {
	"Density",
	"Offset",
	"Color",
	"Decay",
	"Glare",
	"Haze",
}

function EffectController:SetAtmosphere(comingatmosphere: Atmosphere)
	if comingatmosphere.Name == self.CurrentAtmospher then
		warn("Zaten Ayni atmosferi istemissin")
		return
	end
	local PlayersAtmospher = game.Lighting:FindFirstChild("Atmosphere")
	if PlayersAtmospher then
		for _, PropertyName in AtmosphereProperties do
			if PlayersAtmospher[PropertyName] then
				PlayersAtmospher[PropertyName] = comingatmosphere[PropertyName]
			end
		end
		self.CurrentAtmospher = comingatmosphere.Name
	end
end

function EffectController:EnableEffect() end

function EffectController:DiseableEffect() end

function EffectController:PlayOnServer() end

function EffectController:KnitInit()
	self.EffectService = Knit.GetService("EffectService")
end

function EffectController:KnitStart()
	self.EffectService.SetAtmosphere:Connect(function(comingatmosphere)
		self:SetAtmosphere(comingatmosphere)
	end)
end

return EffectController
