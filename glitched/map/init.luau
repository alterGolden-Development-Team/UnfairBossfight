--!nonstrict
--[[
 Builds the glitched place into Workspace.World (run in that place's Studio window, edit mode):
   require(game.ServerStorage.MapBuilder).Build()
 A checker platform in the void (Spawn, and a lone glowing door: the way back to the lobby), a long winding road of broken slabs
 (World.Road, which the client makes shiver), broken pillars, arches and floating cubes along it, and at the far end a round platform
 where the glitched man sits on a broken bench (World.GlitchedMan: TalkPrompt, ContactZone).
 Blender pieces: the Void kit (glitched/blender/void.py) for the road, the city, the clock, trees, stairs, doors and the dais, and the
 Glitch kit (lobby/blender/realm.py) for the bench; plain parts stand in if it
 cannot be loaded. Everything is black, white and grey.
]]
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local api = {}
local GLITCH_KIT = 118962804006333 -- GlitchBench, GlitchPillar, GlitchArch (lobby/blender/realm.py)
local VOID_KIT = 110711929130764 -- the Void kit (glitched/blender/void.py): road slabs, towers, clock, trees, stair, monoliths, door, dais, halo
local R = Random.new(404)
local WHITE, BLACK, GREY = Color3.fromRGB(240, 240, 242), Color3.fromRGB(12, 12, 14), Color3.fromRGB(120, 120, 124)
local SKIN = {
	White = { Enum.Material.SmoothPlastic, WHITE }, Black = { Enum.Material.SmoothPlastic, BLACK }, Glow = { Enum.Material.Neon, WHITE },
	Static = { Enum.Material.Neon, GREY },
}

local function box(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Anchored = true
	p.Color, p.Material = color or GREY, material or Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in props or {} do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function folder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- the Glitch kit, split into pieces (same naming as MeshKit: <Piece>__<Role>_<S?><n>, <Piece>__Pivot)
local pieces = {}
local function loadKit(id)
	local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. id)
	if not ok or not objects or not objects[1] then
		warn("[GlitchedMap] could not load kit " .. id .. ": " .. tostring(objects))
		return
	end
	local pivots, parts = {}, {}
	for _, d in objects[1]:GetDescendants() do
		if d:IsA("MeshPart") then
			local piece, rest = d.Name:match("^(.-)__(.+)$")
			if piece then
				if rest:match("^Pivot") then
					pivots[piece] = d.Position
				else
					local role, solid = rest:match("^(%a+)_(S?)%d+")
					local skin = SKIN[role] or SKIN.White
					d.Material, d.Color, d.TextureID = skin[1], skin[2], ""
					d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, solid == "S", solid == "S", false
					d.Name = role
					parts[piece] = parts[piece] or {}
					table.insert(parts[piece], d)
				end
			end
		end
	end
	for piece, list in parts do
		local m = Instance.new("Model")
		m.Name = piece
		for _, p in list do
			p.Parent = m
		end
		m.WorldPivot = CFrame.new(pivots[piece] or Vector3.zero)
		pieces[piece] = m
	end
end

local function place(parent, name, cf, scale)
	local template = pieces[name]
	if not template then
		return nil
	end
	local m = template:Clone()
	if scale and scale ~= 1 then
		m:ScaleTo(scale)
	end
	m:PivotTo(cf)
	m.Parent = parent
	return m
end

-- the road's centre line: from the start platform out to the man, winding a little
local LENGTH = 560
local function roadPoint(t)
	local z = -36 - t * LENGTH
	return Vector3.new(math.sin(t * math.pi * 2.2) * 34, 0, z)
end

local function lighting()
	for _, c in Lighting:GetChildren() do
		if c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("PostEffect") or c:IsA("Clouds") then
			c:Destroy()
		end
	end
	Lighting.ClockTime = 0
	Lighting.Brightness = 1.6
	Lighting.Ambient = Color3.fromRGB(120, 120, 124)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 144)
	Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0.3, 0
	Lighting.GlobalShadows = true
	local atmo = Instance.new("Atmosphere")
	atmo.Density, atmo.Offset = 0.42, 0.1
	atmo.Color, atmo.Decay = Color3.fromRGB(150, 150, 154), Color3.fromRGB(40, 40, 44)
	atmo.Glare, atmo.Haze = 0, 2.5
	atmo.Parent = Lighting
	local sky = Instance.new("Sky")
	sky.CelestialBodiesShown = false
	sky.StarCount = 0
	sky.Parent = Lighting
	workspace.FallenPartsDestroyHeight = -400
end

local function checker(parent, center, cols, rows, tile, name)
	for i = 0, cols - 1 do
		for j = 0, rows - 1 do
			local x = center.X + (i - (cols - 1) / 2) * tile
			local z = center.Z + (j - (rows - 1) / 2) * tile
			local dark = (i + j) % 2 == 0
			box(parent, name or "Tile", Vector3.new(tile, 2, tile), CFrame.new(x, center.Y - 1 + R:NextNumber(-0.15, 0.15), z), dark and BLACK or WHITE)
		end
	end
end

function api.Build()
	assert(not workspace:FindFirstChild("World") or workspace.World:GetAttribute("Place") == "Glitched", "this does not look like the glitched place")
	local old = workspace:FindFirstChild("World")
	if old then
		old:Destroy()
	end
	for _, c in workspace:GetChildren() do
		if c.Name == "Baseplate" or c:IsA("SpawnLocation") then
			c:Destroy()
		end
	end
	loadKit(GLITCH_KIT)
	loadKit(VOID_KIT)
	lighting()
	local world = folder(workspace, "World")
	world:SetAttribute("Place", "Glitched")

	-- start: a checker platform, the spawn, and the way back
	local start = folder(world, "Start")
	checker(start, Vector3.new(0, 0, 0), 6, 6, 8)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.5, 6)
	spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 0
	spawn.Color, spawn.Material = WHITE, Enum.Material.Neon
	spawn.Transparency = 0.6
	spawn.Parent = start
	-- the way back: a lone door frame in the void, its doorway lit (tag GlitchExit)
	local door = place(start, "VoidDoor", CFrame.lookAt(Vector3.new(0, 0, 30), Vector3.new(0, 0, 0)), 1.2)
	local exit = door and door:FindFirstChild("Glow")
	if exit then
		exit.CanTouch = true
		exit.Transparency = 0.15
	else
		exit = box(start, "Exit", Vector3.new(12, 16, 2), CFrame.new(0, 8, 30), WHITE, Enum.Material.Neon, { Transparency = 0.55, CanCollide = false, CanQuery = false })
	end
	CollectionService:AddTag(exit, "GlitchExit")
	local sign = Instance.new("BillboardGui")
	sign.Size, sign.StudsOffset, sign.MaxDistance = UDim2.fromOffset(300, 40), Vector3.new(0, 11, 0), 80
	sign.Parent = exit
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Font, label.TextSize, label.TextColor3, label.TextStrokeTransparency = Enum.Font.Code, 22, WHITE, 0
	label.Text = "B4CK T0 TH3 S4NCTUM"
	label.Parent = sign

	-- the road: broken slabs (VoidSlab1..3) end to end along the winding line, each a little tilted and offset. They overlap, so it
	-- is walkable all the way, but every seam is a crack and pixels drift off the edges. Plain tiles stand in without the kit.
	local road = folder(world, "Road")
	local step = 15
	local count = math.floor(LENGTH / step)
	for s = 0, count do
		local t = s / count
		local p = roadPoint(t)
		local ahead = roadPoint(math.min(1, t + 0.002)) - p
		local cf = CFrame.lookAt(p, p + Vector3.new(ahead.X, 0, ahead.Z))
		local jiggle = CFrame.new(R:NextNumber(-0.8, 0.8), R:NextNumber(-0.35, 0.1), 0) * CFrame.Angles(R:NextNumber(-0.015, 0.015), R:NextNumber(-0.08, 0.08), R:NextNumber(-0.02, 0.02))
		local slab = place(road, "VoidSlab" .. (s % 3 + 1), cf * jiggle * CFrame.Angles(0, s % 2 == 0 and 0 or math.pi, 0), 1.05)
		if not slab then
			box(road, "Tile", Vector3.new(14, 2, step + 1), cf * CFrame.new(0, -1, 0), s % 2 == 0 and BLACK or WHITE)
		end
	end

	-- the void round the road: a broken city, a shattered clock, trees hanging from nothing, stairs and doors to nowhere
	local decor = folder(world, "Decor")
	for s = 1, 14 do -- towers on both sides, rising from far below and leaning
		local p = roadPoint(s / 15)
		local side = s % 2 == 0 and 1 or -1
		local at = p + Vector3.new(side * R:NextNumber(70, 150), R:NextNumber(-140, -60), R:NextNumber(-30, 30))
		place(decor, "VoidTower", CFrame.new(at) * CFrame.Angles(R:NextNumber(-0.12, 0.12), R:NextNumber(0, 6), R:NextNumber(-0.12, 0.12)), R:NextNumber(1.3, 2.6))
	end
	for s = 1, 4 do -- the broken clock hanging over the road
		local p = roadPoint(s / 5)
		local side = s % 2 == 0 and 1 or -1
		place(decor, "VoidClock", CFrame.lookAt(p + Vector3.new(side * 60, 40 + s * 6, 0), p + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, R:NextNumber(-0.4, 0.4)), R:NextNumber(1.1, 1.8))
	end
	for _ = 1, 16 do -- trees upside down, roots in the air
		local p = roadPoint(R:NextNumber(0.03, 0.97))
		local side = R:NextNumber() < 0.5 and -1 or 1
		place(decor, "VoidTree", CFrame.new(p + Vector3.new(side * R:NextNumber(24, 70), R:NextNumber(40, 70), R:NextNumber(-10, 10))) * CFrame.Angles(R:NextNumber(-0.15, 0.15), R:NextNumber(0, 6), R:NextNumber(-0.15, 0.15)), R:NextNumber(0.9, 1.6))
	end
	for s = 1, 6 do -- monoliths right beside the road
		local t = (s - 0.5) / 6
		local p = roadPoint(t)
		local ahead = roadPoint(math.min(1, t + 0.01)) - p
		local cf = CFrame.lookAt(p, p + Vector3.new(ahead.X, 0, ahead.Z))
		place(decor, "VoidMonolith", cf * CFrame.new((s % 2 == 0 and 1 or -1) * R:NextNumber(14, 22), -6, R:NextNumber(-8, 8)) * CFrame.Angles(0, R:NextNumber(-0.4, 0.4), R:NextNumber(-0.08, 0.08)), R:NextNumber(0.9, 1.4))
	end
	for s = 1, 3 do -- spiral stairs that stop in the air
		local p = roadPoint(s / 4)
		local side = s % 2 == 0 and -1 or 1
		place(decor, "VoidStair", CFrame.new(p + Vector3.new(side * R:NextNumber(34, 50), -10, 0)) * CFrame.Angles(0, R:NextNumber(0, 6), 0), R:NextNumber(1.2, 1.6))
	end
	for _ = 1, 6 do -- more doors, floating, leading nowhere
		local p = roadPoint(R:NextNumber(0.1, 0.9))
		local side = R:NextNumber() < 0.5 and -1 or 1
		place(decor, "VoidDoor", CFrame.new(p + Vector3.new(side * R:NextNumber(40, 90), R:NextNumber(-10, 40), 0)) * CFrame.Angles(R:NextNumber(-0.5, 0.5), R:NextNumber(0, 6), R:NextNumber(-0.5, 0.5)), R:NextNumber(0.8, 1.3))
	end
	for _ = 1, 90 do -- loose pixels everywhere
		local t = R:NextNumber()
		local p = roadPoint(t) + Vector3.new(R:NextNumber(-90, 90), R:NextNumber(-30, 60), R:NextNumber(-20, 20))
		if math.abs(p.X - roadPoint(t).X) > 18 then
			local size = R:NextNumber(1, 7)
			box(decor, "Cube", Vector3.new(size, size, size), CFrame.new(p) * CFrame.Angles(R:NextNumber(0, 6), R:NextNumber(0, 6), R:NextNumber(0, 6)), R:NextNumber() < 0.5 and WHITE or BLACK, R:NextNumber() < 0.15 and Enum.Material.Neon or Enum.Material.SmoothPlastic, { CanCollide = false })
		end
	end
	for _ = 1, 14 do -- dead screens
		local t = R:NextNumber(0.05, 0.95)
		local p = roadPoint(t) + Vector3.new(R:NextNumber(-60, 60), R:NextNumber(8, 30), 0)
		if math.abs(p.X - roadPoint(t).X) > 20 then
			box(decor, "Screen", Vector3.new(R:NextNumber(8, 20), R:NextNumber(5, 12), 0.4), CFrame.lookAt(p, roadPoint(t) + Vector3.new(0, 6, 0)), WHITE, Enum.Material.Neon, { Transparency = R:NextNumber(0.2, 0.6), CanCollide = false })
		end
	end

	-- the end: the Void dais (its middle ring at road height, the centre a step up), a halo of shards turning over it
	-- (World.End.VoidHalo, turned by GlitchClient), the bench and the man
	local finish = folder(world, "End")
	local center = roadPoint(1) + Vector3.new(0, 0, -36)
	if not place(finish, "VoidDais", CFrame.new(center + Vector3.new(0, -1.2, 0))) then
		for ring = 0, 3 do
			local n = ring == 0 and 1 or ring * 10
			for k = 1, n do
				local a = k / n * math.pi * 2
				local r = ring * 9
				box(finish, "Tile", Vector3.new(9, 2, 9), CFrame.new(center + Vector3.new(math.cos(a) * r, -1, math.sin(a) * r)) * CFrame.Angles(0, a, 0), (ring + k) % 2 == 0 and BLACK or WHITE)
			end
		end
	end
	local halo = place(finish, "VoidHalo", CFrame.new(center + Vector3.new(0, 30, -20)), 1)
	if halo then
		halo:SetAttribute("Spin", 0.12)
	end
	local benchAt = CFrame.lookAt(center + Vector3.new(0, 0, -14), center + Vector3.new(0, 0, 20))
	local bench = place(finish, "GlitchBench", benchAt)
	if not bench then
		box(finish, "Bench", Vector3.new(6, 0.5, 2), benchAt * CFrame.new(0, 2, 0), BLACK)
	end

	-- the glitched man: a grey R6 figure, sitting
	local description = Instance.new("HumanoidDescription")
	description.HeadColor, description.TorsoColor = Color3.fromRGB(200, 200, 204), BLACK
	description.LeftArmColor, description.RightArmColor = Color3.fromRGB(200, 200, 204), Color3.fromRGB(200, 200, 204)
	description.LeftLegColor, description.RightLegColor = Color3.fromRGB(40, 40, 44), Color3.fromRGB(40, 40, 44)
	local ok, man = pcall(Players.CreateHumanoidModelFromDescriptionAsync, Players, description, Enum.HumanoidRigType.R6)
	if ok and man then
		man.Name = "GlitchedMan"
		local humanoid = man:FindFirstChildOfClass("Humanoid")
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		for _, d in man:GetDescendants() do
			if d:IsA("Decal") and d.Name == "face" then
				d.Texture = "" -- no face
			elseif d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		-- sitting on the seat. His parts are anchored, so the joints would not move them: every limb is placed by hand (the old way
		-- turned the hip joints only, and he stood on the bench). Seat top: the Glitch kit's seat is 2.4 above the bench's foot.
		for _, d in man:GetDescendants() do
			if d:IsA("Motor6D") then
				d:Destroy()
			end
		end
		local seatTop = bench and 2.4 or 2.25
		local hipY = seatTop + 0.5 -- the thighs lie on the seat
		local torsoCF = benchAt * CFrame.new(0, hipY + 1, 0.35) * CFrame.Angles(math.rad(-8), 0, 0) -- a slight slump forward
		local function put(name, cf)
			local p = man:FindFirstChild(name)
			if p then
				p.CFrame = cf
			end
		end
		put("HumanoidRootPart", torsoCF)
		put("Torso", torsoCF)
		put("Head", torsoCF * CFrame.new(0, 1, 0) * CFrame.Angles(math.rad(-22), math.rad(6), 0) * CFrame.new(0, 0.5, 0)) -- looking down
		for _, side in { -1, 1 } do
			local name = side > 0 and "Right" or "Left"
			-- thighs straight out over the seat edge
			local hip = benchAt * CFrame.new(0.5 * side, hipY, 0.35) * CFrame.Angles(math.rad(90), 0, 0)
			put(name .. " Leg", hip * CFrame.new(0, -1, 0))
			-- forearms on the knees
			local shoulder = torsoCF * CFrame.new(1.5 * side, 1, 0) * CFrame.Angles(math.rad(38), 0, math.rad(-6 * side))
			put(name .. " Arm", shoulder * CFrame.new(0, -1, 0))
		end
		-- the hat and other accessories follow the head (they are welded to it)
		local root = man:FindFirstChild("HumanoidRootPart")
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TalkPrompt"
		prompt.ActionText = "Talk"
		prompt.ObjectText = "???"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
		local zone = box(man, "ContactZone", Vector3.new(9, 8, 9), root.CFrame * CFrame.new(0, 0, -2), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = true })
		zone.Anchored = true
		man.Parent = world
	else
		warn("[GlitchedMap] could not build the man: " .. tostring(man))
	end
	-- a single cold light over him
	local lamp = box(finish, "Lamp", Vector3.new(1, 1, 1), CFrame.new(center + Vector3.new(0, 26, -10)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	local spot = Instance.new("SpotLight")
	spot.Face, spot.Angle, spot.Range, spot.Brightness = Enum.NormalId.Bottom, 50, 40, 3
	spot.Color = WHITE
	spot.Parent = lamp
	return #world:GetDescendants()
end

return api
