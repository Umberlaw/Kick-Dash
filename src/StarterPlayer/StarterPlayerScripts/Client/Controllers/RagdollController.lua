local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.knit)
--local Promise = require(Knit.Util.Promise)

local Player = Players.LocalPlayer

local RagdollController = Knit.CreateController({
	Name = "RagdollController",
})

function RagdollController:StartRagdollTest()
	local TestRagdollDatas = {
		Direction = (Player.Character.HumanoidRootPart.CFrame.LookVector * -1),
		KnockPower = 100,
		RagdollDuration = 3,
	}
	self.RagdollService.Ragdoll:Fire(Player, TestRagdollDatas)
end

function RagdollController:RagdollChar(Char: Model, ragdollData)
	local ragdollingplr = Players:GetPlayerFromCharacter(Char)

	self.RagdollService.Ragdoll:Fire(ragdollingplr, ragdollData)
end

function RagdollController:NPCRagdoll(NPC: Model, ragdollData)
	self.RagdollService.NPCRagdoll:Fire(NPC, ragdollData)
end

function RagdollController:UnRagdoll()
	local hum = Player.Character.Humanoid

	hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	hum.PlatformStand = false
end

function RagdollController:KnitInit()
	self.RagdollService = Knit.GetService("RagdollService")
end

function RagdollController:KnitStart()
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.G then
			self:StartRagdollTest()
		end
	end)
	self.RagdollService.UnRagdoll:Connect(function()
		self:UnRagdoll()
	end)
end

return RagdollController
