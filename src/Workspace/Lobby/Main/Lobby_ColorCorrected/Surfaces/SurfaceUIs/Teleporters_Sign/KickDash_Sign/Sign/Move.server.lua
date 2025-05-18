local RunService = game:GetService("RunService")
local part = script.Parent

local radius = .25            -- Circle radius (studs)
local circleSpeed = .5       -- Circling speed (rotations per second)
local floatAmplitude = .4    -- How high it floats up/down (studs)
local floatSpeed = .5        -- Floating speed (cycles per second)

local centerPosition = part.Position

RunService.Heartbeat:Connect(function()
	local time = tick()

	-- Circle movement in XY plane
	local angle = time * circleSpeed * math.pi * 2
	local offsetX = math.cos(angle) * radius
	local offsetY = math.sin(angle) * radius

	-- Vertical floating on Z axis (up/down)
	local floatZ = math.sin(time * floatSpeed * math.pi * 2) * floatAmplitude

	part.Position = Vector3.new(
		centerPosition.X + offsetX,
		centerPosition.Y + offsetY,
		centerPosition.Z + floatZ
	)
end)