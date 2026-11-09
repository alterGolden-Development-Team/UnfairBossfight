 
local Placement = require(script.Parent.Parent.Encounter.ArenaPlacement)
local Range = {}
function Range.From(origin, fallback)
	local bounds = Placement.GetBounds()
	if not bounds then return fallback or 1000 end
	local distance = 0
	for _, x in ipairs({-bounds.HalfX, bounds.HalfX}) do
		for _, z in ipairs({-bounds.HalfZ, bounds.HalfZ}) do
			local corner = bounds.Frame:PointToWorldSpace(Vector3.new(x, 0, z))
			distance = math.max(distance, (Vector3.new(corner.X, origin.Y, corner.Z) - origin).Magnitude)
		end
	end
	return math.max(distance + 8, fallback or 0)
end
return table.freeze(Range)