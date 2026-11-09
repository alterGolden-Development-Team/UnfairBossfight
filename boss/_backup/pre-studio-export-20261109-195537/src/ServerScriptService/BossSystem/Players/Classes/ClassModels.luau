 
local M = {}
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local METAL, NEON, FABRIC, WOOD, LEATHER = Enum.Material.Metal, Enum.Material.Neon, Enum.Material.Fabric, Enum.Material.Wood, Enum.Material.Leather
local BALL, CYL, WEDGE = Enum.PartType.Ball, Enum.PartType.Cylinder, "Wedge"

local function holder(char)
	local h = char:FindFirstChild("ClassGear")
	if not h then
		h = Instance.new("Folder")
		h.Name = "ClassGear"
		h.Parent = char
	end
	return h
end
 
local function piece(char, limb, size, color, material, offset, shape, name, transparency)
	local to = char:FindFirstChild(limb)
	if not to then
		return
	end
	local p
	if shape == WEDGE then
		p = Instance.new("WedgePart")
	else
		p = Instance.new("Part")
		if shape then
			p.Shape = shape
		end
	end
	p.Name = name or "Gear"
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CFrame = to.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = to, p
	w.Parent = p
	p.Parent = holder(char)
	return p
end
local function glow(p, color, range, brightness)
	if p then
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = color, range or 8, brightness or 1.5, false
		l.Parent = p
	end
end
local function trail(p, color, length)
	if not p then
		return
	end
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, 0, -length / 2), Vector3.new(0, 0, length / 2)
	a0.Parent, a1.Parent = p, p
	local t = Instance.new("Trail")
	t.Name = "SwingTrail"
	t.Attachment0, t.Attachment1 = a0, a1
	t.Color = ColorSequence.new(color, rgb(255, 255, 255))
	t.LightEmission = 1
	t.Lifetime = 0.18
	t.MinLength = 0.1
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	t.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
	t.Parent = p
end

local R = CFrame.Angles
local rad = math.rad

function M.Warrior(char)
	local RED, STEEL, GOLD, DARK = rgb(196, 48, 42), rgb(210, 214, 222), rgb(232, 186, 74), rgb(60, 36, 24)
	 
	local H = CFrame.new(0, -1.05, 0)
	piece(char, "Right Arm", Vector3.new(0.9, 0.24, 0.24), DARK, LEATHER, H * CFrame.new(0, 0, 0.05) * R(0, rad(90), 0), CYL, "Grip")
	piece(char, "Right Arm", Vector3.one * 0.38, GOLD, METAL, H * CFrame.new(0, 0, 0.55), BALL, "Pommel")
	piece(char, "Right Arm", Vector3.new(1.7, 0.22, 0.3), GOLD, METAL, H * CFrame.new(0, 0, -0.45), nil, "Crossguard")
	piece(char, "Right Arm", Vector3.new(0.3, 0.3, 0.3), RED, NEON, H * CFrame.new(0, 0, -0.45) * R(rad(45), 0, rad(45)), nil, "GuardGem")
	local blade = piece(char, "Right Arm", Vector3.new(0.12, 0.42, 3.3), STEEL, METAL, H * CFrame.new(0, 0, -2.25), nil, "Blade")
	piece(char, "Right Arm", Vector3.new(0.13, 0.1, 2.9), RED, NEON, H * CFrame.new(0, 0, -2.15), nil, "Fuller")
	piece(char, "Right Arm", Vector3.new(0.12, 0.21, 0.55), STEEL, METAL, H * CFrame.new(0, 0.105, -4.17) * R(0, rad(180), 0), WEDGE, "TipA")
	piece(char, "Right Arm", Vector3.new(0.12, 0.21, 0.55), STEEL, METAL, H * CFrame.new(0, -0.105, -4.17) * R(0, rad(180), rad(180)), WEDGE, "TipB")
	trail(blade, RED, 3.2)
	 
	local S = CFrame.new(-0.62, -0.35, 0)
	piece(char, "Left Arm", Vector3.new(0.2, 3, 3), GOLD, METAL, S * CFrame.new(-0.02, 0, 0), CYL, "ShieldRim")
	piece(char, "Left Arm", Vector3.new(0.24, 2.7, 2.7), RED, METAL, S * CFrame.new(-0.06, 0, 0), CYL, "ShieldFace")
	piece(char, "Left Arm", Vector3.new(0.27, 2.2, 0.32), GOLD, METAL, S * CFrame.new(-0.08, 0, 0), nil, "EmblemV")
	piece(char, "Left Arm", Vector3.new(0.27, 0.32, 1.7), GOLD, METAL, S * CFrame.new(-0.08, 0.3, 0), nil, "EmblemH")
	piece(char, "Left Arm", Vector3.one * 0.6, GOLD, METAL, S * CFrame.new(-0.2, 0, 0), BALL, "ShieldBoss")
	 
	piece(char, "Torso", Vector3.new(1.3, 0.5, 1.3), GOLD, METAL, CFrame.new(1.45, 0.95, 0), nil, "Pauldron")
	piece(char, "Torso", Vector3.new(2.05, 0.3, 1.05), DARK, LEATHER, CFrame.new(0, -0.8, 0), nil, "Belt")
	piece(char, "Torso", Vector3.new(0.4, 0.4, 0.15), GOLD, METAL, CFrame.new(0, -0.8, -0.55), nil, "Buckle")
end

function M.Mage(char)
	local PURPLE, DEEP, PALE, GOLD = rgb(126, 74, 214), rgb(52, 30, 92), rgb(225, 205, 255), rgb(226, 190, 96)
	 
	piece(char, "Head", Vector3.new(0.18, 3, 3), DEEP, FABRIC, CFrame.new(0, 0.62, 0) * R(0, 0, rad(90)), CYL, "Brim")
	piece(char, "Head", Vector3.new(0.5, 1.45, 1.45), DEEP, FABRIC, CFrame.new(0, 0.95, 0) * R(0, 0, rad(90)), CYL, "HatTier1")
	piece(char, "Head", Vector3.new(0.12, 1.5, 1.5), GOLD, METAL, CFrame.new(0, 0.78, 0) * R(0, 0, rad(90)), CYL, "HatBand")
	piece(char, "Head", Vector3.new(0.6, 1.0, 1.0), DEEP, FABRIC, CFrame.new(0, 1.45, 0.05) * R(0, 0, rad(90)), CYL, "HatTier2")
	piece(char, "Head", Vector3.new(0.6, 0.55, 0.55), DEEP, FABRIC, CFrame.new(0, 1.95, 0.2) * R(rad(-20), 0, rad(90)), CYL, "HatTier3")
	piece(char, "Head", Vector3.one * 0.35, PALE, NEON, CFrame.new(0, 2.25, 0.4), BALL, "HatStar")
	 
	piece(char, "Torso", Vector3.new(2.08, 2.05, 1.08), PURPLE, FABRIC, CFrame.new(), nil, "Robe")
	piece(char, "Torso", Vector3.new(0.3, 2.06, 1.1), GOLD, FABRIC, CFrame.new(0, 0, 0), nil, "RobeTrim")
	piece(char, "Torso", Vector3.new(2.3, 1.6, 1.3), PURPLE, FABRIC, CFrame.new(0, -1.75, 0), nil, "RobeSkirt")
	piece(char, "Torso", Vector3.new(2.32, 0.18, 1.32), GOLD, FABRIC, CFrame.new(0, -2.5, 0), nil, "SkirtHem")
	 
	piece(char, "Torso", Vector3.new(0.35, 1, 0.8), rgb(90, 40, 40), LEATHER, CFrame.new(-1.15, -0.9, 0), nil, "Spellbook")
	piece(char, "Torso", Vector3.new(0.37, 0.4, 0.4), PALE, NEON, CFrame.new(-1.15, -0.9, 0), nil, "BookRune")
	 
	glow(piece(char, "Right Arm", Vector3.one * 0.75, PALE, NEON, CFrame.new(0, -1.45, -0.45), BALL, "HandOrb"), PURPLE, 9, 2)
	for i = 1, 3 do
		local a = i * math.pi * 2 / 3
		piece(char, "Torso", Vector3.one * 0.35, PALE, NEON, CFrame.new(math.cos(a) * 1.7, 1.4, math.sin(a) * 1.2) * R(rad(45), rad(45), 0), nil, "Rune" .. i)
	end
end

function M.Tank(char)
	local STEEL, DARK, BLUE, CREAM = rgb(150, 160, 175), rgb(70, 76, 88), rgb(70, 110, 170), rgb(230, 220, 170)
	piece(char, "Torso", Vector3.new(2.3, 2.2, 1.35), STEEL, METAL, CFrame.new(), nil, "Chestplate")
	piece(char, "Torso", Vector3.new(1.4, 0.9, 0.1), BLUE, METAL, CFrame.new(0, 0.3, -0.7), nil, "Tabard")
	piece(char, "Torso", Vector3.new(2.35, 0.35, 1.4), DARK, METAL, CFrame.new(0, -0.85, 0), nil, "Fauld")
	for _, side in ipairs({ -1, 1 }) do
		piece(char, "Torso", Vector3.new(1.4, 0.6, 1.5), STEEL, METAL, CFrame.new(1.5 * side, 1.0, 0) * R(0, 0, rad(-12 * side)), nil, "Pauldron")
		piece(char, "Torso", Vector3.new(1.45, 0.15, 1.55), CREAM, METAL, CFrame.new(1.5 * side, 1.25, 0) * R(0, 0, rad(-12 * side)), nil, "PauldronTrim")
	end
	piece(char, "Head", Vector3.new(1.35, 1.35, 1.35), STEEL, METAL, CFrame.new(0, 0.12, 0), nil, "Helm")
	piece(char, "Head", Vector3.new(1.0, 0.14, 0.2), rgb(15, 18, 24), METAL, CFrame.new(0, 0.15, -0.66), nil, "Visor")
	piece(char, "Head", Vector3.new(0.18, 0.5, 1.5), BLUE, FABRIC, CFrame.new(0, 0.95, 0.05), nil, "Crest")
	for _, arm in ipairs({ "Left Arm", "Right Arm" }) do
		piece(char, arm, Vector3.new(1.15, 0.9, 1.15), STEEL, METAL, CFrame.new(0, -0.6, 0), nil, "Gauntlet")
	end
	for _, leg in ipairs({ "Left Leg", "Right Leg" }) do
		piece(char, leg, Vector3.new(1.1, 1.2, 1.15), STEEL, METAL, CFrame.new(0, -0.35, 0), nil, "Greave")
	end
	 
	local S = CFrame.new(-0.85, -0.4, -0.35)
	piece(char, "Left Arm", Vector3.new(0.35, 4.8, 3.2), DARK, METAL, S, nil, "ShieldFrame")
	piece(char, "Left Arm", Vector3.new(0.4, 4.4, 2.8), BLUE, METAL, S * CFrame.new(-0.04, 0, 0), nil, "ShieldFace")
	piece(char, "Left Arm", Vector3.new(0.44, 3.4, 0.45), CREAM, METAL, S * CFrame.new(-0.07, 0, 0), nil, "ShieldCrossV")
	piece(char, "Left Arm", Vector3.new(0.44, 0.45, 2.2), CREAM, METAL, S * CFrame.new(-0.07, 0.6, 0), nil, "ShieldCrossH")
	glow(piece(char, "Left Arm", Vector3.new(0.46, 0.5, 0.5), rgb(140, 200, 255), NEON, S * CFrame.new(-0.1, 0.6, 0) * R(rad(45), 0, 0), nil, "ShieldGem"), rgb(140, 200, 255), 6, 1)
end

function M.Supporter(char)
	local GREEN, CLOAK, WOOD_C, PALE, GOLD = rgb(104, 214, 150), rgb(36, 96, 72), rgb(130, 92, 58), rgb(210, 255, 230), rgb(226, 196, 110)
	piece(char, "Head", Vector3.new(1.45, 1.35, 1.45), CLOAK, FABRIC, CFrame.new(0, 0.2, 0.12), nil, "Hood")
	piece(char, "Head", Vector3.new(1.2, 1.0, 0.1), rgb(20, 40, 32), FABRIC, CFrame.new(0, 0.05, -0.62), nil, "HoodShadow", 0.2)
	piece(char, "Torso", Vector3.new(2.3, 3.4, 0.18), CLOAK, FABRIC, CFrame.new(0, -0.6, 0.62), nil, "Cape")
	piece(char, "Torso", Vector3.new(2.35, 0.2, 1.1), GOLD, FABRIC, CFrame.new(0, 0.9, 0), nil, "Clasp")
	 
	local H = CFrame.new(0, -1.05, -0.15)
	piece(char, "Right Arm", Vector3.new(6.2, 0.26, 0.26), WOOD_C, WOOD, H * CFrame.new(0, 0.9, 0) * R(0, 0, rad(90)), CYL, "Shaft")
	piece(char, "Right Arm", Vector3.new(0.12, 1.5, 1.5), GOLD, METAL, H * CFrame.new(0, 4.1, 0), CYL, "HeadRingA")
	piece(char, "Right Arm", Vector3.new(0.12, 1.5, 1.5), GOLD, METAL, H * CFrame.new(0, 4.1, 0) * R(0, rad(90), 0), CYL, "HeadRingB")
	local gem = piece(char, "Right Arm", Vector3.new(0.55, 0.9, 0.55), GREEN, NEON, H * CFrame.new(0, 4.1, 0) * R(0, rad(45), 0), nil, "Crystal")
	glow(gem, GREEN, 12, 2)
	piece(char, "Right Arm", Vector3.one * 0.4, GOLD, METAL, H * CFrame.new(0, -2.15, 0), BALL, "Ferrule")
	 
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		local ring = piece(char, "HumanoidRootPart", Vector3.new(0.15, 40, 40), GREEN, Enum.Material.ForceField, CFrame.new(0, -2.9, 0) * R(0, 0, rad(90)), CYL, "SanctuaryAura", 0.55)
	end
end

function M.Gambler(char)
	local DARK, GOLD, RED, WHITE = rgb(30, 30, 36), rgb(232, 190, 64), rgb(150, 30, 40), rgb(250, 250, 250)
	piece(char, "Head", Vector3.new(0.15, 2.6, 2.6), DARK, FABRIC, CFrame.new(0, 0.62, 0) * R(0, 0, rad(90)), CYL, "HatBrim")
	piece(char, "Head", Vector3.new(1.3, 0.75, 1.3), DARK, FABRIC, CFrame.new(0, 1.02, 0), nil, "HatCrown")
	piece(char, "Head", Vector3.new(1.33, 0.18, 1.33), GOLD, FABRIC, CFrame.new(0, 0.78, 0), nil, "HatBand")
	piece(char, "Torso", Vector3.new(2.1, 2.05, 1.1), RED, FABRIC, CFrame.new(), nil, "Vest")
	piece(char, "Torso", Vector3.new(0.9, 1.4, 0.15), DARK, FABRIC, CFrame.new(-0.55, -1.6, 0.5), nil, "CoatTailL")
	piece(char, "Torso", Vector3.new(0.9, 1.4, 0.15), DARK, FABRIC, CFrame.new(0.55, -1.6, 0.5), nil, "CoatTailR")
	 
	local G = CFrame.new(0, -1.15, -0.35)
	piece(char, "Right Arm", Vector3.new(0.3, 0.75, 0.32), rgb(80, 50, 30), WOOD, G * CFrame.new(0, -0.3, 0.1) * R(rad(-15), 0, 0), nil, "Grip")
	piece(char, "Right Arm", Vector3.new(0.32, 0.42, 0.9), DARK, METAL, G * CFrame.new(0, 0.1, -0.3), nil, "Frame")
	piece(char, "Right Arm", Vector3.new(0.45, 0.48, 0.48), DARK, METAL, G * CFrame.new(0, 0.12, -0.35) * R(0, rad(90), 0), CYL, "Cylinder")
	piece(char, "Right Arm", Vector3.new(1.4, 0.2, 0.2), DARK, METAL, G * CFrame.new(0, 0.22, -1.25) * R(0, rad(90), 0), CYL, "Barrel")
	piece(char, "Right Arm", Vector3.new(1.42, 0.08, 0.08), GOLD, METAL, G * CFrame.new(0, 0.33, -1.25) * R(0, rad(90), 0), CYL, "BarrelTrim")
	piece(char, "Right Arm", Vector3.new(0.34, 0.1, 0.92), GOLD, METAL, G * CFrame.new(0, 0.32, -0.3), nil, "TopStrap")
	 
	local D = CFrame.new(0, -1.35, -0.45) * R(rad(25), rad(40), 0)
	local die = piece(char, "Left Arm", Vector3.one * 0.62, WHITE, Enum.Material.SmoothPlastic, D, nil, "Die")
	glow(die, GOLD, 7, 1.2)
	local pips = { { 0, 0 }, { -0.17, -0.17 }, { 0.17, 0.17 } }  
	for _, p in ipairs(pips) do
		piece(char, "Left Arm", Vector3.one * 0.1, DARK, Enum.Material.SmoothPlastic, D * CFrame.new(p[1], p[2], -0.31), BALL, "Pip")
	end
	piece(char, "Left Arm", Vector3.one * 0.1, DARK, Enum.Material.SmoothPlastic, D * CFrame.new(0, 0.31, 0), BALL, "Pip")
	piece(char, "Left Arm", Vector3.one * 0.66, GOLD, NEON, D, nil, "DieGlow", 0.85)
end

 
 
 
 
local GRIP = CFrame.new(0, -1.05, 0)
local V2 = {}
 
local function swingTrail(part, from, to, c1, c2, life)
	if not part then
		return
	end
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = from, to
	a0.Parent, a1.Parent = part, part
	local t = Instance.new("Trail")
	t.Name = "SwingTrail"
	t.Attachment0, t.Attachment1 = a0, a1
	t.Color = ColorSequence.new(c1, c2)
	t.LightEmission = 1
	t.Lifetime = life or 0.18
	t.MinLength = 0.05
	t.Enabled = false
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	t.Parent = part
end
local function tipAttachment(part, name)
	if part then
		local tip = Instance.new("Attachment")
		tip.Name = name or "Tip"
		tip.Parent = part
		return tip
	end
end
local function sparkle(att, c1, c2, rate, rise)
	if not att then
		return
	end
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(c1, c2)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.17), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Speed = NumberRange.new(0.5, 1.3)
	e.Acceleration = Vector3.new(0, rise or 0, 0)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = rate or 9
	e.Parent = att
end

function V2.Warrior(char)
	local STEEL, CRIMSON, GOLD, DARK = rgb(205, 210, 220), rgb(196, 40, 40), rgb(228, 182, 72), rgb(58, 34, 22)
	local src = game.ServerStorage:FindFirstChild("BossEncounter")
	src = src and src:FindFirstChild("Templates")
	src = src and src:FindFirstChild("alterGolden, the Nothing")
	local template = src and src:FindFirstChild("Basic Sword")
	local arm = char:FindFirstChild("Right Arm")
	if template and arm and template:FindFirstChild("Handle") then
		local handle = template.Handle
		local bossHand = src:FindFirstChild("RightHand") or src:FindFirstChild("Right Arm")
		local bossAttachment = bossHand and bossHand:FindFirstChild("RightGripAttachment")
		local handBasis = bossAttachment and bossAttachment.CFrame.Rotation or CFrame.Angles(-math.pi / 2, 0, 0)
		 
		local handMount = CFrame.new(0.18, -0.82, 0) * handBasis * CFrame.Angles(math.rad(-10), 0, 0)
		local swordGrip = require(script:FindFirstAncestor("BossSystem").Boss.WeaponController).SwordGrip()
		local target = arm.CFrame * handMount * swordGrip:Inverse()
		local swordHandle = handle:Clone()
		for _, child in ipairs(swordHandle:GetDescendants()) do
			if child:IsA("BasePart") or child:IsA("JointInstance") or child:IsA("WeldConstraint") or child:IsA("LuaSourceContainer") then child:Destroy() end
		end
		swordHandle.Name = "SwordHandle"
		swordHandle.Color = DARK
		swordHandle.CFrame = target
		swordHandle.Anchored, swordHandle.CanCollide, swordHandle.CanQuery, swordHandle.CanTouch, swordHandle.Massless = false, false, false, false, true
		swordHandle.Parent = holder(char)
		local grip = Instance.new("Weld")
		grip.Name = "WarriorSwordGrip"
		grip.Part0, grip.Part1 = arm, swordHandle
		grip.C0, grip.C1 = handMount, swordGrip
		grip.Parent = swordHandle
		for _, p in ipairs(template:GetDescendants()) do
			if p:IsA("BasePart") and p ~= handle then
				local c = p:Clone()
				for _, ch in ipairs(c:GetDescendants()) do
					if ch:IsA("BasePart") or ch:IsA("JointInstance") or ch:IsA("WeldConstraint") or ch:IsA("LuaSourceContainer") then
						ch:Destroy()
					end
				end
				c.CFrame = target * handle.CFrame:Inverse() * p.CFrame
				c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch, c.Massless = false, false, false, false, true
				if c.Material == Enum.Material.Neon then
					c.Color = CRIMSON
				elseif c.Name == "Blade" or c.Name == "BladeTip" then
					c.Color = STEEL
				elseif c.Name == "Fuller" then
					c.Color = rgb(150, 155, 168)
				elseif c.Name == "Handle" then
					c.Color = DARK
				elseif c.Name:find("GripWrap") then
					c.Color = CRIMSON
				else
					c.Color = GOLD
				end
				c.Name = "Sword" .. c.Name
				local w = Instance.new("Weld")
				w.Part0, w.Part1 = swordHandle, c
				w.C0, w.C1 = handle.CFrame:ToObjectSpace(p.CFrame), CFrame.identity
				w.Parent = c
				c.Parent = holder(char)
				if c.Name == "SwordBlade" then
					local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
					a0.Position, a1.Position = Vector3.new(0, -c.Size.Y / 2, 0), Vector3.new(0, c.Size.Y / 2, 0)
					a0.Parent, a1.Parent = c, c
					local t = Instance.new("Trail")
					t.Name = "SwingTrail"
					t.Enabled = false
					t.Attachment0, t.Attachment1 = a0, a1
					t.Color = ColorSequence.new(rgb(255, 120, 110), rgb(255, 255, 255))
					t.LightEmission = 1
					t.Lifetime = 0.16
					t.MinLength = 0.05
					t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
					t.Parent = c
					local tip = Instance.new("Attachment")
					tip.Name = "Tip"
					tip.Position = Vector3.new(0, c.Size.Y / 2, 0)
					tip.Parent = c
				end
			end
		end
	end
	local S = CFrame.new(-0.62, -0.3, 0)
	piece(char, "Left Arm", Vector3.new(0.22, 2.9, 2.9), GOLD, METAL, S, CYL, "ShieldRim")
	piece(char, "Left Arm", Vector3.new(0.26, 2.55, 2.55), CRIMSON, METAL, S * CFrame.new(-0.04, 0, 0), CYL, "ShieldFace")
	piece(char, "Left Arm", Vector3.new(0.29, 2.0, 0.28), GOLD, METAL, S * CFrame.new(-0.06, 0, 0), nil, "EmblemV")
	piece(char, "Left Arm", Vector3.new(0.29, 0.28, 2.0), GOLD, METAL, S * CFrame.new(-0.06, 0, 0), nil, "EmblemH")
	piece(char, "Left Arm", Vector3.new(0.5, 0.75, 0.75), GOLD, METAL, S * CFrame.new(-0.16, 0, 0), BALL, "ShieldBoss")
	for i = 0, 7 do
		local ang = i * math.pi / 4
		piece(char, "Left Arm", Vector3.one * 0.16, GOLD, METAL, S * CFrame.new(-0.12, math.cos(ang) * 1.12, math.sin(ang) * 1.12), BALL, "Rivet")
	end
	piece(char, "Torso", Vector3.new(1.4, 0.55, 1.35), STEEL, METAL, CFrame.new(1.42, 0.92, 0) * R(0, 0, rad(-14)), nil, "PauldronR")
	piece(char, "Torso", Vector3.new(1.45, 0.14, 1.4), GOLD, METAL, CFrame.new(1.42, 1.18, 0) * R(0, 0, rad(-14)), nil, "PauldronTrim")
	piece(char, "Torso", Vector3.new(2.06, 0.32, 1.06), DARK, LEATHER, CFrame.new(0, -0.82, 0), nil, "Belt")
	piece(char, "Torso", Vector3.new(0.42, 0.38, 0.14), GOLD, METAL, CFrame.new(0, -0.82, -0.55), nil, "Buckle")
	piece(char, "Torso", Vector3.new(0.4, 1.9, 0.06), CRIMSON, FABRIC, CFrame.new(0, -0.05, -0.53), nil, "Sash")
end

function V2.Mage(char)
	local PURPLE, DEEP, PALE, GOLD, WOODC = rgb(132, 82, 220), rgb(48, 28, 86), rgb(232, 214, 255), rgb(226, 190, 96), rgb(70, 46, 32)
	local G = GRIP
	piece(char, "Right Arm", Vector3.new(5.6, 0.22, 0.22), WOODC, WOOD, G * CFrame.new(0, 0, -1.3) * R(0, rad(90), 0), CYL, "StaffShaft")
	piece(char, "Right Arm", Vector3.new(0.3, 0.3, 0.3), GOLD, METAL, G * CFrame.new(0, 0, 1.45) * R(0, rad(90), 0), CYL, "StaffFoot")
	piece(char, "Right Arm", Vector3.new(0.35, 0.34, 0.34), GOLD, METAL, G * CFrame.new(0, 0, -3.9) * R(0, rad(90), 0), CYL, "StaffCollar")
	for i = 0, 2 do
		local ang = i * math.pi * 2 / 3
		piece(char, "Right Arm", Vector3.new(0.1, 0.1, 0.9), GOLD, METAL, G * CFrame.new(math.cos(ang) * 0.3, math.sin(ang) * 0.3, -4.4) * R(math.sin(ang) * rad(-18), math.cos(ang) * rad(18), 0), nil, "Prong")
	end
	local crystal = piece(char, "Right Arm", Vector3.new(0.45, 0.45, 0.8), PURPLE, NEON, G * CFrame.new(0, 0, -4.55) * R(rad(45), rad(45), 0), nil, "StaffCrystal")
	swingTrail(char:FindFirstChild("ClassGear") and char.ClassGear:FindFirstChild("StaffShaft"), Vector3.new(-1.6, 0, 0), Vector3.new(-2.8, 0, 0), PURPLE, PALE, 0.2)
	glow(piece(char, "Right Arm", Vector3.one * 0.32, PALE, NEON, G * CFrame.new(0, 0, -4.55), BALL, "StaffCore"), PURPLE, 11, 2)
	sparkle(tipAttachment(crystal), PALE, PURPLE, 10, 0)
	piece(char, "Head", Vector3.new(0.14, 3.0, 3.0), DEEP, FABRIC, CFrame.new(0, 0.6, 0) * R(0, 0, rad(90)), CYL, "HatBrim")
	local tiers = { { 1.5, 0.42, 0.85, 0 }, { 1.15, 0.42, 1.22, 0.05 }, { 0.8, 0.42, 1.58, 0.16 }, { 0.45, 0.42, 1.92, 0.34 } }
	for i, t in ipairs(tiers) do
		piece(char, "Head", Vector3.new(t[2], t[1], t[1]), DEEP, FABRIC, CFrame.new(0, t[3], t[4]) * R(rad(-8 * i), 0, rad(90)), CYL, "HatTier" .. i)
	end
	piece(char, "Head", Vector3.new(0.13, 1.55, 1.55), GOLD, METAL, CFrame.new(0, 0.74, 0) * R(0, 0, rad(90)), CYL, "HatBand")
	piece(char, "Head", Vector3.one * 0.28, PALE, NEON, CFrame.new(0, 2.12, 0.5), BALL, "HatStar")
	piece(char, "Torso", Vector3.new(2.06, 2.04, 1.07), PURPLE, FABRIC, CFrame.new(), nil, "Coat")
	piece(char, "Torso", Vector3.new(0.24, 2.05, 1.09), GOLD, FABRIC, CFrame.new(), nil, "CoatSeam")
	piece(char, "Torso", Vector3.new(2.1, 0.35, 1.12), DEEP, FABRIC, CFrame.new(0, 0.86, 0), nil, "Collar")
	piece(char, "Torso", Vector3.new(1.9, 2.1, 0.12), PURPLE, FABRIC, CFrame.new(0, -2.05, -0.5), nil, "RobeFront")
	piece(char, "Torso", Vector3.new(1.9, 2.1, 0.12), PURPLE, FABRIC, CFrame.new(0, -2.05, 0.5), nil, "RobeBack")
	piece(char, "Torso", Vector3.new(1.92, 0.16, 0.14), GOLD, FABRIC, CFrame.new(0, -3.05, -0.5), nil, "HemFront")
	piece(char, "Torso", Vector3.new(2.08, 0.28, 1.1), GOLD, FABRIC, CFrame.new(0, -0.85, 0), nil, "Sash")
end

function V2.Tank(char)
	 
	local STEEL, DARKSTEEL, BRASS, RED, BLUE = rgb(112, 122, 138), rgb(52, 58, 70), rgb(190, 150, 80), rgb(170, 36, 40), rgb(48, 80, 140)
	piece(char, "Head", Vector3.new(1.15, 1.42, 1.42), STEEL, METAL, CFrame.new(0, 0.02, 0) * R(0, 0, rad(90)), CYL, "HelmDrum")
	piece(char, "Head", Vector3.new(1.42, 0.9, 1.42), STEEL, METAL, CFrame.new(0, 0.55, 0), BALL, "HelmDome")
	piece(char, "Head", Vector3.new(1.05, 0.12, 0.2), rgb(12, 14, 18), METAL, CFrame.new(0, 0.12, -0.66), nil, "VisorSlit")
	piece(char, "Head", Vector3.new(0.12, 1.2, 0.18), BRASS, METAL, CFrame.new(0, 0.3, -0.7), nil, "NoseGuard")
	for i = -1, 1, 2 do
		piece(char, "Head", Vector3.new(0.3, 0.06, 0.06), rgb(12, 14, 18), METAL, CFrame.new(0.3 * i, -0.2, -0.7), nil, "Breath")
	end
	for i = 0, 2 do
		piece(char, "Head", Vector3.new(0.22, 0.75 - i * 0.12, 0.42), RED, FABRIC, CFrame.new(0, 1.05 + i * 0.05, 0.05 + i * 0.35) * R(rad(-25 - i * 20), 0, 0), nil, "Plume")
	end
	piece(char, "Torso", Vector3.new(2.12, 1.3, 1.16), STEEL, METAL, CFrame.new(0, 0.38, 0), nil, "Breastplate")
	piece(char, "Torso", Vector3.new(0.18, 1.25, 0.2), BRASS, METAL, CFrame.new(0, 0.38, -0.58) * R(0, rad(45), 0), nil, "Ridge")
	for i = 0, 2 do
		piece(char, "Torso", Vector3.new(2.1 - i * 0.04, 0.3, 1.14 - i * 0.02), i % 2 == 0 and DARKSTEEL or STEEL, METAL, CFrame.new(0, -0.38 - i * 0.28, 0), nil, "Lame")
	end
	piece(char, "Torso", Vector3.new(0.45, 1.5, 1.5), STEEL, METAL, CFrame.new(0, 1.05, 0) * R(0, 0, rad(90)), CYL, "Gorget")
	piece(char, "Torso", Vector3.new(1.0, 0.95, 0.08), BLUE, FABRIC, CFrame.new(0, -0.95, -0.6), nil, "Tabard")
	piece(char, "Torso", Vector3.new(0.5, 0.5, 0.1), BRASS, METAL, CFrame.new(0, -0.8, -0.65) * R(0, 0, rad(45)), nil, "TabardCrest")
	for _, side in ipairs({ -1, 1 }) do
		piece(char, "Torso", Vector3.new(1.55, 1.0, 1.55), STEEL, METAL, CFrame.new(1.45 * side, 0.95, 0), BALL, "Pauldron")
		piece(char, "Torso", Vector3.new(1.35, 0.3, 1.4), DARKSTEEL, METAL, CFrame.new(1.6 * side, 0.55, 0) * R(0, 0, rad(-18 * side)), nil, "PauldronLame")
		piece(char, "Torso", Vector3.new(0.12, 1.25, 1.25), BRASS, METAL, CFrame.new(1.42 * side, 1.38, 0) * R(0, 0, rad(90)), CYL, "PauldronTrim")
	end
	for _, armName in ipairs({ "Left Arm", "Right Arm" }) do
		piece(char, armName, Vector3.new(1.08, 0.95, 1.08), DARKSTEEL, METAL, CFrame.new(0, 0.45, 0), nil, "Rerebrace")
		piece(char, armName, Vector3.new(0.9, 1.15, 1.15), STEEL, METAL, CFrame.new(0, -0.45, 0) * R(0, 0, rad(90)), CYL, "Vambrace")
		piece(char, armName, Vector3.new(1.12, 0.42, 1.12), STEEL, METAL, CFrame.new(0, -0.82, 0), nil, "Gauntlet")
		piece(char, armName, Vector3.new(0.18, 1.22, 1.22), BRASS, METAL, CFrame.new(0, -0.05, 0) * R(0, 0, rad(90)), CYL, "VambraceCuff")
	end
	for _, legName in ipairs({ "Left Leg", "Right Leg" }) do
		piece(char, legName, Vector3.new(1.08, 0.95, 1.08), DARKSTEEL, METAL, CFrame.new(0, 0.5, 0), nil, "Cuisse")
		piece(char, legName, Vector3.new(1.05, 0.7, 0.12), STEEL, METAL, CFrame.new(0, 0.55, -0.55), nil, "Tasset")
		piece(char, legName, Vector3.new(1.1, 0.35, 1.25), DARKSTEEL, METAL, CFrame.new(0, -0.85, -0.08), nil, "Sabaton")
		piece(char, legName, Vector3.new(0.65, 0.6, 0.6), STEEL, METAL, CFrame.new(0, -0.1, -0.45), BALL, "KneeCop")
		piece(char, legName, Vector3.new(1.0, 1.15, 1.15), STEEL, METAL, CFrame.new(0, -0.55, 0) * R(0, 0, rad(90)), CYL, "Greave")
	end
	local S = CFrame.new(-0.85, -0.35, -0.3)
	swingTrail(piece(char, "Left Arm", Vector3.new(0.34, 4.0, 3.0), DARKSTEEL, METAL, S, nil, "ShieldFrame"), Vector3.new(0, 1.8, 0), Vector3.new(0, -1.8, 0), rgb(140, 190, 255), rgb(255, 255, 255), 0.15)
	piece(char, "Left Arm", Vector3.new(0.34, 3.0, 3.0), DARKSTEEL, METAL, S * CFrame.new(0, 2.0, 0), CYL, "ShieldTopFrame")
	piece(char, "Left Arm", Vector3.new(0.38, 3.6, 2.6), BLUE, METAL, S * CFrame.new(-0.03, 0, 0), nil, "ShieldFace")
	piece(char, "Left Arm", Vector3.new(0.38, 2.6, 2.6), BLUE, METAL, S * CFrame.new(-0.03, 1.8, 0), CYL, "ShieldTopFace")
	piece(char, "Left Arm", Vector3.new(0.42, 4.0, 0.42), BRASS, METAL, S * CFrame.new(-0.06, 0.4, 0), nil, "CrossV")
	piece(char, "Left Arm", Vector3.new(0.42, 0.42, 2.3), BRASS, METAL, S * CFrame.new(-0.06, 1.1, 0), nil, "CrossH")
	glow(piece(char, "Left Arm", Vector3.new(0.46, 0.55, 0.55), rgb(140, 200, 255), NEON, S * CFrame.new(-0.09, 1.1, 0) * R(rad(45), 0, 0), nil, "ShieldGem"), rgb(140, 200, 255), 7, 1)
	for _, y in ipairs({ -1.6, 0.2 }) do
		for _, z in ipairs({ -1.15, 1.15 }) do
			piece(char, "Left Arm", Vector3.one * 0.2, BRASS, METAL, S * CFrame.new(-0.07, y, z), BALL, "Rivet")
		end
	end
end

function V2.Supporter(char)
	local GREEN, CLOAK, SHADE, IVORY, GOLD = rgb(104, 214, 150), rgb(34, 92, 70), rgb(16, 36, 28), rgb(236, 230, 210), rgb(226, 196, 110)
	 
	piece(char, "Head", Vector3.new(1.35, 0.28, 1.3), CLOAK, FABRIC, CFrame.new(0, 0.66, 0.05), nil, "HoodTop")
	piece(char, "Head", Vector3.new(1.35, 1.3, 0.28), CLOAK, FABRIC, CFrame.new(0, 0.1, 0.62), nil, "HoodBack")
	piece(char, "Head", Vector3.new(0.22, 1.15, 1.2), CLOAK, FABRIC, CFrame.new(-0.66, 0.08, 0.02), nil, "HoodLeft")
	piece(char, "Head", Vector3.new(0.22, 1.15, 1.2), CLOAK, FABRIC, CFrame.new(0.66, 0.08, 0.02), nil, "HoodRight")
	piece(char, "Head", Vector3.new(1.4, 0.12, 0.2), GOLD, FABRIC, CFrame.new(0, 0.7, -0.56), nil, "HoodTrim")
	 
	piece(char, "Torso", Vector3.new(2.3, 0.45, 1.25), CLOAK, FABRIC, CFrame.new(0, 0.82, 0.04), nil, "Mantle")
	piece(char, "Torso", Vector3.new(2.32, 0.12, 1.27), GOLD, FABRIC, CFrame.new(0, 0.6, 0.04), nil, "MantleTrim")
	piece(char, "Torso", Vector3.new(2.06, 2.04, 1.07), rgb(232, 228, 214), FABRIC, CFrame.new(), nil, "Robe")
	piece(char, "Torso", Vector3.new(0.35, 2.05, 1.09), CLOAK, FABRIC, CFrame.new(), nil, "RobeStole")
	piece(char, "Torso", Vector3.new(2.2, 3.5, 0.14), CLOAK, FABRIC, CFrame.new(0, -0.75, 0.6) * R(rad(-6), 0, 0), nil, "Cape")
	piece(char, "Torso", Vector3.new(2.22, 0.14, 0.16), GOLD, FABRIC, CFrame.new(0, -2.5, 0.78) * R(rad(-6), 0, 0), nil, "CapeHem")
	piece(char, "Torso", Vector3.new(0.35, 0.35, 0.12), GOLD, METAL, CFrame.new(0, 0.85, -0.6), BALL, "Clasp")
	local G = GRIP
	piece(char, "Right Arm", Vector3.new(5.8, 0.2, 0.2), IVORY, WOOD, G * CFrame.new(0, 0, -1.4) * R(0, rad(90), 0), CYL, "StaffShaft")
	for _, z in ipairs({ -0.3, 0.3, -3.2 }) do
		piece(char, "Right Arm", Vector3.new(0.18, 0.27, 0.27), GOLD, METAL, G * CFrame.new(0, 0, z) * R(0, rad(90), 0), CYL, "StaffBand")
	end
	piece(char, "Right Arm", Vector3.new(0.1, 1.4, 1.4), GOLD, METAL, G * CFrame.new(0, 0, -4.55), CYL, "RingA")
	piece(char, "Right Arm", Vector3.new(0.1, 1.4, 1.4), GOLD, METAL, G * CFrame.new(0, 0, -4.55) * R(0, rad(90), 0), CYL, "RingB")
	local crystal = piece(char, "Right Arm", Vector3.new(0.42, 0.42, 0.7), GREEN, NEON, G * CFrame.new(0, 0, -4.55) * R(rad(45), 0, rad(45)), nil, "StaffCrystal")
	swingTrail(char:FindFirstChild("ClassGear") and char.ClassGear:FindFirstChild("StaffShaft"), Vector3.new(-1.6, 0, 0), Vector3.new(-2.9, 0, 0), GREEN, rgb(230, 255, 240), 0.2)
	glow(crystal, GREEN, 12, 2)
	sparkle(tipAttachment(crystal), rgb(220, 255, 235), GREEN, 8, 2)
end

function V2.Gambler(char)
	local DARK, GOLD, RED, WHITE, WOODC = rgb(28, 28, 34), rgb(232, 190, 64), rgb(150, 30, 40), rgb(250, 250, 250), rgb(96, 58, 34)
	piece(char, "Head", Vector3.new(0.12, 2.5, 2.5), DARK, FABRIC, CFrame.new(0, 0.6, 0) * R(0, 0, rad(90)), CYL, "HatBrim")
	piece(char, "Head", Vector3.new(0.7, 1.35, 1.35), DARK, FABRIC, CFrame.new(0, 0.98, 0) * R(0, 0, rad(90)), CYL, "HatCrown")
	piece(char, "Head", Vector3.new(0.16, 1.38, 1.38), RED, FABRIC, CFrame.new(0, 0.74, 0) * R(0, 0, rad(90)), CYL, "HatBand")
	piece(char, "Head", Vector3.new(0.12, 0.16, 0.9), rgb(18, 18, 22), FABRIC, CFrame.new(0, 1.3, 0), nil, "HatPinch")
	piece(char, "Torso", Vector3.new(2.06, 2.04, 1.07), RED, FABRIC, CFrame.new(), nil, "Vest")
	piece(char, "Torso", Vector3.new(0.7, 1.6, 0.08), WHITE, FABRIC, CFrame.new(0, 0.2, -0.54), nil, "Shirt")
	piece(char, "Torso", Vector3.new(0.22, 1.1, 0.1), DARK, FABRIC, CFrame.new(0, 0.3, -0.58), nil, "Tie")
	for _, x in ipairs({ -0.55, 0.55 }) do
		piece(char, "Torso", Vector3.new(0.85, 1.5, 0.12), DARK, FABRIC, CFrame.new(x, -1.65, 0.52) * R(rad(-8), 0, 0), nil, "CoatTail")
	end
	 
	local G = GRIP * R(rad(-90), 0, 0) * CFrame.new(0, 0, 0.35)
	piece(char, "Right Arm", Vector3.new(0.26, 0.7, 0.3), WOODC, WOOD, G * CFrame.new(0, -0.18, 0.12) * R(rad(-18), 0, 0), nil, "GunGrip")
	piece(char, "Right Arm", Vector3.new(0.28, 0.38, 0.8), DARK, METAL, G * CFrame.new(0, 0.18, -0.28), nil, "GunFrame")
	piece(char, "Right Arm", Vector3.new(0.42, 0.44, 0.44), rgb(60, 60, 68), METAL, G * CFrame.new(0, 0.2, -0.36) * R(0, rad(90), 0), CYL, "GunDrum")
	piece(char, "Right Arm", Vector3.new(1.3, 0.19, 0.19), DARK, METAL, G * CFrame.new(0, 0.28, -1.25) * R(0, rad(90), 0), CYL, "GunBarrel")
	piece(char, "Right Arm", Vector3.new(1.32, 0.07, 0.07), GOLD, METAL, G * CFrame.new(0, 0.38, -1.25) * R(0, rad(90), 0), CYL, "GunRib")
	piece(char, "Right Arm", Vector3.new(0.06, 0.12, 0.08), GOLD, METAL, G * CFrame.new(0, 0.42, -1.85), nil, "GunSight")
	piece(char, "Right Arm", Vector3.new(0.1, 0.18, 0.12), DARK, METAL, G * CFrame.new(0, 0.42, 0.06) * R(rad(-30), 0, 0), nil, "GunHammer")
	local muzzlePart = piece(char, "Right Arm", Vector3.new(0.1, 0.22, 0.22), GOLD, METAL, G * CFrame.new(0, 0.28, -1.92) * R(0, rad(90), 0), CYL, "GunMuzzle")
	tipAttachment(muzzlePart)
	swingTrail(muzzlePart, Vector3.new(0, 0.12, 0), Vector3.new(0, -0.12, 0), GOLD, rgb(255, 255, 255), 0.12)
 local arm=char:FindFirstChild("Left Arm")
 if arm then
  local frame=arm.CFrame*GRIP*CFrame.new(0,.05,-.35)*R(rad(20),rad(35),0)
  local die=require(game.ReplicatedStorage.BossShared.Classes.D20Geometry).Build(holder(char),frame,.9,false)
  local weld=Instance.new("WeldConstraint")weld.Part0=arm weld.Part1=die.PrimaryPart weld.Parent=die.PrimaryPart
  glow(die.PrimaryPart,GOLD,7,1.2)
 end
end

function V2.Duelist(char)
	local NAVY, SILVER, CRIMSON, EDGE, DARK = rgb(28, 38, 70), rgb(205, 212, 226), rgb(176, 30, 44), rgb(150, 200, 255), rgb(20, 22, 30)
	local G = GRIP
	 
	local blade = piece(char, "Right Arm", Vector3.new(0.07, 0.17, 4.3), SILVER, METAL, G * CFrame.new(0, 0, -2.75), nil, "Blade")
	piece(char, "Right Arm", Vector3.new(0.08, 0.05, 4.1), EDGE, NEON, G * CFrame.new(0, 0.09, -2.7), nil, "BladeEdge")
	piece(char, "Right Arm", Vector3.new(0.07, 0.12, 0.35), SILVER, METAL, G * CFrame.new(0, 0.03, -5.05) * R(rad(14), 0, 0), nil, "BladeTip")
	piece(char, "Right Arm", Vector3.new(0.5, 0.5, 0.5), SILVER, METAL, G * CFrame.new(0, 0, -0.55), BALL, "CupHilt")
	piece(char, "Right Arm", Vector3.new(0.06, 0.75, 0.75), SILVER, METAL, G * CFrame.new(0, 0, -0.6) * R(0, rad(90), 0), CYL, "GuardRing")
	piece(char, "Right Arm", Vector3.new(0.75, 0.16, 0.16), DARK, LEATHER, G * CFrame.new(0, 0, -0.05) * R(0, rad(90), 0), CYL, "Grip")
	piece(char, "Right Arm", Vector3.one * 0.24, SILVER, METAL, G * CFrame.new(0, 0, 0.4), BALL, "Pommel")
	if blade then
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(0, 0, -2.1), Vector3.new(0, 0, 2.1)
		a0.Parent, a1.Parent = blade, blade
		local t = Instance.new("Trail")
		t.Name = "SwingTrail"
		t.Attachment0, t.Attachment1 = a0, a1
		t.Color = ColorSequence.new(EDGE, rgb(255, 255, 255))
		t.LightEmission = 1
		t.Lifetime = 0.14
		t.MinLength = 0.05
		t.Enabled = false
		t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		t.Parent = blade
		local tip = Instance.new("Attachment")
		tip.Name = "Tip"
		tip.Position = Vector3.new(0, 0, -2.15)
		tip.Parent = blade
	end
	 
	piece(char, "Torso", Vector3.new(2.06, 2.04, 1.07), NAVY, FABRIC, CFrame.new(), nil, "Coat")
	piece(char, "Torso", Vector3.new(0.5, 2.06, 1.09), SILVER, FABRIC, CFrame.new(-0.2, 0, 0), nil, "CoatLapel")
	piece(char, "Torso", Vector3.new(2.08, 0.25, 1.1), DARK, LEATHER, CFrame.new(0, -0.8, 0), nil, "Belt")
	piece(char, "Torso", Vector3.new(0.3, 0.3, 0.12), SILVER, METAL, CFrame.new(0.35, -0.8, -0.56), nil, "Buckle")
	piece(char, "Torso", Vector3.new(0.95, 1.9, 0.1), NAVY, FABRIC, CFrame.new(-0.5, -1.85, 0.52) * R(rad(-10), 0, 0), nil, "TailL")
	piece(char, "Torso", Vector3.new(0.95, 1.9, 0.1), NAVY, FABRIC, CFrame.new(0.5, -1.85, 0.52) * R(rad(-10), 0, 0), nil, "TailR")
	piece(char, "Torso", Vector3.new(0.45, 1.5, 1.5), CRIMSON, FABRIC, CFrame.new(0, 1.05, 0) * R(0, 0, rad(90)), CYL, "Scarf")
	piece(char, "Torso", Vector3.new(0.4, 1.6, 0.1), CRIMSON, FABRIC, CFrame.new(0.45, 0.25, 0.6) * R(rad(-14), 0, rad(-8)), nil, "ScarfTail")
	piece(char, "Torso", Vector3.new(1.25, 0.4, 1.25), SILVER, METAL, CFrame.new(-1.4, 0.95, 0) * R(0, 0, rad(14)), nil, "Pauldron")
	for _, arm in ipairs({ "Left Arm", "Right Arm" }) do
		piece(char, arm, Vector3.new(1.06, 0.45, 1.06), DARK, LEATHER, CFrame.new(0, -0.78, 0), nil, "Glove")
	end
end

function M.Build(char, id)
	local old = char:FindFirstChild("ClassGear")
	if old then
		old:Destroy()
	end
 local saved=char:FindFirstChild("ClassAvatarAccessories")
 local useAvatar=char:GetAttribute("UseAvatarAppearance")==true
 if saved then saved:Destroy() end
 if not useAvatar then
  for _,acc in char:GetChildren() do if acc:IsA("Accessory") then acc:Destroy() end end
 end
	local build = V2[id] or M[id]
	if build then
		build(char)
	end
	if useAvatar then
  local keep={
   Warrior={ShieldRim=true,ShieldFace=true,EmblemV=true,EmblemH=true,ShieldBoss=true,Rivet=true},
   Mage={Prong=true},
   Tank={CrossV=true,CrossH=true,Rivet=true},
   Supporter={RingA=true,RingB=true},
   Gambler={Die=true,Pip=true},
   Duelist={CupHilt=true,GuardRing=true,Grip=true,Pommel=true},
  }
  local gear=char:FindFirstChild("ClassGear")
  if gear then
   for _,part in gear:GetDescendants() do
    if part:IsA("BasePart") then
     local name=part.Name
     local sword=part:FindFirstAncestor("Basic Sword")
     local weapon=part:GetAttribute("ClassWeapon")==true or sword~=nil or keep[id] and keep[id][name]
      or name:find("^Sword") or name:find("^Staff") or name:find("^Shield") or name:find("^Gun") or name:find("^Blade")
     if not weapon then part:Destroy() end
    end
   end
  end
 end
 char:SetAttribute("ClassModelVersion", 4)
end
return M
