local StarterGUI = game:GetService("StarterGui")

-- Reset Character butonunu devre dışı bırak
repeat -- Starts the repeat loop
	local success = pcall(function()
		StarterGUI:SetCore("ResetButtonCallback", false)
	end)
	task.wait(1) -- Cooldown to avoid freezing
until success
