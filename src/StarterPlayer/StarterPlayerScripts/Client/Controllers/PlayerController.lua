local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local starterGui = game:GetService("StarterGui")

local Assets = ReplicatedStorage:WaitForChild("Shared").Assets

local Knit = require(ReplicatedStorage.Packages.knit)
local Zoneplus = require(ReplicatedStorage.Packages.zoneplus)
local InterfaceTweens = require(ReplicatedStorage.Shared.configs.InterfaceTweens)

local Promise = require(Knit.Util.Promise)
--local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local PlayerGui = Player:WaitForChild("PlayerGui")
local HealthBarPromise = nil
local StaminaBarPromise = nil

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
		local StaminaBarGlowPercent = InterfaceTweens:Lerp(0, 1, percentValue)

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
			local FadeInTween, UIFadeinTween, GrowTween, ShrinkTween, FadeOutTween, StrokeFadeOutTween, ResetTween =
				InterfaceTweens:FadeInOut(StaminaBar.ValueBox.Value, {})

			if UIFadeinTween then
				UIFadeinTween:Play()
			end

			FadeInTween:Play()
			FadeInTween.Completed:Connect(function()
				StaminaBar.ValueBox.Value.Text = tostring(NewValue)
				FadeInTween:Destroy()
				GrowTween:Play()
			end)
			GrowTween.Completed:Connect(function()
				ShrinkTween:Play()
				GrowTween:Destroy()
			end)
			ShrinkTween.Completed:Connect(function()
				if StrokeFadeOutTween then
					StrokeFadeOutTween:Play()
				end
				FadeOutTween:Play()
				ShrinkTween:Destroy()
			end)
			FadeOutTween.Completed:Connect(function()
				ResetTween:Play()
				FadeOutTween:Destroy()
			end)
			ResetTween.Completed:Connect(function()
				ResetTween:Destroy()
			end)
		end)
		StaminaBar.ValueBox.Value.Text = tostring(math.floor(NewValue))

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
		local NewValue = math.floor(((self.Data.Health + self.Data.OverHealth) / self.Data.MaximumHealth) * 100)

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
		task.spawn(function() --HealthBarAnims
			local FadeInTween, UIFadeinTween, GrowTween, ShrinkTween, FadeOutTween, StrokeFadeOutTween, ResetTween =
				InterfaceTweens:FadeInOut(HealthBar.Value, {})

			if UIFadeinTween then
				UIFadeinTween:Play()
			end

			FadeInTween:Play()
			FadeInTween.Completed:Connect(function()
				HealthBar.Value.Text = tostring(NewValue)
				FadeInTween:Destroy()
				GrowTween:Play()
			end)
			GrowTween.Completed:Connect(function()
				ShrinkTween:Play()
				GrowTween:Destroy()
			end)
			ShrinkTween.Completed:Connect(function()
				if StrokeFadeOutTween then
					StrokeFadeOutTween:Play()
				end
				FadeOutTween:Play()
				ShrinkTween:Destroy()
			end)
			FadeOutTween.Completed:Connect(function()
				ResetTween:Play()
				FadeOutTween:Destroy()
			end)
			ResetTween.Completed:Connect(function()
				ResetTween:Destroy()
			end)
		end)

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

function PlayerController:UpdatePlayersData(comingData)
	for keys, newDatas in comingData do
		if self.Data[keys] ~= nil then
			if keys == "KickStyle" and self.Data[keys] ~= newDatas then
				self:UpdatePlayersAnimations(newDatas)
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
