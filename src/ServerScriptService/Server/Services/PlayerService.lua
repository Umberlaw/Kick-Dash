local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.knit)

local KickStlyeDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)
local HiglightDatas = require(ReplicatedStorage.Shared.configs.AuraHiglights)
local FontDatas = require(ReplicatedStorage.Shared.configs.FontsConfig)

--local Promise = require(Knit.Util.Promise)

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	Client = { SendPlayerData = Knit.CreateSignal() },
	PlayerDatas = {},
	PlayerCons = {},
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
end

function PlayerService:UpdatePlayerData(player, comingData: table)
	local DataSet = {
		KickStyle = "",
		Aura = "",
		MaxPower = 0,
		Health = 0,
		MaximumHealth = 0,
		OverHealth = 0,
		Stamina = 0,
		MaximumStamina = 100,
		Rage = 0,
		MaximumRage = 0,
		WalkSpeed = 25,
		Ragdoll = 0,
		Coin = 0,
		Emerald = 0,
		StylePassive = 0,
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
	local DisplayName = char:FindFirstChild("DisplayName")

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

	if comingData.Aura or comingData.KickStyle then
		DisplayName.Kick.Text = self.PlayerDatas[player.UserId].Aura
			.. " "
			.. KickStlyeDatas.Kicks[self.PlayerDatas[player.UserId].KickStyle].Cosmetic.DisplayName
		DisplayName:FindFirstChild("Name").Text = player.Name
		DisplayName.Kick.FontFace =
			FontDatas[KickStlyeDatas.Kicks[self.PlayerDatas[player.UserId].KickStyle].Cosmetic.Font]
		DisplayName.Kick:ClearAllChildren()
		local targetGradientFolder =
			ReplicatedStorage.Shared.Assets.Gradients.DisplayName:FindFirstChild(self.PlayerDatas[player.UserId].Aura)
		for _, allDecorations in targetGradientFolder:GetChildren() do
			local clonneddecor = allDecorations:Clone()
			clonneddecor.Parent = DisplayName.Kick
		end
	end
	print(self.PlayerDatas[player.UserId])
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
				StylePassive = 0,
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

	if not char:FindFirstChild("DisplayName") then
		local DisplayNameClone = ReplicatedStorage.Shared.Assets.Indicators:FindFirstChild("DisplayName"):Clone()
		DisplayNameClone.Parent = char
		DisplayNameClone.Adornee = char:FindFirstChild("Head")
		DisplayNameClone.Kick.Text = "ONLYFIFTEENCHARACTER"
		DisplayNameClone:FindFirstChild("Name").Text = "PLAYERNAME"
	end

	char.Humanoid.WalkSpeed = 25

	if not char:FindFirstChild("SymbolIndicators") then
		local SymbolIndicators = Instance.new("Folder")
		SymbolIndicators.Name = "SymbolIndicators"
		SymbolIndicators.Parent = char
	end

	if not char:FindFirstChild("DebuffIndicators") then
		local DebuffIndicators = Instance.new("Folder")
		DebuffIndicators.Name = "DebuffIndicators"
		DebuffIndicators.Parent = char
	end
end

function PlayerService:SetCollisionGroup(character: Model)
	workspace:FindFirstChild("Baseplate").CollisionGroup = "World"
	for _, allparts in character:GetDescendants() do
		if allparts:IsA("BasePart") then
			allparts.CollisionGroup = "Players"
		end
	end
end

function PlayerService:PlayerConnections(player)
	local char = player.Character
	local counter = 1
	if not self.PlayerCons[player.UserId] then
		self.PlayerCons[player.UserId] = {}
	end
	self.PlayerCons[player.UserId]["Stamina"] = task.spawn(function()
		while task.wait(1) do
			local playersTargetData = self.PlayerDatas[player.UserId]
			if not playersTargetData then
				warn("Data yok")
				return
			end
			if math.floor(char.Humanoid.MoveDirection.Magnitude) > 0 then
				if counter > 0 then
					counter = -1
				end
				local decreasingStamina =
					math.clamp(playersTargetData.Stamina + counter, 0, playersTargetData.MaximumStamina)
				counter = math.clamp(counter - 1, -10, 1)
				if decreasingStamina ~= playersTargetData.Stamina then
					self:UpdatePlayerData(player, { Stamina = decreasingStamina })
				end
			elseif math.floor(char.Humanoid.MoveDirection.Magnitude) <= 0 then
				if counter < 0 then
					counter = 1
				end
				local decreasingStamina =
					math.clamp(playersTargetData.Stamina + counter, 0, playersTargetData.MaximumStamina)

				counter = math.clamp(counter + 1, 1, 10)
				if decreasingStamina ~= playersTargetData.Stamina then
					self:UpdatePlayerData(player, { Stamina = decreasingStamina })
				end
			end
		end
	end)
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
		self:PlayerConnections(player)
		task.delay(5, function()
			self:UpdatePlayerData(player, { KickStyle = "Twister", Aura = "Void" })
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:ClearPlayerDatas(player)
	end)
end

return PlayerService
