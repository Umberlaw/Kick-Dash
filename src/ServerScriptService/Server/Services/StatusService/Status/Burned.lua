local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Burned = {}

Burned.OpenedTaskes = {}
Burned.KnitServices = {}

local Knit = require(ReplicatedStorage.Packages.knit)

function Burned:Remove(player)
	if self.OpenedTaskes[player.UserId] then
		if coroutine.status(self.OpenedTaskes[player.UserId]) == "Running" then
			task.cancel(self.OpenedTaskes[player.UserId])
		end
		self.OpenedTaskes[player.UserId] = nil
		print("kapaniyorum")
	end
end

function Burned:Active(player, _, _)
	self.KnitServices["PlayerService"] = self.KnitServices["PlayerService"] or Knit.GetService("PlayerService")

	local playerData = self.KnitServices["PlayerService"].PlayerDatas[player.UserId] or nil
	if not playerData then
		warn("Player data Didnt find")
		return
	end

	if not self.OpenedTaskes[player.UserId] then
		self.OpenedTaskes[player.UserId] = task.spawn(function()
			while task.wait(1) do
				print("gorevimi yapiyorum buirned")
				local BurnedTime = playerData.Debuffes["Burned"].RemainingTime
				local remainingBurnedTime = math.clamp(BurnedTime - 1, 0, math.huge)
				if remainingBurnedTime <= 0 then
					self.KnitServices["PlayerService"]:RemoveDebuff(player, "Burned")
					self:Remove(player)
					break
				elseif remainingBurnedTime > 0 then
					local RemainingHP =
						math.clamp(playerData.Health - (playerData.MaximumHealth * 0.01), 0, playerData.MaximumHealth)
					self.KnitServices["PlayerService"]:UpdatePlayerData(player, { Health = RemainingHP })
					self.KnitServices["PlayerService"]:UpdateDebuffData(player, "Burned", { RemainingTime = -1 })
				end
			end
		end)
	else
		print("ZATEN AKTIF OLARAK VAR")
	end
end

return Burned
