 -- Where the ruined arena's ring of golden fire burns (workspace ArenaRuinedAt, after the first Wild Hunt). Shared so
 -- each client draws the fires (BossClient.Presentation.ArenaRuinClient) exactly where the server burns players who
 -- touch them (BossSystem.Encounter.ArenaRuin). The layout is seeded, so every machine builds the same ring.
local api = {}
api.Spacing = 40
api.Inset = 4  -- how far inside the floor's edge they stand
api.SizeMin, api.SizeMax = 26, 34
api.CatchAt = 1.2  -- seconds after the ruin before the first rim fire catches; the rest follow over CatchSpread
api.CatchSpread = 1.2

function api.Rim(floor)
	local hx = (floor and floor.Size.X / 2 or 310) - api.Inset
	local hz = (floor and floor.Size.Z / 2 or 230) - api.Inset
	local top = floor and floor.Position.Y + floor.Size.Y / 2 or 0
	local rng = Random.new(31)
	local list = {}
	local function add(x, z)
		list[#list + 1] = {
			Position = Vector3.new(x, top, z),
			Size = rng:NextNumber(api.SizeMin, api.SizeMax),
			LitAt = api.CatchAt + rng:NextNumber(0, api.CatchSpread),
		}
	end
	local nx, nz = math.max(1, math.round(2 * hx / api.Spacing)), math.max(1, math.round(2 * hz / api.Spacing))
	for i = 0, nx do
		local x = -hx + 2 * hx * i / nx
		add(x, -hz)
		add(x, hz)
	end
	for i = 1, nz - 1 do
		local z = -hz + 2 * hz * i / nz
		add(-hx, z)
		add(hx, z)
	end
	return list
end

 -- the burning part of a fire: a column as wide as its flames and a little taller than them
function api.Radius(size)
	return size * 0.4
end
function api.Height(size)
	return size * 1.1
end

 -- the rim fire burning at pos, if any; a fire only counts once it has caught, `elapsed` seconds after the ruin
function api.Touching(list, pos, elapsed)
	for _, f in ipairs(list) do
		if elapsed >= f.LitAt then
			local d = pos - f.Position
			local r = api.Radius(f.Size)
			if d.X * d.X + d.Z * d.Z <= r * r and d.Y >= -4 and d.Y <= api.Height(f.Size) then
				return f
			end
		end
	end
	return nil
end

return api
