local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ViewportWindow = require(ReplicatedStorage.Packages.ViewportWindow)
local Helpers = require(ReplicatedStorage.Utility.Helpers)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Class = require(ReplicatedStorage.Utility.Class)
local Maid = require(ReplicatedStorage.Utility.Maid)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local DUPLICATE_CHARACTER = true
local Y_SPIN = CFrame.fromEulerAnglesYXZ(0, math.pi, 0)

-- Class

local Portal = Class("Portal", ViewportWindow)

function Portal:__init(world, surfaceGui)
	ViewportWindow.__init(self, surfaceGui)

	self.linked = nil
	self.prevHRP = nil
	self.prevHRPPosition = nil

	self.characterSteppers = {}
	self.hole = self:_createPhysicsHole(20, 20, 5)

	local portalPart = self:GetPart()
	local worldCollider = self:_createCollider()

	local worldCopy, worldMatches = Helpers.cloneMatch(world)
	self.filteredMatches = Llama.Dictionary.filter(worldMatches, function(value, key)
		return key:IsA("BasePart") and not key.Anchored
	end)

	self.characterCollider = self:_createCollider(0)
	self.characterCollider.Parent = portalPart.Parent

	worldCopy.Parent = self.worldRoot
	worldCollider.Parent = portalPart.Parent
	portalPart.CanCollide = false

	self.maid = Maid.new()

	self.maid:Mark(self.hole)
	self.maid:Mark(worldCollider)
	self.maid:Mark(self.characterCollider)
end

function Portal.FromPart(world, part, normalId)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = normalId
	surfaceGui.CanvasSize = Vector2.new(1024, 1024)
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surfaceGui.Adornee = part
	surfaceGui.ClipsDescendants = true
	surfaceGui.ResetOnSpawn = false
	surfaceGui.Parent = Players.LocalPlayer.PlayerGui

	return Portal.new(world, surfaceGui)
end

-- Private

function Portal:_weldToWindow(offset, size)
	local part = Instance.new("Part")
	part.Transparency = 1
	part.Massless = true
	part.Size = size

	local motor = Instance.new("Motor6D")
	motor.C0 = offset
	motor.Part0 = self:GetPart()
	motor.Part1 = part
	motor.Parent = part

	return part
end

function Portal:_createPhysicsHole(width, height, depth)
	local hole = Instance.new("Model")
	local _, surfaceSize = self:GetSurface()

	-- top
	self:_weldToWindow(
		CFrame.new(0, (surfaceSize.Y + height) / 2, depth / 2),
		Vector3.new(surfaceSize.X, height, surfaceSize.Z + depth)
	).Parent =
		hole

	-- bottom
	self:_weldToWindow(
		CFrame.new(0, -(surfaceSize.Y + height) / 2, depth / 2),
		Vector3.new(surfaceSize.X, height, surfaceSize.Z + depth)
	).Parent =
		hole

	-- right
	self:_weldToWindow(
		CFrame.new((surfaceSize.X + width) / 2, 0, depth / 2),
		Vector3.new(width, height * 2 + surfaceSize.Y, surfaceSize.Z + depth)
	).Parent =
		hole

	-- left
	self:_weldToWindow(
		CFrame.new(-(surfaceSize.X + width) / 2, 0, depth / 2),
		Vector3.new(width, height * 2 + surfaceSize.Y, surfaceSize.Z + depth)
	).Parent =
		hole

	-- backing
	self:_weldToWindow(
		CFrame.new(0, 0, depth + 0.6),
		Vector3.new(width * 2 + surfaceSize.X, height * 2 + surfaceSize.Y, 1)
	).Parent =
		hole

	return hole
end

function Portal:_createCollider(collisionGroupId)
	local part = self:GetPart()

	local collider = part:Clone()
	collider:ClearAllChildren()
	collider.Name = part.Name .. "Collider"
	collider.Massless = true
	collider.Anchored = false
	collider.CanCollide = true
	collider.CanTouch = false
	collider.Transparency = 1

	if collisionGroupId then
		collider.CollisionGroupId = collisionGroupId
	end

	local motor = Instance.new("Motor6D")
	motor.Part0 = part
	motor.Part1 = collider
	motor.Parent = collider

	return collider
end

function Portal:_isInFrontOf(wasTouching, depth, hrp)
	if not hrp then
		local character = Players.LocalPlayer.Character
		hrp = character and character:FindFirstChild("HumanoidRootPart")
	end

	if hrp then
		local surfaceCF, surfaceSize = self:GetSurface()

		local boundCF = surfaceCF * CFrame.new(0, 0, -depth / 2)
		local boundSize = Vector3.new(surfaceSize.X, surfaceSize.Y, depth)

		if wasTouching then
			boundCF = boundCF * CFrame.new(0, 0, surfaceSize.Z)
			boundSize = boundSize + Vector3.new(0, 0, surfaceSize.Z)
		end

		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Whitelist
		overlap.FilterDescendantsInstances = { hrp }

		return (#workspace:GetPartBoundsInBox(boundCF, boundSize, overlap) > 0)
	end

	return false
end

function Portal:_teleport(hrp, humanoid)
	local camera = workspace.CurrentCamera

	local fromSurface = self:GetSurface()
	local toSurface = self.linked:GetSurface()
	toSurface = toSurface * Y_SPIN

	hrp.CFrame = toSurface * fromSurface:ToObjectSpace(hrp.CFrame)
	hrp.Velocity = toSurface:VectorToWorldSpace(fromSurface:VectorToObjectSpace(hrp.Velocity))
	hrp.RotVelocity = toSurface:VectorToWorldSpace(fromSurface:VectorToObjectSpace(hrp.RotVelocity))

	humanoid:Move(toSurface:VectorToWorldSpace(fromSurface:VectorToObjectSpace(humanoid.MoveDirection)))

	camera.Focus = toSurface * fromSurface:ToObjectSpace(camera.Focus)
	camera.CFrame = toSurface * fromSurface:ToObjectSpace(camera.CFrame)
end

-- Public

function Portal:Link(otherPortal)
	self.linked = otherPortal
end

function Portal:GetLinked()
	return self.linked
end

function Portal:GetCameraPassThrough()
	local portalPart = self:GetPart()
	local camera = workspace.CurrentCamera

	local result = Helpers.raycast(workspace, camera.Focus.Position, (camera.CFrame.Position - camera.Focus.Position), {
		FilterType = Enum.RaycastFilterType.Whitelist,
		Instances = { portalPart },
	})

	if result and result.Normal:Dot(portalPart.CFrame.ZVector) <= -0.999 then
		local fromSurface = self:GetSurface()
		local toSurface = self.linked:GetSurface()
		toSurface = toSurface * Y_SPIN

		local newCFrame = toSurface * fromSurface:ToObjectSpace(camera.CFrame)
		local newFocus = toSurface * fromSurface:ToObjectSpace(camera.Focus)

		return true, newCFrame, newFocus
	end

	return false
end

function Portal:AttemptTeleport()
	local success = false

	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local hrp = humanoid and humanoid.RootPart

	if hrp and hrp == self.prevHRP then
		local portalPart = self:GetPart()
		local result = Helpers.raycast(workspace, self.prevHRPPosition, (hrp.Position - self.prevHRPPosition), {
			FilterType = Enum.RaycastFilterType.Whitelist,
			Instances = { portalPart },
		})

		if result and result.Normal:Dot(portalPart.CFrame.ZVector) <= -0.999 then
			self:_teleport(hrp, humanoid)
			success = true
		end
	end

	self.prevHRP = hrp
	self.prevHRPPosition = hrp and hrp.Position

	return success
end

function Portal:Render()
	self.surfaceGui.Enabled = not not self.linked

	if self.linked then
		local cameraCF = workspace.CurrentCamera.CFrame
		local mySurfaceCF, mySurfaceSize = self:GetSurface()
		local linkedSurfaceCF, linkedSurfaceSize = self.linked:GetSurface()

		local newSurfaceCF = linkedSurfaceCF * Y_SPIN
		local newCameraCF = newSurfaceCF * mySurfaceCF:ToObjectSpace(cameraCF)

		ViewportWindow.Render(self, newCameraCF, newSurfaceCF, linkedSurfaceSize)
	end
end

function Portal:SetTouching(enabled)
	self.hole.Parent = enabled and self.characterCollider or nil
	self.characterCollider.CanCollide = not enabled
end

function Portal:PhysicsStep(wasTouching)
	if self.linked then
		if self:_isInFrontOf(wasTouching, 5) then
			wasTouching = true
		else
			wasTouching = false
		end

		for real, copy in pairs(self.filteredMatches) do
			copy.CFrame = real.CFrame
		end
	end

	return wasTouching
end

function Portal:WatchCharacter(character)
	local function refresh()
		local characterCopy, characterMatches = Helpers.cloneMatch(character)
		local filteredMatches = Llama.Dictionary.filter(characterMatches, function(value, key)
			return key:IsA("BasePart")
		end)

		if characterCopy:FindFirstChild("Humanoid") then
			characterCopy.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end

		for real, copy in pairs(filteredMatches) do
			copy.Anchored = true
			--copy.CollisionGroupId = PhysicsService:GetCollisionGroupId("NoCollision")
		end

		return characterCopy, filteredMatches
	end

	local cleanup = Maid.new()
	local characterCopy, filteredMatches = refresh()
	local characterCopy2, filteredMatches2 = refresh()

	characterCopy.Parent = self.worldFrame

	self.characterSteppers[character] = function()
		if self.linked and filteredMatches then
			local portalPart = self:GetPart()
			local surfaceCF, surfaceSize = self:GetSurface()

			local foundSet = {}
			if character.PrimaryPart and self:_isInFrontOf(false, 5, character.PrimaryPart) then
				local overlap = OverlapParams.new()
				overlap.FilterType = Enum.RaycastFilterType.Whitelist
				overlap.FilterDescendantsInstances = { character }
				overlap.CollisionGroup = "Characters"

				local foundList = workspace:GetPartBoundsInBox(portalPart.CFrame, portalPart.Size, overlap)
				foundSet = Llama.Set.fromList(foundList)
			end

			local fromSurface = self:GetSurface()
			local toSurface = self.linked:GetSurface()
			toSurface = toSurface * Y_SPIN

			local visibleWorld = {}

			for real, copy in pairs(filteredMatches) do
				if foundSet[real] then
					copy.CFrame = toSurface * fromSurface:ToObjectSpace(real.CFrame)

					local worldMatch = filteredMatches2[real]
					if DUPLICATE_CHARACTER and worldMatch then
						worldMatch.CFrame = toSurface * fromSurface:ToObjectSpace(real.CFrame)
						visibleWorld[real] = true
					end
				else
					copy.CFrame = real.CFrame
				end
			end

			if next(visibleWorld) then
				for real, copy in pairs(filteredMatches2) do
					if visibleWorld[real] then
						copy.LocalTransparencyModifier = real.LocalTransparencyModifier
					else
						copy.LocalTransparencyModifier = 1
					end
				end
				characterCopy2.Parent = workspace.FakeCharacters
			else
				characterCopy2.Parent = nil
			end
		end
	end

	self.characterSteppers[character]()

	cleanup:Mark(function()
		self.characterSteppers[character] = nil
	end)

	cleanup:Mark(character.DescendantAdded:Connect(function(instance)
		if not instance:IsA("BasePart") then
			return
		end
		characterCopy:Destroy()
		characterCopy, filteredMatches = refresh()
		characterCopy2, filteredMatches2 = refresh()
		characterCopy.Parent = self.worldFrame
	end))

	cleanup:Mark(character.DescendantRemoving:Connect(function(instance)
		if not instance:IsA("BasePart") then
			return
		end
		characterCopy:Destroy()
		characterCopy, filteredMatches = refresh()
		characterCopy2, filteredMatches2 = refresh()

		if filteredMatches[instance] then
			filteredMatches[instance]:Destroy()
			filteredMatches[instance] = nil
		end

		if filteredMatches2[instance] then
			filteredMatches2[instance]:Destroy()
			filteredMatches2[instance] = nil
		end

		characterCopy.Parent = self.worldFrame
	end))

	cleanup:Mark(function()
		characterCopy:Destroy()
	end)

	return cleanup
end

function Portal:StepCharacters()
	for character, stepper in pairs(self.characterSteppers) do
		stepper()
	end
end

function Portal:Destroy()
	self.maid:Sweep()
end

--

return Portal
