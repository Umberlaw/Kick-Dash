local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)

Knit.AddServices(script.Parent.Services)

Knit.Start({ ServicePromises = false })
	:andThen(function()
		print("[Knit] Services started ✅")
	end)
	:catch(warn)
	:finally(function()
		--[[for _, Components in script.Parent.Components:GetChildren() do
			require(Components)
		end]]
	end)
