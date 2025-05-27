local Kick = {}

function Kick:StartRelease(player)
	print(player.Name, "ReleasedThe Mouse")
end

function Kick:Start(player)
	print(player.Name, "Passifi tetikledi")
end

return Kick
