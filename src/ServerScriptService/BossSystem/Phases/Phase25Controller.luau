local BossSystem = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Story = require(BossSystem.Encounter.EncounterStory)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Locomotion = require(BossSystem.Boss.BossLocomotion)
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local Players = game:GetService("Players")
local random = Random.new()
local api = {}
local records = setmetatable({}, { __mode = "k" })
local GOLD = Color3.fromRGB(255, 204, 38)
local function alive(actor)
	local h = actor and actor:FindFirstChildOfClass("Humanoid")
	return actor and actor.Parent and h and h.Health > 0 and not actor:GetAttribute("EncounterEnded")
end
local function send(kind, data)
	local remote = game.ReplicatedStorage:FindFirstChild("BossCombatEffects")
	if remote then
		remote:FireAllClients(kind, data)
	end
end
local function recordFor(actor)
	local record = records[actor]
	if not record then
		record = { Seen = setmetatable({}, { __mode = "k" }), Previews = {} }
		records[actor] = record
	end
	return record
end
local function addPart(cast, name, frame, size, color, alpha)
	local part = Effects.AcquirePart()
	part.Name = name
	part.CFrame = frame
	part.Size = size
	part.Color = color
	part.Transparency = alpha
	part.Parent = Runtime.Effects
	cast:Add(part)
	return part
end

 
local LastMinuteVFX = require(script.Parent.LastMinuteVFX)

function api.Start(actor)
	return recordFor(actor)
end
local CYAN = Color3.fromRGB(152, 221, 255)
local HOT = Color3.fromRGB(255, 244, 190)
local TAU = math.pi * 2

local function newTriangle(cast, name, color)
	local bars = {}
	for i = 1, 3 do
		local bar = addPart(cast, name, CFrame.identity, Vector3.new(0.22, 0.1, 1), color, 1)
		bar:SetAttribute("TimeStopExempt", true)
		bars[i] = bar
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

local function newPulse(cast, name, color, position, fromRadius, toRadius, life, startAlpha)
	local part = addPart(cast, name, CFrame.new(position), Vector3.new(0.14, 1, 1), color, startAlpha)
	part.Shape = Enum.PartType.Cylinder
	part:SetAttribute("TimeStopExempt", true)
	return {
		Part = part,
		Cast = cast,
		Position = position,
		From = fromRadius,
		To = toRadius,
		Life = life,
		Alpha = startAlpha,
		Age = 0,
	}
end
local function stepPulse(pulse, dt)
	if not pulse.Part then
		return false
	end
	pulse.Age += dt
	local t = math.clamp(pulse.Age / pulse.Life, 0, 1)
	local radius = pulse.From + (pulse.To - pulse.From) * (1 - (1 - t) ^ 3)
	pulse.Part.Size = Vector3.new(0.14, radius * 2, radius * 2)
	pulse.Part.CFrame = CFrame.new(pulse.Position) * CFrame.Angles(0, 0, math.pi * 0.5)
	pulse.Part.Transparency = pulse.Alpha + (1 - pulse.Alpha) * t
	if t >= 1 then
		pulse.Cast.objects[pulse.Part] = nil
		Effects.Release(pulse.Part)
		pulse.Part = nil
		return false
	end
	return true
end
local function floorPoint(root, fallbackDrop)
	local ground = Placement.GroundPoint(root.Position, { Margin = 2, Clamp = true })
	return ground and ground.Y or root.Position.Y - fallbackDrop
end

function api.PlayFalseFutureWindup(actor, duration)
	if not alive(actor) then
		return false
	end
	local root = actor:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local fade = 0.3
	local cast = Effects.NewCast(actor, "FalseFutureWindup", duration + fade + 0.2)
	cast.TimeStopExempt = true
	local goldTri = newTriangle(cast, "FalseFutureWindupSigil", GOLD)
	local cyanTri = newTriangle(cast, "FalseFutureWindupSigil", CYAN)
	local began = cast:Now()
	local floorY = floorPoint(root, 2.9)
	cast:Step(function(_, now)
		if not alive(actor) then
			cast:Dispose()
			return false
		end
		local age = now - began
		local t = math.clamp(age / duration, 0, 1)
		local eased = 1 - (1 - t) ^ 3
		local out = math.clamp((age - duration) / fade, 0, 1)
		local alpha = 1 - 0.65 * eased
		alpha = alpha + (1 - alpha) * out
		local center = Vector3.new(root.Position.X, floorY + 0.15, root.Position.Z)
		local radius = 11 - (11 - 5.2) * eased
		placeTriangle(goldTri, center, radius, age * 2.6, alpha)
		placeTriangle(cyanTri, center, radius, -age * 2.6 + math.pi / 3, math.min(1, alpha + 0.08))
		if out >= 1 then
			cast:Dispose()
			return false
		end
		return true
	end)
	return true
end

function api.ArmFalseFuture(actor)
	if
		not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or actor:GetAttribute("PhaseTransitionInProgress")
		or actor:GetAttribute("IsGoldenClone")
		or actor:GetAttribute("IsIllusion")
	then
		return false
	end
	local record = recordFor(actor)
	if (actor:GetAttribute("FalseFutureCharges") or 0) > 0 then
		return false
	end
	local cast = Effects.NewCast(actor, "FalseFutureArmed", Config.FalseFutureMaxDuration)
	cast.TimeStopExempt = true
	record.FalseFuture = cast
	actor:SetAttribute("FalseFutureCharges", Config.FalseFutureCharges)
	actor:SetAttribute("FalseFutureUntil", workspace:GetServerTimeNow() + Config.FalseFutureMaxDuration)
	cast.OnDispose = function()
		if record.FalseFuture == cast then
			record.FalseFuture = nil
			actor:SetAttribute("FalseFutureCharges", 0)
			actor:SetAttribute("FalseFutureUntil", 0)
		end
	end

	local root = actor.HumanoidRootPart
	local total = Config.FalseFutureCharges
	local began = cast:Now()

	local aura = Instance.new("Highlight")
	aura.Name = "FalseFutureAura"
	aura.Adornee = actor
	aura.FillColor = GOLD
	aura.OutlineColor = GOLD
	aura.FillTransparency = 0.93
	aura.OutlineTransparency = 0.6
	aura.Parent = Runtime.Effects
	cast:Add(aura)

	local motes = Instance.new("ParticleEmitter")
	motes.Name = "FalseFutureMotes"
	motes.Rate = 14
	motes.Lifetime = NumberRange.new(0.7, 1.3)
	motes.Speed = NumberRange.new(0.5, 2)
	motes.SpreadAngle = Vector2.new(180, 180)
	motes.Acceleration = Vector3.new(0, 3, 0)
	motes.LightEmission = 1
	motes.LockedToPart = false
	motes.Rotation = NumberRange.new(0, 360)
	motes.RotSpeed = NumberRange.new(-120, 120)
	motes.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GOLD),
		ColorSequenceKeypoint.new(0.5, CYAN),
		ColorSequenceKeypoint.new(1, GOLD),
	})
	motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	motes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	motes.Parent = root
	cast:Add(motes)

	local burst = Instance.new("ParticleEmitter")
	burst.Name = "FalseFutureShatter"
	burst.Rate = 0
	burst.Lifetime = NumberRange.new(0.35, 0.7)
	burst.Speed = NumberRange.new(10, 18)
	burst.Drag = 6
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.LightEmission = 1
	burst.Rotation = NumberRange.new(0, 360)
	burst.RotSpeed = NumberRange.new(-300, 300)
	burst.Color = ColorSequence.new(HOT, CYAN)
	burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0) })
	burst.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	burst.Parent = root
	cast:Add(burst)
	burst:Emit(18)

	local goldTri = newTriangle(cast, "FalseFutureSigil", GOLD)
	local cyanTri = newTriangle(cast, "FalseFutureSigil", CYAN)
	local floorY = floorPoint(root, 2.9)
	local nextFloor = began + 0.15

	local shards = {}
	for i = 1, total do
		local color = i % 2 == 1 and GOLD or CYAN
		local part = addPart(cast, "FalseFutureCharge", root.CFrame, Vector3.new(0.28, 1.25, 0.28), color, 0.1)
		part:SetAttribute("TimeStopExempt", true)
		shards[i] = { Part = part, Phase = (i - 1) * TAU / total, Color = color }
	end

	local pulses = {
		newPulse(
			cast,
			"FalseFutureArmPulse",
			GOLD,
			Vector3.new(root.Position.X, floorY + 0.2, root.Position.Z),
			3,
			15,
			0.4,
			0.55
		),
	}
	local nextGlitch = began + random:NextNumber(0.6, 1.2)
	local glitchUntil = 0
	local flashUntil = 0

	cast:Step(function(dt, now)
		local charges = actor:GetAttribute("FalseFutureCharges") or 0
		if not alive(actor) or actor:GetAttribute("Phase") ~= 2.5 or charges <= 0 then
			cast:Dispose()
			return false
		end
		local elapsed = now - began
		local remaining = (actor:GetAttribute("FalseFutureUntil") or 0) - workspace:GetServerTimeNow()
		local urgent = remaining < 1.5
		if now >= nextFloor then
			nextFloor = now + 0.15
			floorY = floorPoint(root, 2.9)
		end

		local glitching = false
		if now < glitchUntil then
			glitching = true
		elseif now >= nextGlitch then
			glitching = true
			glitchUntil = now + 0.09
			nextGlitch = now + random:NextNumber(0.7, 1.5)
		end
		local flash = now < flashUntil

		local auraColor = flash and HOT or glitching and CYAN or GOLD
		aura.FillColor = auraColor
		aura.OutlineColor = auraColor
		aura.FillTransparency = flash and 0.55 or glitching and 0.8 or 0.93
		aura.OutlineTransparency = flash and 0
			or glitching and 0.1
			or 0.6 + 0.15 * math.sin(elapsed * (urgent and 18 or 3))

		local ramp = math.min(1, elapsed / 0.3)
		local orbitRadius = 9 - (9 - 3.4) * (1 - (1 - ramp) ^ 3)
		local spin = elapsed * (urgent and 4.6 or 2.2)
		local center = root.Position
		for i, shard in ipairs(shards) do
			local part = shard.Part
			if part then
				if i > charges then
					burst:Emit(12)
					flashUntil = now + 0.14
					cast.objects[part] = nil
					Effects.Release(part)
					shard.Part = nil
				else
					local angle = shard.Phase + spin
					local offset = Vector3.new(
						math.cos(angle) * orbitRadius,
						1.3 + math.sin(elapsed * 3 + i * 2) * 0.35,
						math.sin(angle) * orbitRadius
					)
					if glitching then
						offset += Vector3.new(
							random:NextNumber(-0.5, 0.5),
							random:NextNumber(-0.4, 0.4),
							random:NextNumber(-0.5, 0.5)
						)
					end
					part.CFrame = CFrame.new(center + offset) * CFrame.Angles(elapsed * 2 + i, elapsed * 3.1, i)
					part.Transparency = glitching and 0.55
						or 0.1 + 0.2 * (math.sin(elapsed * (urgent and 24 or 7) + i) + 1) * 0.5
					part.Color = glitching and (shard.Color == GOLD and CYAN or GOLD) or shard.Color
				end
			end
		end

		local jitter = glitching and Vector3.new(random:NextNumber(-0.3, 0.3), 0, random:NextNumber(-0.3, 0.3))
			or Vector3.zero
		local sigilCenter = Vector3.new(center.X, floorY + 0.15, center.Z) + jitter
		local sigilAlpha = glitching and 0.5 or 0.72 + 0.1 * math.sin(elapsed * (urgent and 14 or 4))
		local sigilRadius = 5.2 + 0.25 * math.sin(elapsed * 2)
		placeTriangle(goldTri, sigilCenter, sigilRadius, elapsed * 0.9, sigilAlpha)
		placeTriangle(cyanTri, sigilCenter, sigilRadius, -elapsed * 0.9 + math.pi / 3, math.min(1, sigilAlpha + 0.08))

		for i = #pulses, 1, -1 do
			if not stepPulse(pulses[i], dt) then
				table.remove(pulses, i)
			end
		end
		return true
	end)
	send("FalseFutureArmed", { Position = root.Position, Charges = Config.FalseFutureCharges })
	return true
end

function api.BeginFalseTelegraph(actor, name, spec)
	local entry = Metadata.Get(name)
	local charges = actor:GetAttribute("FalseFutureCharges") or 0
	if
		not entry
		or not entry.CanFalseFuture
		or entry.Ultimate
		or entry.Passive
		or entry.TimeStopOnly
		or not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or actor:GetAttribute("PhaseTransitionInProgress")
		or actor:GetAttribute("IsGoldenClone")
		or actor:GetAttribute("IsIllusion")
		or actor:GetAttribute("IsAfterimage")
		or charges <= 0
		or workspace:GetServerTimeNow() >= (actor:GetAttribute("FalseFutureUntil") or 0)
	then
		return nil
	end
	local record = recordFor(actor)
	local duration =
		math.max(spec.Duration or 0, Config.FalseFutureFakeDuration + 0.135 + Config.FalseFutureRealWarning)
	local cast = Effects.NewCast(actor, "FalseFutureCorruptedTelegraph", duration + 0.2)
	record.Previews[cast] = true
	actor:SetAttribute("FalseFutureCharges", charges - 1)
	actor:SetAttribute("FalseFutureAffectedAttacks", (actor:GetAttribute("FalseFutureAffectedAttacks") or 0) + 1)
	local handle = { Cast = cast, Duration = duration, Elapsed = 0, Ready = false }
	local generation = actor:GetAttribute("PhaseGeneration") or 0
	local revealAt = duration - Config.FalseFutureRealWarning
	local isCircle = spec.Shape == "Circle"
	local previews, locked, marks, dissolving, pulses = {}, {}, {}, {}, {}
	local realIndex = random:NextInteger(1, 3)
	local baseAngle = random:NextNumber(0, math.pi * 2)
	local baseRotation = random:NextNumber(-0.3, 0.3)
	local DISSOLVE = math.min(0.16, Config.FalseFutureRealWarning)

	for index = 1, 3 do
		local parts = {}
		for piece = 1, (spec.Shape == "Cone" and 3 or 1) do
			parts[piece] = addPart(cast, "FalseFuturePossibleWarning", CFrame.identity, Vector3.one, GOLD, 0.5)
			parts[piece]:SetAttribute("TemporalPreview", true)
			if isCircle then
				parts[piece].Shape = Enum.PartType.Cylinder
			end
		end
		previews[index] = parts
		local gui = Instance.new("BillboardGui")
		gui.Name = "FalseFutureQuestion"
		gui.Size = UDim2.fromOffset(44, 44)
		gui.StudsOffset = Vector3.new(0, 3.2, 0)
		gui.AlwaysOnTop = false
		gui.LightInfluence = 0
		gui.MaxDistance = 250
		gui.Adornee = parts[1]
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.Garamond
		label.TextScaled = true
		label.Text = "?"
		label.TextColor3 = GOLD
		label.TextStrokeColor3 = Color3.fromRGB(88, 49, 6)
		label.TextStrokeTransparency = 0.3
		label.Parent = gui
		gui.Parent = Runtime.Effects
		cast:Add(gui)
		marks[index] = { Gui = gui, Label = label }
	end
	if spec.SuppressNative then
		spec.SuppressNative(true)
	end

	local function dropMark(index)
		local mark = marks[index]
		if mark then
			cast.objects[mark.Gui] = nil
			mark.Gui:Destroy()
			marks[index] = nil
		end
	end
	local function dissolveFakes(now)
		for index, parts in pairs(previews) do
			if index ~= realIndex then
				for _, part in ipairs(parts) do
					table.insert(dissolving, { Part = part, Size = part.Size, Start = now })
				end
				previews[index] = nil
				dropMark(index)
			end
		end
		dropMark(realIndex)
	end
	local function stepDissolve(now)
		for i = #dissolving, 1, -1 do
			local item = dissolving[i]
			local part = item.Part
			local t = math.clamp((now - item.Start) / DISSOLVE, 0, 1)
			local k = (1 - t) ^ 2
			part.Size = isCircle and Vector3.new(item.Size.X, item.Size.Y * k, item.Size.Z * k)
				or Vector3.new(item.Size.X * k, item.Size.Y, item.Size.Z)
			part.Color = CYAN
			part.Transparency = 0.35 + 0.65 * t
			if t >= 1 then
				cast.objects[part] = nil
				Effects.Release(part)
				table.remove(dissolving, i)
			end
		end
	end
	local function finishExtras()
		for _, item in ipairs(dissolving) do
			cast.objects[item.Part] = nil
			Effects.Release(item.Part)
		end
		table.clear(dissolving)
		for _, pulse in ipairs(pulses) do
			if pulse.Part then
				cast.objects[pulse.Part] = nil
				Effects.Release(pulse.Part)
				pulse.Part = nil
			end
		end
		table.clear(pulses)
	end

	cast.OnDispose = function()
		record.Previews[cast] = nil
		if spec.SuppressNative then
			spec.SuppressNative(false)
		end
	end
	cast:Step(function(dt, now)
		if
			not alive(actor)
			or actor:GetAttribute("Phase") ~= 2.5
			or actor:GetAttribute("PhaseTransitionInProgress")
			or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
			or spec.Valid and not spec.Valid()
		then
			cast:Dispose()
			return false
		end
		local edt = Time.EncounterDelta(actor, dt)
		handle.Elapsed += edt
		local elapsed = handle.Elapsed
		local source = spec.Geometry and spec.Geometry()
		if not source then
			cast:Dispose()
			return false
		end
		local flashing = elapsed >= revealAt - 0.135 and elapsed < revealAt
		local newlyLocked = elapsed >= revealAt and not handle.Revealed
		local revealedFor = handle.Revealed and elapsed - handle.RevealedAt or 0
		local origin = source.Origin or source.Position
		local direction = source.Direction or Vector3.new(0, 0, -1)
		if direction.Magnitude < 0.001 then
			direction = Vector3.new(0, 0, -1)
		else
			direction = direction.Unit
		end
		for index, parts in pairs(previews) do
			local settled = locked[index] ~= nil
			local geometry = locked[index]
			if not geometry then
				local point = origin
				local facing = CFrame.Angles(0, (index - 2) * 0.48 + baseRotation + math.sin(elapsed * 3.2) * 0.14, 0)
					:VectorToWorldSpace(direction)
				if isCircle then
					local theta = baseAngle + (index - 1) * math.pi * 2 / 3 + elapsed * 1.1
					point += Vector3.new(math.cos(theta), 0, math.sin(theta)) * math.max(
						(source.Radius or 8) * 1.65,
						13
					)
					point = Placement.GroundPoint(point, { Margin = (source.Radius or 8) + 1, Clamp = true }) or point
				end
				geometry = {
					Origin = point,
					Position = point,
					Direction = facing,
					Radius = source.Radius,
					Length = source.Length,
					Width = source.Width,
					Spread = source.Spread,
				}
				if newlyLocked then
					locked[index] = geometry
				end
			end
			local fake = index ~= realIndex
			 
			local shake = not settled and not newlyLocked
			local glitchBurst = shake and math.sin(elapsed * 5.3 + index * 2.1) > 0.8
			local amp = shake and (glitchBurst and 0.4 or 0.1) or 0
			local shift = Vector3.new(math.sin(elapsed * 43 + index * 3.7), 0, math.sin(elapsed * 37 + index * 1.9))
				* amp
			for piece, part in ipairs(parts) do
				local alpha = 0.5 + math.sin(elapsed * 13) * 0.06
				if fake and flashing then
					alpha = 0.1 + 0.85 * (math.floor((elapsed - (revealAt - 0.135)) / 0.045) % 2)
				end
				if glitchBurst then
					alpha = math.max(alpha, 0.72)
				end
				if handle.Revealed then
					alpha = revealedFor < 0.1 and 0 or 0.12
				end
				part.Transparency = alpha
				local heat = handle.Revealed and math.clamp(1 - revealedFor / 0.25, 0, 1) or 0
				part.Color = (fake and flashing) and CYAN or GOLD:Lerp(HOT, heat)
				if isCircle then
					local radius = geometry.Radius or 8
					part.Size = Vector3.new(0.17, radius * 2, radius * 2)
					part.CFrame = CFrame.new(geometry.Position + shift + Vector3.new(0, 0.14, 0))
						* CFrame.Angles(0, 0, math.pi * 0.5)
				else
					local facing = geometry.Direction
					if spec.Shape == "Cone" then
						facing = CFrame.Angles(0, (piece - 2) * (geometry.Spread or 0.17), 0):VectorToWorldSpace(facing)
					end
					local length = geometry.Length or 90
					local start = geometry.Origin + shift
					local finish = start + facing * length
					part.Size = Vector3.new(geometry.Width or 0.3, 0.16, length)
					part.CFrame = CFrame.lookAt((start + finish) * 0.5, finish)
				end
			end
			local mark = marks[index]
			if mark then
				mark.Label.TextTransparency = glitchBurst and 0.75 or 0.1 + 0.15 * math.sin(elapsed * 9 + index) ^ 2
				mark.Label.TextColor3 = (fake and flashing) and CYAN or GOLD
				mark.Label.Rotation = math.sin(elapsed * 7 + index * 2) * 9
				mark.Gui.StudsOffset = Vector3.new(0, 3.2 + math.sin(elapsed * 3.5 + index) * 0.3, 0)
			end
		end
		if newlyLocked then
			handle.Revealed = true
			handle.RevealedAt = elapsed
			handle.Geometry = locked[realIndex]
			dissolveFakes(elapsed)
			if isCircle then
				local geometry = handle.Geometry
				local radius = geometry.Radius or 8
				table.insert(
					pulses,
					newPulse(
						cast,
						"FalseFutureLockPulse",
						HOT,
						geometry.Position + Vector3.new(0, 0.2, 0),
						radius,
						radius + 2.5,
						0.28,
						0.55
					)
				)
			end
			if spec.Reveal then
				spec.Reveal(handle.Geometry)
			end
		end
		stepDissolve(elapsed)
		for i = #pulses, 1, -1 do
			if not stepPulse(pulses[i], edt) then
				table.remove(pulses, i)
			end
		end
		if elapsed >= duration then
			finishExtras()
			handle.Ready = true
			return false
		end
		return true
	end)
	return handle
end

function api.ActivateFutureSight(actor)
	if not alive(actor) or actor:GetAttribute("Phase") ~= 2.5 or actor:GetAttribute("PhaseTransitionInProgress") then
		return false
	end
	if
		(actor:GetAttribute("FutureSightCharges") or 0) > 0
		or workspace:GetServerTimeNow() < (actor:GetAttribute("FutureSightReadyAt") or 0)
	then
		return false
	end
	local record = recordFor(actor)
	local now = workspace:GetServerTimeNow()
	actor:SetAttribute("FutureSightCharges", Config.FutureSightCharges)
	actor:SetAttribute("FutureSightUntil", 0)
	actor:SetAttribute("FutureSightReadyAt", now + Config.FutureSightCooldown)
	local cast = Effects.NewCast(actor, "FutureSightPredictionWindow", math.huge)
	cast.TimeStopExempt = true
	record.Prediction = cast
	local eye = Instance.new("BillboardGui")
	eye.Name = "FutureSightGoldenEye"
	eye.Size = UDim2.fromOffset(75, 48)
	eye.StudsOffset = Vector3.new(0, 4.4, 0)
	eye.AlwaysOnTop = false
	eye.Adornee = actor:FindFirstChild("Head")
	eye.Parent = Runtime.Effects
	cast:Add(eye)
	require(Shared:WaitForChild("Presentation"):WaitForChild("StatusIcons")).Create(
		eye,
		"P25FutureSight",
		UDim2.fromOffset(46, 46),
		UDim2.fromOffset(14, 0),
		GOLD
	)
	cast.OnDispose = function()
		if record.Prediction == cast then
			record.Prediction = nil
			actor:SetAttribute("FutureSightCharges", 0)
			actor:SetAttribute("FutureSightUntil", 0)
		end
	end
	cast:Step(function()
		if
			not alive(actor)
			or actor:GetAttribute("Phase") ~= 2.5
			or (actor:GetAttribute("FutureSightCharges") or 0) <= 0
		then
			cast:Dispose()
			return false
		end
		return true
	end)
	actor:SetAttribute("FutureSightActivations", (actor:GetAttribute("FutureSightActivations") or 0) + 1)
	return true
end
function api.TryEvade(actor, attacker, attackToken)
	local player = attacker and Players:GetPlayerFromCharacter(attacker)
	local h = attacker and attacker:FindFirstChildOfClass("Humanoid")
	if
		type(attackToken) ~= "table"
		or attackToken.Direct ~= true
		or (attackToken.Kind ~= "PlayerClass")
		or attackToken.Attacker ~= attacker
		or not player
		or player.Character ~= attacker
		or not h
		or h.Health <= 0
		or not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or actor:GetAttribute("PhaseTransitionInProgress")
		or actor:GetAttribute("Invulnerable")
		or actor:GetAttribute("ShieldDamageLocked")
	then
		return false
	end
	local record = recordFor(actor)
	if record.Seen[attackToken] then
		return true
	end
	if actor:GetAttribute("FutureSightDodging") then
  record.Seen[attackToken]=true
  return true
 end
 local charges = actor:GetAttribute("FutureSightCharges") or 0
 if charges <= 0 then
		return false
	end
	local root = actor:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local frame = root.CFrame
	local goal
	local generation = actor:GetAttribute("PhaseGeneration") or 0
	local distance = random:NextNumber(Config.FutureSightDodgeMinDistance, Config.FutureSightDodgeMaxDistance)
	local side = random:NextInteger(0, 1) == 0 and -1 or 1
 local filter=Runtime.FilterFor(actor)()
 local directions={frame.RightVector*side,-frame.RightVector*side,-frame.LookVector,frame.LookVector}
 for _,scale in ipairs({1,0.5,0.25}) do
  for _,direction in ipairs(directions) do
   local offset=direction*distance*scale
   if not workspace:Blockcast(frame,Vector3.new(3.4,4.5,3.4),offset,filter) then
    goal=Placement.Validate(actor,frame+offset,{Margin=5})
    if goal then break end
   end
  end
  if goal then break end
 end
	if not goal then
		return false
	end
	record.Seen[attackToken] = true
	actor:SetAttribute("FutureSightCharges", charges - 1)
	actor:SetAttribute("FutureSightDodges", (actor:GetAttribute("FutureSightDodges") or 0) + 1)
	if record.Dodge then
		record.Dodge:Dispose()
	end
	actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
	actor:SetAttribute("FutureSightDodging", true)
	local cast = Effects.NewCast(actor, "FutureSightDodge", Config.FutureSightDodgeDuration + 0.45)
	record.Dodge = cast
	 
	 
	local ghosts = {}
	for _, name in ipairs({ "Head", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg" }) do
		local source = actor:FindFirstChild(name)
		if source and source:IsA("BasePart") then
			local ghost = addPart(cast, "FutureSightGoldenAfterimage", source.CFrame, source.Size, GOLD, 0.28)
			table.insert(ghosts, { Part = ghost, Frame = source.CFrame })
		end
	end
	local highlight = Instance.new("Highlight")
	highlight.Name = "FutureSightPrediction"
	highlight.Adornee = actor
	highlight.FillColor = GOLD
	highlight.OutlineColor = GOLD
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0.15
	highlight.Parent = Runtime.Effects
	cast:Add(highlight)
	local began = cast:Now()
	cast.OnDispose = function()
		if record.Dodge == cast then
			record.Dodge = nil
			actor:SetAttribute("FutureSightDodging", false)
		end
	end
	cast:Step(function(_, now)
		if
			not alive(actor)
			or actor:GetAttribute("Phase") ~= 2.5
			or actor:GetAttribute("PhaseTransitionInProgress")
			or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
		then
			cast:Dispose()
			return false
		end
		local t = math.clamp((now - began) / Config.FutureSightDodgeDuration, 0, 1)
		if t < 1 then
			root.CFrame = frame:Lerp(goal, 1 - (1 - t) ^ 3)
		elseif actor:GetAttribute("FutureSightDodging") then
			root.CFrame = goal
			actor:SetAttribute("FutureSightDodging", false)
		end
		highlight.OutlineTransparency = 0.15 + 0.85 * t
		for i, ghost in ipairs(ghosts) do
			ghost.Part.Transparency = 0.28
				+ 0.72 * math.clamp((now - began) / (Config.FutureSightDodgeDuration + 0.4), 0, 1)
			ghost.Part.CFrame = ghost.Frame + frame.RightVector * math.sin(t * math.pi * 4 + i) * 0.12 * (1 - t)
		end
		return true
	end)
	send("FutureSightDodge", { Position = frame.Position, Destination = goal.Position, Charges = charges - 1 })
	return true
end
function api.BeginPhase25(actor)
	if not alive(actor) or actor:GetAttribute("Phase") ~= 2 or actor:GetAttribute("Phase25Triggered") then
		return false
	end
	local record = recordFor(actor)
	actor:SetAttribute("Phase25Triggered", true)
	actor:SetAttribute("Phase25TransitionInProgress", true)
	actor:SetAttribute("PhaseTransitionInProgress", true)
	actor:SetAttribute("TransitionKeepsTemporal", true)
	actor:SetAttribute("Invulnerable", true)
	actor:SetAttribute("ActiveAttackToken", nil)
	actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
	actor:SetAttribute("Phase", 2.5)
	Audio.Phase(actor, 2.5)
	local root = actor.HumanoidRootPart
	local frame = Placement.Validate(actor, root.CFrame) or root.CFrame
	local cast = Effects.NewCast(actor, "Phase25Story", Story.Duration(Story.Phase25) + 1)
	cast.TimeStopExempt = true
	record.Transition = cast
	local token = Locomotion.Pose(actor, { RightShoulder = { 15, 0, -10 }, LeftShoulder = { 0, 0, -5 } }, 0.2, true)
	cast:Step(function()
		root.CFrame = frame
		root.AssemblyLinearVelocity = Vector3.zero
		return true
	end)
	cast.OnDispose = function()
		if record.Transition ~= cast then
			return
		end
		record.Transition = nil
		actor:SetAttribute("Phase25TransitionInProgress", false)
		actor:SetAttribute("TransitionKeepsTemporal", false)
		Locomotion.ReleasePose(actor, token, 0.2)
		if alive(actor) and actor:GetAttribute("Phase") == 2.5 and not actor:GetAttribute("Phase3IntroActive") then
			actor:SetAttribute("PhaseTransitionInProgress", false)
			actor:SetAttribute("Invulnerable", false)
			actor:SetAttribute("AttackInProgress", false)
			actor:SetAttribute("AIEnabled", true)
			actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.25)
			api.ActivateFutureSight(actor)
		end
	end
	task.spawn(function()
		local ok, err = xpcall(function()
			Story.Play(actor, Story.Phase25, {
				Valid = function()
					return cast:Alive() and alive(actor) and actor:GetAttribute("Phase") == 2.5
				end,
			})
		end, debug.traceback)
		if not ok then
			warn("Phase25 story: " .. tostring(err))
		end
		cast:Dispose()
	end)
	return true
end
 
 
local function echoSnapshot(value, depth)
	if type(value) ~= "table" then
		return value
	end
	if depth > 4 then
		return nil
	end
	local copy = {}
	for key, item in pairs(value) do
		copy[key] = echoSnapshot(item, depth + 1)
	end
	return table.freeze(copy)
end
local function pruneEchoes(state)
	for index = #state.Active, 1, -1 do
		local cast = state.Active[index]
		if cast.closed or not cast:Alive() then
			table.remove(state.Active, index)
		end
	end
end
local function closeEchoes(state)
	if not state or state.Closed then
		return
	end
	state.Closed = true
	if state.Queue then
		table.clear(state.Queue)
	end
	for _, cast in ipairs(state.Active) do
		cast:Dispose()
	end
	table.clear(state.Active)
end
local function launchEcho(actor, state, job)
	if
		state.Closed
		or not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or not actor:GetAttribute("LastMinuteActive")
	then
		return false
	end
	pruneEchoes(state)
	if #state.Active >= Config.LastMinuteEchoMaxActive then
		return false
	end
	state.Replaying = true
	local ok, result = xpcall(job.Replay, debug.traceback, job.Payload, {
		Variant = job.Variant,
		DamageScale = Config.LastMinuteEchoDamageScale,
		IsLastMinuteEcho = true,
		Transparency = 0.5,
		MaxCount = Config.LastMinuteEchoProjectileMaxCount,
		CollapsePause = (actor:GetAttribute("LastMinuteStage") or 1) >= 3 and 0.12 or 0,
	})
	state.Replaying = false
	state.NextLaunchAt = state.Cast:Now() + Config.LastMinuteEchoMinInterval
	if not ok then
		warn("Last Minute emission echo: " .. tostring(result))
		return false
	end
	local cast = type(result) == "table" and (result.Cast or result) or nil
	if type(cast) ~= "table" or type(cast.Dispose) ~= "function" or type(cast.Alive) ~= "function" then
		return false
	end
	if state.Closed or not actor:GetAttribute("LastMinuteActive") then
		cast:Dispose()
		return false
	end
	table.insert(state.Active, cast)
	actor:SetAttribute("LastMinuteEchoesReleased", (actor:GetAttribute("LastMinuteEchoesReleased") or 0) + 1)
	if state.VFX then
		state.VFX.Echo()
	end
	return true
end
function api.OnTemporalEmission(actor, name, immutablePayload, replay)
	local definition = Metadata.Get(name)
	local record = records[actor]
	local state = record and record.Echoes
	if
		not state
		or state.Closed
		or state.Replaying
		or not definition
		or not definition.CanLastMinuteEcho
		or definition.Passive
		or definition.Ultimate
		or definition.TimeStopOnly
		or definition.NativePhase == 2.5
		or type(replay) ~= "function"
		or not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or not actor:GetAttribute("LastMinuteActive")
		or actor:GetAttribute("PhaseTransitionInProgress")
		or actor:GetAttribute("ExecutionLocked")
		or actor:GetAttribute("IsGoldenClone")
		or actor:GetAttribute("IsClone")
		or actor:GetAttribute("IsIllusion")
		or actor:FindFirstChild("EncounterOwner")
		or type(immutablePayload) == "table" and immutablePayload.IsLastMinuteEcho
	then
		return 0
	end
	local stage = Config.LastMinuteStages[actor:GetAttribute("LastMinuteStage") or 1]
	if not stage or (stage.EchoChance or 0) <= 0 or random:NextNumber() >= stage.EchoChance then
		return 0
	end
	if #state.Queue >= Config.LastMinuteEchoMaxQueued then
		return 0
	end
	local snapshot = echoSnapshot(immutablePayload, 0)
	local now = state.Cast:Now()
	local originalDelay = 0
	pruneEchoes(state)
	if
		(actor:GetAttribute("LastMinuteStage") or 1) >= 4
		and now >= state.NextLaunchAt
		and #state.Active < Config.LastMinuteEchoMaxActive
	then
		if launchEcho(actor, state, { Replay = replay, Payload = snapshot, Variant = "Past" }) then
			originalDelay = Config.LastMinutePastEchoLead
		end
	end
	local delay = originalDelay > 0 and originalDelay + Config.LastMinuteCollapseFutureDelay
		or Config.LastMinuteFutureEchoDelay
	local job = { At = now + delay, Payload = snapshot, Replay = replay, Variant = "Future" }
	local index = #state.Queue + 1
	while index > 1 and state.Queue[index - 1].At > job.At do
		index -= 1
	end
	table.insert(state.Queue, index, job)
	return originalDelay
end
local function clockSweep(actor, cast, boundary, final)
	local root = actor:FindFirstChild("HumanoidRootPart")
	local bounds = Placement.GetBounds()
	if not root or not bounds then
		return
	end
	local floor = Placement.GroundPoint(root.Position, { Margin = 4, Clamp = true })
	if not floor then
		return
	end
	local radius = math.sqrt(bounds.Width ^ 2 + bounds.Depth ^ 2)
	local center = floor + Vector3.new(0, 1, 0)
	local initial = random:NextNumber(0, math.pi * 2)
	local duration = Config.LastMinuteSweepDuration
	local warning = Config.LastMinuteSweepWarning
	 
	 
	local releaseAt = final and boundary - duration or boundary
	local warningAt = releaseAt - warning
	local bar
	local sweepVFX
	local function frame(angle)
		return CFrame.new(center) * CFrame.Angles(0, angle, 0)
	end
	cast:Schedule(math.max(0, warningAt), function()
		if not cast:Alive() or not actor:GetAttribute("LastMinuteActive") then
			return
		end
		local floorAtWarning = Placement.GroundPoint(root.Position, { Margin = 4, Clamp = true })
		if not floorAtWarning then
			return
		end
		center = floorAtWarning + Vector3.new(0, 1, 0)
		bar = addPart(
			cast,
			"LastMinuteClockHandSweep",
			frame(initial),
			Vector3.new(Config.LastMinuteSweepWidth, 2, radius * 2),
			GOLD,
			0.8
		)
		bar:SetAttribute("TimeStopExempt", true)
		sweepVFX = LastMinuteVFX.Sweep(cast, bar, warning)
		send(
			"LastMinuteSweepWarning",
			{ Origin = center, Angle = initial, Duration = warning, Width = Config.LastMinuteSweepWidth }
		)
	end)
	cast:Schedule(math.max(0, releaseAt), function()
		if not bar or not bar.Parent or not cast:Alive() or not actor:GetAttribute("LastMinuteActive") then
			return
		end
		if sweepVFX then
			sweepVFX:Release()
		end
		bar.Transparency = 0.12
		local began = cast:Now()
		local previous = initial
		local hits = {}
		local Encounter = require(BossSystem.Players.PlayerEncounter)
		cast:Step(function(_, now)
			if not bar.Parent or not actor:GetAttribute("LastMinuteActive") then
				return false
			end
			local t = math.clamp((now - began) / duration, 0, 1)
			local angle = initial + t * math.pi
			bar.CFrame = frame(angle)
			local samples = math.clamp(math.ceil(math.abs(angle - previous) / (math.pi / 90)), 1, 90)
			for _, character in ipairs(Runtime.Characters()) do
				local h = character:FindFirstChildOfClass("Humanoid")
				local r = character:FindFirstChild("HumanoidRootPart")
				if r and h and h.Health > 0 and not hits[character] and Placement.Contains(r.Position, 2) then
					 
					 
					local feet = r.Position - Vector3.new(0, 2.5, 0)
					for sample = 1, samples do
						local point = frame(previous + (angle - previous) * sample / samples):PointToObjectSpace(feet)
						if
							math.abs(point.X) <= bar.Size.X * 0.5 + r.Size.X * 0.5
							and math.abs(point.Y) <= bar.Size.Y * 0.5 + 0.5
							and math.abs(point.Z) <= bar.Size.Z * 0.5 + r.Size.Z * 0.5
						then
							hits[character] = true
							Encounter.Damage(character, Config.LastMinuteSweepDamage, actor)
							-- Borrowed Time: a hand that catches someone takes seconds back onto the clock
							local reclaim = Config.LastMinuteSweepReclaim or 0
							local full = actor:GetAttribute("LastMinuteTimeShield") or 0
							if reclaim > 0 and full > 0 then
								local perSecond = Config.LastMinuteShieldPerSecond or 70
								actor:SetAttribute("Shield", math.min(full, (actor:GetAttribute("Shield") or 0) + reclaim * perSecond))
								if not actor:GetAttribute("LastMinuteReclaimSaid") then
									actor:SetAttribute("LastMinuteReclaimSaid", true)
									pcall(Encounter.Say, "That second was mine. I'll take it back.", nil, { Duration = 2.5 })
								end
							end
							if sweepVFX then
								sweepVFX:Hit(feet)
							end
							break
						end
					end
				end
			end
			previous = angle
			if t >= 1 then
				if sweepVFX then
					sweepVFX:Finish()
					sweepVFX = nil
				end
				cast.objects[bar] = nil
				Effects.Release(bar)
				bar = nil
				table.clear(hits)
				return false
			end
			return true
		end)
	end)
end
local function startLastMinuteCollapse(actor, record)
	if
		not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or actor:GetAttribute("LastMinuteActive")
		or records[actor] ~= record
		or not actor:GetAttribute("LastMinuteUsed")
		or not actor:GetAttribute("ShieldDamageLocked")
	then
		return false
	end
	Time.ClearRates(actor)
	actor:SetAttribute("LastMinutePreparing", false)
	actor:SetAttribute("LastMinuteActive", true)
	-- Borrowed Time: the shield becomes the clock. Every point the players break steals 1/perSecond
	-- of a second from the countdown; breaking it all ends the minute early.
	local perSecond = Config.LastMinuteShieldPerSecond or 70
	local timeShield = math.max(1, math.floor(Config.LastMinuteDuration * perSecond * (Difficulty.Get(actor).Shield or 1)))
	actor:SetAttribute("ShieldDamageLocked", false)
	actor:SetAttribute("Shield", timeShield)
	actor:SetAttribute("LastMinuteTimeShield", timeShield)
	actor:SetAttribute("LastMinuteReclaimSaid", false)
	actor:SetAttribute("LastMinuteAttackMultiplier", Config.LastMinuteStages[1].IntervalMultiplier)
	actor:SetAttribute("LastMinutePhase25Weight", Config.LastMinuteStages[1].Phase25Weight)
	actor:SetAttribute("LastMinuteMissingFrameCount", 0)
	actor:SetAttribute(
		"LastMinuteMissingFrameReadyAt",
		workspace:GetServerTimeNow() + Config.MissingFrameLastMinuteSpacing
	)
	actor:SetAttribute("LastMinuteStage", 1)
	actor:SetAttribute("LastMinuteRevolution", 1)
	local startedAt = workspace:GetServerTimeNow()
	local ends = startedAt + Config.LastMinuteDuration
	actor:SetAttribute("LastMinuteEndsAt", ends)
	workspace:SetAttribute("LastMinuteEndsAt", ends)
	workspace:SetAttribute("LastMinuteActive", true)
	actor:SetAttribute(
		"NextAttackAt",
		math.min(actor:GetAttribute("NextAttackAt") or ends, workspace:GetServerTimeNow() + 0.1)
	)
	local cast = Effects.NewCast(actor, "LastMinuteCollapse", Config.LastMinuteDuration + 0.8)
	cast.TimeStopExempt = true
	record.LastMinute = cast
	local generation = actor:GetAttribute("PhaseGeneration") or 0
	local root = actor.HumanoidRootPart
	local function followingClockFrame()
		local forward = root.CFrame.LookVector
		forward = Vector3.new(forward.X, 0, forward.Z)
		if forward.Magnitude < 0.001 then
			forward = Vector3.new(0, 0, -1)
		else
			forward = forward.Unit
		end
		local position = root.Position
			+ Vector3.new(0, Config.LastMinuteClockHeight, 0)
			- forward * Config.LastMinuteClockBehindOffset
		return CFrame.lookAt(position, position + forward)
	end
	local clockFrame = followingClockFrame()
	local clockPosition = clockFrame.Position
	local radius = Config.LastMinuteClockRadius
	local clockScale = radius / 50
	local face = addPart(
		cast,
		"AncientRomanTemporalClock",
		clockFrame,
		Vector3.new(Config.LastMinuteClockDiameter, Config.LastMinuteClockDiameter, 0.1),
		GOLD,
		1
	)
	face:SetAttribute("TimeStopExempt", true)
	local attachments, beams, cracks = {}, {}, {}
	for index = 1, 24 do
		local a = Instance.new("Attachment")
		local theta = (index - 1) * math.pi * 2 / 24
		a.Position = Vector3.new(math.cos(theta) * radius, math.sin(theta) * radius, 0)
		a.Parent = face
		attachments[index] = a
	end
	for index = 1, 24 do
		local b = Instance.new("Beam")
		b.Name = "LastMinuteAncientClockRim"
		b.Attachment0 = attachments[index]
		b.Attachment1 = attachments[index % 24 + 1]
		b.Width0 = 0.8 * clockScale
		b.Width1 = b.Width0
		b.LightEmission = 1
		b.FaceCamera = true
		b.Segments = 1
		b.Color = ColorSequence.new(GOLD, Color3.fromRGB(175, 113, 25))
		b.Transparency = NumberSequence.new(0.1)
		b:SetAttribute("TimeStopExempt", true)
		b.Parent = face
		beams[index] = b
	end
	 
	 
	for index = 1, 12 do
		local a = Instance.new("Attachment")
		local theta = index * 2.399963
		a.Position = Vector3.new(math.cos(theta) * radius * 0.18, math.sin(theta) * radius * 0.18, 0)
		a.Parent = face
		local b = Instance.new("Beam")
		b.Name = "LastMinuteClockCrack"
		b.Attachment0 = a
		b.Attachment1 = attachments[(index * 2) % 24 + 1]
		b.Width0 = 0.14 * clockScale
		b.Width1 = 0.5 * clockScale
		b.LightEmission = 1
		b.FaceCamera = true
		b.Segments = 1
		b.Color = ColorSequence.new(Color3.fromRGB(255, 249, 178), GOLD)
		b.Transparency = NumberSequence.new(1)
		b:SetAttribute("TimeStopExempt", true)
		b.Parent = face
		cracks[index] = b
	end
	local hands = {
		addPart(cast, "RomanClockSecondHand", face.CFrame, Vector3.new(0.8, 40, 0.6) * clockScale, GOLD, 0.05),
		addPart(
			cast,
			"RomanClockHourHand",
			face.CFrame,
			Vector3.new(1.2, 24, 0.7) * clockScale,
			Color3.fromRGB(215, 159, 41),
			0.1
		),
	}
	local center = addPart(cast, "RomanClockCenter", clockFrame, Vector3.new(2.6, 2.6, 0.8) * clockScale, GOLD, 0.05)
	center.Shape = Enum.PartType.Ball
	local numerals = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII" }
	local labels = {}
	for _, side in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "RomanClockFace"
		gui.CanvasSize = Vector2.new(1024, 1024)
		gui.Face = side
		gui.LightInfluence = 0
		gui.AlwaysOnTop = false
		gui.Parent = face
		for index, numeral in ipairs(numerals) do
			local theta = index * math.pi * 2 / 12
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Size = UDim2.fromOffset(100, 100)
			label.Position = UDim2.fromScale(0.5 + math.sin(theta) * 0.365, 0.5 - math.cos(theta) * 0.365)
			label.Font = Enum.Font.Garamond
			label.TextSize = 86
			label.TextColor3 = GOLD
			label.TextStrokeColor3 = Color3.fromRGB(88, 49, 6)
			label.TextStrokeTransparency = 0.2
			label.Text = numeral
			label.Parent = gui
			table.insert(labels, { Label = label, Theta = theta, Index = index })
		end
	end
	for _, object in ipairs(hands) do
		object:SetAttribute("TimeStopExempt", true)
	end
	center:SetAttribute("TimeStopExempt", true)
	local lastMinuteVFX = LastMinuteVFX.Clock(actor, cast, {
		Face = face,
		Hands = hands,
		Center = center,
		Attachments = attachments,
		Labels = labels,
		Radius = radius,
		Scale = clockScale,
	})
	local began = cast:Now()
	local accumulated = 0
	local resolved = false
	local ending = false
	local lastTick = 0
	local stageIndex = 1
	local nextVisual = 0
	local completedRevolutions = 0
	local Clones = require(BossSystem.Mechanics.Clones.CloneController)
	local echoes = {
		Cast = cast,
		Active = {},
		Queue = {},
		Closed = false,
		Replaying = false,
		NextLaunchAt = began,
		VFX = lastMinuteVFX,
	}
	record.Echoes = echoes
	local pressure = { Active = {}, NextAt = began + 1.4, Sequence = 0 }
	local Projectile = require(BossSystem.Combat.ProjectileService)
	local targeting = require(BossSystem.Combat.AttackRegistry).For(actor, "P1NormalSlash")
	local function pressureVolley(stage)
		pruneEchoes(pressure)
		if
			#pressure.Active >= Config.LastMinutePressureMaxActive
			or actor:GetAttribute("ExecutionLocked")
			or actor:GetAttribute("PhaseTransitionInProgress")
			or Time.IsStopped(actor)
		then
			return false
		end
		local character = targeting.GetTarget()
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		if not alive(character) or not targetRoot then
			return false
		end
		pressure.Sequence += 1
		local kind = pressure.Sequence % 3 == 0 and "Time" or "Golden"
		local count = math.min(
			kind == "Time" and math.ceil(stage.PressureCount * 0.5) or stage.PressureCount,
			Projectile.Capacity(actor, kind)
		)
		if count <= 0 then
			return false
		end
		local positions = {}
		local axis = random:NextNumber(0, math.pi * 2)
		local aim = targetRoot.Position
		for index = 1, count do
			 
			 
			local angle = axis + (index % 2 == 0 and math.pi * 0.8 or 0) + (index / count - 0.5) * 0.7
			local distance = random:NextNumber(40, 65)
			local ground
			for attempt = 1, 4 do
				local candidate = aim + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
				local point = Placement.GroundPoint(candidate, { Margin = 5, Clamp = true })
				local valid = point and Vector3.new(point.X - aim.X, 0, point.Z - aim.Z).Magnitude >= 24
				if valid then
					for _, previous in ipairs(positions) do
						if Vector3.new(previous.X - point.X, 0, previous.Z - point.Z).Magnitude < 2.5 then
							valid = false
							break
						end
					end
				end
				if valid then
					ground = point
					break
				end
				angle += 2.399963
			end
			if not ground then
				return false
			end
			positions[index] = ground + Vector3.new(0, 3.5 + (index % 3) * 0.45, 0)
		end
		local result = Projectile.Burst(actor, character, {
			Kind = kind,
			Count = count,
			SpawnPositions = positions,
			PreparedAim = aim,
			Speed = Config.LastMinutePressureSpeed,
			Damage = Config.LastMinutePressureDamage,
			Skill = kind == "Time" and "P2TimeBullets" or "P2GoldenBullets",
			LockedTrajectory = true,
			LaunchDelay = Config.LastMinutePressureWarning,
			NoMuzzleFlash = true,
			SpreadDegrees = 8,
			MaxHits = 3,
			FlightLifetime = 2.5,
			CollapsePause = stageIndex >= 3 and 0.18 or 0,
		})
		if type(result) == "table" and result.Cast then
			table.insert(pressure.Active, result.Cast)
			actor:SetAttribute("LastMinutePressureVolleys", (actor:GetAttribute("LastMinutePressureVolleys") or 0) + 1)
			return true
		end
		return false
	end
	 -- sweeps are released as the clock (real time + stolen time) crosses each revolution
	local shownStolen, stoleAll, midnightSwept, endedAt = 0, false, false, 0
	local SWEEP_LEAD = Config.LastMinuteSweepWarning + 0.05
	local function finish(normal)
		if resolved then
			return
		end
		resolved = true
		closeEchoes(echoes)
		closeEchoes(pressure)
		if record.Echoes == echoes then
			record.Echoes = nil
		end
		actor:SetAttribute("LastMinutePreparing", false)
		actor:SetAttribute("LastMinuteActive", false)
		actor:SetAttribute("ShieldDamageLocked", false)
		actor:SetAttribute("LastMinuteAttackMultiplier", 1)
		actor:SetAttribute("LastMinuteEndsAt", 0)
		actor:SetAttribute("LastMinutePhase25Weight", 1)
		actor:SetAttribute("LastMinuteStage", 0)
		actor:SetAttribute("LastMinuteMissingFrameInterval", nil)
		actor:SetAttribute("LastMinuteRevolution", 0)
		actor:SetAttribute("LastMinuteMissingFrameReadyAt", 0)
		workspace:SetAttribute("LastMinuteActive", false)
		workspace:SetAttribute("LastMinuteEndsAt", 0)
		send("LastMinuteEnd", { Completed = normal == true })
		if
			alive(actor)
			and actor:GetAttribute("Phase") == 2.5
			and not actor:GetAttribute("Phase3IntroActive")
			and (actor:GetAttribute("PhaseGeneration") or 0) == generation
		then
			if normal then
				pcall(function()
					require(BossSystem.Players.PlayerEncounter).Say(stoleAll and "...You stole my last minute. Then take the next hour too." or "Time's up.", nil, { Duration = 3 })
				end)
				actor:SetAttribute("LastMinuteCompleted", true)
				send("Shake", { Origin = root.Position, Radius = 450, Duration = 0.65, Intensity = 1.6 })
				actor:SetAttribute("Shield", 0)
				require(BossSystem.Presentation.CharacterEffects).ShieldBreak(actor)
				require(BossSystem.Phases.PhaseController).ShieldBroken(actor)
			elseif not cast.CancelReason then
				task.defer(api.RecoverLastMinute, actor, "Interrupted countdown")
			end
		end
	end
	cast.OnDispose = function()
		if record.LastMinute == cast then
			record.LastMinute = nil
		end
		 
		 
		finish(false)
	end
	cast:Step(function(dt, now)
		if
			not alive(actor)
			or actor:GetAttribute("Phase") ~= 2.5
			or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
		then
			cast:Dispose()
			return false
		end
		local shieldNow = actor:GetAttribute("Shield") or 0
		local stolen = math.clamp((timeShield - shieldNow) / perSecond, 0, Config.LastMinuteDuration)
		if shieldNow <= 1 then
			stolen = Config.LastMinuteDuration
			stoleAll = true
		end
		if math.abs(stolen - shownStolen) >= 0.05 then
			shownStolen = stolen
			local endsAt = startedAt + Config.LastMinuteDuration - stolen
			actor:SetAttribute("LastMinuteEndsAt", endsAt)
			workspace:SetAttribute("LastMinuteEndsAt", endsAt)
			actor:SetAttribute("LastMinuteStolen", stolen)
		end
		local elapsed = ending and Config.LastMinuteDuration + (now - endedAt) or math.min(now - began + stolen, Config.LastMinuteDuration)
		local follow = 1 - math.exp(-math.min(dt, 0.15) * Config.LastMinuteClockFollowResponsiveness)
		clockFrame = clockFrame:Lerp(followingClockFrame(), follow)
		clockPosition = clockFrame.Position
		local tremble = stageIndex >= 4 and math.sin(elapsed * 55) * 0.3 * (stageIndex - 3) or 0
		face.CFrame = clockFrame * CFrame.new(tremble, math.sin(elapsed * 61) * math.abs(tremble), 0)
		center.CFrame = face.CFrame
		while Config.LastMinuteStages[stageIndex + 1] and elapsed >= Config.LastMinuteStages[stageIndex + 1].At do
			stageIndex += 1
			local stage = Config.LastMinuteStages[stageIndex]
			actor:SetAttribute("LastMinuteStage", stageIndex)
			actor:SetAttribute("LastMinuteRevolution", stageIndex)
			actor:SetAttribute("LastMinuteAttackMultiplier", stage.IntervalMultiplier)
			actor:SetAttribute("LastMinutePhase25Weight", stage.Phase25Weight)
			send("LastMinuteStage", { Stage = stageIndex, Origin = clockPosition })
		end
		local tick = math.min(Config.LastMinuteDuration, math.floor(elapsed))
		local burst = tick - lastTick > 3
		local pendingSweep = nil
		while lastTick < tick and not ending do
			lastTick += 1
			local revolution = math.ceil(lastTick / Config.LastMinuteRevolutionDuration)
			if not burst or lastTick == tick then
				send("LastMinuteTick", {
				Stage = stageIndex,
					Revolution = revolution,
					NumeralIndex = (lastTick - 1) % 12 + 1,
					Final = lastTick == Config.LastMinuteDuration,
					Origin = clockPosition,
				})
				if lastMinuteVFX then
					lastMinuteVFX.Tick(lastTick, stageIndex)
				end
			end
			if lastTick % Config.LastMinuteRevolutionDuration == 0 then
				completedRevolutions = revolution
				pendingSweep = revolution
				send(
					"LastMinuteRevolution",
					{ Revolution = revolution, Final = revolution == 5, Origin = clockPosition }
				)
				if lastMinuteVFX then
					lastMinuteVFX.Revolution(revolution, revolution == 5)
				end
				send(
					"Shake",
					{
						Origin = root.Position,
						Radius = 450,
						Duration = 0.2 + revolution * 0.045,
						Intensity = 0.35 + revolution * 0.18,
					}
				)
			end
			if lastTick == 59 then
				send("LastMinuteVisualHitch", { Duration = 0.15, Origin = clockPosition })
			end
		end
		if pendingSweep and pendingSweep < 5 and not ending then
			clockSweep(actor, cast, SWEEP_LEAD, false)
		end
		 -- midnight: one last sweep timed to finish as the clock runs out
		if not midnightSwept and not ending
			and elapsed >= Config.LastMinuteDuration - (SWEEP_LEAD + Config.LastMinuteSweepDuration + 0.2) then
			midnightSwept = true
			clockSweep(actor, cast, SWEEP_LEAD, false)
		end
		for index, hand in ipairs(hands) do
			 
			 
			local angle = -lastTick * math.pi * 2 / (index == 1 and Config.LastMinuteRevolutionDuration or 144)
			if stageIndex >= 3 and not ending then
				local phase = elapsed - math.floor(elapsed)
				if phase > 0.72 and phase < 0.86 then
					angle += math.pi / 6 * (phase - 0.72) / 0.14
				end
			end
			if ending then
				angle -= math.max(0, elapsed - Config.LastMinuteDuration) * 22
			end
			hand.CFrame = face.CFrame * CFrame.Angles(0, 0, angle) * CFrame.new(0, hand.Size.Y * 0.5, 0.15 * index)
		end
		if elapsed >= nextVisual then
			nextVisual = elapsed + 0.05
			local collapse = ending and math.clamp((elapsed - Config.LastMinuteDuration) / 0.5, 0, 1) or 0
			for index, attachment in ipairs(attachments) do
				local theta = (index - 1) * math.pi * 2 / 24
				local detached = completedRevolutions >= 3 and index % 3 == 0
				local orbit = detached and elapsed * 0.22 or 0
				local spread = 1 + collapse * 0.8 + (detached and 0.12 + 0.06 * math.sin(elapsed * 2 + index) or 0)
				attachment.Position = Vector3.new(
					math.cos(theta + orbit) * radius * spread,
					math.sin(theta + orbit) * radius * spread,
					detached and math.sin(elapsed + index) * 8 or 0
				)
				local beam = beams[index]
				beam.Transparency = NumberSequence.new(
					ending and collapse or 0.06 + 0.13 * (1 + math.sin(elapsed * (8 + stageIndex * 3) + index)) * 0.5
				)
				beam.Width0 = (0.8 + stageIndex * 0.08) * clockScale
				beam.Width1 = beam.Width0
			end
			for index, crack in ipairs(cracks) do
				crack.Transparency =
					NumberSequence.new(ending and collapse or index <= completedRevolutions * 3 and 0.08 or 1)
			end
			for _, data in ipairs(labels) do
				local label = data.Label
				local drift = completedRevolutions >= 3 and elapsed * 0.11 or 0
				local distance = 0.365
					+ (completedRevolutions >= 4 and 0.045 * math.sin(elapsed * 2 + data.Index) or 0)
					+ collapse * 0.3
				local jitter = elapsed >= 58 and math.sin(elapsed * 55 + data.Index) * 0.01 or 0
				label.Position = UDim2.fromScale(
					0.5 + math.sin(data.Theta + drift) * distance + jitter,
					0.5 - math.cos(data.Theta + drift) * distance
				)
				label.Rotation = completedRevolutions >= 4 and math.sin(elapsed * 4 + data.Index) * 15 or 0
				label.TextTransparency = collapse
				label.TextStrokeTransparency = 0.2 + 0.8 * collapse
			end
			if ending then
				for _, hand in ipairs(hands) do
					hand.Transparency = collapse
				end
				center.Transparency = collapse
			end
		end
		if ending then
			return true
		end
		if now >= pressure.NextAt then
			local stage = Config.LastMinuteStages[stageIndex]
			pressure.NextAt = now + stage.PressureInterval
			pressureVolley(stage)
		end
		pruneEchoes(echoes)
		if
			echoes.Queue[1]
			and echoes.Queue[1].At <= now
			and now >= echoes.NextLaunchAt
			and #echoes.Active < Config.LastMinuteEchoMaxActive
		then
			local job = table.remove(echoes.Queue, 1)
			if now - job.At < 2 then
				launchEcho(actor, echoes, job)
			end
		end
		accumulated += dt
		if accumulated >= 0.15 then
			local stage = Config.LastMinuteStages[stageIndex]
			local advance = stage.TemporalAdvance * math.min(accumulated, 0.3)
			accumulated = 0
			Time.AdvanceDeferred(actor, advance, false, { MaxCount = 4 })
			Clones.AdvanceDeferred(actor, advance, false, 4)
			if stageIndex == #Config.LastMinuteStages then
				Time.FlushDeferred(actor, { MaxCount = 4, Interval = 0.15 })
				Clones.AdvanceDeferred(actor, 60, true, 4)
			end
		end
		if elapsed >= Config.LastMinuteDuration then
			ending = true
			endedAt = now
			closeEchoes(echoes)
			closeEchoes(pressure)
			Time.FlushDeferred(actor, { MaxCount = 4, Interval = 0.15 })
			Clones.AdvanceDeferred(actor, 60, true, 4)
			actor:SetAttribute("LastMinuteAttackMultiplier", 1)
			if lastMinuteVFX then
				lastMinuteVFX.Shatter()
			end
			send("LastMinuteShatter", { Origin = clockPosition })
			cast:Schedule(0.5, function()
				finish(true)
				cast:Dispose()
			end)
		end
		return true
	end)
	send("LastMinute", { ClockOnly = true, Stage = 1, Origin = clockPosition })
	pcall(function()
		require(BossSystem.Players.PlayerEncounter).Say("Every blow you land steals a second from me. Spend them wisely.", nil, { Duration = 3.4 })
	end)
	return true
end

function api.BeginLastMinute(actor)
  
 if alive(actor) and actor:GetAttribute("Phase") == 2.5 and not Difficulty.Get(actor).Ultimates then
  if actor:GetAttribute("PhaseTransitionInProgress") then return false end
  actor:SetAttribute("LastMinuteUsed", true)
  actor:SetAttribute("LastMinuteCompleted", true)
  actor:SetAttribute("Shield", 0)
  return require(BossSystem.Phases.PhaseController).BeginPhase3(actor)
 end
	if
		not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or actor:GetAttribute("LastMinuteUsed")
		or actor:GetAttribute("LastMinuteActive")
		or actor:GetAttribute("LastMinutePreparing")
	then
		return false
	end
	local shield = actor:GetAttribute("Shield") or 0
	if shield <= 0 or shield > Config.LastMinuteShieldGate then
		return false
	end
	local record = recordFor(actor)
	local ultimates = require(BossSystem.Combat.UltimateService)
	if not ultimates.Ready(actor) then
		if not record.UltimateQueued then
			record.UltimateQueued = true
			actor:SetAttribute("LastMinuteQueued", true)
			task.spawn(function()
				while records[actor] == record and alive(actor) and actor:GetAttribute("Phase") == 2.5
						and not actor:GetAttribute("LastMinuteUsed") and (actor:GetAttribute("Shield") or 0) > 0 do
					if ultimates.Ready(actor) then
						record.UltimateQueued = false
						actor:SetAttribute("LastMinuteQueued", false)
						api.BeginLastMinute(actor)
						return
					end
					game:GetService("RunService").Heartbeat:Wait()
				end
				record.UltimateQueued = false
				if actor.Parent then actor:SetAttribute("LastMinuteQueued", false) end
			end)
		end
		return false
	end
	local ultimateHandle = ultimates.Begin(actor, "P2.5LastMinute(Ultimate)")
	if not ultimateHandle then return false end
	if record.Transition then record.Transition:Dispose() end
	 
	 
	actor:SetAttribute("LastMinuteUsed", true)
	actor:SetAttribute("ShieldDamageLocked", true)
	actor:SetAttribute("Shield", Config.LastMinuteShieldGate)
	actor:SetAttribute("LastMinutePreparing", true)
	actor:SetAttribute("PhaseTransitionInProgress", true)
	actor:SetAttribute("TransitionKeepsTemporal", true)
	actor:SetAttribute("Invulnerable", true)
	actor:SetAttribute("AttackInProgress", true)
	actor:SetAttribute("ActiveAttackToken", nil)
	actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
	local generation = actor:GetAttribute("PhaseGeneration") or 0
	local root = actor.HumanoidRootPart
	local frame = Placement.Validate(actor, root.CFrame) or root.CFrame
	local lines = Story.LastMinute
		or { "Hm...", "Looks like we're running out of time.", "Then let's make this last minute count." }
	local preludeDuration = Story.Duration(lines)
	local prelude = Effects.NewCast(actor, "LastMinutePrelude", preludeDuration + 1)
	prelude.TimeStopExempt = true
	record.Transition = prelude
	local completed = false
	local pose = Locomotion.Pose(actor, { RightShoulder = { 15, 0, -15 }, LeftShoulder = { 0, 0, -8 } }, 0.2, true)
	local function owns()
		return alive(actor)
			and actor:GetAttribute("Phase") == 2.5
			and records[actor] == record
			and (actor:GetAttribute("PhaseGeneration") or 0) == generation
			and not actor:GetAttribute("Phase3IntroActive")
	end
	local function retryGate()
		if owns() and not prelude.CancelReason then
			task.defer(api.RecoverLastMinute, actor, "Interrupted opening")
		end
	end
	prelude:Step(function()
		if not owns() then
			prelude:Dispose()
			return false
		end
		root.CFrame = frame
		root.AssemblyLinearVelocity = Vector3.zero
		return true
	end)
	prelude.OnDispose = function()
		if record.Transition ~= prelude then
			return
		end
		record.Transition = nil
		actor:SetAttribute("LastMinutePreparing", false)
		local valid = owns()
		if valid then
			actor:SetAttribute("PhaseTransitionInProgress", false)
			actor:SetAttribute("TransitionKeepsTemporal", false)
			actor:SetAttribute("Invulnerable", false)
			actor:SetAttribute("AttackInProgress", false)
			actor:SetAttribute("AIEnabled", true)
			actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.15)
		end
		local ok, err = pcall(Locomotion.ReleasePose, actor, pose, 0.18)
		if not ok then
			warn("Last Minute prelude pose cleanup: " .. tostring(err))
		end
		if not completed then
			retryGate()
		end
	end
	task.spawn(function()
		local ok, result = xpcall(function()
			LastMinuteVFX.Prelude(actor, prelude, preludeDuration)
			return Story.Play(actor, lines, {
				Prefix = "LastMinute",
				Valid = function()
					return prelude:Alive() and owns()
				end,
			})
		end, debug.traceback)
		if not ok then
			warn("Last Minute prelude: " .. tostring(result))
		end
		completed = ok and result == true and prelude:Alive() and owns()
		prelude:Dispose()
		if completed and owns() then
			local startedOk, started = xpcall(startLastMinuteCollapse, debug.traceback, actor, record)
			if not startedOk then
				warn("Last Minute construction: " .. tostring(started))
				local partial = record.LastMinute
				if partial then
					record.LastMinute = nil
					partial:Dispose()
				end
				closeEchoes(record.Echoes)
				record.Echoes = nil
				if owns() then
					actor:SetAttribute("LastMinuteActive", false)
					actor:SetAttribute("LastMinuteEndsAt", 0)
					actor:SetAttribute("LastMinuteAttackMultiplier", 1)
					actor:SetAttribute("LastMinutePhase25Weight", 1)
					actor:SetAttribute("LastMinuteStage", 0)
					actor:SetAttribute("LastMinuteRevolution", 0)
					workspace:SetAttribute("LastMinuteActive", false)
					workspace:SetAttribute("LastMinuteEndsAt", 0)
				end
			end
			if not startedOk or not started then
				retryGate()
			end
		end
	end)
	ultimates.Finish(ultimateHandle)
	return true
end

 
 
function api.RecoverLastMinute(actor, reason)
	if not alive(actor) or actor:GetAttribute("Phase") ~= 2.5
		or actor:GetAttribute("Phase3IntroActive") or actor:GetAttribute("LastMinuteCompleted") then return false end
	local record = records[actor]
	if api.IsActive(actor) or (record and record.UltimateQueued) then return false end
	api.Cancel(actor, reason or "Last Minute recovery")
	local ultimates = require(BossSystem.Combat.UltimateService)
	ultimates.Cancel(actor, reason or "Last Minute recovery")
	for _, name in ipairs({ "LastMinuteUsed", "LastMinutePreparing", "LastMinuteActive",
		"Phase25TransitionInProgress", "PhaseTransitionInProgress", "TransitionKeepsTemporal",
		"Invulnerable", "AttackInProgress", "ShieldDamageLocked" }) do actor:SetAttribute(name, false) end
	actor:SetAttribute("LastMinuteEndsAt", 0)
	workspace:SetAttribute("LastMinuteActive", false)
	workspace:SetAttribute("LastMinuteEndsAt", 0)
	actor:SetAttribute("AIEnabled", true)
	actor:SetAttribute("LastMinuteRecoveryReason", reason or "Lost cast")
	actor:SetAttribute("LastMinuteRecoveryCount", (actor:GetAttribute("LastMinuteRecoveryCount") or 0) + 1)
	actor:SetAttribute("Shield", Config.LastMinuteShieldGate)
	api.BeginLastMinute(actor)
	return true
end

function api.OnShieldChanged(actor)
	if not alive(actor) then
		return
	end
	local shield = actor:GetAttribute("Shield") or 0
	if actor:GetAttribute("Phase") == 2 and shield > 0 and shield <= Config.Phase25ShieldThreshold then
		api.BeginPhase25(actor)
	end
	if
		actor:GetAttribute("Phase") == 2.5
		and shield > 0
		and shield <= Config.LastMinuteShieldGate
		and not actor:GetAttribute("LastMinuteUsed")
	then
		api.BeginLastMinute(actor)
	end
end
function api.Cancel(actor, reason)
	local record = records[actor]
	if not record then
		return
	end
	if record.Transition then
		record.Transition.CancelReason = reason
		record.Transition:Dispose()
	end
	if record.Prediction then
		record.Prediction:Dispose()
	end
	if record.FalseFuture then
		record.FalseFuture:Dispose()
	end
	local previews = {}
	for cast in pairs(record.Previews) do
		table.insert(previews, cast)
	end
	for _, cast in ipairs(previews) do
		cast:Dispose()
	end
	if record.Dodge then
		record.Dodge:Dispose()
	end
	if record.LastMinute then
		record.LastMinute.CancelReason = reason
		record.LastMinute:Dispose()
	end
	actor:SetAttribute("FutureSightCharges", 0)
	actor:SetAttribute("FutureSightDodging", false)
	actor:SetAttribute("FutureSightUntil", 0)
	actor:SetAttribute("FalseFutureCharges", 0)
	actor:SetAttribute("FalseFutureUntil", 0)
	actor:SetAttribute("ShieldDamageLocked", false)
	actor:SetAttribute("LastMinuteAttackMultiplier", 1)
	actor:SetAttribute("LastMinutePhase25Weight", 1)
	actor:SetAttribute("LastMinuteStage", 0)
	records[actor] = nil
end
function api.IsActive(actor)
	local record = records[actor]
	return record
			and ((record.Transition and record.Transition:Alive()) or (record.LastMinute and record.LastMinute:Alive()))
		or false
end
return api
