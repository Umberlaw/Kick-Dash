local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")

local Assets = ReplicatedStorage:WaitForChild("Shared").Assets

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)
--local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()

local PlayerController = Knit.CreateController({
	Name = "PlayerController",
	Data = {
		KickStyle = "Nil",
		Aura = "Nil",
		MaxPower = 100,
		Health = 100,
		MaximumHealth = 100,
		OverHealth = 0,
		Stamina = 100,
		Rage = 0,
		Ragdoll = 0,
		MaximumRage = 100,
		WalkSpeed = 50,
		Coin = 0,
		Debuffes = {},
		KickPassive = false,
		AuraPassive = false,
		FusionPassive = false,
		Knocked = false,
		Animations = {},
		Sounds = {},
	},
})

function PlayerController:UpdatePlayersData(comingData)
	print(comingData, "Burada Ragdoll NASIL YOK LA")
	for keys, newDatas in comingData do
		if self.Data[keys] then
			self.Data[keys] = newDatas
		end
	end
	self:UpdatePlayersAnimations()
end

function PlayerController:UpdatePlayersAnimations()
	local TargetKickAnimation = Assets.Animations.KickStyles:FindFirstChild(self.Data.KickStyle)
	local TargetPassiveAnims = Assets.Animations.KickPassives:FindFirstChild(self.Data.KickStyle)
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
end

function PlayerController:KnitStart()
	self.PlayerService.SendPlayerData:Connect(function(comingData)
		self:UpdatePlayersData(comingData)
	end)
	self:LoadPlayersAnimations()
end

return PlayerController
