-- Phase25Controller: False Future: the triangle/pulse telegraphs, Future Sight and the evade window.
-- Registers its api.<Name> functions on the shared table from Core; init.luau requires this module.
local Core = require(script.Parent.Core)
local api, Config, Effects, GOLD, Metadata, Placement, Players, Runtime, Shared = Core.api, Core.Config, Core.Effects, Core.GOLD, Core.Metadata, Core.Placement, Core.Players, Core.Runtime, Core.Shared
local Time, addPart, alive, random, recordFor, send = Core.Time, Core.addPart, Core.alive, Core.random, Core.recordFor, Core.send

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

return api
