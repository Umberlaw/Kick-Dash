local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Helpers = require(ReplicatedStorage.Utility.Helpers)
local Class = require(ReplicatedStorage.Utility.Class)

local Lighting = game:GetService("Lighting")

local VEC_XZ = Vector3.new(1, 0, 1)
local VEC_YZ = Vector3.new(0, 1, 1)
local Y_SPIN = CFrame.fromEulerAnglesXYZ(0, math.pi, 0)

local FLIP_X = CFrame.new(0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 1)
local SIDE_CFRAME = FLIP_X * CFrame.fromEulerAnglesXYZ(math.pi, math.pi, 0)
local TOP_CFRAME = FLIP_X * CFrame.fromEulerAnglesXYZ(math.pi, math.pi / 2, 0)
local BOTTOM_CFRAME = FLIP_X * CFrame.fromEulerAnglesXYZ(math.pi, -math.pi / 2, 0)

local SIDES = {
	["SkyboxBk"] = Enum.NormalId.Back,
	["SkyboxFt"] = Enum.NormalId.Front,
	["SkyboxLf"] = Enum.NormalId.Left,
	["SkyboxRt"] = Enum.NormalId.Right,
}

-- Class

local ViewportWindow = Class("ViewportWindow")

function ViewportWindow:__init(surfaceGui)
	self.surfaceGui = surfaceGui

	self.camera = Instance.new("Camera")
	self.camera.Parent = surfaceGui

	self.worldFrame = self:_createVPF("WorldFrame", 2)
	self.skyboxFrame = self:_createVPF("SkyboxFrame", 1)

	self.worldRoot = Instance.new("WorldModel")
	self.worldRoot.Parent = self.worldFrame
end

-- Private

function ViewportWindow:_createVPF(name, zindex)
	local vpf = Instance.new("ViewportFrame")
	vpf.LightColor = Color3.new(0, 0, 0)
	vpf.Size = UDim2.new(1, 0, 1, 0)
	vpf.Position = UDim2.new(0, 0, 0, 0)
	vpf.AnchorPoint = Vector2.new(0, 0)
	vpf.BackgroundTransparency = 1
	vpf.LightDirection = -Lighting:GetSunDirection()
	vpf.Ambient = Lighting.Ambient
	vpf.Name = name
	vpf.ZIndex = zindex
	vpf.CurrentCamera = self.camera
	vpf.Parent = self.surfaceGui

	return vpf
end

function ViewportWindow:_refreshVisibility(cameraCFrame, surfaceCFrame, surfaceSize, marginOfError)
	local aabbCF, aabbSize = Helpers.getAABB({
		surfaceCFrame
			* Vector3.new(-surfaceSize.X / 2 + marginOfError, surfaceSize.Y / 2 - marginOfError, -marginOfError),
		surfaceCFrame
			* Vector3.new(surfaceSize.X / 2 - marginOfError, surfaceSize.Y / 2 - marginOfError, -marginOfError),
		surfaceCFrame
			* Vector3.new(surfaceSize.X / 2 - marginOfError, -surfaceSize.Y / 2 + marginOfError, -marginOfError),
		surfaceCFrame
			* Vector3.new(-surfaceSize.X / 2 + marginOfError, -surfaceSize.Y / 2 + marginOfError, -marginOfError),
		cameraCFrame.Position,
	})

	-- region3 is more performant tmk over newer API which allows rotation (which we don't need)
	-- local overlap = self.worldRoot:GetPartBoundsInBox(aabbCF, aabbSize)
	local overlap = self.worldRoot:FindPartsInRegion3(
		Region3.new(aabbCF.Position + aabbSize / 2, aabbCF.Position - aabbSize / 2),
		nil,
		math.huge
	)

	local overlapped = {}
	for _, part in pairs(overlap) do
		part.LocalTransparencyModifier = 1
		overlapped[part] = true
	end

	for _, instance in pairs(self.worldRoot:GetDescendants()) do
		if instance:IsA("BasePart") and not overlapped[instance] then
			instance.LocalTransparencyModifier = 0
		end
	end
end

-- Public

function ViewportWindow:AddSkybox(skybox)
	self.skyboxFrame:ClearAllChildren()

	local model = Instance.new("Model")

	local side = Instance.new("Part")
	side.Anchored = true
	side.CanCollide = false
	side.CanTouch = false
	side.Transparency = 1
	side.Size = Vector3.new(1, 1, 1)

	local mesh = Instance.new("BlockMesh")
	mesh.Scale = Vector3.new(10000, 10000, 10000)
	mesh.Parent = side

	local top = side:Clone()
	local bottom = side:Clone()

	for property, enum in pairs(SIDES) do
		local decal = Instance.new("Decal")
		decal.Texture = skybox[property]
		decal.Face = enum
		decal.Parent = side
	end

	local decalTop = Instance.new("Decal")
	decalTop.Texture = skybox.SkyboxUp
	decalTop.Face = Enum.NormalId.Top
	decalTop.Parent = top

	local decalBottom = Instance.new("Decal")
	decalBottom.Texture = skybox.SkyboxDn
	decalBottom.Face = Enum.NormalId.Bottom
	decalBottom.Parent = bottom

	side.CFrame = SIDE_CFRAME
	top.CFrame = TOP_CFRAME
	bottom.CFrame = BOTTOM_CFRAME

	side.Parent = model
	top.Parent = model
	bottom.Parent = model

	model.Name = "SkyboxModel"
	model.Parent = self.skyboxFrame
end

function ViewportWindow:GetWorldFrame()
	return self.worldFrame
end

function ViewportWindow:GetWorldRoot()
	return self.worldRoot
end

function ViewportWindow:GetPart()
	return self.surfaceGui.Adornee
end

function ViewportWindow:GetSurface()
	local part = self.surfaceGui.Adornee

	local v = -Vector3.FromNormalId(self.surfaceGui.Face)
	local u = Vector3.new(v.y, math.abs(v.x + v.z), 0)
	local lcf = CFrame.fromMatrix(Vector3.new(), u:Cross(v), u, v)
	local cf = part.CFrame * CFrame.new(-v * part.Size / 2) * lcf

	return cf,
		Vector3.new(
			math.abs(lcf.XVector:Dot(part.Size)),
			math.abs(lcf.YVector:Dot(part.Size)),
			math.abs(lcf.ZVector:Dot(part.Size))
		)
end

function ViewportWindow:Render(cameraCFrame, surfaceCFrame, surfaceSize)
	local camera = workspace.CurrentCamera

	cameraCFrame = cameraCFrame or camera.CFrame
	if not (surfaceCFrame and surfaceSize) then
		surfaceCFrame, surfaceSize = self:GetSurface()
	end

	if surfaceCFrame:PointToObjectSpace(cameraCFrame.Position).Z > 0 then
		return
	end

	local xCross = surfaceCFrame.YVector:Cross(cameraCFrame.ZVector)
	local xVector = xCross:Dot(xCross) > 0 and xCross.Unit or cameraCFrame.XVector
	local levelCameraCFrame = CFrame.fromMatrix(cameraCFrame.Position, xVector, surfaceCFrame.YVector)

	local tc = surfaceCFrame * Vector3.new(0, surfaceSize.y / 2, 0)
	local bc = surfaceCFrame * Vector3.new(0, -surfaceSize.y / 2, 0)
	local cstc = levelCameraCFrame:PointToObjectSpace(tc)
	local csbc = levelCameraCFrame:PointToObjectSpace(bc)

	local tv = (cstc * VEC_YZ).Unit
	local bv = (csbc * VEC_YZ).Unit
	local alpha = math.sign(tv.y) * math.acos(-tv.z)
	local beta = math.sign(bv.y) * math.acos(-bv.z)

	local fovH = 2 * math.tan(math.rad(camera.FieldOfView / 2))
	local surfaceFovH = math.tan(alpha) - math.tan(beta)
	local fovRatio = surfaceFovH / fovH

	local dv = surfaceCFrame:VectorToObjectSpace(surfaceCFrame.Position - cameraCFrame.Position)
	local dvXZ = (dv * VEC_XZ).Unit
	local dvXY = dv * VEC_YZ

	local dvx = -dvXZ.z
	local camXZ = (surfaceCFrame:VectorToObjectSpace(cameraCFrame.LookVector) * VEC_XZ).Unit
	local scale = camXZ:Dot(dvXZ) / dvx
	local tanArcCos = math.sqrt(1 - dvx * dvx) / dvx

	local w, h = 1, 1
	if self.surfaceGui.SizingMode == Enum.SurfaceGuiSizingMode.FixedSize then
		h = surfaceSize.x / surfaceSize.y
	end

	local dx = math.sign(dv.x * dv.z) * tanArcCos
	local dy = dvXY.y / dvXY.z * h
	local d = math.abs(scale * fovRatio * h)

	local newCFrame = (surfaceCFrame - surfaceCFrame.Position)
		* Y_SPIN
		* CFrame.new(0, 0, 0, w, 0, 0, 0, h, 0, dx, dy, d)

	local max = 0
	local components = { newCFrame:GetComponents() }
	for i = 1, #components do
		max = math.max(max, math.abs(components[i]))
	end

	for i = 1, #components do
		components[i] = components[i] / max
	end

	local scaledCFrame = CFrame.new(unpack(components)) + cameraCFrame.Position

	self.camera.FieldOfView = camera.FieldOfView
	self.camera.CFrame = scaledCFrame

	-- this eats performance!
	-- self:_refreshVisibility(cameraCFrame, surfaceCFrame, surfaceSize, 0.001)
end

--

return ViewportWindow
