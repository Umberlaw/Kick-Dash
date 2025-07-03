local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.knit)

local Simple = {}
local Services = {}

function Simple:Start(player, otherDatas)
	print("Simple Basladi", otherDatas)
	--Thats an Example Table:    {Direction = Vector3,KnockPower = Number,RagdollDuration = Number}
	Services["RagdollService"] = Services["RagdollService"] or Knit.GetService("RagdollService")
	local HittedPlayer = otherDatas.HittedPlayer or nil
	local SimpleEffectFolder = ReplicatedStorage.Shared.Assets.VFX.Passives.Auras:FindFirstChild("Simple")
	local effectTable = {}
	if SimpleEffectFolder then
		for _, allEffects in SimpleEffectFolder:GetChildren() do
			local clonnedEffect = allEffects:Clone()
			clonnedEffect.Parent = if player.Character then player.Character.Torso else player.Torso
			clonnedEffect.Enabled = true
			table.insert(effectTable, clonnedEffect)
		end
	end
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
	task.delay(1, function()
		for _, allEffects in effectTable do
			allEffects.Enabled = false
			task.delay(1, function()
				allEffects:Destroy()
			end)
		end
	end)
end

return Simple
