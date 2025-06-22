local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)
local SoundService = Knit.CreateService({
	Name = "SoundService",
	Client = { PlayClient = Knit.CreateSignal(), PlayServer = Knit.CreateSignal(), LoadSounds = Knit.CreateSignal() },
	PlayersSounds = {},
})
--[[soundData :
	{
	SoundObject = Instance
	SoundName = SoundName
	Volume = 1 -- "Optional",
	Looped = false,--"Optional"
	Parent = Char.Head --"Optional Default  is a folder
	PlayTime = optional  Default is a 1
	PlayingArea = Server or Client
	}

]]
function SoundService:CreateSound(player, soundData: table)
	if not self.PlayersSounds[player.UserId] then
		self.PlayersSounds[player.UserId] = {}
	end
	local SoundObject = soundData.SoundObject:Clone()
	SoundObject.Volume = soundData.Volume or SoundObject.Volume
	SoundObject.Looped = soundData.Looped or SoundObject.Looped
	SoundObject.Parent = soundData.Parent or player.Character.Head:FindFirstChild("Sounds")
	SoundObject.Name = soundData.SoundName or SoundObject.Name
	if self.PlayersSounds[player.UserId][soundData.SoundName] then
		self.PlayersSounds[player.UserId][soundData.SoundName]:Destroy()
		self.PlayersSounds[player.UserId][soundData.SoundName] = nil
	end
	self.PlayersSounds[player.UserId][soundData.SoundName] = SoundObject
	self.Client.LoadSounds:Fire(player, self.PlayersSounds[player.UserId])
end

function SoundService:Clear(player)
	if self.PlayersSounds[player.UserId] then
		self.PlayersSounds[player.UserId] = nil
	end
end

function SoundService:PlaySound(player, soundData: table)
	if not self.PlayersSounds[player.UserId] then
		self.PlayersSounds[player.UserId] = {}
	end
	local targetPlayersSounds = self.PlayersSounds[player.UserId][soundData.SoundName] or nil
	if not targetPlayersSounds then
		self:CreateSound(player, soundData)
	end
	if soundData.PlayingArea == "Server" then
		self.PlayersSounds[player.UserId][soundData.SoundName]:Play()
		for _, extraSounds: Sound in self.PlayersSounds[player.UserId][soundData.SoundName]:GetChildren() do
			if extraSounds:IsA("Sound") then
				extraSounds:Play()
				task.delay(extraSounds.TimeLength, function()
					local StopTween = TweenService:Create(
						extraSounds,
						TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
						{ Volume = 0 }
					)
					StopTween:Play()
					StopTween.Completed:Wait()
					extraSounds:Stop()
				end)
			end
		end
		task.delay(soundData.PlayTime or 1, function()
			local StopTween = TweenService:Create(
				self.PlayersSounds[player.UserId][soundData.SoundName],
				TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
				{ Volume = 0 }
			)
			StopTween:Play()
			StopTween.Completed:Wait()
			self.PlayersSounds[player.UserId][soundData.SoundName]:Stop()
		end)
	elseif soundData.PlayingArea == "Client" then
		self.Client.PlayClient:Fire(player, self.PlayersSounds[player.UserId][soundData.SoundName], soundData)
	end
end

function SoundService:KnitInit() end

function SoundService:KnitStart()
	self.Client.PlayServer:Connect(function(player, SoundData)
		self:PlaySound(player, SoundData)
	end)
end

return SoundService
