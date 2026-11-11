--!nonstrict
--[[
 Builds the glitched place into Workspace.World (run in that place's Studio window, edit mode):
   require(game.ServerStorage.MapBuilder).Build()
 A checker platform in the void (Spawn, and a glitched arch: the way back to the lobby), a long winding road of black and white tiles
 (World.Road, which the client makes shiver), broken pillars, arches and floating cubes along it, and at the far end a round platform
 where the glitched man sits on a broken bench (World.GlitchedMan: TalkPrompt, ContactZone).
 Blender pieces come from the Glitch kit (lobby/blender/realm.py: GlitchBench, GlitchPillar, GlitchArch); plain parts stand in if it
 cannot be loaded. Everything is black, white and grey.
]]
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local api = {}
local GLITCH_KIT = 118962804006333
local R = Random.new(404)
local WHITE, BLACK, GREY = Color3.fromRGB(240, 240, 242), Color3.fromRGB(12, 12, 14), Color3.fromRGB(120, 120, 124)
local SKIN = {
	White = { Enum.Material.SmoothPlastic, WHITE }, Black = { Enum.Material.SmoothPlastic, BLACK }, Glow = { Enum.Material.Neon, WHITE },
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
local function loadKit()
	local ok, objects = pcall(game.GetObjects, game, "rbxassetid://" .. GLITCH_KIT)
	if not ok or not objects or not objects[1] then
		warn("[GlitchedMap] could not load the Glitch kit: " .. tostring(objects))
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
	loadKit()
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
	local arch = place(start, "GlitchArch", CFrame.lookAt(Vector3.new(0, 0, 22), Vector3.new(0, 0, 0)))
	local exit = box(start, "Exit", Vector3.new(12, 16, 2), CFrame.new(0, 8, 23), WHITE, Enum.Material.Neon, { Transparency = 0.55, CanCollide = false, CanQuery = false })
	CollectionService:AddTag(exit, "GlitchExit")
	local sign = Instance.new("BillboardGui")
	sign.Size, sign.StudsOffset, sign.MaxDistance = UDim2.fromOffset(300, 40), Vector3.new(0, 11, 0), 80
	sign.Parent = exit
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	label.Font, label.TextSize, label.TextColor3, label.TextStrokeTransparency = Enum.Font.Code, 22, WHITE, 0
	label.Text = "B4CK T0 TH3 S4NCTUM"
	label.Parent = sign
	if not arch then
		box(start, "ArchL", Vector3.new(3, 18, 3), CFrame.new(-8, 9, 22), BLACK)
		box(start, "ArchR", Vector3.new(3, 18, 3), CFrame.new(8, 9, 22), WHITE)
		box(start, "ArchTop", Vector3.new(19, 3, 3), CFrame.new(0, 19.5, 22), BLACK)
	end

	-- the road
	local road = folder(world, "Road")
	local steps = math.floor(LENGTH / 8)
	for s = 0, steps do
		local t = s / steps
		local p = roadPoint(t)
		local ahead = roadPoint(math.min(1, t + 0.002)) - p
		local cf = CFrame.lookAt(p, p + Vector3.new(ahead.X, 0, ahead.Z))
		for lane = -1, 1 do
			if R:NextNumber() > 0.05 or lane == 0 then -- a few holes at the edges, never in the middle
				local dark = (s + lane) % 2 == 0
				local tile = box(road, "Tile", Vector3.new(8, 2, 8.4), cf * CFrame.new(lane * 8, -1 + R:NextNumber(-0.25, 0.25), 0) * CFrame.Angles(R:NextNumber(-0.02, 0.02), R:NextNumber(-0.03, 0.03), R:NextNumber(-0.02, 0.02)), dark and BLACK or WHITE)
				if R:NextNumber() < 0.04 then
					tile.Material = Enum.Material.Neon
				end
			end
		end
	end

	-- along the road: pillars, arches, floating cubes and dead screens
	local decor = folder(world, "Decor")
	for s = 1, 9 do
		local t = s / 10
		local p = roadPoint(t)
		local ahead = roadPoint(t + 0.01) - p
		local cf = CFrame.lookAt(p, p + Vector3.new(ahead.X, 0, ahead.Z))
		place(decor, "GlitchArch", cf * CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, R:NextNumber(-0.06, 0.06)), 1.25)
		for _, side in { -1, 1 } do
			place(decor, "GlitchPillar", cf * CFrame.new(side * 22, -2, R:NextNumber(-20, 20)) * CFrame.Angles(R:NextNumber(-0.1, 0.1), R:NextNumber(0, 6), R:NextNumber(-0.15, 0.15)), R:NextNumber(0.7, 1.4))
		end
	end
	for _ = 1, 140 do
		local t = R:NextNumber()
		local p = roadPoint(t) + Vector3.new(R:NextNumber(-90, 90), R:NextNumber(-30, 60), R:NextNumber(-20, 20))
		if math.abs(p.X - roadPoint(t).X) > 18 then
			local size = R:NextNumber(1, 9)
			box(decor, "Cube", Vector3.new(size, size, size), CFrame.new(p) * CFrame.Angles(R:NextNumber(0, 6), R:NextNumber(0, 6), R:NextNumber(0, 6)), R:NextNumber() < 0.5 and WHITE or BLACK, R:NextNumber() < 0.15 and Enum.Material.Neon or Enum.Material.SmoothPlastic, { CanCollide = false })
		end
	end
	for _ = 1, 18 do
		local t = R:NextNumber(0.05, 0.95)
		local p = roadPoint(t) + Vector3.new(R:NextNumber(-60, 60), R:NextNumber(8, 30), 0)
		if math.abs(p.X - roadPoint(t).X) > 20 then
			box(decor, "Screen", Vector3.new(R:NextNumber(8, 20), R:NextNumber(5, 12), 0.4), CFrame.lookAt(p, roadPoint(t) + Vector3.new(0, 6, 0)), WHITE, Enum.Material.Neon, { Transparency = R:NextNumber(0.2, 0.6), CanCollide = false })
		end
	end

	-- the end: a round platform, the bench and the man
	local finish = folder(world, "End")
	local center = roadPoint(1) + Vector3.new(0, 0, -36)
	for ring = 0, 3 do
		local count = ring == 0 and 1 or ring * 10
		for k = 1, count do
			local a = k / count * math.pi * 2
			local r = ring * 9
			box(finish, "Tile", Vector3.new(9, 2, 9), CFrame.new(center + Vector3.new(math.cos(a) * r, -1, math.sin(a) * r)) * CFrame.Angles(0, a, 0), (ring + k) % 2 == 0 and BLACK or WHITE)
		end
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
		-- sitting: thighs forward, root lowered onto the seat
		local torso = man:FindFirstChild("Torso")
		for _, hip in { "Right Hip", "Left Hip" } do
			local joint = torso and torso:FindFirstChild(hip)
			if joint then
				joint.C0 = joint.C0 * CFrame.Angles(0, 0, (hip == "Right Hip") and math.rad(90) or math.rad(-90))
			end
		end
		man:PivotTo(benchAt * CFrame.new(0, 3.5, 0.1))
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
