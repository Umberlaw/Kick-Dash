local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local InterfaceTweens = require(ReplicatedStorage.Shared.configs.InterfaceTweens)

local EffectService = Knit.CreateService({
	Name = "EffectService",
	Client = {},
	PlayerIndicators = {},
	PlayerDebuffes = {},
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

function EffectService:KnitInit()
	self.PlayerService = Knit.GetService("PlayerService")
end

function EffectService:KnitStart() end

return EffectService
