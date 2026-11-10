--!nonstrict
-- The showroom the shop fades to. A dummy wearing the class performs its real skills on a second dummy in the middle (the boss
-- place's own class kits run here, see TryoutService). Big and walled, because some skills leap or dash a long way.
-- Orbs are shown on a small dais to one side (OrbSpot), by a dummy that exists only on the viewer's client.
local Kit = require(script.Parent.Kit)
local C, M = Kit.C, Kit.M

local Stage = {}
local O = Vector3.new(0, -400, -4000)
local RADIUS = 86
Stage.Origin = O

function Stage.Build(root)
	local m = Kit.folder(root, "Stage")
	local dark = Kit.rgb(30, 26, 26)
	Kit.disc(m, "Floor", O - Vector3.new(0, 1.5, 0), RADIUS * 2 + 8, 3, dark, M.Marble, { Reflectance = 0.06 })
	-- gold inlay: rings to judge distance by (every 20 studs from the dummy)
	-- largest first, each smaller one a little higher, so every ring shows as a thin gold line
	for i, d in { 160, 120, 80, 40 } do
		Kit.noShadow(Kit.disc(m, "Inlay", O + Vector3.new(0, i * 0.02, 0), d + 0.9, 0.06, C.GoldDeep, M.Metal))
		Kit.noShadow(Kit.disc(m, "InlayIn", O + Vector3.new(0, i * 0.02 + 0.01, 0), d, 0.06, i % 2 == 0 and dark or Kit.rgb(40, 34, 32), M.Marble))
	end
	Kit.noShadow(Kit.disc(m, "Mark", O + Vector3.new(0, 0.12, 0), 9, 0.06, Kit.rgb(92, 66, 26), M.Metal))
	-- the wall, with a pillar and a brazier at every eighth
	Kit.ring(m, "Wall", O, RADIUS * 2, 34, 4, 40, Kit.rgb(44, 38, 38), M.Slate)
	Kit.ring(m, "WallCap", O + Vector3.new(0, 34, 0), RADIUS * 2, 2, 6, 40, C.GoldDeep, M.Metal)
	Kit.ring(m, "WallBase", O, RADIUS * 2 - 3, 3, 3, 40, Kit.rgb(58, 50, 48), M.Marble)
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local at = O + dir * (RADIUS - 5)
		Kit.column(m, "Pillar", at, 38, 6, Kit.rgb(52, 46, 44), M.Marble)
		Kit.column(m, "PillarFoot", at, 2.4, 8.4, C.GoldDeep, M.Metal)
		Kit.column(m, "PillarHead", at + Vector3.new(0, 36, 0), 2.4, 8.4, C.GoldDeep, M.Metal)
		local bowlAt = O + dir * (RADIUS - 13)
		Kit.column(m, "BrazierStem", bowlAt, 4.4, 1, Kit.rgb(40, 36, 36), M.Metal)
		Kit.column(m, "BrazierBowl", bowlAt + Vector3.new(0, 4.4, 0), 1.2, 4, Kit.rgb(40, 36, 36), M.Metal)
		local fire = Kit.noShadow(Kit.ball(m, "Fire", 2.2, bowlAt + Vector3.new(0, 6, 0), Kit.rgb(255, 170, 70), M.Neon, { CanCollide = false, CanQuery = false, CanTouch = false }))
		Kit.light(fire, Kit.rgb(255, 180, 110), 60, 1.6)
		Kit.particles(fire, Kit.rgb(255, 150, 60), 14, 3, 1, 1.4)
		-- a banner between the pillars
		local mid = a + math.pi / 8
		local bdir = Vector3.new(math.cos(mid), 0, math.sin(mid))
		local bat = O + bdir * (RADIUS - 2.4) + Vector3.new(0, 20, 0)
		Kit.detail(Kit.box(m, "Banner", Vector3.new(9, 18, 0.3), CFrame.lookAt(bat, bat - bdir), Kit.rgb(112, 30, 36), M.Fabric))
		Kit.detail(Kit.box(m, "BannerTrim", Vector3.new(9.6, 1, 0.4), CFrame.lookAt(bat + Vector3.new(0, 9.4, 0), bat + Vector3.new(0, 9.4, 0) - bdir), C.Gold, M.Foil))
	end
	-- a soft light over the middle so the dummy and your own effects read clearly
	local key = Kit.box(m, "KeyLight", Vector3.new(1, 1, 1), CFrame.new(O + Vector3.new(0, 44, 0)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local spot = Instance.new("SpotLight")
	spot.Brightness, spot.Range, spot.Angle = 4, 70, 80
	spot.Color = Kit.rgb(255, 232, 196)
	spot.Face = Enum.NormalId.Bottom
	spot.Parent = key
	-- the orb dais, well away from the fighting
	local orbAt = O + Vector3.new(0, 0, -58)
	Kit.disc(m, "OrbDais", orbAt + Vector3.new(0, 0.1, 0), 26, 0.4, Kit.rgb(40, 34, 32), M.Marble)
	Kit.noShadow(Kit.disc(m, "OrbDaisRim", orbAt + Vector3.new(0, 0.32, 0), 27, 0.06, C.GoldDeep, M.Metal))
	Kit.box(m, "OrbSpot", Vector3.new(1, 1, 1), CFrame.new(orbAt + Vector3.new(0, 0.5, 0)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	-- the target dummy stands here (TryoutService puts it up); ArrivalStage is where a fall brings you back
	Kit.box(m, "DummySpot", Vector3.new(1, 1, 1), CFrame.new(O), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local arrival = Kit.arrival(m, CFrame.lookAt(O + Vector3.new(0, 0.2, 30), O + Vector3.new(0, 0.2, 0)), 5)
	arrival.Name = "ArrivalStage"
	return m
end

return Stage
