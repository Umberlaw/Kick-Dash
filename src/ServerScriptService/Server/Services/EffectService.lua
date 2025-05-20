local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local EffectService = Knit.CreateService({
	Name = "EffectService",
	Client = {},
	PlayerIndicators = {},
})

function EffectService:CreateSymbols(player, PassiveType)
	Promise.new(function(resolve, reject)
		if not self.PlayerIndicators[player.UserId] then
			self.PlayerIndicators[player.UserId] = {}
		end
		local TargetFolder = if PassiveType == "Aura"
			then ReplicatedStorage.Shared.Assets.Indicators.AuraSymbols
			elseif PassiveType == "Kick" then ReplicatedStorage.Shared.Assets.Indicators.KickSymbols
			else nil

		local PlayerTargetData = self.PlayerService.PlayerDatas[player.UserId] or nil
		if PlayerTargetData then
			local ClonningAsset = if PassiveType == "Aura"
				then TargetFolder:FindFirstChild(PlayerTargetData.Aura):Clone()
				elseif PassiveType == "Kick" then TargetFolder:FindFirstChild(PlayerTargetData.KickStyle):Clone()
				else nil
			if not ClonningAsset then
				reject("ClonningAsset  Bulunamadi")
			else
				self.PlayerIndicators[PassiveType] = ClonningAsset
				ClonningAsset.Parent = player.Character.SymbolIndicators
				ClonningAsset.Adornee = player.Character.Head
				resolve(ClonningAsset)
			end
		else
			reject("Target Data Didnt Found")
		end
	end)
		:andThen(function(ClonningIndicator)
			return ClonningIndicator
		end)
		:catch(function(err)
			print(err)
		end)
end

function EffectService:KnitInit()
	self.PlayerService = Knit.GetService("PlayerService")
end

function EffectService:KnitStart() end

return EffectService
