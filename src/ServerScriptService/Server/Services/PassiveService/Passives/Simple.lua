local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.knit)

local Simple = {}
local Services = {}

function Simple:Start(player, otherDatas)
	print("Simple Basladi", otherDatas)
	--Thats an Example Table:    {Direction = Vector3,KnockPower = Number,RagdollDuration = Number}
	Services["RagdollService"] = Services["RagdollService"] or Knit.GetService("RagdollService")
	local HittedPlayer = otherDatas.HittedPlayer or nil
	if not HittedPlayer then
		warn("Vuracak Kimse yok")
	elseif HittedPlayer then
		local RagdollDatas =
			{ Direction = player.Character.HumanoidRootPart.CFrame.LookVector, KnockPower = 35, RagdollDuration = 3 }

		local hittedPlayer = game.Players:FindFirstChild(otherDatas.HittedPlayer.Name)
		print(hittedPlayer)
		if hittedPlayer then
			Services["RagdollService"]:RagdollStatus(HittedPlayer, true, RagdollDatas)
		elseif not hittedPlayer then
			Services["RagdollService"]:NPCRagdoll(HittedPlayer, true, RagdollDatas)
		end
		print("Ragdolladim")
	end
end

return Simple
