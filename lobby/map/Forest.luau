--!nonstrict
-- The black-and-white forest (Jeff n' Fred). The world is split down the path: white ground with black trees on one side, black ground with
-- white trees on the other. Walking the path leads to The Cut, a clearing where the two brothers fight forever. A trigger there starts a
-- short cutscene (AreaClient). The client also drains all colour from the screen here.
-- Trees, gates, lanterns, pillars and the clearing's portals are Blender meshes (lobby/blender/forest.py and the brothers' portal from
-- portal_brothers.py), recoloured here by the side of the path they stand on.
local Kit = require(script.Parent.Kit)
local Assets = require(script.Parent.Assets)
local Gates = require(script.Parent.Gates)
local BrotherRig = require(game:GetService("ReplicatedStorage").Lobby.BrotherRig)
local C, M = Kit.C, Kit.M

local Forest = {}
local O = Vector3.new(0, -400, 4000)

local function at(x, y, z)
	return O + Vector3.new(x, y, z)
end

-- Recolour a Blender piece: wood/stone parts take `color`, foliage takes `leaf`.
local function tint(model, color, material, leaf)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			if part.Name == "Leaf" then
				part.Color, part.Material = leaf or color, M.Slate
			else
				part.Color, part.Material = color, material
			end
		end
	end
	return model
end

local function piece(parent, name, cf, scale)
	local model = Assets.Get(name)
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

-- The ground runs on under the mountain wall on every side and past the way back, so nowhere does the floor stop short of the rock.
local GROUND_X, GROUND_Z0, GROUND_Z1 = 500, -700, 190
local function ground(m)
	local length = GROUND_Z1 - GROUND_Z0
	local centerZ = (GROUND_Z0 + GROUND_Z1) / 2
	Kit.box(m, "WhiteGround", Vector3.new(GROUND_X, 4, length), CFrame.new(at(-GROUND_X / 2, -2, centerZ)), C.White, M.Marble)
	Kit.box(m, "BlackGround", Vector3.new(GROUND_X, 4, length), CFrame.new(at(GROUND_X / 2, -2, centerZ)), C.Black, M.Slate)
	-- the path follows the seam
	local r = Kit.R
	for z = 40, -350, -7 do
		local jitter = math.sin(z * 0.03) * 1.4
		Kit.noShadow(Kit.box(m, "PathLeft", Vector3.new(4, 0.3, 6.6), CFrame.new(at(-2 + jitter, 0.1, z)) * CFrame.Angles(0, r:NextNumber(-0.08, 0.08), 0), Kit.rgb(70, 70, 72), M.Slate))
		Kit.noShadow(Kit.box(m, "PathRight", Vector3.new(4, 0.3, 6.6), CFrame.new(at(2 + jitter, 0.1, z)) * CFrame.Angles(0, r:NextNumber(-0.08, 0.08), 0), Kit.rgb(190, 190, 192), M.Marble))
	end
end

local keepClear = {} -- { Vector2 (x, z), radius }: props and the glitched portal; no tree grows there
local function clearOf(x, z, pad)
	for _, spot in keepClear do
		if (Vector2.new(x, z) - spot[1]).Magnitude < spot[2] + (pad or 0) then
			return false
		end
	end
	return true
end

local function trees(m)
	local f = Kit.folder(m, "Trees")
	local r = Kit.R
	local kinds = { "ForestTree1", "ForestTree2", "ForestTree1", "ForestTree2", "ForestTree3" }
	local spots = {}
	for _ = 1, 240 do
		table.insert(spots, { (r:NextNumber() > 0.5 and 1 or -1) * r:NextNumber(11, 190), r:NextNumber(-500, 60) })
	end
	-- the outer bands out to the mountains, and the ends of the wood, were bare ground: fill them
	for _ = 1, 210 do
		table.insert(spots, { (r:NextNumber() > 0.5 and 1 or -1) * r:NextNumber(190, 425), r:NextNumber(-590, 120) })
	end
	for _ = 1, 40 do
		table.insert(spots, { (r:NextNumber() > 0.5 and 1 or -1) * r:NextNumber(20, 190), r:NextNumber(60, 140) })
	end
	for _, spot in spots do
		local x, z = spot[1], spot[2]
		local side = x < 0 and -1 or 1
		local inClearing = (Vector2.new(x, z + 400)).Magnitude < 78
		local byTheWayBack = math.abs(x) < 26 and z > 30
		if not inClearing and not byTheWayBack and clearOf(x, z, 6) then
			local height = r:NextNumber(34, 66)
			-- sunk by a stud or two (more for the big ones) so the root flares sit in the ground instead of standing on it
			local tree = piece(f, kinds[r:NextInteger(1, #kinds)], CFrame.new(at(x, -0.8 - height * 0.025, z)) * CFrame.Angles(0, r:NextNumber(0, 6.28), 0), height / 40)
			tree.Name = "Tree"
			if side < 0 then
				tint(tree, C.Black, M.Slate, Kit.rgb(26, 26, 30))
			else
				tint(tree, C.White, M.Marble, Kit.rgb(226, 226, 230))
			end
		end
	end
end

-- Torii over the path (white pillar on the white side), and stone lanterns down both edges, each the other side's colour.
local function gates(m)
	for _, z in { 18, -318 } do
		local gate = piece(m, "ForestGate", CFrame.lookAt(at(0, 0, z), at(0, 0, z + 40)))
		gate.Name = "Gate"
	end
	for z = 34, -330, -32 do
		for _, side in { -1, 1 } do
			local x = side * 7.5
			local lantern = piece(m, "ForestLantern", CFrame.lookAt(at(x, 0, z), at(0, 0, z)))
			lantern.Name = "Lantern"
			tint(lantern, side < 0 and C.Black or C.White, side < 0 and M.Slate or M.Marble)
			local glow = Kit.noShadow(Kit.box(m, "LanternGlow", Vector3.new(1.3, 1.1, 1.3), CFrame.new(at(x, 4.4, z)), Kit.rgb(255, 250, 235), M.Neon, { CanQuery = false, CanTouch = false }))
			Kit.light(glow, Kit.rgb(255, 246, 225), 18, 0.9)
		end
	end
end

local function clearing(m)
	local center = at(0, 0, -400)
	Kit.box(m, "CutWhite", Vector3.new(74, 1, 148), CFrame.new(center + Vector3.new(-37, 0.1, 0)), C.White, M.Marble)
	Kit.box(m, "CutBlack", Vector3.new(74, 1, 148), CFrame.new(center + Vector3.new(37, 0.1, 0)), C.Black, M.Slate)
	-- a slash scorched through the seam: the cut itself
	Kit.noShadow(Kit.box(m, "TheCut", Vector3.new(1.6, 0.2, 110), CFrame.new(center + Vector3.new(0, 0.72, 0)) * CFrame.Angles(0, math.rad(8), 0), C.Black, M.Neon))
	-- the brothers: R6 avatars with Blender katanas and headbands, posed here at guard and animated by the client (AreaClient)
	local fight = Kit.model(m, "TheFight")
	local R6Pose = require(game:GetService("ReplicatedStorage").Lobby.R6Pose)
	for _, who in { { "Jeff", -9, C.Black, Kit.rgb(40, 40, 44), Kit.rgb(150, 30, 36), C.White }, { "Fred", 9, C.White, Kit.rgb(214, 214, 218), Kit.rgb(40, 60, 120), C.Black } } do
		local scale = 2.2
		local home = CFrame.lookAt(center + Vector3.new(who[2], 0.6, 0), center + Vector3.new(0, 0.6, 0))
		local brother = R6Pose.build(fight, who[1], { skin = who[4], torso = who[3], arms = who[3], legs = who[4] })
		for _, part in brother:GetChildren() do
			if part:IsA("BasePart") then
				part.Size *= scale
			end
		end
		local sword = Assets.Get("BroSword")
		sword:ScaleTo(scale)
		sword.Name = "Sword"
		for _, part in sword:GetChildren() do
			if part:IsA("BasePart") then
				part.CanCollide, part.CanQuery = false, false
				if part.Name == "Blade" then
					part.Color = who[6]
				elseif part.Name == "Sash" then
					part.Color = who[5]
				end
			end
		end
		sword.Parent = brother
		local band = Assets.Get("BroHeadband")
		band:ScaleTo(scale)
		band.Name = "Headband"
		for _, part in band:GetChildren() do
			if part:IsA("BasePart") then
				part.Color = who[5]
				part.CanCollide = false
			end
		end
		band.Parent = brother
		brother.WorldPivot = home
		brother:SetAttribute("Scale", scale)
		BrotherRig.pose(brother, home, BrotherRig.POSES.guard, scale)
	end
	local trigger = Kit.box(m, "CutTrigger", Vector3.new(80, 20, 10), CFrame.new(center + Vector3.new(0, 10, 66)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	trigger:SetAttribute("Cut", true)
	-- broken pillars ringing the clearing, open where the path comes in and behind, where the portals stand
	for k = 0, 13 do
		local a = math.rad(-30 + k * 18)
		if math.abs(a - math.rad(90)) > math.rad(16) then
			local p = center + Vector3.new(math.cos(a) * 64, 0.6, math.sin(a) * 64)
			local pillar = piece(m, "ForestPillar", CFrame.lookAt(p, center) * CFrame.Angles(0, Kit.R:NextNumber(-0.6, 0.6), 0), Kit.R:NextNumber(0.85, 1.25))
			pillar.Name = "Pillar"
			tint(pillar, p.X < center.X and C.Black or C.White, p.X < center.X and M.Slate or M.Marble)
		end
	end
	-- four portals behind the fight, on the far edge of the clearing: the brothers' crossed swords, smaller
	local spots = { -48, -16, 16, 48 }
	for i, x in spots do
		local m2 = Kit.model(m, "Portal" .. i)
		local base = CFrame.lookAt(center + Vector3.new(x, 0.6, -58), center + Vector3.new(x * 0.5, 0.6, 40))
		local shell = piece(m2, "GateBrothers", base, 0.5)
		shell.Name = "Shell"
		local face = Gates.glow(shell, Kit.rgb(128, 128, 132), 0.3, 20)
		if face then
			face.Name = "Face"
			Kit.nameplate(face, "Portal " .. i, "Coming soon", C.White, 9, 70)
			face:SetAttribute("ComingSoon", "JeffAndFred")
			face.CanTouch = true
			Kit.tag(face, "UnfairComingSoon")
		end
	end
end

-- A wall of mountains closing the wood in on every side (half sunk, so their feet are hidden), so the world ends in rock.
local function mountains(m)
	local f = Kit.folder(m, "Mountains")
	local r = Kit.R
	local sides = {
		{ -440, -560, -440, 90 }, { 440, -560, 440, 90 }, -- west and east, along z
		{ -440, -600, 440, -600 }, { -440, 110, 440, 110 }, -- north and south, along x
	}
	for _, side in sides do
		local a, b = Vector3.new(side[1], 0, side[2]), Vector3.new(side[3], 0, side[4])
		local count = math.ceil((b - a).Magnitude / 120)
		for i = 0, count do
			local p = a:Lerp(b, i / count) + Vector3.new(r:NextNumber(-20, 20), 0, r:NextNumber(-20, 20))
			local face = Vector3.new(0, 0, -250) - p
			local cf = CFrame.lookAt(at(p.X, -14, p.Z), at(p.X, -14, p.Z) + Vector3.new(face.X, 0, face.Z)) * CFrame.Angles(0, r:NextNumber(-0.3, 0.3), 0)
			local mtn = piece(f, i % 2 == 0 and "ForestMountain1" or "ForestMountain2", cf, r:NextNumber(0.9, 1.35))
			mtn.Name = "Mountain"
			tint(mtn, p.X < 0 and Kit.rgb(70, 70, 74) or Kit.rgb(150, 150, 154), M.Slate)
		end
	end
end

-- Two-tone props: on the white ground they come in dark greys, on the black ground in light ones (the screen is grey here anyway,
-- AreaClient drains the colour). Glass stays see-through and lamp glass stays lit.
local SHADES = {
	dark = { Wood = 46, WoodDark = 28, Plank = 62, Thatch = 74, Stone = 92, Rock = 64, Bark = 40, Moss = 34, Rope = 110, Iron = 24, Black = 12, White = 200, Fabric = 150 },
	light = { Wood = 196, WoodDark = 150, Plank = 222, Thatch = 182, Stone = 168, Rock = 186, Bark = 176, Moss = 214, Rope = 236, Iron = 90, Black = 30, White = 246, Fabric = 230 },
}
local function shade(model, side)
	local tones = side < 0 and SHADES.dark or SHADES.light
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local v = tones[part.Name]
			if v then
				part.Color = Kit.rgb(v, v, v + 2)
			elseif part.Name == "Neon" then
				part.Color = Kit.rgb(255, 250, 238)
			end
		end
	end
	return model
end

-- where the house-sized things stand: { piece, x, z, facing (degrees), scale }
local PROPS = {
	{ "ForestCabin", -96, -60, 80, 1 }, { "ForestCabin", 128, -215, -100, 1 }, { "ForestCabin", -250, 40, 30, 1.1 }, { "ForestCabin", 300, -420, -140, 1 },
	{ "ForestCabinRuin", 92, 10, -70, 1 }, { "ForestCabinRuin", -150, -300, 120, 1.1 }, { "ForestCabinRuin", 260, 70, 200, 1 },
	{ "ForestWell", -62, -172, 0, 1 }, { "ForestWell", 205, -340, 45, 1 },
	{ "ForestShrine", -38, -110, 90, 1.2 }, { "ForestShrine", 46, -268, -90, 1.2 }, { "ForestShrine", -330, -480, 60, 1.4 },
	{ "ForestLogPile", -118, -80, 10, 1 }, { "ForestLogPile", 150, -190, 70, 1 }, { "ForestLogPile", -230, 70, -30, 1 }, { "ForestLogPile", 70, 30, 100, 1 },
}

local function props(m)
	local f = Kit.folder(m, "Props")
	local r = Kit.R
	for _, spec in PROPS do
		local x, z = spec[2], spec[3]
		local side = x < 0 and -1 or 1
		local base = at(x, 0, z)
		local model = piece(f, spec[1], CFrame.new(base) * CFrame.Angles(0, math.rad(spec[4]), 0), spec[5])
		model.Name = (spec[1]:gsub("^Forest", ""))
		shade(model, side)
		local _, size = model:GetBoundingBox()
		table.insert(keepClear, { Vector2.new(x, z), math.max(size.X, size.Z) * 0.6 })
		-- a warm lamp in the cabins that still stand
		if spec[1] == "ForestCabin" then
			local lamp = Kit.box(model, "Lamp", Vector3.new(1, 1, 1), CFrame.new(base + Vector3.new(0, 5, 0)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
			Kit.light(lamp, Kit.rgb(255, 238, 205), 26, 0.8)
		end
	end
	-- boulders, stumps and fallen logs scattered through the wood, mostly away from the path
	local kinds = { "ForestRock1", "ForestRock2", "ForestRock3", "ForestRock2" }
	for i = 1, 46 do
		local side = r:NextNumber() > 0.5 and 1 or -1
		local x, z = side * r:NextNumber(24, 420), r:NextNumber(-580, 140)
		if clearOf(x, z, 10) and (Vector2.new(x, z + 400)).Magnitude > 82 then
			local rock = piece(f, kinds[(i % #kinds) + 1], CFrame.new(at(x, -1.5, z)) * CFrame.Angles(0, r:NextNumber(0, 6.28), 0), r:NextNumber(0.6, 1.5))
			rock.Name = "Boulder"
			shade(rock, side)
			table.insert(keepClear, { Vector2.new(x, z), 9 })
		end
	end
	for _ = 1, 34 do
		local side = r:NextNumber() > 0.5 and 1 or -1
		local x, z = side * r:NextNumber(14, 400), r:NextNumber(-570, 150)
		if clearOf(x, z, 4) and (Vector2.new(x, z + 400)).Magnitude > 80 then
			local stump = piece(f, "ForestStump", CFrame.new(at(x, -0.3, z)) * CFrame.Angles(0, r:NextNumber(0, 6.28), 0), r:NextNumber(0.9, 1.6))
			stump.Name = "Stump"
			shade(stump, side)
			table.insert(keepClear, { Vector2.new(x, z), 4 })
		end
	end
end

-- Low drifting fog banks between the trees: big soft smoke puffs that hang near the ground.
local function mist(m)
	local f = Kit.folder(m, "Mist")
	local r = Kit.R
	for _ = 1, 64 do
		local x, z = r:NextNumber(-430, 430), r:NextNumber(-590, 150)
		local p = Kit.box(f, "FogBank", Vector3.new(60, 2, 60), CFrame.new(at(x, 2, z)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		local e = Instance.new("ParticleEmitter")
		e.Name = "Fog"
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(Kit.rgb(214, 214, 220))
		e.LightInfluence = 0.6
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 14), NumberSequenceKeypoint.new(1, 30) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.82), NumberSequenceKeypoint.new(0.7, 0.86), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(14, 22)
		e.Rate = 0.9
		e.Speed = NumberRange.new(0.4, 1.4)
		e.SpreadAngle = Vector2.new(180, 8)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-4, 4)
		e.Acceleration = Vector3.new(0.3, 0, 0.1)
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		e.Parent = p
	end
end

-- The black-and-white glitched portal: off the path by the south wall. Walking into its face takes you to the glitched place
-- (SidePlaceService, tag UnfairPlacePortal, Place = "Glitched"). GlitchPortalClient makes it flicker and hum.
local GLITCH_AT = Vector2.new(-70, 62)
local function glitchPortal(m)
	local model = Kit.model(m, "GlitchPortal")
	local base = at(GLITCH_AT.X, 0, GLITCH_AT.Y)
	local cf = CFrame.lookAt(base, at(0, 0, 40))
	local shell = piece(model, "GlitchPortal", cf, 1)
	shell.Name = "Shell"
	local face = Kit.cyl(model, "Face", 0.4, 19.6, cf * CFrame.new(0, 12.5, 0) * CFrame.Angles(0, math.rad(90), 0), Kit.rgb(250, 250, 250), M.Neon, { CanCollide = false, CanQuery = false, CastShadow = false, Transparency = 0.15 })
	face:SetAttribute("Place", "Glitched")
	face.CanTouch = true
	Kit.tag(face, "UnfairPlacePortal")
	Kit.tag(face, "UnfairGlitchPortal")
	Kit.light(face, Kit.rgb(255, 255, 255), 40, 1.2)
	table.insert(keepClear, { GLITCH_AT, 26 })
end

function Forest.Build(root)
	local m = Kit.folder(root, "Forest")
	keepClear = {}
	ground(m)
	mountains(m)
	glitchPortal(m)
	props(m)
	trees(m)
	mist(m)
	gates(m)
	clearing(m)
	Kit.arrival(m, CFrame.lookAt(at(0, 3.5, 44), at(0, 3.5, -300)), 6).Name = "ArrivalForest"
	-- the way back, beside the arrival point
	Gates.returnGate(m, CFrame.lookAt(at(0, 0, 66), at(0, 0, 0)), "GateReturnForest")
	return m
end

return Forest
