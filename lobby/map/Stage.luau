--!nonstrict
-- The training arena the shop fades to. A dummy wearing the class performs its real skills on a second dummy in the middle (the boss
-- place's own class kits run here, see TryoutService). A walled sand arena with tiered stands and an arcade, big because some skills
-- leap or dash a long way. Blender meshes (lobby/blender/stage.py, kit "Stage"); this file places them and adds what is live: fire,
-- light, sandbags hanging on ropes (they swing when knocked), and the score board StageBoardService writes on.
-- Orbs are shown on the dais to one side (OrbSpot), by a dummy that exists only on the viewer's client.
local Kit = require(script.Parent.Kit)
local Assets = require(script.Parent.Assets)
local Gates = require(script.Parent.Gates)
local C, M = Kit.C, Kit.M
local B = Gates.B

local Stage = {}
local O = Vector3.new(0, -400, -4000)
Stage.Origin = O

local function piece(parent, name, cf, scale)
	local model = Assets.Get(name)
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

-- facing the middle, at angle `deg` (0 = +X, 90 = +Z) and radius `r`
local function ring(deg, r, y)
	local a = math.rad(deg)
	local p = O + Vector3.new(math.cos(a) * r, y or 0, math.sin(a) * r)
	return CFrame.lookAt(p, Vector3.new(O.X, p.Y, O.Z))
end

local function fire(parent, pos, size)
	local p = Kit.detail(Kit.box(parent, "Fire", Vector3.new(1, 1, 1), CFrame.new(pos), nil, nil, { Transparency = 1, CanQuery = false, CanTouch = false }))
	local f = Instance.new("Fire")
	f.Size, f.Heat = size or 6, 9
	f.Color, f.SecondaryColor = Kit.rgb(255, 150, 50), Kit.rgb(255, 220, 120)
	f.Parent = p
	Kit.light(p, Kit.rgb(255, 180, 110), 50, 1.4)
	return p
end

-- A sandbag on a rope from `hook`: unanchored, so a shove or a dash sets it swinging.
local function sandbag(parent, hook)
	local anchor = Kit.box(parent, "BagHook", Vector3.new(0.4, 0.4, 0.4), CFrame.new(hook), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local bag = piece(parent, "StageSandbag", CFrame.new(hook - Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, Kit.R:NextNumber(0, 6.28), 0))
	bag.Name = "Sandbag"
	local main = bag:FindFirstChild("Fabric")
	for _, part in bag:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = part == main
			part.CanQuery = part == main
			if part ~= main then
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = main, part
				w.Parent = part
			end
		end
	end
	main.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.6, 0.2)
	local a0 = Instance.new("Attachment")
	a0.Parent = anchor
	local a1 = Instance.new("Attachment")
	a1.Parent = main -- parent first: WorldPosition is only world-relative once the attachment has a part
	a1.WorldPosition = hook - Vector3.new(0, 1.6, 0)
	local rope = Instance.new("RopeConstraint")
	rope.Attachment0, rope.Attachment1 = a0, a1
	rope.Length = 1.6
	rope.Visible = true
	rope.Color = BrickColor.new("Brown")
	rope.Thickness = 0.2
	rope.Parent = anchor
	bag.PrimaryPart = main
	return bag
end

-- The score board: three lines StageBoardService fills in.
local function board(parent, cf)
	local b = piece(parent, "StageBoard", cf)
	b.Name = "Board"
	local face = b:FindFirstChild("Ink")
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Score"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(600, 340)
	gui.LightInfluence = 0
	gui.Parent = face
	local function line(name, y, size, color, text)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(20, y)
		l.Size = UDim2.fromOffset(560, size)
		l.Font = Enum.Font.Garamond
		l.TextScaled = true
		l.TextColor3 = color
		l.Text = text
		l.Parent = gui
	end
	line("Title", 14, 60, C.GoldPale, "THE PROVING GROUND")
	line("Last", 96, 64, Color3.new(1, 1, 1), "Last hit  -")
	line("Best", 170, 64, Kit.rgb(255, 214, 120), "Best hit  -")
	line("Count", 248, 56, Kit.rgb(200, 200, 205), "Hits  0")
	return b
end

function Stage.Build(root)
	local m = Kit.folder(root, "Stage")
	piece(m, "StageArena", CFrame.new(O)).Name = "Arena"
	-- braziers round the edge of the sand, the light the arena is lit by at night
	for i = 1, 8 do
		local cf = ring(i * 45 + 22.5, 74)
		piece(m, "StageBrazier", cf).Name = "Brazier"
		fire(m, (cf * CFrame.new(0, 6.6, 0)).Position, 5)
	end
	-- the far side: sandbag gallows, weapon racks, archery targets and practice posts, out of the way of the skills
	for _, deg in { 0, 180 } do
		local cf = ring(deg, 66) * CFrame.Angles(0, math.rad(90), 0)
		piece(m, "StageBagFrame", cf).Name = "Gallows"
		for _, sx in { -1, 1 } do
			sandbag(m, (cf * B(sx * 3.2, 0, 11.1)).Position)
		end
	end
	for _, deg in { 20, 160, 200, 340 } do
		piece(m, "StageRack", ring(deg, 80)).Name = "Rack"
	end
	for _, deg in { 215, 235, 305, 325 } do
		piece(m, "StageTarget", ring(deg, 72)).Name = "Target"
	end
	for _, deg in { 120, 135, 45, 30 } do
		piece(m, "StagePost", ring(deg, 70) * CFrame.Angles(0, Kit.R:NextNumber(-0.3, 0.3), 0)).Name = "Post"
	end
	board(m, ring(90, 80))
	-- a soft light over the middle so the dummy and your own effects read clearly
	local key = Kit.box(m, "KeyLight", Vector3.new(1, 1, 1), CFrame.new(O + Vector3.new(0, 44, 0)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local spot = Instance.new("SpotLight")
	spot.Brightness, spot.Range, spot.Angle = 4, 70, 80
	spot.Color = Kit.rgb(255, 232, 196)
	spot.Face = Enum.NormalId.Bottom
	spot.Parent = key
	-- the orb dais, well away from the fighting
	local orbAt = O + Vector3.new(0, 0, -58)
	piece(m, "StageDais", CFrame.new(orbAt)).Name = "OrbDais"
	Kit.box(m, "OrbSpot", Vector3.new(1, 1, 1), CFrame.new(orbAt + Vector3.new(0, 2.3, 0)), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	-- the target dummy stands here (TryoutService puts it up); ArrivalStage is where a fall brings you back
	Kit.box(m, "DummySpot", Vector3.new(1, 1, 1), CFrame.new(O), nil, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local arrival = Kit.arrival(m, CFrame.lookAt(O + Vector3.new(0, 0.2, 30), O + Vector3.new(0, 0.2, 0)), 5)
	arrival.Name = "ArrivalStage"
	return m
end

return Stage
