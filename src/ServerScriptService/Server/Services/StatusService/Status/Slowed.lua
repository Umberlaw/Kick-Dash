local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Slowed = {}

local Knit = require(ReplicatedStorage.Packages.knit)
--local Promise = require(Knit.Util.Promise)

Slowed.OpenedTaskes = {}
Slowed.KnitServices = {}

Slowed.SlowCount = 15

function Slowed:Remove(player)
	if self.OpenedTaskes[player.UserId] then
		if coroutine.status(self.OpenedTaskes[player.UserId]) == "Running" then
			task.cancel(self.OpenedTaskes[player.UserId])
		end
		self.OpenedTaskes[player.UserId] = nil
	end
end

function Slowed:Active(player, _, _)
	print("Active edildi")
	self.KnitServices["PlayerService"] = self.KnitServices["PlayerService"] or Knit.GetService("PlayerService")
	local PlayersData = self.KnitServices["PlayerService"].PlayerDatas[player.UserId]
	if not PlayersData then
		warn(player.Name .. "'s Data didnt find")
		return
	end
	if not self.OpenedTaskes[player.UserId] then
		self.OpenedTaskes[player.UserId] = task.spawn(function()
			while true do
				task.wait(1)
				print(PlayersData)
				if PlayersData.Debuffes["Slowed"] then
					local SlowedTime = PlayersData.Debuffes["Slowed"].RemainingTime
					SlowedTime = math.clamp(SlowedTime - 1, 0, math.huge) or 0
					if SlowedTime <= 0 then
						self.KnitServices["PlayerService"]:RemoveDebuff(player, "Slowed")
						self.KnitServices["PlayerService"]:UpdatePlayerData(player, { WalkSpeed = 25 })
						self:Remove(player)
						break
					elseif SlowedTime > 0 then
						if PlayersData.WalkSpeed > self.SlowCount then
							self.KnitServices["PlayerService"]:UpdatePlayerData(player, { WalkSpeed = self.SlowCount })
						end
						self.KnitServices["PlayerService"]:UpdateDebuffData(player, "Slowed", { RemainingTime = -1 })
					end
				else
					print("Debuff Data yok")
				end
			end
		end)
	end
end

return Slowed
