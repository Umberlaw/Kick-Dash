local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
--local Promise = require(Knit.Util.Promise)

local RagdollJointDatas = require(ReplicatedStorage.Shared.configs.RagdollJoints)

local RagdollService = Knit.CreateService({
	Name = "RagdollService",
	Client = { Ragdoll = Knit.CreateSignal(), UnRagdoll = Knit.CreateSignal(), NPCRagdoll = Knit.CreateSignal() },
})

---Ragdol System Features--------------------------------
function RagdollService:KnockBack(KnockingPlayer: Player, KnockDatas: table)
	--Thats an Example Table:    {Direction = Vector3,KnockPower = Number,RagdollDuration = Number}
	local char = KnockingPlayer.Character
	if not char then
		warn("Character didnt find")
		return
	end
	local VectorForce = Instance.new("VectorForce")
	VectorForce.Attachment0 = char.HumanoidRootPart:FindFirstChild("KnockBackAttachment")
	VectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	VectorForce.ApplyAtCenterOfMass = true
	VectorForce.Force = KnockDatas.Direction.Unit * (KnockDatas.KnockPower * 100)
	VectorForce.Parent = char.HumanoidRootPart
	Debris:AddItem(VectorForce, 0.1)
end

---------------------------------------------------

----Ragdoll System Defaults----------------------------------------
function RagdollService:UnRagdoll(RagdollingPlayer)
	self.PlayerService:UpdatePlayerData(RagdollingPlayer, {
		Ragdoll = self.PlayerService.PlayerDatas[RagdollingPlayer.UserId].Ragdoll - 1,
	})
	print(self.PlayerService.PlayerDatas[RagdollingPlayer.UserId])
	if
		self.PlayerService.PlayerDatas[RagdollingPlayer.UserId]
		and self.PlayerService.PlayerDatas[RagdollingPlayer.UserId].Ragdoll <= 0
	then
		print("Unragdollaniyorsun cunkuu:", self.PlayerService.PlayerDatas[RagdollingPlayer.UserId].Ragdoll, "bitti")
		self:RagdollStatus(RagdollingPlayer, false)
	else
		print("Ragdoll sayacin nil ya da ragdoll sayacin 1 den yuksek")
	end
end

function RagdollService:RagdollStatus(RagdollingPlayer: Player, Status: boolean, KnockBackDatas)
	local char = RagdollingPlayer.Character
	if not char then
		warn("RagdollChar missing")
		return
	end
	local hum = char:FindFirstChild("Humanoid")
	if Status then
		if RagdollingPlayer then
			if hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
				char.Humanoid:SetStateEnabled("Jumping", false)
				char.Humanoid.Jump = false
			end
			hum.AutoRotate = false
			hum.PlatformStand = true
		end
		self:CreateJoints(char)
		self:Motor6DEnabled(char, false)
		self:KnockBack(RagdollingPlayer, KnockBackDatas)
		self.PlayerService:UpdatePlayerData(RagdollingPlayer, {
			Ragdoll = if self.PlayerService.PlayerDatas[RagdollingPlayer.UserId]
				then self.PlayerService.PlayerDatas[RagdollingPlayer.UserId].Ragdoll + 1
				else 1,
		})
		task.delay(KnockBackDatas.RagdollDuration, function()
			self:UnRagdoll(RagdollingPlayer)
		end)
	elseif not Status then
		if RagdollingPlayer then
			self.Client.UnRagdoll:Fire(RagdollingPlayer)
		end
		self:DestroyJoints(char)
		task.wait()
		self:Motor6DEnabled(char, true)
		task.wait()
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		hum.PlatformStand = false

		char.Humanoid.Jump = true
		hum.AutoRotate = true
	end
end

function RagdollService:BuildCollideParts(Player)
	local character = Player.character or nil
	if character then
		for _, RootJoints in character:GetChildren() do
			if RootJoints:IsA("BasePart") and RootJoints.Name ~= "HumanoidRootPart" then
				RootJoints.CanCollide = false
				local Collide = RootJoints:Clone()
				Collide.Parent = RootJoints
				Collide.Massless = true
				Collide.Size = Vector3.one
				Collide.Name = "Collide"
				Collide.CollisionGroup = "CollideParts"
				Collide.Transparency = 1
				Collide:ClearAllChildren()
				local Weld = Instance.new("WeldConstraint")
				Weld.Parent = Collide
				Weld.Part0 = RootJoints
				Weld.Part1 = Collide
			end
		end
	end
end

function RagdollService:Motor6DEnabled(character: Model, status: boolean)
	for _, V in character:GetDescendants() do
		if V.Name == "Handle" or V.Name == "RootJoint" or V.Name == "Neck" then
			continue
		end
		if V:IsA("Motor6D") then
			V.Enabled = status
		end
		if V:IsA("BasePart") then
			V.CollisionGroup = if status then "Players" else "RagdolledPlayers"
			if V.Name == "Collide" then
				V.CanCollide = not status
			end
		end
	end
end

function RagdollService:CreateJoints(character: Model)
	local hrp = character:FindFirstChild("HumanoidRootPart")

	for _, childs in character:GetDescendants() do
		if
			not childs:IsA("BasePart")
			or childs:FindFirstAncestor("Accessory")
			or childs.Name == "Handle"
			or childs.Name == "Torso"
			or childs.Name == "HumanoidRootPart"
		then
			continue
		end
		if not RagdollJointDatas[childs.Name] then
			continue
		end
		local A0: Attachment, A1: Attachment = Instance.new("Attachment"), Instance.new("Attachment")
		local joint: Constraint = Instance.new("BallSocketConstraint")

		A0.Name = "RAGDOLL_ATTACHMENT"
		A0.Parent = childs
		A0.CFrame = RagdollJointDatas[childs.Name].CFrames[2]

		A1.Name = "RAGDOLL_ATTACHMENT"
		A1.Parent = if RagdollJointDatas[childs.Name].Target
			then character:FindFirstChild(RagdollJointDatas[childs.Name].Target)
			else hrp
		A1.CFrame = RagdollJointDatas[childs.Name].CFrames[1]

		joint.Name = "RAGDOLL_CONSTRAINT"
		joint.Parent = childs
		joint.Attachment0 = A0
		joint.Attachment1 = A1
		childs.Massless = true
	end
end

function RagdollService:DestroyJoints(character: Model)
	character.HumanoidRootPart.Massless = false
	for _, v in character:GetDescendants() do
		if v:IsA("BasePart") then
			v.Velocity = Vector3.zero
			if v.Name ~= "Collide" then
				v.Massless = false
			end
		end
		if v.Name == "RAGDOLL_ATTACHMENT" or v.Name == "RAGDOLL_CONSTRAINT" then
			v:Destroy()
		end
		if
			not v:IsA("BasePart")
			or v:FindFirstAncestor("Accessory")
			or v.name == "Torso"
			or v.Name == "HumanoidRootPart"
		then
			continue
		end
	end
end

--------------------------------------NPC RAGDOLLL SYSTEM----------------------------------------------------
function RagdollService:NPCRagdoll(RagdollingNPC, Status, KnockBackDatas)
	local char = RagdollingNPC
	local hum = char:FindFirstChild("Humanoid")
	if Status then
		if RagdollingNPC then
			if hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
				char.Humanoid:SetStateEnabled("Jumping", false)
				char.Humanoid.Jump = false
			end
			hum.AutoRotate = false
			hum.PlatformStand = true
		end
		self:CreateJoints(char)
		self:NPCMotor6DEnabled(char, false)
		self:NPCKnockBack(RagdollingNPC, KnockBackDatas)
		task.delay(KnockBackDatas.RagdollDuration, function()
			self:NPCUnRagdoll(RagdollingNPC)
		end)
	elseif not Status then
		self:DestroyJoints(char)
		task.wait()
		self:NPCMotor6DEnabled(char, true)
		task.wait()
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		hum.PlatformStand = false

		char.Humanoid.Jump = true
		hum.AutoRotate = true
	end
end

function RagdollService:NPCUnRagdoll(RagdollingNPC)
	self:NPCRagdoll(RagdollingNPC, false)
end

function RagdollService:NPCKnockBack(KnockingNPC, KnockDatas)
	local VectorForce = Instance.new("VectorForce")
	VectorForce.Attachment0 = KnockingNPC.HumanoidRootPart:FindFirstChild("KnockBackAttachment")
	VectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	VectorForce.ApplyAtCenterOfMass = true
	VectorForce.Force = KnockDatas.Direction.Unit * (KnockDatas.KnockPower * 100)
	VectorForce.Parent = KnockingNPC.HumanoidRootPart
	Debris:AddItem(VectorForce, 0.1)
end

function RagdollService:NPCMotor6DEnabled(character: Model, status: boolean)
	for _, V in character:GetDescendants() do
		if V.Name == "Handle" or V.Name == "RootJoint" or V.Name == "Neck" then
			continue
		end
		if V:IsA("Motor6D") then
			V.Enabled = status
		end
		if V:IsA("BasePart") then
			V.CollisionGroup = if status then "NPC" else "RagdolledPlayers"
			if V.Name == "Collide" then
				V.CanCollide = not status
			end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------

----------------------------

function RagdollService:KnitInit()
	self.PlayerService = Knit.GetService("PlayerService")
end

function RagdollService:KnitStart()
	self.Client.Ragdoll:Connect(function(_, hittingPlayer, KnockBackDatas)
		self:RagdollStatus(hittingPlayer, true, KnockBackDatas)
	end)
	self.Client.NPCRagdoll:Connect(function(_, NPC, KnockBackDatas)
		self:NPCRagdoll(NPC, true, KnockBackDatas)
	end)
end

return RagdollService
