local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local LocalPlayer = Players.LocalPlayer

local CommandController = Knit.CreateController({
	Name = "CommandController",
})

function CommandController:WriteCommands()
	print("CommandWriteArea Exucuted")
end

function CommandController:KnitInit()
	self.CommanService = Knit.GetService("CommandService")
end

function CommandController:KnitStart()
	self:WriteCommands()
end

return CommandController
