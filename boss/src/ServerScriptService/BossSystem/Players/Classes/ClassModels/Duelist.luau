local Shared = require(script.Parent.Shared)
local rgb, METAL, NEON, FABRIC, LEATHER, BALL, CYL, piece, glow, trail, R, rad, W, GRIP, sin, cos = Shared.rgb, Shared.METAL, Shared.NEON, Shared.FABRIC, Shared.LEATHER, Shared.BALL, Shared.CYL, Shared.piece, Shared.glow, Shared.trail, Shared.R, Shared.rad, Shared.W, Shared.GRIP, Shared.sin, Shared.cos
local V2 = {}

function V2.Duelist(char)
	local NAVY, SILVER, CRIMSON, EDGE, DARK = rgb(28, 38, 70), rgb(205, 212, 226), rgb(176, 30, 44), rgb(150, 200, 255), rgb(20, 22, 30)
	local STEEL, GUNMETAL, WHITE = rgb(196, 205, 222), rgb(88, 96, 114), rgb(255, 255, 255)
	local G = GRIP

	local DETAIL = 2
	local KB = -1
	local V = Vector3.new

	local function core(size, color, mat, cf, shape, name)
		return piece(char, "Right Arm", size, color, mat, G * cf, shape, name)
	end

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

	local function bezier(p0, p1, p2, n)
		local pts = {}
		for i = 0, n do
			local t = i / n
			pts[#pts + 1] = p0 * ((1 - t) ^ 2) + p1 * (2 * (1 - t) * t) + p2 * (t * t)
		end
		return pts
	end

	local function ring(z, r, n, t, color, mat, name, props)
		local pts = {}
		for i = 0, n do
			local a = (i / n) * math.pi * 2
			pts[#pts + 1] = V(math.cos(a) * r, math.sin(a) * r, z)
		end
		chain(pts, t, color, mat, name, props)
	end

	local blade = core(V(0.07, 0.17, 4.3), STEEL, METAL, CFrame.new(0, 0, -2.75), nil, "Blade")
	core(V(0.08, 0.05, 4.1), EDGE, NEON, CFrame.new(0, 0.09, -2.7), nil, "BladeEdge")

	core(V(0.06, 0.12, 0.36), STEEL, METAL, CFrame.new(0, 0.01, -5.08), nil, "BladeTip")
	deco(V(0.04, 0.065, 0.3), STEEL, METAL, CFrame.new(0, 0.01, -5.36), nil, "BladeTip2")
	deco(Vector3.one * 0.13, WHITE, NEON, CFrame.new(0, 0.01, -5.5), BALL, "TipGlint", { Transparency = 0.3 })

	deco(V(0.1, 0.21, 0.5), GUNMETAL, METAL, CFrame.new(0, 0, -0.9), nil, "BladeRicasso")
	deco(V(0.07, 0.04, 4.0), EDGE, NEON, CFrame.new(0, -0.09, -2.75), nil, "BladeEdgeLow", { Transparency = 0.5 })
	deco(V(0.05, 0.1, 3.6), rgb(230, 240, 255), METAL, CFrame.new(0, -0.05, -2.6), nil, "BladeFuller")

	if DETAIL >= 2 then
		local ys = { 0.035, -0.03, 0.03, -0.035 }
		for i = 0, 3 do
			for _, s in ipairs({ -1, 1 }) do
				deco(V(0.012, 0.06, 0.14), EDGE, NEON, CFrame.new(0.04 * s, ys[i + 1], -1.7 - i * 0.55), nil, "BladeRune", { Transparency = 0.6 })
			end
		end
	end

	core(Vector3.one * 0.5, SILVER, METAL, CFrame.new(0, 0, -0.55), BALL, "CupHilt")
	core(V(0.06, 0.75, 0.75), SILVER, METAL, CFrame.new(0, 0, -0.6) * R(0, rad(90), 0), CYL, "GuardRing")
	if DETAIL >= 2 then
		ring(-0.6, 0.39, 12, 0.045, EDGE, NEON, "CupRim", { Transparency = 0.15 })
	end

	deco(V(0.26, 0.24, 0.24), GUNMETAL, METAL, CFrame.new(0, 0, -0.62), nil, "GuardBlock")
	deco(V(0.7, 0.1, 0.1), SILVER, METAL, CFrame.new(0, 0, -0.62), nil, "BladeQuillon")
	chain(bezier(V(0.35, 0, -0.62), V(0.62, 0, -0.62), V(0.72, 0, -0.88), 3), 0.085, SILVER, METAL, "BladeQuillonArc")
	chain(bezier(V(-0.35, 0, -0.62), V(-0.62, 0, -0.62), V(-0.72, 0, -0.36), 3), 0.085, SILVER, METAL, "BladeQuillonArc")
	deco(Vector3.one * 0.15, SILVER, METAL, CFrame.new(0.73, 0, -0.9), BALL, "QuillonFinial")
	deco(Vector3.one * 0.15, SILVER, METAL, CFrame.new(-0.73, 0, -0.34), BALL, "QuillonFinial")

	chain(bezier(V(0, 0.09 * KB, -0.62), V(0, 0.85 * KB, -0.6), V(0, 0.58 * KB, -0.08), 3), 0.07, SILVER, METAL, "BladeKnuckle")
	chain(bezier(V(0, 0.58 * KB, -0.08), V(0, 0.55 * KB, 0.4), V(0, 0.1 * KB, 0.4), 3), 0.07, SILVER, METAL, "BladeKnuckle")

	if DETAIL >= 2 then
		chain(bezier(V(-0.72, 0, -0.36), V(-0.42, 0.45 * KB, -0.2), V(-0.02, 0.55 * KB, -0.02), 3), 0.05, SILVER, METAL, "HiltArm")
		chain(bezier(V(0.72, 0, -0.88), V(0.42, 0.5 * KB, -0.6), V(0.02, 0.5 * KB, -0.3), 3), 0.05, SILVER, METAL, "HiltArm")
	end

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

	if blade then
		blade.Reflectance = 0.12

		local function att(name, z, y)
			local a = Instance.new("Attachment")
			a.Name = name
			a.Position = V(0, y or 0, z)
			a.Parent = blade
			return a
		end

		local tip = att("Tip", -2.75)
		att("Foible", -1.75)
		att("Mid", -0.4)
		att("Forte", 1.55)
		att("Hilt", 2.15)

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

		local light = Instance.new("PointLight")
		light.Name = "BladeLight"
		light.Color = EDGE
		light.Range = 9
		light.Brightness = 2
		light.Shadows = false
		light.Enabled = false
		light.Parent = blade
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

return V2.Duelist
