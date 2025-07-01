local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local starterGui = game:GetService("StarterGui")

local Assets = ReplicatedStorage:WaitForChild("Shared").Assets

local Knit = require(ReplicatedStorage.Packages.knit)
--local Zoneplus = require(ReplicatedStorage.Packages.zoneplus)
local InterfaceTweens = require(ReplicatedStorage.Shared.configs.InterfaceTweens)
local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)

local Promise = require(Knit.Util.Promise)
--local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local PlayerGui = Player:WaitForChild("PlayerGui")
local HealthBarPromise = nil
local StaminaBarPromise = nil
local OldStamina = 0
local OldHealth = 0

local PlayerController = Knit.CreateController({
	Name = "PlayerController",
	Data = {
		KickStyle = "",
		Aura = "",
		Coin = 0,
		WalkSpeed = 50,
		MaxPower = 100,
		Health = 100,
		MaximumHealth = 100,
		OverHealth = 0,
		Stamina = 100,
		MaximumStamina = 100,
		Rage = 0,
		MaximumRage = 100,
		Ragdoll = 0,
		StylePassive = 0,
		AuraPassive = 0,
		FusionPassive = false,
		Knocked = false,
		InSafeZone = true,
		Animations = {},
		Sounds = {},
		Debuffes = {},
	},
})

function PlayerController:SetCoreHuds()
	starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	starterGui:SetCore("ResetButtonCallback", false)
end

function PlayerController:UpdateStaminaBar()
	local StaminaBar = self.CoreHUD.Bottom.Stats.SP
	local StaminaBarRedFrame = StaminaBar.Bar_Change
	local StaminaBarMain = StaminaBarRedFrame.Bar
	local StaminaBarGlow = StaminaBar.BarChangingFrame
	local NewValue = math.floor((self.Data.Stamina / self.Data.MaximumStamina) * 100)

	if StaminaBarPromise then
		StaminaBarPromise:await()
	end

	StaminaBarPromise = Promise.new(function(resolve, reject)
		local percentValue = 1 - (self.Data.Stamina / self.Data.MaximumStamina)
		local StaminaBarPercent = InterfaceTweens:Lerp(0.4, -0.6, percentValue)
		local StaminaBarRedPercent = InterfaceTweens:Lerp(0.4, -0.6, percentValue)
		local StaminaBarGlowPercent = InterfaceTweens:Lerp(0, -1, percentValue)

		local StaminaBarTween =
			InterfaceTweens:HealthBarUpdate(StaminaBarMain.UIGradient, { Offset = Vector2.new(StaminaBarPercent, 0) })
		local StaminaBarGlowTween = InterfaceTweens:HealthBarGlowUpdate(
			StaminaBarGlow.UIGradient,
			{ Offset = Vector2.new(StaminaBarGlowPercent, 0) }
		)
		local StaminaBarRedFrameTween = InterfaceTweens:HealthBarRedUpdate(
			StaminaBarRedFrame.UIGradient,
			{ Offset = Vector2.new(StaminaBarRedPercent, 0) }
		)
		task.spawn(function() --StaminaValueAnims
			--[[{ PopDuration =0,PopScale = 0,time = 0,speed = 0, OriginalPos = UDim2.new(), OriginalSize = UDim2.new(), OriginalRotation = 0}]]
			local currentChanginName = if OldStamina
					and (OldStamina - self.Data.Stamina) < 10
					and (OldStamina - self.Data.Stamina) >= 0
				then "TextDecrease"
				elseif OldStamina and (OldStamina - self.Data.Stamina) >= 10 then "TextLose"
				elseif
					OldStamina
					and (OldStamina - self.Data.Stamina) > -10
					and (OldStamina - self.Data.Stamina) <= 0
				then "TextIncrease"
				elseif
					OldStamina
					and (OldStamina - self.Data.Stamina) <= -10
					and (OldStamina - self.Data.Stamina) <= 0
				then "TextGain"
				else nil
			if not currentChanginName then
				warn("bu ne la")
			end

			local OriginalSize = StaminaBar.Value.Size
			local OriginalPosition = StaminaBar.Value.Position
			local OriginalRotation = StaminaBar.Value.Rotation

			local GrowAnim, ShrinkAnim = InterfaceTweens[currentChanginName](self, StaminaBar.Value, {
				OriginalSize = OriginalSize,
				OriginalPosition = OriginalPosition,
				OriginalRotation = OriginalRotation,
			})
			if GrowAnim and ShrinkAnim then
				GrowAnim:Play()
				GrowAnim.Completed:Wait()
				GrowAnim:Destroy()
				ShrinkAnim:Play()
				ShrinkAnim:Destroy()
			end
		end)
		StaminaBar.Value.Text = tostring(math.floor(NewValue))
		OldStamina = self.Data.Stamina

		StaminaBarTween:Play()
		StaminaBarGlowTween:Play()

		StaminaBarTween.Completed:Wait()
		StaminaBarRedFrameTween:Play()

		resolve()
	end):andThen(function()
		StaminaBarPromise = nil
	end)
end

function PlayerController:UpdateHealthBar()
	local HealthBar = self.CoreHUD.Bottom.Stats.HP
	local HealthBarRedFrame = HealthBar.Bar_Change
	local HealthBarMain = HealthBarRedFrame.Bar
	local HealthBarGlow = HealthBar.BarChangingFrame

	if HealthBarPromise then
		HealthBarPromise:await()
	end
	HealthBarPromise = Promise.new(function(resolve, reject)
		local percentValue = 1 - (self.Data.Health / self.Data.MaximumHealth)
		local HealthBarPercent = InterfaceTweens:Lerp(-0.4, 0.6, percentValue)
		local HealthBarRedPercent = InterfaceTweens:Lerp(-0.4, 0.6, percentValue)
		local HealthBarGlowPercent = InterfaceTweens:Lerp(0, 1, percentValue)
		local NewValue = math.floor((self.Data.Health / self.Data.MaximumHealth) * 100)

		local HealthBarTween =
			InterfaceTweens:HealthBarUpdate(HealthBarMain.UIGradient, { Offset = Vector2.new(HealthBarPercent, 0) })
		local HealthBarGlowTween = InterfaceTweens:HealthBarGlowUpdate(
			HealthBarGlow.UIGradient,
			{ Offset = Vector2.new(HealthBarGlowPercent, 0) }
		)
		local HealthBarRedTween = InterfaceTweens:HealthBarRedUpdate(
			HealthBarRedFrame.UIGradient,
			{ Offset = Vector2.new(HealthBarRedPercent, 0) }
		)
		task.spawn(function() --HealthValueChangings
			--[[{ PopDuration =0,PopScale = 0,time = 0,speed = 0, OriginalPos = UDim2.new(), OriginalSize = UDim2.new(), OriginalRotation = 0}]]
			local currentChanginName = if OldHealth
					and (OldHealth - self.Data.Health) < 10
					and (OldHealth - self.Data.Health) >= 0
				then "TextDecrease"
				elseif OldHealth and (OldHealth - self.Data.Health) >= 10 then "TextLose"
				elseif
					OldHealth
					and (OldHealth - self.Data.Health) > -10
					and (OldHealth - self.Data.Health) <= 0
				then "TextIncrease"
				elseif
					OldHealth
					and (OldHealth - self.Data.Health) <= -10
					and (OldHealth - self.Data.Health) <= 0
				then "TextGain"
				else nil
			if not currentChanginName then
				warn("bu ne la")
			end

			local OriginalSize = HealthBar.Value.Size
			local OriginalPosition = HealthBar.Value.Position
			local OriginalRotation = HealthBar.Value.Rotation

			local GrowAnim, ShrinkAnim = InterfaceTweens[currentChanginName](self, HealthBar.Value, {
				OriginalSize = OriginalSize,
				OriginalPosition = OriginalPosition,
				OriginalRotation = OriginalRotation,
			})
			if GrowAnim and ShrinkAnim then
				GrowAnim:Play()
				GrowAnim.Completed:Wait()
				GrowAnim:Destroy()
				ShrinkAnim:Play()
				ShrinkAnim:Destroy()
			end
		end)
		HealthBar.Value.Text = tostring(NewValue)
		OldHealth = self.Data.Health

		HealthBarTween:Play()
		HealthBarGlowTween:Play()

		HealthBarTween.Completed:Wait()
		HealthBarRedTween:Play()
		resolve()
	end):andThen(function()
		HealthBarPromise = nil
	end)
end

function PlayerController:UpdateHUD(AuraName, StyleName)
	local BottomHud = PlayerGui.CoreHUD.Bottom
	local RageArea = BottomHud.Stats.Rage
	local AuraBar = BottomHud.PassiveRelatives.AuraPassiveBar
	local StyleBar = BottomHud.PassiveRelatives.StylePassiveBar

	local AuraIcon = if ReplicatedStorage.Shared.Assets.Indicators.AuraSymbols:FindFirstChild(AuraName)
		then ReplicatedStorage.Shared.Assets.Indicators.AuraSymbols:FindFirstChild(AuraName).AuraPassiveIcon.Image
		elseif
			ReplicatedStorage.Shared.Assets.Indicators.AuraSymbols:FindFirstChild(self.Data.Aura)
		then ReplicatedStorage.Shared.Assets.Indicators.AuraSymbols:FindFirstChild(self.Data.Aura).AuraPassiveIcon.Image
		else nil
	local StyleIcon = if StyleName
			and ReplicatedStorage.Shared.Assets.Indicators.KickSymbols:FindFirstChild(StyleName)
		then ReplicatedStorage.Shared.Assets.Indicators.KickSymbols:FindFirstChild(StyleName).StylePassiveIcon.Image
		elseif
			ReplicatedStorage.Shared.Assets.Indicators.KickSymbols:FindFirstChild(self.Data.KickStyle)
		then ReplicatedStorage.Shared.Assets.Indicators.KickSymbols:FindFirstChild(self.Data.KickStyle).StylePassiveIcon.Image
		else nil

	local AuraGradient = if ReplicatedStorage.Shared.Assets.Gradients.AuraBased.Defaults:FindFirstChild(AuraName)
		then ReplicatedStorage.Shared.Assets.Gradients.AuraBased.Defaults:FindFirstChild(AuraName)
		else nil
	local function CreateGradient(target)
		if not AuraGradient then
			return
		end
		if target:FindFirstChild("GRADIENT") then
			target:FindFirstChild("GRADIENT"):Destroy()
		end
		local newGradient = AuraGradient:Clone()
		newGradient.Name = "GRADIENT"
		newGradient.Parent = target
	end

	AuraBar.IconGroup.AuraIcon.Image = AuraIcon or ""
	AuraBar.IconGroup.AuraIcon.AuraIcon_Aura.Image = AuraIcon or ""
	CreateGradient(AuraBar.IconGroup.AuraIcon.AuraIcon_Aura)
	for _, PointsName in AuraBar.Points:GetChildren() do
		local AuraParent = PointsName:FindFirstChild("PassivePoint_Aura")
		if AuraParent then
			CreateGradient(AuraParent)
		end
	end
	RageArea.RageBar.Icon.Image = if KickStyleDatas.Auras[AuraName]
		then KickStyleDatas.Auras[AuraName].Cosmetic.Image
		else ""
	CreateGradient(RageArea.RageBar.Background_Aura)

	for _, allEffects in RageArea.Bar2:GetChildren() do
		if not allEffects:IsA("ImageLabel") then
			continue
		end
		CreateGradient(allEffects)
	end

	StyleBar.IconGroup.StyleIcon.StyleIcon.Image = StyleIcon or ""

	for _, alleffects in BottomHud.Effects:GetChildren() do
		if string.find(alleffects.Name, "_Aura") then
			CreateGradient(alleffects)
		end
	end

	local HPBar = BottomHud.Stats.HP
	local StaminaBar = BottomHud.Stats.SP

	if KickStyleDatas.Kicks[StyleName] and KickStyleDatas.Auras[AuraName] then
		local HPtargetPoint = KickStyleDatas.Kicks[StyleName].Stats.HealthPoint
			+ KickStyleDatas.Auras[AuraName].Stats.HealthPoint

		local SPtargetPoint = KickStyleDatas.Kicks[StyleName].Stats.StaminaPoint
			+ KickStyleDatas.Auras[AuraName].Stats.StaminaPoint

		for _, AllBars in HPBar["Divider_Bar"]:GetChildren() do
			if AllBars.Name ~= tostring(HPtargetPoint) then
				AllBars.Visible = false
			else
				AllBars.Visible = true
			end
			if HPtargetPoint > 6 and AllBars.Name == "6" then
				AllBars.Visible = true
			end
		end

		for _, AllBars in StaminaBar["Divider_Bar"]:GetChildren() do
			if AllBars.Name ~= tostring(SPtargetPoint) then
				AllBars.Visible = false
			else
				AllBars.Visible = true
			end
			if SPtargetPoint > 6 and AllBars.Name == "6" then
				AllBars.Visible = true
			end
		end
	end
end

function PlayerController:UpdatePlayersData(comingData)
	for keys, newDatas in comingData do
		if self.Data[keys] ~= nil then
			if keys == "KickStyle" and self.Data[keys] ~= newDatas then
				self:UpdatePlayersAnimations(newDatas)
				self:UpdateHUD(self.Data.Aura, newDatas)
			end
			if keys == "Aura" and self.Data[keys] ~= newDatas then
				print("AURA DEGSIECEK", self.Data[keys], newDatas)
				self:UpdateHUD(newDatas, self.Data.KickStyle)
			end
			if self.Data[keys] ~= newDatas then
				self.Data[keys] = newDatas
			elseif self.Data[keys] == newDatas then
				continue
			end
			if keys == "Health" or keys == "OverHealth" then
				self:UpdateHealthBar()
			end
			if keys == "Stamina" then
				self:UpdateStaminaBar()
			end
		end
	end
end

function PlayerController:UpdatePlayersAnimations(animName)
	print(animName, "UPDATELENECEK")
	local TargetKickAnimation = Assets.Animations.KickStyles:FindFirstChild(animName)
	local TargetPassiveAnims = Assets.Animations.KickPassives:FindFirstChild(animName)
	local Animator = Char.Humanoid.Animator
	local animsTable = {}
	if TargetKickAnimation then
		for _, KickAnims in TargetKickAnimation:GetChildren() do
			if KickAnims:IsA("Animation") then
				table.insert(animsTable, KickAnims.AnimationId)
				self.Data.Animations[KickAnims.Name] = Animator:LoadAnimation(KickAnims)
			end
		end
	end

	if TargetPassiveAnims then
		for _, KickPassiveAnims in TargetPassiveAnims:GetChildren() do
			if KickPassiveAnims:IsA("Animation") then
				table.insert(animsTable, KickPassiveAnims.AnimationId)
				self.Data.Animations[KickPassiveAnims.Name] = Animator:LoadAnimation(KickPassiveAnims)
			end
		end
	end
	ContentProvider:PreloadAsync(animsTable)
end

function PlayerController:LoadPlayersAnimations()
	local CommonAnims = Assets.Animations.Commons
	local TargetKickAnims = Assets.Animations.KickStyles:FindFirstChild(self.Data.KickStyle)
	local TargetPassiveAnims = Assets.Animations.KickPassives:FindFirstChild(self.Data.KickStyle)
	local Animator = Char.Humanoid:FindFirstChild("Animator")
	local animsTable = {}
	for _, CommonAnimations in CommonAnims:GetChildren() do
		if CommonAnimations:IsA("Animation") then
			table.insert(animsTable, CommonAnimations.AnimationId)
			self.Data.Animations[CommonAnimations.Name] = Animator:LoadAnimation(CommonAnimations)
		end
	end
	if TargetKickAnims then
		for _, KickAnims in TargetKickAnims:GetChildren() do
			if KickAnims:IsA("Animation") then
				table.insert(animsTable, KickAnims.AnimationId)
				self.Data.Animations[KickAnims.Name] = Animator:LoadAnimation(KickAnims)
			end
		end
	end

	if TargetPassiveAnims then
		for _, KickPassiveAnims in TargetPassiveAnims:GetChildren() do
			if KickPassiveAnims:IsA("Animation") then
				table.insert(animsTable, KickPassiveAnims.AnimationId)
				self.Data.Animations[KickPassiveAnims.Name] = Animator:LoadAnimation(KickPassiveAnims)
			end
		end
	end
	ContentProvider:PreloadAsync(animsTable)
end

function PlayerController:GetPlayerData()
	return Promise.new(function(resolve, reject)
		if self.Data then
			resolve(self.Data)
		else
			reject("Data missing")
		end
	end)
end

function PlayerController:KnitInit()
	self.PlayerService = Knit.GetService("PlayerService")
	self.CoreHUD = PlayerGui:WaitForChild("CoreHUD")
end

function PlayerController:CameraNuance()
	if self.CameraNuanceTween and self.CameraNuanceTween.PlaybackState == Enum.PlaybackState.Playing then
		self.CameraNuanceTween:Cancel()
		self.CameraNuanceTween = nil
	end
	if self.Data.Health > 0 and not self.Data.Knocked then
		local offset = Char.Torso.CFrame:ToObjectSpace(Char.HumanoidRootPart.CFrame).Position
		local camOffset = Vector3.new(-offset.X, -offset.Y, -offset.Z)
		self.CameraNuanceTween = TweenService:Create(
			Char.Humanoid,
			TweenInfo.new(0.0625, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ CameraOffset = camOffset }
		)
	else
		self.CameraNuanceTween = TweenService:Create(
			Char.Humanoid,
			TweenInfo.new(0.0625, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ CameraOffset = Vector3.zero }
		)
	end

	self.CameraNuanceTween:Play()
end

function PlayerController:LerpMovement()
	local char = Char
	local hrp = char.HumanoidRootPart
	local torso = char.Torso

	local RootJoint = hrp.RootJoint
	local LeftHipJoint = torso["Left Hip"]
	local RightHipJoint = torso["Right Hip"]
	local Force = nil
	local Direction = nil
	local Value1 = 0
	local Value2 = 0

	local RootJointC0 = RootJoint.C0
	local LeftHipJointC0 = LeftHipJoint.C0
	local RightHipJointC0 = RightHipJoint.C0

	RunService.RenderStepped:Connect(function(deltaTime)
		Force = hrp.Velocity * Vector3.new(1, 0, 1)
		if Force.Magnitude > 2 then
			--> This represents the direction
			Direction = Force.Unit
			Value1 = hrp.CFrame.RightVector:Dot(Direction)
			Value2 = hrp.CFrame.LookVector:Dot(Direction)
		else
			Value1 = 0
			Value2 = 0
		end

		--> the values being multiplied are how much you want to rotate by
		RootJoint.C0 =
			RootJoint.C0:Lerp(RootJointC0 * CFrame.Angles(math.rad(Value2 * 18.25), math.rad(-Value1 * 10), 0), 0.2)
		LeftHipJoint.C0 = LeftHipJoint.C0:Lerp(LeftHipJointC0 * CFrame.Angles(math.rad(Value1 * 16.25), 0, 0), 0.2)
		RightHipJoint.C0 = RightHipJoint.C0:Lerp(RightHipJointC0 * CFrame.Angles(math.rad(-Value1 * 16.25), 0, 0), 0.2)
	end)
end

function PlayerController:JumpNuance()
	if self.Data.InSafeZone then
		return
	end

	local jumpForce = 1.15
	local moveDirection = Char.Humanoid.MoveDirection
	local currentVelocity = Char.HumanoidRootPart.Velocity
	local lookDirection = Char.HumanoidRootPart.CFrame.LookVector
	local dashForceMultiplier = 0.5
	local stationaryDashForceMultiplier = -0.25
	if moveDirection.Magnitude > 0 then
		local dashVelocity = currentVelocity + moveDirection * Char.Humanoid.WalkSpeed * dashForceMultiplier
		Char.HumanoidRootPart.Velocity = dashVelocity
	elseif moveDirection.Magnitude == 0 then
		local stationaryDashForce = lookDirection * Char.Humanoid.WalkSpeed * stationaryDashForceMultiplier
		Char.HumanoidRootPart.Velocity = currentVelocity + stationaryDashForce + Vector3.new(0, jumpForce / 3, 0) -- Ufak bir yukarı itme de ekledim
	end
end

function PlayerController:KnitStart()
	self.CameraNuanceTween = nil

	self.PlayerService.SendPlayerData:Connect(function(comingData)
		self:UpdatePlayersData(comingData)
	end)

	self:LoadPlayersAnimations()

	self:SetCoreHuds()
	self:LerpMovement()

	RunService.RenderStepped:Connect(function()
		self:CameraNuance()
	end)
end

return PlayerController
