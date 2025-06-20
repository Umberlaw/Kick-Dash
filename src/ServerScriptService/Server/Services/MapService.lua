local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)

local MapService = Knit.CreateService({ Name = "MapService", Client = {}, MapStatus = "NaN", ShipMoveTask = nil })

function MapService:StopMovingShip() end

function MapService:StartMovingShip()
	local ship: Model = workspace:WaitForChild("Ship")
	local floor = workspace:WaitForChild("Map"):FindFirstChild("Floor")
	local angle = 0
	local timePassed = 0
	local radius = 325 -- Floor merkezinden uzaklık
	local rotationSpeed = math.rad(3) -- Derece cinsinden saniyede 30 derece dönsün (radyana çevrildi)
	local bobbingAmplitude = 2 -- Yukarı aşağı eğilme miktarı (derece)
	local bobbingSpeed = 1.65 -- Salınım hızı
	if not self.ShipMoveTask then
		self.ShipMoveTask = RunService.Heartbeat:Connect(function(deltaTime)
			angle += rotationSpeed * deltaTime
			timePassed += deltaTime

			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			local centerPosition = floor.Position
			local targetPosition = centerPosition + Vector3.new(x, ship:GetExtentsSize().Y / 2.45, z)
			local bobbingAngle = math.sin(timePassed * bobbingSpeed) * math.rad(bobbingAmplitude)
			local bobbingCFrame = CFrame.Angles(0, 0, bobbingAngle)

			local lookAtCFrame = CFrame.new(
				targetPosition,
				centerPosition + Vector3.new(0, ship:GetExtentsSize().Y / 2, 0)
			) * CFrame.Angles(0, math.rad(170), 0)

			local finalCFrame = lookAtCFrame * bobbingCFrame
			if ship:IsA("Model") then
				ship:PivotTo(finalCFrame)
			else
				ship.CFrame = finalCFrame
			end
		end)
	end
end

function MapService:KnitInit() end

function MapService:KnitStart()
	print("KnitStarted", self)
	self:StartMovingShip()
end

return MapService
