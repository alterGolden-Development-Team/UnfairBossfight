local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
 
local TAU = math.pi * 2
local GOLD, BRIGHT = Style.GOLD, Style.BRIGHT
local SPARK_TEXTURE = Style.SPARK_TEXTURE
local SMOKE_TEXTURE = Style.SMOKE_TEXTURE

local style = Visuals.style({})

 
 
local makeRing = Visuals.makeRing({
	TAU = TAU,
})

local sparks = Visuals.sparks({
	SPARK_TEXTURE = SPARK_TEXTURE,
	BRIGHT = BRIGHT,
	GOLD = GOLD,
})

local dust = Visuals.dust({
	SMOKE_TEXTURE = SMOKE_TEXTURE,
})

 
local sandDrags = setmetatable({}, { __mode = "k" })
local function clearDrag(character, token)
	local record = sandDrags[character]
	if not record then
		return
	end
	record.Zones[token] = nil
	record.Force.Force = Vector3.zero
	if next(record.Zones) then
		return
	end
	record.Force:Destroy()
	record.Attachment:Destroy()
	sandDrags[character] = nil
end
local function clearDragZone(token)
	for character in pairs(sandDrags) do
		clearDrag(character, token)
	end
end
local function updateDrag(character, token, center, speed, response, maxAcceleration, canAffect)
	local root = character:FindFirstChild("HumanoidRootPart")
	local h = character:FindFirstChildOfClass("Humanoid")
	if not root or not h or h.Health <= 0 then
		clearDrag(character, token)
		return
	end
	local record = sandDrags[character]
	if record and record.Root ~= root then
		record.Force:Destroy()
		record.Attachment:Destroy()
		sandDrags[character] = nil
		record = nil
	end
	if not record then
		local a = Instance.new("Attachment")
		a.Name = "GoldenSandDragAttachment"
		a.Parent = root
		local force = Instance.new("VectorForce")
		force.Name = "GoldenSandDragForce"
		force.Attachment0 = a
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.ApplyAtCenterOfMass = true
		force.Force = Vector3.zero
		force.Parent = root
		record = { Root = root, Attachment = a, Force = force, Zones = {} }
		sandDrags[character] = record
	end
	local entry = record.Zones[token]
	if not entry then
		entry = {}
		record.Zones[token] = entry
	end
	entry.Center = center
	entry.Speed = speed
	entry.Response = response
	entry.MaxAcceleration = maxAcceleration
	if
		not canAffect
		or root.Anchored
		or character:GetAttribute("Dashing")
		or character:GetAttribute("MovementLocked")
		or character:GetAttribute("TimeFrozen")
	then
		record.Force.Force = Vector3.zero
		return
	end
	 
	 
	local delta, pull, selectedResponse, cap, nearest = nil, 0, response, maxAcceleration, math.huge
	for _, zone in pairs(record.Zones) do
		local offset = zone.Center - root.Position
		offset = Vector3.new(offset.X, 0, offset.Z)
		if offset.Magnitude < nearest then
			delta = offset
			pull = zone.Speed
			selectedResponse = zone.Response
			cap = zone.MaxAcceleration
			nearest = offset.Magnitude
		end
	end
	local velocity = root.AssemblyLinearVelocity
	 
	 
	local acceleration = Vector3.zero
	if delta and delta.Magnitude > 0.6 then
		local inward = delta.Unit
		local desiredSpeed = math.min(pull, delta.Magnitude * 3)
		acceleration = inward * (desiredSpeed - Vector3.new(velocity.X, 0, velocity.Z):Dot(inward)) * selectedResponse
	end
	if acceleration.Magnitude > cap then
		acceleration = acceleration.Unit * cap
	end
	record.Force.Force = acceleration * root.AssemblyMass
end
return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	 
	 
	 
	local Debris = Effects
	local Tween = Effects
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Encounter = require(BossSystem.Players.PlayerEncounter)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Players = game:GetService("Players")
	local core = Registry.For(actor, "P1CombatCore")
	local reference = actor:FindFirstChild("EncounterOwner")
	local owner = reference and reference:IsA("ObjectValue") and reference.Value or actor
	local ownerHumanoid = owner:FindFirstChildOfClass("Humanoid")
	local gold = GOLD
	local bright = BRIGHT
	local api = {}
	local FLAT = CFrame.Angles(0, 0, math.pi * 0.5)  
	local function encounterAlive()
		return owner.Parent and ownerHumanoid and ownerHumanoid.Health > 0 and not owner:GetAttribute("EncounterEnded")
	end
	local part = Visuals.part({
		core = core,
	})
	local function squaredDistance(point, first, last)
		local delta = last - first
		local t = delta:Dot(delta) > 0.001 and math.clamp((point - first):Dot(delta) / delta:Dot(delta), 0, 1) or 0
		local distance = point - (first + delta * t)
		return distance:Dot(distance)
	end

	 
	 
	local shock = Visuals.shock({
		FLAT = FLAT,
		part = part,
		gold = gold,
		style = style,
		makeRing = makeRing,
		bright = bright,
		Tween = Tween,
		Debris = Debris,
	})

	 
	 
	 
	local HAND_GOLD, HAND_DARK = Style.HAND_GOLD, Style.HAND_DARK
	local buildHand = Visuals.buildHand({
		part = part,
		HAND_GOLD = HAND_GOLD,
		HAND_DARK = HAND_DARK,
		bright = bright,
	})

	function api.CreateSandZone(center, radius, duration)
		radius = radius or actor:GetAttribute("GoldenSandRadius") or 26
		duration = duration or actor:GetAttribute("GoldenSandDuration") or 12
		local cast = Effects.NewCast(actor, "GoldenHandSandZone", duration)
		local fullSize = Vector3.new(0.15, radius * 2, radius * 2)
		local zone =
			part(cast, "GoldenSandArea", CFrame.new(center + Vector3.new(0, 0.11, 0)) * FLAT, fullSize, gold, 0.55)
		zone.Shape = Enum.PartType.Cylinder
		 
		zone.Size = Vector3.new(0.15, 2, 2)
		Tween:Create(zone, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = fullSize })
			:Play()

		 
		local rim = part(
			cast,
			"GoldenSandRim",
			CFrame.new(center + Vector3.new(0, 0.16, 0)) * FLAT,
			Vector3.new(0.15, 2, 2),
			gold,
			1
		)
		rim.Shape = Enum.PartType.Cylinder
		style(rim)
		local rimStrokes = makeRing(rim, 6, bright, false)
		Tween:Create(rim, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = fullSize })
			:Play()

		local anchor =
			part(cast, "GoldenSandWindAnchor", CFrame.new(center + Vector3.new(0, 0.4, 0)), Vector3.one * 0.1, gold, 1)
		local attachments = {}
		for index = 1, 6 do
			local a = Instance.new("Attachment")
			a.Parent = anchor
			attachments[index] = a
		end
		for index = 1, 3 do
			local beam = Instance.new("Beam")
			beam.Name = "GoldenSandSweptRibbon"
			beam.Attachment0 = attachments[index * 2 - 1]
			beam.Attachment1 = attachments[index * 2]
			beam.Width0 = 0.22
			beam.Width1 = 0.08
			beam.FaceCamera = true
			beam.Color = ColorSequence.new(gold, bright)
			beam.Transparency = NumberSequence.new(0.45)
			beam.LightEmission = 0.85
			beam.CurveSize0 = radius * 0.4
			beam.CurveSize1 = -radius * 0.4
			beam.Segments = 6
			beam.Parent = anchor
		end

		 
		 
		local emitters = {}
		local function track(emitter, rate)
			emitters[#emitters + 1] = { Emitter = emitter, Base = rate }
		end
		for _, a in ipairs(attachments) do
			local d = dust(a, 7, math.clamp(radius * 0.22, 3, 9), 2.4)
			track(d, 7)
			local s = sparks(a, 6, 5, 0.45, 1.2)
			track(s, 6)
		end
		local column = dust(anchor, 5, 6, 3)
		column.Speed = NumberRange.new(4, 9)
		column.SpreadAngle = Vector2.new(20, 20)
		column.Acceleration = Vector3.new(0, 5, 0)
		track(column, 5)

		 
		local function ripple()
			local ring = part(
				cast,
				"GoldenSandPullRipple",
				CFrame.new(center + Vector3.new(0, 0.18, 0)) * FLAT,
				Vector3.new(0.15, radius * 1.9, radius * 1.9),
				gold,
				1
			)
			ring.Shape = Enum.PartType.Cylinder
			style(ring)
			local stroke = makeRing(ring, 4, bright, false)[1]
			stroke.Transparency = 0.7
			Tween:Create(
				ring,
				TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ Size = Vector3.new(0.15, 3, 3) }
			):Play()
			Tween
				:Create(
					stroke,
					TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Transparency = 1 }
				)
				:Play()
			Debris:AddItem(ring, 1.3)
		end

		local members = {}
		 
		local function clearMembers()
			for char in pairs(members) do
				pcall(Status.RemoveZoneSlow, char, cast)
				pcall(clearDrag, char, cast)
			end
			pcall(clearDragZone, cast)
			table.clear(members)
		end
		cast.OnExpire = clearMembers
		cast.OnDispose = clearMembers
		Audio.Loop(cast, actor, "Sandstorm", anchor)
		local elapsed, scanClock, damageClock, rippleClock = 0, 0, 0, 0.5
		cast:Step(function(dt)
			if not encounterAlive() or not zone.Parent then
				clearMembers()
				cast:Dispose()
				return false
			end
			elapsed += dt
			scanClock += dt
			damageClock += dt
			rippleClock += dt
			local alpha = math.clamp(elapsed / duration, 0, 1)
			local fade = math.max(0, (alpha - 0.9) / 0.1)
			zone.Transparency = 0.45 + 0.2 * fade
			for index, a in ipairs(attachments) do
				local angle = elapsed * 0.85 + index * math.pi / 3
				a.Position = Vector3.new(
					math.cos(angle) * radius * 0.72,
					0.2 + math.sin(angle * 2) * 0.3,
					math.sin(angle) * radius * 0.72
				)
			end
			 
			local rimTransparency = math.clamp(0.2 + 0.15 * math.sin(elapsed * 3) + 0.8 * fade, 0, 1)
			for _, stroke in ipairs(rimStrokes) do
				stroke.Transparency = rimTransparency
			end
			if fade > 0 then
				for _, entry in ipairs(emitters) do
					entry.Emitter.Rate = entry.Base * (1 - fade)
				end
			elseif rippleClock >= 0.9 then
				rippleClock = 0
				ripple()
			end
			if scanClock >= 0.1 then
				scanClock = 0
				local current = {}
				for _, char in ipairs(core.Characters()) do
					if core.Alive(char) then
						local offset = char.HumanoidRootPart.Position - center
						if
							offset.Y >= -2
							and offset.Y <= 9
							and Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius
						then
							current[char] = true
							if not members[char] then
								Status.SetZoneSlow(char, cast, Config.GoldenSandSlow)
							end
						end
					end
				end
				for char in pairs(members) do
					if not current[char] then
						Status.RemoveZoneSlow(char, cast)
						clearDrag(char, cast)
					end
				end
				members = current
			end
			for char in pairs(members) do
				if core.Alive(char) then
					local offset = char.HumanoidRootPart.Position - center
					local inside = offset.Y >= -2
						and offset.Y <= 9
						and Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius
					if inside then
						if Status.IsDebuffImmune(char) then
							clearDrag(char, cast)
						else
							updateDrag(
								char,
								cast,
								center,
								Config.GoldenSandPullSpeed or 14,
								Config.GoldenSandPullResponse or 80,
								Config.GoldenSandPullMaxAcceleration or 1200,
								Encounter.CanReceiveHit(char)
							)
						end
					else
						 
						 
						Status.RemoveZoneSlow(char, cast)
						clearDrag(char, cast)
						members[char] = nil
					end
				else
					Status.RemoveZoneSlow(char, cast)
					clearDrag(char, cast)
					members[char] = nil
				end
			end
			if damageClock >= 0.5 then
				damageClock = 0
				for char in pairs(members) do
					if core.Alive(char) then
						core.Damage(char, 2)
					end
				end
			end
			return true
		end)
		actor:SetAttribute("GoldenSandZonesCreated", (actor:GetAttribute("GoldenSandZonesCreated") or 0) + 1)
		return {
			Cast = cast,
			Center = center,
			Radius = radius,
			Duration = duration,
			Slow = Config.GoldenSandSlow,
			Members = function()
				return members
			end,
		}
	end

	function api.ReleaseHand(character)
		if not core.Alive(character) then
			return nil
		end
		local cast = Effects.NewCast(actor, "GoldenHandProjectile", 2.5)
		local generation = owner:GetAttribute("PhaseGeneration") or 0
		 
		 
		local target = character.HumanoidRootPart.Position + Vector3.new(0, 3, 0)
		local origin = core.Root.Position + core.Root.CFrame.LookVector * 6 + Vector3.new(0, 6, 0)
		local delta = target - origin
		local direction = delta.Magnitude > 0.01 and delta.Unit or core.Root.CFrame.LookVector
		local goal = target + direction * 7
		local duration =
			math.clamp((goal - origin).Magnitude / (actor:GetAttribute("GoldenHandSpeed") or 150), 0.28, 1.2)
		local hand = buildHand(cast)
		local pieces, palm = hand.Pieces, hand.Palm
		 
		local handParts, handFrames = {}, {}
		for index, item in ipairs(pieces) do
			handParts[index] = item.Part
		end
		local function placeHand(frame)
			for index, item in ipairs(pieces) do
				handFrames[index] = frame * item.Offset
			end
			workspace:BulkMoveTo(handParts, handFrames, Enum.BulkMoveMode.FireCFrameChanged)
		end
		placeHand(CFrame.lookAt(origin, origin + direction))

		 
		 
		local trailStart, trailEnd = Instance.new("Attachment"), Instance.new("Attachment")
		trailStart.Parent = hand.Cuff
		trailEnd.Parent = hand.Tips[2]
		local trail = Instance.new("Trail")
		trail.Name = "GoldenHandTrail"
		trail.Attachment0 = trailStart
		trail.Attachment1 = trailEnd
		trail.Lifetime = 0.28
		trail.LightEmission = 1
		trail.FaceCamera = true
		trail.Color = ColorSequence.new(bright, gold)
		trail.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
		trail.Parent = palm
		sparks(palm, 60, 10, 1.1, 0.5)
		dust(palm, 25, 5, 1)
		for _, tip in ipairs(hand.Tips) do
			sparks(tip, 16, 6, 0.6, 0.4)
		end
		local light = Instance.new("PointLight")
		light.Color = gold
		light.Range = 30
		light.Brightness = 4
		light.Shadows = false
		light.Parent = palm
		shock(cast, origin, 2, 16, 0.3, 28, direction)  

		local begin, previous, hit = cast:Now(), origin, {}
		local carried, carriedPlayer, carryStarted, carryOrigin, knockback, carriedHighlight
		local carryDuration = Config.GoldenHandCarryDuration or 0.65
		local carrySpeed = Config.GoldenHandCarrySpeed or 95
		local flatDirection = Vector3.new(direction.X, 0, direction.Z)
		flatDirection = flatDirection.Magnitude > 0.01 and flatDirection.Unit or Vector3.new(0, 0, -1)
		cast.OnDispose = function()
			if carried then
				Status.ReleaseRestraint(carried, cast)
				if carried.Parent then
					carried:SetAttribute("GoldenHandGrabbed", false)
				end
			end
			if carriedHighlight then
				carriedHighlight:Destroy()
				carriedHighlight = nil
			end
			if knockback then
				knockback:Dispose()
				knockback = nil
			end
			cast.CarryCharacter = nil
		end
		cast:Step(function(_, now)
			if
				not encounterAlive()
				or owner:GetAttribute("PhaseTransitionInProgress")
				or (owner:GetAttribute("PhaseGeneration") or 0) ~= generation
			then
				cast:Dispose()
				return false
			end
			local t = math.clamp((now - begin) / duration, 0, 1)
			local position = origin:Lerp(goal, t)
			local completed = t >= 1
			if carried then
				if
					not core.Alive(carried)
					or Status.IsDebuffImmune(carried)
					or (carriedPlayer and carriedPlayer.Character ~= carried)
				then
					completed = true
					position = previous
				else
					local carryTarget = carried.HumanoidRootPart.Position + Vector3.new(0, 3, 0) - flatDirection * 2
					position = carryOrigin:Lerp(carryTarget, math.clamp((now - carryStarted) / 0.08, 0, 1))
					completed = now - carryStarted >= carryDuration
				end
			end
			local step = position - previous
			local wall = step.Magnitude > 0.001 and workspace:Spherecast(previous, 4, step, core.Params())
			if wall then
				position = previous + step.Unit * wall.Distance
				completed = true
			end
			if not carried and not wall then
				for _, char in ipairs(core.Characters()) do
					if
						not hit[char]
						and core.Alive(char)
						and core.CanHit(char, previous)
						and squaredDistance(char.HumanoidRootPart.Position, previous, position) <= 8 * 8
					then
						hit[char] = true
						local dealt = core.Damage(char, actor:GetAttribute("GoldenHandImpactDamage") or 10)
						if
							dealt > 0
							and core.Alive(char)
							and Status.Restrain(char, cast, carryDuration + 0.15, { AllowDefense = true })
						then
							carried = char
							carriedPlayer = Players:GetPlayerFromCharacter(char)
							carryStarted = now
							carryOrigin = position
							completed = false
							cast.CarryCharacter = char
							cast.CarryStartedAt = now
							char:SetAttribute("GoldenHandGrabbed", true)
							Audio.Emit(actor, "HandGrab", char.HumanoidRootPart)
							Audio.Loop(cast, actor, "HandCarry", palm)
							 
							shock(cast, char.HumanoidRootPart.Position, 2, 18, 0.3, 28)
							carriedHighlight = Instance.new("Highlight")
							carriedHighlight.Name = "GoldenHandGrab"
							carriedHighlight.FillColor = gold
							carriedHighlight.OutlineColor = bright
							carriedHighlight.FillTransparency = 0.7
							carriedHighlight.OutlineTransparency = 0
							carriedHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
							carriedHighlight.Adornee = char
							carriedHighlight.Parent = char
							core.ScreenEffect(
								"Shake",
								{ Origin = position, Radius = 60, Duration = 0.2, Intensity = 0.25 }
							)
							actor:SetAttribute("GoldenHandCarryStartedAt", workspace:GetServerTimeNow())
							knockback = Runtime.Knockback(actor, char, flatDirection, {
								Speed = carrySpeed,
								Lift = Config.GoldenHandCarryLift or 15,
								Duration = carryDuration,
								Sustain = carryDuration,
							})
							break
						end
					end
				end
			end
			local frame = CFrame.lookAt(position, position + flatDirection)
			placeHand(frame)
			if completed then
				local center = Placement.GroundPoint(position, { Margin = 5, Clamp = true })
				if center then
					Audio.Emit(actor, "HandExplosion", center)
					local sandRadius = actor:GetAttribute("GoldenSandRadius") or 26
					local flash = Effects.NewCast(actor, "GoldenHandExplosion", 1)
					local orb = part(
						flash,
						"GoldenHandExplosionFlash",
						CFrame.new(center + Vector3.new(0, 3, 0)),
						Vector3.new(4, 4, 4),
						bright,
						0.08
					)
					orb.Shape = Enum.PartType.Ball
					Tween:Create(orb, TweenInfo.new(0.45), { Size = Vector3.new(32, 15, 32), Transparency = 1 }):Play()

					 
					local pillar = part(
						flash,
						"GoldenHandExplosionPillar",
						CFrame.new(center + Vector3.new(0, 8, 0)) * FLAT,
						Vector3.new(16, 9, 9),
						gold,
						0.35
					)
					pillar.Shape = Enum.PartType.Cylinder
					style(pillar, Enum.Material.Neon)
					Tween:Create(pillar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = Vector3.new(34, 3, 3),
						Transparency = 1,
						CFrame = CFrame.new(center + Vector3.new(0, 16, 0)) * FLAT,
					}):Play()
					shock(flash, center + Vector3.new(0, 0.3, 0), 4, sandRadius * 2, 0.6, 20)
					shock(flash, center + Vector3.new(0, 0.35, 0), 4, sandRadius * 1.2, 0.4, 24)
					local burst = part(
						flash,
						"GoldenHandBurstAnchor",
						CFrame.new(center + Vector3.new(0, 1, 0)),
						Vector3.one * 0.1,
						gold,
						1
					)
					local burstSparks = sparks(burst, 0, 55, 1.1, 0.8)
					burstSparks.SpreadAngle = Vector2.new(55, 55)
					burstSparks.Acceleration = Vector3.new(0, -45, 0)
					burstSparks:Emit(70)
					local burstDust = dust(burst, 0, 14, 1.4)
					burstDust.Speed = NumberRange.new(12, 28)
					burstDust.SpreadAngle = Vector2.new(80, 80)
					burstDust:Emit(28)

					api.CreateSandZone(center)
					core.ScreenEffect("Shake", { Origin = center, Radius = 90, Duration = 0.35, Intensity = 0.4 })
					actor:SetAttribute("GoldenHandExplosionAt", workspace:GetServerTimeNow())
				end
				cast:Dispose()
				return false
			end
			previous = position
			return true
		end)
		actor:SetAttribute("GoldenHandsReleased", (actor:GetAttribute("GoldenHandsReleased") or 0) + 1)
		return cast
	end
	function api.CanUse(character)
		return (tonumber(actor:GetAttribute("Phase")) or 1) >= 1.5 and core.Active() and core.Alive(character)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P1.5GoldenHand", function()
			 
			local summon
			local summonClosed = false
			local function closeSummon()
				if summon and not summonClosed then
					summonClosed = true
					pcall(function()
						summon:Dispose()
					end)
				end
			end

			local ok, result = xpcall(function()
				core.Face(character)
				core.Melee.Pose("Windup", 0.15)
				actor:SetAttribute("AttackState", "Golden Hand: summoning")
				Audio.Emit(actor, "HandSummon", core.Root)

				 
				 
				 
				summon = Effects.NewCast(actor, "GoldenHandSummon", 0.75)
				local function summonOrigin()
					return core.Root.Position + core.Root.CFrame.LookVector * 6 + Vector3.new(0, 6, 0)
				end
				local circle =
					part(summon, "GoldenHandSummonCircle", CFrame.new(summonOrigin()), Vector3.new(0.2, 1, 1), gold, 1)
				circle.Shape = Enum.PartType.Cylinder
				style(circle)
				makeRing(circle, 8, bright, true, 12)
				local showLane = Config.GoldenHandTelegraphLane ~= false
				local lane, laneLine
				if showLane then
					lane = part(summon, "GoldenHandLane", CFrame.identity, Vector3.new(16, 0.1, 1), gold, 0.9)
					style(lane, Enum.Material.Neon)
					laneLine =
						part(summon, "GoldenHandLaneLine", CFrame.identity, Vector3.new(0.5, 0.1, 1), bright, 0.5)
					style(laneLine, Enum.Material.Neon)
				end
				local waited = 0
				summon:Step(function(dt)
					waited += dt
					local alpha = math.clamp(waited / 0.45, 0, 1)
					local origin = summonOrigin()
					local dir = core.Root.CFrame.LookVector
					local targetPosition
					if core.Alive(character) then
						targetPosition = character.HumanoidRootPart.Position
						local delta = targetPosition + Vector3.new(0, 3, 0) - origin
						if delta.Magnitude > 0.01 then
							dir = delta.Unit
						end
					end
					local size = 2 + 16 * (1 - (1 - alpha) ^ 3)
					circle.Size = Vector3.new(0.2, size, size)
					circle.CFrame = CFrame.lookAt(origin, origin + dir)
						* CFrame.Angles(0, math.pi * 0.5, 0)
						* CFrame.Angles(waited * 5, 0, 0)
					if showLane and targetPosition then
						local ground = Placement.GroundPoint(targetPosition, { Margin = 5, Clamp = true })
						local floorY = (ground and ground.Y or targetPosition.Y - 3) + 0.15
						local first = Vector3.new(origin.X, floorY, origin.Z)
						local goalPoint = targetPosition + dir * 7
						local last = Vector3.new(goalPoint.X, floorY, goalPoint.Z)
						local length = (last - first).Magnitude
						if length > 1 then
							local frame = CFrame.lookAt(first, last) * CFrame.new(0, 0, -length * 0.5)
							lane.Size = Vector3.new(16, 0.1, length)
							lane.CFrame = frame
							laneLine.Size = Vector3.new(0.5, 0.1, length)
							laneLine.CFrame = frame
							local pulse = 0.5 + 0.5 * math.sin(waited * (14 + 26 * alpha))
							lane.Transparency = 0.92 - 0.25 * alpha
							laneLine.Transparency = 0.65 - 0.3 * pulse
						end
					end
					return true
				end)

				if not core.WaitFor(0.45) or not core.Alive(character) then
					closeSummon()
					return false
				end
				closeSummon()
				core.Melee.Pose("Slash1", 0.1)
				actor:SetAttribute("AttackState", "Golden Hand: release")
				api.ReleaseHand(character)
				return core.WaitFor(0.18)
			end, debug.traceback)

			closeSummon()  
			if not ok then
				error(result, 0)
			end  
			return result
		end)
	end
	function api.Dispose()
		 
	end
	return api
end
