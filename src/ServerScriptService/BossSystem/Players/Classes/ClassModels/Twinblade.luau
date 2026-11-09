local Shared = require(script.Parent.Shared)
local rgb, METAL, NEON, LEATHER, CYL, WEDGE, holder, glow, R, rad, W, GRIP = Shared.rgb, Shared.METAL, Shared.NEON, Shared.LEATHER, Shared.CYL, Shared.WEDGE, Shared.holder, Shared.glow, Shared.R, Shared.rad, Shared.W, Shared.GRIP
local V2 = {}

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

	add("BladeGrip", Vector3.new(1.0, 0.19, 0.19), DARK, LEATHER, CFrame.new(0, 0, 0.03) * R(0, rad(90), 0), CYL)
	for i = 0, 3 do
		add("BladeWrap", Vector3.new(0.2, 0.2, 0.06), WRAP, LEATHER, CFrame.new(0, 0, -0.33 + i * 0.24) * R(0, 0, rad(45)))
	end
	add("BladePommel", Vector3.new(0.12, 0.27, 0.27), TRIM, METAL, CFrame.new(0, 0, 0.57) * R(0, rad(90), 0), CYL)
	add("BladePommelGem", Vector3.one * 0.11, edge, NEON, CFrame.new(0, 0, 0.67) * R(rad(45), 0, rad(45)))

	if ember then
		add("BladeGuard", Vector3.new(0.07, 0.86, 0.86), TRIM, METAL, CFrame.new(0, 0, -0.55) * R(0, rad(90), 0), CYL)
		add("BladeGuardInner", Vector3.new(0.09, 0.58, 0.58), DARK, METAL, CFrame.new(0, 0, -0.55) * R(0, rad(90), 0), CYL)
	else
		add("BladeGuard", Vector3.new(0.66, 0.66, 0.07), TRIM, METAL, CFrame.new(0, 0, -0.55) * R(0, 0, rad(45)))
		add("BladeGuardInner", Vector3.new(0.44, 0.44, 0.09), DARK, METAL, CFrame.new(0, 0, -0.55) * R(0, 0, rad(45)))
	end
	glow(add("BladeGem", Vector3.one * 0.16, edge, NEON, CFrame.new(0, 0, -0.6) * R(rad(45), 0, rad(45))), edgeGlow, 6, 1.5)
	add("BladeCollar", Vector3.new(0.12, 0.36, 0.14), TRIM, METAL, CFrame.new(0, 0, -0.67))

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
		makeTrail("SwingTrail", attach("TrailA0", 0.08, -3.7), attach("TrailA1", 0.08, 0.1), 0.22, HOT, edge, edge:Lerp(rgb(0, 0, 0), 0.55))
		makeTrail("SwingTrailCore", attach("TrailB0", 0.14, -3.7), attach("TrailB1", 0.14, -2.0), 0.13, rgb(255, 255, 255), HOT, edge)
		if ember then attach("Tip", 0, -3.7) end
	end

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

return V2.Twinblade
