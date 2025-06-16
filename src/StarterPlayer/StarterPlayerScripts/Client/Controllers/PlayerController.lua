local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local starterGui = game:GetService("StarterGui")

local Assets = ReplicatedStorage:WaitForChild("Shared").Assets

local Knit = require(ReplicatedStorage.Packages.knit)
local Zoneplus = require(ReplicatedStorage.Packages.zoneplus)
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
		InSafeZone = false,
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

		StaminaBarRedFrameTween.Completed:Wait()
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

		HealthBarRedTween.Completed:Wait()
		resolve()
	end):andThen(function()
		print("oYnadik Bitti kral")

		HealthBarPromise = nil
	end)
end

function PlayerController:UpdateHUD(AuraName)
	local BottomHud = PlayerGui.CoreHUD.Bottom
	local RageArea = BottomHud.Stats.Rage
	local AuraBar = BottomHud.PassiveRelatives.AuraPassiveBar
	local StyleBar = BottomHud.PassiveRelatives.StylePassiveBar

	local AuraIcon = if ReplicatedStorage.Shared.Assets.Indicators.AuraSymbols:FindFirstChild(AuraName)
		then ReplicatedStorage.Shared.Assets.Indicators.AuraSymbols:FindFirstChild(AuraName).AuraPassiveIcon.Image
		else nil
	local StyleIcon = if ReplicatedStorage.Shared.Assets.Indicators.KickSymbols:FindFirstChild(self.Data.KickStyle)
		then ReplicatedStorage.Shared.Assets.Indicators.KickSymbols:FindFirstChild(self.Data.KickStyle).StylePassiveIcon.Image
		else nil

	local AuraGradient = if ReplicatedStorage.Shared.Assets.Gradients.AuraBased.Defaults:FindFirstChild(AuraName)
		then ReplicatedStorage.Shared.Assets.Gradients.AuraBased.Defaults:FindFirstChild(AuraName)
		else nil
	local function CreateGradient(target)
		if not AuraGradient then
			return
		else
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
end

function PlayerController:UpdatePlayersData(comingData)
	if comingData["Health"] then
		print(comingData, "CHECKLE BAKIM BI BIRAZCIK")
	end

	for keys, newDatas in comingData do
		if self.Data[keys] ~= nil then
			if keys == "KickStyle" and self.Data[keys] ~= newDatas then
				self:UpdatePlayersAnimations(newDatas)
				self:UpdateHUD("NIL")
			end
			if keys == "Aura" and self.Data[keys] ~= newDatas then
				print("AURA DEGSIECEK", self.Data[keys], newDatas)
				self:UpdateHUD(newDatas)
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

function PlayerController:KnitStart()
	self.PlayerService.SendPlayerData:Connect(function(comingData)
		self:UpdatePlayersData(comingData)
	end)

	self:LoadPlayersAnimations()

	self:SetCoreHuds()
end

return PlayerController
