local RunService = game:GetService("RunService")

local model = script.Parent

-- Tiny, slow floating settings
local radiusMin, radiusMax = 0.05, 0.15
local circleSpeedMin, circleSpeedMax = 0.1, 0.3
local floatAmplitudeMin, floatAmplitudeMax = 0.02, 0.05
local floatSpeedMin, floatSpeedMax = 0.2, 0.45
local rotationSpeedMin, rotationSpeedMax = 0.08, 0.16
local rotationAngleMax = math.rad(5)

local partsData = {}

for _, part in ipairs(model:GetDescendants()) do
	if part:IsA("BasePart") and part.Name == "Letter" then
		table.insert(partsData, {
			part = part,
			centerPosition = part.Position,
			originalCFrame = part.CFrame, -- Save original orientation
			radius = math.random(radiusMin * 100, radiusMax * 100) / 100,
			circleSpeed = math.random(circleSpeedMin * 100, circleSpeedMax * 100) / 100,
			floatAmplitude = math.random(floatAmplitudeMin * 100, floatAmplitudeMax * 100) / 100,
			floatSpeed = math.random(floatSpeedMin * 100, floatSpeedMax * 100) / 100,
			rotationSpeed = math.random(rotationSpeedMin * 100, rotationSpeedMax * 100) / 100,
			circlePhase = math.random() * math.pi * 2,
			floatPhase = math.random() * math.pi * 2,
			rotationPhase = math.random() * math.pi * 2,
		})
	end
end

if #partsData == 0 then
	warn("No parts named 'Letter' found in model.")
	return
end

RunService.Heartbeat:Connect(function()
	local time = tick()
	for _, data in ipairs(partsData) do
		local angle = (time * data.circleSpeed * math.pi * 2) + data.circlePhase
		local offsetX = math.cos(angle) * data.radius
		local offsetY = math.sin(angle) * data.radius
		local floatZ = math.sin((time * data.floatSpeed * math.pi * 2) + data.floatPhase) * data.floatAmplitude
		local rotationZ = math.sin((time * data.rotationSpeed * math.pi * 2) + data.rotationPhase) * rotationAngleMax

		local offset = Vector3.new(offsetX, offsetY, floatZ)
		local newPos = data.centerPosition + offset

		-- Rotate around local Z by rotating on top of original orientation
		local localRotation = CFrame.Angles(0, 0, rotationZ)
		data.part.CFrame = CFrame.new(newPos) * data.originalCFrame.Rotation * localRotation
	end
end)