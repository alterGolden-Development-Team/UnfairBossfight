local Shared = require(script.Parent.Shared)
local rgb, METAL, FABRIC, LEATHER, holder, piece, R, rad, sin, cos = Shared.rgb, Shared.METAL, Shared.FABRIC, Shared.LEATHER, Shared.holder, Shared.piece, Shared.R, Shared.rad, Shared.sin, Shared.cos
local V2 = {}

do
	local PI = math.pi
	local STEEL, CRIMSON, GOLD, DARK = Color3.fromRGB(205, 210, 220), Color3.fromRGB(196, 40, 40), Color3.fromRGB(228, 182, 72), Color3.fromRGB(58, 34, 22)
	local STEEL_HI, STEEL_LO = Color3.fromRGB(240, 244, 250), Color3.fromRGB(150, 155, 168)
	local CRIMSON_DEEP, GOLD_DEEP = Color3.fromRGB(128, 22, 26), Color3.fromRGB(176, 132, 46)

	local BLADE_BASE, BLADE_LEN, TIP_LEN, TIP_STEPS = 0.72, 2.5, 0.75, 5
	local GUARD_Y = 0.64

	local SWORD_ANGLE = math.rad(55)
	local swordY = Vector3.new(0, -math.cos(SWORD_ANGLE), -math.sin(SWORD_ANGLE))
	local swordZ = Vector3.new(1, 0, 0)
	local swordX = swordY:Cross(swordZ)
	local SWORD_GRIP_C0 = CFrame.fromMatrix(Vector3.new(0, -0.85, -0.15), swordX, swordY, swordZ)

	local SHIELD_GRIP_C0 = CFrame.new(0, -0.85, 0) * CFrame.Angles(0, PI, 0)
	local SHIELD_OFFSET = CFrame.new(0.62, 0.5, 0)

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

	local function buildSword(arm, container)
		local handleInFrame = ROT_Y

		local handle = newPart("SwordHandle", Vector3.new(1.04, 0.23, 0.23), DARK, Enum.Material.Leather, Enum.PartType.Cylinder)
		local grip = Instance.new("Weld")
		grip.Name = "WarriorSwordGrip"
		grip.Part0, grip.Part1 = arm, handle
		grip.C0, grip.C1 = SWORD_GRIP_C0, handleInFrame:Inverse()
		handle.CFrame = arm.CFrame * grip.C0 * grip.C1:Inverse()
		grip.Parent = handle
		handle.Parent = container

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

		for i = 1, 3 do
			cylY("SwordGripWrap" .. i, 0.07, 0.275, (i - 2) * 0.27, CRIMSON, Enum.Material.Fabric)
		end
		cylY("SwordCollarLow", 0.1, 0.32, -0.54, GOLD, Enum.Material.Metal)
		cylY("SwordCollarHigh", 0.1, 0.32, 0.54, GOLD, Enum.Material.Metal)

		cylY("SwordPommelCap", 0.1, 0.5, -0.65, GOLD_DEEP, Enum.Material.Metal)
		ball("SwordPommel", 0.42, Vector3.new(0, -0.86, 0), GOLD, Enum.Material.Metal)
		ball("SwordPommelGem", 0.2, Vector3.new(0, -1.02, 0), CRIMSON, Enum.Material.Neon)

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

		local bladeY = BLADE_BASE + BLADE_LEN / 2
		local blade = add("SwordBlade", Vector3.new(0.46, BLADE_LEN, 0.085), CFrame.new(0, bladeY, 0), STEEL, Enum.Material.Metal)
		blade.Reflectance = 0.18
		for _, s in ipairs({ 1, -1 }) do
			add("SwordEdge", Vector3.new(0.05, BLADE_LEN, 0.1), CFrame.new(s * 0.205, bladeY, 0), STEEL_HI, Enum.Material.Metal)
		end
		add("SwordFuller", Vector3.new(0.12, BLADE_LEN - 0.55, 0.095), CFrame.new(0, bladeY - 0.12, 0), STEEL_LO, Enum.Material.Metal)
		local glowLine = add("SwordFullerGlow", Vector3.new(0.035, BLADE_LEN - 0.85, 0.105), CFrame.new(0, bladeY - 0.12, 0), CRIMSON, Enum.Material.Neon)

		local tipBase = BLADE_BASE + BLADE_LEN
		local h = TIP_LEN / TIP_STEPS
		for i = 0, TIP_STEPS - 1 do
			local w = 0.46 * (1 - (i + 0.5) / TIP_STEPS)
			local th = 0.085 - 0.03 * (i / TIP_STEPS)
			add(i == 0 and "SwordBladeTip" or ("SwordBladeTip" .. (i + 1)), Vector3.new(math.max(w, 0.04), h + 0.004, th), CFrame.new(0, tipBase + (i + 0.5) * h, 0), STEEL, Enum.Material.Metal)
		end

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

	function V2.Warrior(char)
		local rightArm, leftArm = char:FindFirstChild("Right Arm"), char:FindFirstChild("Left Arm")
		if not (rightArm and leftArm) then
			warn("V2.Warrior: expected an R6 rig (Right Arm / Left Arm)")
			return
		end
		local container = holder(char)

		buildSword(rightArm, container)
		buildShield(leftArm, container)

		local STEEL_A, GOLD_A, CRIMSON_A, DARK_A = rgb(205, 210, 220), rgb(228, 182, 72), rgb(196, 40, 40), rgb(58, 34, 22)
		piece(char, "Torso", Vector3.new(1.4, 0.55, 1.35), STEEL_A, METAL, CFrame.new(1.42, 0.92, 0) * R(0, 0, rad(-14)), nil, "PauldronR")
		piece(char, "Torso", Vector3.new(1.45, 0.14, 1.4), GOLD_A, METAL, CFrame.new(1.42, 1.18, 0) * R(0, 0, rad(-14)), nil, "PauldronTrim")
		piece(char, "Torso", Vector3.new(2.06, 0.32, 1.06), DARK_A, LEATHER, CFrame.new(0, -0.82, 0), nil, "Belt")
		piece(char, "Torso", Vector3.new(0.42, 0.38, 0.14), GOLD_A, METAL, CFrame.new(0, -0.82, -0.55), nil, "Buckle")
		piece(char, "Torso", Vector3.new(0.4, 1.9, 0.06), CRIMSON_A, FABRIC, CFrame.new(0, -0.05, -0.53), nil, "Sash")

		char:SetAttribute("WarriorClass", true)
	end
end

return V2.Warrior
