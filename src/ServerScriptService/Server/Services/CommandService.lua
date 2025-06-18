local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local KickStyleDatas = require(ReplicatedStorage.Shared.configs.KickStyleDatas)

local CommandService = Knit.CreateService({
	Name = "CommandService",
	Client = { UseCommand = Knit.CreateSignal() },
})

function CommandService:UseCommand(player, command, comingData)
	if command == "KickChange" then
		if KickStyleDatas.Kicks[comingData] then
			self.PlayerService:UpdatePlayerData(player, { KickStyle = comingData })
		else
			warn("Wrong KickStyle Name")
		end
	elseif command == "AuraChange" then
		if KickStyleDatas.Auras[comingData] then
			self.PlayerService:UpdatePlayerData(player, { Aura = comingData })
		else
			warn("Wrong Aura Name")
		end
	elseif command == "Health" then
		self.PlayerService:UpdatePlayerData(player, { Health = tonumber(comingData) })
	end
end

function CommandService:KnitInit()
	self.PlayerService = Knit.GetService("PlayerService")
	self.PassiveService = Knit.GetService("PassiveService")
	self.EffectService = Knit.GetService("EffectService")
end

function CommandService:KnitStart()
	self.Client.UseCommand:Connect(function(player, command, comingData)
		self:UseCommand(player, command, comingData)
	end)
end

return CommandService
