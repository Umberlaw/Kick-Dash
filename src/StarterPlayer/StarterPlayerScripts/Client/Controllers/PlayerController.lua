local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage:WaitForChild("Shared").Assets

local Knit = require(ReplicatedStorage.Packages.knit)
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
		MaxPower = 100,
		Health = 100,
		MaximumHealth = 100,
		OverHealth = 0,
		Stamina = 100,
		MaximumStamina = 100,
		Rage = 0,
		Ragdoll = 0,
		MaximumRage = 100,
		WalkSpeed = 50,
		Coin = 0,
		Debuffes = {},
		StylePassive = 0,
		AuraPassive = 0,
		FusionPassive = false,
		Knocked = false,
		Animations = {},
		Sounds = {},
	},
})

function PlayerController:UpdateStaminaBar()
	local StaminaBar = self.CoreHUD.Bottom.Stats.SP
	local StaminaBarRedFrame = StaminaBar.Bar_Change
	local StaminaBarMain = StaminaBarRedFrame.Bar
	local StaminaBarGlow = StaminaBar.BarFrame
	local NewValue = math.floor((self.Data.Stamina / self.Data.MaximumStamina) * 100)
	StaminaBar.Value.Text = tostring(math.floor(NewValue))

	if StaminaBarPromise then
		StaminaBarPromise:await()
	end
	StaminaBarPromise = Promise.new(function(resolve, reject)
		local BarChangeRatio = (2 * (NewValue / 100)) - 1
		local ColorBarTween = TweenService:Create(
			StaminaBarMain.Gradient,
			TweenInfo.new(0.74, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
			{ Offset = Vector2.new(BarChangeRatio, 0) }
		)
		local RedFrameTween = TweenService:Create(
			StaminaBarRedFrame.Gradient,
			TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
			{ Offset = Vector2.new(BarChangeRatio, 0) }
		)
		StaminaBarGlow.Gradient.Offset = Vector2.new(BarChangeRatio - 1, 0)
		ColorBarTween.Completed:Connect(function()
			RedFrameTween:Play()
			ColorBarTween:Destroy()
		end)

		RedFrameTween.Completed:Connect(function()
			resolve()
			RedFrameTween:Destroy()
		end)
	end):andThen(function()
		StaminaBarPromise = nil
	end)
end

function PlayerController:UpdateHealthBar()
	local HealthBar = self.CoreHUD.Bottom.Stats.HP
	local HealthBarRedFrame = HealthBar.Bar_Change
	local HealthBarMain = HealthBarRedFrame.Bar
	local HealthBarGlow = HealthBar.BarFrame
	local NewValue = math.floor(((self.Data.Health + self.Data.OverHealth) / self.Data.MaximumHealth) * 100)

	if HealthBarPromise then
		HealthBarPromise:await()
	end
	HealthBarPromise = Promise.new(function(resolve, reject)
		local BarChangeRatio = (-2 * (NewValue / 100)) + 1
		local RedFrameTween = TweenService:Create(
			HealthBarRedFrame.Gradient,
			TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
			{ Offset = Vector2.new(BarChangeRatio, 0) }
		)

		local ColorBarTween = TweenService:Create(
			HealthBarMain.Gradient,
			TweenInfo.new(0.74, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0),
			{ Offset = Vector2.new(BarChangeRatio, 0) }
		)
		HealthBarGlow.Gradient.Offset = Vector2.new(BarChangeRatio + 1, 0)
		ColorBarTween:Play()

		ColorBarTween.Completed:Connect(function()
			HealthBar.Value.Text = tostring(NewValue)
			RedFrameTween:Play()
			ColorBarTween:Destroy()
		end)

		RedFrameTween.Completed:Connect(function()
			resolve()
			RedFrameTween:Destroy()
		end)
	end):andThen(function()
		HealthBarPromise = nil
	end)
end

function PlayerController:UpdatePlayersData(comingData)
	for keys, newDatas in comingData do
		if self.Data[keys] ~= nil then
			if keys == "KickStyle" and self.Data[keys] ~= newDatas then
				self:UpdatePlayersAnimations(newDatas)
			end
			self.Data[keys] = newDatas
			if keys == "Stamina" then
				self:UpdateStaminaBar()
			end
			if keys == "Health" or keys == "OverHealth" then
				self:UpdateHealthBar()
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
end

return PlayerController
