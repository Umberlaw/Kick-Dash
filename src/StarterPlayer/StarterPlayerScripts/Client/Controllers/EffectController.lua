local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Knit = require(ReplicatedStorage.Packages.knit)
local LightingData = require(ReplicatedStorage.Shared.configs.Lightings)
--local Promise = require(Knit.Util.Promise)

local EffectController = Knit.CreateController({ Name = "EffectController", CurrentAtmospher = "Arena" })

local LocalPlayer = Players.LocalPlayer

local AtmosphereProperties = {
	"Density",
	"Offset",
	"Color",
	"Decay",
	"Glare",
	"Haze",
}

function EffectController:SetAtmosphere(comingatmosphere: Atmosphere, AtmosphereType)
	if comingatmosphere.Name == self.CurrentAtmospher then
		warn("Zaten Ayni atmosferi istemissin")
		return
	end

	local targetLightingData = LightingData[AtmosphereType] or nil
	if targetLightingData then
		for propertyName, propertyValue in targetLightingData do
			if Lighting[propertyName] then
				Lighting[propertyName] = propertyValue
			end
		end
	end

	local PlayersAtmospher = game.Lighting:FindFirstChild("Atmosphere")
		or game.Lighting:FindFirstChild("WorkAtmosphere")
		or nil
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

function EffectController:CreateEffect(targetEffect: table, targetEffectDatas: table)
	self.EffectService.CreateEffect:Fire(targetEffect, targetEffectDatas)
end

function EffectController:KnitInit()
	self.EffectService = Knit.GetService("EffectService")
end

function EffectController:KnitStart()
	self.EffectService.SetAtmosphere:Connect(function(comingatmosphere, AtmosphereName)
		self:SetAtmosphere(comingatmosphere, AtmosphereName)
	end)
end

return EffectController
