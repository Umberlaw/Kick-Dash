local Passives = {}

for _, allPassives in script:GetChildren() do
	if not Passives[allPassives.Name] then
		Passives[allPassives.Name] = require(allPassives)
	end
end

return Passives
