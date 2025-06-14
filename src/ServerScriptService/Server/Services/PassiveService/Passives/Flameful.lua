local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Flameful = {}
local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

Flameful.Services = {}
Flameful.FlamefulStartPos = {}
Flameful.FlameRoads = {}

function Flameful:StartRelease(player)
	print(player)
	if not self.FlamefulStartPos[player.UserId] then
		print("Bakacaz")
		self.FlamefulStartPos[player.UserId] = player.Character:GetPivot()
	end
end

function Flameful:Start(player, otherdatas)
	self.Services["PlayerService"] = self.Services["PlayerService"] or Knit.GetService("PlayerService")
	self.Services["StatusService"] = self.Services["StatusService"] or Knit.GetService("StatusService")
	self.Services["EffectService"] = self.Services["EffectService"] or Knit.GetService("EffectService")
	print("Burasi calisti")
	self.Services["StatusService"]:AddStatus(otherdatas.HittedPlayer, "Burned", { RemainingTime = 10 })
	if self.FlamefulStartPos[player.UserId] then
		task.delay(1, function()
			self:CreateFlameRoad(
				player,
				self.FlamefulStartPos[player.UserId],
				if otherdatas.HittedPlayer.Character
					then otherdatas.HittedPlayer.Character:GetPivot()
					else otherdatas.HittedPlayer:GetPivot()
			)
			self.FlamefulStartPos[player.UserId] = nil
		end)
	end
end

function Flameful:CreateFlameRoad(player, StartPos, FinishPos)
	local direction = (FinishPos.Position - StartPos.Position).unit
	local Magnitude = (FinishPos.Position - StartPos.Position).Magnitude
	if not self.FlameRoads[player.UserId] then
		self.FlameRoads[player.UserId] = {}
	end
	local FlameRoadModel = ReplicatedStorage.Shared.Assets.Models:FindFirstChild("FlamefulRoad"):Clone()
	FlameRoadModel.Size = Vector3.new(4, 1, Magnitude)
	FlameRoadModel.CFrame = CFrame.lookAt(StartPos.Position + direction * (Magnitude / 2), FinishPos.Position)
	FlameRoadModel.Parent = workspace
	table.insert(self.FlameRoads[player.UserId], FlameRoadModel)
	print(self.FlameRoads[player.UserId])
	for _, allParticles in FlameRoadModel:GetChildren() do
		if allParticles:IsA("ParticleEmitter") then
			allParticles.Rate = allParticles:GetAttribute("Rate")
		end
	end
	task.delay(15, function()
		table.remove(self.FlameRoads[player.UserId], table.find(self.FlameRoads[player.UserId], FlameRoadModel))
		FlameRoadModel:Destroy()
		print(self.FlameRoads[player.UserId])
	end)
end

return Flameful
