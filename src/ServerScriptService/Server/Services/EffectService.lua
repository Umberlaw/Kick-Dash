local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local InterfaceTweens = require(ReplicatedStorage.Shared.configs.InterfaceTweens)

local EffectService = Knit.CreateService({
	Name = "EffectService",
	Client = { SetAtmosphere = Knit.CreateSignal(), CreateEffect = Knit.CreateSignal() },
	PlayerIndicators = {},
	PlayerDebuffes = {},
	PlayerEffects = {},
})

function EffectService:RemoveDebuffIndicator(player, IndicatorName)
	local targetRemoveIndicatorData = self.PlayerDebuffes[player.UserId][IndicatorName] or nil
	if targetRemoveIndicatorData then
		if targetRemoveIndicatorData.BillboardTask then
			task.cancel(targetRemoveIndicatorData.BillboardTask)
			targetRemoveIndicatorData.BillboardTask = nil
		end
		if targetRemoveIndicatorData.Billboard then
			local diseappearSizeAnim, diseappearBrightnessAnim =
				InterfaceTweens:DebuffDisappear(targetRemoveIndicatorData.Billboard)
			diseappearSizeAnim.Phase2:Play()
			diseappearBrightnessAnim.Phase1:Play()
			diseappearSizeAnim.Phase2.Completed:Once(function(playbackState)
				diseappearSizeAnim.Phase3:Play()
				diseappearBrightnessAnim.Phase2:Play()
			end)
			diseappearSizeAnim.Phase3.Completed:Once(function(playbackState)
				targetRemoveIndicatorData.Billboard:Destroy()
				self.PlayerDebuffes[player.UserId][IndicatorName] = nil
			end)
		end
	end
end

--Indicator Type  can be like  Decreasing,Counter,Permanent
function EffectService:CreateDebuffIndicator(player, IndicatorName, IndicatorType, DebuffName)
	local function DecreasingTaskType(Indicator)
		local TextArea = Indicator.Count
		local decreasingtask = task.spawn(function()
			while true do
				task.wait(1)
				local currentData = self.PlayerService.PlayerDatas[player.UserId] or nil
				local DecreaseAnimations = if InterfaceTweens[IndicatorName .. "Decreasing"]
					then InterfaceTweens[IndicatorName .. "Decreasing"](self, TextArea)
					else InterfaceTweens:TextDecrease(TextArea)
				DecreaseAnimations[1]:Play()
				DecreaseAnimations[2]:Play()
				DecreaseAnimations[2].Completed:Once(function()
					print(currentData.Debuffes)
					TextArea.Text = if currentData.Debuffes[DebuffName]
						then currentData.Debuffes[DebuffName].RemainingTime
						else "-"
					DecreaseAnimations[3]:Play()
					DecreaseAnimations[4]:Play()
				end)
				DecreaseAnimations[4].Completed:Once(function()
					DecreaseAnimations[5]:Play()
				end)
				if not currentData then
					warn("DATAyOK BIRADER bu debuff icin")
					break
				end
			end
		end)
		return decreasingtask
	end

	if not self.PlayerDebuffes[player.UserId] then
		self.PlayerDebuffes[player.UserId] = {}
	end

	if not self.PlayerDebuffes[player.UserId][DebuffName] then
		local targetPlayersData = self.PlayerService.PlayerDatas[player.UserId] or nil
		if not targetPlayersData then
			warn("DATA KAYIP LA")
			return
		end
		self.PlayerDebuffes[player.UserId][DebuffName] = {}
		local TargetDebuffIndicator =
			ReplicatedStorage.Shared.Assets.Indicators.Debuffes:FindFirstChild(IndicatorName):Clone()
		TargetDebuffIndicator.Brightness = 0
		TargetDebuffIndicator.Size = UDim2.new(6, 0, 3, 0)
		local DebuffSizeTweens, DebufBrightnesTweens = InterfaceTweens:DebuffAppear(TargetDebuffIndicator)
		DebuffSizeTweens.Phase1:Play()
		DebufBrightnesTweens.Phase2:Play()
		DebuffSizeTweens.Phase1.Completed:Once(function(playbackState)
			DebuffSizeTweens.Phase2:Play()
			DebufBrightnesTweens.Phase2:Play()
		end)
		TargetDebuffIndicator.Parent = player.Character.DebuffIndicators
		TargetDebuffIndicator.StudsOffset = Vector3.new(0, 0.75, 0)
			+ Vector3.new(0, ((#player.Character.DebuffIndicators:GetChildren() - 1) * 1.25), 0)
		TargetDebuffIndicator.Adornee = player.Character.Head
		self.PlayerDebuffes[player.UserId][DebuffName]["Billboard"] = TargetDebuffIndicator
		self.PlayerDebuffes[player.UserId][DebuffName]["BillboardTask"] = DecreasingTaskType(TargetDebuffIndicator)
	end
end

function EffectService:Clear(player, comingData)
	print(player, "Efektlerini temizledik")
	if self.PlayerIndicators and self.PlayerIndicators[player.UserId] then
		for indicatorKey, allIndicators in self.PlayerIndicators[player.UserId] do
			allIndicators:Destroy()
			self.PlayerIndicators[indicatorKey] = nil
		end
	end
	for debuffName, allDebuffes in comingData.Debuffes do
		if self.PlayerDebuffes[player.UserId][debuffName] then
			task.cancel(self.PlayerDebuffes[player.UserId][debuffName]["BillboardTask"])
			self.PlayerDebuffes[player.UserId][debuffName]["BillboardTask"] = nil
			self.PlayerDebuffes[player.UserId][debuffName]["Billboard"]:Destroy()
			self.PlayerDebuffes[player.UserId][debuffName]["Billboard"] = nil
			self.PlayerDebuffes[player.UserId][debuffName] = nil
		end
	end
end

function EffectService:SetIndicator(Player, PassiveType)
	local PlayerTargetIndicator = if self.PlayerIndicators[Player.UserId]
			and self.PlayerIndicators[Player.UserId][PassiveType]
		then self.PlayerIndicators[Player.UserId][PassiveType]
		else nil
	if not PlayerTargetIndicator then
		warn("Indicator Yokmus Reelde")
		return
	end

	PlayerTargetIndicator.StudsOffset = PlayerTargetIndicator.StudsOffset
		+ Vector3.new(#PlayerTargetIndicator.Parent:GetChildren() - 1, 0, 0)
end

function EffectService:RemoveIndicator(Player, PassiveType)
	Promise.new(function(resolve, reject)
		local PlayerTargetIndicator = if self.PlayerIndicators[Player.UserId]
				and self.PlayerIndicators[Player.UserId][PassiveType]
			then self.PlayerIndicators[Player.UserId][PassiveType]
			else nil
		if not PlayerTargetIndicator then
			reject("Player didnt have anythinm")
		end
		local SizeTweens, BrightnesTweens = InterfaceTweens:SymbolDiseappear(PlayerTargetIndicator)
		task.spawn(function()
			BrightnesTweens.Phase1:Play()
			task.delay(0.5, function()
				SizeTweens.Phase2:Play()
				BrightnesTweens.Phase2:Play()
				task.delay(0.35, function()
					SizeTweens.Phase3:Play()
				end)
			end)
		end)
		SizeTweens.Phase3.Completed:Once(function()
			resolve(PlayerTargetIndicator)
		end)
	end)
		:andThen(function(result)
			result:Destroy()
			self.PlayerIndicators[Player.UserId][PassiveType] = nil
		end)
		:catch(function(err)
			warn(err)
		end)
end

function EffectService:CreateSymbols(player, PassiveType)
	task.delay(0.15, function()
		Promise.new(function(resolve, reject)
			if not self.PlayerIndicators[player.UserId] then
				self.PlayerIndicators[player.UserId] = {}
			end
			local TargetFolder = if PassiveType == "Aura"
				then ReplicatedStorage.Shared.Assets.Indicators.AuraSymbols
				elseif PassiveType == "Style" then ReplicatedStorage.Shared.Assets.Indicators.KickSymbols
				else nil

			local PlayerTargetData = self.PlayerService.PlayerDatas[player.UserId] or nil
			if PlayerTargetData then
				local ClonningAsset = if PassiveType == "Aura"
					then TargetFolder:FindFirstChild(PlayerTargetData.Aura):Clone()
					elseif PassiveType == "Style" then TargetFolder:FindFirstChild(PlayerTargetData.KickStyle)
						:Clone()
					else nil
				if not ClonningAsset then
					reject("ClonningAsset  Bulunamadi")
				else
					self.PlayerIndicators[player.UserId][PassiveType] = ClonningAsset
					ClonningAsset.Size = UDim2.new(0, 0, 0, 0)
					ClonningAsset.Brightness = 0
					local SizeTweens, BrightnesTweens = InterfaceTweens:SymbolAppearence(ClonningAsset)

					ClonningAsset.Parent = player.Character.SymbolIndicators
					ClonningAsset.Adornee = player.Character.Head
					ClonningAsset.StudsOffset = Vector3.new(0, 0, 2)
					task.spawn(function()
						ClonningAsset.Size = UDim2.fromScale(6, 3)
						SizeTweens.Phase1:Play()
						BrightnesTweens.Phase1:Play()
						task.delay(0.3, function()
							SizeTweens.Phase2:Play()
							BrightnesTweens.Phase2:Play()
						end)
					end)
					BrightnesTweens.Phase2.Completed:Once(function()
						ClonningAsset.Brightness = 1
					end)
					SizeTweens.Phase2.Completed:Once(function()
						resolve(ClonningAsset)
					end)
				end
			else
				reject("Target Data Didnt Found")
			end
		end):catch(function(err)
			print(err)
		end)
	end)
end

function EffectService:SetAtmosphere(player, AtmosphereName)
	local targetAtmosphere = ReplicatedStorage.Shared.Assets.VFX.Atmospheres:FindFirstChild(AtmosphereName)
	if targetAtmosphere then
		self.Client.SetAtmosphere:Fire(player, targetAtmosphere, AtmosphereName)
	end
end

function EffectService:CreateEffect(player, targetEffect: table, targetDatas: table)
	--[[targetEffect = {AuraName = string,EffectName = string}]]
	local targetingPart
	if targetDatas.SpecialStatue and targetDatas.SpecialStatue == "PartCreate" then
		targetingPart = Instance.new("Part")
		targetingPart.Size = targetDatas.PartSize or Vector3.new(4, 1, 2)
		targetingPart.Position = targetDatas.PartPosition or player.Character["Right Leg"].Position
		targetingPart.CanCollide = false
		targetingPart.Anchored = true
		targetingPart.Transparency = 1
		targetingPart.Parent = workspace:FindFirstChild("Particles")
		targetingPart.Name = tostring(player.UserId) .. targetEffect.EffectName
	end
	local EffectAsset = ReplicatedStorage.Shared.Assets.VFX.Particles.AuraEffects
		:FindFirstChild(targetEffect.AuraName or "Simple")
		:FindFirstChild(targetEffect.EffectName or "Hit")
	local ClonnedEffect = if EffectAsset then EffectAsset:Clone() else nil
	ClonnedEffect.CFrame = CFrame.new(0, 0, 0)
	if not ClonnedEffect then
		warn("EFFECT YOK")
		return
	end
	if not targetEffect then
		warn("EFFECT BOS DONDU BABNA")
		return
	end
	if targetEffect.EffectName == "Dash" then
		if ClonnedEffect:GetAttribute("EnableTime") then
			ClonnedEffect:SetAttribute(
				"EnableTime",
				ClonnedEffect:GetAttribute("EnableTime") * targetDatas.EnabledTime * 10
			)
			print(targetDatas.EnabledTime)
			print(ClonnedEffect:GetAttribute("EnableTime"), targetDatas.EnabledTime)
			print(ClonnedEffect:GetAttribute("EnableTime") * targetDatas.EnabledTime)
		end
		if ClonnedEffect:GetAttribute("DisableTime") then
			ClonnedEffect:SetAttribute(
				"DisableTime",
				ClonnedEffect:GetAttribute("DisableTime") * targetDatas.DiseabledTime * 20
			)
		end
	end
	print(ClonnedEffect:GetAttribute("DisableTime"), ClonnedEffect:GetAttribute("EnableTime"))
	if not self.PlayerEffects[player.UserId] then
		self.PlayerEffects[player.UserId] = {}
	end
	ClonnedEffect.Parent = if targetDatas.SpecialStatue == "PartCreate"
		then workspace:FindFirstChild("Particles"):FindFirstChild(tostring(player.UserId) .. targetEffect.EffectName)
		elseif targetDatas.Target then targetDatas.Target
		else player.Character.HumanoidRootPart
	self.PlayerEffects[player.UserId][ClonnedEffect] = ClonnedEffect
	print("Createlendi")
	if ClonnedEffect:IsA("Attachment") then
		for _, allTargetParticles in self.PlayerEffects[player.UserId][ClonnedEffect]:GetChildren() do
			print(allTargetParticles.Enabled)
			allTargetParticles.Enabled = true
			print(allTargetParticles.Enabled)
		end
	elseif ClonnedEffect:IsA("ParticleEmitter") then
		ClonnedEffect.Enabled = true
	end
	task.delay(ClonnedEffect:GetAttribute("EnableTime") or targetDatas.EnabledTime or 1, function()
		self:ClearEffect(player, ClonnedEffect, targetDatas, targetingPart)
	end)
end

function EffectService:ClearEffect(player, targetEffect, targetDatas, targetingpart)
	if targetEffect:IsA("Attachment") then
		for _, allTargetParticles in self.PlayerEffects[player.UserId][targetEffect]:GetChildren() do
			allTargetParticles.Enabled = false
		end
		task.delay(targetEffect:GetAttribute("DisableTime") or targetDatas.DiseabledTime or 1, function()
			print(self.PlayerEffects[player.UserId], self.PlayerEffects[player.UserId][targetEffect])
			if self.PlayerEffects[player.UserId][targetEffect] then
				self.PlayerEffects[player.UserId][targetEffect]:Destroy()
				self.PlayerEffects[player.UserId][targetEffect] = nil
			end
			if targetDatas.SpecialStatue and targetDatas.SpecialStatue == "PartCreate" and targetingpart then
				targetingpart:Destroy()
			end
		end)
	elseif targetEffect:IsA("ParticleEmitter") then
		targetEffect.Enabled = false
		task.delay(targetEffect:GetAttribute("DisableTime") or targetDatas.DiseabledTime or 1, function()
			print(self.PlayerEffects[player.UserId], self.PlayerEffects[player.UserId][targetEffect])
			if self.PlayerEffects[player.UserId][targetEffect] then
				self.PlayerEffects[player.UserId][targetEffect]:Destroy()
				self.PlayerEffects[player.UserId][targetEffect] = nil
			end
			if targetDatas.SpecialStatue and targetDatas.SpecialStatue == "PartCreate" and targetingpart then
				targetingpart:Destroy()
			end
		end)
	end
end

function EffectService:KnitInit()
	self.PlayerService = Knit.GetService("PlayerService")
end

function EffectService:KnitStart()
	self.Client.CreateEffect:Connect(function(player, targetEffect, TargetDatas)
		self:CreateEffect(player, targetEffect, TargetDatas)
	end)
end

return EffectService
