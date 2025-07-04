local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lobby = workspace:WaitForChild("Lobby")
local Terrain = workspace.Terrain

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
	self.EffectService:CreateEffect(knockedPlayer, {
		AuraName = KnockedPlayerData.Aura,
		EffectName = "Knockdown",
	}, { EnabledTime = 1, DiseabledTime = 1 })
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
					end)
				end)
				KnockedPlayerData.PlayerAnims["KnockUp"]:GetMarkerReachedSignal("End"):Connect(function()
					self:Respawn(knockedPlayer)
				end)
			end
			KnockedPlayerData.PlayerAnims["KnockDown"]:Play()
			self.SoundService:PlaySound(knockedPlayer, { SoundName = "Knockdown", PlayingArea = "Server" })
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
	local AuraPool = ReplicatedStorage.Shared.Assets.Indicators:FindFirstChild("AuraSymbols"):GetChildren()
	local StylePool = ReplicatedStorage.Shared.Assets.Indicators:FindFirstChild("KickSymbols"):GetChildren()
	for debufNames, _ in playerData.Debuffes do
		self.StatusService:RemoveStatus(RespawningPlayer, debufNames)
		self.EffectService:RemoveDebuffIndicator(RespawningPlayer, debufNames)
	end
	self.EffectService:RemoveIndicator(RespawningPlayer, "Aura")
	self.EffectService:RemoveIndicator(RespawningPlayer, "Style")
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
		KickStyle = StylePool[math.random(1, #StylePool)].Name,
		Aura = AuraPool[math.random(1, #AuraPool)].Name,
	})
	self.PassiveService:AddPassivePoint(RespawningPlayer, "Aura", 0)
	self.PassiveService:AddPassivePoint(RespawningPlayer, "Style", 0)
	self.EffectService:SetAtmosphere(RespawningPlayer, "Lobby")
end
---------------------------

---------------Player Data Areas-------------------------------

function PlayerService:PlayerEnteredSafeZone(player)
	self.EffectService:SetAtmosphere(player, "Lobby")
	local targetPlayerData = self.PlayerDatas[player.UserId] or nil
	if not targetPlayerData then
		warn("Datasi yok bunun")
		return
	end

	for debuffName in targetPlayerData.Debuffes do
		self:RemoveDebuff(player, debuffName)
	end
	self:UpdatePlayerData(player, { InSafeZone = true, WalkSpeed = 33 })
end

function PlayerService:ClearPlayerDatas(player)
	local TargetPlayerData = self.PlayerDatas[player.UserId]

	if not TargetPlayerData then
		warn("Player didnd have any data whole game WOAAA")
	end

	for _, taskes in self.PlayerCons[player.UserId] do
		task.cancel(taskes)
		taskes = nil
	end

	self.DataService:SavePlayersData(player, TargetPlayerData)
	self.PlayerDatas[player.UserId] = nil

	for _, Services in Knit:GetServices() do
		if Services["Clear"] then
			Services["Clear"](self, player, TargetPlayerData)
		end
	end
end

function PlayerService:SetKickStats(comingData)
	local HealthPoint = (
		KickStlyeDatas.Kicks[comingData.EquippedKickStyle].Stats.HealthPoint
		+ KickStlyeDatas.Auras[comingData.EquippedAura].Stats.HealthPoint
	) * 50
	local StaminaPoint = (
		KickStlyeDatas.Kicks[comingData.EquippedKickStyle].Stats.StaminaPoint
		+ KickStlyeDatas.Auras[comingData.EquippedAura].Stats.StaminaPoint
	) * 40
	local RagePoint = (
		KickStlyeDatas.Kicks[comingData.EquippedKickStyle].Stats.RagePoint
		+ KickStlyeDatas.Auras[comingData.EquippedAura].Stats.RagePoint
	) * 30

	return { MaximumHealth = HealthPoint, MaximumStamina = StaminaPoint, MaximumRage = RagePoint }
end

function PlayerService:RemoveDebuff(player, DebuffName)
	if self.PlayerDatas[player.UserId].Debuffes[DebuffName] then
		if self.PlayerDatas[player.UserId].Debuffes[DebuffName] then
			self.EffectService:RemoveDebuffIndicator(player, DebuffName)
		end
		self.PlayerDatas[player.UserId].Debuffes[DebuffName] = nil
	end
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
	if not self.PlayerDatas[player.UserId] then
		self.PlayerDatas[player.UserId] = DataSet
	end

	for keys, changindatas in comingData do
		if self.PlayerDatas[player.UserId][keys] ~= nil then
			self.PlayerDatas[player.UserId][keys] = changindatas
		end
	end
	self.Client.SendPlayerData:Fire(player, self.PlayerDatas[player.UserId])
	local char = player.Character or player.CharacterAdded:Wait()
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
		if not comingData.Aura then
			comingData.Aura = self.PlayerDatas[player.UserId].Aura
		end
		if not comingData.KickStyle then
			comingData.KickStyle = self.PlayerDatas[player.UserId].KickStyle
		end
		DisplayName.Kick.Text = self.PlayerDatas[player.UserId].Aura
			.. " "
			.. KickStlyeDatas.Kicks[self.PlayerDatas[player.UserId].KickStyle].Cosmetic.DisplayName
		DisplayName:FindFirstChild("Name").Text = player.Name
		DisplayName.Kick.FontFace =
			FontDatas[KickStlyeDatas.Kicks[self.PlayerDatas[player.UserId].KickStyle].Cosmetic.Font]
		DisplayName.Kick:ClearAllChildren()
		local AuraSoundsFolder = ReplicatedStorage.Shared.Assets.SFX.Auras:FindFirstChild(comingData.Aura)
		local KickSoundsFolder = ReplicatedStorage.Shared.Assets.SFX.KickStyles:FindFirstChild(comingData.KickStyle)
		if AuraSoundsFolder then
			for _, AuraSounds in AuraSoundsFolder:GetChildren() do
				self.SoundService:CreateSound(player, { SoundObject = AuraSounds, SoundName = AuraSounds.Name })
			end
		end
		if KickSoundsFolder then
			for _, KickSounds in KickSoundsFolder:GetChildren() do
				local RemainingName = KickSounds.Name:gsub("^" .. KickSoundsFolder.Name, "")
				self.SoundService:CreateSound(
					player,
					{ SoundObject = KickSounds, SoundName = "KickStyle" .. RemainingName }
				)
			end
		end
		local targetGradientFolder =
			ReplicatedStorage.Shared.Assets.Gradients.DisplayName:FindFirstChild(self.PlayerDatas[player.UserId].Aura)
		for _, allDecorations in targetGradientFolder:GetChildren() do
			local clonneddecor = allDecorations:Clone()
			clonneddecor.Parent = DisplayName.Kick
		end
	end
	if comingData.Health then
		self:UpdateHealthBar(player)
	end
end

function PlayerService:LoadPlayersData(player)
	self.DataService
		:GetPlayersData(player)
		:andThen(function(comingData)
			self.Client.SendPlayerData:Fire(player, comingData)
			self.EffectService:SetAtmosphere(player, "Lobby")
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
				InSafeZone = true,
			}
			self:UpdatePlayerData(player, UpdatingDataTable)
		end)
		:catch(function(err)
			print(err, "Basarili deildostum")
		end)
end

function PlayerService:LoadPlayersSounds(player)
	local CommonFolder = ReplicatedStorage.Shared.Assets.SFX.Common

	for _, allCommonSounds in CommonFolder:GetChildren() do
		self.SoundService:CreateSound(player, { SoundObject = allCommonSounds, SoundName = allCommonSounds.Name })
	end
end

------------------------------------------------

---------------Player Visual Areas---------------------------------
function PlayerService:UpdateHealthBar(player)
	local HPBar = player.Character:FindFirstChild("HPBar") or nil
	if not HPBar then
		warn("NOT HP BAR")
		return
	end
	local remainingPercent =
		math.clamp(1 - (self.PlayerDatas[player.UserId].Health / self.PlayerDatas[player.UserId].MaximumHealth), 0, 1)
	local UIGradient = HPBar.Health.HP.UIGradient
	UIGradient.Offset = Vector2.new(remainingPercent)
end
----------------------------------------------------

----PLAYER STARTING EVENTS--------------------------
function PlayerService:SetPlayerDependicies(char)
	local hum: Humanoid = char.Humanoid
	local hrp: BasePart = char.HumanoidRootPart

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
		DisplayNameClone.Kick.Text = "ONLYTWENTYCHARACTER"
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

	if not char.Head:FindFirstChild("Sounds") then
		local SoundsFolder = Instance.new("Folder")
		SoundsFolder.Parent = char.Head
		SoundsFolder.Name = "Sounds"
	end

	if not char:FindFirstChild("HPBar") then
		local HPBar: BillboardGui = ReplicatedStorage.Shared.Assets.Indicators:FindFirstChild("HP"):Clone()
		HPBar.Name = "HPBar"
		HPBar.Parent = char
		HPBar.Adornee = char.Head
		HPBar.PlayerToHideFrom = game.Players:GetPlayerFromCharacter(char)
		HPBar.Health.HP.UIGradient.Offset = Vector2.new(0, 0)
	end

	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	char.Parent = workspace:WaitForChild("PlayerCharacters")
end

function PlayerService:SetCollisionGroup(character: Model)
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
			--[[if math.floor(char.Humanoid.MoveDirection.Magnitude) > 0 and not playersTargetData.InSafeZone then
				if counter > 0 then
					counter = -1
				end
				local decreasingStamina = math.clamp(playersTargetData.Stamina - 1, 0, playersTargetData.MaximumStamina)
				if decreasingStamina ~= playersTargetData.Stamina then
					self:UpdatePlayerData(player, { Stamina = decreasingStamina })
				end]]
			if math.floor(char.Humanoid.MoveDirection.Magnitude) <= 0 or playersTargetData.InSafeZone then
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
					self:UpdatePlayerData(player, { WalkSpeed = 25 })
				end
			end
			char.Humanoid.WalkSpeed = targetPlayerData.WalkSpeed
		end
	end)
	self.PlayerCons[player.UserId]["AutoSave"] = task.spawn(function()
		while true do
			task.wait(5)
			local targetPlayersData = self.PlayerDatas[player.UserId]
			if targetPlayersData then
				self.DataService:UpdatePlayerProfile(player, targetPlayersData)
			end
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
		player.Character:PivotTo(Lobby:WaitForChild("Points"):FindFirstChild("GameAreaTeleport").CFrame)
		self.EffectService:SetAtmosphere(player, "Arena")
	end)

	local OutArenaZone = {}

	for _, meshparts in workspace:FindFirstChild("Waterhitbox"):GetChildren() do
		table.insert(OutArenaZone, meshparts)
	end
	local OutGameArea = Zoneplus.new(OutArenaZone)
	OutGameArea.playerEntered:Connect(function(player)
		local targetpart = workspace:FindFirstChild("ReturnPart")
		if targetpart then
			player.Character:PivotTo(targetpart.CFrame)
			self.AttackService:GiveDamage(player, math.floor(self.PlayerDatas[player.UserId].MaximumHealth / 5))
		end
	end)
end

function PlayerService:SetCharClone(player)
	if ReplicatedStorage.Shared.Assets.Models:FindFirstChild("CharacterClones"):FindFirstChild(player.Name) then
		ReplicatedStorage.Shared.Assets.Models:FindFirstChild("CharacterClones"):FindFirstChild(player.Name):Destroy()
	end
	local char = player.Character or nil
	if char then
		char.Archivable = true
		local clonnedChar = char:Clone()
		for _, allScriptsandGuis in clonnedChar:GetChildren() do
			if
				allScriptsandGuis:IsA("Script")
				or allScriptsandGuis:IsA("LocalScript")
				or allScriptsandGuis:IsA("ModuleScript")
				or allScriptsandGuis:IsA("BillboardGui")
			then
				allScriptsandGuis:Destroy()
			end
		end
		clonnedChar.Parent = ReplicatedStorage.Shared.Assets.Models:FindFirstChild("CharacterClones")
		clonnedChar.Name = player.Name
	end
end

function PlayerService:CommandPanel(player)
	player.Chatted:Connect(function(message)
		local Command = string.sub(message, 1, 2)
		if Command == "/K" then
			local argument = string.sub(message, 4)
			self.CommandService:UseCommand(player, "KickChange", argument)
		elseif Command == "/A" then
			local argument = string.sub(message, 4)
			self.CommandService:UseCommand(player, "AuraChange", argument)
		elseif Command == "/H" then
			local argument = string.sub(message, 4)
			self.CommandService:UseCommand(player, "Health", argument)
		elseif Command == "/B" then
			local argument = "Burned"
			self.CommandService:UseCommand(player, "AddBurned", argument)
		end
	end)
end

function PlayerService:Jump(comingplayer)
	return Promise.new(function(resolve, reject)
		if self.PlayerDatas[comingplayer.UserId] then
			if self.PlayerDatas[comingplayer.UserId].InSafeZone then
				resolve()
			else
				local leftingStamina =
					math.clamp(self.PlayerDatas[comingplayer.UserId].Stamina - (math.round((20 / 3))), -1, math.huge)
				if leftingStamina >= 0 then
					self:UpdatePlayerData(comingplayer, { Stamina = leftingStamina })
					resolve()
				else
					reject("Dont have enough stamina")
				end
			end
		else
			reject("PlayerDataDidntFindIt")
		end
	end)
end

function PlayerService.Client:JumpStamina(player)
	return self.Server:Jump(player):await()
end

--------------------------------------------------------

function PlayerService:KnitInit()
	self.RagdollService = Knit.GetService("RagdollService")
	self.DataService = Knit.GetService("DataService")
	self.StatusService = Knit.GetService("StatusService")
	self.EffectService = Knit.GetService("EffectService")
	self.PassiveService = Knit.GetService("PassiveService")
	self.SoundService = Knit.GetService("SoundService")
	self.CommandService = Knit.GetService("CommandService")
	self.AttackService = Knit.GetService("AttackService")
	self.PortalService = Knit.GetService("PortalService")
end

function PlayerService:KnitStart()
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
		self:SetCharClone(player)
		self:LoadPlayersSounds(player)
		self:CommandPanel(player)
		self.PortalService:CreatePortal(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:ClearPlayerDatas(player)
	end)
end

return PlayerService
