local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Char = Player.Character or Player.CharacterAdded:Wait()

local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)
local AuraHighlights = require(ReplicatedStorage.Shared.configs.AuraHiglights)

local Knit = require(ReplicatedStorage.Packages.knit)
--local Promise = require(Knit.Util.Promise)

local AttackController = Knit.CreateController({
	Name = "AttackController",
	AttackController = nil,
	AttackCon = nil,
	Attacking = nil,
	CameraCon = nil,
	DashCon = nil,
	AnimationConnections = {},
	HittedChars = {},

	HelperAsistanActive = false,
	ProtectSelfRagdoll = false,
	HiglightStatus = "Default",
})

function AttackController:SetHiglight(deltatime)
	if self.HiglightStatus == "Default" and not self.RageActive then
		if self.HiglightDefaultTween and self.HiglightDefaultTween.PlaybackState == Enum.PlaybackState.Playing then
			self.HiglightDefaultTween:Cancel()
			self.HiglightDefaultTween:Destroy()
			self.HiglightDefaultTween = nil
		end
		self.HiglightDefaultTween = TweenService:Create(
			self.Higlight,
			TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, 0),
			{ FillTransparency = AuraHighlights[self.PlayersAttackData.Aura].Default }
		)
		self.HiglightDefaultTween:Play()
		self.HiglightDefaultTween.Completed:Once(function()
			self.HiglightDefaultTween:Destroy()
			self.HiglightDefaultTween = nil
		end)
	elseif self.HiglightStatus == "Default" and #self.RageActive then
		self.HiglightDefaultTween = TweenService:Create(
			self.Higlight,
			TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, 0),
			{ FillTransparency = AuraHighlights[self.PlayersAttackData.Aura].Rage }
		)
		self.HiglightDefaultTween:Play()
		self.HiglightDefaultTween.Completed:Once(function()
			self.HiglightDefaultTween:Destroy()
			self.HiglightDefaultTween = nil
		end)
	elseif self.HiglightStatus == "Attack" then
		self.Higlight.FillTransparency = self.Higlight.FillTransparency
			- (AuraHighlights[self.PlayersAttackData.Aura].Kick * deltatime)
	end
end

function AttackController:Dash(dashpower: number)
	local DashVectorForce = Instance.new("VectorForce")
	DashVectorForce.Attachment0 = Char.HumanoidRootPart:FindFirstChild("KnockBackAttachment")
	DashVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	DashVectorForce.ApplyAtCenterOfMass = true
	DashVectorForce.Parent = Char.HumanoidRootPart

	local function GoingDistance()
		return (2 * (1 + (16 * (dashpower / 100))) * Char.HumanoidRootPart.AssemblyMass) / (0.2 ^ 2)
	end
	local forceamount = GoingDistance()
	if not self.DashCon then
		self.DashCon = RunService.RenderStepped:Connect(function()
			DashVectorForce.Force = Char.HumanoidRootPart.CFrame.LookVector * forceamount * 2
		end)
	end
	task.delay(0.3, function()
		DashVectorForce:Destroy()
		self.DashCon:Disconnect()
		self.DashCon = nil
	end)
end

function AttackController:AimAsistant(CurrentState, NewPosition)
	if not self.HelperAsistanActive and CurrentState then
		self.HelperAsistanActive = true
		self.HelperAsistant.Beam.Enabled = true
	elseif self.HelperAsistanActive and not CurrentState then
		self.HelperAsistant.Beam.Enabled = false
		self.HelperAsistant.Finish.Position = self.HelperAsistant.Position
		self.HelperAsistanActive = false
		return
	end
	if CurrentState then
		self.HelperAsistant.Finish.WorldCFrame = CFrame.new(self.HelperAsistant.Finish.WorldPosition + NewPosition)
	end
end

function AttackController:StartKickAttack(atackpower)
	if not atackpower then
		warn("not attack power have")
		return
	end
	if self.PlayersAttackData.Animations.Prepare.IsPlaying then
		if self.HiglightStatus ~= "Default" then
			self.HiglightStatus = "Default"
			self:SetHiglight(0)
		end
		if self.AttackCon then
			self.AttackCon:Disconnect()
			self:FixCamera()
			self.AttackCon = nil
			self.AttackPower = 0
		end
		self.PlayersAttackData.Animations.Prepare:Stop()
		self.AnimationConnections["Prepare"]:Disconnect()
		self.AnimationConnections["Locking"]:Disconnect()
		self.AnimationConnections["ChargeUp"]:Disconnect()
		self.AnimationConnections["ChargeCrack"]:Disconnect()
		self.AnimationConnections["ChargeCrack"] = nil
		self.AnimationConnections["ChargeUp"] = nil
		self.AnimationConnections["Locking"] = nil
		self.AnimationConnections["Prepare"] = nil
		self.PlayersAttackData.Animations.Attack:Play()
		self.AnimationConnections["AttackRelease"] = self.PlayersAttackData.Animations.Attack
			:GetMarkerReachedSignal("AttackRelease")
			:Connect(function()
				local TargetData = KickStyleDatas.Kicks[self.PlayersAttackData.KickStyle]
				if TargetData then
					for _, AllHitboxes in TargetData.HitboxTarget do
						local params = OverlapParams.new()
						params.FilterDescendantsInstances = { Char }
						params.FilterType = Enum.RaycastFilterType.Exclude
						params.MaxParts = 100
						task.spawn(function()
							repeat
								local TouchingItems = workspace:GetPartBoundsInBox(
									Char:FindFirstChild(AllHitboxes).CFrame,
									Char:FindFirstChild(AllHitboxes).Size * 3,
									params
								)
								for _, allTouchingitems in TouchingItems do
									local KnockBackDatas = {
										Direction = Char.HumanoidRootPart.CFrame.LookVector,
										KnockPower = atackpower,
										RagdollDuration = 3,
									}
									if
										game.Players:GetPlayerFromCharacter(allTouchingitems.Parent)
										and not table.find(self.HittedChars, allTouchingitems.Parent)
									then
										table.insert(self.HittedChars, allTouchingitems.Parent)
										self.ProtectSelfRagdoll = true
										self.RagdollController:RagdollChar(allTouchingitems.Parent, KnockBackDatas) --ToDo  ileriye donuk saldiri hasar rage kisimlari eklenecek
										self.AttackService.Attack:Fire(
											game.Players:GetPlayerFromCharacter(allTouchingitems.Parent),
											{ "tEST" }
										)
									elseif
										not game.Players:GetPlayerFromCharacter(allTouchingitems.Parent)
										and allTouchingitems.CollisionGroup == "NPC"
										and not table.find(self.HittedChars, allTouchingitems.Parent)
										and allTouchingitems.Parent:FindFirstChild("Humanoid")
									then
										table.insert(self.HittedChars, allTouchingitems.Parent)
										self.ProtectSelfRagdoll = true
										self.RagdollController:NPCRagdoll(allTouchingitems.Parent, KnockBackDatas) -- Burayada saldiri hasar rage pasif ssitemleri eklenecek
										self.AttackService.NPCAttack:Fire(allTouchingitems.Parent, { "tEST" })
									end
								end
								task.wait()
							until not self.Attacking
						end)
					end
				end
			end)
		self.AnimationConnections["AttackFinished"] = self.PlayersAttackData.Animations.Attack
			:GetMarkerReachedSignal("Finished")
			:Connect(function()
				self.AnimationConnections["AttackRelease"]:Disconnect()
				self.AnimationConnections["AttackRelease"] = nil
				self.Attacking = false
				self.AnimationConnections["AttackFinished"]:Disconnect()
				self.AnimationConnections["AttackFinished"] = nil
				self.HittedChars = {}
				Char.Humanoid.WalkSpeed = self.PlayersAttackData.WalkSpeed
				self:FixCamera()
				self:AimAsistant(false)
				if
					atackpower / self.PlayersAttackData.MaxPower
						>= KickStyleDatas.Kicks[self.PlayersAttackData.KickStyle].Stats.RagdollPercent
					and not self.ProtectSelfRagdoll
				then
					local KnockBackDatas = {
						Direction = Char.HumanoidRootPart.CFrame.LookVector,
						KnockPower = 25,
						RagdollDuration = 3,
					}
					self.RagdollController:RagdollChar(Char, KnockBackDatas)
					self.AttackService.Attack:Fire(game.Players:GetPlayerFromCharacter(Char), { "tEST" })
				end
				self.ProtectSelfRagdoll = false
			end)
	end
end

function AttackController:StartKickPassiveAttack(atackpower)
	if not atackpower then
		warn("not attack power have")
		return
	end
	self.AttackService.PassiveRelease:Fire() --If game need data will send there
	if self.PlayersAttackData.Animations.PreparePassive.IsPlaying then
		if self.HiglightStatus ~= "Default" then
			self.HiglightStatus = "Default"
			self:SetHiglight(0)
		end
		if self.AttackCon then
			self.AttackCon:Disconnect()
			self:FixCamera()
			self.AttackCon = nil
			self.AttackPower = 0
		end
		self.PlayersAttackData.Animations.PreparePassive:Stop()
		self.AnimationConnections["Prepare"]:Disconnect()
		self.AnimationConnections["Locking"]:Disconnect()
		self.AnimationConnections["ChargeUp"]:Disconnect()
		self.AnimationConnections["ChargeCrack"]:Disconnect()
		self.AnimationConnections["ChargeCrack"] = nil
		self.AnimationConnections["ChargeUp"] = nil
		self.AnimationConnections["Locking"] = nil
		self.AnimationConnections["Prepare"] = nil
		self.PlayersAttackData.Animations.AttackPassive:Play()
		self.AnimationConnections["AttackRelease"] = self.PlayersAttackData.Animations.AttackPassive
			:GetMarkerReachedSignal("AttackRelease")
			:Connect(function()
				local TargetData = KickStyleDatas.Kicks[self.PlayersAttackData.KickStyle]
				if TargetData then
					for _, AllHitboxes in TargetData.HitboxTarget do
						local params = OverlapParams.new()
						params.FilterDescendantsInstances = { Char }
						params.FilterType = Enum.RaycastFilterType.Exclude
						params.MaxParts = 100
						task.spawn(function()
							repeat
								local TouchingItems = workspace:GetPartBoundsInBox(
									Char:FindFirstChild(AllHitboxes).CFrame,
									Char:FindFirstChild(AllHitboxes).Size * 3,
									params
								)
								for _, allTouchingitems in TouchingItems do
									local KnockBackDatas = {
										Direction = Char.HumanoidRootPart.CFrame.LookVector,
										KnockPower = atackpower,
										RagdollDuration = 3,
									}
									if
										game.Players:GetPlayerFromCharacter(allTouchingitems.Parent)
										and not table.find(self.HittedChars, allTouchingitems.Parent)
									then
										table.insert(self.HittedChars, allTouchingitems.Parent)
										self.ProtectSelfRagdoll = true
										self.RagdollController:RagdollChar(allTouchingitems.Parent, KnockBackDatas) --ToDo  ileriye donuk saldiri hasar rage kisimlari eklenecek
										self.AttackService.Attack:Fire(
											game.Players:GetPlayerFromCharacter(allTouchingitems.Parent),
											{ "tEST" }
										)
									elseif
										not game.Players:GetPlayerFromCharacter(allTouchingitems.Parent)
										and allTouchingitems.CollisionGroup == "NPC"
										and not table.find(self.HittedChars, allTouchingitems.Parent)
										and allTouchingitems.Parent:FindFirstChild("Humanoid")
									then
										table.insert(self.HittedChars, allTouchingitems.Parent)
										self.ProtectSelfRagdoll = true
										self.RagdollController:NPCRagdoll(allTouchingitems.Parent, KnockBackDatas) -- Burayada saldiri hasar rage pasif ssitemleri eklenecek
										self.AttackService.NPCAttack:Fire(allTouchingitems.Parent, { "tEST" })
									end
								end
								task.wait()
							until not self.Attacking
						end)
					end
				end
			end)
		self.AnimationConnections["AttackFinished"] = self.PlayersAttackData.Animations.AttackPassive
			:GetMarkerReachedSignal("Finished")
			:Connect(function()
				self.AnimationConnections["AttackRelease"]:Disconnect()
				self.AnimationConnections["AttackRelease"] = nil
				self.Attacking = false
				self.AnimationConnections["AttackFinished"]:Disconnect()
				self.AnimationConnections["AttackFinished"] = nil
				self.HittedChars = {}
				Char.Humanoid.WalkSpeed = self.PlayersAttackData.WalkSpeed
				self:FixCamera()
				self:AimAsistant(false)
				if
					atackpower / self.PlayersAttackData.MaxPower
						>= KickStyleDatas.Kicks[self.PlayersAttackData.KickStyle].Stats.RagdollPercent
					and not self.ProtectSelfRagdoll
				then
					local KnockBackDatas = {
						Direction = Char.HumanoidRootPart.CFrame.LookVector,
						KnockPower = 25,
						RagdollDuration = 3,
					}
					self.RagdollController:RagdollChar(Char, KnockBackDatas)
					self.AttackService.Attack:Fire(game.Players:GetPlayerFromCharacter(Char), { "tEST" })
				end
				self.ProtectSelfRagdoll = false
			end)
	end
end

function AttackController:FixCamera()
	local success, CameraDatas = self.CameraController:GetCameraData(self.PlayersAttackData):await()

	if success and CameraDatas then
		if self.CameraCon then
			self.CameraCon:Disconnect()
			self.CameraCon = nil
		end
		if not self.CameraCon then
			local currentCam = workspace.CurrentCamera
			self.CameraCon = RunService.RenderStepped:Connect(function(dt)
				if currentCam.FieldOfView == CameraDatas.NormalPov then
					self.CameraCon:Disconnect()
					self.CameraCon = nil
					currentCam.FieldOfView = CameraDatas.NormalPov
				end
				if currentCam.FieldOfView < CameraDatas.NormalPov then
					currentCam.FieldOfView =
						math.clamp(currentCam.FieldOfView + (CameraDatas.ZoomSpeed * dt * 60), 0, CameraDatas.NormalPov)
				elseif currentCam.FieldOfView > CameraDatas.NormalPov then
					currentCam.FieldOfView =
						math.clamp(currentCam.FieldOfView - (CameraDatas.ZoomSpeed * dt * 10), 0, CameraDatas.NormalPov)
				end
			end)
		end
	end
end

function AttackController:KickAttack()
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local success, playersData = self.PlayerController:GetPlayerData():await()
			print(playersData)
			if success and playersData and type(playersData.StylePassive) ~= "boolean" then
				self.PlayersAttackData = playersData
				print(self.PlayersAttackData.Knocked)
				local camsuccess, CameraDatas = self.CameraController:GetCameraData(playersData):await()
				if
					not self.Attacking
					and not self.AttackCon
					and self.PlayersAttackData.Ragdoll <= 0
					and not self.PlayersAttackData.Knocked
				then
					self.AttackPower = 0
					if self.CameraCon then
						self.CameraCon:Disconnect()
						self.CameraCon = nil
					end
					self.HiglightStatus = "Attack"
					self.AttackCon = RunService.RenderStepped:Connect(function(dt)
						self.AttackPower += dt * 32
						Char.Humanoid.WalkSpeed -= self.PlayersAttackData.WalkSpeed * dt
						if self.AttackPower >= 3 then
							local newPosition = Char.HumanoidRootPart.CFrame.LookVector * dt * 10
							self:AimAsistant(true, newPosition)
						end
						self:SetHiglight(dt)
						--Camera Area--------------------------------------
						if camsuccess and CameraDatas then
							local currentCam = workspace.CurrentCamera
							if self.PlayersAttackData.Animations.Prepare.TimePosition <= 0.5 then
								currentCam.FieldOfView = currentCam.FieldOfView + (CameraDatas.ZoomSpeed * dt * 30)
							elseif
								currentCam.FieldOfView >= CameraDatas.MidValue
								or self.PlayersAttackData.Animations.Prepare.TimePosition <= 3.5
							then
								currentCam.FieldOfView = currentCam.FieldOfView - (CameraDatas.ZoomSpeed * dt * 30)
								if currentCam.FieldOfView <= CameraDatas.MinimumValue then
									currentCam.FieldOfView = CameraDatas.MinimumValue
								end
							end
						end
						--------------------------------------------------
						if self.AttackPower >= self.PlayersAttackData.MaxPower then
							self.AttackCon:Disconnect()
							self.AttackCon = nil
							self:StartKickAttack(self.AttackPower)
							self:Dash(self.AttackPower)
						end
						if not self.PlayersAttackData.Animations.Prepare.IsPlaying and not self.Attacking then
							self.PlayersAttackData.Animations.Prepare:Play()
							self.Attacking = true

							self.AnimationConnections["Prepare"] = self.PlayersAttackData.Animations.Prepare
								:GetMarkerReachedSignal("Finished")
								:Connect(function()
									self:StartKickAttack(self.atackpower)
								end)
							self.AnimationConnections["Locking"] = self.PlayersAttackData.Animations.Prepare
								:GetMarkerReachedSignal("Locking")
								:Connect(function()
									Char.Humanoid.WalkSpeed = 0
								end)
							self.AnimationConnections["ChargeUp"] = self.PlayersAttackData.Animations.Prepare
								:GetMarkerReachedSignal("ChargeUp")
								:Connect(function()
									--Todo
								end)
							self.AnimationConnections["ChargeCrack"] = self.PlayersAttackData.Animations.Prepare
								:GetMarkerReachedSignal("ChargeCrack")
								:Connect(function()
									--Todo
								end)
						end
					end)
				end
			elseif success and playersData and type(playersData.StylePassive) == "boolean" then
				self.PlayersAttackData = playersData
				local camsuccess, CameraDatas = self.CameraController:GetCameraData(playersData):await()
				if not self.Attacking and not self.AttackCon and self.PlayersAttackData.Ragdoll <= 0 then
					self.AttackPower = 0
					if self.CameraCon then
						self.CameraCon:Disconnect()
						self.CameraCon = nil
					end
					self.HiglightStatus = "Attack"
					self.AttackCon = RunService.RenderStepped:Connect(function(dt)
						self.AttackPower += dt * 32
						Char.Humanoid.WalkSpeed -= self.PlayersAttackData.WalkSpeed * dt
						if self.AttackPower >= 3 then
							local newPosition = Char.HumanoidRootPart.CFrame.LookVector * dt * 10
							self:AimAsistant(true, newPosition)
						end
						self:SetHiglight(dt)
						--Camera Area--------------------------------------
						if camsuccess and CameraDatas then
							local currentCam = workspace.CurrentCamera
							if self.PlayersAttackData.Animations.Prepare.TimePosition <= 0.5 then
								currentCam.FieldOfView = currentCam.FieldOfView + (CameraDatas.ZoomSpeed * dt * 30)
							elseif
								currentCam.FieldOfView >= CameraDatas.MidValue
								or self.PlayersAttackData.Animations.Prepare.TimePosition <= 3.5
							then
								currentCam.FieldOfView = currentCam.FieldOfView - (CameraDatas.ZoomSpeed * dt * 30)
								if currentCam.FieldOfView <= CameraDatas.MinimumValue then
									currentCam.FieldOfView = CameraDatas.MinimumValue
								end
							end
						end
						--------------------------------------------------
						if self.AttackPower >= self.PlayersAttackData.MaxPower then
							self.AttackCon:Disconnect()
							self.AttackCon = nil
							self:StartKickPassiveAttack(self.AttackPower)
							self:Dash(self.AttackPower)
						end
						if not self.PlayersAttackData.Animations.PreparePassive.IsPlaying and not self.Attacking then
							self.PlayersAttackData.Animations.PreparePassive:Play()
							self.Attacking = true

							self.AnimationConnections["Prepare"] = self.PlayersAttackData.Animations.PreparePassive
								:GetMarkerReachedSignal("Finished")
								:Connect(function()
									self:StartKickPassiveAttack(self.atackpower)
								end)
							self.AnimationConnections["Locking"] = self.PlayersAttackData.Animations.PreparePassive
								:GetMarkerReachedSignal("Locking")
								:Connect(function()
									Char.Humanoid.WalkSpeed = 0
								end)
							self.AnimationConnections["ChargeUp"] = self.PlayersAttackData.Animations.PreparePassive
								:GetMarkerReachedSignal("ChargeUp")
								:Connect(function()
									--Todo
								end)
							self.AnimationConnections["ChargeCrack"] = self.PlayersAttackData.Animations.PreparePassive
								:GetMarkerReachedSignal("ChargeCrack")
								:Connect(function()
									--Todo
								end)
						end
					end)
				end
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		local success, playersData = self.PlayerController:GetPlayerData():await()
		if success then
			self.PlayersAttackData = playersData
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self.Attacking and self.AttackCon and type(playersData.StylePassive) ~= "boolean" then
				self.AttackCon:Disconnect()
				self.AttackCon = nil
				self:AimAsistant(false)
				if self.HiglightStatus ~= "Default" then
					self.HiglightStatus = "Default"
					self:SetHiglight(0)
				end
				if self.AttackPower >= 7 and not self.AttackCon then
					self:StartKickAttack(self.AttackPower)
					self:Dash(self.AttackPower)
				elseif self.AttackPower < 7 then
					if self.PlayersAttackData.Animations.Prepare.IsPlaying then
						self.PlayersAttackData.Animations.Prepare:Stop()
						self.Attacking = false
					end
				end
				self.AttackPower = 0
				Char.Humanoid.WalkSpeed = self.PlayersAttackData.WalkSpeed --KALDIRILACAKLAR
				self:FixCamera()
			elseif self.Attacking and self.AttackCon and type(playersData.StylePassive) == "boolean" then
				self.AttackCon:Disconnect()
				self.AttackCon = nil
				self:AimAsistant(false)
				if self.HiglightStatus ~= "Default" then
					self.HiglightStatus = "Default"
					self:SetHiglight(0)
				end
				if self.AttackPower >= 7 and not self.AttackCon then
					self:StartKickPassiveAttack(self.AttackPower)
					self:Dash(self.AttackPower)
				elseif self.AttackPower < 7 then
					if self.PlayersAttackData.Animations.PreparePassive.IsPlaying then
						self.PlayersAttackData.Animations.PreparePassive:Stop()
						self.Attacking = false
					end
				end
				self.AttackPower = 0
				Char.Humanoid.WalkSpeed = self.PlayersAttackData.WalkSpeed --KALDIRILACAKLAR
				self:FixCamera()
			end
		end
	end)
	UserInputService.JumpRequest:Connect(function()
		if self.Attacking then
			Char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		else
			if self.PlayersAttackData and self.PlayersAttackData.Ragdoll <= 0 then
				Char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			elseif self.PlayersAttackData and self.PlayersAttackData.Ragdoll >= 0 then
				Char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			end
		end
	end)
end

function AttackController:KnitInit()
	self.AttackService = Knit.GetService("AttackService")
	self.PlayerController = Knit.GetController("PlayerController")
	self.SoundController = Knit.GetController("SoundController")
	self.EffectController = Knit.GetController("EffectController")
	self.RagdollController = Knit.GetController("RagdollController")
	self.CameraController = Knit.GetController("CameraController")
	self.HelperAsistant = Char:WaitForChild("HumanoidRootPart"):WaitForChild("Helper", 9e9)
	self.Higlight = Char:WaitForChild("AURAHIGHLIGHT", 9e9)
end

function AttackController:KnitStart()
	self:KickAttack()
end

return AttackController
