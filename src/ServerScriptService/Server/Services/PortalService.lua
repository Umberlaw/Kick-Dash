local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)
local Portal = require(ReplicatedStorage.Packages.Portal)

local PortalService =
	Knit.CreateService({ Name = "PortalService", Client = { CreatePortal = Knit.CreateSignal() }, Portals = {} })

function PortalService:CreatePortal(player)
	print("CALISTIRILDI")
	self.Client.CreatePortal:Fire(player)
end

function PortalService:KnitInit() end

function PortalService:KnitStart() end

return PortalService
