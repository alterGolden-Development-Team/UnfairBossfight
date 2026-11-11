 
 
 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local Golden = require(BossSystem.Attacks.Shared.P4GoldenFX)
local FX = Golden.FX
local S = require(script.Parent.Style)
local V = {}

local UP = Vector3.yAxis
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local rng = Random.new()
local function flatUnit()
	local a = rng:NextNumber(0, math.pi * 2)
	return Vector3.new(math.cos(a), 0, math.sin(a))
end
local function easeOutBack(t)
	local c = 1.70158
	return 1 + (c + 1) * (t - 1) ^ 3 + c * (t - 1) ^ 2
end
local function newBeam(parent, a0, a1, color, alpha, w0, w1)
	local b = Instance.new("Beam")
	b.Attachment0, b.Attachment1 = a0, a1
	b.FaceCamera, b.Segments = true, 1
	b.Color = typeof(color) == "ColorSequence" and color or ColorSequence.new(color)
	b.Transparency = typeof(alpha) == "NumberSequence" and alpha or NumberSequence.new(alpha or 0)
	b.LightEmission, b.LightInfluence, b.Brightness = 1, 0, 3
	b.Width0, b.Width1 = w0, w1 or w0
	b.Parent = parent
	return b
end
local function point(parent, position)
	local a = Instance.new("Attachment")
	a.Position = position
	a.Parent = parent
	return a
end
local function trail(part, half, color, lifetime, width)
	local a0 = point(part, Vector3.new(half, 0, 0))
	local a1 = point(part, Vector3.new(-half, 0, 0))
	local t = Instance.new("Trail")
	t.Attachment0, t.Attachment1 = a0, a1
	t.Color = FX.Grad(S.White, color, S.Gold)
	t.Transparency = FX.Seq(0, 0.4, 1)
	t.WidthScale = FX.Seq(1, 0.2)
	t.Lifetime = lifetime
	t.LightEmission, t.LightInfluence = 1, 0
	t.FaceCamera = true
	t.MinLength = 0.05
	t.Parent = part
	if width then t.WidthScale = FX.Seq(width, 0) end
	return t
end

 
 
 
 
local function spike(ctx, cast, name, rot, length, width, thickness, color, alpha, sides)
	local list = {}
	for k = 0, (sides or 4) - 1 do
		local p = FX.Temp(ctx, cast, name, CFrame.new(), Vector3.new(thickness, width / 2, length), color, alpha)
		p.Shape = Enum.PartType.Wedge
		local turn = rot * CFrame.Angles(0, 0, k * math.pi / ((sides or 4) == 2 and 1 or 2))
		table.insert(list, { Part = p, Rot = turn.Rotation, Offset = (turn * CFrame.new(0, width / 4, -length / 2)).Position,
			Size = Vector3.new(thickness, width / 2, length) })
	end
	return list
end
local function aimAt(dir)
	local up = math.abs(dir.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis
	return CFrame.lookAt(Vector3.zero, dir, up)
end

 
 
 
 
 
 
local POINTS = {
	 
	{ Vector3.new(1, 0, 0), 30, 5.2, true }, { Vector3.new(-1, 0, 0), 30, 5.2, true },
	{ Vector3.new(0, 0, 1), 30, 5.2, true }, { Vector3.new(0, 0, -1), 30, 5.2, true },
	{ Vector3.new(1, 0, 1).Unit, 15, 3.6, false }, { Vector3.new(-1, 0, 1).Unit, 15, 3.6, false },
	{ Vector3.new(1, 0, -1).Unit, 15, 3.6, false }, { Vector3.new(-1, 0, -1).Unit, 15, 3.6, false },
	{ Vector3.new(0, -1, 0), 24, 4.4, true }, { Vector3.new(0, 1, 0), 18, 4, true },
}
function V.Star(ctx, cast, position, form)
	local core = FX.Temp(ctx, cast, "HeavenStarCore", CFrame.new(position), Vector3.one, S.White, 0)
	core.Shape = Enum.PartType.Ball
	local glow = FX.Temp(ctx, cast, "HeavenStarGlow", CFrame.new(position), Vector3.one, S.Gold, 0.45)
	glow.Shape = Enum.PartType.Ball
	local corona = FX.Temp(ctx, cast, "HeavenStarCorona", CFrame.new(position), Vector3.one, S.Yellow, 0.84)
	corona.Shape = Enum.PartType.Ball
	local pieces = {}
	for _, def in ipairs(POINTS) do
		local rot = aimAt(def[1])
		for _, w in ipairs(spike(ctx, cast, "HeavenStarPoint", rot, def[2], def[3], 0.5, S.Gold, 0.05)) do table.insert(pieces, w) end
		if def[4] then
			for _, w in ipairs(spike(ctx, cast, "HeavenStarBlade", rot, def[2] * 1.12, def[3] * 0.38, 0.6, S.White, 0, 2)) do table.insert(pieces, w) end
		end
	end
	 
	local motes = {}
	for i = 1, 6 do
		local m = FX.Temp(ctx, cast, "HeavenStarMote", CFrame.new(position), Vector3.one * 1.1, S.White, 0)
		m.Shape = Enum.PartType.Ball
		local a0 = point(m, Vector3.new(0, 0.5, 0))
		local a1 = point(m, Vector3.new(0, -0.5, 0))
		local t = Instance.new("Trail")
		t.Attachment0, t.Attachment1 = a0, a1
		t.Color, t.Transparency = FX.Grad(S.White, S.Yellow, S.Gold), FX.Seq(0, 0.5, 1)
		t.Lifetime, t.LightEmission, t.LightInfluence, t.FaceCamera, t.WidthScale = 0.45, 1, 0, true, FX.Seq(1, 0)
		t.Parent = m
		motes[i] = { Part = m, Tilt = CFrame.Angles(rng:NextNumber(-1.2, 1.2), rng:NextNumber(0, 6.28), rng:NextNumber(-1.2, 1.2)),
			Radius = rng:NextNumber(22, 34), Speed = rng:NextNumber(1.6, 2.6) * (i % 2 == 0 and -1 or 1), Phase = rng:NextNumber(0, 6.28) }
	end
	local ringA, setA = Golden.BeamRing(ctx, cast, "HeavenStarHaloA", position, 1, S.Yellow, 0.6, 48)
	local ringB, setB = Golden.BeamRing(ctx, cast, "HeavenStarHaloB", position, 1, S.Bright, 0.6, 48)
	 
	local flare = Instance.new("BillboardGui")
	flare.Name, flare.LightInfluence, flare.Brightness, flare.AlwaysOnTop, flare.MaxDistance = "HeavenStarFlare", 0, 3, false, 2000
	flare.Size = UDim2.fromScale(1, 1)
	flare.Parent = core
	local cross = Instance.new("ImageLabel")
	cross.BackgroundTransparency, cross.Image, cross.ImageColor3, cross.ImageTransparency = 1, SPARK, S.Bright, 0.15
	cross.AnchorPoint, cross.Position, cross.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1)
	cross.Parent = flare
	local streak = Instance.new("Frame")
	streak.BorderSizePixel, streak.BackgroundColor3 = 0, S.Bright
	streak.AnchorPoint, streak.Position, streak.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(2.6, 0.022)
	streak.Parent = flare
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
	fade.Parent = streak
	local twinkle = FX.Emitter(core, {
		Color = FX.Grad(S.White, S.Yellow), Size = FX.Seq(0, 2.6, 0), Transparency = FX.Seq(0.1, 0.2, 1),
		Lifetime = NumberRange.new(0.6, 1.4), Speed = NumberRange.new(8, 30), SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-180, 180), Rate = 0,
	})
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = S.Yellow, 0, 140, false
	light.Parent = core

	local parts, frames = {}, {}
	for i, w in ipairs(pieces) do parts[i] = w.Part end
	local born = cast:Now()
	local spin, boost, alive, scaleOverride, lastScale = 0, 0, true, nil, -1
	local lastNow = born
	cast:Step(function(_, now)
		if not core.Parent or not alive then return false end
		local dt = now - lastNow
		lastNow = now
		local t = math.clamp((now - born) / form, 0, 1)
		local scale = scaleOverride or (t < 1 and math.max(0, easeOutBack(t)) or 1)
		boost *= math.exp(-dt * 4)
		spin += dt * (0.35 + boost * 2.5)
		local s = scale * (1 + 0.35 * boost)
		local breathe = 1 + 0.035 * math.sin(now * 5)
		local base = CFrame.new(position) * CFrame.Angles(0.32, spin, 0.18)
		 
		local sizeNow = s * breathe
		local resize = math.abs(sizeNow - lastScale) > 0.004
		if resize then lastScale = sizeNow end
		for i, w in ipairs(pieces) do
			frames[i] = base * CFrame.new(w.Offset * sizeNow) * w.Rot
			if resize then w.Part.Size = w.Size * math.max(sizeNow, 0.01) end
		end
		workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
		core.Size = Vector3.one * 7 * sizeNow
		glow.Size = Vector3.one * 14 * sizeNow
		corona.Size = Vector3.one * 30 * sizeNow
		for i, m in ipairs(motes) do
			local a = m.Phase + now * m.Speed
			m.Part.Position = position + (m.Tilt * CFrame.new(math.cos(a) * m.Radius * s, 0, math.sin(a) * m.Radius * s)).Position
			m.Part.Transparency = s < 0.2 and 1 or 0
		end
		ringA.CFrame = CFrame.new(position) * CFrame.Angles(0.55, -spin * 1.3, 0.25)
		ringB.CFrame = CFrame.new(position) * CFrame.Angles(-0.4, spin * 1.7, -0.35)
		setA(math.max(0.5, 19 * s), 0.25 + 0.2 * math.sin(now * 4), 0.75 * math.max(s, 0.1))
		setB(math.max(0.5, 24 * s), 0.45 + 0.2 * math.sin(now * 3 + 1), 0.45 * math.max(s, 0.1))
		local flareSize = 64 * s * (1 + boost)
		flare.Size = UDim2.fromScale(flareSize, flareSize)
		cross.Rotation = spin * 25
		streak.BackgroundTransparency = 0.35 - 0.3 * math.min(boost, 1)
		light.Brightness = 6 * s * (1 + boost)
		twinkle.Rate = 34 * s
		return true
	end)
	local handle = { Position = position }
	function handle.Pulse(strength) boost = math.max(boost, strength or 0.3) end
	 
	function handle.Flare()
		boost = 1.6
		FX.Flash(ctx, cast, position, S.White, 80, 0.5, 0)
		FX.Flash(ctx, cast, position, S.Gold, 140, 0.9, 0.3)
		FX.Ring(ctx, cast, CFrame.new(position) * CFrame.Angles(math.pi / 2, 0, 0), 6, 170, 0.9, S.Bright, 0, 2.4, 1)
		FX.Ring(ctx, cast, CFrame.new(position) * CFrame.Angles(0.3, 0, 0.2), 4, 120, 0.7, S.Gold, 0, 1.8, 1)
		FX.Ring(ctx, cast, CFrame.new(position) * CFrame.Angles(-0.4, 0.6, 0), 4, 90, 0.55, S.White, 0, 1.2, 1)
		FX.Streaks(ctx, cast, position, nil, S.Gold, S.White, 70, 180, 80, 170, 5)
		FX.Light(ctx, cast, position, S.White, 14, 260, 1)
		twinkle:Emit(80)
	end
	 
	function handle.Collapse(duration)
		local start = cast:Now()
		cast:Step(function(_, now)
			if not core.Parent then return false end
			local t = math.clamp((now - start) / duration, 0, 1)
			scaleOverride = (1 - t) ^ 2 * (1 + 0.3 * math.sin(t * 30))
			return t < 1
		end)
		cast:Schedule(duration, function()
			alive = false
			FX.Flash(ctx, cast, position, S.White, 70, 0.4, 0)
			FX.Ring(ctx, cast, CFrame.new(position) * CFrame.Angles(math.pi / 2, 0, 0), 4, 180, 1, S.Gold, 0, 2.8, 1)
			FX.Sparks(ctx, cast, position, S.Gold, S.White, 110, 20, 80, 1.3)
			FX.Light(ctx, cast, position, S.Yellow, 10, 220, 0.6)
			for _, p in ipairs({ core, glow, corona }) do FX.Release(cast, p) end
			for _, p in ipairs(parts) do FX.Release(cast, p) end
			for _, m in ipairs(motes) do FX.Release(cast, m.Part) end
			FX.Release(cast, ringA)
			FX.Release(cast, ringB)
		end)
	end
	return handle
end

 
 
 
function V.Bow(ctx, cast, actor, root)
	local hand = actor:FindFirstChild("LeftHand") or actor:FindFirstChild("Left Arm") or root
	local anchor = FX.Temp(ctx, cast, "HeavenBow", hand.CFrame, Vector3.one * 0.2, S.Gold, 1)
	local L = 4.6
	local rest = {
		Grip = Vector3.new(0, 0, 0),
		UpperMid = Vector3.new(0, L * 0.55, 0.85), Top = Vector3.new(0, L, -0.35),
		LowerMid = Vector3.new(0, -L * 0.55, 0.85), Bottom = Vector3.new(0, -L, -0.35),
		Nock = Vector3.new(0, 0, -0.35),
	}
	local pts = {}
	for name in pairs(rest) do pts[name] = point(anchor, Vector3.zero) end
	local beams = {}
	local function limb(a, b, w0, w1)
		table.insert(beams, { newBeam(anchor, pts[a], pts[b], S.Gold, 0.55, w0 * 3, w1 * 3), w0 * 3, w1 * 3 })
		table.insert(beams, { newBeam(anchor, pts[a], pts[b], FX.Grad(S.White, S.Bright), 0, w0, w1), w0, w1 })
	end
	limb("Grip", "UpperMid", 0.42, 0.3) limb("UpperMid", "Top", 0.3, 0.12)
	limb("Grip", "LowerMid", 0.42, 0.3) limb("LowerMid", "Bottom", 0.3, 0.12)
	local strings = {
		{ newBeam(anchor, pts.Top, pts.Nock, S.White, 0.1, 0.07, 0.07), 0.07, 0.07 },
		{ newBeam(anchor, pts.Nock, pts.Bottom, S.White, 0.1, 0.07, 0.07), 0.07, 0.07 },
	}
	local sparks = FX.Emitter(anchor, {
		Color = FX.Grad(S.White, S.Gold), Size = FX.Seq(0.35, 0), Transparency = FX.Seq(0, 1),
		Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(180, 180), Rate = 25,
	})
	 
	local arrow = FX.Temp(ctx, cast, "HeavenNockedArrow", anchor.CFrame, Vector3.new(0.18, 0.18, 0.1), S.Yellow, 1)
	local arrowGlow = FX.Temp(ctx, cast, "HeavenNockedArrowGlow", anchor.CFrame, Vector3.new(0.6, 0.6, 0.1), S.Gold, 1)
	local handle = { Aim = function() return root.CFrame.LookVector end }
	local grown, draw, nocked, twang, born = 0, 0, false, nil, cast:Now()
	local dissolving = false
	cast:Step(function(_, now)
		if not anchor.Parent then return false end
		grown = math.clamp((now - born) / 0.45, 0, 1)
		local g = 1 - (1 - grown) ^ 3
		local aim = handle.Aim()
		local frame = CFrame.lookAt(hand.Position, hand.Position + aim, UP)
		anchor.CFrame = frame
		local nockZ = rest.Nock.Z - 3.4 * draw ^ 1.3
		if twang then
			local t = now - twang.Start
			nockZ = rest.Nock.Z + (twang.From - rest.Nock.Z) * math.exp(-12 * t) * math.cos(t * 48)
			if t > 0.45 then twang = nil end
		end
		for name, a in pairs(pts) do
			a.Position = name == "Nock" and Vector3.new(0, 0, nockZ * g) or rest[name] * g
		end
		if not dissolving then
			for _, b in ipairs(beams) do b[1].Width0, b[1].Width1 = b[2] * g, b[3] * g end
		end
		local nockWorld = frame:PointToWorldSpace(Vector3.new(0, 0, nockZ))
		if nocked then
			local length = 6
			local mid = nockWorld + aim * (length / 2)
			arrow.CFrame, arrow.Size, arrow.Transparency = CFrame.lookAt(mid, mid + aim), Vector3.new(0.22, 0.22, length), 0
			arrowGlow.CFrame, arrowGlow.Size, arrowGlow.Transparency = arrow.CFrame, Vector3.new(0.7, 0.7, length + 0.6), 0.55
		else
			arrow.Transparency, arrowGlow.Transparency = 1, 1
		end
		handle.NockWorld = nockWorld
		return true
	end)
	function handle.Nock(on) nocked = on end
	function handle.Draw(amount) draw = math.clamp(amount, 0, 1) end
	function handle.Release()
		twang = { Start = cast:Now(), From = rest.Nock.Z - 3.4 * draw ^ 1.3 }
		draw, nocked = 0, false
		FX.Flash(ctx, cast, handle.NockWorld or anchor.Position, S.White, 6, 0.15, 0)
	end
	function handle.Dissolve(time)
		dissolving = true
		sparks.Enabled = false
		FX.Sparks(ctx, cast, anchor.Position, S.Gold, S.White, 30, 6, 20, 0.5)
		for _, b in ipairs(beams) do FX.Tween(b[1], time, { Width0 = 0, Width1 = 0 }) end
		for _, b in ipairs(strings) do FX.Tween(b[1], time, { Width0 = 0, Width1 = 0 }) end
		cast:Schedule(time + 0.05, function()
			FX.Release(cast, anchor)
			FX.Release(cast, arrow)
			FX.Release(cast, arrowGlow)
		end)
	end
	FX.Sparks(ctx, cast, hand.Position, S.Gold, S.White, 24, 6, 18, 0.45)
	return handle
end

 
 
 
function V.Arrow(ctx, cast, from, to, flight, scale, onArrive)
	scale = scale or 1
	local dir = (to - from).Unit
	 -- sized for the 620-stud arena: a long gold shaft in a thick glow, a bright head
	local length = 14 * scale
	local shaft = FX.Temp(ctx, cast, "HeavenArrow", CFrame.lookAt(from, to), Vector3.new(0.7, 0.7, length) * Vector3.new(scale, scale, 1), S.Yellow, 0)
	local glow = FX.Temp(ctx, cast, "HeavenArrowGlow", shaft.CFrame, Vector3.new(2.4 * scale, 2.4 * scale, length * 1.1), S.Gold, 0.55)
	local head = FX.Temp(ctx, cast, "HeavenArrowHead", shaft.CFrame, Vector3.new(1.8, 1.8, 3.4) * scale, S.White, 0)
	trail(shaft, 1.3 * scale, S.Yellow, 0.25)
	local born = cast:Now()
	cast:Step(function(_, now)
		if not shaft.Parent then return false end
		local t = math.clamp((now - born) / flight, 0, 1)
		local p = from:Lerp(to, t ^ 1.2)
		local frame = CFrame.lookAt(p - dir * length / 2, p)
		shaft.CFrame, glow.CFrame = frame, frame
		head.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(0, 0, math.pi / 4)
		if t >= 1 then
			FX.Release(cast, shaft)
			FX.Release(cast, glow)
			FX.Release(cast, head)
			if onArrive then task.spawn(onArrive, to, dir) end
			return false
		end
		return true
	end)
end

function V.Mark(ctx, cast, sky, ground, radius, life)
	local length = (sky - ground).Magnitude
	local mid = (sky + ground) / 2
	local ray = FX.Temp(ctx, cast, "HeavenMarkRay", CFrame.lookAt(mid, ground), Vector3.new(0.12, 0.12, length), S.Yellow, 0.9, life + 0.05)
	FX.Tween(ray, life, { Size = Vector3.new(0.3, 0.3, length), Transparency = 0.45 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local anchor, set = Golden.BeamRing(ctx, cast, "HeavenMarkRing", ground + Vector3.new(0, 0.2, 0), radius * 1.6, S.Gold, 0.35, 28)
	local disc = Golden.Disc(ctx, cast, "HeavenMarkFill", ground + Vector3.new(0, 0.06, 0), radius * 2, S.Yellow, 0.9, life + 0.05)
	local born = cast:Now()
	cast:Step(function(_, now)
		if not anchor.Parent then return false end
		local t = math.clamp((now - born) / life, 0, 1)
		set(radius * (1.6 - 0.6 * t), 0.6 - 0.5 * t, 0.25 + 0.3 * t)
		disc.Transparency = 0.9 - 0.25 * t
		if t >= 1 then
			FX.Release(cast, anchor)
			return false
		end
		return true
	end)
end

 
 
function V.Impact(ctx, cast, ground, dir, scale, impactRadius)
	scale = scale or 1
	impactRadius = impactRadius or S.Rain.Radius
	local at = ground + UP * 0.6
	local big = scale > 1.6
	 -- the blast: a white-gold dome balloons out of the strike and burns away, a column of light
	 -- shoots up, a shock ring rolls out (two for the big arrows) and dust kicks up
	local dome = FX.Temp(ctx, cast, "HeavenBlastDome", CFrame.new(ground), Vector3.one * impactRadius * 0.6, S.White, 0.05, 0.55)
	dome.Shape = Enum.PartType.Ball
	FX.Tween(dome, 0.38, { Size = Vector3.one * impactRadius * (big and 3.2 or 2.6), Transparency = 1, Color = S.Gold }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local pillarHeight = (big and 80 or 30) * math.max(scale, 1)
	local pillar = FX.Temp(ctx, cast, "HeavenBlastPillar", CFrame.new(ground + UP * pillarHeight * 0.5), Vector3.new(impactRadius, pillarHeight, impactRadius), S.Bright, 0.2, 0.5)
	pillar.Shape = Enum.PartType.Cylinder
	pillar.CFrame = CFrame.new(ground + UP * pillarHeight * 0.5) * CFrame.Angles(0, 0, math.pi / 2)
	pillar.Size = Vector3.new(pillarHeight, impactRadius, impactRadius)
	FX.Tween(pillar, 0.42, { Size = Vector3.new(pillarHeight * 1.15, 0.3, 0.3), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	FX.Flash(ctx, cast, at, S.White, 10 * scale + impactRadius * 2, 0.22, 0)
	FX.Shockwave(ctx, cast, CFrame.new(ground + UP * 0.1), 1, impactRadius * 3, 0.4, S.Gold, 0.15)
	if big then
		FX.Shockwave(ctx, cast, CFrame.new(ground + UP * 0.15), 2, impactRadius * 5.5, 0.65, S.Bright, 0.25)
	end
	FX.Sparks(ctx, cast, at, S.Gold, S.White, math.floor(22 * scale), 18, 46, 0.6)
	FX.Streaks(ctx, cast, at, UP, S.Gold, S.White, math.floor(14 * scale), 40, 34, 70, 2.4)
	FX.Sparks(ctx, cast, ground + UP * 0.4, Golden.DUST, Golden.DUST, math.floor(10 * scale), 8, 20, 1.6)
	FX.Light(ctx, cast, ground + UP * 2, S.Yellow, big and 9 or 6, (big and 60 or 30) * scale, 0.45)
	for _ = 1, big and 4 or 2 do
		FX.Bolt(ctx, cast, at, ground + flatUnit() * rng:NextNumber(4, 10) * scale + UP * 0.3, S.Electric, S.White, 0.16, nil, 5, 0.18, true)
	end
	 -- the arrow stays stuck in the ground for a moment
	dir = dir or -UP
	local length = 10 * scale
	local stuck = CFrame.lookAt(ground - dir * (length * 0.3), ground + dir)
	local shaft = FX.Temp(ctx, cast, "HeavenArrowStuck", stuck, Vector3.new(0.6, 0.6, length), S.Yellow, 0, 1.8)
	local glow = FX.Temp(ctx, cast, "HeavenArrowStuckGlow", stuck, Vector3.new(1.9, 1.9, length + 0.6), S.Gold, 0.6, 1.8)
	cast:Schedule(1.1, function()
		if shaft.Parent then
			FX.Tween(shaft, 0.6, { Transparency = 1, Size = Vector3.new(0.1, 0.1, length) })
			FX.Tween(glow, 0.6, { Transparency = 1 })
		end
	end)
end

 
 
 
 
function V.Constellation(ctx, cast, points, drawTime)
	local glints, lines = {}, {}
	local handle = {}
	local count = #points
	local each = drawTime / math.max(1, count)
	for i, p in ipairs(points) do
		cast:Schedule((i - 1) * each, function()
			local spin = rng:NextNumber(0, math.pi)
			local pieces = {}
			for k = 0, 3 do
				local rot = CFrame.Angles(0, spin + k * math.pi / 2, 0) * CFrame.Angles(0, 0, math.pi / 2)
				for _, w in ipairs(spike(ctx, cast, "HeavenConstellationStar", rot, k % 2 == 0 and 3.2 or 2.2, 0.9, 0.08, S.White, 0, 2)) do
					w.Part.CFrame = CFrame.new(p + UP * 0.12) * CFrame.new(w.Offset) * w.Rot
					table.insert(pieces, w.Part)
				end
			end
			local dot = FX.Temp(ctx, cast, "HeavenConstellationDot", CFrame.new(p + UP * 0.2), Vector3.one * 1.2, S.White, 0)
			dot.Shape = Enum.PartType.Ball
			local halo = Golden.Disc(ctx, cast, "HeavenConstellationHalo", p + UP * 0.05, 7, S.Night, 0.7)
			FX.Glint(ctx, cast, p + UP * 1.5, S.White, 7, 0.35)
			glints[i] = { Pieces = pieces, Dot = dot, Halo = halo, Position = p }
			 
			if i > 1 then
				local a, b = points[i - 1] + UP * 0.1, p + UP * 0.1
				local core = FX.Temp(ctx, cast, "HeavenConstellationLine", CFrame.lookAt(a, b), Vector3.new(0.22, 0.06, 0.05), S.White, 0)
				local glow = FX.Temp(ctx, cast, "HeavenConstellationLineGlow", CFrame.lookAt(a, b), Vector3.new(1.1, 0.04, 0.05), S.Night, 0.55)
				lines[i - 1] = { Core = core, Glow = glow }
				local born = cast:Now()
				cast:Step(function(_, now)
					if not core.Parent then return false end
					local t = math.clamp((now - born) / (each * 0.9), 0, 1)
					local tip = a:Lerp(b, 1 - (1 - t) ^ 2)
					local mid = (a + tip) / 2
					local frame = CFrame.lookAt(mid, tip + (b - a).Unit * 0.01)
					core.CFrame, glow.CFrame = frame, frame
					core.Size = Vector3.new(0.22, 0.06, math.max(0.05, (tip - a).Magnitude))
					glow.Size = Vector3.new(1.1, 0.04, math.max(0.05, (tip - a).Magnitude))
					return t < 1
				end)
			end
		end)
	end
	function handle.Trace(i)
		local g = glints[i]
		if not g then return end
		FX.Flash(ctx, cast, g.Position + UP, S.White, 5, 0.2, 0)
		for _, piece in ipairs(g.Pieces) do FX.Tween(piece, 0.4, { Transparency = 1 }) end
		FX.Tween(g.Dot, 0.4, { Transparency = 1, Size = Vector3.one * 3 })
		local line = lines[i - 1]
		if line then
			line.Core.Color = S.Bright
			FX.Tween(line.Core, 0.5, { Transparency = 1 })
			FX.Tween(line.Glow, 0.5, { Transparency = 1 })
		end
	end
	function handle.Fade(time)
		for _, g in pairs(glints) do
			for _, piece in ipairs(g.Pieces) do FX.Tween(piece, time, { Transparency = 1 }) end
			FX.Tween(g.Dot, time, { Transparency = 1 })
			FX.Tween(g.Halo, time, { Transparency = 1 })
		end
		for _, line in pairs(lines) do
			FX.Tween(line.Core, time, { Transparency = 1 })
			FX.Tween(line.Glow, time, { Transparency = 1 })
		end
		cast:Schedule(time + 0.05, function()
			for _, g in pairs(glints) do
				for _, piece in ipairs(g.Pieces) do FX.Release(cast, piece) end
				FX.Release(cast, g.Dot)
				FX.Release(cast, g.Halo)
			end
			for _, line in pairs(lines) do
				FX.Release(cast, line.Core)
				FX.Release(cast, line.Glow)
			end
		end)
	end
	return handle
end

 
 
function V.Seal(ctx, cast, ground, radius, life)
	local outer, setOuter = Golden.BeamRing(ctx, cast, "HeavenSealOuter", ground + UP * 0.25, radius, S.Gold, 0.5, 48)
	local inner, setInner = Golden.BeamRing(ctx, cast, "HeavenSealInner", ground + UP * 0.3, radius * 0.7, S.White, 0.4, 40)
	local pieces = {}
	for k = 0, 3 do
		for _, w in ipairs(spike(ctx, cast, "HeavenSealStar", CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), radius * 0.95, 1.6, 0.1, S.Bright, 0.3, 2)) do
			table.insert(pieces, w)
		end
	end
	local disc = Golden.Disc(ctx, cast, "HeavenSealFill", ground + UP * 0.06, radius * 2, S.Yellow, 0.85, life + 0.1)
	local born = cast:Now()
	cast:Step(function(_, now)
		if not outer.Parent then return false end
		local t = math.clamp((now - born) / life, 0, 1)
		local spin = t * 3 + t * t * 6
		setOuter(radius * (1.25 - 0.25 * t), 0.5 - 0.4 * t, 0.35 + 0.4 * t)
		setInner(radius * 0.7 * (1 - 0.6 * t), 0.4 - 0.3 * t, 0.25 + 0.3 * t)
		local base = CFrame.new(ground + UP * 0.15) * CFrame.Angles(0, spin, 0)
		for _, w in ipairs(pieces) do
			w.Part.CFrame = base * CFrame.new(w.Offset) * w.Rot
			w.Part.Transparency = 0.6 - 0.5 * t
		end
		disc.Transparency = 0.85 - 0.35 * t
		if t >= 1 then
			FX.Release(cast, outer)
			FX.Release(cast, inner)
			for _, w in ipairs(pieces) do FX.Release(cast, w.Part) end
			return false
		end
		return true
	end)
end

 
 
function V.Quill(ctx, cast, position)
	local shaft = FX.Temp(ctx, cast, "HeavenQuillShaft", CFrame.new(position), Vector3.new(0.1, 0.1, 2.6), S.White, 0)
	local vanes = spike(ctx, cast, "HeavenQuillVane", CFrame.identity, 2.2, 0.75, 0.06, S.Bright, 0.05, 2)
	local glow = FX.Temp(ctx, cast, "HeavenQuillGlow", CFrame.new(position), Vector3.new(0.5, 0.9, 2.9), S.Gold, 0.65)
	trail(shaft, 0.3, S.Gold, 0.22)
	FX.Flash(ctx, cast, position, S.Bright, 2.5, 0.12, 0)
	local parts = { shaft, glow }
	for _, w in ipairs(vanes) do table.insert(parts, w.Part) end
	local frames = {}
	local quill = {}
	function quill.Set(frame)
		frames[1], frames[2] = frame, frame
		 
		for i, w in ipairs(vanes) do
			frames[i + 2] = frame * CFrame.new(0, 0, 1.1) * CFrame.new(w.Offset) * w.Rot
		end
		workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	function quill.Lock()
		FX.Glint(ctx, cast, shaft.Position, S.White, 3.2, 0.2)
	end
	function quill.Pop(hit)
		local p = shaft.Position
		for _, part in ipairs(parts) do FX.Release(cast, part) end
		if hit then
			FX.Flash(ctx, cast, p, S.White, 4.5, 0.14, 0)
			FX.Sparks(ctx, cast, p, S.Gold, S.White, 12, 8, 24, 0.35)
		else
			FX.Sparks(ctx, cast, p, S.Gold, S.White, 6, 4, 12, 0.3)
		end
	end
	function quill.Alive() return shaft.Parent ~= nil end
	return quill
end

 
function V.Aura(ctx, cast, actor, root)
	local holder = Instance.new("Attachment")
	holder.Name = "HeavenlyDiscipleAura"
	holder.Parent = root
	cast:Add(holder)
	local crackle = FX.Emitter(holder, {
		Color = FX.Grad(S.White, S.Electric), Size = FX.Seq(0.5, 0), Transparency = FX.Seq(0, 1),
		Lifetime = NumberRange.new(0.1, 0.25), Speed = NumberRange.new(10, 26), SpreadAngle = Vector2.new(180, 180), Rate = 50,
	})
	local motes = FX.Emitter(holder, {
		Color = FX.Grad(S.White, S.Gold), Size = FX.Seq(0, 0.5, 0), Transparency = FX.Seq(0.2, 0.1, 1),
		Lifetime = NumberRange.new(1.2, 2), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(60, 60),
		Acceleration = Vector3.new(0, 5, 0), EmissionDirection = Enum.NormalId.Top, Rate = 24,
	})
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = S.Yellow, 2.5, 24, false
	light.Parent = holder
	local highlight = Instance.new("Highlight")
	highlight.Name = "HeavenlyDiscipleGlow"
	highlight.FillColor, highlight.OutlineColor = S.Gold, S.Bright
	highlight.FillTransparency, highlight.OutlineTransparency = 1, 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = actor
	highlight.Parent = actor
	cast:Add(highlight)
	FX.Tween(highlight, 0.5, { FillTransparency = 0.82, OutlineTransparency = 0.1 })
	return function()
		if holder.Parent then
			crackle.Enabled, motes.Enabled, light.Enabled = false, false, false
		end
		if highlight.Parent then FX.Tween(highlight, 0.5, { FillTransparency = 1, OutlineTransparency = 1 }) end
	end
end

 
function V.Crackle(ctx, cast, origin, radius)
	local target = Vector3.new(origin.X, origin.Y - 2.8, origin.Z) + flatUnit() * rng:NextNumber(3, radius)
	if rng:NextNumber() < 0.3 then
		FX.ForkedBolt(ctx, cast, origin + Vector3.new(0, rng:NextNumber(-1, 2.5), 0), target, S.Electric, S.White, 0.22, 0.2, 2)
	else
		FX.Bolt(ctx, cast, origin + Vector3.new(0, rng:NextNumber(-1, 2.5), 0), target, S.Electric, S.White, 0.2, nil, 6, 0.18, true)
	end
	FX.Sparks(ctx, cast, target + Vector3.new(0, 0.3, 0), S.Electric, S.White, 6, 6, 16, 0.3)
end

 
function V.HealPulse(ctx, cast, root)
	FX.Ring(ctx, cast, CFrame.new(root.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(math.pi / 2, 0, 0), 3, 7, 0.6, S.Bright, 0.3, 0.35, 1)
	FX.Streaks(ctx, cast, root.Position, UP, S.Gold, S.White, 6, 25, 6, 14, 1.2)
end

for _, name in ipairs({ "Star", "Bow", "Arrow", "Mark", "Constellation", "Seal", "Impact", "Quill", "Aura", "Crackle", "HealPulse" }) do
	local fn = V[name]
	V[name] = function(...)
		local ok, a, b = pcall(fn, ...)
		if not ok then
			warn("[HeavenlyDisciple VFX] " .. name .. " failed: " .. tostring(a))
			return nil
		end
		return a, b
	end
end
return V
