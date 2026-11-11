--!nonstrict
--[[
 Azusa's skills (second pass). Each one teaches one rule of the shared fight layer (UnfairShared/BossKit), she says it out loud the
 first time (boss dialogue at the bottom of the screen, like alterGolden), and each one is built the same way:
   telegraph  Blender shapes (kit "AzusaFX") tagged AzusaFlash: TutorialClient blinks them, faster and faster until they land
   wind-up    a generated animation (Azusa.Play), her body flashing (Azusa.Charge), the blade trail on
   strike     layered shapes: a Neon core inside a ForceField aura, petals, smoke and a flaring light, camera shake or an impact frame
   residue    something that lingers a moment and fades (burning lines, X-cuts, ghosts)

   Sigils     Blossom Mines     ornate sigils under you (two rings turning), then a sakura snaps open        -> step out
   Crescent   Moonlit Crescent  a two-layer crescent sweeps the arena, leaving a burning line               -> dash THROUGH (Q)
   Iai        Flash Draw        she crouches, the shield flashes on you, one cut crosses the arena          -> deflect (E)
   Thorns     Thorn Waltz       she leaps and drives the blade down: shockwave and thorn rings               -> jump
   PetalFan   Petal Storm       fans of petal kunai with trails, each fan offset from the last              -> strafe or guard (R)
   Rush       Hundred Steps     (phase 2) three red lines, three cuts, ghosts and X-cuts left in the air   -> deflect each (E)
   Bloom      Petal Requiem     (phase 2) the sky turns, a giant spirit blade rises, pillars chase you, the blade falls and a
                                ring wave runs out from the middle                                            -> run, then dash
 Every attack is `function(ctx, target)`;
 ctx = { Kit, Azusa, Phase, Speed, Stopped(), Exposed(seconds), Say(lessonId, lesson, quips), FX(kind, data) }.
]]
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local A = {}
local PINK, DEEP, WHITE, RED = Color3.fromRGB(255, 120, 185), Color3.fromRGB(230, 60, 140), Color3.new(1, 1, 1), Color3.fromRGB(255, 60, 90)
local FLOOR = 0
local LIMIT = 66 -- she never cuts past this far from the middle

local fxFolder = workspace:FindFirstChild("AzusaFXLive") or Instance.new("Folder")
fxFolder.Name = "AzusaFXLive"
fxFolder.Parent = workspace

local function now()
	return workspace:GetServerTimeNow()
end

-- A kit shape, styled: "core" = bright Neon, "aura" = shimmering ForceField, "glass" = clear tinted glass.
local function shape(name, style, color)
	local lib = ReplicatedStorage:FindFirstChild("AzusaFX")
	local template = lib and lib:FindFirstChild(name)
	local m
	if template then
		m = template:Clone()
	else
		m = Instance.new("Model")
		m.Name = name
		local p = Instance.new("Part")
		p.Size = Vector3.new(2, 0.2, 2)
		p.Parent = m
	end
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			if style == "aura" then
				p.Material, p.Color, p.Transparency = Enum.Material.ForceField, color or PINK, 0
			elseif style == "glass" then
				p.Material, p.Color, p.Transparency = Enum.Material.Glass, color or PINK, 0.45
			elseif p.Name == "Glow" or style == "core" then
				p.Material, p.Color = Enum.Material.Neon, color or WHITE
			end
		end
	end
	m.Parent = fxFolder
	return m
end

-- Flash `model` from now for `seconds` (TutorialClient), then hold `color`.
local function flash(model, seconds, color, base)
	local t = now()
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p:SetAttribute("FlashColor", color or PINK)
			p:SetAttribute("FlashFrom", t)
			p:SetAttribute("FlashTo", t + seconds)
			p:SetAttribute("FlashBase", base or 0.1)
			CollectionService:AddTag(p, "AzusaFlash")
		end
	end
end

-- TutorialClient turns tagged models round their pivot (radians a second).
local function spin(model, speed)
	model:SetAttribute("Spin", speed)
	CollectionService:AddTag(model, "AzusaSpin")
end

local function fade(model, seconds, grow)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			CollectionService:RemoveTag(p, "AzusaFlash")
			local goal = { Transparency = 1 }
			if grow then
				goal.Size = p.Size * grow
			end
			TweenService:Create(p, TweenInfo.new(seconds or 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
		end
	end
	CollectionService:RemoveTag(model, "AzusaSpin")
	Debris:AddItem(model, (seconds or 0.4) + 0.1)
end

local function holder(pos)
	local h = Instance.new("Part")
	h.Anchored, h.CanCollide, h.CanQuery, h.CanTouch, h.Transparency = true, false, false, false, 1
	h.Size, h.Position = Vector3.new(1, 1, 1), pos
	h.Parent = fxFolder
	return h
end

-- petals, a puff of pink smoke and a light that flares and dies
local function burst(pos, scale, color)
	scale = scale or 1
	local h = holder(pos)
	local petals = Instance.new("ParticleEmitter")
	petals.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	petals.Color = ColorSequence.new(color or PINK, WHITE)
	petals.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2 * scale), NumberSequenceKeypoint.new(1, 0) })
	petals.Lifetime = NumberRange.new(0.5, 1.1)
	petals.Speed = NumberRange.new(16 * scale, 34 * scale)
	petals.SpreadAngle = Vector2.new(180, 180)
	petals.Drag, petals.Acceleration = 4, Vector3.new(0, -10, 0)
	petals.Rotation, petals.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-300, 300)
	petals.LightEmission, petals.Rate = 0.8, 0
	petals.Parent = h
	petals:Emit(math.floor(36 * scale))
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(255, 200, 225))
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2 * scale), NumberSequenceKeypoint.new(1, 7 * scale) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(0.6, 1)
	smoke.Speed = NumberRange.new(6 * scale, 12 * scale)
	smoke.SpreadAngle = Vector2.new(180, 30)
	smoke.Drag, smoke.Rate = 5, 0
	smoke.Parent = h
	smoke:Emit(math.floor(10 * scale))
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = color or PINK, 22 * scale, 6, false
	light.Parent = h
	TweenService:Create(light, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	Debris:AddItem(h, 1.6)
end

-- a flat shockwave (white core, pink aura) spreading on the floor
local function shockwave(pos, radius, seconds)
	for i, style in { "core", "aura" } do
		local m = shape("Shockwave", style, i == 1 and WHITE or PINK)
		m:ScaleTo(radius * 0.2)
		m:PivotTo(CFrame.new(pos + Vector3.new(0, 0.1 * i, 0)))
		local part = m:FindFirstChildWhichIsA("BasePart")
		if part then
			TweenService:Create(part, TweenInfo.new(seconds or 0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = part.Size * (i == 1 and 5 or 5.6), Transparency = 1,
			}):Play()
		end
		Debris:AddItem(m, (seconds or 0.45) + 0.1)
	end
end

local function rootOf(char)
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function pause(seconds, ctx)
	local untilAt = os.clock() + seconds
	while os.clock() < untilAt do
		if ctx.Stopped() then
			return false
		end
		RunService.Heartbeat:Wait()
	end
	return true
end

local function inArena(p)
	local flat = Vector3.new(p.X, 0, p.Z)
	if flat.Magnitude > LIMIT then
		flat = flat.Unit * LIMIT
	end
	return Vector3.new(flat.X, FLOOR, flat.Z)
end

local function flatDistance(a, b)
	return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end

local function hit(ctx, char, damage, skill, opts)
	opts = opts or {}
	opts.Skill = skill
	local result = ctx.Kit.Hit(char, damage, ctx.Azusa.Model(), opts)
	local r = rootOf(char)
	if result == "Deflected" then
		if r then
			burst(r.Position, 1.2, WHITE)
		end
	elseif type(result) == "number" and result > 0 and r then
		burst(r.Position, 0.6)
	end
	return result
end

-- a tall wave stretched from a kit shape (a mesh can be stretched along one axis by its Size)
local function stretch(model, factor)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Size = Vector3.new(p.Size.X, p.Size.Y * factor, p.Size.Z)
		end
	end
end

-- ---------------------------------------------------------------------------------------------------------- Blossom Mines
function A.Sigils(ctx, target)
	ctx.Say("Sigils", "Watch the ground. When my sigils glow under you, step out before they bloom!", { "Bloom.", "Mind your feet.", "Dance for me." })
	local count = ctx.Phase == 2 and 6 or 4
	local delay = 1.3 / ctx.Speed
	ctx.Azusa.Play("Point", 1.4)
	local marks = {}
	for i = 1, count do
		local r = rootOf(target)
		if not r then
			break
		end
		local lead = r.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * 0.4
		local at = inArena(r.Position + (i == 1 and lead or Vector3.new(math.random(-12, 12), 0, math.random(-12, 12)))) + Vector3.new(0, 0.07, 0)
		local inner, outer, fill = shape("Sigil", "core", RED), shape("SigilOuter", "core", RED), shape("Shockwave", "aura", RED)
		inner:ScaleTo(8.5)
		outer:ScaleTo(8.5)
		fill:ScaleTo(8.2)
		local turn = CFrame.Angles(0, math.random() * 6, 0)
		inner:PivotTo(CFrame.new(at) * turn)
		outer:PivotTo(CFrame.new(at + Vector3.new(0, 0.02, 0)) * turn)
		fill:PivotTo(CFrame.new(at - Vector3.new(0, 0.03, 0)))
		spin(inner, 1.4)
		spin(outer, -0.9)
		flash(inner, delay, RED, 0.05)
		flash(outer, delay, RED, 0.05)
		table.insert(marks, { parts = { inner, outer, fill }, at = at, due = os.clock() + delay })
		if not pause(0.26 / ctx.Speed, ctx) then
			break
		end
	end
	for _, mark in marks do
		local left = mark.due - os.clock()
		if left > 0 and not pause(left, ctx) then
			break
		end
		for _, m in mark.parts do
			fade(m, 0.25, 1.15)
		end
		-- the bloom: a flower snaps open and a petal column shoots up
		for _, style in { "core", "aura" } do
			local flower = shape("BloomFlower", style, style == "core" and WHITE or PINK)
			flower:ScaleTo(0.3)
			flower:PivotTo(CFrame.new(mark.at) * CFrame.Angles(0, math.random() * 6, 0))
			local part = flower:FindFirstChildWhichIsA("BasePart")
			if part then
				TweenService:Create(part, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = part.Size * 6 }):Play()
			end
			task.delay(0.2, function()
				fade(flower, 0.45)
			end)
		end
		local pillar = shape("BloomPillar", "aura", PINK)
		pillar:ScaleTo(0.55)
		pillar:PivotTo(CFrame.new(mark.at))
		fade(pillar, 0.55, 1.2)
		burst(mark.at + Vector3.new(0, 2, 0), 1)
		ctx.FX("Shake", { At = mark.at, Power = 0.35 })
		for _, char in ctx.Kit.Fighters() do
			local cr = rootOf(char)
			if cr and flatDistance(cr.Position, mark.at) < 8.5 and cr.Position.Y < FLOOR + 14 then
				hit(ctx, char, 22, "AzusaSigil")
			end
		end
	end
	return true
end

-- ---------------------------------------------------------------------------------------------------------- Moonlit Crescent
-- (also the end of Petal Requiem, aimed by `aimAt`)
function A.Crescent(ctx, target, aimAt)
	if not aimAt then
		ctx.Say("Crescent", "This wave is too tall to jump. Dash straight THROUGH it with Q!", { "Moonlit Crescent!", "Cut through, if you can.", "Too slow!" })
	end
	local root, r = ctx.Azusa.Root(), rootOf(target)
	if not root or not r then
		return false
	end
	local aim = aimAt or r.Position
	ctx.Azusa.Face(aim)
	local windup = 1.0 / ctx.Speed
	ctx.Azusa.Play("BigSlash", windup + 0.6)
	ctx.Azusa.Trail(true)
	ctx.Azusa.Charge(windup)
	local origin = Vector3.new(root.Position.X, FLOOR, root.Position.Z)
	local dir = (aim - root.Position) * Vector3.new(1, 0, 1)
	dir = dir.Magnitude > 0.1 and dir.Unit or root.CFrame.LookVector
	local look = CFrame.lookAt(origin, origin + dir)
	-- the lane: a shimmering strip and three chevrons pointing down it
	local lane = Instance.new("Model")
	lane.Parent = fxFolder
	local strip = Instance.new("Part")
	strip.Anchored, strip.CanCollide, strip.CanQuery, strip.CanTouch, strip.CastShadow = true, false, false, false, false
	strip.Material, strip.Color, strip.Size = Enum.Material.ForceField, PINK, Vector3.new(36, 0.1, 150)
	strip.CFrame = look * CFrame.new(0, 0.1, -75)
	strip.Parent = lane
	for k = 1, 3 do
		local chevron = shape("PetalKunai", "core", RED)
		chevron:ScaleTo(3)
		chevron:PivotTo(look * CFrame.new(0, 0.15, -20 * k) * CFrame.Angles(math.rad(-90), 0, 0))
		chevron.Parent = lane
	end
	flash(lane, windup, PINK, 0.3)
	if not pause(windup, ctx) then
		lane:Destroy()
		ctx.Azusa.Trail(false)
		return false
	end
	fade(lane, 0.3)
	ctx.FX("Shake", { At = origin, Power = 0.6 })
	burst(root.Position + dir * 3, 0.8, WHITE)
	-- the wave: a thin white core inside a wide pink aura, petals pouring off it
	local core, aura = shape("SlashCore", "core", WHITE), shape("SlashAura", "aura", PINK)
	core:ScaleTo(1.08)
	aura:ScaleTo(1.08)
	stretch(core, 2.6)
	stretch(aura, 2.6)
	local trailHolder = holder(origin)
	trailHolder.Size = Vector3.new(30, 8, 2)
	local pour = Instance.new("ParticleEmitter")
	pour.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pour.Color = ColorSequence.new(PINK, WHITE)
	pour.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	pour.Lifetime = NumberRange.new(0.5, 0.9)
	pour.Speed = NumberRange.new(2, 6)
	pour.Rate = 140
	pour.SpreadAngle = Vector2.new(180, 180)
	pour.Shape, pour.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
	pour.LightEmission = 0.9
	pour.Parent = trailHolder
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness = PINK, 30, 4
	glow.Parent = trailHolder
	local speed = 100 * ctx.Speed
	local travelled, struck, lastScorch = 4, {}, 0
	while travelled < 160 and not ctx.Stopped() do
		local dt = RunService.Heartbeat:Wait()
		travelled += speed * dt
		local at = look * CFrame.new(0, 0, -travelled)
		core:PivotTo(at * CFrame.new(0, 6, 0) * CFrame.Angles(0, math.pi, 0))
		aura:PivotTo(at * CFrame.new(0, 6, 0.6) * CFrame.Angles(0, math.pi, 0))
		trailHolder.CFrame = at * CFrame.new(0, 5, 1.5)
		if travelled - lastScorch > 6 then -- a burning line left on the floor
			lastScorch = travelled
			local scorch = Instance.new("Part")
			scorch.Anchored, scorch.CanCollide, scorch.CanQuery, scorch.CanTouch, scorch.CastShadow = true, false, false, false, false
			scorch.Material, scorch.Color, scorch.Size = Enum.Material.Neon, PINK, Vector3.new(26, 0.06, 6.2)
			scorch.CFrame = at * CFrame.new(0, 0.05, 2)
			scorch.Transparency = 0.35
			scorch.Parent = fxFolder
			TweenService:Create(scorch, TweenInfo.new(1.1), { Transparency = 1, Size = Vector3.new(30, 0.06, 2) }):Play()
			Debris:AddItem(scorch, 1.2)
		end
		for _, char in ctx.Kit.Fighters() do
			local cr = rootOf(char)
			if cr and not struck[char] then
				local rel = look:PointToObjectSpace(cr.Position)
				if math.abs(rel.X) < 17 and math.abs(-rel.Z - travelled) < 3.4 and cr.Position.Y < FLOOR + 13 then
					struck[char] = true
					hit(ctx, char, 28, "AzusaCrescent")
				end
			end
		end
		if (at.Position * Vector3.new(1, 0, 1)).Magnitude > 92 then
			break
		end
	end
	ctx.Azusa.Trail(false)
	pour.Enabled = false
	fade(core, 0.2, 1.3)
	fade(aura, 0.3, 1.5)
	Debris:AddItem(trailHolder, 1)
	return true
end

-- ---------------------------------------------------------------------------------------------------------- Flash Draw
function A.Iai(ctx, target)
	ctx.Say("Iai", "When the white shield flashes on you, press E. Turn my blade aside!", { "Flash Draw.", "Can you see it?", "One cut." })
	local root, r = ctx.Azusa.Root(), rootOf(target)
	if not root or not r then
		return false
	end
	ctx.Azusa.Face(r.Position)
	local windup = 1.2 / ctx.Speed
	ctx.Azusa.Play("Iai", windup + 0.5)
	ctx.Azusa.Charge(windup, WHITE)
	ctx.FX("Focus", { Seconds = windup })
	if not pause(windup - 0.55, ctx) then
		return false
	end
	ctx.Kit.Warn(target, "Tap", 0.55)
	if not pause(0.55, ctx) then
		return false
	end
	r = rootOf(target)
	if not r then
		return false
	end
	local model = ctx.Azusa.Model()
	local height = model:GetAttribute("Height") or 3
	local from = Vector3.new(root.Position.X, FLOOR, root.Position.Z)
	local dir = (r.Position - root.Position) * Vector3.new(1, 0, 1)
	dir = dir.Magnitude > 0.1 and dir.Unit or root.CFrame.LookVector
	local to = inArena(r.Position + dir * 9)
	-- ghosts along the way, then she is simply there
	for k = 0, 4 do
		local p = from:Lerp(to, k / 4) + Vector3.new(0, height, 0)
		model:PivotTo(CFrame.lookAt(p, p + dir))
		ctx.Azusa.Afterimage(0.5)
	end
	ctx.Azusa.Blink(to, to + dir)
	-- the cut: a long white line inside a pink edge, hanging for a breath, then blooms burst along it
	local length = (to - from).Magnitude
	local line = Instance.new("Part")
	line.Anchored, line.CanCollide, line.CanQuery, line.CanTouch, line.CastShadow = true, false, false, false, false
	line.Material, line.Color, line.Size = Enum.Material.Neon, WHITE, Vector3.new(0.35, 0.35, math.max(length, 1))
	line.CFrame = CFrame.lookAt((from + to) / 2 + Vector3.new(0, 3.2, 0), to + Vector3.new(0, 3.2, 0))
	line.Parent = fxFolder
	local edge = line:Clone()
	edge.Material, edge.Color, edge.Size = Enum.Material.ForceField, PINK, Vector3.new(1.6, 1.6, math.max(length, 1))
	edge.Parent = fxFolder
	TweenService:Create(line, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.new(0.02, 6, math.max(length, 1)), Transparency = 1 }):Play()
	TweenService:Create(edge, TweenInfo.new(0.6), { Size = Vector3.new(0.1, 9, math.max(length, 1)), Transparency = 1 }):Play()
	Debris:AddItem(line, 0.6)
	Debris:AddItem(edge, 0.7)
	local result = hit(ctx, target, 35, "AzusaIai", { Deflect = "Tap" })
	ctx.FX("ImpactFrame", { Strong = result ~= "Deflected" })
	task.delay(0.25, function()
		for k = 1, 4 do
			burst(from:Lerp(to, k / 5) + Vector3.new(0, 3, 0), 0.5)
		end
	end)
	if result == "Deflected" then
		ctx.Azusa.Play("Stagger", 1.6)
		ctx.Exposed(2.6)
	end
	return true
end

-- ---------------------------------------------------------------------------------------------------------- Thorn Waltz
-- a ring of thorns spreading from `center`; returns when it has gone past the arena
local function thornRing(ctx, center, speed, damage, tall, skill)
	local parts, models = {}, {}
	for _, style in { "core", "aura" } do
		local m = shape("ThornRing", style, style == "core" and WHITE or PINK)
		flash(m, 0.3, PINK, 0)
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				table.insert(parts, { part = p, size = p.Size, scale = style == "aura" and 1.25 or 1 })
			end
		end
		table.insert(models, m)
	end
	local radius, struck = 3, {}
	while radius < 92 and not ctx.Stopped() do
		local dt = RunService.Heartbeat:Wait()
		radius += speed * dt
		for _, b in parts do
			local height = b.size.Y * tall * b.scale
			b.part.Size = Vector3.new(b.size.X * radius * b.scale, height, b.size.Z * radius * b.scale)
			b.part.CFrame = CFrame.new(center + Vector3.new(0, height / 2, 0))
		end
		for _, char in ctx.Kit.Fighters() do
			local cr = rootOf(char)
			if cr and not struck[char] and math.abs(flatDistance(cr.Position, center) - radius) < 1.9 and cr.Position.Y < FLOOR + (tall > 20 and 14 or 4.8) then
				struck[char] = true
				hit(ctx, char, damage, skill)
			end
		end
	end
	for _, m in models do
		fade(m, 0.2)
	end
end

function A.Thorns(ctx, target)
	ctx.Say("Thorns", "Thorns run along the floor. Jump over them!", { "Thorn Waltz!", "Jump!", "Higher!" })
	local root = ctx.Azusa.Root()
	if not root then
		return false
	end
	local rings = ctx.Phase == 2 and 3 or 2
	local windup = 0.8 / ctx.Speed
	ctx.Azusa.Play("Plunge", windup + 0.9)
	ctx.Azusa.Trail(true)
	ctx.Azusa.Charge(windup)
	local center = Vector3.new(root.Position.X, FLOOR + 0.15, root.Position.Z)
	local warn = shape("Shockwave", "aura", RED)
	warn:ScaleTo(10)
	warn:PivotTo(CFrame.new(center))
	flash(warn, windup, RED, 0.2)
	if not pause(windup, ctx) then
		warn:Destroy()
		ctx.Azusa.Trail(false)
		return false
	end
	fade(warn, 0.2)
	ctx.Azusa.Trail(false)
	for _ = 1, rings do
		shockwave(center, 10, 0.4)
		burst(center + Vector3.new(0, 1, 0), 1.2)
		ctx.FX("Shake", { At = center, Power = 0.9 })
		task.spawn(thornRing, ctx, center, 40 * ctx.Speed, 18, 9, "AzusaThorns")
		if not pause(0.8 / ctx.Speed, ctx) then
			return false
		end
	end
	return pause(0.5, ctx)
end

-- ---------------------------------------------------------------------------------------------------------- Petal Storm
function A.PetalFan(ctx, target)
	ctx.Say("PetalFan", "Keep moving sideways, or hold R to guard!", { "Petal Storm!", "Scatter!", "How many can you dodge?" })
	local root = ctx.Azusa.Root()
	if not root then
		return false
	end
	local volleys = ctx.Phase == 2 and 3 or 2
	for v = 1, volleys do
		local r = rootOf(target)
		if not r then
			return false
		end
		ctx.Azusa.Face(r.Position)
		local windup = 0.5 / ctx.Speed
		ctx.Azusa.Play("Throw", windup + 0.5)
		ctx.Azusa.Charge(windup)
		-- the kunai gather behind her, flashing, then fly
		local n = ctx.Phase == 2 and 9 or 7
		local origin = root.Position + Vector3.new(0, 0.6, 0)
		local aim = (r.Position - origin) * Vector3.new(1, 0, 1)
		aim = aim.Magnitude > 0.1 and aim.Unit or root.CFrame.LookVector
		local spread = math.rad(ctx.Phase == 2 and 72 or 58)
		local offset = (v % 2 == 0) and spread / (n - 1) / 2 or 0
		local petals = {}
		for i = 1, n do
			local a = -spread / 2 + spread * (i - 1) / (n - 1) + offset
			local dir = (CFrame.Angles(0, a, 0) * CFrame.lookAt(Vector3.zero, aim)).LookVector
			local kunai = shape("PetalKunai", "core", WHITE)
			kunai:ScaleTo(1.5)
			local part = kunai:FindFirstChildWhichIsA("BasePart")
			if part then
				local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a0.Position, a1.Position = Vector3.new(-0.5, 0, 0), Vector3.new(0.5, 0, 0)
				a0.Parent, a1.Parent = part, part
				local trail = Instance.new("Trail")
				trail.Attachment0, trail.Attachment1 = a0, a1
				trail.Color = ColorSequence.new(PINK, DEEP)
				trail.Transparency = NumberSequence.new(0.1, 1)
				trail.Lifetime, trail.LightEmission = 0.25, 1
				trail.Parent = part
			end
			local start = origin - aim * 3 + Vector3.new(math.cos(i) * 2, 1 + math.sin(i * 2), 0)
			kunai:PivotTo(CFrame.lookAt(start, start + dir))
			flash(kunai, windup, PINK, 0)
			table.insert(petals, { model = kunai, dir = dir, pos = start })
		end
		if not pause(windup, ctx) then
			for _, p in petals do
				p.model:Destroy()
			end
			return false
		end
		burst(origin + aim * 2, 0.5)
		for _, petal in petals do
			task.spawn(function()
				local life = 0
				while life < 2.2 and not ctx.Stopped() do
					local dt = RunService.Heartbeat:Wait()
					life += dt
					petal.pos += petal.dir * 64 * ctx.Speed * dt
					petal.model:PivotTo(CFrame.lookAt(petal.pos, petal.pos + petal.dir) * CFrame.Angles(0, 0, life * 14))
					for _, char in ctx.Kit.Fighters() do
						local cr = rootOf(char)
						if cr and (cr.Position - petal.pos).Magnitude < 3 then
							hit(ctx, char, 12, "AzusaPetal")
							life = 99
							break
						end
					end
				end
				fade(petal.model, 0.15)
			end)
		end
		if not pause(0.55 / ctx.Speed, ctx) then
			return false
		end
	end
	return true
end

-- ---------------------------------------------------------------------------------------------------------- Hundred Steps
function A.Rush(ctx, target)
	ctx.Say("Rush", "Three cuts, three red lines. Deflect each one with E, or dash out of the line!", { "Hundred Steps!", "Keep up!", "One, two, THREE!" })
	for step = 1, 3 do
		local root, r = ctx.Azusa.Root(), rootOf(target)
		if not root or not r then
			return false
		end
		local from = Vector3.new(root.Position.X, FLOOR, root.Position.Z)
		local aim = Vector3.new(r.Position.X, FLOOR, r.Position.Z)
		local dir = aim - from
		dir = dir.Magnitude > 0.1 and dir.Unit or root.CFrame.LookVector
		local to = inArena(aim + dir * 14)
		ctx.Azusa.Face(to)
		local length = math.max((to - from).Magnitude, 1)
		local lane = Instance.new("Model")
		lane.Parent = fxFolder
		for _, spec in { { Enum.Material.Neon, 0.6 }, { Enum.Material.ForceField, 3.4 } } do
			local line = Instance.new("Part")
			line.Anchored, line.CanCollide, line.CanQuery, line.CanTouch, line.CastShadow = true, false, false, false, false
			line.Material, line.Color, line.Size = spec[1], RED, Vector3.new(spec[2], 0.1, length)
			line.CFrame = CFrame.lookAt((from + to) / 2 + Vector3.new(0, 0.12, 0), to + Vector3.new(0, 0.12, 0))
			line.Parent = lane
		end
		local windup = (step == 1 and 0.75 or 0.55) / ctx.Speed
		flash(lane, windup, RED, 0.2)
		ctx.Azusa.Charge(windup)
		ctx.Azusa.Play("DashCut", windup + 0.35)
		ctx.Azusa.Trail(true)
		task.delay(windup - 0.45, function()
			if target.Parent then
				ctx.Kit.Warn(target, "Tap", 0.45)
			end
		end)
		if not pause(windup, ctx) then
			lane:Destroy()
			ctx.Azusa.Trail(false)
			return false
		end
		fade(lane, 0.2)
		local model = ctx.Azusa.Model()
		local height = model:GetAttribute("Height") or 3
		for k = 0, 3 do
			local p = from:Lerp(to, k / 3) + Vector3.new(0, height, 0)
			model:PivotTo(CFrame.lookAt(p, p + dir))
			ctx.Azusa.Afterimage(0.4)
		end
		ctx.Azusa.Blink(to, to + dir)
		-- an X of cuts hangs where she passed
		local mid = (from + to) / 2 + Vector3.new(0, 3.5, 0)
		local mark = shape("CutMark", "core", WHITE)
		mark:PivotTo(CFrame.lookAt(mid, mid + Vector3.new(-dir.Z, 0, dir.X)) * CFrame.Angles(0, 0, math.rad(step * 25)))
		fade(mark, 0.7, 1.3)
		ctx.FX("Shake", { At = to, Power = 0.4 })
		for _, char in ctx.Kit.Fighters() do
			local cr = rootOf(char)
			if cr then
				local p = Vector3.new(cr.Position.X, FLOOR, cr.Position.Z)
				local t = math.clamp((p - from):Dot(to - from) / (length * length), 0, 1)
				if (p - from:Lerp(to, t)).Magnitude < 4.5 and cr.Position.Y < FLOOR + 10 then
					if hit(ctx, char, 20, "AzusaRush", { Deflect = "Tap" }) == "Deflected" and char == target then
						ctx.Azusa.Trail(false)
						ctx.Azusa.Play("Stagger", 1.4)
						ctx.Exposed(1.8)
						return true
					end
				end
			end
		end
		if not pause(0.22, ctx) then
			break
		end
	end
	ctx.Azusa.Trail(false)
	return true
end

-- ---------------------------------------------------------------------------------------------------------- Petal Requiem
function A.Bloom(ctx, target)
	ctx.Say("Bloom", "My finisher: Petal Requiem! Keep running, and dash through the last wave!", { "Petal Requiem!", "Full bloom!" })
	ctx.Azusa.MoveTo(Vector3.new(0, FLOOR, 0), 0.6)
	ctx.Azusa.Play("Summon", 2.4)
	ctx.Azusa.Charge(2)
	ctx.FX("Sky", { On = true })
	-- the spirit blade rises behind her
	local blades = { shape("SpiritBlade", "glass", PINK), shape("SpiritBlade", "aura", WHITE) }
	local low, up = CFrame.new(0, -40, -6), CFrame.new(0, 70, -6) * CFrame.Angles(0, math.rad(30), 0)
	local function move(from, to, seconds, ease)
		task.spawn(function()
			local start = os.clock()
			while os.clock() - start < seconds do
				local t = (os.clock() - start) / seconds
				for _, m in blades do
					if m.Parent then
						m:PivotTo(from:Lerp(to, ease(t)))
					end
				end
				RunService.Heartbeat:Wait()
			end
		end)
	end
	local function cleanup()
		for _, m in blades do
			m:Destroy()
		end
		ctx.FX("Sky", { On = false })
	end
	for _, m in blades do
		m:PivotTo(low)
	end
	move(low, up, 1.6, function(t)
		return 1 - (1 - t) ^ 3
	end)
	if not pause(2, ctx) then
		cleanup()
		return false
	end
	-- pillars chase the target
	for i = 1, 9 do
		local r = rootOf(target)
		if not r then
			break
		end
		local at = inArena(r.Position) + Vector3.new(0, 0.07, 0)
		local inner, outer = shape("Sigil", "core", RED), shape("SigilOuter", "core", RED)
		inner:ScaleTo(7)
		outer:ScaleTo(7)
		inner:PivotTo(CFrame.new(at))
		outer:PivotTo(CFrame.new(at + Vector3.new(0, 0.02, 0)))
		spin(inner, 2)
		spin(outer, -1.4)
		local delay = math.max(0.55, 0.9 - i * 0.04) / ctx.Speed
		flash(inner, delay, RED, 0.05)
		flash(outer, delay, RED, 0.05)
		task.delay(delay, function()
			fade(inner, 0.2, 1.2)
			fade(outer, 0.2, 1.2)
			if ctx.Stopped() then
				return
			end
			for _, style in { "aura", "core" } do
				local pillar = shape("BloomPillar", style, style == "core" and WHITE or PINK)
				pillar:ScaleTo(style == "core" and 0.42 or 0.5)
				pillar:PivotTo(CFrame.new(at))
				fade(pillar, style == "core" and 0.4 or 0.55, style == "aura" and 1.2 or nil)
			end
			burst(at + Vector3.new(0, 2, 0), 0.9)
			for _, char in ctx.Kit.Fighters() do
				local cr = rootOf(char)
				if cr and flatDistance(cr.Position, at) < 7 and cr.Position.Y < FLOOR + 14 then
					hit(ctx, char, 16, "AzusaBloom")
				end
			end
		end)
		if not pause(0.42 / ctx.Speed, ctx) then
			break
		end
	end
	if not pause(0.8, ctx) then
		cleanup()
		return false
	end
	-- the blade falls: a tall ring wave runs out from the middle (dash through it)
	ctx.Say(nil, "Fall!")
	move(up, CFrame.new(0, 34, -6) * CFrame.Angles(0, math.rad(30), 0), 0.35, function(t)
		return t * t
	end)
	if not pause(0.35, ctx) then
		cleanup()
		return false
	end
	ctx.FX("ImpactFrame", { Strong = true })
	ctx.FX("Shake", { At = Vector3.zero, Power = 1.6 })
	shockwave(Vector3.new(0, FLOOR + 0.1, 0), 14, 0.6)
	burst(Vector3.new(0, 3, 0), 2.2)
	for _, m in blades do
		fade(m, 1.2)
	end
	thornRing(ctx, Vector3.new(0, FLOOR, 0), 48, 30, 36, "AzusaRequiem")
	ctx.FX("Sky", { On = false })
	return true
end

return A
