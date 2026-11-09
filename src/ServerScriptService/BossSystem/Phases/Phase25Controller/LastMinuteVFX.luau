-- LastMinuteVFX: the Phase 2.5 Last Minute presentation (the prelude, the clock and the sweeps). It was an inline
-- block in Phase25Controller; Prelude / Clock / Sweep are what the controller calls.
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
 
 
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Placement = require(BossSystem.Encounter.ArenaPlacement)

local GOLD = Color3.fromRGB(255, 204, 38)
local CYAN = Color3.fromRGB(152, 221, 255)
local HOT = Color3.fromRGB(255, 244, 190)
local TAU = math.pi * 2
local random = Random.new()
 
local INTENSITY = Config.LastMinuteVFXIntensity or 1
local STAGE_COLORS =
	{ GOLD, GOLD:Lerp(HOT, 0.25), GOLD:Lerp(HOT, 0.55), GOLD:Lerp(CYAN, 0.4), CYAN:Lerp(HOT, 0.35) }
local FADE = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
local api = {}

local function n(count)
	return math.max(1, math.floor(count * INTENSITY + 0.5))
end
local function ease(t)
	return 1 - (1 - t) ^ 3
end
local function lerpAlpha(a, f)
	return a + (1 - a) * f
end
local function stageColor(stage)
	return STAGE_COLORS[math.clamp(stage, 1, #STAGE_COLORS)]
end
local function fadeSize(start)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, start), NumberSequenceKeypoint.new(1, 0) })
end
local function alive(actor)
	local h = actor and actor:FindFirstChildOfClass("Humanoid")
	return actor and actor.Parent and h and h.Health > 0 and not actor:GetAttribute("EncounterEnded")
end
local function floorY(root)
	local ground = Placement.GroundPoint(root.Position, { Margin = 2, Clamp = true })
	return ground and ground.Y or root.Position.Y - 2.9
end
local function fxPart(cast, name, frame, size, color, alpha)
	local part = Effects.AcquirePart()
	part.Name = name
	part.CFrame = frame
	part.Size = size
	part.Color = color
	part.Transparency = alpha
	part.Material = Enum.Material.Neon
	part:SetAttribute("TimeStopExempt", true)
	part.Parent = Runtime.Effects
	cast:Add(part)
	return part
end
local function dropPart(cast, part)
	cast.objects[part] = nil
	Effects.Release(part)
end
local function destroy(cast, object)
	cast.objects[object] = nil
	object:Destroy()
end
local function emitter(parent, cast, name, props)
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Rate = 0
	e.LightEmission = 1
	e.LockedToPart = false
	e.Rotation = NumberRange.new(0, 360)
	for key, value in pairs(props) do
		e[key] = value
	end
	e.Parent = parent
	cast:Add(e)
	return e
end

local function newTriangle(cast, color)
	local bars = {}
	for i = 1, 3 do
		bars[i] = fxPart(cast, "LastMinuteSigil", CFrame.identity, Vector3.new(0.22, 0.1, 1), color, 1)
	end
	return bars
end
local function placeTriangle(bars, center, radius, rotation, alpha)
	local vertices = {}
	for i = 1, 3 do
		local theta = rotation + (i - 1) * TAU / 3
		vertices[i] = center + Vector3.new(math.cos(theta) * radius, 0, math.sin(theta) * radius)
	end
	for i, bar in ipairs(bars) do
		local a, b = vertices[i], vertices[i % 3 + 1]
		bar.Size = Vector3.new(0.22, 0.1, (b - a).Magnitude + 0.22)
		bar.CFrame = CFrame.lookAt((a + b) * 0.5, b)
		bar.Transparency = alpha
	end
end

 
 
local SEGMENTS = 28
local function newRing(cast)
	local anchor = fxPart(cast, "LastMinuteRing", CFrame.identity, Vector3.one, GOLD, 1)
	local points, beams = {}, {}
	for index = 1, SEGMENTS do
		local point = Instance.new("Attachment")
		point.Parent = anchor
		points[index] = point
	end
	for index = 1, SEGMENTS do
		local beam = Instance.new("Beam")
		beam.Attachment0 = points[index]
		beam.Attachment1 = points[index % SEGMENTS + 1]
		beam.LightEmission = 1
		beam.FaceCamera = true
		beam.Segments = 1
		beam.Enabled = false
		beam:SetAttribute("TimeStopExempt", true)
		beam.Parent = anchor
		beams[index] = beam
	end
	return { Anchor = anchor, Points = points, Beams = beams, Live = false }
end
local function placeRing(ring, t)
	local radius = ring.From + (ring.To - ring.From) * ease(t)
	for index, point in ipairs(ring.Points) do
		local theta = (index - 1) * TAU / SEGMENTS
		point.Position = Vector3.new(math.cos(theta) * radius, math.sin(theta) * radius, 0)
	end
	local width = ring.Width * (1 - t * 0.7)
	local alpha = NumberSequence.new(ring.Alpha + (1 - ring.Alpha) * t * t)
	for _, beam in ipairs(ring.Beams) do
		beam.Width0 = width
		beam.Width1 = width
		beam.Transparency = alpha
	end
end
local function ringBank(cast, size)
	local rings, live, bank = {}, {}, {}
	for i = 1, size do
		rings[i] = newRing(cast)
	end
	 
	function bank.Fire(frame, color, from, to, life, width, alpha)
		local ring
		for _, candidate in ipairs(rings) do
			if not candidate.Live then
				ring = candidate
				break
			end
		end
		if not ring then
			return false
		end
		ring.Live = true
		ring.Age = 0
		ring.Life = life
		ring.From = from
		ring.To = to
		ring.Width = width
		ring.Alpha = alpha or 0.1
		ring.Anchor.CFrame = frame
		local sequence = ColorSequence.new(color)
		for _, beam in ipairs(ring.Beams) do
			beam.Color = sequence
			beam.Enabled = true
		end
		placeRing(ring, 0)
		table.insert(live, ring)
		return true
	end
	function bank.Floor(position, color, from, to, life, width, alpha)
		return bank.Fire(
			CFrame.new(position) * CFrame.Angles(-math.pi / 2, 0, 0),
			color,
			from,
			to,
			life,
			width,
			alpha
		)
	end
	function bank.Step(dt)
		for i = #live, 1, -1 do
			local ring = live[i]
			ring.Age += dt
			local t = math.clamp(ring.Age / ring.Life, 0, 1)
			placeRing(ring, t)
			if t >= 1 then
				for _, beam in ipairs(ring.Beams) do
					beam.Enabled = false
				end
				ring.Live = false
				table.remove(live, i)
			end
		end
	end
	return bank
end
local banks = setmetatable({}, { __mode = "k" })
local function sharedBank(cast)
	local bank = banks[cast]
	if bank then
		return bank
	end
	bank = ringBank(cast, 12)
	banks[cast] = bank
	cast:Step(function(dt)
		bank.Step(dt)
		return cast:Alive()
	end)
	return bank
end

 
local function buildDial(gui)
	local function circle(size, fillAlpha, thickness, strokeAlpha)
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.fromScale(size, size)
		frame.BackgroundColor3 = Color3.fromRGB(70, 42, 6)
		frame.BackgroundTransparency = fillAlpha
		frame.BorderSizePixel = 0
		frame.ZIndex = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = frame
		local line = Instance.new("UIStroke")
		line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		line.Color = GOLD
		line.Thickness = thickness
		line.Transparency = strokeAlpha
		line.Parent = frame
		frame.Parent = gui
		return { Frame = frame, Stroke = line, FillAlpha = fillAlpha, StrokeAlpha = strokeAlpha }
	end
	local dial =
		{ Rings = { circle(0.97, 0.9, 10, 0.25), circle(0.86, 1, 3, 0.55), circle(0.56, 1, 5, 0.45) }, Ticks = {} }
	for i = 0, 59 do
		local major = i % 5 == 0
		local theta = i * TAU / 60
		local tick = Instance.new("Frame")
		tick.AnchorPoint = Vector2.new(0.5, 0.5)
		tick.Position = UDim2.fromScale(0.5 + math.sin(theta) * 0.45, 0.5 - math.cos(theta) * 0.45)
		tick.Size = major and UDim2.fromOffset(9, 36) or UDim2.fromOffset(4, 16)
		tick.Rotation = math.deg(theta)
		tick.BackgroundColor3 = GOLD
		tick.BackgroundTransparency = major and 0.2 or 0.5
		tick.BorderSizePixel = 0
		tick.ZIndex = 0
		tick.Parent = gui
		dial.Ticks[i] = { Frame = tick, Base = major and 0.2 or 0.5 }
	end
	return dial
end

 
 
function api.Prelude(actor, cast, duration)
	local root = actor:FindFirstChild("HumanoidRootPart")
	if not root or duration <= 0 then
		return
	end
	local bank = sharedBank(cast)
	local gold, cyan, hot = newTriangle(cast, GOLD), newTriangle(cast, CYAN), newTriangle(cast, HOT)
	local aura = Instance.new("Highlight")
	aura.Name = "LastMinuteGatherAura"
	aura.Adornee = actor
	aura.FillColor = GOLD
	aura.OutlineColor = GOLD
	aura.FillTransparency = 0.9
	aura.OutlineTransparency = 0.6
	aura.Parent = Runtime.Effects
	cast:Add(aura)
	local embers = emitter(root, cast, "LastMinuteGatherEmbers", {
		Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(4, 10),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(25, 25),
		Acceleration = Vector3.new(0, 6, 0),
		Color = ColorSequence.new(GOLD, HOT),
		Size = fadeSize(0.55),
		Transparency = FADE,
	})
	local motes = {}
	for index = 1, n(16) do
		local d = random:NextUnitVector()
		motes[index] = {
			Part = fxPart(
				cast,
				"LastMinuteGatherMote",
				CFrame.identity,
				Vector3.new(0.16, 0.16, 0.7),
				index % 2 == 0 and GOLD or CYAN,
				1
			),
			Direction = Vector3.new(d.X, math.abs(d.Y) * 0.7 + 0.1, d.Z).Unit,
			Distance = random:NextNumber(11, 19),
			Seed = random:NextNumber(),
		}
	end
	local beats = { 0, 0.3, 0.6, 0.85 }
	local nextBeat = 1
	local began = cast:Now()
	local ground = floorY(root)
	local nextFloor = began + 0.15
	cast:Step(function(_, now)
		if not cast:Alive() or not alive(actor) then
			return false
		end
		local age = now - began
		local t = math.clamp(age / duration, 0, 1)
		if now >= nextFloor then
			nextFloor = now + 0.15
			ground = floorY(root)
		end
		local rootPos = root.Position
		local center = Vector3.new(rootPos.X, ground + 0.15, rootPos.Z)
		local radius = 13 - 6.5 * ease(t)
		local spin = age * (1.2 + t * 4)
		local alpha = 0.85 - 0.45 * t
		placeTriangle(gold, center, radius, spin, alpha)
		placeTriangle(cyan, center, radius, -spin + math.pi / 3, math.min(1, alpha + 0.08))
		placeTriangle(hot, center, radius * 1.45, -spin * 0.5, math.min(1, alpha + 0.2))
		while beats[nextBeat] and t >= beats[nextBeat] do
			bank.Floor(
				center + Vector3.new(0, 0.05, 0),
				nextBeat % 2 == 1 and GOLD or CYAN,
				16,
				3,
				0.55 + nextBeat * 0.05,
				0.3 + nextBeat * 0.12,
				0.2
			)
			nextBeat += 1
		end
		embers.Rate = (6 + 60 * t * t) * INTENSITY
		aura.FillTransparency = math.clamp(0.9 - 0.35 * t + 0.04 * math.sin(age * 9), 0, 1)
		aura.OutlineTransparency = math.clamp(0.6 - 0.55 * t, 0, 1)
		local target = rootPos + Vector3.new(0, 1, 0)
		for _, mote in ipairs(motes) do
			local phase = (age * (1 + t * 1.4) * 0.9 + mote.Seed) % 1
			local position = target + mote.Direction * (mote.Distance * (1 - phase) ^ 2)
			mote.Part.CFrame = CFrame.lookAt(position, position - mote.Direction)
			mote.Part.Transparency = 1 - 0.85 * math.sin(phase * math.pi)
		end
		return true
	end)
end

 
 
function api.Clock(actor, cast, parts)
	local root = actor:FindFirstChild("HumanoidRootPart")
	local face, hands, center = parts.Face, parts.Hands, parts.Center
	if not root or not face or not hands or not center then
		return nil
	end
	local labels = parts.Labels or {}
	local scale = parts.Scale or 1
	local radius = parts.Radius or 50
	local wide = math.max(scale, 0.5)
	local bank = sharedBank(cast)

	local dials = {}
	for _, child in ipairs(face:GetChildren()) do
		if child:IsA("SurfaceGui") then
			table.insert(dials, buildDial(child))
		end
	end
	local uiScales = {}
	for _, data in ipairs(labels) do
		local ui = Instance.new("UIScale")
		ui.Parent = data.Label
		uiScales[data] = ui
	end

	 
	local rim = {}
	for index, attachment in ipairs(parts.Attachments or {}) do
		if index % 2 == 1 then
			rim[#rim + 1] = emitter(attachment, cast, "LastMinuteRimShards", {
				Lifetime = NumberRange.new(0.6, 1.4),
				Speed = NumberRange.new(14 * scale, 36 * scale),
				Drag = 1.5,
				SpreadAngle = Vector2.new(180, 180),
				RotSpeed = NumberRange.new(-300, 300),
				Color = ColorSequence.new(HOT, GOLD),
				Size = fadeSize(2.2 * scale + 0.2),
				Transparency = FADE,
			})
		end
	end
	local core = emitter(center, cast, "LastMinuteCore", {
		Rate = 8 * INTENSITY,
		Lifetime = NumberRange.new(0.5, 1.1),
		Speed = NumberRange.new(3 * scale + 1, 9 * scale + 2),
		SpreadAngle = Vector2.new(180, 180),
		Color = ColorSequence.new(HOT, GOLD),
		Size = fadeSize(1.2 * scale + 0.2),
		Transparency = FADE,
	})
	local tip = Instance.new("Attachment")
	tip.Name = "LastMinuteSecondHandTip"
	tip.Parent = face
	cast:Add(tip)
	local sparks = emitter(tip, cast, "LastMinuteTickSparks", {
		Lifetime = NumberRange.new(0.3, 0.7),
		Speed = NumberRange.new(10 * scale + 4, 26 * scale + 8),
		Drag = 3,
		SpreadAngle = Vector2.new(180, 180),
		Color = ColorSequence.new(HOT, GOLD),
		Size = fadeSize(1.4 * scale + 0.2),
		Transparency = FADE,
	})
	local embers = emitter(root, cast, "LastMinuteEmbers", {
		Rate = 10 * INTENSITY,
		Lifetime = NumberRange.new(0.8, 1.5),
		Speed = NumberRange.new(3, 9),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(40, 40),
		Acceleration = Vector3.new(0, 5, 0),
		Color = ColorSequence.new(GOLD, HOT),
		Size = fadeSize(0.5),
		Transparency = FADE,
	})
	local glitch = emitter(root, cast, "LastMinuteEchoGlitch", {
		Lifetime = NumberRange.new(0.3, 0.6),
		Speed = NumberRange.new(8, 16),
		Drag = 5,
		SpreadAngle = Vector2.new(180, 180),
		Color = ColorSequence.new(HOT, CYAN),
		Size = fadeSize(0.6),
		Transparency = FADE,
	})

	 
	local aura = Instance.new("Highlight")
	aura.Name = "LastMinuteAura"
	aura.Adornee = actor
	aura.FillColor = GOLD
	aura.OutlineColor = GOLD
	aura.FillTransparency = 0.84
	aura.OutlineTransparency = 0.4
	aura.Parent = Runtime.Effects
	cast:Add(aura)
	local gold, cyan, hot = newTriangle(cast, GOLD), newTriangle(cast, CYAN), newTriangle(cast, HOT)

	local began = cast:Now()
	local stage = 1
	local ground = floorY(root)
	local nextFloor = began
	local flashUntil, glitchUntil, pulseUntil = 0, 0, 0
	local nextGlitch = began + random:NextNumber(0.6, 1.2)
	local shatterAt = nil
	local ghosts, labelFlash, tickFlash = {}, {}, {}
	local vfx = {}

	local function floorPosition()
		return Vector3.new(root.Position.X, ground + 0.2, root.Position.Z)
	end
	local function applyStage(newStage)
		stage = newStage
		local color = stageColor(stage)
		for _, dial in ipairs(dials) do
			for _, ring in ipairs(dial.Rings) do
				ring.Stroke.Color = color
			end
			for _, tick in pairs(dial.Ticks) do
				tick.Frame.BackgroundColor3 = color
			end
		end
		for _, data in ipairs(labels) do
			data.Label.TextColor3 = color
		end
		embers.Color = ColorSequence.new(color, HOT)
		core.Color = ColorSequence.new(HOT, color)
	end
	applyStage(1)

	cast:Step(function(dt, now)
		if not alive(actor) then
			return false
		end
		local elapsed = now - began
		local current = actor:GetAttribute("LastMinuteStage") or stage
		if current > stage then
			applyStage(current)
			flashUntil = now + 0.14
			bank.Floor(floorPosition(), HOT, 3, 30, 0.7, 1, 0.1)
		end
		local base = stageColor(stage)
		if now >= nextFloor then
			nextFloor = now + 0.15
			ground = floorY(root)
		end
		local fade = shatterAt and math.clamp((now - shatterAt) / 0.45, 0, 1) or 0

		 
		local glitching = now < glitchUntil
		if stage >= 4 and not shatterAt and not glitching and now >= nextGlitch then
			glitching = true
			glitchUntil = now + 0.09
			nextGlitch = now + random:NextNumber(0.35, 1)
		end
		local flash = now < flashUntil
		local pulse = math.clamp((pulseUntil - now) / 0.15, 0, 1)
		local color = flash and HOT or glitching and CYAN or base
		aura.FillColor = color
		aura.OutlineColor = color
		local fill = 0.9 - 0.06 * stage - 0.18 * pulse
		local fillAlpha = math.clamp(flash and 0.35 or glitching and fill - 0.15 or fill, 0, 1)
		local outlineAlpha = math.clamp(
			flash and 0 or glitching and 0.05 or 0.45 - 0.07 * stage + 0.12 * math.sin(elapsed * (6 + stage * 2)),
			0,
			1
		)
		aura.FillTransparency = lerpAlpha(fillAlpha, fade)
		aura.OutlineTransparency = lerpAlpha(outlineAlpha, fade)
		embers.Rate = (8 + stage * 9) * INTENSITY * (1 - fade)
		core.Rate = (6 + stage * 5) * INTENSITY * (1 - fade)

		 
		local rp = root.Position
		local sigilCenter = Vector3.new(rp.X, ground + 0.15, rp.Z)
		local sigilRadius = 5.5 + stage * 1.1 + 0.3 * math.sin(elapsed * 2.2)
		local spin = elapsed * (0.8 + stage * 0.45)
		local sigilAlpha = lerpAlpha(glitching and 0.45 or 0.7 + 0.08 * math.sin(elapsed * (4 + stage * 2)), fade)
		placeTriangle(gold, sigilCenter, sigilRadius, spin, sigilAlpha)
		placeTriangle(cyan, sigilCenter, sigilRadius, -spin + math.pi / 3, math.min(1, sigilAlpha + 0.08))
		placeTriangle(
			hot,
			sigilCenter,
			sigilRadius * 1.35,
			-spin * 0.6,
			stage >= 4 and math.min(1, sigilAlpha + 0.1) or 1
		)

		 
		for i = #ghosts, 1, -1 do
			local g = ghosts[i]
			local k = (now - g.Born) / g.Life
			if k >= 1 then
				dropPart(cast, g.Part)
				table.remove(ghosts, i)
			else
				g.Part.CFrame = face.CFrame * g.Local
				g.Part.Transparency = 0.35 + 0.65 * k
			end
		end

		 
		for data, start in pairs(labelFlash) do
			local k = 1 - (now - start) / 0.5
			if k <= 0 then
				labelFlash[data] = nil
				data.Label.TextColor3 = base
				uiScales[data].Scale = 1
			else
				data.Label.TextColor3 = base:Lerp(HOT, k)
				uiScales[data].Scale = 1 + 0.35 * k
			end
		end
		for index, start in pairs(tickFlash) do
			local k = 1 - (now - start) / 0.4
			for _, dial in ipairs(dials) do
				local tick = dial.Ticks[index]
				if k <= 0 then
					tick.Frame.BackgroundColor3 = base
					tick.Frame.BackgroundTransparency = tick.Base
				else
					tick.Frame.BackgroundColor3 = base:Lerp(HOT, k)
					tick.Frame.BackgroundTransparency = tick.Base * (1 - k)
				end
			end
			if k <= 0 then
				tickFlash[index] = nil
			end
		end

		 
		for _, dial in ipairs(dials) do
			dial.Rings[1].Stroke.Transparency = lerpAlpha(0.22 + 0.12 * math.sin(elapsed * (3 + stage * 1.5)), fade)
			if fade > 0 then
				for index, ring in ipairs(dial.Rings) do
					ring.Frame.BackgroundTransparency = lerpAlpha(ring.FillAlpha, fade)
					if index > 1 then
						ring.Stroke.Transparency = lerpAlpha(ring.StrokeAlpha, fade)
					end
				end
				for _, tick in pairs(dial.Ticks) do
					tick.Frame.BackgroundTransparency = lerpAlpha(tick.Base, fade)
				end
			end
		end
		return true
	end)

	 
	function vfx.Tick(tickCount, stageIndex)
		local now = cast:Now()
		local color = stageColor(stageIndex)
		local numeral = (tickCount - 1) % 12 + 1
		for _, data in ipairs(labels) do
			if data.Index == numeral then
				labelFlash[data] = now
			end
		end
		tickFlash[(tickCount % 12) * 5] = now
		pulseUntil = now + 0.15
		local second = hands[1]
		if second then
			local angle = -tickCount * TAU / 12
			local length = second.Size.Y
			tip.Position = Vector3.new(-math.sin(angle) * length, math.cos(angle) * length, 0.15)
			sparks:Emit(n(8 + stageIndex * 3))
			local count = n(4)
			for j = 1, count do
				if #ghosts >= 48 then
					break
				end
				local a = angle + TAU / 12 * (1 - j / (count + 1))
				local ghost = fxPart(cast, "LastMinuteHandAfterimage", face.CFrame, second.Size, HOT, 0.4)
				table.insert(ghosts, {
					Part = ghost,
					Born = now,
					Life = 0.4,
					Local = CFrame.Angles(0, 0, a) * CFrame.new(0, second.Size.Y * 0.5, 0.15),
				})
			end
		end
		core:Emit(n(5 + stageIndex * 2))
		bank.Floor(floorPosition(), color, 2.5, 9 + stageIndex * 3.5, 0.55, 0.4 + 0.1 * stageIndex, 0.2)
		bank.Fire(face.CFrame, color, radius * 0.12, radius * 0.95, 0.5, (0.7 + 0.12 * stageIndex) * wide, 0.25)
	end

	 
	function vfx.Revolution(revolution, final)
		local now = cast:Now()
		flashUntil = now + 0.16
		for _, source in ipairs(rim) do
			source:Emit(n(3 + revolution * 2) * (final and 2 or 1))
		end
		for _, data in ipairs(labels) do
			labelFlash[data] = now
		end
		bank.Fire(face.CFrame, HOT, radius * 0.1, radius * 1.2, 0.7, 1.8 * wide, 0.1)
		bank.Floor(floorPosition(), HOT, 4, 24 + revolution * 5, 0.85, 1, 0.1)
		cast:Schedule(0.14, function()
			if cast:Alive() and not shatterAt then
				bank.Floor(floorPosition(), stageColor(revolution), 3, 18 + revolution * 4, 0.7, 0.7, 0.2)
			end
		end)
	end

	 
	function vfx.Shatter()
		local now = cast:Now()
		shatterAt = now
		flashUntil = now + 0.3
		for _, source in ipairs(rim) do
			source:Emit(n(16))
		end
		core:Emit(n(90))
		for _, data in ipairs(labels) do
			labelFlash[data] = now
		end
		bank.Fire(face.CFrame, HOT, radius * 0.1, radius * 1.6, 0.8, 2.4 * wide, 0.05)
		bank.Floor(floorPosition(), HOT, 4, 60, 1, 1.4, 0.05)
		cast:Schedule(0.12, function()
			if cast:Alive() then
				bank.Fire(face.CFrame, GOLD, radius * 0.1, radius * 1.9, 0.9, 1.6 * wide, 0.2)
			end
		end)
		cast:Schedule(0.26, function()
			if cast:Alive() then
				bank.Fire(face.CFrame, CYAN, radius * 0.1, radius * 2.2, 1, 1.2 * wide, 0.3)
			end
		end)
	end

	 
	function vfx.Echo()
		glitchUntil = cast:Now() + 0.12
		glitch:Emit(n(14))
		bank.Floor(floorPosition(), CYAN, 3, 15, 0.4, 0.45, 0.15)
	end

	return vfx
end

 
 
function api.Sweep(cast, bar, warning)
	local fx = { Released = false, Done = false }
	local bank = sharedBank(cast)
	local began = cast:Now()
	local ghosts = {}
	local halo, sparks
	 
	cast:Step(function(_, now)
		if fx.Released or fx.Done or not bar.Parent then
			return false
		end
		local t = math.clamp((now - began) / math.max(warning, 0.01), 0, 1)
		local blink = math.max(0, math.sin((now - began) * (4 + t * t * 10)))
		bar.Transparency = 0.8 - 0.22 * t - 0.12 * blink
		bar.Color = t > 0.85 and HOT or GOLD
		return true
	end)
	function fx:Release()
		if self.Released then
			return
		end
		self.Released = true
		bar.Color = GOLD
		bank.Floor(bar.Position - Vector3.new(0, 0.8, 0), HOT, 2, 14, 0.4, 0.5, 0.15)
		halo = fxPart(
			cast,
			"LastMinuteSweepHalo",
			bar.CFrame,
			Vector3.new(bar.Size.X * 3.2, bar.Size.Y * 0.8, bar.Size.Z),
			GOLD,
			0.82
		)
		sparks = emitter(bar, cast, "LastMinuteSweepEmbers", {
			Rate = 140 * INTENSITY,
			Lifetime = NumberRange.new(0.3, 0.7),
			Speed = NumberRange.new(3, 9),
			EmissionDirection = Enum.NormalId.Top,
			SpreadAngle = Vector2.new(25, 25),
			Acceleration = Vector3.new(0, 4, 0),
			Color = ColorSequence.new(HOT, GOLD),
			Size = fadeSize(0.9),
			Transparency = FADE,
		})
		local nextGhost = 0
		cast:Step(function(_, now)
			if not self.Done and bar.Parent then
				halo.CFrame = bar.CFrame
				if now >= nextGhost then
					nextGhost = now + 0.035
					table.insert(
						ghosts,
						{
							Part = fxPart(cast, "LastMinuteSweepAfterglow", bar.CFrame, bar.Size, GOLD, 0.6),
							Born = now,
						}
					)
				end
			end
			for i = #ghosts, 1, -1 do
				local g = ghosts[i]
				local k = (now - g.Born) / 0.4
				if k >= 1 then
					dropPart(cast, g.Part)
					table.remove(ghosts, i)
				else
					g.Part.Transparency = 0.6 + 0.4 * k
				end
			end
			return not self.Done or #ghosts > 0
		end)
	end
	function fx:Hit(position)
		bank.Floor(position + Vector3.new(0, 0.2, 0), HOT, 1, 9, 0.3, 0.5, 0.1)
	end
	 
	function fx:Finish()
		if self.Done then
			return
		end
		self.Done = true
		if sparks then
			destroy(cast, sparks)
			sparks = nil
		end
		if halo then
			dropPart(cast, halo)
			halo = nil
		end
	end
	return fx
end

return api
