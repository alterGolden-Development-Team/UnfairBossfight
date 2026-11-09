local Shared = require(script.Parent.Shared)
local rgb, METAL, NEON, FABRIC, LEATHER, BALL, CYL, piece, glow, R, rad, W, GRIP, sin, cos = Shared.rgb, Shared.METAL, Shared.NEON, Shared.FABRIC, Shared.LEATHER, Shared.BALL, Shared.CYL, Shared.piece, Shared.glow, Shared.R, Shared.rad, Shared.W, Shared.GRIP, Shared.sin, Shared.cos
local V2 = {}

function V2.TrueWarrior(char)
	local GUARD_ON_BLADE_WIDTH = true

	local GOLDC, WHITEC, DARK, CROWN = rgb(255, 214, 120), rgb(245, 245, 250), rgb(40, 32, 28), rgb(255, 235, 170)
	local GOLDD = rgb(176, 128, 44)
	local STEEL_HI, STEEL_LO = rgb(238, 241, 250), rgb(168, 176, 196)
	local G = GRIP
	local ARM = "Right Arm"

	local function add(limb, size, color, material, cf, shape, name, transparency)
		return W(piece(char, limb, size, color, material, cf, shape, name, transparency))
	end

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
	for _, z in ipairs({ -0.5, 0.7 }) do
		add(ARM, Vector3.new(0.14, 0.32, 0.32), GOLDC, METAL, G * CFrame.new(0, 0, z) * R(0, rad(90), 0), CYL, "BladeFerrule")
	end
	add(ARM, Vector3.one * 0.44, GOLDC, METAL, G * CFrame.new(0, 0, 0.84), BALL, "BladePommel")
	add(ARM, Vector3.one * 0.18, WHITEC, NEON, G * CFrame.new(0, 0, 1.05), BALL, "BladePommelGem")

	local GF = G * CFrame.new(0, 0, -0.82) * (GUARD_ON_BLADE_WIDTH and R(0, 0, rad(90)) or CFrame.identity)
	add(ARM, Vector3.new(0.62, 0.3, 0.5), GOLDC, METAL, GF, nil, "BladeGuard")
	for _, side in ipairs({ -1, 1 }) do
		add(ARM, Vector3.one * 0.24, WHITEC, NEON, GF * CFrame.new(0, side * 0.17, 0), BALL, "BladeGuardJewel")

		local lengths = { 0.5, 0.5, 0.42 }
		local headings = { 0, rad(28), rad(62) }
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

	local blade = add(ARM, Vector3.new(0.2, 0.26, 3.9), STEEL_HI, METAL, G * CFrame.new(0, 0, -2.85), nil, "Blade")

	local stripLen, stripZ = 4.25, -3.025
	local yBase, yTip = 0.21, -0.01
	local phi = math.atan((yBase - yTip) / stripLen)
	local yMid = (yBase + yTip) / 2
	for _, s in ipairs({ -1, 1 }) do
		add(
			ARM,
			Vector3.new(0.09, 0.3, stripLen),
			STEEL_LO,
			METAL,
			G * CFrame.new(0, s * yMid, stripZ) * R(-s * phi, 0, 0),
			nil,
			"BladeBevel"
		)
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
	add(ARM, Vector3.new(0.09, 0.198, 0.198), STEEL_HI, METAL, G * CFrame.new(0, 0, -5.15) * R(rad(45), 0, 0), nil, "BladeTip")
	add(ARM, Vector3.new(0.23, 0.07, 3.3), GOLDC, NEON, G * CFrame.new(0, 0, -2.75), nil, "BladeFuller")

	if blade then
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Name, a1.Name = "TrailBase", "TrailTip"
		a0.Position, a1.Position = Vector3.new(0, 0, -1.9), Vector3.new(0, 0, 1.9)
		a0.Parent, a1.Parent = blade, blade

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
		t.MinLength = 0
		t.FaceCamera = true
		t.Enabled = false
		t.Parent = blade

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
		tip.Position = Vector3.new(0, 0, -2.44)
		tip.Parent = blade
	end

	local LA = "Left Arm"
	local S = CFrame.new(-0.7, -0.3, 0)
	add(LA, Vector3.new(0.24, 3.5, 3.5), GOLDC, METAL, S, CYL, "ShieldRim")
	add(LA, Vector3.new(0.28, 3.1, 3.1), GOLDD, METAL, S * CFrame.new(-0.02, 0, 0), CYL, "ShieldGroove")
	add(LA, Vector3.new(0.32, 2.8, 2.8), WHITEC, METAL, S * CFrame.new(-0.06, 0, 0), CYL, "ShieldFace")

	add(LA, Vector3.new(0.1, 2.4, 0.24), GOLDC, METAL, S * CFrame.new(-0.27, 0, 0), nil, "ShieldCrossV")
	add(LA, Vector3.new(0.1, 0.24, 2.0), GOLDC, METAL, S * CFrame.new(-0.27, 0.3, 0), nil, "ShieldCrossH")
	for _, a in ipairs({ rad(45), rad(-45) }) do
		add(LA, Vector3.new(0.09, 1.5, 0.12), GOLDC, METAL, S * CFrame.new(-0.26, 0, 0) * R(a, 0, 0), nil, "ShieldRay")
	end
	add(LA, Vector3.new(0.55, 0.85, 0.85), CROWN, METAL, S * CFrame.new(-0.3, 0, 0), BALL, "ShieldBoss")
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

return V2.TrueWarrior
