local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)

local KickStlyeDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)
local HiglightDatas = require(ReplicatedStorage.Shared.configs.AuraHiglights)

--local Promise = require(Knit.Util.Promise)

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	Client = { SendPlayerData = Knit.CreateSignal() },
	PlayerDatas = {},
})

function PlayerService:ClearPlayerDatas(player)
	local TargetPlayerData = self.PlayerDatas[player.UserId]

	if not TargetPlayerData then
		warn("Player didnd have any data whole game WOAAA")
	end

	for debufNames, _ in TargetPlayerData.Debuffes do
		self.StatusService:RemoveStatus(player, debufNames)
	end
	self.StatusService:RemoveStatus(player, "OverHealth")
	self.PlayerDatas[player.UserId] = nil
end

function PlayerService:SetKickStats(comingData)
	local HealthPoint = (
		KickStlyeDatas.Kicks[comingData.EquippedKickStyle].Stats.HealthPoint
		+ KickStlyeDatas.Auras[comingData.EquippedAura].Stats.HealthPoint
	) * 30
	local StaminaPoint = (
		KickStlyeDatas.Kicks[comingData.EquippedKickStyle].Stats.StaminaPoint
		+ KickStlyeDatas.Auras[comingData.EquippedAura].Stats.StaminaPoint
	) * 40
	local RagePoint = (
		KickStlyeDatas.Kicks[comingData.EquippedKickStyle].Stats.RagePoint
		+ KickStlyeDatas.Auras[comingData.EquippedAura].Stats.RagePoint
	) * 20

	return { MaximumHealth = HealthPoint, MaximumStamina = StaminaPoint, MaximumRage = RagePoint }
end

function PlayerService:RemoveDebuff(player, DebuffName)
	if self.PlayerDatas[player.UserId].Debuffes[DebuffName] then
		if self.PlayerDatas[player.UserId].Debuffes[DebuffName].Indicator then
			--BURAYA  EFEKTSERVICEDEN INDICATOR KALDIRMA EKLENECEK
			print("Buraya daha eklenecek efekt service")
		end
		self.PlayerDatas[player.UserId].Debuffes[DebuffName] = nil
	end
	print(self.PlayerDatas[player.UserId].Debuffes)
end

function PlayerService:UpdateDebuffData(player, debuffName, debuffData)
	local TargetPlayerData = self.PlayerDatas[player.UserId] or nil
	if not TargetPlayerData then
		warn("TargetPlayer Data Didnt find")
		return
	end
	if not TargetPlayerData.Debuffes[debuffName] then
		TargetPlayerData.Debuffes[debuffName] = {}
		for debuffKey, detail in debuffData do
			TargetPlayerData.Debuffes[debuffName][debuffKey] = detail
		end
		self.StatusService:ActivateDebuff(player, debuffName)
	elseif TargetPlayerData.Debuffes[debuffName] then
		for debuffKey, detail in debuffData do
			if type(detail) == "number" then
				TargetPlayerData.Debuffes[debuffName][debuffKey] += detail
			end
		end
	end
	print(TargetPlayerData.Debuffes)
end

function PlayerService:UpdatePlayerData(player, comingData: table)
	local DataSet = {
		KickStyle = "Nil",
		Aura = "Nil",
		MaxPower = 0,
		Health = 0,
		MaximumHealth = 0,
		OverHealth = 0,
		Stamina = 0,
		Rage = 0,
		MaximumRage = 0,
		WalkSpeed = 25,
		Ragdoll = 0,
		Coin = 0,
		Emerald = 0,
		KickPassive = 0,
		AuraPassive = 0,
		Debuffes = {},
		FusionPassive = false,
		Knocked = false,
		RageActive = false,
	}
	if not self.PlayerDatas[player.UserId] then
		self.PlayerDatas[player.UserId] = DataSet
	end
	for keys, changindatas in comingData do
		if self.PlayerDatas[player.UserId][keys] then
			self.PlayerDatas[player.UserId][keys] = changindatas
		end
	end
	self.Client.SendPlayerData:Fire(player, self.PlayerDatas[player.UserId])
	local char = player.Character
	local AuraHiglight = char:FindFirstChild("AURAHIGHLIGHT")

	local AuraTable = {
		FillColor = Color3.fromRGB(255, 255, 255),
		FillTransparency = 1.125,
		OutlineColor = Color3.fromRGB(255, 255, 255),
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.Occluded,
	}

	for PropertyName, Value in HiglightDatas[self.PlayerDatas[player.UserId].Aura] do
		if AuraTable[PropertyName] then
			AuraHiglight[PropertyName] = Value
		end
	end
	if char.Humanoid.WalkSpeed > self.PlayerDatas[player.UserId].WalkSpeed then
		char.Humanoid.WalkSpeed = self.PlayerDatas[player.UserId].WalkSpeed
	end
end

function PlayerService:LoadPlayersData(player)
	self.DataService
		:GetPlayersData(player)
		:andThen(function(comingData)
			self.Client.SendPlayerData:Fire(player, comingData)
			local StatsPoints = self:SetKickStats(comingData)
			local UpdatingDataTable = {
				KickStyle = comingData.EquippedKickStyle,
				Aura = comingData.EquippedAura,
				MaxPower = 100,
				Health = StatsPoints.MaximumHealth,
				MaximumHealth = StatsPoints.MaximumHealth,
				Rage = 0,
				Ragdoll = 0,
				MaximumRage = StatsPoints.MaximumRage,
				Stamina = StatsPoints.MaximumStamina,
				MaximumStamina = StatsPoints.MaximumStamina,
				Coin = comingData.Currencies.Coin,
				Emerald = comingData.Currencies.Emerald,
				WalkSpeed = 25,
				OverHealth = 0,
				KickPassive = 0,
				AuraPassive = 0,
				Debuffes = {},
				FusionPassive = false,
				Knocked = false,
				RageActive = false,
			}
			self:UpdatePlayerData(player, UpdatingDataTable)
		end)
		:catch(function(err)
			print(err, "Basarili deildostum")
		end)
end

function PlayerService:SetPlayerDependicies(char)
	if not char.HumanoidRootPart:FindFirstChild("KnockBackAttachment") then
		local KBAttachment = Instance.new("Attachment")
		KBAttachment.Name = "KnockBackAttachment"
		KBAttachment.Parent = char.HumanoidRootPart
	end
	if not char.HumanoidRootPart:FindFirstChild("Helper") then
		local Helper = ReplicatedStorage.Shared.Assets.VFX.Beams:FindFirstChild("HelperAsist").Helper:Clone()
		Helper.Parent = char.HumanoidRootPart
	end

	if not char.HumanoidRootPart:FindFirstChild("AURAHIGHLIGHT") then
		local AuraHighlight = Instance.new("Highlight")
		AuraHighlight.Name = "AURAHIGHLIGHT"
		AuraHighlight.Parent = char
		AuraHighlight.Enabled = true
	end
	char.Humanoid.WalkSpeed = 25
end

function PlayerService:SetCollisionGroup(character: Model)
	workspace:FindFirstChild("Baseplate").CollisionGroup = "World"
	for _, allparts in character:GetDescendants() do
		if allparts:IsA("BasePart") then
			allparts.CollisionGroup = "Players"
		end
	end
end

function PlayerService:KnitInit()
	self.RagdollService = Knit.GetService("RagdollService")
	self.DataService = Knit.GetService("DataService")
	self.StatusService = Knit.GetService("StatusService")
	self.EffectService = Knit.GetService("EffectService")
end

function PlayerService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			self.RagdollService:BuildCollideParts(player)
			self:SetCollisionGroup(character)
			self:SetPlayerDependicies(character)
		end)
		self.DataService:LoadPlayersData(player)
		self:LoadPlayersData(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:ClearPlayerDatas(player)
	end)
end

return PlayerService
