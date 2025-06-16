local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Flameful = {}
local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

Flameful.Services = {}
Flameful.FlamefulStartPos = {}
Flameful.FlameRoads = {}
Flameful.AlreadyTouchedThings = {}

--[[function Flameful:StartRelease(player)
	print(player)
	if not self.FlamefulStartPos[player.UserId] then
		print("Bakacaz")
		self.FlamefulStartPos[player.UserId] = player.Character:GetPivot()
	end
end]]

function Flameful:Start(player, otherdatas)
	self.Services["PlayerService"] = self.Services["PlayerService"] or Knit.GetService("PlayerService")
	self.Services["StatusService"] = self.Services["StatusService"] or Knit.GetService("StatusService")
	self.Services["EffectService"] = self.Services["EffectService"] or Knit.GetService("EffectService")
	print("Burasi calisti")
	self.Services["StatusService"]:AddStatus(
		otherdatas.HittedPlayer,
		"Burned",
		{ RemainingTime = 10 },
		"Flameful",
		"Decreasing"
	)
	local StartPos = if otherdatas.HittedPlayer.Character
		then otherdatas.HittedPlayer.Character:GetPivot()
		else player.Character:GetPivot()
	task.delay(1.25, function()
		self:CreateFlameRoad(
			player,
			StartPos,
			if otherdatas.HittedPlayer.Character
				then otherdatas.HittedPlayer.Character:GetPivot()
				else otherdatas.HittedPlayer:GetPivot()
		)
		self.FlamefulStartPos[player.UserId] = nil
	end)
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

	FlameRoadModel.Touched:Connect(function(touchingobject)
		if touchingobject.Parent:FindFirstChild("Humanoid") then
			local char = touchingobject.Parent
			if self.AlreadyTouchedThings[char] then
				return
			else
				self.AlreadyTouchedThings[char] = char
			end
			local plr = game.Players:GetPlayerFromCharacter(char)
			self.Services["StatusService"]:AddStatus(plr, "Burned", { RemainingTime = 10 }, "Flameful", "Decreasing")
			task.delay(5, function()
				if self.AlreadyTouchedThings[char] then
					self.AlreadyTouchedThings[char] = nil
				end
			end)
		end
	end)

	task.delay(15, function()
		table.remove(self.FlameRoads[player.UserId], table.find(self.FlameRoads[player.UserId], FlameRoadModel))
		FlameRoadModel:Destroy()
		print(self.FlameRoads[player.UserId])
	end)
end

return Flameful
