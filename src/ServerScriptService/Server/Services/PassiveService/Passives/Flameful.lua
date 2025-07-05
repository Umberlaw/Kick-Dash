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

function Flameful:Clear(player) end

function Flameful:Start(player, otherdatas)
	local FlamefulRoadAsset = ReplicatedStorage.Shared.Assets.Models:FindFirstChild("FlamefulRoad")
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
	for _, AllEffects in FlamefulRoadAsset.OnLaunch:GetChildren() do
		print(AllEffects)
		local clonnedEffect = AllEffects:Clone()
		clonnedEffect.Enabled = true
		clonnedEffect.Parent = otherdatas.HittedPlayer.Character.HumanoidRootPart

		task.delay(clonnedEffect:GetAttribute(clonnedEffect:GetAttribute("EnabledTime") or 1.15), function()
			clonnedEffect.Enabled = false
			task.delay(0.1, function()
				clonnedEffect:Destroy()
			end)
		end)
	end
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
	local FlameRoadCreateSound = FlameRoadModel:FindFirstChild("FlamefulRoadCreate")
	local FlameRoadHitSound = FlameRoadModel:FindFirstChild("FlamefulRoadHit")
	local FlamefulRoadIdle = FlameRoadModel:FindFirstChild("FlamefulRoadIdle")
	FlameRoadModel.Size = Vector3.new(4, 1, Magnitude)
	FlameRoadCreateSound:Play()
	FlamefulRoadIdle:Play()
	FlameRoadModel.CFrame = CFrame.lookAt(StartPos.Position + direction * (Magnitude / 2), FinishPos.Position)
	FlameRoadModel.Parent = workspace
	table.insert(self.FlameRoads[player.UserId], FlameRoadModel)
	print(self.FlameRoads[player.UserId])
	for _, allParticles in FlameRoadModel:GetChildren() do
		if allParticles:IsA("ParticleEmitter") then
			allParticles.Rate = allParticles:GetAttribute("Rate")
		end
	end

	local roadTouched = FlameRoadModel.Touched:Connect(function(touchingobject)
		if touchingobject.Parent:FindFirstChild("Humanoid") then
			local char = touchingobject.Parent
			if self.AlreadyTouchedThings[char] then
				return
			else
				self.AlreadyTouchedThings[char] = char
				FlameRoadHitSound:Play()
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

	task.delay(20, function()
		FlamefulRoadIdle:Stop()
		roadTouched:Disconnect()
		table.remove(self.FlameRoads[player.UserId], table.find(self.FlameRoads[player.UserId], FlameRoadModel))
		for _, allParticles in FlameRoadModel:GetChildren() do
			if allParticles:IsA("ParticleEmitter") then
				allParticles.Enabled = false
			end
		end
		print(self.FlameRoads[player.UserId])
		task.delay(1, function()
			FlameRoadModel:Destroy()
		end)
	end)
end

return Flameful
