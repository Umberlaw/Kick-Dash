local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OverHealth = {}
local Knit = require(ReplicatedStorage.Packages.knit)

OverHealth.OpenedTaskes = {}
OverHealth.KnitServices = {}

function OverHealth:Remove(player)
	if self.OpenedTaskes[player.UserId] then
		task.cancel(self.OpenedTaskes[player.UserId])
		self.OpenedTaskes[player.UserId] = nil
	else
		warn("not find andy removing data")
	end
end

function OverHealth:Active(player, OverHealthAmount)
	self.KnitServices["PlayerService"] = if self.KnitServices["PlayerService"]
		then self.KnitServices["PlayerService"]
		else Knit.GetService("PlayerService")

	if not self.OpenedTaskes[player.UserId] then
		self.OpenedTaskes[player.UserId] = task.spawn(function()
			while task.wait(1) do
				local playerOverHealth = self.KnitServices["PlayerService"].PlayerDatas[player.UserId].OverHealth or 0
				local newOverHealth = math.clamp(playerOverHealth - 2, 0, 100)
				if newOverHealth ~= 0 then
					self.KnitServices["PlayerService"]:UpdatePlayerData(player, { OverHealth = newOverHealth })
				elseif newOverHealth == 0 then
					self.OpenedTaskes[player.UserId] = nil
					print(player, "OverHealth finished")
					break
				end
			end
		end)
	end
	self.KnitServices["PlayerService"]:UpdatePlayerData(player, {
		OverHealth = math.clamp(
			self.KnitServices["PlayerService"].PlayerDatas[player.UserId].OverHealth + OverHealthAmount,
			0,
			100
		),
	})
end

return OverHealth
