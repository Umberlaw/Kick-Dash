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
	local NewValue = math.floor((self.Data.Stamina / self.Data.MaximumStamina) * 100)
	StaminaBar.Value.Text = tostring(math.floor(NewValue))
end

function PlayerController:UpdateHealthBar()
	local HealthBar = self.CoreHUD.Bottom.Stats.HP
	local NewValue = math.floor(((self.Data.Health + self.Data.OverHealth) / self.Data.MaximumHealth) * 100)
	HealthBar.Value.Text = tostring(NewValue)
end

function PlayerController:UpdatePlayersData(comingData)
	for keys, newDatas in comingData do
		if self.Data[keys] then
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
