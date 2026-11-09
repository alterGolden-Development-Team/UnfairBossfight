local Shared = require(script.Parent.Shared)
local rgb, METAL, NEON, FABRIC, WOOD, BALL, CYL, piece, glow, trail, R, rad, W, GRIP, sin, cos, swingTrail, tipAttachment, sparkle = Shared.rgb, Shared.METAL, Shared.NEON, Shared.FABRIC, Shared.WOOD, Shared.BALL, Shared.CYL, Shared.piece, Shared.glow, Shared.trail, Shared.R, Shared.rad, Shared.W, Shared.GRIP, Shared.sin, Shared.cos, Shared.swingTrail, Shared.tipAttachment, Shared.sparkle
local V2 = {}

function V2.Mage(char)
	local V3 = Vector3.new
	local PURPLE, DEEP, PALE, GOLD, WOODC = rgb(132, 82, 220), rgb(48, 28, 86), rgb(232, 214, 255), rgb(226, 190, 96), rgb(70, 46, 32)
	local MID, INK, WINE = rgb(70, 42, 124), rgb(36, 22, 60), rgb(96, 34, 72)
	local G = GRIP
	local AXIS = R(0, rad(90), 0)
	local CORNER = R(0, rad(-54.74), 0) * R(0, 0, rad(-45))
	local UPCORNER = R(rad(-90), 0, 0) * CORNER

	local function st(name, size, color, mat, pos, rot, shape)
		return piece(char, "Right Arm", size, color, mat, G * CFrame.new(pos) * (rot or CFrame.new()), shape, name)
	end
	local function bar(on, base, name, a, b, w, color, mat, up)
		return piece(char, on, V3(w, w, (b - a).Magnitude * 1.06), color, mat, base * CFrame.lookAt((a + b) / 2, b, up or V3(0, 1, 0)), nil, name)
	end
	local function ring(base, name, r, n, w, color, mat)
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

	st("StaffShaft", V3(5.6, 0.22, 0.22), WOODC, WOOD, V3(0, 0, -1.3), AXIS, CYL)
	st("StaffGrip", V3(1.1, 0.29, 0.29), INK, FABRIC, V3(0, 0, 0), AXIS, CYL)
	for _, z in ipairs({ -0.58, 0.58 }) do
		st("StaffGripRing", V3(0.08, 0.34, 0.34), GOLD, METAL, V3(0, 0, z), AXIS, CYL)
	end

	st("StaffFoot", V3(0.3, 0.3, 0.3), GOLD, METAL, V3(0, 0, 1.45), AXIS, CYL)
	st("StaffFootRing", V3(0.08, 0.3, 0.3), GOLD, METAL, V3(0, 0, 1.15), AXIS, CYL)
	st("StaffSpike", V3(0.24, 0.24, 0.24), GOLD, METAL, V3(0, 0, 1.68), CORNER)

	st("StaffMidRing", V3(0.1, 0.32, 0.32), GOLD, METAL, V3(0, 0, -1.6), AXIS, CYL)
	for i = 0, 7 do
		local a = i * rad(80)
		st("StaffRune", V3(0.05, 0.1, 0.2), i % 2 == 0 and PALE or PURPLE, NEON,
			V3(math.cos(a) * 0.13, math.sin(a) * 0.13, -1.95 - i * 0.2), R(0, 0, a))
	end

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

	local crystal = st("StaffCrystal", V3(0.5, 0.5, 0.5), PURPLE, NEON, V3(0, 0, zc), CORNER)
	crystal.Transparency = 0.3
	st("StaffCrystalInner", V3(0.36, 0.36, 0.36), PALE, NEON, V3(0, 0, zc), R(0, 0, rad(60)) * CORNER)
	glow(st("StaffCore", V3(0.3, 0.3, 0.3), PALE, NEON, V3(0, 0, zc), nil, BALL), PURPLE, 11, 2)
	sparkle(tipAttachment(crystal), PALE, PURPLE, 10, 0)
	-- trail kept as in the original. NOTE: negative X on a CYL rotated by AXIS is the FOOT end.
	swingTrail(char:FindFirstChild("ClassGear") and char.ClassGear:FindFirstChild("StaffShaft"), V3(-1.6, 0, 0), V3(-2.8, 0, 0), PURPLE, PALE, 0.2)

	ring(G * CFrame.new(0, 0, zc) * R(rad(62), rad(28), 0), "StaffHaloA", 0.82, 12, 0.05, GOLD, METAL)
	ring(G * CFrame.new(0, 0, zc) * R(rad(-48), rad(-35), rad(20)), "StaffHaloB", 0.68, 10, 0.035, PALE, NEON)

	for i = 1, 5 do
		local a = i * 2 * math.pi / 5
		W(st("StaffShard" .. i, V3(0.13, 0.13, 0.34), i % 2 == 0 and PURPLE or PALE, NEON,
			V3(math.cos(a) * 1.05, math.sin(a) * 1.05, zc + math.sin(i * 1.9) * 0.45), R(rad(30 * i), rad(20 * i), 0)))
	end

	hed("HatBrimTrim", V3(0.06, 3.3, 3.3), GOLD, METAL, CFrame.new(0, 0.57, 0) * R(0, 0, rad(90)), CYL)
	hed("HatBrim", V3(0.14, 3.2, 3.2), DEEP, FABRIC, CFrame.new(0, 0.6, 0) * R(0, 0, rad(90)), CYL)
	local y, z = 0.9, 0
	for i = 1, 7 do
		local phi = 3 * i ^ 1.35
		local dia = 1.6 - 0.22 * (i - 1)
		hed("HatTier" .. i, V3(0.42, dia, dia), i % 2 == 0 and MID or DEEP, FABRIC, CFrame.new(0, y, z) * R(rad(phi), 0, rad(90)), CYL)
		y, z = y + 0.3 * math.cos(rad(phi)), z + 0.3 * math.sin(rad(phi))
	end
	hed("HatBand", V3(0.14, 1.68, 1.68), GOLD, METAL, CFrame.new(0, 0.77, 0) * R(0, 0, rad(90)), CYL)
	hed("HatBuckle", V3(0.5, 0.4, 0.1), GOLD, METAL, CFrame.new(0, 0.77, -0.86))
	hed("HatBuckleGem", V3(0.22, 0.22, 0.06), PALE, NEON, CFrame.new(0, 0.77, -0.92) * R(0, 0, rad(45)))
	glow(hed("HatStar", V3(0.3, 0.3, 0.3), PALE, NEON, CFrame.new(0, y + 0.05, z) * UPCORNER), PALE, 6, 1)

	tor("Coat", V3(2.06, 2.04, 1.07), PURPLE, FABRIC)
	tor("CoatSeam", V3(0.24, 2.05, 1.09), GOLD, FABRIC)

	tor("Mantle", V3(2.7, 0.3, 1.3), DEEP, FABRIC, CFrame.new(0, 0.88, 0))
	tor("MantleTrim", V3(2.74, 0.07, 1.34), GOLD, METAL, CFrame.new(0, 0.74, 0))
	tor("CollarBack", V3(1.7, 0.95, 0.1), DEEP, FABRIC, CFrame.new(0, 1.35, 0.6) * R(rad(10), 0, 0))

	for _, s in ipairs({ 1, -1 }) do
		bar("Torso", CFrame.new(), "Lapel", V3(s * 0.62, 0.9, -0.56), V3(s * 0.14, 0.15, -0.56), 0.14, DEEP, FABRIC)
		bar("Torso", CFrame.new(), "LapelTrim", V3(s * 0.62, 0.9, -0.65), V3(s * 0.14, 0.15, -0.65), 0.05, GOLD, METAL)
	end
	tor("Brooch", V3(0.34, 0.34, 0.08), GOLD, METAL, CFrame.new(0, 0.2, -0.58) * R(0, 0, rad(45)))
	tor("BroochGem", V3(0.18, 0.18, 0.06), PALE, NEON, CFrame.new(0, 0.2, -0.62) * R(0, 0, rad(45)))

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

	tor("Sash", V3(2.08, 0.28, 1.1), GOLD, FABRIC, CFrame.new(0, -0.85, 0))
	tor("Buckle", V3(0.42, 0.42, 0.08), DEEP, METAL, CFrame.new(0, -0.85, -0.58) * R(0, 0, rad(45)))
	tor("BuckleGem", V3(0.22, 0.22, 0.06), PALE, NEON, CFrame.new(0, -0.85, -0.62) * R(0, 0, rad(45)))
	tor("SashTail", V3(0.34, 1.4, 0.07), GOLD, FABRIC, CFrame.new(0.62, -1.65, -0.66) * R(0, 0, rad(4)))
	tor("SashTailGem", V3(0.2, 0.2, 0.05), PALE, NEON, CFrame.new(0.67, -2.33, -0.7) * R(0, 0, rad(45)))

	local bk = CFrame.new(-0.82, -1.05, -0.7) * R(0, 0, rad(7))
	tor("Grimoire", V3(0.52, 0.66, 0.2), WINE, FABRIC, bk)
	tor("GrimoireSpine", V3(0.08, 0.68, 0.22), GOLD, METAL, bk * CFrame.new(-0.22, 0, 0))
	tor("GrimoireGem", V3(0.2, 0.2, 0.05), PALE, NEON, bk * CFrame.new(0.04, 0.02, -0.12) * R(0, 0, rad(45)))
end

return V2.Mage
