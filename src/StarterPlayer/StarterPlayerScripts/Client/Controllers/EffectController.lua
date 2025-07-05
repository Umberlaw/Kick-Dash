local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.knit)
local LightingData = require(ReplicatedStorage.Shared.configs.Lightings)
local Shake = require(ReplicatedStorage.Packages.shake)
local ShakeConfig = require(ReplicatedStorage.Shared.configs.ShakeDatas)
--local Promise = require(Knit.Util.Promise)

local EffectController =
	Knit.CreateController({ Name = "EffectController", CurrentAtmospher = "Arena", Shake = nil, ShakeCon = nil })

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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

function EffectController:CreateShake(ShakePreset)
	local shake = Shake.new()
	shake.Amplitude = ShakeConfig[ShakePreset].Amplitude or 1
	shake.FadeInTime = ShakeConfig[ShakePreset].FadeInTime or 0
	shake.FadeOutTime = ShakeConfig[ShakePreset].FadeOutTime or 0.5
	shake.Frequency = ShakeConfig[ShakePreset].Frequency or 0.25
	shake.Sustain = ShakeConfig[ShakePreset].Sustained or false
	shake.SustainTime = ShakeConfig[ShakePreset].SustainTime or 0.35
	shake.RotationInfluence = ShakeConfig[ShakePreset].RotationInfluence or Vector3.new(0, 0.5, 0)
	shake.PositionInfluence = ShakeConfig[ShakePreset].PositionInfluence or Vector3.one
	shake:Start()
	shake:BindToRenderStep(shake.NextRenderName(), Enum.RenderPriority.Last.Value, function(pos, rot, isDone)
		workspace.CurrentCamera.CFrame *= CFrame.new(pos) * CFrame.Angles(
			math.rad(rot.X),
			math.rad(rot.Y),
			math.rad(rot.Z)
		)
	end)
end

function EffectController:DamageVignette(status, targetValue)
	local DmgVignetteFrame = PlayerGui:WaitForChild("CoreHUD"):WaitForChild("DmgVignette")
	local DmgAppearTween = TweenService:Create(
		DmgVignetteFrame,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
		{ GroupTransparency = targetValue or 0.45 }
	)
	local DmginTween = TweenService:Create(
		DmgVignetteFrame,
		TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In, -1, true, 0),
		{ GroupTransparency = targetValue or 0.65 }
	)
	local DmgDisAppearTween = TweenService:Create(
		DmgVignetteFrame,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
		{ GroupTransparency = 1 }
	)
	DmgAppearTween:Play()
	DmgAppearTween.Completed:Once(function(playbackState)
		DmginTween:Play()
		task.delay(2.5, function()
			DmginTween:Cancel()
			DmginTween:Destroy()
			DmgDisAppearTween:Play()
		end)
	end)
end

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
	self.EffectService.CreateShake:Connect(function(ShakePreset)
		self:CreateShake(ShakePreset)
	end)
	self.EffectService.CreateVignette:Connect(function(status, targetvalue)
		self:DamageVignette(status, targetvalue)
	end)
end

return EffectController
