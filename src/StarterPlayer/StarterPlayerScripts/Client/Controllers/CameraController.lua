local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(Knit.Util.Promise)
local CameraDatas = require(ReplicatedStorage.Shared.configs.CameraDatas)

local CameraController = Knit.CreateController({ Name = "CameraController" })

function CameraController:GetCameraData(comingData)
	return Promise.new(function(resolve, reject)
		if not comingData then
			reject()
		end
		if CameraDatas[comingData.KickStyle] then
			resolve(CameraDatas[comingData.KickStyle])
		else
			resolve(CameraDatas.Default)
		end
	end)
end

function CameraController:KnitInit() end

function CameraController:KnitStart() end

return CameraController
