--[==[ BACKUP of ServerScriptService.BossSystem.Players.Classes.ClassModels (ModuleScript) ]==]
return nil
--[==[
 
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
local WHITE_ = Color3.new(1, 1, 1)
local function W(p)
	if p then p:SetAttribute("ClassWeapon", true) end
	return p
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

--[[
	WarriorModel  —  drop-in replacement for `function V2.Warrior(char)`

	HOW TO USE
	  Delete your old `function V2.Warrior(char) ... end` and paste this whole `do ... end` block in its place
	  (same spot in the same script, so `V2` and `holder` are in scope).

	WHAT CHANGED
	  • Sword is now built procedurally (gilded winged crossguard, ruby gems, wrapped grip, bevelled blade with a
	    glowing fuller, tapered point). It no longer depends on the "Basic Sword" template in ServerStorage.
	  • Shield is rebuilt: raised gold rim, studded, inset ring, 8-ray sunburst, domed boss with a ruby, leather straps.
	  • Both items are mounted on *wrist welds* (WarriorSwordGrip / WarriorShieldGrip). WarriorCombat rotates these
	    welds every frame, so the blade / shield face can be aimed independently from the arm (this is what makes
	    the swings, thrusts and blocks read cleanly).
	  • Every name the old model exposed is kept (SwordHandle, SwordBlade, SwingTrail, Tip, ShieldRim, ShieldFace,
	    EmblemV/EmblemH, ShieldBoss, Rivet, WarriorSwordGrip) so existing code keeps working.
	  • Pauldron / belt / buckle / sash are untouched (they still use your own piece() helper).

	LOCAL FRAMES (WarriorCombat reads these, do not rotate them without updating it)
	  Sword  frame: origin = centre of the grip, +Y = towards the tip, +X = crossguard width, +Z = flat of the blade.
	  Shield frame: origin = centre of the disc,  +X = outward face normal, +Y = up, +Z = side.
]]
do
	local PI = math.pi
	local STEEL, CRIMSON, GOLD, DARK = Color3.fromRGB(205, 210, 220), Color3.fromRGB(196, 40, 40), Color3.fromRGB(228, 182, 72), Color3.fromRGB(58, 34, 22)
	local STEEL_HI, STEEL_LO = Color3.fromRGB(240, 244, 250), Color3.fromRGB(150, 155, 168)
	local CRIMSON_DEEP, GOLD_DEEP = Color3.fromRGB(128, 22, 26), Color3.fromRGB(176, 132, 46)

	-- sword blade dimensions (studs)
	local BLADE_BASE, BLADE_LEN, TIP_LEN, TIP_STEPS = 0.72, 2.5, 0.75, 5
	local GUARD_Y = 0.64

	-- Where the items sit in the (R6) arms. Grip frames are expressed in arm-local space.
	local SWORD_ANGLE = math.rad(55) -- angle between forearm and blade when the wrist is neutral
	local swordY = Vector3.new(0, -math.cos(SWORD_ANGLE), -math.sin(SWORD_ANGLE))
	local swordZ = Vector3.new(1, 0, 0)
	local swordX = swordY:Cross(swordZ)
	local SWORD_GRIP_C0 = CFrame.fromMatrix(Vector3.new(0, -0.85, -0.15), swordX, swordY, swordZ)

	local SHIELD_GRIP_C0 = CFrame.new(0, -0.85, 0) * CFrame.Angles(0, PI, 0) -- shield +X (face) -> arm -X (outwards)
	local SHIELD_OFFSET = CFrame.new(0.62, 0.5, 0) -- shield centre relative to the hand frame (in front of / above the fist)

	local ROT_Y = CFrame.Angles(0, 0, PI / 2) -- turns a Cylinder (axis = X) so that its axis follows +Y

	local function newPart(name, size, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		if shape then p.Shape = shape end
		p.Color = color
		p.Material = material or Enum.Material.Metal
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = size.Magnitude > 1.1
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		return p
	end

	local function attachment(parent, name, pos)
		local a = Instance.new("Attachment")
		a.Name = name
		a.Position = pos
		a.Parent = parent
		return a
	end

	--------------------------------------------------------------------------------------------- SWORD
	local function buildSword(arm, container)
		local handleInFrame = ROT_Y -- the cylindrical grip's own frame, relative to the sword frame

		local handle = newPart("SwordHandle", Vector3.new(1.04, 0.23, 0.23), DARK, Enum.Material.Leather, Enum.PartType.Cylinder)
		local grip = Instance.new("Weld")
		grip.Name = "WarriorSwordGrip"
		grip.Part0, grip.Part1 = arm, handle
		grip.C0, grip.C1 = SWORD_GRIP_C0, handleInFrame:Inverse()
		handle.CFrame = arm.CFrame * grip.C0 * grip.C1:Inverse()
		grip.Parent = handle
		handle.Parent = container

		-- adds a part given in sword-frame coordinates; `axisRot` is the part's own rotation inside the frame
		local function add(name, size, frameCF, color, material, shape, axisRot)
			local p = newPart(name, size, color, material, shape)
			local w = Instance.new("Weld")
			w.Name = "SwordWeld"
			w.Part0, w.Part1 = handle, p
			w.C0 = handleInFrame:Inverse() * frameCF * (axisRot or CFrame.identity)
			w.C1 = CFrame.identity
			p.CFrame = handle.CFrame * w.C0
			w.Parent = p
			p.Parent = container
			return p
		end
		local function cylY(name, len, dia, y, color, material)
			return add(name, Vector3.new(len, dia, dia), CFrame.new(0, y, 0), color, material, Enum.PartType.Cylinder, ROT_Y)
		end
		local function ball(name, dia, pos, color, material)
			return add(name, Vector3.one * dia, CFrame.new(pos), color, material, Enum.PartType.Ball)
		end

		-- grip wraps + ferrules
		for i = 1, 3 do
			cylY("SwordGripWrap" .. i, 0.07, 0.275, (i - 2) * 0.27, CRIMSON, Enum.Material.Fabric)
		end
		cylY("SwordCollarLow", 0.1, 0.32, -0.54, GOLD, Enum.Material.Metal)
		cylY("SwordCollarHigh", 0.1, 0.32, 0.54, GOLD, Enum.Material.Metal)

		-- pommel
		cylY("SwordPommelCap", 0.1, 0.5, -0.65, GOLD_DEEP, Enum.Material.Metal)
		ball("SwordPommel", 0.42, Vector3.new(0, -0.86, 0), GOLD, Enum.Material.Metal)
		ball("SwordPommelGem", 0.2, Vector3.new(0, -1.02, 0), CRIMSON, Enum.Material.Neon)

		-- winged crossguard
		add("SwordGuard", Vector3.new(1.5, 0.14, 0.26), CFrame.new(0, GUARD_Y, 0), GOLD, Enum.Material.Metal)
		local wingAngle, wingLen = math.rad(28), 0.5
		for _, s in ipairs({ 1, -1 }) do
			local cx = s * (0.75 + wingLen / 2 * math.cos(wingAngle))
			local cy = GUARD_Y + wingLen / 2 * math.sin(wingAngle)
			add("SwordWing", Vector3.new(wingLen, 0.12, 0.22), CFrame.new(cx, cy, 0), GOLD_DEEP, Enum.Material.Metal, nil, CFrame.Angles(0, 0, s * wingAngle))
			ball("SwordFinial", 0.21, Vector3.new(s * (0.75 + wingLen * math.cos(wingAngle)), GUARD_Y + wingLen * math.sin(wingAngle), 0), GOLD, Enum.Material.Metal)
		end
		add("SwordGuardBlock", Vector3.new(0.36, 0.22, 0.2), CFrame.new(0, BLADE_BASE + 0.04, 0), GOLD, Enum.Material.Metal)
		for _, z in ipairs({ 0.14, -0.14 }) do
			add("SwordGem", Vector3.new(0.2, 0.2, 0.06), CFrame.new(0, GUARD_Y, z), CRIMSON, Enum.Material.Neon, nil, CFrame.Angles(0, 0, PI / 4))
		end

		-- blade
		local bladeY = BLADE_BASE + BLADE_LEN / 2
		local blade = add("SwordBlade", Vector3.new(0.46, BLADE_LEN, 0.085), CFrame.new(0, bladeY, 0), STEEL, Enum.Material.Metal)
		blade.Reflectance = 0.18
		for _, s in ipairs({ 1, -1 }) do
			add("SwordEdge", Vector3.new(0.05, BLADE_LEN, 0.1), CFrame.new(s * 0.205, bladeY, 0), STEEL_HI, Enum.Material.Metal)
		end
		add("SwordFuller", Vector3.new(0.12, BLADE_LEN - 0.55, 0.095), CFrame.new(0, bladeY - 0.12, 0), STEEL_LO, Enum.Material.Metal)
		local glowLine = add("SwordFullerGlow", Vector3.new(0.035, BLADE_LEN - 0.85, 0.105), CFrame.new(0, bladeY - 0.12, 0), CRIMSON, Enum.Material.Neon)

		-- stepped taper (reads as a smooth point at this scale)
		local tipBase = BLADE_BASE + BLADE_LEN
		local h = TIP_LEN / TIP_STEPS
		for i = 0, TIP_STEPS - 1 do
			local w = 0.46 * (1 - (i + 0.5) / TIP_STEPS)
			local th = 0.085 - 0.03 * (i / TIP_STEPS)
			add(i == 0 and "SwordBladeTip" or ("SwordBladeTip" .. (i + 1)), Vector3.new(math.max(w, 0.04), h + 0.004, th), CFrame.new(0, tipBase + (i + 0.5) * h, 0), STEEL, Enum.Material.Metal)
		end

		-- VFX hooks (everything is created disabled; WarriorCombat switches them on)
		local a0 = attachment(blade, "TrailBase", Vector3.new(0, -BLADE_LEN / 2 + 0.15, 0))
		local a1 = attachment(blade, "Tip", Vector3.new(0, BLADE_LEN / 2 + TIP_LEN, 0))
		attachment(blade, "Base", Vector3.new(0, -BLADE_LEN / 2, 0))
		attachment(blade, "Mid", Vector3.new(0, BLADE_LEN / 2 * 0.2, 0))
		local g0 = attachment(blade, "GlowBase", Vector3.new(0, -BLADE_LEN / 2 - 0.5, 0))
		local g1 = attachment(blade, "GlowTip", Vector3.new(0, BLADE_LEN / 2 + TIP_LEN + 1.0, 0))

		local t = Instance.new("Trail")
		t.Name = "SwingTrail"
		t.Enabled = false
		t.Attachment0, t.Attachment1 = a0, a1
		t.Color = ColorSequence.new(Color3.fromRGB(255, 120, 110), Color3.fromRGB(255, 255, 255))
		t.LightEmission = 1
		t.Lifetime = 0.16
		t.MinLength = 0.05
		t.FaceCamera = true
		t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
		t.Parent = blade

		local gt = Instance.new("Trail")
		gt.Name = "GlowTrail"
		gt.Enabled = false
		gt.Attachment0, gt.Attachment1 = g0, g1
		gt.Color = ColorSequence.new(GOLD, CRIMSON)
		gt.LightEmission = 1
		gt.Lifetime = 0.34
		gt.MinLength = 0.05
		gt.FaceCamera = true
		gt.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		gt.Parent = blade

		local embers = Instance.new("ParticleEmitter")
		embers.Name = "SwordEmbers"
		embers.Enabled = false
		embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		embers.Color = ColorSequence.new(GOLD, CRIMSON)
		embers.LightEmission = 1
		embers.Rate = 24
		embers.Lifetime = NumberRange.new(0.5, 0.9)
		embers.Speed = NumberRange.new(1, 3)
		embers.SpreadAngle = Vector2.new(180, 180)
		embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0) })
		embers.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		embers.Parent = blade

		local light = Instance.new("PointLight")
		light.Name = "BladeGlow"
		light.Color = CRIMSON
		light.Range = 7
		light.Brightness = 1.2
		light.Shadows = false
		light.Enabled = false
		light.Parent = blade

		return handle
	end

	--------------------------------------------------------------------------------------------- SHIELD
	local function buildShield(arm, container)
		local root = newPart("ShieldRoot", Vector3.new(0.2, 0.2, 0.2), GOLD, Enum.Material.SmoothPlastic)
		root.Transparency = 1
		local grip = Instance.new("Weld")
		grip.Name = "WarriorShieldGrip"
		grip.Part0, grip.Part1 = arm, root
		grip.C0, grip.C1 = SHIELD_GRIP_C0, SHIELD_OFFSET:Inverse()
		root.CFrame = arm.CFrame * grip.C0 * SHIELD_OFFSET
		grip.Parent = root
		root.Parent = container

		local function add(name, size, frameCF, color, material, shape)
			local p = newPart(name, size, color, material, shape)
			local w = Instance.new("Weld")
			w.Name = "ShieldWeld"
			w.Part0, w.Part1 = root, p
			w.C0, w.C1 = frameCF, CFrame.identity
			p.CFrame = root.CFrame * frameCF
			w.Parent = p
			p.Parent = container
			return p
		end
		local function disc(name, dia, thick, x, color, material)
			return add(name, Vector3.new(thick, dia, dia), CFrame.new(x, 0, 0), color, material, Enum.PartType.Cylinder)
		end

		disc("ShieldBack", 2.76, 0.14, -0.15, DARK, Enum.Material.Wood)
		local rim = disc("ShieldRim", 2.9, 0.32, 0, GOLD, Enum.Material.Metal)
		disc("ShieldFace", 2.52, 0.2, 0, CRIMSON, Enum.Material.Metal)
		disc("ShieldRing", 1.36, 0.14, 0.13, GOLD, Enum.Material.Metal)
		disc("ShieldField", 1.14, 0.12, 0.12, CRIMSON_DEEP, Enum.Material.Metal)

		-- sunburst: four bars cross the whole face; the ring/field hide the middle so only the rays show
		add("EmblemV", Vector3.new(0.07, 2.5, 0.2), CFrame.new(0.13, 0, 0), GOLD, Enum.Material.Metal)
		add("EmblemH", Vector3.new(0.07, 0.2, 2.5), CFrame.new(0.13, 0, 0), GOLD, Enum.Material.Metal)
		add("EmblemD1", Vector3.new(0.07, 1.9, 0.13), CFrame.new(0.125, 0, 0) * CFrame.Angles(PI / 4, 0, 0), GOLD_DEEP, Enum.Material.Metal)
		add("EmblemD2", Vector3.new(0.07, 1.9, 0.13), CFrame.new(0.125, 0, 0) * CFrame.Angles(-PI / 4, 0, 0), GOLD_DEEP, Enum.Material.Metal)

		add("ShieldBoss", Vector3.one * 0.72, CFrame.new(0.04, 0, 0), GOLD, Enum.Material.Metal, Enum.PartType.Ball)
		add("ShieldGem", Vector3.one * 0.26, CFrame.new(0.3, 0, 0), CRIMSON, Enum.Material.Neon, Enum.PartType.Ball)

		for i = 0, 7 do
			local ang = i * PI / 4 + PI / 8
			add("Rivet", Vector3.one * 0.2, CFrame.new(0.16, math.cos(ang) * 1.36, math.sin(ang) * 1.36), GOLD, Enum.Material.Metal, Enum.PartType.Ball)
		end

		-- back: straps (visible when the shield is raised)
		add("ShieldGripBar", Vector3.new(0.1, 0.22, 1.0), CFrame.new(-0.28, 0, 0), DARK, Enum.Material.Leather)
		add("ShieldArmStrap", Vector3.new(0.1, 0.9, 0.2), CFrame.new(-0.28, 0.1, 0.0), DARK, Enum.Material.Leather)

		attachment(root, "ShieldFront", Vector3.new(0.7, 0, 0))
		local top = attachment(rim, "TrailTop", Vector3.new(0, 1.45, 0))
		local bot = attachment(rim, "TrailBottom", Vector3.new(0, -1.45, 0))
		local tr = Instance.new("Trail")
		tr.Name = "ShieldTrail"
		tr.Enabled = false
		tr.Attachment0, tr.Attachment1 = top, bot
		tr.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 244, 200))
		tr.LightEmission = 0.9
		tr.Lifetime = 0.28
		tr.MinLength = 0.05
		tr.FaceCamera = true
		tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		tr.Parent = rim

		return root
	end

	--------------------------------------------------------------------------------------------- V2.Warrior
	function V2.Warrior(char)
		local rightArm, leftArm = char:FindFirstChild("Right Arm"), char:FindFirstChild("Left Arm")
		if not (rightArm and leftArm) then
			warn("V2.Warrior: expected an R6 rig (Right Arm / Left Arm)")
			return
		end
		local container = holder(char)

		buildSword(rightArm, container)
		buildShield(leftArm, container)

		-- armour (unchanged from the original)
		local STEEL_A, GOLD_A, CRIMSON_A, DARK_A = rgb(205, 210, 220), rgb(228, 182, 72), rgb(196, 40, 40), rgb(58, 34, 22)
		piece(char, "Torso", Vector3.new(1.4, 0.55, 1.35), STEEL_A, METAL, CFrame.new(1.42, 0.92, 0) * R(0, 0, rad(-14)), nil, "PauldronR")
		piece(char, "Torso", Vector3.new(1.45, 0.14, 1.4), GOLD_A, METAL, CFrame.new(1.42, 1.18, 0) * R(0, 0, rad(-14)), nil, "PauldronTrim")
		piece(char, "Torso", Vector3.new(2.06, 0.32, 1.06), DARK_A, LEATHER, CFrame.new(0, -0.82, 0), nil, "Belt")
		piece(char, "Torso", Vector3.new(0.42, 0.38, 0.14), GOLD_A, METAL, CFrame.new(0, -0.82, -0.55), nil, "Buckle")
		piece(char, "Torso", Vector3.new(0.4, 1.9, 0.06), CRIMSON_A, FABRIC, CFrame.new(0, -0.05, -0.53), nil, "Sash")

		-- lets WarriorCombat / WarriorClient find warriors without extra setup
		char:SetAttribute("WarriorClass", true)
	end
end

-- =====================================================================
--  V2.Mage  --  full model rework ("Starweaver")
--  Drop-in replacement for your function V2.Mage(char).
--  Same helper set as before: piece, glow, sparkle, swingTrail, tipAttachment, W,
--  rgb, R, rad, GRIP, CYL, BALL, METAL, NEON, FABRIC, WOOD
--  Part names other code may look up are kept:
--  StaffShaft, StaffFoot, StaffCollar, StaffCrystal, StaffCore, StaffShard*,
--  HatBrim, HatTier*, HatBand, HatStar, Coat, CoatSeam, Sash
-- =====================================================================
function V2.Mage(char)
	local V3 = Vector3.new
	local PURPLE, DEEP, PALE, GOLD, WOODC = rgb(132, 82, 220), rgb(48, 28, 86), rgb(232, 214, 255), rgb(226, 190, 96), rgb(70, 46, 32)
	local MID, INK, WINE = rgb(70, 42, 124), rgb(36, 22, 60), rgb(96, 34, 72)
	local G = GRIP
	local AXIS = R(0, rad(90), 0) -- lays a cylinder's long X axis along Z
	-- a cube balanced on a corner: its body diagonal points along local Z (hexagonal gem look)
	local CORNER = R(0, rad(-54.74), 0) * R(0, 0, rad(-45))
	local UPCORNER = R(rad(-90), 0, 0) * CORNER -- same, but pointing up (Y)

	-- ---------- small build helpers ----------
	local function st(name, size, color, mat, pos, rot, shape) -- staff piece, GRIP space
		return piece(char, "Right Arm", size, color, mat, G * CFrame.new(pos) * (rot or CFrame.new()), shape, name)
	end
	local function bar(on, base, name, a, b, w, color, mat, up) -- square bar from point a to point b
		return piece(char, on, V3(w, w, (b - a).Magnitude * 1.06), color, mat, base * CFrame.lookAt((a + b) / 2, b, up or V3(0, 1, 0)), nil, name)
	end
	local function ring(base, name, r, n, w, color, mat) -- true hollow ring made of n bars
		for k = 0, n - 1 do
			local a0, a1 = k * 2 * math.pi / n, (k + 1) * 2 * math.pi / n
			bar("Right Arm", base, name, V3(math.cos(a0) * r, math.sin(a0) * r, 0), V3(math.cos(a1) * r, math.sin(a1) * r, 0), w, color, mat, V3(0, 0, 1))
		end
	end
	local function tor(name, size, color, mat, cf, shape)
		return piece(char, "Torso", size, color, mat, cf or CFrame.new(), shape, name)
	end
	local function hed(name, size, color, mat, cf, shape)
		return piece(char, "Head", size, color, mat, cf, shape, name)
	end

	-- ================================================================
	--  STAFF  (Right Arm, GRIP space: head toward -Z)
	-- ================================================================
	-- shaft is kept exactly as before so swingTrail / other code still finds "StaffShaft"
	st("StaffShaft", V3(5.6, 0.22, 0.22), WOODC, WOOD, V3(0, 0, -1.3), AXIS, CYL)
	st("StaffGrip", V3(1.1, 0.29, 0.29), INK, FABRIC, V3(0, 0, 0), AXIS, CYL)
	for _, z in ipairs({ -0.58, 0.58 }) do
		st("StaffGripRing", V3(0.08, 0.34, 0.34), GOLD, METAL, V3(0, 0, z), AXIS, CYL)
	end

	-- foot: ferrule, ring, spike
	st("StaffFoot", V3(0.3, 0.3, 0.3), GOLD, METAL, V3(0, 0, 1.45), AXIS, CYL)
	st("StaffFootRing", V3(0.08, 0.3, 0.3), GOLD, METAL, V3(0, 0, 1.15), AXIS, CYL)
	st("StaffSpike", V3(0.24, 0.24, 0.24), GOLD, METAL, V3(0, 0, 1.68), CORNER)

	-- spiral of glowing runes climbing the shaft
	st("StaffMidRing", V3(0.1, 0.32, 0.32), GOLD, METAL, V3(0, 0, -1.6), AXIS, CYL)
	for i = 0, 7 do
		local a = i * rad(80)
		st("StaffRune", V3(0.05, 0.1, 0.2), i % 2 == 0 and PALE or PURPLE, NEON,
			V3(math.cos(a) * 0.13, math.sin(a) * 0.13, -1.95 - i * 0.2), R(0, 0, a))
	end

	-- head: collar + flared cup + four hooked prongs cradling the crystal
	local zc = -4.8
	st("StaffCollar", V3(0.35, 0.34, 0.34), GOLD, METAL, V3(0, 0, -3.9), AXIS, CYL)
	st("StaffCupA", V3(0.12, 0.46, 0.46), GOLD, METAL, V3(0, 0, -4.06), AXIS, CYL)
	st("StaffCupB", V3(0.08, 0.62, 0.62), GOLD, METAL, V3(0, 0, -4.16), AXIS, CYL)
	for i = 0, 3 do
		local a = rad(45 + 90 * i)
		local function pt(r, z) return V3(math.cos(a) * r, math.sin(a) * r, z) end
		local p0, p1, p2, p3 = pt(0.26, -4.16), pt(0.56, -4.62), pt(0.34, -5.12), pt(0.12, -5.36)
		bar("Right Arm", G, "Prong", p0, p1, 0.09, GOLD, METAL)
		bar("Right Arm", G, "Prong", p1, p2, 0.09, GOLD, METAL)
		bar("Right Arm", G, "Prong", p2, p3, 0.08, GOLD, METAL)
		st("ProngTip", V3(0.1, 0.1, 0.1), PALE, NEON, p3, nil, BALL)
	end

	-- crystal: translucent hex gem, twisted inner gem, glowing core
	local crystal = st("StaffCrystal", V3(0.5, 0.5, 0.5), PURPLE, NEON, V3(0, 0, zc), CORNER)
	crystal.Transparency = 0.3
	st("StaffCrystalInner", V3(0.36, 0.36, 0.36), PALE, NEON, V3(0, 0, zc), R(0, 0, rad(60)) * CORNER)
	glow(st("StaffCore", V3(0.3, 0.3, 0.3), PALE, NEON, V3(0, 0, zc), nil, BALL), PURPLE, 11, 2)
	sparkle(tipAttachment(crystal), PALE, PURPLE, 10, 0)
	-- trail kept as in the original. NOTE: negative X on a CYL rotated by AXIS is the FOOT end.
	-- If you want the arc at the head instead, flip to +1.6 / +2.8.
	swingTrail(char:FindFirstChild("ClassGear") and char.ClassGear:FindFirstChild("StaffShaft"), V3(-1.6, 0, 0), V3(-2.8, 0, 0), PURPLE, PALE, 0.2)

	-- two real (hollow) halo rings around the crystal, tilted against each other
	ring(G * CFrame.new(0, 0, zc) * R(rad(62), rad(28), 0), "StaffHaloA", 0.82, 12, 0.05, GOLD, METAL)
	ring(G * CFrame.new(0, 0, zc) * R(rad(-48), rad(-35), rad(20)), "StaffHaloB", 0.68, 10, 0.035, PALE, NEON)

	-- floating shards (same W() treatment as the old shards)
	for i = 1, 5 do
		local a = i * 2 * math.pi / 5
		W(st("StaffShard" .. i, V3(0.13, 0.13, 0.34), i % 2 == 0 and PURPLE or PALE, NEON,
			V3(math.cos(a) * 1.05, math.sin(a) * 1.05, zc + math.sin(i * 1.9) * 0.45), R(rad(30 * i), rad(20 * i), 0)))
	end

	-- ================================================================
	--  HAT  (wide dished brim, 7-tier cone that droops back, buckle band, glowing tip)
	-- ================================================================
	hed("HatBrimTrim", V3(0.06, 3.3, 3.3), GOLD, METAL, CFrame.new(0, 0.57, 0) * R(0, 0, rad(90)), CYL)
	hed("HatBrim", V3(0.14, 3.2, 3.2), DEEP, FABRIC, CFrame.new(0, 0.6, 0) * R(0, 0, rad(90)), CYL)
	local y, z = 0.9, 0
	for i = 1, 7 do
		local phi = 3 * i ^ 1.35 -- droop angle grows toward the tip
		local dia = 1.6 - 0.22 * (i - 1)
		hed("HatTier" .. i, V3(0.42, dia, dia), i % 2 == 0 and MID or DEEP, FABRIC, CFrame.new(0, y, z) * R(rad(phi), 0, rad(90)), CYL)
		y, z = y + 0.3 * math.cos(rad(phi)), z + 0.3 * math.sin(rad(phi))
	end
	hed("HatBand", V3(0.14, 1.68, 1.68), GOLD, METAL, CFrame.new(0, 0.77, 0) * R(0, 0, rad(90)), CYL)
	hed("HatBuckle", V3(0.5, 0.4, 0.1), GOLD, METAL, CFrame.new(0, 0.77, -0.86))
	hed("HatBuckleGem", V3(0.22, 0.22, 0.06), PALE, NEON, CFrame.new(0, 0.77, -0.92) * R(0, 0, rad(45)))
	glow(hed("HatStar", V3(0.3, 0.3, 0.3), PALE, NEON, CFrame.new(0, y + 0.05, z) * UPCORNER), PALE, 6, 1)

	-- ================================================================
	--  COAT + ROBE
	-- ================================================================
	tor("Coat", V3(2.06, 2.04, 1.07), PURPLE, FABRIC)
	tor("CoatSeam", V3(0.24, 2.05, 1.09), GOLD, FABRIC)

	-- mantle over the shoulders + tall back collar
	tor("Mantle", V3(2.7, 0.3, 1.3), DEEP, FABRIC, CFrame.new(0, 0.88, 0))
	tor("MantleTrim", V3(2.74, 0.07, 1.34), GOLD, METAL, CFrame.new(0, 0.74, 0))
	tor("CollarBack", V3(1.7, 0.95, 0.1), DEEP, FABRIC, CFrame.new(0, 1.35, 0.6) * R(rad(10), 0, 0))

	-- lapels with gold piping, brooch
	for _, s in ipairs({ 1, -1 }) do
		bar("Torso", CFrame.new(), "Lapel", V3(s * 0.62, 0.9, -0.56), V3(s * 0.14, 0.15, -0.56), 0.14, DEEP, FABRIC)
		bar("Torso", CFrame.new(), "LapelTrim", V3(s * 0.62, 0.9, -0.65), V3(s * 0.14, 0.15, -0.65), 0.05, GOLD, METAL)
	end
	tor("Brooch", V3(0.34, 0.34, 0.08), GOLD, METAL, CFrame.new(0, 0.2, -0.58) * R(0, 0, rad(45)))
	tor("BroochGem", V3(0.18, 0.18, 0.06), PALE, NEON, CFrame.new(0, 0.2, -0.62) * R(0, 0, rad(45)))

	-- skirt: dark lining behind two flared front flaps and a back panel, each with hem + sigil
	tor("RobeInner", V3(0.7, 2.1, 0.1), INK, FABRIC, CFrame.new(0, -2.05, -0.4))
	local function flap(name, x, zz, w, rotX, rotZ, side)
		local base = CFrame.new(x, -2.05, zz) * R(rotX, 0, rotZ)
		local function on(n, size, color, mat, pos, r)
			tor(n, size, color, mat, base * CFrame.new(pos) * (r or CFrame.new()))
		end
		on(name, V3(w, 2.1, 0.12), PURPLE, FABRIC, V3(0, 0, 0))
		on(name .. "Hem", V3(w + 0.02, 0.16, 0.16), GOLD, FABRIC, V3(0, -1.03, 0))
		on(name .. "Bezel", V3(0.34, 0.34, 0.05), GOLD, METAL, V3(0, -0.55, side * 0.07), R(0, 0, rad(45)))
		on(name .. "Sigil", V3(0.2, 0.2, 0.05), PALE, NEON, V3(0, -0.55, side * 0.1), R(0, 0, rad(45)))
	end
	flap("RobeFrontL", -0.5, -0.52, 0.98, 0, rad(-4), -1)
	flap("RobeFrontR", 0.5, -0.52, 0.98, 0, rad(4), -1)
	flap("RobeBack", 0, 0.52, 1.9, rad(-3), 0, 1)

	-- sash, buckle, hanging tail
	tor("Sash", V3(2.08, 0.28, 1.1), GOLD, FABRIC, CFrame.new(0, -0.85, 0))
	tor("Buckle", V3(0.42, 0.42, 0.08), DEEP, METAL, CFrame.new(0, -0.85, -0.58) * R(0, 0, rad(45)))
	tor("BuckleGem", V3(0.22, 0.22, 0.06), PALE, NEON, CFrame.new(0, -0.85, -0.62) * R(0, 0, rad(45)))
	tor("SashTail", V3(0.34, 1.4, 0.07), GOLD, FABRIC, CFrame.new(0.62, -1.65, -0.66) * R(0, 0, rad(4)))
	tor("SashTailGem", V3(0.2, 0.2, 0.05), PALE, NEON, CFrame.new(0.67, -2.33, -0.7) * R(0, 0, rad(45)))

	-- grimoire hanging from the left hip
	local bk = CFrame.new(-0.82, -1.05, -0.7) * R(0, 0, rad(7))
	tor("Grimoire", V3(0.52, 0.66, 0.2), WINE, FABRIC, bk)
	tor("GrimoireSpine", V3(0.08, 0.68, 0.22), GOLD, METAL, bk * CFrame.new(-0.22, 0, 0))
	tor("GrimoireGem", V3(0.2, 0.2, 0.05), PALE, NEON, bk * CFrame.new(0.04, 0.02, -0.12) * R(0, 0, rad(45)))
end

function V2.Tank(char)

	local STEEL, DARKSTEEL, BRASS, RED, BLUE = rgb(112, 122, 138), rgb(52, 58, 70), rgb(190, 150, 80), rgb(170, 36, 40), rgb(48, 80, 140)

	-- ===================================================== ARMOUR (unchanged) =====================================================
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

	-- ===================================================== SHARED =====================================================
	local DETAIL = 2 -- 1 = lean (about two thirds of the parts), 2 = full detail
	local FULL = DETAIL >= 2

	local LEATHER = Enum.Material.Leather
	local ICE, ICE_FACET = rgb(140, 200, 255), rgb(196, 228, 255)
	local BRASS_LIGHT, BRASS_DARK = rgb(228, 192, 118), rgb(124, 94, 48)
	local BLADE, BLADE_EDGE, BLADE_DARK = rgb(204, 212, 224), rgb(242, 246, 252), rgb(78, 90, 110)
	local HIDE, BLACK = rgb(74, 48, 32), Color3.new(0, 0, 0)
	local atan2, sqrt, cos, abs, ceil, max = math.atan2, math.sqrt, math.cos, math.abs, math.ceil, math.max
	local ALONG = R(0, 0, rad(90)) -- stands a cylinder (they lie along X) up along Y

	-- empty Attachment on a part: anchor points for the animation / skill VFX (slash arcs, bash shockwave, parry flash ...)
	local function attach(part, name, pos)
		local a = Instance.new("Attachment")
		a.Name = name
		a.Position = pos
		a.Parent = part
		return a
	end

	-- A bar between two points of a (y, z) plane. Rotated about X so the part's Y axis runs along the chord.
	-- make = the shield / sword builder, tx = thickness (X), tw = width (Z), pad = extra length so joints overlap.
	local function chord(make, y0, z0, y1, z1, tx, tw, pad, color, mat, x, name)
		local dy, dz = y1 - y0, z1 - z0
		local len = sqrt(dy * dy + dz * dz)
		return make(Vector3.new(tx, len + pad, tw), color, mat, x, (y0 + y1) / 2, (z0 + z1) / 2, name, nil, R(atan2(dz, dy), 0, 0))
	end

	-- ===================================================== SHIELD (Left Arm) =====================================================
	-- Shield space: X = thickness (outward is -X), Y = height (point is down), Z = width. Mount frame is unchanged from the old kit.
	-- Layers, front to back:  gem -0.485 | rim -0.42 | cross -0.36 | cross border -0.32 | inner fillet -0.30 | enamel -0.23 | plate +0.20
	local S = CFrame.new(-0.85, -0.35, -0.3)
	local TOP, SHOULDER, TIP, HALF = 2.6, 1.1, -1.9, 1.55 -- heater outline: flat top, straight sides to SHOULDER, convex taper to the point
	local STEPS, RIMW = 7, 0.30 -- the taper is STEPS slabs; RIMW = brass rim width
	local CY = 1.3 -- height of the cross-bar / gem
	local XF, FT = -0.04, 0.38 -- enamel face: centre x, thickness
	local XR, RT = -0.115, 0.61 -- brass rim
	local XC, CT = -0.15, 0.42 -- brass cross
	local FIELD_A, FIELD_B = BLUE, RED -- quartered field (set FIELD_B = rgb(34, 58, 112) for an all-blue shield)

	local function halfWidth(y) -- straight shoulders, then a convex curve down to the point
		if y >= SHOULDER then
			return HALF
		end
		local t = math.clamp((SHOULDER - y) / (SHOULDER - TIP), 0, 1)
		return HALF * (1 - t ^ 1.5)
	end
	local function shield(size, color, mat, x, y, z, name, shape, rot)
		return piece(char, "Left Arm", size, color, mat, S * CFrame.new(x, y, z) * (rot or CFrame.new()), shape, name)
	end

	-- mount frame: same size and place as the old back plate (carries the swing trail and the VFX anchors), but invisible -
	-- as a 2.2 x 4.3 rectangle it stuck out past the tapered lower half of the heater. The visible back is built below.
	local frame = shield(Vector3.new(0.3, 4.3, 2.2), DARKSTEEL, METAL, 0.05, 0.35, 0, "ShieldFrame")
	frame.Transparency = 1
	swingTrail(frame, Vector3.new(0, 2.0, 0), Vector3.new(0, -2.0, 0), rgb(140, 190, 255), rgb(255, 255, 255), 0.15)

	-- the polyline the rim follows (inset by half the rim width), and how far each face slab may reach without poking past the rim
	local vy, vz, outer = {}, {}, {}
	for i = 0, STEPS do
		local y = SHOULDER - (SHOULDER - TIP) * i / STEPS
		vy[i] = y
		vz[i] = max(halfWidth(y) - RIMW / 2, 0)
	end
	for i = 1, STEPS do
		local slope = atan2(abs(vz[i] - vz[i - 1]), abs(vy[i] - vy[i - 1]))
		outer[i] = vz[i] + (RIMW / 2) / cos(slope)
	end

	-- enamel face, quartered by the cross; every row a touch darker than the one above so the field has depth
	local function band(yTop, yBot, hw, shade, flip)
		local a, b = FIELD_A, FIELD_B
		if flip then
			a, b = b, a
		end
		local h, y = yTop - yBot, (yTop + yBot) / 2
		shield(Vector3.new(FT, h, hw), a:Lerp(BLACK, shade), METAL, XF, y, -hw / 2, "ShieldFace")
		shield(Vector3.new(FT, h, hw), b:Lerp(BLACK, shade), METAL, XF, y, hw / 2, "ShieldFace")
	end
	band(TOP, CY, HALF, 0, false)
	band(CY, SHOULDER, HALF, 0, true)
	for i = 1, STEPS do
		band(vy[i - 1], vy[i], outer[i], 0.035 * i, true)
	end

	-- dark steel backing in the full heater outline, so the reverse is solid steel with the brass rim wrapping round it
	shield(Vector3.new(0.14, TOP - SHOULDER, HALF * 2), DARKSTEEL, METAL, 0.11, (TOP + SHOULDER) / 2, 0, "ShieldBack")
	for i = 1, STEPS do
		shield(Vector3.new(0.14, vy[i - 1] - vy[i], outer[i] * 2), DARKSTEEL, METAL, 0.11, (vy[i - 1] + vy[i]) / 2, 0, "ShieldBack")
	end
	if FULL then -- reinforcing plate where the arm mounts (kept inside the outline)
		shield(Vector3.new(0.1, 1.9, 1.6), STEEL, METAL, 0.15, 0.35, 0, "ShieldBackPlate")
	end

	-- raised brass rim: top bar, straight shoulders, then one bar per taper step following the chord of the curve
	W(shield(Vector3.new(RT, RIMW, HALF * 2), BRASS, METAL, XR, TOP - RIMW / 2, 0, "ShieldRimTop"))
	for _, side in ipairs({ -1, 1 }) do
		local rimName = side < 0 and "ShieldRimL" or "ShieldRimR"
		W(shield(Vector3.new(RT, TOP - SHOULDER + 0.1, RIMW), BRASS, METAL, XR, (TOP + SHOULDER) / 2 - 0.05, side * (HALF - RIMW / 2), rimName))
		W(shield(Vector3.one * 0.46, BRASS_LIGHT, METAL, XR - 0.12, TOP - 0.17, side * (HALF - 0.17), "ShieldCorner", BALL))
		for i = 0, STEPS - 2 do -- the last step is closed by the tip boss instead of two bars crossing at the point
			W(chord(shield, vy[i], side * vz[i], vy[i + 1], side * vz[i + 1], RT, RIMW, 0.14, BRASS, METAL, XR, rimName))
		end
	end

	-- dark inner fillet just inside the rim: the face steps up to the rim instead of butting into it (stops before the point, where it would cross over)
	if FULL then
		local FW, FOFF = 0.07, RIMW / 2 + 0.035
		local fx, fth = -0.07, 0.46
		shield(Vector3.new(fth, FW, (HALF - RIMW) * 2), DARKSTEEL, METAL, fx, TOP - RIMW - FW / 2, 0, "ShieldFillet")
		for _, side in ipairs({ -1, 1 }) do
			shield(Vector3.new(fth, TOP - RIMW - SHOULDER + 0.05, FW), DARKSTEEL, METAL, fx, (TOP - RIMW + SHOULDER) / 2 - 0.025, side * (HALF - RIMW - FW / 2), "ShieldFillet")
			for i = 0, 4 do
				local y0, z0, y1, z1 = vy[i], side * vz[i], vy[i + 1], side * vz[i + 1]
				local dy, dz = y1 - y0, z1 - z0
				local len = sqrt(dy * dy + dz * dz)
				local ny, nz = -dz / len, dy / len -- unit normal, flipped to point at the centre line
				if nz * side > 0 then
					ny, nz = -ny, -nz
				end
				chord(shield, y0 + ny * FOFF, z0 + nz * FOFF, y1 + ny * FOFF, z1 + nz * FOFF, fth, FW, 0.08, DARKSTEEL, METAL, fx, "ShieldFillet")
			end
		end
	end

	-- rivets sit on the rim joints (they hide the seams), plus a row along the top bar and shoulders
	for i = 1, 5 do
		for _, side in ipairs({ -1, 1 }) do
			shield(Vector3.one * 0.2, BRASS_LIGHT, METAL, XR - 0.305, vy[i], side * vz[i], "Rivet", BALL)
		end
	end
	if FULL then
		for _, z in ipairs({ -0.8, 0, 0.8 }) do
			shield(Vector3.one * 0.2, BRASS_LIGHT, METAL, XR - 0.305, TOP - RIMW / 2, z, "Rivet", BALL)
		end
		for _, side in ipairs({ -1, 1 }) do
			for _, y in ipairs({ 2.0, 1.6 }) do
				shield(Vector3.one * 0.2, BRASS_LIGHT, METAL, XR - 0.305, y, side * (HALF - RIMW / 2), "Rivet", BALL)
			end
		end
	end
	W(shield(Vector3.new(0.56, 0.85, 0.44), BRASS, METAL, XR - 0.03, vy[STEPS - 1] - 0.15, 0, "ShieldTip", BALL))

	-- cross-pattee: steel border, brass bar with stepped flared ends, glowing inlay down the middle
	local ARM_UP, ARM_DOWN, ARM_SIDE = TOP - RIMW - 0.14, -0.45, 1.0 -- where the arms end (y for the long bar, z for the cross-bar)
	local vMid, vLen = (ARM_UP + ARM_DOWN) / 2, ARM_UP - ARM_DOWN
	shield(Vector3.new(0.4, vLen - 0.56, 0.64), STEEL, METAL, -0.12, vMid, 0, "CrossBorderV")
	shield(Vector3.new(0.4, 0.64, (ARM_SIDE - 0.28) * 2), STEEL, METAL, -0.12, CY, 0, "CrossBorderH")
	shield(Vector3.new(CT, vLen - 0.2, 0.42), BRASS, METAL, XC, vMid, 0, "CrossV")
	shield(Vector3.new(CT, 0.42, (ARM_SIDE - 0.1) * 2), BRASS, METAL, XC, CY, 0, "CrossH")
	for _, e in ipairs({ { "y", ARM_UP, 1 }, { "y", ARM_DOWN, -1 }, { "z", ARM_SIDE, 1 }, { "z", -ARM_SIDE, -1 } }) do
		local axis, tip, sgn = e[1], e[2], e[3]
		for _, step in ipairs({ { 0.23, 0.14, 0.62 }, { 0.08, 0.16, 0.9 } }) do -- { distance back from the tip, length, width }
			local c = tip - sgn * step[1]
			if axis == "y" then
				shield(Vector3.new(CT, step[2], step[3]), BRASS, METAL, XC, c, 0, "CrossCap")
			else
				shield(Vector3.new(CT, step[3], step[2]), BRASS, METAL, XC, CY, c, "CrossCap")
			end
		end
	end
	local iy0, iy1 = ARM_DOWN + 0.45, ARM_UP - 0.42
	shield(Vector3.new(0.42, iy1 - iy0, 0.09), ICE, NEON, -0.165, (iy0 + iy1) / 2, 0, "ShieldInlay").Transparency = 0.55
	shield(Vector3.new(0.42, 0.09, (ARM_SIDE - 0.4) * 2), ICE, NEON, -0.165, CY, 0, "ShieldInlay").Transparency = 0.55
	if FULL then -- diagonal light-lines radiating from the gem, in the four quarters between the arms
		for _, a in ipairs({ 45, -45 }) do
			shield(Vector3.new(0.12, 2.4, 0.07), ICE, NEON, -0.23, CY, 0, "ShieldInlay", nil, R(rad(a), 0, 0)).Transparency = 0.6
		end
	end

	-- gem in a brass collar at the crossing: collar -> dark socket -> pale facet -> glowing diamond (the kit brightens the light + inlay)
	shield(Vector3.new(0.46, 0.92, 0.92), BRASS_LIGHT, METAL, -0.17, CY, 0, "ShieldGemRing", CYL)
	shield(Vector3.new(0.5, 0.7, 0.7), DARKSTEEL, METAL, -0.18, CY, 0, "ShieldGemSocket", CYL)
	shield(Vector3.new(0.5, 0.46, 0.46), ICE_FACET, NEON, -0.205, CY, 0, "ShieldGemFacet") -- square behind the diamond = eight-point star
	local gem = shield(Vector3.new(0.52, 0.48, 0.48), ICE, NEON, -0.225, CY, 0, "ShieldGem", nil, R(rad(45), 0, 0))
	glow(gem, ICE, 7, 1)

	-- forearm straps (rings that meet the back plate; its inner face sits at arm-local x = -0.65), buckles on the inside, a leather pad against the plate
	for _, y in ipairs({ 0.5, -0.45 }) do
		piece(char, "Left Arm", Vector3.new(0.28, 1.3, 1.3), HIDE, LEATHER, CFrame.new(0, y, 0) * ALONG, CYL, "ShieldStrap")
		if FULL then
			piece(char, "Left Arm", Vector3.new(0.08, 0.34, 0.28), BRASS, METAL, CFrame.new(0.66, y, 0), nil, "ShieldBuckle")
		end
	end
	if FULL then
		piece(char, "Left Arm", Vector3.new(0.07, 1.5, 1.0), HIDE, LEATHER, CFrame.new(-0.61, 0.05, 0), nil, "ShieldPad")
	end

	-- VFX anchors (shield space -> frame-local: x - 0.05, y - 0.35)
	attach(frame, "ShieldCenter", Vector3.new(-0.55, 0, 0))
	attach(frame, "ShieldGemPoint", Vector3.new(-0.55, CY - 0.35, 0))
	attach(frame, "ShieldTop", Vector3.new(-0.45, TOP - 0.35, 0))
	attach(frame, "ShieldTipPoint", Vector3.new(-0.35, TIP - 0.35, 0))
	attach(frame, "ShieldEdgeL", Vector3.new(-0.45, 1.6 - 0.35, -HALF))
	attach(frame, "ShieldEdgeR", Vector3.new(-0.45, 1.6 - 0.35, HALF))

	-- ===================================================== SWORD (Right Arm) =====================================================
	-- Sword space: -Y = toward the tip, +Y = toward the pommel, X = blade thickness, Z = blade width (edges run along Z).
	-- G sits in the fist and is tilted 62 deg: blade points forward (and a little down) when the arm hangs, up-forward when it lifts.
	local G = CFrame.new(0.02, -0.8, 0) * R(rad(62), 0, 0)
	local function sword(size, color, mat, x, y, z, name, shape, rot)
		return piece(char, "Right Arm", size, color, mat, G * CFrame.new(x, y, z) * (rot or CFrame.new()), shape, name)
	end

	-- pommel: neck, oblate wheel-pommel with a flange, glowing orb on top
	W(sword(Vector3.new(0.16, 0.34, 0.34), BRASS, METAL, 0, 0.7, 0, "SwordPommel", CYL, ALONG))
	W(sword(Vector3.new(0.62, 0.5, 0.62), BRASS, METAL, 0, 0.92, 0, "SwordPommel", BALL))
	sword(Vector3.new(0.07, 0.72, 0.72), BRASS_LIGHT, METAL, 0, 0.92, 0, "SwordPommelBand", CYL, ALONG)
	glow(sword(Vector3.one * 0.28, ICE, NEON, 0, 1.16, 0, "SwordGem", BALL), ICE, 5, 1)

	-- leather grip with binding rings
	W(sword(Vector3.new(1.3, 0.26, 0.26), HIDE, LEATHER, 0, 0.02, 0, "SwordGrip", CYL, ALONG))
	for k, y in ipairs(FULL and { 0.5, 0.2, -0.1, -0.4 } or { 0.5, -0.4 }) do
		sword(Vector3.new(0.06, 0.32, 0.32), k % 2 == 1 and BRASS_LIGHT or BRASS_DARK, METAL, 0, y, 0, "SwordGripRing", CYL, ALONG)
	end

	-- swept crossguard: centre bar + boss, three-segment quillons curving toward the tip, ball finials, a gem on each face of the boss
	local GY = -0.7
	W(sword(Vector3.new(0.2, 0.2, 0.5), BRASS, METAL, 0, GY, 0, "SwordGuard"))
	sword(Vector3.new(0.3, 0.38, 0.44), BRASS_LIGHT, METAL, 0, GY - 0.02, 0, "SwordGuardBoss")
	local Q = { { GY, 0.25 }, { GY - 0.02, 0.55 }, { GY - 0.1, 0.82 }, { GY - 0.25, 0.98 } } -- { y, half-span }
	for _, side in ipairs({ -1, 1 }) do
		for k = 1, 3 do
			W(chord(sword, Q[k][1], side * Q[k][2], Q[k + 1][1], side * Q[k + 1][2], 0.2, 0.22 - k * 0.02, 0.1, BRASS, METAL, 0, "SwordQuillon"))
		end
		sword(Vector3.one * 0.3, BRASS_LIGHT, METAL, 0, Q[4][1] - 0.02, side * 1.0, "SwordFinial", BALL)
		if FULL then
			sword(Vector3.new(0.06, 0.22, 0.22), ICE, NEON, side * 0.17, GY - 0.02, 0, "SwordGuardGem", nil, R(rad(45), 0, 0))
		end
	end

	-- blade. The outline is a short polyline { y, half-width }; honed edge bevels run along it as bars, and the flat is filled
	-- with slabs that stay inside it, so every step in the taper is hidden under a bevel (same trick as the shield rim).
	sword(Vector3.new(0.14, 0.34, 0.56), BLADE_DARK, METAL, 0, -0.94, 0, "SwordRicasso")
	local BEV = 0.11
	local B = { { -1.1, 0.27 }, { -2.7, 0.235 }, { -3.3, 0.19 }, { -3.7, 0.1 }, { -3.97, 0 } }
	local bz = {}
	for j = 1, #B do
		bz[j] = max(B[j][2] - BEV / 2, 0)
	end
	for j = 1, #B - 1 do
		for _, side in ipairs({ -1, 1 }) do
			W(chord(sword, B[j][1], side * bz[j], B[j + 1][1], side * bz[j + 1], 0.06, BEV, 0.04, BLADE_EDGE, METAL, 0, j == #B - 1 and "SwordPoint" or "SwordEdge"))
		end
	end
	local blade, bladeY
	for j = 1, #B - 1 do
		local n = max(1, ceil((bz[j] - bz[j + 1]) / 0.04))
		for k = 1, n do
			local ya = B[j][1] + (B[j + 1][1] - B[j][1]) * (k - 1) / n
			local yb = B[j][1] + (B[j + 1][1] - B[j][1]) * k / n
			local za = bz[j] + (bz[j + 1] - bz[j]) * (k - 1) / n
			local zb = bz[j] + (bz[j + 1] - bz[j]) * k / n
			local hw = (za + zb) / 2
			if hw >= 0.02 then
				local isMain = blade == nil
				local part = sword(Vector3.new(0.1, ya - yb, hw * 2), BLADE, METAL, 0, (ya + yb) / 2, 0, isMain and "SwordBlade" or "SwordTaper")
				W(part)
				if isMain then
					blade, bladeY = part, (ya + yb) / 2
				end
			end
		end
	end
	sword(Vector3.new(0.13, 1.95, 0.12), BLADE_DARK, METAL, 0, -2.15, 0, "SwordFuller")
	sword(Vector3.new(0.16, 1.7, 0.045), ICE, NEON, 0, -2.1, 0, "SwordInlay").Transparency = 0.35
	if FULL then -- tapering ice-runes either side of the fuller
		for k = 0, 2 do
			for _, side in ipairs({ -1, 1 }) do
				sword(Vector3.new(0.13, 0.17 - k * 0.04, 0.045), ICE, NEON, 0, -1.55 - k * 0.5, side * 0.115, "SwordRune").Transparency = 0.5
			end
		end
	end

	-- trail runs from the true tip back along the blade; VFX anchors are blade-local
	local TIPY = B[#B][1]
	swingTrail(blade, Vector3.new(0, TIPY - bladeY, 0), Vector3.new(0, -1.5 - bladeY, 0), rgb(140, 190, 255), rgb(255, 255, 255), 0.18)
	attach(blade, "SwordTip", Vector3.new(0, TIPY - bladeY, 0))
	attach(blade, "SwordMid", Vector3.new(0, -2.6 - bladeY, 0))
	attach(blade, "SwordBase", Vector3.new(0, -1.2 - bladeY, 0))
	attach(blade, "SwordHilt", Vector3.new(0, 0 - bladeY, 0))
end

-- V2.Supporter (reworked)
--
-- Drop-in replacement for the old function. It only uses what the original already used:
--   helpers   rgb, piece, W, R, rad, GRIP, swingTrail, glow, sparkle, tipAttachment
--   constants FABRIC, METAL, WOOD, NEON, BALL, CYL
-- Names the old version used (Cape, CapeHem, Mantle, Robe, StaffShaft, StaffCrystal,
-- StaffWing1-3, StaffCharm ...) are kept in case anything looks parts up by name.
--
-- Knobs:
--   SEG    ring smoothness (12 = smooth, 8 = cheaper)
--   FANCY  false drops the micro-details (vine runes, tome, cape sigil, tabard), ~30 fewer parts
function V2.Supporter(char)
	local V3, CF = Vector3.new, CFrame.new

	local GREEN, MINT = rgb(104, 214, 150), rgb(220, 255, 235)
	local CLOAK, SHADE = rgb(34, 92, 70), rgb(16, 36, 28)
	local IVORY, ROBE = rgb(236, 230, 210), rgb(232, 228, 214)
	local GOLD, GOLD_DK = rgb(226, 196, 110), rgb(168, 134, 66)

	local SEG = 12
	local FANCY = true

	-- Ring of small bars lying in the XY plane of `frame` (Roblox has no torus part).
	-- Returns the first bar so a light or sparkle can be hung on it.
	local function ring(limb, frame, radius, segs, thick, color, mat, name)
		local chord = 2 * radius * math.sin(math.pi / segs) * 1.08
		local first
		for i = 0, segs - 1 do
			local a = i / segs * math.pi * 2
			local p = piece(char, limb, V3(thick, chord, thick), color, mat,
				frame * CF(math.cos(a) * radius, math.sin(a) * radius, 0) * R(0, 0, a), nil, name .. i)
			first = first or p
		end
		return first
	end

	-- Square turned 45 degrees: gem settings and emblems.
	local function diamond(limb, size, color, mat, cf, name)
		return piece(char, limb, size, color, mat, cf * R(0, 0, rad(45)), nil, name)
	end

	---------------------------------------------------------------- HOOD + HALO
	piece(char, "Head", V3(1.35, 0.28, 1.3), CLOAK, FABRIC, CF(0, 0.66, 0.05), nil, "HoodTop")
	piece(char, "Head", V3(1.35, 1.3, 0.28), CLOAK, FABRIC, CF(0, 0.1, 0.62), nil, "HoodBack")
	piece(char, "Head", V3(0.22, 1.15, 1.2), CLOAK, FABRIC, CF(-0.66, 0.08, 0.02), nil, "HoodLeft")
	piece(char, "Head", V3(0.22, 1.15, 1.2), CLOAK, FABRIC, CF(0.66, 0.08, 0.02), nil, "HoodRight")
	piece(char, "Head", V3(0.5, 0.22, 0.9), CLOAK, FABRIC, CF(0, 0.84, 0.2), nil, "HoodRidge")
	-- gold frame around the face opening
	piece(char, "Head", V3(1.4, 0.12, 0.2), GOLD, FABRIC, CF(0, 0.7, -0.56), nil, "HoodTrim")
	for _, s in ipairs({ -1, 1 }) do
		piece(char, "Head", V3(0.12, 1.15, 0.2), GOLD, FABRIC, CF(0.69 * s, 0.08, -0.58), nil, "HoodTrimSide")
	end
	-- circlet gem
	diamond("Head", V3(0.3, 0.3, 0.08), GOLD, METAL, CF(0, 0.66, -0.66), "HoodGemSetting")
	diamond("Head", V3(0.18, 0.18, 0.1), GREEN, NEON, CF(0, 0.66, -0.71), "HoodGem")
	-- halo, tilted a few degrees back
	local halo = ring("Head", CF(0, 1.32, 0.08) * R(rad(96), 0, 0), 0.7, SEG + 2, 0.07, GOLD, NEON, "Halo")
	glow(halo, GOLD, 8, 1)
	sparkle(tipAttachment(halo), rgb(255, 244, 200), GOLD, 4, 1.5)

	---------------------------------------------------------------- MANTLE + ROBE
	piece(char, "Torso", V3(2.3, 0.45, 1.25), CLOAK, FABRIC, CF(0, 0.82, 0.04), nil, "Mantle")
	piece(char, "Torso", V3(2.32, 0.12, 1.27), GOLD, FABRIC, CF(0, 0.6, 0.04), nil, "MantleTrim")
	piece(char, "Torso", V3(1.3, 0.3, 1.1), CLOAK, FABRIC, CF(0, 1.06, 0.04), nil, "MantleCollar")
	piece(char, "Torso", V3(1.32, 0.06, 1.12), GOLD, FABRIC, CF(0, 1.21, 0.04), nil, "MantleCollarRim")
	for _, s in ipairs({ -1, 1 }) do
		diamond("Torso", V3(0.3, 0.3, 0.08), GOLD, METAL, CF(0.78 * s, 0.84, -0.6), "MantleGemSetting")
		diamond("Torso", V3(0.18, 0.18, 0.1), GREEN, NEON, CF(0.78 * s, 0.84, -0.65), "MantleGem")
	end

	piece(char, "Torso", V3(2.06, 2.04, 1.07), ROBE, FABRIC, CF(), nil, "Robe")
	piece(char, "Torso", V3(0.35, 2.05, 1.09), CLOAK, FABRIC, CF(), nil, "RobeStole")
	for _, s in ipairs({ -1, 1 }) do
		piece(char, "Torso", V3(0.04, 2.06, 1.1), GOLD, FABRIC, CF(0.2 * s, 0, 0), nil, "StoleEdge")
	end
	piece(char, "Torso", V3(0.35, 0.35, 0.12), GOLD, METAL, CF(0, 0.85, -0.6), BALL, "Clasp")

	-- chest medallion: gold diamond with a glowing healing cross
	diamond("Torso", V3(0.5, 0.5, 0.04), GOLD, METAL, CF(0, 0.1, -0.57), "ChestSigil")
	piece(char, "Torso", V3(0.3, 0.09, 0.05), GREEN, NEON, CF(0, 0.1, -0.6), nil, "ChestPlusH")
	piece(char, "Torso", V3(0.09, 0.3, 0.05), GREEN, NEON, CF(0, 0.1, -0.6), nil, "ChestPlusV")

	-- belt
	piece(char, "Torso", V3(2.1, 0.18, 1.12), SHADE, FABRIC, CF(0, -0.78, 0), nil, "Belt")
	diamond("Torso", V3(0.34, 0.34, 0.08), GOLD, METAL, CF(0, -0.78, -0.58), "BeltBuckle")
	diamond("Torso", V3(0.15, 0.15, 0.1), GREEN, NEON, CF(0, -0.78, -0.62), "BeltGem")

	---------------------------------------------------------------- CAPE
	-- three panels hanging from a hinge at the shoulders, longest in the middle
	local hinge = CF(0, 0.95, 0.6) * R(rad(-6), 0, 0)
	for _, c in ipairs({ { 0, 1.1, 3.7, 0, "" }, { -0.9, 0.7, 3.2, -2, "Side" }, { 0.9, 0.7, 3.2, 2, "Side" } }) do
		local x, w, h, flare, tag = c[1], c[2], c[3], c[4], c[5]
		local base = hinge * CF(x, 0, 0) * R(0, 0, rad(flare))
		piece(char, "Torso", V3(w, h, 0.14), CLOAK, FABRIC, base * CF(0, -h / 2, 0), nil, "Cape" .. tag)
		piece(char, "Torso", V3(w + 0.02, 0.14, 0.18), GOLD, FABRIC, base * CF(0, -h + 0.07, 0.02), nil, "CapeHem" .. tag)
	end

	if FANCY then
		-- sigil on the back of the cape
		local sig = hinge * CF(0, -1.7, 0.1)
		ring("Torso", sig, 0.36, 8, 0.05, GOLD, METAL, "CapeSigil")
		piece(char, "Torso", V3(0.3, 0.07, 0.04), GREEN, NEON, sig, nil, "CapeSigilH")
		piece(char, "Torso", V3(0.07, 0.3, 0.04), GREEN, NEON, sig, nil, "CapeSigilV")

		-- spellbook tucked into the belt (left front, above the leg so it never clips)
		piece(char, "Torso", V3(0.5, 0.56, 0.04), CLOAK, FABRIC, CF(-0.62, -0.52, -0.56), nil, "TomeBack")
		piece(char, "Torso", V3(0.44, 0.5, 0.1), IVORY, FABRIC, CF(-0.62, -0.52, -0.63), nil, "TomePages")
		piece(char, "Torso", V3(0.5, 0.56, 0.04), CLOAK, FABRIC, CF(-0.62, -0.52, -0.7), nil, "TomeCover")
		piece(char, "Torso", V3(0.06, 0.56, 0.18), GOLD_DK, METAL, CF(-0.84, -0.52, -0.63), nil, "TomeSpine")
		diamond("Torso", V3(0.16, 0.16, 0.02), GREEN, NEON, CF(-0.62, -0.52, -0.725), "TomeRune")
	end

	---------------------------------------------------------------- SLEEVES
	for _, side in ipairs({ "Left", "Right" }) do
		local arm = side .. " Arm"
		piece(char, arm, V3(1.1, 1.4, 1.1), ROBE, FABRIC, CF(0, 0.3, 0), nil, "Sleeve" .. side)
		piece(char, arm, V3(1.26, 0.2, 1.26), CLOAK, FABRIC, CF(0, -0.45, 0), nil, "Cuff" .. side)
		piece(char, arm, V3(1.28, 0.06, 1.28), GOLD, METAL, CF(0, -0.58, 0), nil, "CuffTrim" .. side)
	end

	---------------------------------------------------------------- SKIRT + BOOTS
	-- built on the legs so it follows the stride; the tabard halves line up with the stole
	for _, side in ipairs({ "Left", "Right" }) do
		local leg = side .. " Leg"
		local inward = side == "Left" and 1 or -1
		piece(char, leg, V3(1.1, 1.5, 1.12), ROBE, FABRIC, CF(0, 0.27, 0), nil, "Skirt" .. side)
		piece(char, leg, V3(1.14, 0.1, 1.16), GOLD, FABRIC, CF(0, -0.5, 0), nil, "SkirtHem" .. side)
		piece(char, leg, V3(1.08, 0.48, 1.12), SHADE, FABRIC, CF(0, -0.75, 0), nil, "Boot" .. side)
		if FANCY then
			piece(char, leg, V3(0.22, 1.5, 0.1), CLOAK, FABRIC, CF(0.39 * inward, 0.27, -0.58), nil, "Tabard" .. side)
			piece(char, leg, V3(0.26, 0.1, 0.14), GOLD, FABRIC, CF(0.39 * inward, -0.5, -0.58), nil, "TabardHem" .. side)
		end
	end

	---------------------------------------------------------------- STAFF
	local G = GRIP
	local function gp(size, color, mat, cf, shape, name)
		return piece(char, "Right Arm", size, color, mat, G * cf, shape, name)
	end
	local axis = R(0, rad(90), 0) -- turns a cylinder (its axis is X) so it runs along the staff (Z)

	-- shaft, leather grip, bands, caps
	gp(V3(5.8, 0.2, 0.2), IVORY, WOOD, CF(0, 0, -1.4) * axis, CYL, "StaffShaft")
	gp(V3(1.1, 0.25, 0.25), SHADE, FABRIC, CF(0, 0, 0) * axis, CYL, "StaffGrip")
	for _, z in ipairs({ -0.3, 0.3, -3.2 }) do
		gp(V3(0.18, 0.27, 0.27), GOLD, METAL, CF(0, 0, z) * axis, CYL, "StaffBand")
	end
	for _, z in ipairs({ -0.58, 0.58 }) do
		gp(V3(0.1, 0.3, 0.3), GOLD, METAL, CF(0, 0, z) * axis, CYL, "StaffGripCap")
	end
	gp(V3(0.3, 0.27, 0.27), GOLD, METAL, CF(0, 0, 1.45) * axis, CYL, "StaffFoot")
	gp(V3(0.22, 0.22, 0.22), GOLD, METAL, CF(0, 0, 1.64), BALL, "StaffFootTip")
	gp(V3(0.34, 0.4, 0.4), GOLD, METAL, CF(0, 0, -3.85) * axis, CYL, "StaffCollar")
	gp(V3(0.1, 0.32, 0.32), GOLD_DK, METAL, CF(0, 0, -3.66) * axis, CYL, "StaffCollarRing")

	if FANCY then
		-- glowing runes spiralling up the shaft
		for i = 0, 9 do
			local a = i * 1.1
			gp(Vector3.one * (i % 2 == 0 and 0.1 or 0.07), GREEN, NEON,
				CF(math.cos(a) * 0.13, math.sin(a) * 0.13, -0.8 - i * 0.25), BALL, "StaffVine" .. i)
		end
	end

	-- four claws cradling the crystal
	for i = 0, 3 do
		gp(V3(0.07, 0.07, 0.8), GOLD, METAL,
			R(0, 0, rad(90 * i)) * CF(0.27, 0, -4.25) * R(0, rad(10), 0), nil, "StaffProng" .. i)
	end

	-- faceted crystal: octagonal body with stepped points
	local c = CF(0, 0, -4.55)
	local crystal = gp(V3(0.36, 0.36, 0.78), GREEN, NEON, c * R(0, 0, rad(45)), nil, "StaffCrystal")
	gp(V3(0.36, 0.36, 0.78), GREEN, NEON, c, nil, "StaffCrystalB")
	for _, s in ipairs({ -1, 1 }) do
		gp(V3(0.26, 0.26, 0.16), GREEN, NEON, c * CF(0, 0, 0.44 * s) * R(0, 0, rad(45)), nil, "StaffCrystalTip")
		gp(V3(0.13, 0.13, 0.13), MINT, NEON, c * CF(0, 0, 0.55 * s) * R(0, 0, rad(45)), nil, "StaffCrystalPoint")
	end

	-- gyroscope: two gold rings at +-45 deg to the wings (so they never cross a feather) and an energy ring inside
	ring("Right Arm", G * c * R(0, 0, rad(-45)) * R(0, rad(90), 0), 0.74, SEG, 0.07, GOLD, METAL, "RingA")
	ring("Right Arm", G * c * R(0, 0, rad(45)) * R(0, rad(90), 0), 0.74, SEG, 0.07, GOLD, METAL, "RingB")
	ring("Right Arm", G * c, 0.58, SEG, 0.05, GREEN, NEON, "RingC")

	-- shards floating between the crystal and the energy ring
	for i = 0, 2 do
		W(gp(V3(0.1, 0.1, 0.26), MINT, NEON,
			c * R(0, 0, rad(90 + 120 * i)) * CF(0.4, 0, (i - 1) * 0.22) * R(rad(25), 0, rad(45)), nil, "StaffShard" .. i))
	end

	-- wings: five fanned feathers per side, gold primaries and ivory coverts,
	-- sprouting from the energy ring (it has a bar exactly at +-X, so the roots sit on it)
	local feathers = {
		{ -22, 1.0, GOLD }, { -2, 0.92, GOLD }, { 18, 0.8, IVORY }, { 38, 0.64, IVORY }, { 58, 0.46, IVORY },
	}
	for _, s in ipairs({ -1, 1 }) do
		local root = V3(0.58 * s, 0, -4.55)
		gp(Vector3.one * 0.18, GOLD, METAL, CF(root), BALL, "StaffWingRoot")
		for k, f in ipairs(feathers) do
			local a = rad(f[1])
			local dir = V3(s * math.cos(a), 0.16, -math.sin(a)).Unit
			local mid = root + dir * (f[2] / 2)
			W(gp(V3(0.15, 0.05, f[2]), f[3], METAL, CF(mid, mid + dir), nil, "StaffWing" .. k))
		end
	end

	-- hanging charm with chain and two ribbons
	gp(V3(0.04, 0.3, 0.04), GOLD, METAL, CF(0, -0.17, -3.2), nil, "StaffChain")
	W(gp(Vector3.one * 0.26, GREEN, NEON, CF(0, -0.35, -3.2), BALL, "StaffCharm"))
	for i, s in ipairs({ -1, 1 }) do
		W(gp(V3(0.07, 0.75, 0.03), IVORY, FABRIC, CF(0.08 * s, -0.86, -3.2), nil, "StaffRibbon" .. i))
	end

	---------------------------------------------------------------- FX
	-- trail now sits on the head end of the shaft (+X on the cylinder points at the crystal)
	swingTrail(char:FindFirstChild("ClassGear") and char.ClassGear:FindFirstChild("StaffShaft"),
		V3(1.4, 0, 0), V3(2.9, 0, 0), GREEN, rgb(230, 255, 240), 0.2)
	glow(crystal, GREEN, 12, 2)
	sparkle(tipAttachment(crystal), MINT, GREEN, 8, 2)
end

--[[
	GAMBLER  ·  "Ace of Spades" revolver  +  "Loaded D20"
	────────────────────────────────────────────────────────────────────────────
	Drop-in replacement for V2.Gambler(char). Paste this block where the old
	function was (same file / same scope) so piece, W, holder, glow, tipAttachment,
	swingTrail, GRIP, R, rad, rgb, FABRIC, CYL ... resolve exactly as before.
	The hat / vest / tie / coat-tail code is unchanged.

	WHAT CHANGED
	  Revolver  : single-action frame, shield, top strap, boss, ejector rod, collar,
	              gold rib, sights, pearl grips with a spade (right) and heart (left)
	              inlay, gold guard + backstrap, loading gate, engraving lines.
	              Cylinder (with 6 flutes), hammer and trigger are REAL joints.
	  D20       : true icosahedron. 40 glass facets, numbered faces (opposites sum
	              to 21), gold edge rods + vertex studs, glowing core, crit face is
	              gold, four suit tokens orbit it. Hover/spin run per-frame.

	ANIMATION HOOKS  (V2.GetGamblerRig(char), or the value V2.Gambler returns)
	  rig.Fire()            trigger pull -> hammer drop -> muzzle flash -> recock -> cylinder +60°
	  rig.Fan(n, gap)       n shots, `gap` seconds apart (default 4, 0.07)
	  rig.Spin(secs, turns) roulette spin of the cylinder (default 1.3, 3)
	  rig.Cock(true/false)  raise / drop the hammer
	  rig.Roll(h, turns, s) toss the die straight up in WORLD space and catch it
	  rig.Crit()            die flares, spins up, light spikes
	  rig.Muzzle / rig.Flash / rig.Gun.* / rig.Die.*   raw parts and Weld joints
	  rig.Destroy()         stops every loop this rig started
]]
do
	local RunService = game:GetService("RunService")

	----------------------------------------------------------------------------
	-- TUNING
	----------------------------------------------------------------------------
	local QUALITY              = 3     -- 1 lean · 2 + gold edges / inlays / engraving · 3 + numerals, studs, orbiting tokens
	local DIE_RADIUS           = 0.85  -- d20 circumradius (studs)
	local ALLOW_SERVER_AMBIENT = false -- idle die animation runs on clients only unless this is true
	local USE_W                = true  -- pass static gun parts through W() like the old Round AA parts

	local TAU = math.pi * 2

	----------------------------------------------------------------------------
	-- PALETTE / MATERIALS  (built from Enum + Color3 directly: no load-order dependency)
	----------------------------------------------------------------------------
	local function C(r, g, b) return Color3.fromRGB(r, g, b) end
	local C_GOLD   = C(232, 190, 64)
	local C_EMBER  = C(255, 208, 102)
	local C_STEEL  = C(44, 48, 60)
	local C_BLUED  = C(24, 26, 33)
	local C_NICKEL = C(206, 211, 221)
	local C_PEARL  = C(241, 233, 213)
	local C_RUBY   = C(192, 30, 48)
	local C_RUBY_D = C(146, 18, 34)
	local C_INK    = C(30, 16, 10)
	local C_BLACK  = C(8, 8, 10)

	local MET, NEON, GLASS, SMOOTH = Enum.Material.Metal, Enum.Material.Neon, Enum.Material.Glass, Enum.Material.SmoothPlastic
	local CYLS, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball

	----------------------------------------------------------------------------
	-- LOW-LEVEL BUILDERS
	----------------------------------------------------------------------------
	local function make(class, parent, name, size, color, mat, cf, shape, trans)
		local p = Instance.new(class)
		p.Name = name
		if shape then p.Shape = shape end
		p.Size = size
		p.Color = color
		p.Material = mat
		p.Transparency = trans or 0
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = cf
		p.Parent = parent
		return p
	end

	-- Part1.CFrame = Part0.CFrame * C0   (C1 stays identity, so C0 is the only thing to animate)
	local function weld(p0, p1, c0, name)
		local w = Instance.new("Weld")
		w.Name = name or "Weld"
		w.Part0 = p0
		w.Part1 = p1
		w.C0 = c0
		w.C1 = CFrame.new()
		w.Parent = p1
		return w
	end

	-- creates a part at root * rel and welds it to root. returns part, weld
	local function attach(root, parent, name, size, color, mat, rel, shape, trans, class)
		local p = make(class or "Part", parent, name, size, color, mat, root.CFrame * rel, shape, trans)
		return p, weld(root, p, rel)
	end

	-- A rigid sub-assembly hanging off a limb through ONE animatable Weld ("<name>Joint").
	-- base = joint C0 at rest, pose = joint C0 to start in (defaults to base)
	local function newGroup(parent, limb, name, base, pose)
		pose = pose or base
		local hub = make("Part", parent, name .. "Hub", Vector3.new(0.04, 0.04, 0.04), C_BLUED, SMOOTH, limb.CFrame * pose, nil, 1)
		local g = { hub = hub, base = base, joint = weld(limb, hub, pose, name .. "Joint") }
		function g.add(pname, size, color, mat, rel, shape, trans)
			return attach(hub, parent, pname, size, color, mat, rel, shape, trans)
		end
		return g
	end

	----------------------------------------------------------------------------
	-- EASING + TINY TWEEN LOOP  (no Instances, cancellable through rig._conns)
	----------------------------------------------------------------------------
	local function lerp(a, b, t) return a + (b - a) * t end

	local ease = {
		outQuad   = function(t) return 1 - (1 - t) * (1 - t) end,
		inQuad    = function(t) return t * t end,
		outCubic  = function(t) return 1 - (1 - t) ^ 3 end,
		outQuart  = function(t) return 1 - (1 - t) ^ 4 end,
		inOutSine = function(t) return -(math.cos(math.pi * t) - 1) / 2 end,
		outBack   = function(t)
			local c1, c3 = 1.70158, 2.70158
			return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
		end,
	}

	local function makeAnimator(conns)
		return function(duration, curve, step, done)
			local started = os.clock()
			local conn
			conn = RunService.Heartbeat:Connect(function()
				local a = math.min((os.clock() - started) / duration, 1)
				step(curve(a))
				if a >= 1 then
					conn:Disconnect()
					conns[conn] = nil
					if done then done() end
				end
			end)
			conns[conn] = true
		end
	end

	----------------------------------------------------------------------------
	-- D20 GEOMETRY  (icosahedron built from the golden-ratio vertex set)
	----------------------------------------------------------------------------
	local THICK = 0.014 -- facet sheet thickness

	-- EgoMoose's 3-point triangle: two right-angle WedgeParts. a,b,c are local to `root`.
	local function triangle(root, parent, a, b, c, color, mat, trans, name)
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		local s1 = math.max(math.abs(ab:Dot(back)), 0.002)
		local s2 = math.max(math.abs(ac:Dot(back)), 0.002)
		attach(root, parent, name, Vector3.new(THICK, height, s1), color, mat,
			CFrame.fromMatrix((a + b) / 2, right, up, back), nil, trans, "WedgePart")
		attach(root, parent, name, Vector3.new(THICK, height, s2), color, mat,
			CFrame.fromMatrix((a + c) / 2, -right, up, -back), nil, trans, "WedgePart")
	end

	local function d20Geometry(radius)
		local phi = (1 + math.sqrt(5)) / 2
		local raw = {
			{ -1, phi, 0 }, { 1, phi, 0 }, { -1, -phi, 0 }, { 1, -phi, 0 },
			{ 0, -1, phi }, { 0, 1, phi }, { 0, -1, -phi }, { 0, 1, -phi },
			{ phi, 0, -1 }, { phi, 0, 1 }, { -phi, 0, -1 }, { -phi, 0, 1 },
		}
		local k = radius / math.sqrt(1 + phi * phi)
		local V = {}
		for i, v in ipairs(raw) do V[i] = Vector3.new(v[1] * k, v[2] * k, v[3] * k) end

		-- edges = vertex pairs exactly one edge-length apart; faces = triples of mutually adjacent vertices
		local edgeLen = 2 * k
		local adj, E = {}, {}
		for i = 1, 12 do adj[i] = {} end
		for i = 1, 11 do
			for j = i + 1, 12 do
				if math.abs((V[i] - V[j]).Magnitude - edgeLen) < edgeLen * 0.01 then
					adj[i][j] = true
					adj[j][i] = true
					E[#E + 1] = { i, j }
				end
			end
		end
		local F = {}
		for i = 1, 10 do
			for j = i + 1, 11 do
				if adj[i][j] then
					for m = j + 1, 12 do
						if adj[i][m] and adj[j][m] then
							F[#F + 1] = { a = V[i], b = V[j], c = V[m] }
						end
					end
				end
			end
		end
		for _, f in ipairs(F) do
			local n = (f.b - f.a):Cross(f.c - f.a)
			f.center = (f.a + f.b + f.c) / 3
			if n:Dot(f.center) < 0 then
				f.b, f.c = f.c, f.b
				n = -n
			end
			f.normal = n.Unit
		end

		-- numbering: top face = 20, opposite faces always sum to 21, high/low spread over both hemispheres
		local order = {}
		for i = 1, #F do order[i] = i end
		table.sort(order, function(p, q)
			local np, nq = F[p].normal, F[q].normal
			if math.abs(np.Y - nq.Y) > 1e-4 then return np.Y > nq.Y end
			if math.abs(np.X - nq.X) > 1e-4 then return np.X < nq.X end
			return np.Z < nq.Z
		end)
		local opposite = {}
		for i = 1, #F do
			for j = 1, #F do
				if i ~= j and F[i].normal:Dot(F[j].normal) < -0.99 then opposite[i] = j end
			end
		end
		local highs = { 20, 12, 18, 14, 16, 11, 19, 13, 17, 15 }
		local used = 0
		for _, i in ipairs(order) do
			if not F[i].number then
				used = used + 1
				local hi = highs[used]
				local flip = (used % 2 == 0)
				F[i].number = flip and (21 - hi) or hi
				F[opposite[i]].number = flip and hi or (21 - hi)
			end
		end
		return V, E, F, edgeLen
	end

	local function numeral(plate, text, color)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 400
		gui.LightInfluence = 0
		gui.Parent = plate
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBlack
		label.RichText = true
		label.TextScaled = true
		label.TextColor3 = color
		label.Text = text
		label.Parent = gui
	end

	----------------------------------------------------------------------------
	-- REVOLVER
	----------------------------------------------------------------------------
	local function buildGun(char, G, rig, animate)
		local limb = char:FindFirstChild("Right Arm")
		if not limb then return end
		local parent = holder(char)

		local BY, CY = 0.28, 0.12      -- barrel axis height (unchanged: tip attachment / trail still line up), cylinder axis height
		local ZR = R(0, rad(90), 0)    -- turns a Cylinder part's X axis onto the barrel (Z) axis

		local function gp(name, size, color, mat, cf, shape)
			local p = piece(char, "Right Arm", size, color, mat, G * cf, shape, name)
			if p and USE_W then W(p) end
			return p
		end

		-- ── frame ───────────────────────────────────────────────────────────────
		gp("GunShield",   Vector3.new(0.40, 0.52, 0.18), C_STEEL, MET, CFrame.new(0, 0.14, 0.04))
		gp("GunRearPlate", Vector3.new(0.18, 0.30, 0.05), C_STEEL, MET, CFrame.new(0, 0.20, 0.155))
		gp("GunTang",     Vector3.new(0.18, 0.15, 0.24), C_STEEL, MET, CFrame.new(0, 0.10, 0.22))
		gp("GunFrameLow", Vector3.new(0.34, 0.16, 0.74), C_STEEL, MET, CFrame.new(0, -0.22, -0.24))
		gp("GunFrame",    Vector3.new(0.26, 0.06, 0.80), C_STEEL, MET, CFrame.new(0, 0.40, -0.23))
		gp("GunBoss",     Vector3.new(0.27, 0.54, 0.14), C_STEEL, MET, CFrame.new(0, 0.13, -0.68))
		gp("GunHammerPin", Vector3.new(0.22, 0.05, 0.05), C_GOLD, MET, CFrame.new(0, 0.21, 0.21), CYL)
		gp("GunGate",     Vector3.new(0.03, 0.26, 0.17), C_NICKEL, MET, CFrame.new(0.212, 0.08, 0.035))
		gp("GunGateScrew", Vector3.new(0.02, 0.05, 0.05), C_GOLD, MET, CFrame.new(0.228, 0.11, 0.035), CYL)

		-- ── barrel group ────────────────────────────────────────────────────────
		gp("GunBarrel",   Vector3.new(1.14, 0.19, 0.19), C_STEEL, MET, CFrame.new(0, BY, -1.30) * ZR, CYL)
		gp("GunCollar",   Vector3.new(0.14, 0.25, 0.25), C_NICKEL, MET, CFrame.new(0, BY, -0.82) * ZR, CYL)
		gp("GunRib",      Vector3.new(0.045, 0.02, 0.86), C_GOLD, MET, CFrame.new(0, BY + 0.099, -1.28))
		gp("GunRod",      Vector3.new(0.62, 0.095, 0.095), C_BLUED, MET, CFrame.new(0.085, 0.125, -1.06) * ZR, CYL)
		gp("GunRodTip",   Vector3.new(0.05, 0.12, 0.12), C_GOLD, MET, CFrame.new(0.085, 0.125, -1.39) * ZR, CYL)
		gp("GunSightBase", Vector3.new(0.07, 0.035, 0.17), C_STEEL, MET, CFrame.new(0, BY + 0.11, -1.74))
		gp("GunSight",    Vector3.new(0.035, 0.08, 0.06), C_GOLD, MET, CFrame.new(0, BY + 0.155, -1.77))
		gp("GunSightRear", Vector3.new(0.15, 0.04, 0.09), C_STEEL, MET, CFrame.new(0, 0.455, 0.12))
		gp("GunTopLine",  Vector3.new(0.035, 0.012, 0.60), C_GOLD, MET, CFrame.new(0, 0.434, -0.22))
		gp("GunBore",     Vector3.new(0.02, 0.12, 0.12), C_BLACK, SMOOTH, CFrame.new(0, BY, -1.975) * ZR, CYL)
		-- GunMuzzle keeps its old size / position / orientation: tipAttachment + swingTrail depend on it
		local muzzle = gp("GunMuzzle", Vector3.new(0.10, 0.22, 0.22), C_GOLD, MET, CFrame.new(0, BY, -1.92) * R(0, rad(90), 0), CYL)
		tipAttachment(muzzle)
		swingTrail(muzzle, Vector3.new(0, 0.12, 0), Vector3.new(0, -0.12, 0), C_GOLD, rgb(255, 255, 255), 0.12)

		-- ── trigger guard (gold) ────────────────────────────────────────────────
		gp("GunGuard",      Vector3.new(0.045, 0.045, 0.42), C_GOLD, MET, CFrame.new(0, -0.43, -0.09))
		gp("GunGuardFront", Vector3.new(0.045, 0.14, 0.045), C_GOLD, MET, CFrame.new(0, -0.37, -0.30))
		gp("GunGuardBend",  Vector3.new(0.045, 0.075, 0.075), C_GOLD, MET, CFrame.new(0, -0.43, -0.30), CYL)

		-- ── grip: steel core, pearl plates, gold backstrap + butt ───────────────
		local GR = CFrame.new(0, -0.20, 0.19) * R(rad(-18), 0, 0)
		gp("GunGrip",       Vector3.new(0.15, 0.62, 0.27), C_STEEL, MET, GR)
		gp("GunBackstrap",  Vector3.new(0.16, 0.56, 0.035), C_GOLD, MET, GR * CFrame.new(0, 0, 0.1525))
		gp("GunButt",       Vector3.new(0.30, 0.05, 0.33), C_GOLD, MET, GR * CFrame.new(0, -0.325, 0.01))
		local plateR = gp("GunGripPlateR", Vector3.new(0.07, 0.60, 0.29), C_PEARL, SMOOTH, GR * CFrame.new(0.108, 0, 0))
		local plateL = gp("GunGripPlateL", Vector3.new(0.07, 0.60, 0.29), C_PEARL, SMOOTH, GR * CFrame.new(-0.108, 0, 0))
		if plateR then plateR.Reflectance = 0.06 end
		if plateL then plateL.Reflectance = 0.06 end

		if QUALITY >= 2 then
			for _, side in ipairs({ 1, -1 }) do
				gp("GunGripScrew", Vector3.new(0.02, 0.05, 0.05), C_GOLD, MET, GR * CFrame.new(side * 0.147, 0.22, 0), CYL)
				gp("GunFrameInlay", Vector3.new(0.012, 0.018, 0.62), C_GOLD, MET, CFrame.new(side * 0.176, -0.22, -0.26))
			end
			-- card-suit inlays: spade on the outer (right) plate, heart on the inner (left) plate
			local function suit(kind, side, color, mat)
				local x, s, cy = side * 0.1495, 0.10, 0.04
				local d = s * 0.7071                           -- half-diagonal of the 45°-rotated square
				local lobeY = (kind == "spade") and -d / 2 or d / 2
				gp(kind .. "Body", Vector3.new(0.012, s, s), color, mat, GR * CFrame.new(x, cy, 0) * R(rad(45), 0, 0))
				for _, z in ipairs({ -d / 2, d / 2 }) do
					gp(kind .. "Lobe", Vector3.new(0.012, s, s), color, mat, GR * CFrame.new(x, cy + lobeY, z), CYL)
				end
				if kind == "spade" then
					gp("spadeStem", Vector3.new(0.012, 0.06, 0.03), color, mat, GR * CFrame.new(x, cy - d - 0.02, 0))
				end
			end
			suit("spade", 1, C_GOLD, MET)
			suit("heart", -1, C_RUBY, SMOOTH)
		end

		-- ── cylinder (animated): spins about the barrel axis ────────────────────
		local cyl = newGroup(parent, limb, "GunCylinder", G * CFrame.new(0, CY, -0.33))
		cyl.add("GunDrum", Vector3.new(0.56, 0.50, 0.50), C_STEEL, MET, ZR, CYLS)
		cyl.add("GunDrumFront", Vector3.new(0.035, 0.53, 0.53), C_GOLD, MET, CFrame.new(0, 0, -0.27) * ZR, CYLS)
		cyl.add("GunDrumRear", Vector3.new(0.035, 0.53, 0.53), C_GOLD, MET, CFrame.new(0, 0, 0.27) * ZR, CYLS)
		if QUALITY >= 2 then
			for k = 0, 5 do
				local a = rad(30 + 60 * k)
				cyl.add("GunFlute", Vector3.new(0.07, 0.022, 0.44), C_NICKEL, MET, R(0, 0, -a) * CFrame.new(0, 0.256, 0))
			end
		end

		-- ── hammer (animated): pivots about X at the tang ───────────────────────
		local COCKED, RESTED, PULL = rad(46), rad(7), rad(-24)
		local hamBase = G * CFrame.new(0, 0.21, 0.21)
		local ham = newGroup(parent, limb, "GunHammer", hamBase, hamBase * R(COCKED, 0, 0))
		ham.add("GunHammer", Vector3.new(0.075, 0.28, 0.075), C_BLUED, MET, CFrame.new(0, 0.14, 0))
		ham.add("GunHammerNose", Vector3.new(0.07, 0.07, 0.10), C_BLUED, MET, CFrame.new(0, 0.05, -0.07))
		local spurCF = CFrame.new(0, 0.285, 0.07) * R(rad(-16), 0, 0)
		ham.add("GunSpur", Vector3.new(0.09, 0.045, 0.18), C_GOLD, MET, spurCF)
		if QUALITY >= 2 then
			for k = 1, 3 do
				ham.add("GunSpurGrip", Vector3.new(0.095, 0.012, 0.02), C_BLUED, MET, spurCF * CFrame.new(0, 0.026, (k - 2) * 0.045))
			end
		end

		-- ── trigger (animated) ──────────────────────────────────────────────────
		local trg = newGroup(parent, limb, "GunTrigger", G * CFrame.new(0, -0.29, 0))
		trg.add("GunTrigger", Vector3.new(0.04, 0.115, 0.05), C_NICKEL, MET, CFrame.new(0, -0.0575, 0) * R(rad(10), 0, 0))

		-- ── muzzle flash (hidden until Fire) ────────────────────────────────────
		local flashCF = G * CFrame.new(0, BY, -2.08)
		local flash = make("Part", parent, "GunFlash", Vector3.new(0.5, 0.5, 0.5), C_EMBER, NEON, limb.CFrame * flashCF, BALL, 1)
		weld(limb, flash, flashCF, "GunFlashWeld")
		local flashLight, sparks, smoke
		if flash then
			flash.Transparency = 1
			flashLight = Instance.new("PointLight")
			flashLight.Color = C_EMBER
			flashLight.Range = 14
			flashLight.Brightness = 0
			flashLight.Parent = flash

			sparks = Instance.new("ParticleEmitter")
			sparks.Rate = 0
			sparks.EmissionDirection = Enum.NormalId.Front
			sparks.Speed = NumberRange.new(14, 26)
			sparks.SpreadAngle = Vector2.new(22, 22)
			sparks.Lifetime = NumberRange.new(0.12, 0.28)
			sparks.Drag = 4
			sparks.Acceleration = Vector3.new(0, -12, 0)
			sparks.LightEmission = 1
			sparks.Color = ColorSequence.new(C_EMBER, C_GOLD)
			sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.16), NumberSequenceKeypoint.new(1, 0) })
			sparks.Parent = flash

			smoke = Instance.new("ParticleEmitter")
			smoke.Rate = 0
			smoke.EmissionDirection = Enum.NormalId.Front
			smoke.Speed = NumberRange.new(2, 5)
			smoke.SpreadAngle = Vector2.new(18, 18)
			smoke.Lifetime = NumberRange.new(0.5, 0.9)
			smoke.RotSpeed = NumberRange.new(-40, 40)
			smoke.Acceleration = Vector3.new(0, 2.5, 0)
			smoke.Color = ColorSequence.new(C(150, 150, 156))
			smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1.1) })
			smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
			smoke.Parent = flash
		end

		-- ── animation state + hooks ─────────────────────────────────────────────
		local state = { ham = COCKED, trig = 0, cyl = 0, cylTarget = 0 }
		local function setHam(a) state.ham = a; ham.joint.C0 = ham.base * R(a, 0, 0) end
		local function setTrig(a) state.trig = a; trg.joint.C0 = trg.base * R(a, 0, 0) end
		local function setCyl(a) state.cyl = a; cyl.joint.C0 = cyl.base * R(0, 0, a) end

		local function muzzleFlash()
			if not flash then return end
			flash.Transparency = 0.15
			if flashLight then flashLight.Brightness = 6 end
			sparks:Emit(9)
			smoke:Emit(4)
			animate(0.12, ease.outQuad, function(a)
				flash.Transparency = lerp(0.15, 1, a)
				local s = lerp(0.5, 0.95, a)
				flash.Size = Vector3.new(s, s, s)
				if flashLight then flashLight.Brightness = 6 * (1 - a) end
			end)
		end

		local function fire()
			local h0 = state.ham
			state.cylTarget = state.cylTarget - rad(60)   -- clockwise seen from behind, like a Colt
			local c0, c1 = state.cyl, state.cylTarget
			animate(0.05, ease.outQuad, function(a) setTrig(PULL * a) end)
			animate(0.055, ease.inQuad, function(a) setHam(lerp(h0, RESTED, a)) end, function()
				muzzleFlash()
				animate(0.20, ease.outBack, function(a) setHam(lerp(RESTED, COCKED, a)) end)
				animate(0.18, ease.outCubic, function(a) setCyl(lerp(c0, c1, a)) end)
				animate(0.14, ease.outQuad, function(a) setTrig(PULL * (1 - a)) end)
			end)
		end

		rig.Fire = fire
		function rig.Fan(n, gap)
			n = n or 4
			gap = gap or 0.07
			for i = 0, n - 1 do
				if i == 0 then fire() else task.delay(i * gap, fire) end
			end
		end
		function rig.Spin(duration, turns)
			local from = state.cyl
			state.cylTarget = from - TAU * (turns or 3)
			local to = state.cylTarget
			animate(duration or 1.3, ease.outQuart, function(a) setCyl(lerp(from, to, a)) end)
		end
		function rig.Cock(on)
			local from = state.ham
			local to = (on == false) and RESTED or COCKED
			animate(0.16, ease.outBack, function(a) setHam(lerp(from, to, a)) end)
		end

		rig.Muzzle = muzzle
		rig.Flash = flash
		rig.Gun = { Cylinder = cyl.joint, Hammer = ham.joint, Trigger = trg.joint, State = state }
	end

	----------------------------------------------------------------------------
	-- LOADED D20  (left hand)
	----------------------------------------------------------------------------
	local function buildDie(char, rig)
		local limb = char:FindFirstChild("Left Arm")
		if not limb then return end

		local model = Instance.new("Model")
		model.Name = "GamblerD20"
		model.Parent = holder(char)

		-- same hand pose as the old die
		local base = GRIP * CFrame.new(0, 0.05, -0.35) * R(rad(20), rad(35), 0)
		local hover = newGroup(model, limb, "D20Hover", base)   -- floats / tosses / wobbles (never spins)
		model.PrimaryPart = hover.hub

		local coreSize = DIE_RADIUS * 0.62
		local core, spinJoint = attach(hover.hub, model, "D20Core", Vector3.new(coreSize, coreSize, coreSize), C_EMBER, NEON, CFrame.new(), BALL, 0)
		spinJoint.Name = "D20Spin"

		local V, E, F, edgeLen = d20Geometry(DIE_RADIUS)
		for i, f in ipairs(F) do
			local crit = (f.number == 20)
			local color = crit and C_EMBER or ((i % 2 == 0) and C_RUBY or C_RUBY_D)
			triangle(core, model, f.a, f.b, f.c, color, crit and NEON or GLASS, crit and 0.12 or 0.2, "D20Face" .. f.number)

			if QUALITY >= 3 then
				-- numeral plate: invisible part just above the facet, text "up" points at the facet's first vertex
				local toVertex = f.a - f.center
				local up = (toVertex - f.normal * toVertex:Dot(f.normal)).Unit
				local back = -f.normal
				local pos = f.center + f.normal * 0.016
				local plate = attach(core, model, "D20Num" .. f.number, Vector3.new(0.3, 0.3, 0.01), C_BLACK, SMOOTH,
					CFrame.fromMatrix(pos, up:Cross(back), up, back), nil, 1)
				local text = tostring(f.number)
				if f.number == 6 or f.number == 9 then text = "<u>" .. text .. "</u>" end
				numeral(plate, text, crit and C_INK or C_EMBER)
			end
		end

		if QUALITY >= 2 then
			for _, e in ipairs(E) do
				local a, b = V[e[1]], V[e[2]]
				local dir = (b - a).Unit
				local ref = (math.abs(dir.Y) < 0.95) and Vector3.new(0, 1, 0) or Vector3.new(1, 0, 0)
				local y = (ref - dir * ref:Dot(dir)).Unit
				local z = dir:Cross(y)
				attach(core, model, "D20Edge", Vector3.new(edgeLen + 0.03, 0.04, 0.04), C_GOLD, MET,
					CFrame.fromMatrix((a + b) / 2, dir, y, z), CYLS, 0)
			end
		end
		if QUALITY >= 3 then
			for _, v in ipairs(V) do
				attach(core, model, "D20Stud", Vector3.new(0.085, 0.085, 0.085), C_GOLD, MET, CFrame.new(v), BALL, 0)
			end
		end

		-- four suit tokens orbit the die (attached to the hover hub, so they do NOT spin with the die)
		local tokens = {}
		if QUALITY >= 3 then
			for k = 1, 4 do
				local _, j = hover.add("D20Token", Vector3.new(0.1, 0.1, 0.1), (k % 2 == 1) and C_GOLD or C_RUBY, NEON, CFrame.new(), nil, 0)
				tokens[k] = j
			end
		end

		glow(core, C_GOLD, 7, 1.2)
		local light = core:FindFirstChildWhichIsA("PointLight")

		local dust = Instance.new("ParticleEmitter")
		dust.Rate = 7
		dust.Lifetime = NumberRange.new(0.7, 1.3)
		dust.Speed = NumberRange.new(0.2, 0.7)
		dust.SpreadAngle = Vector2.new(180, 180)
		dust.Acceleration = Vector3.new(0, 0.8, 0)
		dust.LightEmission = 1
		dust.LockedToPart = true
		dust.Color = ColorSequence.new(C_EMBER)
		dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.09), NumberSequenceKeypoint.new(1, 0) })
		dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		dust.Parent = core

		-- per-frame pose: idle float/spin + optional toss (roll) + optional flare (crit)
		local t0 = os.clock()
		local roll, critT
		local function stepDie()
			local now = os.clock()
			local t = now - t0
			local lift = Vector3.new(0, 0, 0)
			local tumble = CFrame.new()
			if roll then
				local a = (now - roll.t) / roll.dur
				if a >= 1 then
					roll = nil
				else
					-- toss goes straight up in WORLD space, whatever the arm is doing
					lift = limb.CFrame:VectorToObjectSpace(Vector3.new(0, roll.height * 4 * a * (1 - a), 0))
					tumble = R(TAU * roll.turns * ease.inOutSine(a), 0, TAU * 0.5 * a)
				end
			end
			local extraSpin, heat = 0, 0
			if critT then
				local c = (now - critT) / 0.85
				if c >= 1 then
					critT = nil
				else
					extraSpin = TAU * 2 * ease.outCubic(c)
					heat = 1 - c
				end
			end
			hover.joint.C0 = CFrame.new(lift) * base
				* CFrame.new(0, math.sin(t * 2.2) * 0.05, 0)
				* R(math.sin(t * 1.6) * 0.10, 0, math.cos(t * 1.2) * 0.10)
				* tumble
			spinJoint.C0 = R(0, t * 0.9 + extraSpin, 0)
			if light then light.Brightness = 1.2 + math.sin(t * 3) * 0.25 + heat * 4.5 end
			for k = 1, #tokens do
				local ang = t * 1.35 + (k - 1) * TAU / #tokens
				tokens[k].C0 = R(rad(24), 0, rad(-14)) * R(0, ang, 0)
					* CFrame.new(DIE_RADIUS * 1.35, math.sin(ang * 2 + k) * 0.08, 0) * R(ang, ang * 0.7, 0)
			end
		end

		local ambient = RunService:IsClient() or ALLOW_SERVER_AMBIENT
		local loop
		local function startLoop()
			if loop then return end
			loop = RunService.Heartbeat:Connect(function()
				if not hover.hub.Parent then
					loop:Disconnect()
					loop = nil
					return
				end
				stepDie()
				if not ambient and not roll and not critT then
					loop:Disconnect()
					loop = nil
				end
			end)
		end

		stepDie() -- pose once so a static (server) build still looks right
		if ambient then startLoop() end

		function rig.Roll(height, turns, duration)
			roll = { t = os.clock(), dur = duration or 0.9, height = height or 1.8, turns = turns or 2 }
			startLoop()
		end
		function rig.Crit()
			critT = os.clock()
			startLoop()
		end
		function rig._stopDie()
			if loop then
				loop:Disconnect()
				loop = nil
			end
		end
		rig.Die = { Model = model, Core = core, Hover = hover.joint, Spin = spinJoint, Light = light }
	end

	----------------------------------------------------------------------------
	-- PUBLIC
	----------------------------------------------------------------------------
	V2.GamblerRigs = V2.GamblerRigs or setmetatable({}, { __mode = "k" })
	function V2.GetGamblerRig(char) return V2.GamblerRigs[char] end

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
		local rig = { Char = char, _conns = {} }
		local animate = makeAnimator(rig._conns)
		buildGun(char, G, rig, animate)
		buildDie(char, rig)

		function rig.Destroy()
			for conn in pairs(rig._conns) do
				conn:Disconnect()
				rig._conns[conn] = nil
			end
			if rig._stopDie then rig._stopDie() end
		end

		V2.GamblerRigs[char] = rig
		return rig
	end
end

function V2.Duelist(char)
	local NAVY, SILVER, CRIMSON, EDGE, DARK = rgb(28, 38, 70), rgb(205, 212, 226), rgb(176, 30, 44), rgb(150, 200, 255), rgb(20, 22, 30)
	local STEEL, GUNMETAL, WHITE = rgb(196, 205, 222), rgb(88, 96, 114), rgb(255, 255, 255)
	local G = GRIP

	local DETAIL = 2 -- 1 = lean (~35 parts), 2 = full (~65 parts)
	local KB = -1 -- knuckle-bow side along G's Y axis (-1 = below the hand, as in your original knuckle disc)
	local V = Vector3.new

	-- ---------------------------------------------------------------- helpers
	-- core part: not W-wrapped, exactly like the first block of your original
	local function core(size, color, mat, cf, shape, name)
		return piece(char, "Right Arm", size, color, mat, G * cf, shape, name)
	end

	-- decorative part: W-wrapped, like your Round AA block
	local function deco(size, color, mat, cf, shape, name, props)
		local p = piece(char, "Right Arm", size, color, mat, G * cf, shape, name)
		if p then
			W(p)
			if props then
				for k, v in pairs(props) do
					p[k] = v
				end
			end
		end
		return p
	end

	-- a square bar from point a to point b (G space)
	local function seg(a, b, t, color, mat, name, props)
		local d = b - a
		local len = d.Magnitude
		if len < 1e-4 then
			return nil
		end
		local up = (math.abs(d.Unit.Y) > 0.96) and V(1, 0, 0) or V(0, 1, 0)
		return deco(V(t, t, len * 1.06), color, mat, CFrame.lookAt((a + b) / 2, b, up), nil, name, props)
	end

	local function chain(points, t, color, mat, name, props)
		for i = 1, #points - 1 do
			seg(points[i], points[i + 1], t, color, mat, name, props)
		end
	end

	-- quadratic bezier -> point list (lets a handful of bars read as a smooth curve)
	local function bezier(p0, p1, p2, n)
		local pts = {}
		for i = 0, n do
			local t = i / n
			pts[#pts + 1] = p0 * ((1 - t) ^ 2) + p1 * (2 * (1 - t) * t) + p2 * (t * t)
		end
		return pts
	end

	-- ring of bars in the XY plane at depth z
	local function ring(z, r, n, t, color, mat, name, props)
		local pts = {}
		for i = 0, n do
			local a = (i / n) * math.pi * 2
			pts[#pts + 1] = V(math.cos(a) * r, math.sin(a) * r, z)
		end
		chain(pts, t, color, mat, name, props)
	end

	-- ------------------------------------------------------------------ BLADE
	-- blade-local Z: -2.75 is the very point, +2.15 sits just above the guard
	local blade = core(V(0.07, 0.17, 4.3), STEEL, METAL, CFrame.new(0, 0, -2.75), nil, "Blade")
	core(V(0.08, 0.05, 4.1), EDGE, NEON, CFrame.new(0, 0.09, -2.7), nil, "BladeEdge")

	-- stepped taper to a needle point (forte -> foible -> point)
	core(V(0.06, 0.12, 0.36), STEEL, METAL, CFrame.new(0, 0.01, -5.08), nil, "BladeTip")
	deco(V(0.04, 0.065, 0.3), STEEL, METAL, CFrame.new(0, 0.01, -5.36), nil, "BladeTip2")
	deco(Vector3.one * 0.13, WHITE, NEON, CFrame.new(0, 0.01, -5.5), BALL, "TipGlint", { Transparency = 0.3 })

	-- unsharpened ricasso, lower edge glow, bright fuller
	deco(V(0.1, 0.21, 0.5), GUNMETAL, METAL, CFrame.new(0, 0, -0.9), nil, "BladeRicasso")
	deco(V(0.07, 0.04, 4.0), EDGE, NEON, CFrame.new(0, -0.09, -2.75), nil, "BladeEdgeLow", { Transparency = 0.5 })
	deco(V(0.05, 0.1, 3.6), rgb(230, 240, 255), METAL, CFrame.new(0, -0.05, -2.6), nil, "BladeFuller")

	-- engraved runes, dim at rest - DuelistCombat lights them up when charging
	if DETAIL >= 2 then
		local ys = { 0.035, -0.03, 0.03, -0.035 }
		for i = 0, 3 do
			for _, s in ipairs({ -1, 1 }) do
				deco(V(0.012, 0.06, 0.14), EDGE, NEON, CFrame.new(0.04 * s, ys[i + 1], -1.7 - i * 0.55), nil, "BladeRune", { Transparency = 0.6 })
			end
		end
	end

	-- ------------------------------------------------------------------ GUARD
	-- the cup (same two pieces as before) plus a glowing rim
	core(Vector3.one * 0.5, SILVER, METAL, CFrame.new(0, 0, -0.55), BALL, "CupHilt")
	core(V(0.06, 0.75, 0.75), SILVER, METAL, CFrame.new(0, 0, -0.6) * R(0, rad(90), 0), CYL, "GuardRing")
	if DETAIL >= 2 then
		ring(-0.6, 0.39, 12, 0.045, EDGE, NEON, "CupRim", { Transparency = 0.15 })
	end

	-- quillon block + S-curved quillons (one sweeps to the point, one to the pommel)
	deco(V(0.26, 0.24, 0.24), GUNMETAL, METAL, CFrame.new(0, 0, -0.62), nil, "GuardBlock")
	deco(V(0.7, 0.1, 0.1), SILVER, METAL, CFrame.new(0, 0, -0.62), nil, "BladeQuillon")
	chain(bezier(V(0.35, 0, -0.62), V(0.62, 0, -0.62), V(0.72, 0, -0.88), 3), 0.085, SILVER, METAL, "BladeQuillonArc")
	chain(bezier(V(-0.35, 0, -0.62), V(-0.62, 0, -0.62), V(-0.72, 0, -0.36), 3), 0.085, SILVER, METAL, "BladeQuillonArc")
	deco(Vector3.one * 0.15, SILVER, METAL, CFrame.new(0.73, 0, -0.9), BALL, "QuillonFinial")
	deco(Vector3.one * 0.15, SILVER, METAL, CFrame.new(-0.73, 0, -0.34), BALL, "QuillonFinial")

	-- knuckle bow: a D-shaped loop from the guard block round to the pommel
	chain(bezier(V(0, 0.09 * KB, -0.62), V(0, 0.85 * KB, -0.6), V(0, 0.58 * KB, -0.08), 3), 0.07, SILVER, METAL, "BladeKnuckle")
	chain(bezier(V(0, 0.58 * KB, -0.08), V(0, 0.55 * KB, 0.4), V(0, 0.1 * KB, 0.4), 3), 0.07, SILVER, METAL, "BladeKnuckle")

	-- swept-hilt side arms joining quillon tips to the bow
	if DETAIL >= 2 then
		chain(bezier(V(-0.72, 0, -0.36), V(-0.42, 0.45 * KB, -0.2), V(-0.02, 0.55 * KB, -0.02), 3), 0.05, SILVER, METAL, "HiltArm")
		chain(bezier(V(0.72, 0, -0.88), V(0.42, 0.5 * KB, -0.6), V(0.02, 0.5 * KB, -0.3), 3), 0.05, SILVER, METAL, "HiltArm")
	end

	-- ------------------------------------------------------------ GRIP/POMMEL
	core(V(0.75, 0.16, 0.16), DARK, LEATHER, CFrame.new(0, 0, -0.05) * R(0, rad(90), 0), CYL, "Grip")
	for i = 0, 3 do
		deco(V(0.07, 0.2, 0.2), CRIMSON, LEATHER, CFrame.new(0, 0, -0.3 + i * 0.2) * R(0, rad(90), 0), CYL, "BladeWrap")
	end
	if DETAIL >= 2 then
		for i = 0, 2 do
			deco(V(0.03, 0.215, 0.215), SILVER, METAL, CFrame.new(0, 0, -0.2 + i * 0.2) * R(0, rad(90), 0), CYL, "GripWire")
		end
	end
	deco(V(0.05, 0.2, 0.2), GUNMETAL, METAL, CFrame.new(0, 0, 0.345) * R(0, rad(90), 0), CYL, "PommelCollar")
	core(Vector3.one * 0.24, SILVER, METAL, CFrame.new(0, 0, 0.4), BALL, "Pommel")
	deco(Vector3.one * 0.1, CRIMSON, NEON, CFrame.new(0, 0, 0.52), BALL, "PommelGem")

	-- ---------------------------------------------------------- FX ATTACHMENTS
	if blade then
		blade.Reflectance = 0.12

		local function att(name, z, y)
			local a = Instance.new("Attachment")
			a.Name = name
			a.Position = V(0, y or 0, z)
			a.Parent = blade
			return a
		end

		-- the true point (blade-local -2.75 == G z -5.5)
		local tip = att("Tip", -2.75)
		att("Foible", -1.75) -- weak third: parry sparks, light taps
		att("Mid", -0.4)
		att("Forte", 1.55) -- strong third near the guard: binds, beats
		att("Hilt", 2.15)

		-- swing trail: a ribbon along the whole blade (same anchor points as before)
		local a0, a1 = att("SwingA0", -2.1), att("SwingA1", 2.1)
		local t = Instance.new("Trail")
		t.Name = "SwingTrail"
		t.Attachment0, t.Attachment1 = a0, a1
		t.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITE),
			ColorSequenceKeypoint.new(0.3, EDGE),
			ColorSequenceKeypoint.new(1, rgb(70, 110, 255)),
		})
		t.LightEmission = 1
		t.Lifetime = 0.16
		t.MinLength = 0.05
		t.FaceCamera = true
		t.Enabled = false
		t.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.6, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		t.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15) })
		t.Parent = blade

		-- thrust trail: a short vertical ribbon dragged behind the POINT (streak for lunges)
		local p0, p1 = att("ThrustA0", -2.75, 0.16), att("ThrustA1", -2.75, -0.16)
		local tt = Instance.new("Trail")
		tt.Name = "ThrustTrail"
		tt.Attachment0, tt.Attachment1 = p0, p1
		tt.Color = ColorSequence.new(WHITE, EDGE)
		tt.LightEmission = 1
		tt.Lifetime = 0.22
		tt.MinLength = 0.03
		tt.FaceCamera = true
		tt.Enabled = false
		tt.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
		tt.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		tt.Parent = blade

		-- sparks: Emit()-only burst at the point (hits, parries, thrusts)
		local sp = Instance.new("ParticleEmitter")
		sp.Name = "TipSparks"
		sp.Enabled = false
		sp.Rate = 0
		sp.Lifetime = NumberRange.new(0.2, 0.45)
		sp.Speed = NumberRange.new(6, 18)
		sp.SpreadAngle = Vector2.new(180, 180)
		sp.Drag = 4
		sp.LightEmission = 1
		sp.LightInfluence = 0
		sp.Acceleration = V(0, -12, 0)
		sp.Color = ColorSequence.new(WHITE, EDGE)
		sp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0) })
		sp.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		sp.Parent = tip

		-- motes drifting off the whole blade while a skill is charged
		local m = Instance.new("ParticleEmitter")
		m.Name = "EdgeMotes"
		m.Enabled = false
		m.Rate = 30
		m.Lifetime = NumberRange.new(0.5, 0.9)
		m.Speed = NumberRange.new(0.3, 1.6)
		m.SpreadAngle = Vector2.new(180, 180)
		m.LightEmission = 1
		m.LightInfluence = 0
		m.Acceleration = V(0, 2, 0)
		m.Color = ColorSequence.new(WHITE, EDGE)
		m.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0) })
		m.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		m.Shape = Enum.ParticleEmitterShape.Box
		m.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		m.Parent = blade

		-- glow (off at rest; DuelistCombat drives Enabled/Brightness)
		local light = Instance.new("PointLight")
		light.Name = "BladeLight"
		light.Color = EDGE
		light.Range = 9
		light.Brightness = 2
		light.Shadows = false
		light.Enabled = false
		light.Parent = blade
	end

	-- ------------------------------------------------------- COAT (unchanged)
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

-- Twinblade (rework 2). Each sword is a slim curved sabre, built around one invisible hub (BladeRoot R/L) that hangs off the arm
-- by a Motor6D (BladeSpin R/L), so the client can really spin the whole weapon in the hand (ClassAnimator, Blade Whirl).
-- Hub space: blade runs along -Z, edge on +Y, spine on -Y. Hub origin is the hand. HOLD rolls the hub 180 degrees about the blade so the
-- edge faces down-forward in the hand and the tip curves up, like a sabre is really held.
-- Right = "Emberfang" (gold round tsuba, ember edge). Left = "Azurewing" (silver square tsuba, frost edge).
-- Parts the kit looks up by name: BladeGem, BladeEdgeGlow* (every segment), BladeFuller > FlowEmbers, Blade > SwingTrail / SwingTrailCore.
local function twinBlade(char, arm, edge, edgeGlow, tag)
	local armPart = char:FindFirstChild(arm)
	if not armPart then return end
	local ember = tag == "R"
	local STEEL, SHEEN = rgb(200, 206, 218), rgb(240, 244, 252)
	local TRIM = ember and rgb(222, 176, 84) or rgb(190, 205, 226)
	local DARK = ember and rgb(38, 26, 28) or rgb(24, 30, 42)
	local WRAP = edge:Lerp(rgb(0, 0, 0), 0.45)
	local HOT = edge:Lerp(rgb(255, 255, 255), 0.65)

	local hub = Instance.new("Part")
	hub.Name = "BladeRoot" .. tag
	hub.Size = Vector3.one * 0.1
	hub.Transparency = 1
	hub.CanCollide, hub.CanQuery, hub.CanTouch, hub.Massless, hub.CastShadow = false, false, false, true, false
	local HOLD = GRIP * R(0, 0, math.pi)
	hub.CFrame = armPart.CFrame * HOLD
	W(hub)
	hub.Parent = holder(char)
	local spin = Instance.new("Motor6D")
	spin.Name = "BladeSpin" .. tag
	spin.Part0, spin.Part1 = armPart, hub
	spin.C0 = HOLD
	spin.Parent = hub

	local function add(name, size, color, mat, cf, shape, transp)
		local p
		if shape == WEDGE then
			p = Instance.new("WedgePart")
		else
			p = Instance.new("Part")
			if shape then p.Shape = shape end
		end
		p.Name = name .. tag
		p.Size = size
		p.Color = color
		p.Material = mat or Enum.Material.SmoothPlastic
		p.Transparency = transp or 0
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CFrame = hub.CFrame * cf
		local w = Instance.new("Weld")
		w.Part0, w.Part1 = hub, p
		w.C0 = cf
		w.Parent = p
		W(p)
		p.Parent = holder(char)
		return p
	end

	-- ===== hilt =====
	add("BladeGrip", Vector3.new(1.0, 0.19, 0.19), DARK, LEATHER, CFrame.new(0, 0, 0.03) * R(0, rad(90), 0), CYL)
	for i = 0, 3 do
		add("BladeWrap", Vector3.new(0.2, 0.2, 0.06), WRAP, LEATHER, CFrame.new(0, 0, -0.33 + i * 0.24) * R(0, 0, rad(45)))
	end
	add("BladePommel", Vector3.new(0.12, 0.27, 0.27), TRIM, METAL, CFrame.new(0, 0, 0.57) * R(0, rad(90), 0), CYL)
	add("BladePommelGem", Vector3.one * 0.11, edge, NEON, CFrame.new(0, 0, 0.67) * R(rad(45), 0, rad(45)))

	-- ===== tsuba (guard) =====
	if ember then
		add("BladeGuard", Vector3.new(0.07, 0.86, 0.86), TRIM, METAL, CFrame.new(0, 0, -0.55) * R(0, rad(90), 0), CYL)
		add("BladeGuardInner", Vector3.new(0.09, 0.58, 0.58), DARK, METAL, CFrame.new(0, 0, -0.55) * R(0, rad(90), 0), CYL)
	else
		add("BladeGuard", Vector3.new(0.66, 0.66, 0.07), TRIM, METAL, CFrame.new(0, 0, -0.55) * R(0, 0, rad(45)))
		add("BladeGuardInner", Vector3.new(0.44, 0.44, 0.09), DARK, METAL, CFrame.new(0, 0, -0.55) * R(0, 0, rad(45)))
	end
	glow(add("BladeGem", Vector3.one * 0.16, edge, NEON, CFrame.new(0, 0, -0.6) * R(rad(45), 0, rad(45))), edgeGlow, 6, 1.5)
	add("BladeCollar", Vector3.new(0.12, 0.36, 0.14), TRIM, METAL, CFrame.new(0, 0, -0.67))

	-- ===== curved blade: short overlapping segments, narrowing toward the tip =====
	local SEGMENTS, LEN, BEND = 6, 0.62, rad(1.7)
	local seg = CFrame.new(0, 0, -0.72)
	local blade
	for i = 1, SEGMENTS do
		local depth = 0.32 - 0.022 * (i - 1)
		local c = seg * CFrame.new(0, 0, -LEN / 2)
		local body = add(i == 1 and "Blade" or ("BladeSeg" .. i), Vector3.new(0.07, depth, LEN + 0.03), STEEL, METAL, c)
		if i == 1 then blade = body end
		add("BladeShine" .. i, Vector3.new(0.076, depth * 0.3, LEN + 0.03), SHEEN, METAL, c * CFrame.new(0, -depth * 0.14, 0))
		add("BladeSpine" .. i, Vector3.new(0.09, 0.05, LEN + 0.03), DARK, METAL, c * CFrame.new(0, -depth / 2, 0))
		add("BladeEdgeGlow" .. i, Vector3.new(0.05, 0.055, LEN + 0.03), edge, NEON, c * CFrame.new(0, depth / 2, 0), nil, 0.45)
		seg = seg * CFrame.new(0, 0, -LEN) * R(-BEND, 0, 0)
	end
	-- kissaki: the spine runs straight on, the cutting edge sweeps down into the point
	local tipDepth, tipLen = 0.32 - 0.022 * SEGMENTS, 0.66
	local tip = seg * CFrame.new(0, 0, -tipLen / 2)
	add("BladeTip", Vector3.new(0.07, tipDepth, tipLen), STEEL, METAL, tip, WEDGE)
	local slope = math.sqrt(tipDepth ^ 2 + tipLen ^ 2)
	add("BladeEdgeGlowTip", Vector3.new(0.05, 0.05, slope), edge, NEON, tip * R(-math.atan2(tipDepth, tipLen), 0, 0), nil, 0.45)

	local fuller = add("BladeFuller", Vector3.new(0.08, 0.05, 1.7), HOT, NEON, CFrame.new(0, 0.02, -1.6), nil, 0.2)

	if blade then
		local function attach(name, y, z)
			local a = Instance.new("Attachment")
			a.Name = name
			a.Position = Vector3.new(0, y, z)
			a.Parent = blade
			return a
		end
		local function makeTrail(name, a0, a1, life, c0, c1, c2)
			local t = Instance.new("Trail")
			t.Name = name
			t.Attachment0, t.Attachment1 = a0, a1
			t.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c0), ColorSequenceKeypoint.new(0.4, c1), ColorSequenceKeypoint.new(1, c2) })
			t.LightEmission = 1
			t.Lifetime = life
			t.MinLength = 0.05
			t.FaceCamera = false
			t.Enabled = false
			t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1) })
			t.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.35) })
			t.Parent = blade
		end
		-- blade-local Z: the Blade segment is centred at grip z = -1.03, the tip is about 3.9 further along
		makeTrail("SwingTrail", attach("TrailA0", 0.08, -3.7), attach("TrailA1", 0.08, 0.1), 0.22, HOT, edge, edge:Lerp(rgb(0, 0, 0), 0.55))
		makeTrail("SwingTrailCore", attach("TrailB0", 0.14, -3.7), attach("TrailB1", 0.14, -2.0), 0.13, rgb(255, 255, 255), HOT, edge)
		if ember then attach("Tip", 0, -3.7) end
	end

	-- Flow embers / frost motes: off by default, the kit turns them on from 3 Flow stacks
	if fuller then
		local e = Instance.new("ParticleEmitter")
		e.Name = "FlowEmbers"
		e.Color = ColorSequence.new(HOT, edge)
		e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.3), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(0.45, 0.9)
		e.Speed = NumberRange.new(1.5, 4)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Acceleration = ember and Vector3.new(0, 7, 0) or Vector3.new(0, -2, 0)
		e.Drag = 1
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-90, 90)
		e.Rate = 0
		e.Enabled = false
		e.Parent = fuller
	end
	return blade
end

function V2.Twinblade(char)
	twinBlade(char, "Right Arm", rgb(255, 150, 70), rgb(255, 130, 40), "R")
	twinBlade(char, "Left Arm", rgb(110, 190, 255), rgb(70, 160, 255), "L")
end

--==============================================================================
--  V2.Disorderer  ·  GLITCHED HANDS
--
--  The staff is gone. Each arm now ends in a floating, corrupted hand.
--
--  LOOK    obsidian skeletal hands with neon needle claws · palm cut into three
--          slices that slide out of alignment · wrist ring that tears apart ·
--          floating error-core gem in a glass cage · orbiting corrupted shards ·
--          cyan + magenta "chromatic aberration" afterimage hands that LAG behind
--          the real one (they replay the pose from 55 ms / 110 ms ago).
--
--  MOTION  everything runs on stepped clocks (12 / 20 fps) so the hands look like
--          they're dropping frames · random ambient glitch bursts · a three-phase
--          strike (wind-up -> snap -> recover) that fires on Action-priority
--          animations automatically.
--
--  HOOKS   V2.DisordererFX[char].Strike(power)       -- claw rake, power 0..1+
--          V2.DisordererFX[char].Burst(power, secs)  -- one-shot corruption pulse
--          V2.DisordererFX[char].Channel(true/false) -- sustained corruption (held skills)
--          V2.DisordererFX[char].Destroy()
--
--  Needs the same helpers the old function used:
--          piece, W, rgb, METAL, NEON   (GRIP / CYL / R / rad / glow / swingTrail /
--          sparkle / tipAttachment are no longer needed)
--  Run it on the CLIENT: ~100 welds are updated 30x per second.
--==============================================================================

local RunService = game:GetService("RunService")

local GH = {
	Scale      = 1.25,  -- overall size of the hands
	Echoes     = true,  -- cyan/magenta afterimage hands (6 extra parts each)
	Shards     = 5,     -- orbiting fragments per hand
	StepRate   = 30,    -- pose updates / second
	AutoStrike = true,  -- Strike() whenever an Action-priority, non-looped animation plays
}

local PI, ANG = math.pi, CFrame.Angles
local floor, sin, cos = math.floor, math.sin, math.cos

--------------------------------------------------------------------------------
-- tiny math kit
--------------------------------------------------------------------------------
local function hash(n) -- deterministic noise, 0..1 (pure function of n -> echoes can replay the past)
	local x = sin(n * 12.9898 + 78.233) * 43758.5453
	return x - floor(x)
end
local function lerp(a, b, t) return a + (b - a) * t end
local function sat(x) return x < 0 and 0 or (x > 1 and 1 or x) end
local function easeOut(t) t = sat(t); return 1 - (1 - t) ^ 3 end
local function easeInOut(t) t = sat(t); return t * t * (3 - 2 * t) end

--------------------------------------------------------------------------------
-- hand anatomy (all in "hand space": origin = end of arm, -Z = fingers, +Y = back of hand)
--------------------------------------------------------------------------------
local HF     = CFrame.new(0, -1, 0) * ANG(-PI / 2, 0, 0) -- same frame as the standard tool grip
local FX     = { 1, 1 / 3, -1 / 3, -1 }                  -- index..pinky across the palm (+1 = thumb side)
local FLEN   = { 0.95, 1.08, 1.0, 0.8 }                  -- relative finger lengths
local SEG    = { 0.5, 0.4, 0.34 }                        -- phalanx lengths
local THK    = { 0.21, 0.185, 0.13 }                    -- phalanx thickness
local TSEG   = { 0.46, 0.4, 0.34 }
local TTHK   = { 0.24, 0.2, 0.14 }
local BEND   = { 1.25, 1.55, 0.95 }                      -- radians of bend per joint at curl = 1
local TBEND  = { 0.55, 1.05, 0.9 }
local IDLE   = { 0.62, 0.26, 0.18, 0.28, 0.42 }          -- thumb, index, middle, ring, pinky

--------------------------------------------------------------------------------
-- bone construction: piece -> W (keeps your ClassGear pipeline) -> our own Weld
--------------------------------------------------------------------------------
local function strip(part) -- remove whatever rigid joint W made so our animated Weld is the only one
	local ok, joints = pcall(function() return part:GetJoints() end)
	if ok and joints then
		for _, j in ipairs(joints) do j:Destroy() end
	end
	for _, c in ipairs(part:GetChildren()) do
		if c:IsA("JointInstance") or c:IsA("WeldConstraint") then c:Destroy() end
	end
end

-- parent: {part, rest}  (rest = limb-space CFrame of the parent part as placed)
-- lcf   : hand-space CFrame of the bone centre
-- az    : joint position along the bone's own Z (fingers pivot at their back end)
-- roll  : fixed roll around the bone's long axis (turns finger needles into diamonds)
local function makeBone(ctx, parent, lcf, size, color, mat, name, transp, az, roll)
	az, roll = az or 0, roll or 0
	local rest = ctx.H * lcf * ANG(0, 0, roll)
	local part = W(piece(ctx.char, ctx.limbName, size, color, mat, rest, nil, name, transp))
	strip(part)
	part.Massless, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false

	local weld = Instance.new("Weld")
	weld.Name = "GlitchJoint"
	weld.Part0, weld.Part1 = parent.part, part
	local J = parent.rest:Inverse() * (ctx.H * lcf) * CFrame.new(0, 0, az)
	weld.C0 = J
	weld.C1 = CFrame.new(0, 0, az) * ANG(0, 0, -roll)
	weld.Parent = part

	return { part = part, weld = weld, J = J, rest = rest, lcf = lcf, size = size, color = color, stretch = 1 }
end

--------------------------------------------------------------------------------
-- build one hand
--------------------------------------------------------------------------------
local function buildHand(char, limbName, side, delay, pal)
	local limb = char:FindFirstChild(limbName)
	if not limb then return nil end

	local S      = GH.Scale
	local tag    = side > 0 and "R" or "L"
	local tside  = -side -- thumb sits on the inner edge of the hand
	local ctx    = { char = char, limbName = limbName, H = HF }
	local top    = { part = limb, rest = CFrame.new() }
	local DARK, ASH, MAG, CYAN, PALE = pal.DARK, pal.ASH, pal.MAG, pal.CYAN, pal.PALE
	local GLASS  = Enum.Material.Glass

	local function bone(parent, lcf, size, color, mat, name, transp, az, roll)
		return makeBone(ctx, parent, lcf, size, color, mat, "GH" .. tag .. name, transp, az, roll)
	end

	local PW, PT, PL = 1.1 * S, 0.28 * S, 1.0 * S -- palm width / thickness / length
	local gap0       = 0.2 * S                    -- the hand floats slightly past the arm
	local sliceL     = PL / 3
	local flashParts = {}

	-- root: everything that lunges/floats hangs off this invisible joint at the wrist
	local root = bone(top, CFrame.new(), Vector3.new(0.2, 0.2, 0.2), DARK, METAL, "Root", 1)

	-- palm: three slices that can slide sideways, each with a neon plate on the back
	local sl, plates = {}, {}
	for j = 1, 3 do
		local z = -(gap0 + (j - 0.5) * sliceL)
		sl[j] = bone(root, CFrame.new(0, 0, z), Vector3.new(PW, PT, sliceL - 0.02 * S), DARK, METAL, "Slice" .. j, 0)
	end
	for j = 1, 3 do
		plates[j] = bone(sl[j], sl[j].lcf * CFrame.new(0, PT / 2 + 0.02 * S, 0),
			Vector3.new(PW * 0.82, 0.04 * S, sliceL * 0.78), (j % 2 == 1) and CYAN or MAG, NEON, "Plate" .. j, 0)
	end

	-- four fingers: 3 phalanges each, last one is a neon needle
	local fingers = {}
	for i = 1, 4 do
		local x      = FX[i] * tside * 0.405 * S
		local cursor = CFrame.new(x, 0, -(gap0 + PL))
		local parent = sl[3]
		fingers[i] = {}
		for k = 1, 3 do
			local len    = SEG[k] * FLEN[i] * S
			local needle = (k == 3)
			local th     = THK[k] * S
			local b = bone(parent, cursor * CFrame.new(0, 0, -len / 2),
				Vector3.new(th, needle and th or th * 0.9, len),
				needle and ((i % 2 == 0) and CYAN or MAG) or (k == 1 and ASH or DARK),
				needle and NEON or METAL, "F" .. i .. "_" .. k, 0, len / 2, needle and PI / 4 or 0)
			fingers[i][k] = b
			if needle then flashParts[#flashParts + 1] = b end
			cursor = cursor * CFrame.new(0, 0, -len)
			parent = b
		end
	end

	-- thumb
	local thumbBase = CFrame.new(tside * (PW / 2 - 0.03 * S), 0, -(gap0 + 0.3 * S)) * ANG(0, -tside * 0.66, 0)
	local thumb, cursor, parent = {}, thumbBase, sl[1]
	for k = 1, 3 do
		local len    = TSEG[k] * S
		local needle = (k == 3)
		local th     = TTHK[k] * S
		local b = bone(parent, cursor * CFrame.new(0, 0, -len / 2), Vector3.new(th, needle and th or th * 0.9, len),
			needle and PALE or (k == 1 and ASH or DARK), needle and NEON or METAL, "T" .. k, 0, len / 2, needle and PI / 4 or 0)
		thumb[k] = b
		if needle then flashParts[#flashParts + 1] = b end
		cursor = cursor * CFrame.new(0, 0, -len)
		parent = b
	end

	-- wrist ring: octagon of neon bars, stays on the arm so it can "tear" while the hand lunges
	local ringRoot = bone(top, CFrame.new(0, 0, 0.25 * S), Vector3.new(0.2, 0.2, 0.2), DARK, METAL, "RingRoot", 1)
	local ring, RR = {}, 0.92
	for n = 1, 8 do
		local a = (n - 1) * PI / 4
		ring[n] = bone(ringRoot, ringRoot.lcf * CFrame.new(cos(a) * RR, sin(a) * RR, 0) * ANG(0, 0, a + PI / 2),
			Vector3.new(0.74, 0.07, 0.11), (n % 2 == 0) and MAG or CYAN, NEON, "Ring" .. n, 0)
		ring[n].vis = true
	end

	-- error core + glass cage on the back of the hand
	local pc    = CFrame.new(0, 0.52 * S, -(gap0 + PL * 0.5))
	local core  = makeBone(ctx, sl[2], pc, Vector3.new(0.27 * S, 0.27 * S, 0.27 * S), PALE, NEON,
		side > 0 and "StaffCore" or "GlitchCoreL", 0) -- right core keeps the old name so skill code that looks it up still works
	local cage  = bone(sl[2], pc, Vector3.new(0.5 * S, 0.5 * S, 0.5 * S), CYAN, GLASS, "Cage", 0.7)
	flashParts[#flashParts + 1] = cage

	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = MAG, 9, 1.6, false
	light.Parent = core.part

	local dust = Instance.new("ParticleEmitter")
	dust.Color        = ColorSequence.new(PALE, MAG)
	dust.LightEmission = 1
	dust.Size         = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.16 * S), NumberSequenceKeypoint.new(1, 0) })
	dust.Transparency = NumberSequence.new(0.1, 1)
	dust.Lifetime     = NumberRange.new(0.35, 0.8)
	dust.Rate         = 8
	dust.Speed        = NumberRange.new(0.5, 2.5)
	dust.SpreadAngle  = Vector2.new(180, 180)
	dust.Drag         = 2
	dust.Rotation     = NumberRange.new(0, 360)
	dust.RotSpeed     = NumberRange.new(-180, 180)
	dust.Parent       = core.part

	-- corrupted shards orbiting the hand
	local shards = {}
	for n = 1, GH.Shards do
		local sz = (0.1 + 0.12 * hash(n * 3.3 + side)) * S
		local b = bone(root, CFrame.new(0, 0, -(gap0 + PL * 0.5)), Vector3.new(sz, sz, sz),
			(n % 3 == 0) and PALE or ((n % 2 == 0) and CYAN or MAG), NEON, "Shard" .. n, 0)
		b.phase = n / GH.Shards * 2 * PI
		b.orbit = (0.85 + 0.5 * hash(n * 7.1 + side)) * S
		shards[n] = b
	end

	-- swipe ribbon between index and pinky claws
	local ni, np = fingers[1][3], fingers[4][3]
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0, -ni.size.Z / 2)
	a1.Position = Vector3.new(0, 0, -np.size.Z / 2)
	a0.Parent, a1.Parent = ni.part, np.part
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color        = ColorSequence.new(MAG, CYAN)
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime     = 0.28
	trail.LightEmission = 1
	trail.FaceCamera   = true
	trail.Enabled      = false
	trail.Parent       = ni.part

	-- afterimage hands: single-bone fingers, cyan lags 55 ms, magenta lags 110 ms
	local echoes = {}
	if GH.Echoes then
		for e = 1, 2 do
			local col, tr = (e == 1) and CYAN or MAG, 0.7
			local palm = bone(root, CFrame.new(0, 0, -(gap0 + PL * 0.5)),
				Vector3.new(PW * 1.12, PT * 0.75, PL * 1.03), col, NEON, "Echo" .. e .. "Palm", tr)
			local all, fing = { palm }, {}
			for i = 1, 4 do
				local len = (SEG[1] + SEG[2] + SEG[3]) * FLEN[i] * S
				fing[i] = bone(palm, CFrame.new(FX[i] * tside * 0.405 * S, 0, -(gap0 + PL) - len / 2),
					Vector3.new(0.27 * S, 0.12 * S, len), col, NEON, "Echo" .. e .. "F" .. i, tr, len / 2)
				all[#all + 1] = fing[i]
			end
			local tl = (TSEG[1] + TSEG[2] + TSEG[3]) * S
			fing[5] = bone(palm, thumbBase * CFrame.new(0, 0, -tl / 2),
				Vector3.new(0.26 * S, 0.12 * S, tl), col, NEON, "Echo" .. e .. "T", tr, tl / 2)
			all[#all + 1] = fing[5]
			echoes[e] = { palm = palm, fing = fing, all = all, tr = tr, dir = (e == 1) and -1 or 1 }
		end
	end

	return {
		side = side, tside = tside, delay = delay, pal = pal,
		root = root, sl = sl, plates = plates, fingers = fingers, thumb = thumb,
		ringRoot = ringRoot, ring = ring, core = core, cage = cage, shards = shards,
		echoes = echoes, light = light, dust = dust, trail = trail,
		flashParts = flashParts, flash = false, trailOn = false,
	}
end

--------------------------------------------------------------------------------
-- pose: pure function of time -> that's what lets the echoes replay the past
--------------------------------------------------------------------------------
local function pose(rig, tt, events, chan)
	local side, S = rig.side, GH.Scale
	local tf   = floor(tt * 12) / 12 -- 12 fps stop-motion clock (fingers, core spin, ring)
	local step = floor(tt * 20)      -- 20 fps noise clock (glitch jitter)

	local g, k, sCurl, lunge, pitch, sSpread, hit = 0.04, 0, 0, 0, 0, 0, 0
	for _, e in ipairs(events) do
		if e.kind == "burst" then
			local u = (tt - e.t0) / e.dur
			if u >= 0 and u < 1 then g = math.max(g, e.p * (1 - u) ^ 1.5) end
		else -- strike: wind-up (22%) -> snap (12%) -> recover (66%), off-hand trails by rig.delay
			local u = (tt - e.t0 - rig.delay) / e.dur
			if u >= 0 and u < 1 then
				local P = e.p
				if u < 0.22 then
					local w = easeOut(u / 0.22)
					k, sCurl, lunge, pitch, sSpread = w, lerp(0.3, 0.95, w), -0.35 * w, 0.5 * w, 0
					g = math.max(g, 0.2 * w)
				elseif u < 0.34 then
					local w = easeOut((u - 0.22) / 0.12)
					k, sCurl, lunge, pitch, sSpread = 1, lerp(0.95, -0.2, w), lerp(-0.35, 1.5 * P, w), lerp(0.5, -0.35, w), w
					g = math.max(g, P)
				else
					local r  = (u - 0.34) / 0.66
					local e2 = easeInOut(r)
					k, sCurl, lunge, pitch, sSpread = 1 - e2, -0.2, lerp(1.5 * P, 0, e2), lerp(-0.35, 0, e2), 1
					g = math.max(g, P * (1 - r) ^ 2)
				end
				hit = 1
			end
		end
	end
	g = math.max(g, chan * 0.6)

	-- fingers: breathing + sporadic stop-motion twitch, then strike blend, then glitch scramble
	local curl, jit = {}, g * 0.55
	for i = 1, 5 do
		local c  = IDLE[i] + 0.12 * sin(tf * 2.2 + i * 0.8 + side)
		local tw = hash(i * 17.3 + floor(tf * 3) * 3.7 + side * 5)
		if tw > 0.88 then c = c + (tw - 0.88) / 0.12 * 0.8 end
		c = lerp(c, sCurl, k)
		curl[i] = lerp(c, -0.3 + 1.3 * hash(i * 31.1 + step * 7.7 + side * 13), jit)
	end
	local spread = lerp(0.15 + 0.1 * sin(tf * 1.7), sSpread, k) + g * 0.5 * (hash(step * 2.9 + side) - 0.5)

	-- palm slices slide, neon plates stretch (the "tear")
	local sx, st = {}, {}
	for j = 1, 3 do
		sx[j] = (hash(j * 5.3 + step * 3.1 + side * 7) - 0.5) * (0.03 + g * 0.6) * S
		st[j] = (g > 0.25) and (hash(j * 2.2 + step * 1.9 + side) * g * 1.4) or 0
	end

	-- wrist ring: segments get displaced / deleted by corruption
	local ringOff, ringVis = {}, {}
	for n = 1, 8 do
		local torn = hash(n * 4.1 + step * 2.3 + side * 11) < g * 0.6
		ringOff[n] = torn and (hash(n * 1.9 + step * 0.7) - 0.25) * 0.8 or 0
		ringVis[n] = hash(n * 6.3 + step * 1.1 + side) >= g * 0.3
	end
	local ringAng = tf * 1.4 * side + ((g > 0.3) and (hash(step * 1.1 + side) - 0.5) * g * 1.5 or 0)

	return {
		curl = curl, spread = spread, g = g, hit = hit, tf = tf, step = step,
		lunge = lunge, pitch = pitch,
		rise = 0.07 * sin(tt * 1.9 + side * 1.3),
		jx = (hash(step * 1.3 + side * 3) - 0.5) * g * 0.35 * S,
		jy = (hash(step * 2.1 + side * 9) - 0.5) * g * 0.25 * S,
		rz = (hash(step * 3.7 + side) - 0.5) * g * 0.35,
		sx = sx, st = st, ringOff = ringOff, ringVis = ringVis, ringAng = ringAng,
	}
end

--------------------------------------------------------------------------------
-- drivers: push a pose onto the welds
--------------------------------------------------------------------------------
local function driveCore(rig, p)
	rig.root.weld.C0 = rig.root.J * CFrame.new(p.jx, p.rise + p.jy, -p.lunge) * ANG(p.pitch, 0, p.rz)

	for j = 1, 3 do
		rig.sl[j].weld.C0 = rig.sl[j].J * CFrame.new(p.sx[j], 0, 0)
		local pl, s = rig.plates[j], 1 + p.st[j]
		if s ~= pl.stretch then
			pl.stretch = s
			pl.part.Size = Vector3.new(pl.size.X * s, pl.size.Y, pl.size.Z)
		end
	end

	for i = 1, 4 do
		local c, ch = p.curl[i + 1], rig.fingers[i]
		local yaw = -(FX[i] * rig.tside) * p.spread * 0.2
		ch[1].weld.C0 = ch[1].J * ANG(0, yaw, 0) * ANG(-c * BEND[1], 0, 0)
		ch[2].weld.C0 = ch[2].J * ANG(-c * BEND[2], 0, 0)
		ch[3].weld.C0 = ch[3].J * ANG(-c * BEND[3], 0, 0)
	end
	local c, th = p.curl[1], rig.thumb
	th[1].weld.C0 = th[1].J * ANG(0, -rig.tside * p.spread * 0.4, 0) * ANG(-c * TBEND[1], 0, 0)
	th[2].weld.C0 = th[2].J * ANG(-c * TBEND[2], 0, 0)
	th[3].weld.C0 = th[3].J * ANG(-c * TBEND[3], 0, 0)

	rig.ringRoot.weld.C0 = rig.ringRoot.J * ANG(0, 0, p.ringAng)
	for n, seg in ipairs(rig.ring) do
		seg.weld.C0 = seg.J * CFrame.new(0, -p.ringOff[n], 0) -- local -Y is radially outward
		if p.ringVis[n] ~= seg.vis then
			seg.vis = p.ringVis[n]
			seg.part.Transparency = seg.vis and 0 or 1
		end
	end

	local tf = p.tf
	rig.core.weld.C0 = rig.core.J * CFrame.new(0, 0.04 * sin(tf * 3), 0) * ANG(tf * 1.7, tf * 2.3 + p.g * 1.5, tf * 1.1)
	rig.cage.weld.C0 = rig.cage.J * ANG(-tf * 1.1, -tf * 1.6, tf * 2.2)
end

local function driveShards(rig, p)
	local S = GH.Scale
	for n, b in ipairs(rig.shards) do
		local ang = p.tf * (1.2 + n * 0.25) * ((n % 2 == 0) and 1 or -1) + b.phase
		local x = cos(ang) * b.orbit
		local y = sin(p.tf * 1.8 + b.phase) * 0.4 * S
		local z = sin(ang) * b.orbit * 0.75
		if hash(n * 9.1 + p.step * 2.3 + rig.side) < p.g * 0.7 then -- teleport glitch
			x = (hash(n * 3.3 + p.step) - 0.5) * 3 * S
			y = (hash(n * 5.7 + p.step) - 0.5) * 1.6 * S
			z = (hash(n * 8.9 + p.step) - 0.5) * 3 * S
		end
		b.weld.C0 = b.J * CFrame.new(x, y, z) * ANG(p.tf * 3 + n, p.tf * 2 + n * 2, n)
	end
end

local function driveEcho(rig, echo, p, pe)
	local S, dir = GH.Scale, echo.dir
	local split  = (0.04 + 0.45 * p.g) * S -- chromatic split widens with corruption
	local n      = hash(p.step * 1.7 + dir * 4)

	echo.palm.weld.C0 = echo.palm.J
		* CFrame.new(dir * split, (pe.rise - p.rise) + dir * split * 0.4 * n, -(pe.lunge - p.lunge))
		* ANG(pe.pitch - p.pitch, 0, 0)
	for i = 1, 4 do
		local yaw = -(FX[i] * rig.tside) * pe.spread * 0.2
		echo.fing[i].weld.C0 = echo.fing[i].J * ANG(0, yaw, 0) * ANG(-pe.curl[i + 1] * 0.95, 0, 0)
	end
	echo.fing[5].weld.C0 = echo.fing[5].J * ANG(0, -rig.tside * pe.spread * 0.4, 0) * ANG(-pe.curl[1] * 0.75, 0, 0)

	local gone = p.g > 0.3 and hash(p.step * 2.7 + dir * 9) < p.g * 0.35
	local tr   = gone and 1 or (0.78 - 0.4 * p.g)
	if tr ~= echo.tr then
		echo.tr = tr
		for _, b in ipairs(echo.all) do b.part.Transparency = tr end
	end
end

local function driveFx(rig, p)
	local pal   = rig.pal
	local flash = p.g > 0.45 and hash(p.step * 1.3 + rig.side * 3) > 0.55
	if flash ~= rig.flash then
		rig.flash = flash
		for _, b in ipairs(rig.flashParts) do b.part.Color = flash and pal.PALE or b.color end
		rig.core.part.Color = flash and pal.MAG or pal.PALE
	end
	rig.light.Color      = flash and pal.CYAN or pal.MAG
	rig.light.Brightness = 1.4 + 3.2 * p.g
	rig.light.Range      = 9 + 7 * p.g
	rig.dust.Rate        = 8 + 50 * p.g

	local on = p.hit > 0 or p.g > 0.35
	if on ~= rig.trailOn then
		rig.trailOn = on
		rig.trail.Enabled = on
	end
end

local function update(rig, ctl, now)
	local p = pose(rig, now, ctl.events, ctl.chan)
	driveCore(rig, p)
	driveShards(rig, p)
	driveFx(rig, p)
	for e, echo in ipairs(rig.echoes) do
		driveEcho(rig, echo, p, pose(rig, now - 0.055 * e, ctl.events, ctl.chan))
	end
end

--------------------------------------------------------------------------------
-- the class
--------------------------------------------------------------------------------
V2.DisordererFX = V2.DisordererFX or setmetatable({}, { __mode = "k" })

function V2.Disorderer(char)
	local pal = {
		MAG  = rgb(255, 80, 225),
		CYAN = rgb(70, 235, 255),
		DARK = rgb(22, 20, 30),
		PALE = rgb(255, 235, 255),
		ASH  = rgb(40, 35, 58),
	}

	local rigs = {}
	local right = buildHand(char, "Right Arm", 1, 0, pal)
	local left  = buildHand(char, "Left Arm", -1, 0.09, pal) -- off-hand follows 90 ms later: double rake
	if right then rigs[#rigs + 1] = right end
	if left then rigs[#rigs + 1] = left end
	if #rigs == 0 then return nil end

	local ctl, conns = { events = {}, chan = 0, target = 0 }, {}

	function ctl.Burst(power, dur, quiet)
		power = power or 1
		ctl.events[#ctl.events + 1] = { kind = "burst", t0 = os.clock(), dur = dur or 0.3, p = power }
		if not quiet then
			for _, h in ipairs(rigs) do h.dust:Emit(floor(6 + 10 * power)) end
		end
	end

	function ctl.Strike(power)
		ctl.events[#ctl.events + 1] = { kind = "strike", t0 = os.clock(), dur = 0.55, p = power or 1 }
		for _, h in ipairs(rigs) do
			task.delay(0.12 + h.delay, function()
				if h.dust.Parent then h.dust:Emit(14) end
			end)
		end
	end

	function ctl.Channel(on) ctl.target = on and 1 or 0 end

	function ctl.Destroy()
		for _, c in ipairs(conns) do c:Disconnect() end
		table.clear(conns)
		V2.DisordererFX[char] = nil
	end

	-- every Action-priority one-shot animation (attacks, skills) triggers a claw rake
	if GH.AutoStrike then
		local hum      = char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		if animator then
			local ACTION = {
				[Enum.AnimationPriority.Action]  = true, [Enum.AnimationPriority.Action2] = true,
				[Enum.AnimationPriority.Action3] = true, [Enum.AnimationPriority.Action4] = true,
			}
			conns[#conns + 1] = animator.AnimationPlayed:Connect(function(track)
				if ACTION[track.Priority] and not track.Looped then ctl.Strike(1) end
			end)
		end
	end

	-- main loop (stepped on purpose)
	local interval, acc, seen = 1 / GH.StepRate, 0, false
	local nextAmbient = os.clock() + 0.8
	local anchor = rigs[1].root.part
	conns[#conns + 1] = RunService.Heartbeat:Connect(function(dt)
		if anchor:IsDescendantOf(game) then
			seen = true
		elseif seen or anchor.Parent == nil then
			ctl.Destroy()
			return
		end

		acc = acc + dt
		if acc < interval then return end
		local elapsed = acc
		acc = 0
		local now = os.clock()

		local ev, n = ctl.events, 0 -- drop events that no echo can still be replaying
		for i = 1, #ev do
			local e = ev[i]
			if now < e.t0 + e.dur + 0.5 then n = n + 1; ev[n] = e end
		end
		for i = #ev, n + 1, -1 do ev[i] = nil end

		if now >= nextAmbient then -- ambient micro-glitches so the hands are never quite stable
			ctl.Burst(0.25 + 0.5 * math.random(), 0.1 + 0.2 * math.random(), true)
			nextAmbient = now + 1.2 + math.random() * 2.6
		end
		ctl.chan = ctl.chan + (ctl.target - ctl.chan) * math.min(1, elapsed * 8)

		for _, rig in ipairs(rigs) do update(rig, ctl, now) end
	end)

	V2.DisordererFX[char] = ctl
	return ctl
end

-- True Warrior: a greatsword and a crowned shield; the Champion adds a halo and golden pauldrons
function V2.TrueWarrior(char)
	-- Set to false to put the crossguard back on the old X axis (it was perpendicular to the blade's width).
	local GUARD_ON_BLADE_WIDTH = true

	local GOLDC, WHITEC, DARK, CROWN = rgb(255, 214, 120), rgb(245, 245, 250), rgb(40, 32, 28), rgb(255, 235, 170)
	local GOLDD = rgb(176, 128, 44) -- deep gold: gives the gold a shadow value so it reads as form, not flat colour
	local STEEL_HI, STEEL_LO = rgb(238, 241, 250), rgb(168, 176, 196) -- spine vs bevel: value contrast sells the edge
	local G = GRIP
	local ARM = "Right Arm"

	local function add(limb, size, color, material, cf, shape, name, transparency)
		return W(piece(char, limb, size, color, material, cf, shape, name, transparency))
	end

	----------------------------------------------------------------------
	-- SWORD   (blade runs along -Z from the grip; thin axis X, width axis Y)
	----------------------------------------------------------------------
	-- grip + wraps (alternate flat/diamond rings so the wrap looks faceted)
	add(ARM, Vector3.new(1.1, 0.2, 0.2), DARK, LEATHER, G * CFrame.new(0, 0, 0.1) * R(0, rad(90), 0), CYL, "BladeGrip")
	for i = 0, 4 do
		local diamond = i % 2 == 1
		add(
			ARM,
			Vector3.new(0.26, 0.26, 0.07),
			diamond and GOLDD or GOLDC,
			LEATHER,
			G * CFrame.new(0, 0, -0.3 + i * 0.22) * R(0, 0, diamond and rad(45) or 0),
			nil,
			"BladeWrap"
		)
	end
	-- ferrules
	for _, z in ipairs({ -0.5, 0.7 }) do
		add(ARM, Vector3.new(0.14, 0.32, 0.32), GOLDC, METAL, G * CFrame.new(0, 0, z) * R(0, rad(90), 0), CYL, "BladeFerrule")
	end
	-- pommel
	add(ARM, Vector3.one * 0.44, GOLDC, METAL, G * CFrame.new(0, 0, 0.84), BALL, "BladePommel")
	add(ARM, Vector3.one * 0.18, WHITEC, NEON, G * CFrame.new(0, 0, 1.05), BALL, "BladePommelGem")

	-- crossguard: core + two swept wings that curl toward the blade tip (reads at distance, unlike a flat bar)
	local GF = G * CFrame.new(0, 0, -0.82) * (GUARD_ON_BLADE_WIDTH and R(0, 0, rad(90)) or CFrame.identity)
	add(ARM, Vector3.new(0.62, 0.3, 0.5), GOLDC, METAL, GF, nil, "BladeGuard")
	for _, side in ipairs({ -1, 1 }) do
		add(ARM, Vector3.one * 0.24, WHITEC, NEON, GF * CFrame.new(0, side * 0.17, 0), BALL, "BladeGuardJewel")

		local lengths = { 0.5, 0.5, 0.42 }
		local headings = { 0, rad(28), rad(62) } -- how far each segment bends toward -Z
		local thick = { 0.2, 0.17, 0.14 }
		local depth = { 0.34, 0.3, 0.24 }
		local x, z = 0.31, 0
		for i = 1, 3 do
			local h, len = headings[i], lengths[i]
			local cx, cz = x + math.cos(h) * len / 2, z - math.sin(h) * len / 2
			add(
				ARM,
				Vector3.new(len + 0.04, thick[i], depth[i]),
				i == 2 and GOLDD or GOLDC,
				METAL,
				GF * CFrame.new(side * cx, 0, cz) * R(0, side * h, 0),
				nil,
				"BladeGuardWing"
			)
			x, z = x + math.cos(h) * len, z - math.sin(h) * len
		end
		add(ARM, Vector3.one * 0.2, WHITEC, NEON, GF * CFrame.new(side * x, 0, z), BALL, "BladeGuardJewel")
	end
	glow(
		add(ARM, Vector3.one * 0.32, WHITEC, NEON, G * CFrame.new(0, 0, -0.82) * R(rad(45), 0, rad(45)), nil, "BladeGem"),
		GOLDC,
		8,
		1.6
	)

	-- blade: spine (thick, bright) + two tapering bevel strips (thin, darker) + diamond point.
	-- Cross-section is a flattened hexagon; outline tapers from 0.72 wide at the guard to 0.28 at the point.
	local blade = add(ARM, Vector3.new(0.2, 0.26, 3.9), STEEL_HI, METAL, G * CFrame.new(0, 0, -2.85), nil, "Blade")

	local stripLen, stripZ = 4.25, -3.025
	local yBase, yTip = 0.21, -0.01 -- strip centre-line at the guard end / at the point (strip is 0.30 wide)
	local phi = math.atan((yBase - yTip) / stripLen)
	local yMid = (yBase + yTip) / 2
	for _, s in ipairs({ -1, 1 }) do
		-- rotating about X by -s*phi pulls the tip end of each strip toward the centre line
		add(
			ARM,
			Vector3.new(0.09, 0.3, stripLen),
			STEEL_LO,
			METAL,
			G * CFrame.new(0, s * yMid, stripZ) * R(-s * phi, 0, 0),
			nil,
			"BladeBevel"
		)
		-- glowing cutting edge on the outer line of each strip
		add(
			ARM,
			Vector3.new(0.1, 0.045, stripLen - 0.05),
			WHITEC,
			NEON,
			G * CFrame.new(0, s * (yMid + 0.15), stripZ) * R(-s * phi, 0, 0),
			nil,
			"BladeEdge"
		)
	end
	-- point: square rotated 45 degrees about the thin axis -> diamond tip, no wedge orientation to get wrong
	add(ARM, Vector3.new(0.09, 0.198, 0.198), STEEL_HI, METAL, G * CFrame.new(0, 0, -5.15) * R(rad(45), 0, 0), nil, "BladeTip")
	-- light vein down the spine
	add(ARM, Vector3.new(0.23, 0.07, 3.3), GOLDC, NEON, G * CFrame.new(0, 0, -2.75), nil, "BladeFuller")

	if blade then
		-- attachments sit on the spine part (centre z=-2.85, half length 1.95)
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Name, a1.Name = "TrailBase", "TrailTip"
		a0.Position, a1.Position = Vector3.new(0, 0, -1.9), Vector3.new(0, 0, 1.9)
		a0.Parent, a1.Parent = blade, blade

		-- core streak
		local t = Instance.new("Trail")
		t.Name = "SwingTrail"
		t.Attachment0, t.Attachment1 = a0, a1
		t.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITEC),
			ColorSequenceKeypoint.new(0.35, GOLDC),
			ColorSequenceKeypoint.new(1, GOLDD),
		})
		t.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.45, 0.45),
			NumberSequenceKeypoint.new(1, 1),
		})
		t.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
		t.LightEmission = 1
		t.LightInfluence = 0
		t.Lifetime = 0.22
		t.MinLength = 0 -- shorter segments = rounder curve at low fps (the polygon look comes from long segments)
		t.FaceCamera = true
		t.Enabled = false
		t.Parent = blade

		-- softer, wider, longer-lived glow behind it; follows SwingTrail.Enabled so existing code needs no change
		local glowTrail = t:Clone()
		glowTrail.Name = "SwingTrailGlow"
		glowTrail.Attachment0, glowTrail.Attachment1 = a0, a1
		glowTrail.Color = ColorSequence.new(GOLDC, GOLDD)
		glowTrail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
		glowTrail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0.35) })
		glowTrail.Lifetime = 0.36
		glowTrail.Enabled = false
		glowTrail.Parent = blade
		t:GetPropertyChangedSignal("Enabled"):Connect(function()
			glowTrail.Enabled = t.Enabled
		end)

		local tip = Instance.new("Attachment")
		tip.Name = "Tip"
		tip.Position = Vector3.new(0, 0, -2.44) -- blade point in spine-local space
		tip.Parent = blade
	end

	----------------------------------------------------------------------
	-- SHIELD  (disc faces -X on the left arm)
	----------------------------------------------------------------------
	local LA = "Left Arm"
	local S = CFrame.new(-0.7, -0.3, 0)
	add(LA, Vector3.new(0.24, 3.5, 3.5), GOLDC, METAL, S, CYL, "ShieldRim")
	add(LA, Vector3.new(0.28, 3.1, 3.1), GOLDD, METAL, S * CFrame.new(-0.02, 0, 0), CYL, "ShieldGroove")
	add(LA, Vector3.new(0.32, 2.8, 2.8), WHITEC, METAL, S * CFrame.new(-0.06, 0, 0), CYL, "ShieldFace")

	-- emblem: templar cross + two diagonal rays
	add(LA, Vector3.new(0.1, 2.4, 0.24), GOLDC, METAL, S * CFrame.new(-0.27, 0, 0), nil, "ShieldCrossV")
	add(LA, Vector3.new(0.1, 0.24, 2.0), GOLDC, METAL, S * CFrame.new(-0.27, 0.3, 0), nil, "ShieldCrossH")
	for _, a in ipairs({ rad(45), rad(-45) }) do
		add(LA, Vector3.new(0.09, 1.5, 0.12), GOLDC, METAL, S * CFrame.new(-0.26, 0, 0) * R(a, 0, 0), nil, "ShieldRay")
	end
	add(LA, Vector3.new(0.55, 0.85, 0.85), CROWN, METAL, S * CFrame.new(-0.3, 0, 0), BALL, "ShieldBoss")
	-- Aegis core: recolour / fade / pulse this from your Kit to show Aegis charges
	local core = add(LA, Vector3.one * 0.3, WHITEC, NEON, S * CFrame.new(-0.52, 0, 0), BALL, "AegisCore")
	glow(core, GOLDC, 6, 1.2)

	for i = 0, 7 do
		local a = i * math.pi / 4
		add(
			LA,
			Vector3.new(0.26, 0.2, 0.2),
			CROWN,
			METAL,
			S * CFrame.new(-0.15, math.cos(a) * 1.64, math.sin(a) * 1.64),
			BALL,
			"ShieldRivet"
		)
	end

	-- crown: five spikes fanned along the top edge, centre one tallest
	local spikes = { { 0, 0.75 }, { 22, 0.55 }, { -22, 0.55 }, { 44, 0.42 }, { -44, 0.42 } }
	for _, sp in ipairs(spikes) do
		local a, len = rad(sp[1]), sp[2]
		local r = 1.72 + len / 2 - 0.12
		add(
			LA,
			Vector3.new(0.26, len, 0.2),
			GOLDC,
			METAL,
			S * CFrame.new(-0.1, math.cos(a) * r, math.sin(a) * r) * R(a, 0, 0),
			nil,
			"ShieldCrown"
		)
	end

	----------------------------------------------------------------------
	-- CHAMPION extras
	----------------------------------------------------------------------
	if char:GetAttribute("ChampionTier") == 1 then
		add("Head", Vector3.new(0.08, 2.3, 2.3), GOLDC, NEON, CFrame.new(0, 1.7, 0) * R(0, 0, rad(90)), CYL, "ChampionHalo", 0.15)
		for _, s in ipairs({ -1, 1 }) do
			add("Torso", Vector3.new(1.65, 0.16, 1.65), GOLDD, METAL, CFrame.new(1.45 * s, 0.72, 0) * R(0, 0, rad(-14 * s)), nil, "ChampionPauldronRim")
			add("Torso", Vector3.new(1.5, 0.6, 1.5), GOLDC, METAL, CFrame.new(1.45 * s, 1.0, 0) * R(0, 0, rad(-14 * s)), nil, "ChampionPauldron")
			add("Torso", Vector3.new(0.4, 1.0, 0.3), WHITEC, NEON, CFrame.new(1.45 * s, 1.5, 0) * R(0, 0, rad(-20 * s)), nil, "ChampionPauldronSpike")
		end
		add("Torso", Vector3.new(0.4, 3.2, 0.12), WHITEC, FABRIC, CFrame.new(0, -0.7, 0.62), nil, "ChampionCape", 0.05)
		add("Torso", Vector3.new(0.44, 0.16, 0.16), GOLDC, METAL, CFrame.new(0, -2.3, 0.62), nil, "ChampionCapeTrim")
		add("Torso", Vector3.one * 0.3, GOLDC, METAL, CFrame.new(0, 0.85, 0.66), BALL, "ChampionClasp")
	end
end

function M.Build(char, id)
	local old = char:FindFirstChild("ClassGear")
	if old then
		old:Destroy()
	end
 local saved=char:FindFirstChild("ClassAvatarAccessories")
 local useAvatar=true -- class skins are gone: characters always wear their own avatar clothing
 if saved then saved:Destroy() end
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

]==]