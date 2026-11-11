--!nonstrict
-- The Reliquary: the shop on the hub. A timber-framed shop with a tiled roof, bay windows and a striped awning; inside, a keeper behind
-- a counter heaped with sacks, walled in by shelves of swords, potions, shields, books, scrolls and orbs. Blender meshes
-- (lobby/blender/shop.py, kit "Shop"); this file places them and adds what is live: the keeper's prompt, lamps, smoke, the sign that
-- swings on its hinge, and barrels and crates you can push about. Local frame: front (door) is -Z. Gates.B converts Blender points.
local Kit = require(script.Parent.Kit)
local Assets = require(script.Parent.Assets)
local Gates = require(script.Parent.Gates)
local C, M = Kit.C, Kit.M
local B = Gates.B

local Shop = {}
local BASE = CFrame.new(84, 400, 18) * CFrame.Angles(0, math.rad(90), 0)
local HEIGHT, DEPTH = 24, 36

local BREWS = { Kit.rgb(230, 60, 70), Kit.rgb(70, 150, 245), Kit.rgb(90, 220, 120), Kit.rgb(245, 180, 60), Kit.rgb(190, 90, 240) }
local SHIELDS = { Kit.rgb(140, 36, 40), Kit.rgb(40, 70, 130), Kit.rgb(60, 100, 60) }

local function piece(parent, name, cf, scale)
	local model = Assets.Get(name)
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

local function detail(model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
		end
	end
	return model
end

local function tint(model, role, color)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name == role then
			part.Color = color
		end
	end
	return model
end

-- an unanchored prop welded into one body, so players can shove it about
local function physical(model)
	local main
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			main = main or part
			part.Anchored = false
			part.CanCollide = true
			part.CanQuery = true
		end
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= main then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = main, part
			w.Parent = part
		end
	end
	model.PrimaryPart = main
	return model
end

-- One shelf unit's stock: a different kind of thing on each shelf, the odd orb crammed in.
local LEVELS = { 1.2, 5.9, 10.6, 15.3 }
local function stock(parent, shelfCF, r)
	for row, z in LEVELS do
		local kind = (row + r:NextInteger(0, 3)) % 5
		local u = -5.0
		while u < 5.0 do
			local at = shelfCF * CFrame.new(u, z + 0.2, 0.1)
			local width
			if r:NextNumber() < 0.1 then
				tint(detail(piece(parent, "ShopOrbStand", at)), "Neon", BREWS[r:NextInteger(1, #BREWS)])
				width = 1.4
			elseif kind == 0 then
				tint(detail(piece(parent, "ShopPotion", at * CFrame.Angles(0, r:NextNumber(-0.5, 0.5), 0))), "Neon", BREWS[r:NextInteger(1, #BREWS)])
				width = 1.5
			elseif kind == 1 then
				detail(piece(parent, "ShopSword", at * CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, r:NextNumber(-0.06, 0.06))))
				width = 1.3
			elseif kind == 2 then
				tint(detail(piece(parent, "ShopShield", at * CFrame.new(0, 1.7, 0.3) * CFrame.Angles(math.rad(-10), 0, 0))), "Red", SHIELDS[r:NextInteger(1, #SHIELDS)])
				width = 3.3
			elseif kind == 3 then
				detail(piece(parent, "ShopBooks", at))
				width = 2.4
			else
				detail(piece(parent, "ShopScroll", at))
				width = 2.2
			end
			u += width + r:NextNumber(0.1, 0.4)
		end
	end
end

local function interior(m)
	local inner = Kit.folder(m, "Stock")
	local r = Kit.R
	-- shelves: three along the back wall, two down each side, floor to rafters
	local units = {}
	for _, x in { -13, 0, 13 } do
		local p = (BASE * B(x, 15.7, 1)).Position
		table.insert(units, CFrame.lookAt(p, (BASE * B(x, 0, 1)).Position))
	end
	for _, sx in { -1, 1 } do
		for _, y in { -5.5, 7 } do
			local p = (BASE * B(sx * 19.7, y, 1)).Position
			table.insert(units, CFrame.lookAt(p, (BASE * B(0, y, 1)).Position))
		end
	end
	for _, cf in units do
		piece(inner, "ShopShelf", cf).Name = "Shelves"
		stock(inner, cf, r)
	end
	-- the counter across the shop, heaped with sacks either side of the keeper
	piece(m, "ShopCounter", BASE * B(0, 6, 1)).Name = "Counter"
	for i, x in { -11, -8, -5, 5, 8, 11 } do
		local sack = detail(piece(inner, "ShopSack", BASE * B(x + r:NextNumber(-0.4, 0.4), 2.6, 1) * CFrame.Angles(0, r:NextNumber(0, 6.28), 0), r:NextNumber(0.85, 1.05)))
		tint(sack, "Fabric", ({ Kit.rgb(216, 192, 140), Kit.rgb(196, 140, 80), Kit.rgb(226, 212, 176) })[i % 3 + 1])
	end
	-- on the counter: a balance, a ledger, coin, and the orb of the day
	local top = BASE * CFrame.new(0, 6.5, 6)
	Kit.detail(Kit.box(inner, "ScalePost", Vector3.new(0.4, 3.6, 0.4), top * CFrame.new(8, 1.8, 0), C.GoldDeep, M.Metal))
	Kit.detail(Kit.box(inner, "ScaleBar", Vector3.new(5, 0.25, 0.25), top * CFrame.new(8, 3.5, 0), C.GoldDeep, M.Metal))
	for _, s in { -1, 1 } do
		Kit.detail(Kit.cyl(inner, "ScalePan", 0.16, 2.2, top * CFrame.new(8 + s * 2.4, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)), C.Gold, M.Metal))
	end
	Kit.detail(Kit.box(inner, "Ledger", Vector3.new(3, 0.5, 2.2), top * CFrame.new(-7, 0.3, 0) * CFrame.Angles(0, 0.3, 0), Kit.rgb(100, 40, 34), M.Leather))
	local orb = tint(detail(piece(inner, "ShopOrbStand", top * CFrame.new(4.6, 0, -0.6), 1.4)), "Neon", Kit.rgb(240, 170, 255))
	orb.Name = "OrbOfTheDay"
	Kit.light(orb:FindFirstChild("Neon"), Kit.rgb(240, 170, 255), 12, 0.6)
	for _ = 1, 22 do
		Kit.detail(Kit.cyl(inner, "Coin", 0.16, 1, top * CFrame.new(r:NextNumber(-5, -2), 0.1 + r:NextNumber(0, 0.5), r:NextNumber(-1.4, 1.4)) * CFrame.Angles(0, 0, math.rad(90) + r:NextNumber(-0.25, 0.25)), C.Gold, M.Foil))
	end
	-- warm lamps hung from the beams
	for _, x in { -13, 0, 13 } do
		Kit.detail(Kit.box(inner, "Chain", Vector3.new(0.2, 4, 0.2), BASE * CFrame.new(x, HEIGHT - 3, -3), C.StoneDark, M.Metal))
		local glow = Kit.detail(Kit.ball(inner, "Lamp", 2.2, (BASE * CFrame.new(x, HEIGHT - 6, -3)).Position, C.GoldPale, M.Neon))
		Kit.light(glow, Kit.rgb(255, 196, 120), 30, 0.9)
	end
	Kit.noShadow(Kit.box(m, "Rug", Vector3.new(9, 0.12, 6), BASE * CFrame.new(0, 1.12, -DEPTH / 2 + 5), Kit.rgb(132, 34, 40), M.Fabric))
	Kit.noShadow(Kit.box(m, "RugTrim", Vector3.new(9.6, 0.1, 6.6), BASE * CFrame.new(0, 1.09, -DEPTH / 2 + 5), C.GoldDeep, M.Fabric))
end

local function keeper(m)
	-- the keeper: an R6 avatar leaning on his counter
	local R6Pose = require(game:GetService("ReplicatedStorage").Lobby.R6Pose)
	local scale = 1.9
	local fig = R6Pose.build(m, "Shopkeeper", { skin = Kit.rgb(226, 178, 138), torso = Kit.rgb(112, 40, 52), arms = Kit.rgb(112, 40, 52), legs = Kit.rgb(84, 30, 40) })
	for _, part in fig:GetChildren() do
		if part:IsA("BasePart") then
			part.Size *= scale
		end
	end
	local _, head = R6Pose.place(fig, BASE * B(0, 11.5, 1), { shR = { 52, 0, 8 }, shL = { 52, 0, -8 }, spine = { -6, 0, 0 }, neck = { -6, 0, 0 } }, scale)
	-- he wears elcuh_4l's avatar (R6Pose.dress); if it cannot load, the old robe, star-spangled hat and long white beard stand in
	if not R6Pose.dress(fig, "elcuh_4l", scale) then
		local hat = Assets.Get("KeeperHat")
		hat:ScaleTo(scale * 0.55)
		hat:PivotTo(head * CFrame.new(0, 0.5 * scale, 0))
		hat.Name = "Hat"
		hat.Parent = fig
		local beard = Assets.Get("KeeperBeard")
		beard:ScaleTo(scale * 0.62)
		beard:PivotTo(head * CFrame.new(0, -0.15 * scale, -0.5 * scale))
		beard.Name = "Beard"
		beard.Parent = fig
	end
	for _, part in fig:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = part.Name == "Torso"
		end
	end
	local robe, face = fig:FindFirstChild("Torso"), fig:FindFirstChild("Head")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "" -- just the key: the nameplate already says who he is
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 18
	prompt.HoldDuration = 0
	prompt.Parent = robe
	Kit.nameplate(face, "The Keeper", "", C.GoldPale, 4, 40)
	-- where you come back to from the training hall
	Kit.box(m, "ShopArrival", Vector3.new(1, 1, 1), BASE * CFrame.new(0, 1, 2) * CFrame.Angles(0, math.rad(180), 0), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
end

local function outside(m)
	-- the hanging sign: hinged on its bracket and free to swing (AmbientService gives it a gust now and then)
	local hingeCF = BASE * B(-19, -18 - 6.4, 20.6)
	local anchor = Kit.box(m, "SignHinge", Vector3.new(0.4, 0.4, 0.4), hingeCF, nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local board = piece(m, "ShopSignBoard", hingeCF)
	board.Name = "Sign"
	physical(board)
	for _, part in board:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
	local a0 = Instance.new("Attachment")
	a0.Parent = anchor
	local a1 = Instance.new("Attachment")
	a1.CFrame = board.PrimaryPart.CFrame:ToObjectSpace(hingeCF)
	a1.Parent = board.PrimaryPart
	local hinge = Instance.new("HingeConstraint")
	hinge.Attachment0, hinge.Attachment1 = a0, a1
	hinge.Parent = anchor
	Kit.tag(board, "UnfairSway")
	-- lanterns on the door posts, under the awning
	for _, side in { -1, 1 } do
		Kit.wallLantern(m, BASE * CFrame.new(side * 9.6, 10.5, -DEPTH / 2 - 1))
	end
	-- chimney smoke
	local smoke = Kit.detail(Kit.box(m, "Smoke", Vector3.new(2.4, 0.4, 2.4), BASE * B(12, 9, 43.6), nil, nil, { Transparency = 1 }))
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
	-- the yard: barrels and crates either side of the door that you can shove about
	local yard = Kit.folder(m, "Yard")
	for _, spot in { { "ShopBarrel", -24, -22.5 }, { "ShopBarrel", -27.5, -21 }, { "ShopCrate", 24, -22.5 }, { "ShopCrate", 27.4, -21.4 }, { "ShopBarrel", 26, -26 } } do
		local prop = piece(yard, spot[1], BASE * B(spot[2], spot[3], 0.2) * CFrame.Angles(0, Kit.R:NextNumber(0, 6.28), 0))
		physical(prop)
	end
	-- the landmark: the store greatsword (Wirly_world's gothic blade), gilded and huge, driven point-first through the roof
	local giant = Assets.Get("GothicSword")
	local blade = giant:FindFirstChildWhichIsA("MeshPart", true)
	local length = 84
	blade.Size *= length / math.max(blade.Size.X, blade.Size.Y, blade.Size.Z)
	blade.CFrame = BASE * CFrame.new(0, 45, 4) * CFrame.Angles(0, 0, math.rad(-7)) * CFrame.new(0, length * 0.3, 0) * CFrame.Angles(0, 0, math.rad(90))
	local look = blade:FindFirstChildOfClass("SurfaceAppearance")
	if look then
		look.Color = Kit.rgb(255, 214, 120)
	end
	giant.Name = "GiantSword"
	giant.Parent = m
end

function Shop.Build(root)
	local m = Kit.model(root, "Shop")
	piece(m, "ShopHouse", BASE).Name = "House"
	interior(m)
	keeper(m)
	outside(m)
	return m
end

return Shop
