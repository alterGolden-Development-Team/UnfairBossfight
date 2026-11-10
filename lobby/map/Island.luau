--!nonstrict
-- TheFallenNoob's private island. You arrive on a small sandbar and board one of the boats (PortalService sails them) to the main island.
-- An original island: a blue-and-white striped lighthouse on a rocky point is the landmark, with the four portals on the terrace below it.
local Kit = require(script.Parent.Kit)
local C, M = Kit.C, Kit.M
local Terrain = workspace.Terrain

local Island = {}
-- Far out (12000 studs) so the sea is lost in the haze from the other areas; terrain cannot be hidden per player like parts can.
local O = Vector3.new(-12000, 0, 0)

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

local function land()
	-- ocean to the horizon
	Terrain:FillBlock(CFrame.new(at(0, -20, 0)), Vector3.new(1600, 44, 1600), Enum.Material.Water)
	-- main island: sand shelf, grass top, hills, rocky point in the north
	Terrain:FillCylinder(CFrame.new(at(0, -10, -20)), 30, 190, Enum.Material.Sand)
	Terrain:FillCylinder(CFrame.new(at(0, -7, -30)), 30, 150, Enum.Material.Grass)
	Terrain:FillBall(at(-90, -36, -40), 66, Enum.Material.Grass)
	Terrain:FillBall(at(95, -42, -10), 70, Enum.Material.Grass)
	task.wait()
	Terrain:FillBall(at(0, -26, -190), 62, Enum.Material.Rock)
	Terrain:FillBall(at(-46, -26, -176), 40, Enum.Material.Rock)
	Terrain:FillBall(at(48, -26, -172), 40, Enum.Material.Rock)
	-- beach apron facing the boats
	Terrain:FillBall(at(0, -56, 150), 66, Enum.Material.Sand)
	-- arrival sandbar
	Terrain:FillCylinder(CFrame.new(at(0, -10, 390)), 28, 58, Enum.Material.Sand)
	task.wait(2) -- terrain collision catches up a moment after the fill; props below measure the ground
end

local function jetty(parent, from, to, width)
	local dir = to - from
	local count = math.floor(dir.Magnitude / 4)
	local right = dir.Unit:Cross(Vector3.yAxis)
	for i = 0, count do
		local p = from + dir.Unit * (i * 4)
		Kit.box(parent, "Plank", Vector3.new(width, 0.6, 3.6), CFrame.lookAt(p, p + dir), Kit.R:NextNumber() > 0.5 and C.Plank or Kit.rgb(122, 88, 56), M.WoodPlanks)
		if i % 3 == 0 then
			for _, side in { -1, 1 } do
				Kit.column(parent, "Piling", p + right * side * (width / 2) - Vector3.new(0, 14, 0), 17, 1.5, C.WoodDark, M.Wood)
			end
		end
	end
end

-- A lighthouse with broad blue and white bands. Original shape: tapered tower, gallery, glass lamp room and cap.
local function lighthouse(parent, base)
	local m = Kit.model(parent, "Lighthouse")
	local bands = 8
	local bandHeight = 7
	local blue, white = Kit.rgb(34, 92, 178), Kit.rgb(244, 244, 240)
	Kit.column(m, "Foot", base, 3, 34, C.StoneDark, M.Slate)
	for i = 0, bands - 1 do
		local d = 26 - i * 1.5
		Kit.column(m, "Band", base + Vector3.new(0, 3 + i * bandHeight, 0), bandHeight, d, i % 2 == 0 and blue or white, M.SmoothPlastic)
	end
	local top = base + Vector3.new(0, 3 + bands * bandHeight, 0)
	Kit.column(m, "Gallery", top, 1.6, 24, C.StoneDark, M.Metal)
	for i = 1, 16 do
		local a = i / 16 * 6.28
		Kit.noShadow(Kit.column(m, "Rail", top + Vector3.new(math.cos(a) * 11.2, 1.6, math.sin(a) * 11.2), 4, 0.5, C.StoneDark, M.Metal))
	end
	Kit.column(m, "LampRoom", top + Vector3.new(0, 1.6, 0), 9, 13, Kit.rgb(190, 225, 240), M.Glass, { Transparency = 0.45 })
	local lamp = Kit.noShadow(Kit.ball(m, "Lamp", 7, top + Vector3.new(0, 6, 0), C.GoldPale, M.Neon))
	Kit.light(lamp, Kit.rgb(255, 230, 170), 90, 2.5)
	Kit.column(m, "Cap", top + Vector3.new(0, 10.6, 0), 3, 16, blue, M.Metal)
	Kit.ball(m, "Finial", 3.4, top + Vector3.new(0, 15, 0), C.GoldDeep, M.Metal)
	return m
end

local function boat(parent, name, dock)
	local m = Kit.model(parent, name)
	local hull = Kit.box(m, "Root", Vector3.new(11, 1, 26), dock, Kit.rgb(92, 58, 34), M.WoodPlanks)
	local function welded(part)
		part.Anchored = false
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = hull, part
		w.Parent = part
		return part
	end
	for _, s in { -1, 1 } do
		welded(Kit.box(m, "Side", Vector3.new(1, 3.4, 26), dock * CFrame.new(s * 5.6, 1.7, 0), Kit.rgb(126, 80, 46), M.WoodPlanks))
	end
	welded(Kit.box(m, "Stern", Vector3.new(11, 3.4, 1), dock * CFrame.new(0, 1.7, 13), Kit.rgb(126, 80, 46), M.WoodPlanks))
	welded(Kit.wedge(m, "Bow", Vector3.new(11, 3.4, 8), dock * CFrame.new(0, 1.7, -17) * CFrame.Angles(0, math.rad(180), 0), Kit.rgb(126, 80, 46), M.WoodPlanks))
	welded(Kit.wedge(m, "BowFloor", Vector3.new(11, 1, 8), dock * CFrame.new(0, 0, -17) * CFrame.Angles(0, math.rad(180), 0), Kit.rgb(92, 58, 34), M.WoodPlanks))
	welded(Kit.box(m, "Mast", Vector3.new(1, 26, 1), dock * CFrame.new(0, 13, -4), C.WoodDark, M.Wood))
	welded(Kit.box(m, "Yard", Vector3.new(16, 0.8, 0.8), dock * CFrame.new(0, 23, -3.6), C.WoodDark, M.Wood))
	local sail = welded(Kit.box(m, "Sail", Vector3.new(15, 16, 0.3), dock * CFrame.new(0, 14.6, -3.4), Kit.rgb(240, 232, 214), M.Fabric))
	sail.CanCollide = false
	for _, z in { -6, 1.5, 8 } do
		for _, s in { -1, 1 } do
			local seat = Instance.new("Seat")
			seat.Name = "BoatSeat"
			seat.Size, seat.CFrame = Vector3.new(3, 0.8, 3), dock * CFrame.new(s * 2.6, 1, z)
			seat.Color, seat.Material = C.Plank, M.Wood
			seat.TopSurface, seat.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			seat.CanTouch = false -- only PortalService seats people, so nobody sits by bumping into it
			seat.Anchored = false
			seat.Parent = m
			welded(seat)
		end
	end
	m.PrimaryPart = hull
	m:SetAttribute("Boat", true)
	return m
end

local function portals(parent)
	-- the four portals sit on a stone terrace below the lighthouse
	local center = at(0, groundAt(0, -130) + 1.2, -130)
	Kit.box(parent, "Terrace", Vector3.new(124, 6, 44), CFrame.new(center - Vector3.new(0, 3, 0)), C.StoneWarm, M.Limestone)
	local spots = { -48, -16, 16, 48 }
	for i, x in spots do
		local m = Kit.model(parent, "Portal" .. i)
		local base = CFrame.lookAt(center + Vector3.new(x, 0, -8), center + Vector3.new(x * 0.6, 0, 60))
		local r = Kit.R
		local count = 13
		local arch = base * CFrame.new(0, 10, 0)
		for k = 0, count do
			local a = math.rad(-14 + k / count * 208)
			local size = r:NextNumber(3.6, 5.2)
			Kit.rock(m, (arch * CFrame.new(math.cos(a) * 10, math.sin(a) * 10, 0)).Position, Vector3.new(size, size, size), C.Rock, M.Slate)
		end
		local face = Kit.cyl(m, "Face", 0.4, 18.5, arch * CFrame.Angles(0, math.rad(90), 0), Kit.rgb(70, 190, 215), M.Neon, { Transparency = 0.15, CanCollide = false })
		Kit.particles(face, Kit.rgb(190, 240, 250), 14, 2, 1.6, 0.8)
		Kit.nameplate(face, "Portal " .. i, "Coming soon", Kit.rgb(200, 240, 250), 12, 70)
		face:SetAttribute("ComingSoon", "FallenNoob")
		Kit.tag(face, "UnfairComingSoon")
	end
end

function Island.Build(root)
	local m = Kit.folder(root, "Island")
	m:SetAttribute("Origin", O) -- PortalService reads it (the island's swim-out bounds, the boats' route)
	Terrain:FillBlock(CFrame.new(at(0, 0, 0)), Vector3.new(1800, 300, 1800), Enum.Material.Air)
	land()

	-- piers
	local pierY = groundAt(0, 388) + 0.4
	jetty(m, at(0, pierY, 356), at(0, pierY, 300), 9)
	jetty(m, at(0, pierY, 206), at(0, pierY, 146), 9)

	-- boats wait at the sandbar pier: three, nose toward the island
	local boats = Kit.folder(m, "Boats")
	for i, x in { -18, 18, 54 } do
		boat(boats, "Boat" .. i, CFrame.new(at(x, 1.8, 296)))
	end

	local board = Kit.box(m, "BoardingSpot", Vector3.new(6, 1, 6), CFrame.new(at(0, pierY + 0.6, 318)), C.Gold, M.Metal, { CanCollide = false })
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

	-- island dressing: palms round the shore, a few rocks and a path from the beach up to the terrace
	local r = Kit.R
	local flora = Kit.folder(m, "Flora")
	for _ = 1, 42 do
		local a = r:NextNumber(0, 6.28)
		local d = r:NextNumber(92, 158)
		local x, z = math.cos(a) * d, math.sin(a) * d - 20
		if math.abs(x) > 16 and not (z < -90 and math.abs(x) < 80) then
			Kit.palm(flora, at(x, groundAt(x, z) - 0.5, z), r:NextNumber(24, 40))
		end
	end
	for z = 132, -106, -8 do
		local sx = r:NextNumber(-1.5, 1.5)
		Kit.noShadow(Kit.box(flora, "PathStone", Vector3.new(r:NextNumber(8, 12), 0.5, 6), CFrame.new(at(sx, groundAt(sx, z) + 0.15, z)) * CFrame.Angles(0, r:NextNumber(-0.15, 0.15), 0), C.StoneWarm, M.Slate))
	end
	-- arrival, on the sandbar, looking at the boats and the far lighthouse
	Kit.arrival(m, CFrame.lookAt(at(0, pierY + 1, 388), at(0, pierY + 1, 0)), 10).Name = "ArrivalIsland"

	-- where boats let you off, and the way back
	local landing = Kit.arrival(m, CFrame.lookAt(at(0, groundAt(0, 134) + 1, 134), at(0, 20, -130)), 4)
	landing.Name = "BoatLanding"
	local exitY = groundAt(-34, 112) + 8.6
	local exitCF = CFrame.lookAt(at(-34, exitY, 112), at(0, exitY, 134))
	Kit.noShadow(Kit.cyl(m, "ExitFace", 0.4, 18, exitCF * CFrame.Angles(0, math.rad(90), 0), Kit.rgb(140, 190, 255), M.Neon, { Transparency = 0.2 }))
	Kit.spinRing(m, exitCF * CFrame.new(0, 0, -0.5), 9.5, 20, C.Sand, M.Sand, 0.3, Vector3.new(1.6, 1.1, 1.1))
	Kit.trigger(m, Vector3.new(16, 18, 4), exitCF * CFrame.new(0, 0, -1), "Hub")
	local label = Kit.box(m, "ExitLabel", Vector3.new(1, 1, 1), exitCF * CFrame.new(0, -7, 0), nil, nil, { Transparency = 1, CanCollide = false })
	Kit.nameplate(label, "Back to the Sanctum", "", C.White, 2, 60)
	return m
end

return Island
