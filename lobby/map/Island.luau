--!nonstrict
-- TheFallenNoob's private island. You arrive on a small sandbar and board one of the boats (PortalService sails them) to the main island.
-- An original island: a blue-and-white striped lighthouse on a rocky point is the landmark, with the four portals on the terrace below it.
-- The lighthouse, ferries, pier, huts, portal arches and cliffs are Blender meshes (lobby/blender/island.py, kit "Island" in Assets.luau).
local Kit = require(script.Parent.Kit)
local Assets = require(script.Parent.Assets)
local Gates = require(script.Parent.Gates)
local C, M = Kit.C, Kit.M
local Terrain = workspace.Terrain

local Island = {}
-- Far out (12000 studs) so the sea is lost in the haze from the other areas; terrain cannot be hidden per player like parts can.
local O = Vector3.new(-12000, 0, 0)
-- The arrival isle is far out: the ferry crossing is long enough to sail through the mist and lose sight of where you came from.
local ISLE_Z = 1300
local SEA_Z, SEA = 600, 3600

local function at(x, y, z)
	return O + Vector3.new(x, y, z)
end

-- Terrain height under a point, so props sit on the ground whatever the voxels did.
local function groundAt(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Terrain }
	params.IgnoreWater = true
	local hit = workspace:Raycast(at(x, 300, z), Vector3.new(0, -600, 0), params)
	return hit and hit.Position.Y or 5
end

-- FillBlock refuses very large extents, so big fills go down in tiles
local function fillTiles(center, size, material)
	local tile = 900
	local nx, nz = math.ceil(size.X / tile), math.ceil(size.Z / tile)
	for i = 0, nx - 1 do
		for k = 0, nz - 1 do
			local x = center.X - size.X / 2 + (i + 0.5) * size.X / nx
			local z = center.Z - size.Z / 2 + (k + 0.5) * size.Z / nz
			Terrain:FillBlock(CFrame.new(x, center.Y, z), Vector3.new(size.X / nx, size.Y, size.Z / nz), material)
		end
		task.wait()
	end
end

local function land()
	-- ocean to the horizon
	fillTiles(at(0, -20, SEA_Z), Vector3.new(SEA, 44, SEA), Enum.Material.Water)
	-- main island: sand shelf, grass top, hills, rocky point in the north
	-- the sand shelf slopes into the sea in shallow steps (terrain smooths them) instead of standing up as one wall
	-- and keeps going down under the water (the sea is clear, so a sheer underwater side reads as a cliff) onto a sandy floor
	fillTiles(at(0, -38, SEA_Z), Vector3.new(SEA, 8, SEA), Enum.Material.Sand)
	for _, step in { { 5, 184 }, { 4, 191 }, { 3, 197 }, { 2, 203 }, { 0.5, 209 }, { -1.5, 215 }, { -4.5, 222 }, { -9, 232 }, { -14, 246 }, { -20, 262 }, { -26, 282 }, { -31, 304 } } do
		local top, radius = step[1], step[2]
		local bottom = -36
		Terrain:FillCylinder(CFrame.new(at(0, (top + bottom) / 2, -20)), top - bottom, radius, Enum.Material.Sand)
	end
	Terrain:FillCylinder(CFrame.new(at(0, -7, -30)), 30, 150, Enum.Material.Grass)
	Terrain:FillBall(at(-90, -36, -40), 66, Enum.Material.Grass)
	Terrain:FillBall(at(95, -42, -10), 70, Enum.Material.Grass)
	task.wait()
	Terrain:FillBall(at(0, -26, -190), 62, Enum.Material.Rock)
	Terrain:FillBall(at(-46, -26, -176), 40, Enum.Material.Rock)
	Terrain:FillBall(at(48, -26, -172), 40, Enum.Material.Rock)
	-- the arrival isle: a sandy cay with a grassy crown and a rocky back
	for _, step in { { 3, 70 }, { 1, 80 }, { -3, 92 }, { -10, 108 }, { -20, 130 } } do
		Terrain:FillCylinder(CFrame.new(at(0, (step[1] - 36) / 2, ISLE_Z)), step[1] + 36, step[2], Enum.Material.Sand)
	end
	Terrain:FillCylinder(CFrame.new(at(0, -4, ISLE_Z + 14)), 16, 46, Enum.Material.Grass)
	Terrain:FillBall(at(-30, -20, ISLE_Z + 60), 34, Enum.Material.Rock)
	Terrain:FillBall(at(34, -22, ISLE_Z + 54), 30, Enum.Material.Rock)
	task.wait(2) -- terrain collision catches up a moment after the fill; props below measure the ground
end

-- A pier from `from` to `to` (deck top at their height), in 12-stud segments.
local function jetty(parent, from, to)
	local dir = to - from
	local count = math.max(1, math.floor(dir.Magnitude / 12 + 0.5))
	local step = dir / count
	for i = 0, count - 1 do
		local p = from + step * (i + 0.5)
		local seg = Assets.Get("IslandPier")
		seg:PivotTo(CFrame.lookAt(p, p + dir))
		seg.Name = "Pier"
		seg.Parent = parent
	end
end

-- The lighthouse, door toward the terrace. Its lamp (73 up) glows, and two beams sweep round (UnfairSpin on the client).
local LAMP_Y = 72.5
local function lighthouse(parent, base)
	local m = Kit.model(parent, "Lighthouse")
	local tower = Assets.Get("IslandLighthouse")
	tower:PivotTo(CFrame.lookAt(base, base + Vector3.new(0, 0, 1)))
	tower.Name = "Tower"
	tower.Parent = m
	local lampPos = base + Vector3.new(0, LAMP_Y, 0)
	local lamp = Kit.noShadow(Kit.ball(m, "Lamp", 4.2, lampPos, C.GoldPale, M.Neon))
	Kit.light(lamp, Kit.rgb(255, 230, 170), 90, 2.5)
	-- the beams: a hub whose local Z is world up, so the client's spin turns it round the tower
	local beams = Kit.model(m, "Beams")
	local hub = Kit.box(beams, "Hub", Vector3.new(1, 1, 1), CFrame.fromMatrix(lampPos, Vector3.xAxis, -Vector3.zAxis), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	beams.PrimaryPart = hub
	for _, face in { Enum.NormalId.Right, Enum.NormalId.Left } do
		local spot = Instance.new("SpotLight")
		spot.Face, spot.Range, spot.Angle, spot.Brightness = face, 60, 28, 4
		spot.Color = Kit.rgb(255, 236, 190)
		spot.Parent = hub
	end
	beams:SetAttribute("SpinSpeed", 0.9)
	Kit.tag(beams, "UnfairSpin")
	return m
end

-- A ferry: the Blender hull and rig welded to an invisible Root deck (PortalService moves Root), and six Seats on its benches.
local function boat(parent, name, dock)
	local m = Kit.model(parent, name)
	local hull = Kit.box(m, "Root", Vector3.new(11, 1, 26), dock, Kit.rgb(92, 58, 34), M.WoodPlanks, { Transparency = 1 })
	local look = Assets.Get("IslandBoat")
	look:PivotTo(dock)
	for _, part in look:GetChildren() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			part.CanCollide = false
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = hull, part
			w.Parent = part
			part.Parent = m
		end
	end
	look:Destroy()
	for _, z in { -6, 1.5, 8 } do
		for _, s in { -1, 1 } do
			local seat = Instance.new("Seat")
			seat.Name = "BoatSeat"
			seat.Size, seat.CFrame = Vector3.new(3, 0.8, 3), dock * CFrame.new(s * 2.6, 1.1, z)
			seat.Transparency = 1
			seat.TopSurface, seat.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			seat.CanTouch = false -- only PortalService seats people, so nobody sits by bumping into it
			seat.Anchored = false
			seat.Parent = m
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = hull, seat
			w.Parent = seat
		end
	end
	m.PrimaryPart = hull
	m:SetAttribute("Boat", true)
	return m
end

local function portals(parent)
	-- the four portals sit on a stone terrace below the lighthouse: giant scallops, top valve raised, the portal glowing in the gape
	local center = at(0, groundAt(0, -130) + 1.2, -130)
	-- the terrace stands on rock, not grass (terrain grass blades would poke through the slab)
	local lo, hi = center - Vector3.new(66, 20, 26), center + Vector3.new(66, 8, 26)
	Terrain:ReplaceMaterial(Region3.new(lo, hi):ExpandToGrid(4), 4, Enum.Material.Grass, Enum.Material.Ground)
	Kit.box(parent, "Terrace", Vector3.new(124, 6, 44), CFrame.new(center - Vector3.new(0, 3, 0)), C.StoneWarm, M.Limestone)
	local spots = { -46, -15.5, 15.5, 46 }
	for i, x in spots do
		local m = Kit.model(parent, "Portal" .. i)
		local base = CFrame.lookAt(center + Vector3.new(x, 0, -8), center + Vector3.new(x * 0.6, 0, 60))
		local shell = Assets.Get("IslandShellPortal")
		shell:ScaleTo(1.25)
		shell:PivotTo(base)
		shell.Name = "Shell"
		shell.Parent = m
		local face = Gates.glow(shell, Kit.rgb(70, 200, 225), 0.35, 24)
		if face then
			-- set back into the gape between the valves, so the shell frames the glow instead of hiding behind it
			face.Size *= Vector3.new(0.8, 0.75, 1)
			face.CFrame *= CFrame.new(0, -0.8, 3.2)
			face.Name = "Face"
			face.CanTouch = true
			Kit.nameplate(face, "Portal " .. i, "Coming soon", Kit.rgb(200, 240, 250), 12, 70, Kit.PLATE.Island)
			face:SetAttribute("ComingSoon", "FallenNoob")
			Kit.tag(face, "UnfairComingSoon")
		end
	end
end

function Island.Build(root)
	local m = Kit.folder(root, "Island")
	m:SetAttribute("Origin", O) -- PortalService reads it (the island's swim-out bounds, the boats' route)
	fillTiles(at(0, 0, SEA_Z), Vector3.new(SEA + 200, 300, SEA + 200), Enum.Material.Air)
	land()

	-- piers
	local pierY = groundAt(0, ISLE_Z - 40) + 0.4
	jetty(m, at(0, pierY + 0.3, ISLE_Z - 48), at(0, pierY + 0.3, ISLE_Z - 108))
	jetty(m, at(0, pierY + 0.3, 206), at(0, pierY + 0.3, 146))

	-- boats wait off the isle's pier, nose toward the island, each in its own lane all the way across (Shore = where it stops),
	-- so they never cross or bump into each other or the piers
	local boats = Kit.folder(m, "Boats")
	for i, x in { -26, 26, 0 } do
		local dock = CFrame.new(at(x, 1.8, ISLE_Z - 130 + (x == 0 and -10 or 0)))
		local b = boat(boats, "Boat" .. i, dock)
		b:SetAttribute("Shore", CFrame.new(at(x, 1.8, x == 0 and 232 or 214)))
	end

	local board = Kit.box(m, "BoardingSpot", Vector3.new(6, 1, 6), CFrame.new(at(0, pierY + 0.6, ISLE_Z - 80)), C.Gold, M.Metal, { CanCollide = false })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BoardPrompt"
	prompt.ActionText = "Board a boat"
	prompt.ObjectText = "Ferry to the island"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0
	prompt.Parent = board
	Kit.nameplate(board, "Ferry", "A boat leaves every few seconds", C.White, 7, 60)

	lighthouse(m, at(0, groundAt(0, -192) - 1, -192))
	portals(m)

	-- beach huts round the grass, facing the middle of the island
	for _, spot in { { 78, 40 }, { -84, 20 }, { 104, -52 } } do
		local x, z = spot[1], spot[2]
		local p = at(x, groundAt(x, z) - 0.6, z)
		local hut = Assets.Get("IslandHut")
		hut:PivotTo(CFrame.lookAt(p, at(0, p.Y - O.Y, -20)))
		hut.Name = "Hut"
		hut.Parent = m
	end
	-- sea cliffs: round the rocky point behind the lighthouse and standing out of the water along the shore
	for i, spot in { { -64, -168, 1.3, 0.4 }, { 66, -158, 1.2, 2.2 }, { -30, -236, 1.5, 4.0 }, { 40, -240, 1.1, 1.0 }, { 196, -20, 1.0, 3.0 }, { -204, 30, 1.2, 5.0 }, { 150, 120, 0.8, 0.8 }, { -150, -120, 0.9, 2.6 } } do
		local x, z, scale, turn = spot[1], spot[2], spot[3], spot[4]
		local cliff = Assets.Get(i % 2 == 0 and "IslandCliff2" or "IslandCliff1")
		cliff:ScaleTo(scale)
		cliff:PivotTo(CFrame.new(at(x, groundAt(x, z) - 4, z)) * CFrame.Angles(0, turn, 0))
		cliff.Name = "Cliff"
		cliff.Parent = m
	end

	-- island dressing: palms round the shore, a few rocks and a path from the beach up to the terrace
	local r = Kit.R
	local flora = Kit.folder(m, "Flora")
	for _ = 1, 42 do
		local a = r:NextNumber(0, 6.28)
		local d = r:NextNumber(92, 158)
		local x, z = math.cos(a) * d, math.sin(a) * d - 20
		-- clear of the path, the terrace, the way back (-34, 112) and the huts
		local near = false
		for _, spot in { { -34, 112, 26 }, { 78, 40, 20 }, { -84, 20, 20 }, { 104, -52, 20 } } do
			if (Vector2.new(x, z) - Vector2.new(spot[1], spot[2])).Magnitude < spot[3] then
				near = true
			end
		end
		if math.abs(x) > 16 and not (z < -90 and math.abs(x) < 80) and not near then
			Kit.palm(flora, at(x, groundAt(x, z) - 0.5, z), r:NextNumber(24, 40))
		end
	end
	-- no grass blades through the path stones: the strip under the path is plain ground
	local lo, hi = at(-8, -40, -112), at(8, 24, 140)
	Terrain:ReplaceMaterial(Region3.new(lo, hi):ExpandToGrid(4), 4, Enum.Material.Grass, Enum.Material.Ground)
	for z = 132, -106, -8 do
		local sx = r:NextNumber(-1.5, 1.5)
		Kit.noShadow(Kit.box(flora, "PathStone", Vector3.new(r:NextNumber(8, 12), 0.5, 6), CFrame.new(at(sx, groundAt(sx, z) + 0.15, z)) * CFrame.Angles(0, r:NextNumber(-0.15, 0.15), 0), C.StoneWarm, M.Slate))
	end
	-- arrival, on the isle, looking down the pier at the boats; the island is out there somewhere in the mist
	Kit.arrival(m, CFrame.lookAt(at(0, pierY + 1, ISLE_Z - 20), at(0, pierY + 1, 0)), 10).Name = "ArrivalIsland"
	-- the isle: palms, a hut by the pier, a couple of rocks
	for _ = 1, 16 do
		local a = r:NextNumber(0, 6.28)
		local d = r:NextNumber(30, 72)
		local x, z = math.cos(a) * d, ISLE_Z + math.sin(a) * d
		if math.abs(x) > 14 or z > ISLE_Z then
			Kit.palm(flora, at(x, groundAt(x, z) - 0.5, z), r:NextNumber(22, 36))
		end
	end
	local hut = Assets.Get("IslandHut")
	hut:PivotTo(CFrame.lookAt(at(-30, groundAt(-30, ISLE_Z - 24) - 0.6, ISLE_Z - 24), at(0, 0, ISLE_Z - 60)))
	hut.Name = "Hut"
	hut.Parent = m
	for i, spot in { { -60, ISLE_Z + 50, 0.9, 1.0 }, { 58, ISLE_Z + 44, 0.7, 3.4 } } do
		local cliff = Assets.Get(i % 2 == 0 and "IslandCliff2" or "IslandCliff1")
		cliff:ScaleTo(spot[3])
		cliff:PivotTo(CFrame.new(at(spot[1], groundAt(spot[1], spot[2]) - 4, spot[2])) * CFrame.Angles(0, spot[4], 0))
		cliff.Name = "Cliff"
		cliff.Parent = m
	end
	-- mist lying on the water between the two: banks of slow fog the ferries sail through
	local mist = Kit.folder(m, "Mist")
	for z = 330, ISLE_Z - 180, 110 do
		for x = -180, 180, 90 do
			local bank = Kit.detail(Kit.box(mist, "Bank", Vector3.new(80, 6, 80), CFrame.new(at(x + r:NextNumber(-20, 20), 6, z + r:NextNumber(-20, 20))), nil, nil, { Transparency = 1, CanQuery = false, CanTouch = false }))
			local e = Instance.new("ParticleEmitter")
			e.Name = "Fog"
			e.Color = ColorSequence.new(Kit.rgb(232, 240, 246))
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(0.7, 0.6), NumberSequenceKeypoint.new(1, 1) })
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 26), NumberSequenceKeypoint.new(1, 44) })
			e.Lifetime = NumberRange.new(12, 18)
			e.Rate = 0.9
			e.Speed = NumberRange.new(0.5, 1.5)
			e.SpreadAngle = Vector2.new(180, 10)
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-4, 4)
			e.LightInfluence = 0.6
			e.Parent = bank
		end
	end

	-- where boats let you off, and the way back
	local landing = Kit.arrival(m, CFrame.lookAt(at(0, groundAt(0, 134) + 1, 134), at(0, 20, -130)), 4)
	landing.Name = "BoatLanding"
	local exitY = groundAt(-34, 112) + 8.6
	Gates.returnGate(m, CFrame.lookAt(at(-34, exitY - 8.6, 112), at(0, exitY - 8.6, 134)), "GateReturnIsland")
	return m
end

return Island
