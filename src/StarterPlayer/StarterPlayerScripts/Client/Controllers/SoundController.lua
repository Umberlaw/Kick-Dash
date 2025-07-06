local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local LocalPlr = Players.LocalPlayer

local SoundController = Knit.CreateController({
	Name = "SoundController",
	PlayersSounds = {},
})

function SoundController:CloseTheSound(soundName)
	if self.PlayersSounds[soundName] and self.PlayersSounds[soundName].IsPlaying then
		local oldVolume = self.PlayersSounds[soundName].Volume
		local targetSoundTween = TweenService:Create(
			self.PlayersSounds[soundName],
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
			{ Volume = 0 }
		)
		targetSoundTween:Play()
		targetSoundTween.Completed:Once(function()
			self.PlayersSounds[soundName].Volume = oldVolume
			self.PlayersSounds[soundName]:Stop()
			targetSoundTween:Destroy()
		end)
	end
end

function SoundController:PlaySoundInServer(SoundDetails)
	self.SoundService.PlayServer:Fire(SoundDetails)
end

function SoundController:PlaySoundOnlyClient(SoundDetails)
	local targetSound = self.PlayersSounds[SoundDetails.SoundName]
	if targetSound then
		targetSound:Play()
		for _, extraSounds in targetSound:GetChildren() do
			if extraSounds:IsA("Sound") then
				extraSounds:Play()
				task.delay(extraSounds.TimeLength, function()
					if not extraSounds.Looped then
						extraSounds:Stop()
					end
				end)
			end
		end
		task.delay(SoundDetails.PlayTime or targetSound.TimeLength, function()
			if not targetSound.Looped then
				self:CloseTheSound(SoundDetails.SoundName)
			end
		end)
	else
		print("Bu ses YOK ", SoundDetails)
	end
end

function SoundController:KnitInit()
	self.SoundService = Knit.GetService("SoundService")
end

function SoundController:KnitStart()
	self.SoundService.PlayClient:Connect(function(SoundObject, soundDetails)
		print(SoundObject, soundDetails)
	end)
	self.SoundService.LoadSounds:Connect(function(Sounds)
		self.PlayersSounds = Sounds
	end)
end

return SoundController
