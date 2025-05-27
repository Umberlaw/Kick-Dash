local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local EffectService = Knit.CreateService({
	Name = "EffectService",
	Client = {},
	PlayerIndicators = {},
})

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
	local PlayerTargetIndicator = if self.PlayerIndicators[Player.UserId]
			and self.PlayerIndicators[Player.UserId][PassiveType]
		then self.PlayerIndicators[Player.UserId][PassiveType]
		else nil
	if not PlayerTargetIndicator then
		warn("Indicator Yokmus Reelde")
		return
	end
	PlayerTargetIndicator:Destroy()
	self.PlayerIndicators[Player.UserId][PassiveType] = nil
end

function EffectService:CreateSymbols(player, PassiveType)
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
				elseif PassiveType == "Style" then TargetFolder:FindFirstChild(PlayerTargetData.KickStyle):Clone()
				else nil
			if not ClonningAsset then
				reject("ClonningAsset  Bulunamadi")
			else
				self.PlayerIndicators[player.UserId][PassiveType] = ClonningAsset
				ClonningAsset.Parent = player.Character.SymbolIndicators
				ClonningAsset.Adornee = player.Character.Head
				ClonningAsset.StudsOffset = Vector3.new(-0.5, 0, 0)
				resolve(ClonningAsset)
			end
		else
			reject("Target Data Didnt Found")
		end
	end):catch(function(err)
		print(err)
	end)
end

function EffectService:KnitInit()
	self.PlayerService = Knit.GetService("PlayerService")
end

function EffectService:KnitStart() end

return EffectService
