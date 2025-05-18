local Status = {}

for _, StatuModule in script:GetChildren() do
	Status[StatuModule.Name] = require(StatuModule)
end

return Status
