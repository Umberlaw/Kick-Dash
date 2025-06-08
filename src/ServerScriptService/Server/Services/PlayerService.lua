local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lobby = workspace:WaitForChild("Lobby")

local Knit = require(ReplicatedStorage.Packages.knit)
local Zoneplus = require(ReplicatedStorage.Packages.zoneplus)

local KickStlyeDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)
local HiglightDatas = require(ReplicatedStorage.Shared.configs.AuraHiglights)
local FontDatas = require(ReplicatedStorage.Shared.configs.FontsConfig)

local Promise = require(Knit.Util.Promise)

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	Client = {
		SendPlayerData = Knit.CreateSignal(),
		HealthUpdate = Knit.CreateSignal(),
		StaminaUpdate = Knit.CreateSignal(),
	},
	PlayerDatas = {},
	PlayerCons = {},
})

---General Player Events---------
function PlayerService:Knocked(knockedPlayer)
	local knockDatas = { Knocked = true, WalkSpeed = 0, Ragdoll = 0 }
	self:UpdatePlayerData(knockedPlayer, knockDatas)
	local KnockedPlayerData = self.PlayerDatas[knockedPlayer.UserId]

	if not KnockedPlayerData then
		warn("Datasi yok bunun")
		return
	end

	local function KnockedAnimation()
		Promise.new(function(resolve, reject)
			local KnockDownAnimAsset = ReplicatedStorage.Shared.Assets.Animations.Commons.KnockDown
			local KnockUpAnimAsset = ReplicatedStorage.Shared.Assets.Animations.Commons.KnockUp
			local RollingAnimAsset = ReplicatedStorage.Shared.Assets.Animations.Commons.Rolling
			if not KnockedPlayerData.PlayerAnims["KnockDown"] then
				local Animations = {
					KnockDown = knockedPlayer.Character.Humanoid.Animator:LoadAnimation(KnockDownAnimAsset),
					KnockUp = knockedPlayer.Character.Humanoid.Animator:LoadAnimation(KnockUpAnimAsset),
					Rolling = knockedPlayer.Character.Humanoid.Animator:LoadAnimation(RollingAnimAsset),
				}
				self:UpdatePlayerData(knockedPlayer, { PlayerAnims = Animations })

				KnockedPlayerData.PlayerAnims["KnockDown"]:GetMarkerReachedSignal("Rolling"):Connect(function()
					KnockedPlayerData.PlayerAnims["Rolling"]:Play()
					KnockedPlayerData.PlayerAnims["Rolling"].Looped = true
					task.delay(4, function() -- task delay yerine Wish olayi gelecek
						KnockedPlayerData.PlayerAnims["Rolling"]:Stop()
						KnockedPlayerData.PlayerAnims["KnockUp"]:Play()
						print("Tamam tekrar oynatti iste ")
					end)
				end)
				KnockedPlayerData.PlayerAnims["KnockUp"]:GetMarkerReachedSignal("End"):Connect(function()
					self:Respawn(knockedPlayer)
				end)
			end
			KnockedPlayerData.PlayerAnims["KnockDown"]:Play()
			if not KnockedPlayerData then
				reject("Datan yok birader")
			end
		end):catch(function(err)
			print(err)
		end)
	end

	----ANIMATION AREA
	KnockedAnimation()
end

function PlayerService:Respawn(RespawningPlayer)
	local playerData = self.PlayerDatas[RespawningPlayer.UserId]
	for debufNames, _ in playerData.Debuffes do
		self.StatusService:RemoveStatus(RespawningPlayer, debufNames)
	end
	RespawningPlayer.Character.HumanoidRootPart:PivotTo(
		Lobby:FindFirstChild("Points"):FindFirstChild("SafezoneTeleport").CFrame
	)
	self:UpdatePlayerData(RespawningPlayer, {
		Health = playerData.MaximumHealth,
		Debuffes = {},
		Stamina = playerData.MaximumStamina,
		AuraPassive = 0,
		StylePassive = 0,
		FusionPassive = false,
		Ragdoll = 0,
		WalkSpeed = 25,
		Knocked = false,
		RageActive = false,
		OverHealth = 0,
	})
	self.PassiveService:AddPassivePoint(RespawningPlayer, "Aura", 0)
	self.PassiveService:AddPassivePoint(RespawningPlayer, "Style", 0)
end
---------------------------

---------------Player Data Areas-------------------------------

function PlayerService:PlayerEnteredSafeZone(player)
	local targetPlayerData = self.PlayerDatas[player.UserId] or nil
	if not targetPlayerData then
		warn("Datasi yok bunun")
		return
	end

	for debuffName in targetPlayerData.Debuffes do
		self:RemoveDebuff(player, debuffName)
	end
	self:UpdatePlayerData(player, { InSafeZone = true, WalkSpeed = 35 })
end

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
		FusionPassive = false,
		Knocked = false,
		RageActive = false,
		InSafeZone = false,
		Debuffes = {},
		PlayerAnims = {},
	}
	print(player, "Ilginc")
	if not self.PlayerDatas[player.UserId] then
		self.PlayerDatas[player.UserId] = DataSet
	end

	for keys, changindatas in comingData do
		if self.PlayerDatas[player.UserId][keys] ~= nil then
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
------------------------------------------------

---------------Player Visual Areas---------------------------------

----------------------------------------------------

----PLAYER STARTING EVENTS--------------------------
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
		DisplayNameClone.AlwaysOnTop = false
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
			if math.floor(char.Humanoid.MoveDirection.Magnitude) > 0 and not playersTargetData.InSafeZone then
				if counter > 0 then
					counter = -1
				end
				local decreasingStamina =
					math.clamp(playersTargetData.Stamina + counter, 0, playersTargetData.MaximumStamina)
				counter = math.clamp(counter - 1, -10, 1)
				if decreasingStamina ~= playersTargetData.Stamina then
					self:UpdatePlayerData(player, { Stamina = decreasingStamina })
				end
			elseif math.floor(char.Humanoid.MoveDirection.Magnitude) <= 0 or playersTargetData.InSafeZone then
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
	self.PlayerCons[player.UserId]["WalkSpeed"] = task.spawn(function()
		while task.wait(0.3) do
			local targetPlayerData = self.PlayerDatas[player.UserId]
			local char = player.Character
			if not targetPlayerData then
				warn("Data yok")
				return
			end
			if targetPlayerData.Stamina <= 0 then
				if targetPlayerData.WalkSpeed > 16 then
					self:UpdatePlayerData(player, { WalkSpeed = 16 })
				end
			elseif targetPlayerData.Stamina > 0 then
				if targetPlayerData.WalkSpeed == 16 then
					self:UpdatePlayerData(player, { WalkSpeed = 22 })
				end
			end
			char.Humanoid.WalkSpeed = targetPlayerData.WalkSpeed
		end
	end)
end

function PlayerService:SetZones()
	local SafeZoneConteyner = Lobby:WaitForChild("Zones"):FindFirstChild("SafeZone")
	local safeZone = Zoneplus.new(SafeZoneConteyner)

	safeZone.playerEntered:Connect(function(player)
		self:PlayerEnteredSafeZone(player)
	end)

	safeZone.playerExited:Connect(function(player)
		self:UpdatePlayerData(player, { InSafeZone = false, WalkSpeed = 25 })
	end)

	local TeleporterInSafeZoneConteyner = Lobby:WaitForChild("Zones"):FindFirstChild("SafeZoneTeleporter")

	local TeleporterInSafeZone = Zoneplus.new(TeleporterInSafeZoneConteyner)

	TeleporterInSafeZone.playerEntered:Connect(function(player)
		player.Character.HumanoidRootPart:PivotTo(
			Lobby:WaitForChild("Points"):FindFirstChild("GameAreaTeleport").CFrame
		)
	end)

	local TeleporterInGameAreaConteyner = Lobby:WaitForChild("Zones"):FindFirstChild("InGameTeleporter")
	local TeleporterInGameArea = Zoneplus.new(TeleporterInGameAreaConteyner)

	TeleporterInGameArea.playerEntered:Connect(function(player)
		player.Character.HumanoidRootPart:PivotTo(
			Lobby:WaitForChild("Points"):FindFirstChild("SafezoneTeleport").CFrame
		)
	end)
end

--------------------------------------------------------

function PlayerService:KnitInit()
	self.RagdollService = Knit.GetService("RagdollService")
	self.DataService = Knit.GetService("DataService")
	self.StatusService = Knit.GetService("StatusService")
	self.EffectService = Knit.GetService("EffectService")
	self.PassiveService = Knit.GetService("PassiveService")
end

function PlayerService:KnitStart()
	print("PlayerServiceStarted")
	self:SetZones()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			self.RagdollService:BuildCollideParts(player)
			self:SetCollisionGroup(character)
			self:SetPlayerDependicies(character)
		end)
		self.DataService:LoadPlayersData(player)
		self:LoadPlayersData(player)
		self:PlayerConnections(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:ClearPlayerDatas(player)
	end)
end

return PlayerService
