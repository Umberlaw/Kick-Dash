local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)

Knit.AddControllers(script.Parent.Controllers)

Knit.Start({ ServicePromises = false })
	:andThen(function()
		print("[Knit] Controllers started ✅")
	end)
	:catch(warn)
	:finally(function()
		--[[for _,Components in script.Parent.Components:GetChildren() do
            require(Components)
        end]]
	end)
