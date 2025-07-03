local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)
--local Portal = require(ReplicatedStorage.Packages.Portal)

local PortalsFolder = Workspace:WaitForChild("Lobby"):WaitForChild("Portals")

local PortalController = Knit.CreateController({ Name = "PortalController" })

function PortalController:CreatePortal()
	--[[print("Portal kurulacak")
	print(PortalsFolder:GetChildren())
	local portalA1 = PortalsFolder:FindFirstChild("PortalA") or PortalsFolder:WaitForChild("PortalA", 9e9)
	local PortalB1 = PortalsFolder:FindFirstChild("PortalB")
	if not portalA1 or not PortalB1 then
		warn("PORTALLAR YOOOOK")
		return
	end
	if not self.Portals then
		self.Portals = {}
	end
	if not self.Portals[portalA1] then
		self.Portals[portalA1] = { PortalA = portalA1, PortalB = PortalB1 }

		local portalA = Portal.FromPart(workspace.World, self.Portals[portalA1].PortalA, Enum.NormalId.Front)
		local portalB = Portal.FromPart(workspace.World, self.Portals[portalA1].PortalB, Enum.NormalId.Front)

		portalA:Link(portalB)
		portalB:Link(portalA)

		-- World rendering and camera pass through

		local characterPortalSide = portalA
		local prevPortalSide = characterPortalSide

		local prevCamCF = workspace.CurrentCamera.CFrame
		local prevCamFocus = workspace.CurrentCamera.Focus

		RunService:BindToRenderStep("BeforeInput", Enum.RenderPriority.Input.Value - 1, function()
			workspace.CurrentCamera.CFrame = prevCamCF
			workspace.CurrentCamera.Focus = prevCamFocus
		end)

		RunService.RenderStepped:Connect(function(dt)
			local successTeleA = portalA:AttemptTeleport()
			local successTeleB = portalB:AttemptTeleport()

			if characterPortalSide == portalA and successTeleA then
				characterPortalSide = portalB
			elseif characterPortalSide == portalB and successTeleB then
				characterPortalSide = portalA
			end

			prevCamCF = workspace.CurrentCamera.CFrame
			prevCamFocus = workspace.CurrentCamera.Focus

			for _, portal in pairs({ portalA, portalB }) do
				local surfaceCF, surfaceSize = portal:GetSurface()
				local lp = surfaceCF:PointToObjectSpace(prevCamCF.Position)

				-- only do the pass through if the camera is more than x studs behine the portal surface
				-- if we don't do this we get weird geometry for a frame on pass through b/c of near clipping plane z
				if lp.Z < 0.15 then
					continue
				end

				local success, cframe, focus = portal:GetCameraPassThrough()

				if success then
					workspace.CurrentCamera.CFrame = cframe
					workspace.CurrentCamera.Focus = focus

					break
				end
			end

			portalA:StepCharacters()
			portalB:StepCharacters()

			portalA:Render()
			portalB:Render()
		end)

		local wasTouchingA = false
		local wasTouchingB = false

		RunService.Heartbeat:Connect(function()
			wasTouchingA = portalA:PhysicsStep(wasTouchingA)
			wasTouchingB = portalB:PhysicsStep(wasTouchingB)

			if not wasTouchingA and not wasTouchingB then
				portalA:SetTouching(false)
				portalB:SetTouching(false)
			else
				portalA:SetTouching(true)
				portalB:SetTouching(true)
			end
		end)

		-- Character rendering

		local function onCharacterAdded(player, character)
			local cleanupA = portalA:WatchCharacter(player.Character)
			local cleanupB = portalB:WatchCharacter(player.Character)
			player.CharacterRemoving:Wait()
			cleanupA:Sweep()
			cleanupB:Sweep()
		end

		for _, player in pairs(Players:GetPlayers()) do
			if player.Character then
				task.spawn(onCharacterAdded, player, player.Character)
			end

			player.CharacterAdded:Connect(function(character)
				onCharacterAdded(player, character)
			end)
		end

		Players.PlayerAdded:Connect(function(player)
			player.CharacterAdded:Connect(function(character)
				onCharacterAdded(player, character)
			end)
		end)
	end]]
end

function PortalController:KnitInit()
	self.PortalService = Knit.GetService("PortalService")
end

function PortalController:KnitStart()
	self.PortalService.CreatePortal:Connect(function(portal1, portal2)
		print("vERI GELDi mi")
		self:CreatePortal(portal1, portal2)
	end)
end

return PortalController
