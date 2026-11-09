local Shared = require(script.Parent.Shared)
local rgb, METAL, NEON, FABRIC, WOOD, BALL, CYL, piece, glow, trail, R, rad, W, GRIP, sin, cos, swingTrail, tipAttachment, sparkle = Shared.rgb, Shared.METAL, Shared.NEON, Shared.FABRIC, Shared.WOOD, Shared.BALL, Shared.CYL, Shared.piece, Shared.glow, Shared.trail, Shared.R, Shared.rad, Shared.W, Shared.GRIP, Shared.sin, Shared.cos, Shared.swingTrail, Shared.tipAttachment, Shared.sparkle
local V2 = {}

function V2.Supporter(char)
	local V3, CF = Vector3.new, CFrame.new

	local GREEN, MINT = rgb(104, 214, 150), rgb(220, 255, 235)
	local CLOAK, SHADE = rgb(34, 92, 70), rgb(16, 36, 28)
	local IVORY, ROBE = rgb(236, 230, 210), rgb(232, 228, 214)
	local GOLD, GOLD_DK = rgb(226, 196, 110), rgb(168, 134, 66)

	local SEG = 12
	local FANCY = true

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

	local function diamond(limb, size, color, mat, cf, name)
		return piece(char, limb, size, color, mat, cf * R(0, 0, rad(45)), nil, name)
	end

	piece(char, "Head", V3(1.35, 0.28, 1.3), CLOAK, FABRIC, CF(0, 0.66, 0.05), nil, "HoodTop")
	piece(char, "Head", V3(1.35, 1.3, 0.28), CLOAK, FABRIC, CF(0, 0.1, 0.62), nil, "HoodBack")
	piece(char, "Head", V3(0.22, 1.15, 1.2), CLOAK, FABRIC, CF(-0.66, 0.08, 0.02), nil, "HoodLeft")
	piece(char, "Head", V3(0.22, 1.15, 1.2), CLOAK, FABRIC, CF(0.66, 0.08, 0.02), nil, "HoodRight")
	piece(char, "Head", V3(0.5, 0.22, 0.9), CLOAK, FABRIC, CF(0, 0.84, 0.2), nil, "HoodRidge")
	piece(char, "Head", V3(1.4, 0.12, 0.2), GOLD, FABRIC, CF(0, 0.7, -0.56), nil, "HoodTrim")
	for _, s in ipairs({ -1, 1 }) do
		piece(char, "Head", V3(0.12, 1.15, 0.2), GOLD, FABRIC, CF(0.69 * s, 0.08, -0.58), nil, "HoodTrimSide")
	end
	diamond("Head", V3(0.3, 0.3, 0.08), GOLD, METAL, CF(0, 0.66, -0.66), "HoodGemSetting")
	diamond("Head", V3(0.18, 0.18, 0.1), GREEN, NEON, CF(0, 0.66, -0.71), "HoodGem")
	local halo = ring("Head", CF(0, 1.32, 0.08) * R(rad(96), 0, 0), 0.7, SEG + 2, 0.07, GOLD, NEON, "Halo")
	glow(halo, GOLD, 8, 1)
	sparkle(tipAttachment(halo), rgb(255, 244, 200), GOLD, 4, 1.5)

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

	diamond("Torso", V3(0.5, 0.5, 0.04), GOLD, METAL, CF(0, 0.1, -0.57), "ChestSigil")
	piece(char, "Torso", V3(0.3, 0.09, 0.05), GREEN, NEON, CF(0, 0.1, -0.6), nil, "ChestPlusH")
	piece(char, "Torso", V3(0.09, 0.3, 0.05), GREEN, NEON, CF(0, 0.1, -0.6), nil, "ChestPlusV")

	piece(char, "Torso", V3(2.1, 0.18, 1.12), SHADE, FABRIC, CF(0, -0.78, 0), nil, "Belt")
	diamond("Torso", V3(0.34, 0.34, 0.08), GOLD, METAL, CF(0, -0.78, -0.58), "BeltBuckle")
	diamond("Torso", V3(0.15, 0.15, 0.1), GREEN, NEON, CF(0, -0.78, -0.62), "BeltGem")

	local hinge = CF(0, 0.95, 0.6) * R(rad(-6), 0, 0)
	for _, c in ipairs({ { 0, 1.1, 3.7, 0, "" }, { -0.9, 0.7, 3.2, -2, "Side" }, { 0.9, 0.7, 3.2, 2, "Side" } }) do
		local x, w, h, flare, tag = c[1], c[2], c[3], c[4], c[5]
		local base = hinge * CF(x, 0, 0) * R(0, 0, rad(flare))
		piece(char, "Torso", V3(w, h, 0.14), CLOAK, FABRIC, base * CF(0, -h / 2, 0), nil, "Cape" .. tag)
		piece(char, "Torso", V3(w + 0.02, 0.14, 0.18), GOLD, FABRIC, base * CF(0, -h + 0.07, 0.02), nil, "CapeHem" .. tag)
	end

	if FANCY then
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

	for _, side in ipairs({ "Left", "Right" }) do
		local arm = side .. " Arm"
		piece(char, arm, V3(1.1, 1.4, 1.1), ROBE, FABRIC, CF(0, 0.3, 0), nil, "Sleeve" .. side)
		piece(char, arm, V3(1.26, 0.2, 1.26), CLOAK, FABRIC, CF(0, -0.45, 0), nil, "Cuff" .. side)
		piece(char, arm, V3(1.28, 0.06, 1.28), GOLD, METAL, CF(0, -0.58, 0), nil, "CuffTrim" .. side)
	end

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

	local G = GRIP
	local function gp(size, color, mat, cf, shape, name)
		return piece(char, "Right Arm", size, color, mat, G * cf, shape, name)
	end
	local axis = R(0, rad(90), 0)

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
		for i = 0, 9 do
			local a = i * 1.1
			gp(Vector3.one * (i % 2 == 0 and 0.1 or 0.07), GREEN, NEON,
				CF(math.cos(a) * 0.13, math.sin(a) * 0.13, -0.8 - i * 0.25), BALL, "StaffVine" .. i)
		end
	end

	for i = 0, 3 do
		gp(V3(0.07, 0.07, 0.8), GOLD, METAL,
			R(0, 0, rad(90 * i)) * CF(0.27, 0, -4.25) * R(0, rad(10), 0), nil, "StaffProng" .. i)
	end

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

	for i = 0, 2 do
		W(gp(V3(0.1, 0.1, 0.26), MINT, NEON,
			c * R(0, 0, rad(90 + 120 * i)) * CF(0.4, 0, (i - 1) * 0.22) * R(rad(25), 0, rad(45)), nil, "StaffShard" .. i))
	end

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

	gp(V3(0.04, 0.3, 0.04), GOLD, METAL, CF(0, -0.17, -3.2), nil, "StaffChain")
	W(gp(Vector3.one * 0.26, GREEN, NEON, CF(0, -0.35, -3.2), BALL, "StaffCharm"))
	for i, s in ipairs({ -1, 1 }) do
		W(gp(V3(0.07, 0.75, 0.03), IVORY, FABRIC, CF(0.08 * s, -0.86, -3.2), nil, "StaffRibbon" .. i))
	end

	swingTrail(char:FindFirstChild("ClassGear") and char.ClassGear:FindFirstChild("StaffShaft"),
		V3(1.4, 0, 0), V3(2.9, 0, 0), GREEN, rgb(230, 255, 240), 0.2)
	glow(crystal, GREEN, 12, 2)
	sparkle(tipAttachment(crystal), MINT, GREEN, 8, 2)
end

return V2.Supporter
