local Joints = {
	Head = {
		Joint = "Neck",
		CFrames = {
			CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1),
			CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 1, 0),
		},
	},
	HumanoidRootPart = {
		Joint = "HumanoidRootPart",
		CFrames = { CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), CFrame.new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) },
	},
	["Right Arm"] = {
		Joint = "Default",
		CFrames = {
			CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		},
	},
	["Left Arm"] = {
		Joint = "Default",
		CFrames = {
			CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1),
			CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1),
		},
	},
	["Right Leg"] = {
		Joint = "Default",
		CFrames = {
			CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
			CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
		},
	},
	["Left Leg"] = {
		Joint = "Default",
		CFrames = {
			CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
			CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
		},
	},
}

return Joints
