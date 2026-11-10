--!nonstrict
-- The Reliquary: the shop on the hub. Layout from the reference photo (a keeper behind a counter of sacks, walled in by floor-to-ceiling
-- shelves so full they feel like they might fall), but the stock is swords, bows, axes, shields, potions, scrolls and orbs.
-- Local coordinates: front (doorway) is -Z, back wall is +Z. A giant sword through the roof is the landmark you steer by.
local Kit = require(script.Parent.Kit)
local Assets = require(script.Parent.Assets)
local C, M = Kit.C, Kit.M

local Shop = {}
local BASE = CFrame.new(84, 400, 18) * CFrame.Angles(0, math.rad(90), 0)

local WIDTH, DEPTH, HEIGHT = 44, 36, 24

local POTIONS = { Kit.rgb(220, 60, 60), Kit.rgb(70, 140, 235), Kit.rgb(90, 210, 110), Kit.rgb(230, 170, 60), Kit.rgb(190, 90, 230) }
local ORBS = { Kit.rgb(255, 214, 92), Kit.rgb(110, 230, 130), Kit.rgb(120, 200, 255), Kit.rgb(255, 120, 70), Kit.rgb(240, 170, 255) }

local function detail(part)
	part.CastShadow = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

-- Items stand on a shelf at `at` (a CFrame on the plank, -Z facing the room). Each returns the width it took.
local function sword(m, at, big)
	local s = big and 1.35 or 1
	local steel = Kit.rgb(196, 204, 214)
	detail(Kit.box(m, "Blade", Vector3.new(0.34, 3 * s, 0.1) , at * CFrame.new(0, 1.5 * s, 0), steel, M.Metal))
	detail(Kit.box(m, "Guard", Vector3.new(1.3, 0.2, 0.26) * s, at * CFrame.new(0, 3.08 * s, 0), C.Gold, M.Metal))
	detail(Kit.box(m, "Grip", Vector3.new(0.2, 0.9, 0.2) * s, at * CFrame.new(0, 3.6 * s, 0), C.WoodDark, M.Fabric))
	detail(Kit.ball(m, "Pommel", 0.34 * s, (at * CFrame.new(0, 4.1 * s, 0)).Position, C.Gold, M.Metal))
	return 1.5
end

local function bow(m, at)
	local count = 7
	for i = 0, count - 1 do
		local a = math.rad(-65 + i / (count - 1) * 130)
		local p = at * CFrame.new(0, 2.1 + math.sin(a) * 2, -math.cos(a) * 0.65 + 0.4)
		detail(Kit.box(m, "Limb", Vector3.new(0.2, 0.82, 0.24), p * CFrame.Angles(a, 0, 0), C.Wood, M.Wood))
	end
	detail(Kit.box(m, "String", Vector3.new(0.05, 3.7, 0.05), at * CFrame.new(0, 2.1, 0.45), C.White, M.Fabric))
	return 1.4
end

local function axe(m, at)
	detail(Kit.box(m, "Haft", Vector3.new(0.24, 3.8, 0.24), at * CFrame.new(0, 1.9, 0), C.Wood, M.Wood))
	detail(Kit.wedge(m, "Bit", Vector3.new(0.14, 1.3, 1), at * CFrame.new(0.55, 3.1, 0) * CFrame.Angles(0, math.rad(90), 0), Kit.rgb(166, 172, 184), M.Metal))
	detail(Kit.wedge(m, "Bit", Vector3.new(0.14, 1.3, 1), at * CFrame.new(-0.55, 3.1, 0) * CFrame.Angles(0, math.rad(-90), 0), Kit.rgb(166, 172, 184), M.Metal))
	return 1.9
end

local function shield(m, at, tint)
	detail(Kit.cyl(m, "Face", 0.22, 2.7, at * CFrame.new(0, 1.55, 0) * CFrame.Angles(0, math.rad(90), 0), tint, M.Metal))
	detail(Kit.cyl(m, "Boss", 0.42, 0.8, at * CFrame.new(0, 1.55, -0.08) * CFrame.Angles(0, math.rad(90), 0), C.Gold, M.Metal))
	return 3
end

local function potion(m, at, tint)
	detail(Kit.ball(m, "Flask", 1.05, (at * CFrame.new(0, 0.6, 0)).Position, tint, M.Glass, { Transparency = 0.2 }))
	detail(Kit.box(m, "Neck", Vector3.new(0.3, 0.55, 0.3), at * CFrame.new(0, 1.3, 0), tint, M.Glass))
	detail(Kit.box(m, "Cork", Vector3.new(0.34, 0.22, 0.34), at * CFrame.new(0, 1.66, 0), C.Plank, M.Wood))
	return 1.2
end

local function orb(m, at, tint)
	detail(Kit.cyl(m, "Stand", 0.32, 1, at * CFrame.new(0, 0.16, 0) * CFrame.Angles(0, 0, math.rad(90)), C.GoldDeep, M.Metal))
	detail(Kit.ball(m, "Orb", 1.3, (at * CFrame.new(0, 0.95, 0)).Position, tint, M.Neon))
	return 1.6
end

local function scrolls(m, at)
	for i = 0, 2 do
		detail(Kit.cyl(m, "Scroll", 2, 0.42, at * CFrame.new(0, 0.22 + (i == 2 and 0.38 or 0), (i == 2 and 0.2 or i * 0.44)) , Kit.rgb(226, 208, 164), M.Fabric))
	end
	return 2.3
end

local function dagger(m, at)
	detail(Kit.box(m, "Blade", Vector3.new(0.24, 1.3, 0.08), at * CFrame.new(0, 0.65, 0), Kit.rgb(196, 204, 214), M.Metal))
	detail(Kit.box(m, "Guard", Vector3.new(0.7, 0.14, 0.2), at * CFrame.new(0, 1.35, 0), C.Gold, M.Metal))
	detail(Kit.box(m, "Grip", Vector3.new(0.16, 0.56, 0.16), at * CFrame.new(0, 1.7, 0), C.WoodDark, M.Fabric))
	return 0.9
end

-- One floor-to-ceiling shelf unit. `at` is the bottom-centre, -Z toward the room.
local function shelfUnit(parent, at, width, rows, rowHeight)
	local m = Kit.model(parent, "Shelves")
	local r = Kit.R
	Kit.box(m, "Back", Vector3.new(width, rows * rowHeight + 1, 0.6), at * CFrame.new(0, (rows * rowHeight + 1) / 2, 1.5), C.WoodDark, M.WoodPlanks)
	for _, side in { -1, 1 } do
		Kit.box(m, "Upright", Vector3.new(0.7, rows * rowHeight + 1, 3.2), at * CFrame.new(side * width / 2, (rows * rowHeight + 1) / 2, 0), C.Wood, M.Wood)
	end
	for row = 0, rows do
		Kit.box(m, "Plank", Vector3.new(width, 0.4, 3.2), at * CFrame.new(0, row * rowHeight + 0.5, 0), C.Plank, M.Wood)
	end
	for row = 0, rows - 1 do
		-- each row sells one thing, like the photo's rows of matching bottles, with odd ones crammed in
		local stock = row % 5
		local x = -width / 2 + 1.1
		local limit = width / 2 - 0.9
		while x < limit do
			local at2 = at * CFrame.new(x, row * rowHeight + 0.7, r:NextNumber(-0.5, 0.2))
			local tint = POTIONS[r:NextInteger(1, #POTIONS)]
			local roll = r:NextNumber()
			local used
			if roll < 0.12 then
				used = orb(m, at2, ORBS[r:NextInteger(1, #ORBS)])
			elseif stock == 0 then
				used = sword(m, at2)
			elseif stock == 1 then
				used = potion(m, at2, tint)
			elseif stock == 2 then
				used = roll < 0.55 and bow(m, at2) or axe(m, at2)
			elseif stock == 3 then
				used = roll < 0.6 and scrolls(m, at2) or dagger(m, at2)
			else
				used = roll < 0.5 and shield(m, at2, C.StoneDark) or orb(m, at2, ORBS[r:NextInteger(1, #ORBS)])
			end
			x += used + r:NextNumber(0.1, 0.5)
		end
	end
	return m
end

local function shell(m)
	local h = HEIGHT
	Kit.box(m, "Floor", Vector3.new(WIDTH, 1, DEPTH), BASE * CFrame.new(0, 0.5, 0), C.StoneDark, M.Slate)
	Kit.box(m, "Back", Vector3.new(WIDTH, h, 2), BASE * CFrame.new(0, h / 2, DEPTH / 2), C.StoneWarm, M.Limestone)
	for _, side in { -1, 1 } do
		Kit.box(m, "Side", Vector3.new(2, h, DEPTH), BASE * CFrame.new(side * WIDTH / 2, h / 2, 0), C.StoneWarm, M.Limestone)
		Kit.box(m, "Front", Vector3.new(14, h, 2), BASE * CFrame.new(side * (WIDTH / 2 - 7), h / 2, -DEPTH / 2), C.StoneWarm, M.Limestone)
		-- great timber corner posts
		Kit.box(m, "Post", Vector3.new(3, h + 2, 3), BASE * CFrame.new(side * (WIDTH / 2), h / 2 + 1, -DEPTH / 2), C.WoodDark, M.Wood)
		Kit.box(m, "Post", Vector3.new(3, h + 2, 3), BASE * CFrame.new(side * (WIDTH / 2), h / 2 + 1, DEPTH / 2), C.WoodDark, M.Wood)
		Kit.box(m, "DoorPost", Vector3.new(2.4, h, 2.6), BASE * CFrame.new(side * 8.2, h / 2, -DEPTH / 2), C.WoodDark, M.Wood)
	end
	Kit.box(m, "Over", Vector3.new(16, 6, 2), BASE * CFrame.new(0, h - 3, -DEPTH / 2), C.StoneWarm, M.Limestone)
	Kit.box(m, "Ceiling", Vector3.new(WIDTH, 1, DEPTH), BASE * CFrame.new(0, h + 0.5, 0), C.WoodDark, M.WoodPlanks)
	for z = -14, 14, 7 do
		Kit.box(m, "Beam", Vector3.new(WIDTH, 1.4, 1.4), BASE * CFrame.new(0, h - 0.7, z), C.Wood, M.Wood)
	end
	-- tile roof: two big wedges, ridge running front to back
	local roof = Kit.rgb(132, 62, 46)
	for _, side in { -1, 1 } do
		Kit.wedge(m, "Roof", Vector3.new(DEPTH + 7, 15, WIDTH / 2 + 4), BASE * CFrame.new(side * (WIDTH / 4 + 2), h + 8.5, 0) * CFrame.Angles(0, side * math.rad(-90), 0), roof, M.Slate)
	end
	-- sign, awning and lanterns on the front
	local plank = Kit.box(m, "SignBoard", Vector3.new(30, 6, 0.8), BASE * CFrame.new(0, h - 2, -DEPTH / 2 - 1.6), C.WoodDark, M.Wood)
	Kit.sign(plank, Enum.NormalId.Front, "THE RELIQUARY", C.Gold, Enum.Font.Garamond, 0.4)
	for i = -3, 3 do
		Kit.wedge(m, "Awning", Vector3.new(4, 2.4, 6), BASE * CFrame.new(i * 4, h - 7.6, -DEPTH / 2 - 3.6) * CFrame.Angles(0, math.rad(180), 0), i % 2 == 0 and Kit.rgb(164, 40, 44) or Kit.rgb(230, 206, 150), M.Fabric)
	end
	for _, side in { -1, 1 } do
		-- on brackets either side of the door, under the awning
		Kit.wallLantern(m, BASE * CFrame.new(side * 11.5, h - 11, -DEPTH / 2 - 1))
	end
	-- the landmark
	-- the store greatsword (Wirly_world's gothic blade), gilded and made huge, driven point-first through the roof
	local giant = Assets.Get("GothicSword")
	local blade = giant:FindFirstChildWhichIsA("MeshPart", true)
	local length = 84
	blade.Size *= length / math.max(blade.Size.X, blade.Size.Y, blade.Size.Z)
	-- the mesh's long axis is X with the hilt at +X; turned hilt-up, leaning a little, about a third of it inside the roof
	blade.CFrame = BASE * CFrame.new(0, h + 2, 4) * CFrame.Angles(0, 0, math.rad(-7)) * CFrame.new(0, length * 0.3, 0) * CFrame.Angles(0, 0, math.rad(90))
	local look = blade:FindFirstChildOfClass("SurfaceAppearance")
	if look then
		look.Color = Kit.rgb(255, 214, 120)
	end
	blade.CastShadow = true
	giant.Name = "GiantSword"
	giant.Parent = m
end

local TIMBER = Kit.rgb(70, 48, 32)

-- One outside wall's half-timbering, a window in each upper panel. `face` sits on the wall's outer face, -Z pointing out, X along it.
local function timberWall(m, face, length, verticals, windows)
	local h = HEIGHT
	for _, x in verticals do
		Kit.box(m, "Timber", Vector3.new(1.1, h, 0.5), face * CFrame.new(x, h / 2, -0.25), TIMBER, M.Wood)
	end
	for _, y in { 0.6, 9, h - 0.6 } do
		Kit.box(m, "Timber", Vector3.new(length, 1.1, 0.5), face * CFrame.new(0, y, -0.3), TIMBER, M.Wood)
	end
	-- braces in the lower panels, leaning alternately
	for i = 1, #verticals - 1 do
		local x0, x1 = verticals[i], verticals[i + 1]
		local a = Vector3.new(x0 + 0.6, 1.2, 0)
		local b = Vector3.new(x1 - 0.6, 8.4, 0)
		if i % 2 == 0 then
			a, b = Vector3.new(x0 + 0.6, 8.4, 0), Vector3.new(x1 - 0.6, 1.2, 0)
		end
		local mid = (a + b) / 2
		local cf = face * CFrame.new(mid.X, mid.Y, -0.25) * CFrame.Angles(0, 0, math.atan2(b.Y - a.Y, b.X - a.X))
		Kit.box(m, "Brace", Vector3.new((b - a).Magnitude, 0.9, 0.45), cf, TIMBER, M.Wood)
	end
	local r = Kit.R
	local colors = { Kit.rgb(236, 90, 90), Kit.rgb(255, 214, 96), Kit.rgb(250, 250, 250) }
	for _, x in windows do
		local w = face * CFrame.new(x, 15.5, 0)
		Kit.box(m, "WindowFrame", Vector3.new(5.6, 6.6, 0.5), w * CFrame.new(0, 0, -0.35), TIMBER, M.Wood)
		Kit.box(m, "Pane", Vector3.new(4.4, 5.4, 0.2), w * CFrame.new(0, 0, -0.62), Kit.rgb(255, 204, 128), M.Glass)
		Kit.detail(Kit.box(m, "Mullion", Vector3.new(0.3, 5.4, 0.2), w * CFrame.new(0, 0, -0.75), TIMBER, M.Wood))
		Kit.detail(Kit.box(m, "Mullion", Vector3.new(4.4, 0.3, 0.2), w * CFrame.new(0, 0, -0.75), TIMBER, M.Wood))
		for _, s in { -1, 1 } do
			-- hinged on the frame's edge, swung a little open
			Kit.detail(Kit.box(m, "Shutter", Vector3.new(2.6, 6.4, 0.25), w * CFrame.new(s * 2.9, 0, -0.75) * CFrame.Angles(0, s * math.rad(28), 0) * CFrame.new(s * 1.3, 0, 0), Kit.rgb(52, 86, 76), M.Wood))
		end
		Kit.box(m, "FlowerBox", Vector3.new(5.8, 1.1, 1.4), w * CFrame.new(0, -3.9, -1), TIMBER, M.WoodPlanks)
		for k = 1, 9 do
			local leaf = k % 3 == 0
			Kit.detail(Kit.ball(m, leaf and "Leaf" or "Bloom", r:NextNumber(0.7, 1.1), (w * CFrame.new(-2.5 + k * 0.5, -3.1 + r:NextNumber(0, 0.4), -1 + r:NextNumber(-0.3, 0.3))).Position, leaf and C.GrassDark or colors[r:NextInteger(1, 3)], M.SmoothPlastic))
		end
	end
end

local function exterior(m)
	local h = HEIGHT
	for _, side in { -1, 1 } do
		-- side walls: outer face at x = +-23, looking out
		local face = BASE * CFrame.new(side * (WIDTH / 2 + 1), 0, 0) * CFrame.Angles(0, side * math.rad(-90), 0)
		timberWall(m, face, DEPTH - 2, { -17, -9, 0, 9, 17 }, { -4.5, 4.5 })
	end
	timberWall(m, BASE * CFrame.new(0, 0, DEPTH / 2 + 1) * CFrame.Angles(0, math.rad(180), 0), WIDTH - 2, { -21, -11, 0, 11, 21 }, { -15.5, 15.5 })
	-- a stone plinth along the foot of the walls
	for _, side in { -1, 1 } do
		Kit.box(m, "Plinth", Vector3.new(1.4, 1.4, DEPTH + 2), BASE * CFrame.new(side * (WIDTH / 2 + 1.2), 0.7, 0), C.StoneDark, M.Cobblestone)
	end
	Kit.box(m, "Plinth", Vector3.new(WIDTH + 2, 1.4, 1.4), BASE * CFrame.new(0, 0.7, DEPTH / 2 + 1.2), C.StoneDark, M.Cobblestone)
	-- chimney through the roof, with a lazy smoke
	local chimney = BASE * CFrame.new(-12, 0, 9)
	Kit.box(m, "Chimney", Vector3.new(4.4, 22, 4.4), chimney * CFrame.new(0, h + 7, 0), C.StoneDark, M.Brick)
	Kit.box(m, "ChimneyCap", Vector3.new(5.4, 1, 5.4), chimney * CFrame.new(0, h + 18.5, 0), C.Stone, M.Slate)
	local smoke = Kit.detail(Kit.box(m, "Smoke", Vector3.new(2.4, 0.4, 2.4), chimney * CFrame.new(0, h + 19.2, 0), nil, nil, { Transparency = 1 }))
	local e = Instance.new("ParticleEmitter")
	e.Name = "Smoke"
	e.Color = ColorSequence.new(Kit.rgb(200, 196, 192))
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 6) })
	e.Rate = 3
	e.Speed = NumberRange.new(3, 4)
	e.Lifetime = NumberRange.new(4, 6)
	e.RotSpeed = NumberRange.new(-20, 20)
	e.Rotation = NumberRange.new(0, 360)
	e.SpreadAngle = Vector2.new(8, 8)
	e.Acceleration = Vector3.new(1.5, 0.5, 0)
	e.Parent = smoke
	-- the doorstep, a rug inside, and the yard: crates and barrels of stock either side of the door
	Kit.box(m, "Doorstep", Vector3.new(16, 0.6, 3), BASE * CFrame.new(0, 0.3, -DEPTH / 2 - 1.6), C.Stone, M.Slate)
	Kit.noShadow(Kit.box(m, "Rug", Vector3.new(9, 0.12, 6), BASE * CFrame.new(0, 1.06, -DEPTH / 2 + 4), Kit.rgb(132, 34, 40), M.Fabric))
	Kit.noShadow(Kit.box(m, "RugTrim", Vector3.new(9.6, 0.1, 6.6), BASE * CFrame.new(0, 1.03, -DEPTH / 2 + 4), C.GoldDeep, M.Fabric))
	local yard = BASE * CFrame.new(0, 0, -DEPTH / 2 - 3.5)
	Kit.barrel(m, (yard * CFrame.new(-15.5, 0, 0)).Position)
	Kit.barrel(m, (yard * CFrame.new(-19, 0, 1)).Position, 3.8, 3)
	Kit.crate(m, yard * CFrame.new(15.5, 0, 0) * CFrame.Angles(0, 0.2, 0), 3.6)
	Kit.crate(m, yard * CFrame.new(19.2, 0, 0.6) * CFrame.Angles(0, -0.15, 0), 3.2)
	Kit.crate(m, yard * CFrame.new(16.2, 3.6, 0.2) * CFrame.Angles(0, 0.5, 0), 2.6)
	-- a shield hung on the front wall, for whoever cannot read the sign
	local plaque = BASE * CFrame.new(-18, 11, -DEPTH / 2 - 1.2) -- -Z points out of the wall
	Kit.cyl(m, "Shield", 0.4, 5, plaque * CFrame.Angles(0, math.rad(90), 0), Kit.rgb(140, 36, 40), M.Metal)
	Kit.detail(Kit.cyl(m, "ShieldRim", 0.3, 5.5, plaque * CFrame.new(0, 0, 0.1) * CFrame.Angles(0, math.rad(90), 0), C.Gold, M.Foil))
	for _, a in { 0.7, -0.7 } do
		Kit.detail(Kit.box(m, "CrossedBlade", Vector3.new(0.6, 8, 0.2), plaque * CFrame.new(0, 0, 0.1) * CFrame.Angles(0, 0, a), Kit.rgb(196, 204, 214), M.Metal))
	end
end

local function interior(m)
	local inner = Kit.folder(m, "Stock")
	local rowH = 4.7
	-- back wall behind the keeper, then the side walls, floor to rafters
	shelfUnit(inner, BASE * CFrame.new(0, 1, DEPTH / 2 - 3.2) * CFrame.Angles(0, 0, 0), WIDTH - 5, 4, rowH)
	for _, side in { -1, 1 } do
		shelfUnit(inner, BASE * CFrame.new(side * (WIDTH / 2 - 3.2), 1, 0.5) * CFrame.Angles(0, side * math.rad(-90), 0), DEPTH - 12, 4, rowH)
	end
	-- the counter across the shop, heaped with sacks like the photo
	local counterZ = 6
	Kit.box(m, "Counter", Vector3.new(26, 4, 5), BASE * CFrame.new(0, 3, counterZ), C.Wood, M.WoodPlanks)
	Kit.box(m, "CounterTop", Vector3.new(27, 0.6, 6), BASE * CFrame.new(0, 5.3, counterZ), C.Plank, M.Wood)
	local r = Kit.R
	local sackColors = { Kit.rgb(216, 192, 140), Kit.rgb(196, 110, 62), Kit.rgb(180, 140, 80), Kit.rgb(226, 212, 176), Kit.rgb(150, 130, 90), Kit.rgb(200, 150, 60) }
	-- two heaps of tied sacks, the middle left clear in front of the keeper
	for row = 0, 1 do
		for i = -5, 5 do
			if math.abs(i) > 1 or (row == 0 and math.abs(i) == 1) then
				local x = i * 3.1 + r:NextNumber(-0.3, 0.3)
				local cf = BASE * CFrame.new(x, 2.2 + row * 1.9, counterZ - 4.8 - (1 - row) * 1.9) * CFrame.Angles(r:NextNumber(-0.08, 0.08), r:NextNumber(-0.3, 0.3), r:NextNumber(-0.08, 0.08))
				local color = sackColors[r:NextInteger(1, #sackColors)]
				detail(Kit.box(inner, "Sack", Vector3.new(2.8, 2.4, 2.4), cf, color, M.Fabric))
				detail(Kit.box(inner, "SackTop", Vector3.new(2.2, 0.5, 1.8), cf * CFrame.new(0, 1.3, 0), color, M.Fabric))
				detail(Kit.box(inner, "SackTie", Vector3.new(0.9, 0.7, 0.9), cf * CFrame.new(0, 1.8, 0), color:Lerp(Color3.new(0, 0, 0), 0.25), M.Fabric))
			end
		end
	end
	-- things on the counter: a balance, a ledger, a heap of coin, the orb of the day
	local top = BASE * CFrame.new(0, 5.7, counterZ)
	detail(Kit.box(inner, "ScalePost", Vector3.new(0.4, 3.6, 0.4), top * CFrame.new(8, 1.8, 0), C.GoldDeep, M.Metal))
	detail(Kit.box(inner, "ScaleBar", Vector3.new(5, 0.25, 0.25), top * CFrame.new(8, 3.5, 0), C.GoldDeep, M.Metal))
	for _, s in { -1, 1 } do
		detail(Kit.cyl(inner, "ScalePan", 0.16, 2.2, top * CFrame.new(8 + s * 2.4, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)), C.Gold, M.Metal))
	end
	detail(Kit.box(inner, "Ledger", Vector3.new(3, 0.5, 2.2), top * CFrame.new(-7, 0.3, 0) * CFrame.Angles(0, 0.3, 0), Kit.rgb(100, 40, 34), M.Leather))
	-- beside the keeper, not in front of him
	detail(Kit.cyl(inner, "OrbStand", 0.5, 1.6, top * CFrame.new(4.6, 0.25, -0.6) * CFrame.Angles(0, 0, math.rad(90)), C.GoldDeep, M.Metal))
	local showOrb = detail(Kit.ball(inner, "OrbOfTheDay", 1.9, (top * CFrame.new(4.6, 1.4, -0.6)).Position, ORBS[5], M.Neon))
	Kit.light(showOrb, ORBS[5], 12, 0.6)
	for _ = 1, 22 do
		detail(Kit.cyl(inner, "Coin", 0.16, 1, top * CFrame.new(r:NextNumber(-5, -2), 0.2 + r:NextNumber(0, 0.5), r:NextNumber(-1.4, 1.4)) * CFrame.Angles(0, 0, math.rad(90) + r:NextNumber(-0.25, 0.25)), C.Gold, M.Foil))
	end
	-- warm lamps hung from the rafters
	for _, x in { -13, 0, 13 } do
		detail(Kit.box(inner, "Chain", Vector3.new(0.2, 5, 0.2), BASE * CFrame.new(x, HEIGHT - 3.5, -3), C.StoneDark, M.Metal))
		local glow = detail(Kit.ball(inner, "Lamp", 2.4, (BASE * CFrame.new(x, HEIGHT - 7, -3)).Position, C.GoldPale, M.Neon))
		Kit.light(glow, Kit.rgb(255, 196, 120), 30, 0.9)
	end
	-- spare stock on the floor: swords in a barrel by the door
	for _, side in { -1, 1 } do
		local barrel = BASE * CFrame.new(side * 12, 1, -DEPTH / 2 + 5)
		Kit.column(inner, "Barrel", barrel.Position, 4.2, 4, C.Wood, M.WoodPlanks)
		for i = 1, 5 do
			local a = i / 5 * 6.28
			sword(inner, barrel * CFrame.new(math.cos(a) * 0.9, 2.4, math.sin(a) * 0.9) * CFrame.Angles(math.cos(a) * 0.14, 0, math.sin(a) * 0.14), true)
		end
	end
end

local function keeper(m)
	local stand = BASE * CFrame.new(0, 1, 11.5) * CFrame.Angles(0, 0, 0)
	local robe = Kit.rgb(112, 40, 52)
	local fig = Kit.figure(m, "Shopkeeper", stand, robe, M.Fabric, 1.15, { headColor = Kit.rgb(214, 172, 132), legColor = Kit.rgb(84, 30, 40) })
	local head = fig:FindFirstChild("Head")
	local hood = Kit.box(fig, "Hood", head.Size + Vector3.new(0.5, 0.5, 0.5), head.CFrame * CFrame.new(0, 0.2, 0.4), Kit.rgb(70, 26, 36), M.Fabric)
	Kit.noShadow(hood)
	-- face looks at the door: dark eyes on the front
	for _, s in { -1, 1 } do
		Kit.noShadow(Kit.box(fig, "Eye", Vector3.new(0.3, 0.3, 0.1), head.CFrame * CFrame.new(s * 0.45, 0.2, -head.Size.Z / 2 - 0.02), C.Ink, M.SmoothPlastic))
	end
	local torso = fig:FindFirstChild("Torso")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "" -- just the key: the nameplate already says who he is
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 18
	prompt.HoldDuration = 0
	prompt.Parent = torso
	Kit.nameplate(head, "The Keeper", "", C.GoldPale, 4, 40)
	-- where you come back to from the training hall
	Kit.box(m, "ShopArrival", Vector3.new(1, 1, 1), BASE * CFrame.new(0, 1, 2) * CFrame.Angles(0, math.rad(180), 0), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
end

function Shop.Build(root)
	local m = Kit.model(root, "Shop")
	shell(m)
	exterior(m)
	interior(m)
	keeper(m)
	return m
end

return Shop
