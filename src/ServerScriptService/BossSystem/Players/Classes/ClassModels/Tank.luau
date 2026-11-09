local Shared = require(script.Parent.Shared)
local rgb, METAL, NEON, FABRIC, LEATHER, BALL, CYL, piece, glow, trail, R, rad, W, cos, swingTrail = Shared.rgb, Shared.METAL, Shared.NEON, Shared.FABRIC, Shared.LEATHER, Shared.BALL, Shared.CYL, Shared.piece, Shared.glow, Shared.trail, Shared.R, Shared.rad, Shared.W, Shared.cos, Shared.swingTrail
local V2 = {}

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

	local DETAIL = 2
	local FULL = DETAIL >= 2

	local LEATHER = Enum.Material.Leather
	local ICE, ICE_FACET = rgb(140, 200, 255), rgb(196, 228, 255)
	local BRASS_LIGHT, BRASS_DARK = rgb(228, 192, 118), rgb(124, 94, 48)
	local BLADE, BLADE_EDGE, BLADE_DARK = rgb(204, 212, 224), rgb(242, 246, 252), rgb(78, 90, 110)
	local HIDE, BLACK = rgb(74, 48, 32), Color3.new(0, 0, 0)
	local atan2, sqrt, cos, abs, ceil, max = math.atan2, math.sqrt, math.cos, math.abs, math.ceil, math.max
	local ALONG = R(0, 0, rad(90))

	local function attach(part, name, pos)
		local a = Instance.new("Attachment")
		a.Name = name
		a.Position = pos
		a.Parent = part
		return a
	end

	local function chord(make, y0, z0, y1, z1, tx, tw, pad, color, mat, x, name)
		local dy, dz = y1 - y0, z1 - z0
		local len = sqrt(dy * dy + dz * dz)
		return make(Vector3.new(tx, len + pad, tw), color, mat, x, (y0 + y1) / 2, (z0 + z1) / 2, name, nil, R(atan2(dz, dy), 0, 0))
	end

	local S = CFrame.new(-0.85, -0.35, -0.3)
	local TOP, SHOULDER, TIP, HALF = 2.6, 1.1, -1.9, 1.55
	local STEPS, RIMW = 7, 0.30
	local CY = 1.3
	local XF, FT = -0.04, 0.38
	local XR, RT = -0.115, 0.61
	local XC, CT = -0.15, 0.42
	local FIELD_A, FIELD_B = BLUE, RED

	local function halfWidth(y)
		if y >= SHOULDER then
			return HALF
		end
		local t = math.clamp((SHOULDER - y) / (SHOULDER - TIP), 0, 1)
		return HALF * (1 - t ^ 1.5)
	end
	local function shield(size, color, mat, x, y, z, name, shape, rot)
		return piece(char, "Left Arm", size, color, mat, S * CFrame.new(x, y, z) * (rot or CFrame.new()), shape, name)
	end

	local frame = shield(Vector3.new(0.3, 4.3, 2.2), DARKSTEEL, METAL, 0.05, 0.35, 0, "ShieldFrame")
	frame.Transparency = 1
	swingTrail(frame, Vector3.new(0, 2.0, 0), Vector3.new(0, -2.0, 0), rgb(140, 190, 255), rgb(255, 255, 255), 0.15)

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

	shield(Vector3.new(0.14, TOP - SHOULDER, HALF * 2), DARKSTEEL, METAL, 0.11, (TOP + SHOULDER) / 2, 0, "ShieldBack")
	for i = 1, STEPS do
		shield(Vector3.new(0.14, vy[i - 1] - vy[i], outer[i] * 2), DARKSTEEL, METAL, 0.11, (vy[i - 1] + vy[i]) / 2, 0, "ShieldBack")
	end
	if FULL then
		shield(Vector3.new(0.1, 1.9, 1.6), STEEL, METAL, 0.15, 0.35, 0, "ShieldBackPlate")
	end

	W(shield(Vector3.new(RT, RIMW, HALF * 2), BRASS, METAL, XR, TOP - RIMW / 2, 0, "ShieldRimTop"))
	for _, side in ipairs({ -1, 1 }) do
		local rimName = side < 0 and "ShieldRimL" or "ShieldRimR"
		W(shield(Vector3.new(RT, TOP - SHOULDER + 0.1, RIMW), BRASS, METAL, XR, (TOP + SHOULDER) / 2 - 0.05, side * (HALF - RIMW / 2), rimName))
		W(shield(Vector3.one * 0.46, BRASS_LIGHT, METAL, XR - 0.12, TOP - 0.17, side * (HALF - 0.17), "ShieldCorner", BALL))
		for i = 0, STEPS - 2 do
			W(chord(shield, vy[i], side * vz[i], vy[i + 1], side * vz[i + 1], RT, RIMW, 0.14, BRASS, METAL, XR, rimName))
		end
	end

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
				local ny, nz = -dz / len, dy / len
				if nz * side > 0 then
					ny, nz = -ny, -nz
				end
				chord(shield, y0 + ny * FOFF, z0 + nz * FOFF, y1 + ny * FOFF, z1 + nz * FOFF, fth, FW, 0.08, DARKSTEEL, METAL, fx, "ShieldFillet")
			end
		end
	end

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

	local ARM_UP, ARM_DOWN, ARM_SIDE = TOP - RIMW - 0.14, -0.45, 1.0
	local vMid, vLen = (ARM_UP + ARM_DOWN) / 2, ARM_UP - ARM_DOWN
	shield(Vector3.new(0.4, vLen - 0.56, 0.64), STEEL, METAL, -0.12, vMid, 0, "CrossBorderV")
	shield(Vector3.new(0.4, 0.64, (ARM_SIDE - 0.28) * 2), STEEL, METAL, -0.12, CY, 0, "CrossBorderH")
	shield(Vector3.new(CT, vLen - 0.2, 0.42), BRASS, METAL, XC, vMid, 0, "CrossV")
	shield(Vector3.new(CT, 0.42, (ARM_SIDE - 0.1) * 2), BRASS, METAL, XC, CY, 0, "CrossH")
	for _, e in ipairs({ { "y", ARM_UP, 1 }, { "y", ARM_DOWN, -1 }, { "z", ARM_SIDE, 1 }, { "z", -ARM_SIDE, -1 } }) do
		local axis, tip, sgn = e[1], e[2], e[3]
		for _, step in ipairs({ { 0.23, 0.14, 0.62 }, { 0.08, 0.16, 0.9 } }) do
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
	if FULL then
		for _, a in ipairs({ 45, -45 }) do
			shield(Vector3.new(0.12, 2.4, 0.07), ICE, NEON, -0.23, CY, 0, "ShieldInlay", nil, R(rad(a), 0, 0)).Transparency = 0.6
		end
	end

	shield(Vector3.new(0.46, 0.92, 0.92), BRASS_LIGHT, METAL, -0.17, CY, 0, "ShieldGemRing", CYL)
	shield(Vector3.new(0.5, 0.7, 0.7), DARKSTEEL, METAL, -0.18, CY, 0, "ShieldGemSocket", CYL)
	shield(Vector3.new(0.5, 0.46, 0.46), ICE_FACET, NEON, -0.205, CY, 0, "ShieldGemFacet")
	local gem = shield(Vector3.new(0.52, 0.48, 0.48), ICE, NEON, -0.225, CY, 0, "ShieldGem", nil, R(rad(45), 0, 0))
	glow(gem, ICE, 7, 1)

	for _, y in ipairs({ 0.5, -0.45 }) do
		piece(char, "Left Arm", Vector3.new(0.28, 1.3, 1.3), HIDE, LEATHER, CFrame.new(0, y, 0) * ALONG, CYL, "ShieldStrap")
		if FULL then
			piece(char, "Left Arm", Vector3.new(0.08, 0.34, 0.28), BRASS, METAL, CFrame.new(0.66, y, 0), nil, "ShieldBuckle")
		end
	end
	if FULL then
		piece(char, "Left Arm", Vector3.new(0.07, 1.5, 1.0), HIDE, LEATHER, CFrame.new(-0.61, 0.05, 0), nil, "ShieldPad")
	end

	attach(frame, "ShieldCenter", Vector3.new(-0.55, 0, 0))
	attach(frame, "ShieldGemPoint", Vector3.new(-0.55, CY - 0.35, 0))
	attach(frame, "ShieldTop", Vector3.new(-0.45, TOP - 0.35, 0))
	attach(frame, "ShieldTipPoint", Vector3.new(-0.35, TIP - 0.35, 0))
	attach(frame, "ShieldEdgeL", Vector3.new(-0.45, 1.6 - 0.35, -HALF))
	attach(frame, "ShieldEdgeR", Vector3.new(-0.45, 1.6 - 0.35, HALF))

	local G = CFrame.new(0.02, -0.8, 0) * R(rad(62), 0, 0)
	local function sword(size, color, mat, x, y, z, name, shape, rot)
		return piece(char, "Right Arm", size, color, mat, G * CFrame.new(x, y, z) * (rot or CFrame.new()), shape, name)
	end

	W(sword(Vector3.new(0.16, 0.34, 0.34), BRASS, METAL, 0, 0.7, 0, "SwordPommel", CYL, ALONG))
	W(sword(Vector3.new(0.62, 0.5, 0.62), BRASS, METAL, 0, 0.92, 0, "SwordPommel", BALL))
	sword(Vector3.new(0.07, 0.72, 0.72), BRASS_LIGHT, METAL, 0, 0.92, 0, "SwordPommelBand", CYL, ALONG)
	glow(sword(Vector3.one * 0.28, ICE, NEON, 0, 1.16, 0, "SwordGem", BALL), ICE, 5, 1)

	W(sword(Vector3.new(1.3, 0.26, 0.26), HIDE, LEATHER, 0, 0.02, 0, "SwordGrip", CYL, ALONG))
	for k, y in ipairs(FULL and { 0.5, 0.2, -0.1, -0.4 } or { 0.5, -0.4 }) do
		sword(Vector3.new(0.06, 0.32, 0.32), k % 2 == 1 and BRASS_LIGHT or BRASS_DARK, METAL, 0, y, 0, "SwordGripRing", CYL, ALONG)
	end

	local GY = -0.7
	W(sword(Vector3.new(0.2, 0.2, 0.5), BRASS, METAL, 0, GY, 0, "SwordGuard"))
	sword(Vector3.new(0.3, 0.38, 0.44), BRASS_LIGHT, METAL, 0, GY - 0.02, 0, "SwordGuardBoss")
	local Q = { { GY, 0.25 }, { GY - 0.02, 0.55 }, { GY - 0.1, 0.82 }, { GY - 0.25, 0.98 } }
	for _, side in ipairs({ -1, 1 }) do
		for k = 1, 3 do
			W(chord(sword, Q[k][1], side * Q[k][2], Q[k + 1][1], side * Q[k + 1][2], 0.2, 0.22 - k * 0.02, 0.1, BRASS, METAL, 0, "SwordQuillon"))
		end
		sword(Vector3.one * 0.3, BRASS_LIGHT, METAL, 0, Q[4][1] - 0.02, side * 1.0, "SwordFinial", BALL)
		if FULL then
			sword(Vector3.new(0.06, 0.22, 0.22), ICE, NEON, side * 0.17, GY - 0.02, 0, "SwordGuardGem", nil, R(rad(45), 0, 0))
		end
	end

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
	if FULL then
		for k = 0, 2 do
			for _, side in ipairs({ -1, 1 }) do
				sword(Vector3.new(0.13, 0.17 - k * 0.04, 0.045), ICE, NEON, 0, -1.55 - k * 0.5, side * 0.115, "SwordRune").Transparency = 0.5
			end
		end
	end

	local TIPY = B[#B][1]
	swingTrail(blade, Vector3.new(0, TIPY - bladeY, 0), Vector3.new(0, -1.5 - bladeY, 0), rgb(140, 190, 255), rgb(255, 255, 255), 0.18)
	attach(blade, "SwordTip", Vector3.new(0, TIPY - bladeY, 0))
	attach(blade, "SwordMid", Vector3.new(0, -2.6 - bladeY, 0))
	attach(blade, "SwordBase", Vector3.new(0, -1.2 - bladeY, 0))
	attach(blade, "SwordHilt", Vector3.new(0, 0 - bladeY, 0))
end

return V2.Tank
