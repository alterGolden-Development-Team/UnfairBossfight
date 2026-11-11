--[[
 TrainingDummy - the target in the lobby's class showroom (the Golden Encounter has none any more).
 A wooden straw dummy on a post. Its R6-named parts (HumanoidRootPart, Torso, Head, arms, legs) are invisible hitboxes so every kit
 finds what it looks for; what you see is the Blender mesh "TrainingDummy" (lobby/blender/realm.py, MeshKit kit Realm), or a
 part-built dummy of the same shape when the place has no meshes yet.

 The readout over its head is plain text, no box: DPS, the last hit and the total of the current burst.
 DPS = damage of the current burst / time since its first hit (at least 1 s). A burst ends after IDLE seconds without a hit; the
 readout then keeps the burst's final numbers until the next hit starts a new one. Damage is read from the health it loses, so every
 source counts the same (direct hits, damage over time, summons, clones, explosions).
]]
local api = {}
-- Humanoid.Health is a 32-bit float. At the old 1,000,000,000 it could only move in steps of 64, so any hit under ~32 (laser ticks,
-- damage over time, small orbs) vanished and bigger ones were rounded. Below 2^24 = 16,777,216 the step is 1 HP, so the pool sits
-- there and is topped back up after every hit: every point of damage shows, and no single hit in the game can empty it.
local MAX_HEALTH = 16000000
local IDLE = 3

local function part(model, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, true
	p.Material, p.Color = material or Enum.Material.SmoothPlastic, color or Color3.new(1, 1, 1)
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = model
	return p
end

-- the look, built from parts: same silhouette as the Blender mesh
local function partLook(model, base)
	local look = Instance.new("Model")
	look.Name = "Look"
	local wood, dark, straw, sack, rope = Color3.fromRGB(122, 84, 52), Color3.fromRGB(78, 52, 34), Color3.fromRGB(214, 180, 112), Color3.fromRGB(196, 170, 128), Color3.fromRGB(150, 120, 80)
	local W, F = Enum.Material.Wood, Enum.Material.Fabric
	local function cyl(name, length, d, cf, color, material)
		local p = part(look, name, Vector3.new(length, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder)
		p.CanQuery = false
		return p
	end
	local function block(name, size, cf, color, material)
		local p = part(look, name, size, cf, color, material)
		p.CanQuery = false
		return p
	end
	block("BaseA", Vector3.new(5, 0.6, 1), CFrame.new(base + Vector3.new(0, 0.3, 0)), dark, W)
	block("BaseB", Vector3.new(1, 0.6, 5), CFrame.new(base + Vector3.new(0, 0.3, 0)), dark, W)
	cyl("Post", 4.2, 0.7, CFrame.new(base + Vector3.new(0, 2.4, 0)), wood, W)
	cyl("Body", 3, 2.3, CFrame.new(base + Vector3.new(0, 4.6, 0)), straw, Enum.Material.Sand)
	for _, y in { 3.5, 4.6, 5.7 } do
		cyl("Band", 0.22, 2.42, CFrame.new(base + Vector3.new(0, y, 0)), rope, F)
	end
	cyl("Arms", 4.6, 0.55, CFrame.new(base + Vector3.new(0, 5.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), wood, W)
	for _, s in { -1, 1 } do
		part(look, "Fist", Vector3.new(0.9, 0.9, 0.9), CFrame.new(base + Vector3.new(s * 2.4, 5.4, 0)), sack, F, Enum.PartType.Ball).CanQuery = false
	end
	part(look, "Head", Vector3.new(1.7, 1.7, 1.7), CFrame.new(base + Vector3.new(0, 7, 0)), sack, F, Enum.PartType.Ball).CanQuery = false
	-- a painted target on the chest
	local target = cyl("Target", 0.05, 1.3, CFrame.new(base + Vector3.new(0, 4.7, -1.16)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(190, 48, 40), Enum.Material.SmoothPlastic)
	target.CastShadow = false
	local inner = cyl("TargetInner", 0.06, 0.6, CFrame.new(base + Vector3.new(0, 4.7, -1.17)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(236, 224, 196), Enum.Material.SmoothPlastic)
	inner.CastShadow = false
	look.Parent = model
end

local function meshLook(model, base)
	local ok, MeshKit = pcall(function()
		return require(game:GetService("ReplicatedStorage").BossShared.Presentation.MeshKit)
	end)
	local look = ok and MeshKit.Get("TrainingDummy")
	if not look then
		return false
	end
	look.Name = "Look"
	look:PivotTo(CFrame.new(base) * CFrame.Angles(0, math.pi, 0))
	for _, p in look:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		end
	end
	look.Parent = model
	return true
end

local function readout(model, humanoid)
	local gui = Instance.new("BillboardGui")
	gui.Name = "DPSDisplay"
	gui.Size = UDim2.fromOffset(220, 66)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	gui.Adornee = model.Head
	gui.Parent = model.Head
	local function label(name, y, h, size, color, font)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position, l.Size = UDim2.new(0, 0, 0, y), UDim2.new(1, 0, 0, h)
		l.Font, l.TextSize, l.TextColor3 = font, size, color
		l.TextStrokeTransparency, l.TextStrokeColor3 = 0.15, Color3.fromRGB(28, 18, 8)
		l.Text = ""
		l.Parent = gui
		return l
	end
	local dpsLabel = label("Readout", 0, 38, 30, Color3.fromRGB(255, 226, 140), Enum.Font.GothamBlack)
	local detail = label("Detail", 38, 22, 15, Color3.fromRGB(240, 232, 214), Enum.Font.GothamMedium)
	dpsLabel.Text = "DPS 0"
	detail.Text = "hit me"

	local function fmt(n)
		local s = tostring(math.floor(n + 0.5)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
		return (s:gsub("^,", ""))
	end
	local previous = humanoid.Health
	local burstStart, lastHitAt, burstTotal, lastHit = nil, 0, 0, 0
	local function show()
		if not burstStart then
			return
		end
		local span = math.max(1, lastHitAt - burstStart)
		if os.clock() - lastHitAt < IDLE then
			span = math.max(1, os.clock() - burstStart)
		end
		local dps = burstTotal / span
		dpsLabel.Text = "DPS " .. fmt(dps)
		detail.Text = string.format("last %s  ·  total %s", fmt(lastHit), fmt(burstTotal))
		model:SetAttribute("DPS", dps)
		model:SetAttribute("BurstTotal", burstTotal)
	end
	humanoid.HealthChanged:Connect(function(current)
		local dealt = previous - current
		previous = current
		if current < MAX_HEALTH and current > 0 then
			previous = MAX_HEALTH
			humanoid.Health = MAX_HEALTH -- straight back up, so the next hit is measured at full precision too
		end
		if dealt <= 0 then
			return -- a heal, or the top-up itself
		end
		local t = os.clock()
		if not burstStart or t - lastHitAt > IDLE then
			burstStart, burstTotal = t, 0
		end
		lastHitAt, lastHit = t, dealt
		burstTotal += dealt
		show()
	end)
	task.spawn(function()
		while model.Parent do
			task.wait(0.25)
			if burstStart and os.clock() - lastHitAt < IDLE then
				show()
			end
		end
	end)
end

local function create(standAt)
	if not standAt then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "ClassTrainingDummy"
	model:SetAttribute("DamageableClone", true)
	model:SetAttribute("TrainingDummy", true)
	local base = standAt
	local torsoCF = CFrame.new(base + Vector3.new(0, 4.6, 0))
	local hidden = Color3.fromRGB(122, 84, 52)
	local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), torsoCF, hidden)
	model.PrimaryPart = root
	-- invisible R6-named hitboxes: kits aim at and attach effects to these
	for name, spec in {
		Torso = { Vector3.new(2.3, 3, 2.3), torsoCF },
		Head = { Vector3.new(1.7, 1.7, 1.7), torsoCF * CFrame.new(0, 2.4, 0) },
		["Left Arm"] = { Vector3.new(1, 1, 1), torsoCF * CFrame.new(-2.4, 0.8, 0) },
		["Right Arm"] = { Vector3.new(1, 1, 1), torsoCF * CFrame.new(2.4, 0.8, 0) },
		["Left Leg"] = { Vector3.new(0.7, 2, 0.7), torsoCF * CFrame.new(0, -2.6, 0) },
		["Right Leg"] = { Vector3.new(0.7, 2, 0.7), torsoCF * CFrame.new(0, -2.6, 0) },
	} do
		part(model, name, spec[1], spec[2], hidden)
	end
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			p.Transparency = 1
		end
	end
	if not meshLook(model, base) then
		partLook(model, base)
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.Name, humanoid.MaxHealth, humanoid.Health = "Humanoid", MAX_HEALTH, MAX_HEALTH
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Parent = model
	readout(model, humanoid)
	humanoid.Died:Connect(function()
		task.delay(0.15, function()
			if humanoid.Parent and model.Parent then
				humanoid.Health = MAX_HEALTH
			end
		end)
	end)
	model.Parent = workspace
	return model
end

-- The lobby's training hall stands one where it likes (standAt = the point on the floor under it).
function api.Create(standAt)
	return create(standAt)
end

-- Kept for older callers: the Golden Encounter no longer puts up a dummy.
function api.Start() end

return api
