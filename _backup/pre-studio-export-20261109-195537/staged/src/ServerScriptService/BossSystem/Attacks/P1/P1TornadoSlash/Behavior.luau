local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
 
 
 
 
 
 
 
 
local nextContact = setmetatable({}, { __mode = "k" })
return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Projectiles = require(BossSystem.Combat.ProjectileService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Locomotion = require(BossSystem.Boss.BossLocomotion)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local b = actor
	local core = Registry.For(b, "P1CombatCore")
	local ranged = Registry.For(b, "P1RangedSlashes")
	local root, melee = core.Root, core.Melee
	local Run = game:GetService("RunService")
	local Tween = Effects
	local Debris = Effects
	local api = {}
	local gold = Style.gold
	local bright = Style.bright
	local amber = Style.amber
	local dust = Style.dust
	local SPARKLE = Style.SPARKLE
	local SMOKE = Style.SMOKE

	local key = Visuals.key({})
	local function groundAt(position)
		return core.FloorY(position + Vector3.new(0, 3, 0), core.Params()) or position.Y - 1.4
	end
	local shake = Visuals.shake({
		core = core,
	})
	local sparkBurst = Visuals.sparkBurst({
		core = core,
		gold = gold,
		SPARKLE = SPARKLE,
		bright = bright,
		key = key,
		Debris = Debris,
	})
	local dustBurst = Visuals.dustBurst({
		core = core,
		dust = dust,
		SMOKE = SMOKE,
		key = key,
		Debris = Debris,
	})
	local flashBall = Visuals.flashBall({
		core = core,
		bright = bright,
		Tween = Tween,
		Debris = Debris,
	})
	 
	local floorDisc = Visuals.floorDisc({
		core = core,
		Tween = Tween,
		Debris = Debris,
	})

	api.HitFx = Visuals.HitFx({
		flashBall = flashBall,
		bright = bright,
		sparkBurst = sparkBurst,
	})
	 
	api.ChargeFx = Visuals.ChargeFx({
		root = root,
		groundAt = groundAt,
		floorDisc = floorDisc,
		gold = gold,
		SPARKLE = SPARKLE,
		bright = bright,
		key = key,
	})
	 
	api.PassBurst = Visuals.PassBurst({
		groundAt = groundAt,
		floorDisc = floorDisc,
		amber = amber,
		dustBurst = dustBurst,
		flashBall = flashBall,
		bright = bright,
		sparkBurst = sparkBurst,
		shake = shake,
	})

	function api.DamageSweep(start, finish, candidates, hit, now)
		now = now or Time.EncounterNow(actor)
		local interval = Config.TornadoTickInterval
		local segment = Vector3.new(finish.X - start.X, 0, finish.Z - start.Z)
		local lengthSquared = segment:Dot(segment)
		local radius = b:GetAttribute("TornadoSlashRadius") or 11
		for _, char in ipairs(candidates or core.Characters()) do
			if core.Alive(char) then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local point = char.HumanoidRootPart.Position
				local offset = Vector3.new(point.X - start.X, 0, point.Z - start.Z)
				local fraction = lengthSquared > 0.001 and math.clamp(offset:Dot(segment) / lengthSquared, 0, 1) or 0
				local closest = start:Lerp(finish, fraction)
				if
					now + 0.0001 >= (nextContact[hum] or -math.huge)
					and math.abs(point.Y - closest.Y) <= 7
					and Vector3.new(point.X - closest.X, 0, point.Z - closest.Z).Magnitude <= radius
					and core.CanHit(char, closest)
				then
					nextContact[hum] = now + interval
					if hit then
						hit[hum] = nextContact[hum]
					end
					if core.Damage(char, Config.TornadoTickDamage) > 0 then
						api.HitFx(point)
						Status.ApplyBleed(char, Config.TornadoBleedDuration, actor)
						b:SetAttribute("TornadoSlashHits", (b:GetAttribute("TornadoSlashHits") or 0) + 1)
					end
				end
			end
		end
	end

	local spinRing
	local ringLayers
	local ringBeams = {}
	local spinClock = 0
	local spinRate = 1
	 
	local RING_RADII = { 5, 7.5, 9.5, 11 }
	local RING_HEIGHTS = { -1, 2.2, 5.4, 8.6 }
	local RING_WIDTHS = { 1.2, 1.5, 1.8, 2.1 }
	local ARC_SPAN = math.rad(28)  
	local TAIL_WIDTH = { 0.12, 0.4, 0.75, 1 }
	local TAIL_ALPHA = { 0.9, 0.65, 0.3, 0.08 }
	local TAIL_COLORS = { gold, amber, bright, bright }

	local addBeam = Visuals.addBeam({
		get_ringBeams = function() return ringBeams end,
	})
	local function buildRing(position)
		local model = Instance.new("Model")
		model.Name = "GoldenTornadoReusableRings"
		model.WorldPivot = CFrame.new(position)
		model.Parent = core.Effects
		local scale = (b:GetAttribute("TornadoSlashRadius") or 11) / 11
		ringLayers = {}
		ringBeams = {}
		spinClock = 0
		local ribPoints = {}
		for k = 1, 4 do
			local radius = RING_RADII[k] * scale
			local anchor = core.Part(
				"GoldenTornadoLayer",
				CFrame.new(position) * CFrame.new(0, RING_HEIGHTS[k], 0),
				Vector3.new(radius * 1.3, 0.2, radius * 1.3),
				gold,
				1
			)
			anchor.Parent = model
			 
			local headPosition
			for arc = 0, 2 do
				local base = arc * math.pi * 2 / 3 + k * 0.4
				local points = {}
				for j = 0, 3 do
					local a = base + j * ARC_SPAN
					local attachment = Instance.new("Attachment")
					attachment.Position = Vector3.new(math.sin(a) * radius, (j / 3 - 0.5) * 1.2, math.cos(a) * radius)
					attachment.Parent = anchor
					points[j + 1] = attachment
				end
				for j = 1, 3 do
					addBeam(
						anchor,
						points[j],
						points[j + 1],
						RING_WIDTHS[k] * TAIL_WIDTH[j],
						RING_WIDTHS[k] * TAIL_WIDTH[j + 1],
						TAIL_COLORS[j],
						TAIL_COLORS[j + 1],
						TAIL_ALPHA[j],
						TAIL_ALPHA[j + 1],
						1
					)
				end
				if arc == 0 then
					headPosition = points[4].Position
				end
			end
			 
			ribPoints[k] = {}
			for i = 0, 2 do
				local a = i * math.pi * 2 / 3
				local attachment = Instance.new("Attachment")
				attachment.Position = Vector3.new(math.sin(a) * radius, 0, math.cos(a) * radius)
				attachment.Parent = anchor
				ribPoints[k][i + 1] = attachment
			end
			 
			if k >= 3 then
				local t0, t1 = Instance.new("Attachment"), Instance.new("Attachment")
				t0.Position = headPosition + Vector3.new(0, 0.8, 0)
				t1.Position = headPosition - Vector3.new(0, 0.8, 0)
				t0.Parent = anchor
				t1.Parent = anchor
				local trail = Instance.new("Trail")
				trail.Name = "GoldenTornadoCurtain"
				trail.Attachment0 = t0
				trail.Attachment1 = t1
				trail.Lifetime = 0.3
				trail.LightEmission = 1
				trail.FaceCamera = false
				trail.MinLength = 0.1
				trail.Color = ColorSequence.new(bright, gold)
				trail.Transparency = NumberSequence.new({ key(0, 0.35), key(1, 1) })
				trail.Parent = anchor
			end
			if k == 1 then
				 
				local dustEmitter = Instance.new("ParticleEmitter")
				dustEmitter.Name = "GoldenTornadoFloorDust"
				dustEmitter.Texture = SMOKE
				dustEmitter.Color = ColorSequence.new(dust)
				dustEmitter.Rate = 35
				dustEmitter.Lifetime = NumberRange.new(0.5, 0.9)
				dustEmitter.Speed = NumberRange.new(6, 14)
				dustEmitter.SpreadAngle = Vector2.new(70, 70)
				dustEmitter.EmissionDirection = Enum.NormalId.Top
				dustEmitter.Acceleration = Vector3.new(0, -4, 0)
				dustEmitter.Rotation = NumberRange.new(0, 360)
				dustEmitter.Size = NumberSequence.new({ key(0, 2), key(1, 6) })
				dustEmitter.Transparency = NumberSequence.new({ key(0, 0.6), key(1, 1) })
				dustEmitter.Parent = anchor
			elseif k == 2 then
				local light = Instance.new("PointLight")
				light.Color = gold
				light.Range = 28
				light.Brightness = 2.5
				light.Shadows = false
				light.Parent = anchor
			elseif k == 3 then
				local sparks = Instance.new("ParticleEmitter")
				sparks.Name = "GoldenTornadoSparks"
				sparks.Texture = SPARKLE
				sparks.Color = ColorSequence.new(bright, gold)
				sparks.LightEmission = 1
				sparks.Rate = 30
				sparks.Lifetime = NumberRange.new(0.3, 0.6)
				sparks.Speed = NumberRange.new(8, 18)
				sparks.SpreadAngle = Vector2.new(180, 180)
				sparks.Acceleration = Vector3.new(0, -10, 0)
				sparks.Size = NumberSequence.new({ key(0, 0.5), key(1, 0) })
				sparks.Transparency = NumberSequence.new({ key(0, 0.1), key(1, 1) })
				sparks.Parent = anchor
			end
			ringLayers[k] = { Anchor = anchor, Height = RING_HEIGHTS[k] }
		end
		 
		for i = 1, 3 do
			for k = 1, 3 do
				addBeam(
					ringLayers[k].Anchor,
					ribPoints[k][i],
					ribPoints[k + 1][i],
					0.5,
					0.5,
					gold,
					gold,
					0.55,
					0.55,
					0.8
				)
			end
		end
		return model
	end
	 
	function api.PoseRing(position, dt)
		if not spinRing or not spinRing.Parent or not ringLayers then
			return
		end
		spinClock += dt or 0
		for k, layer in ipairs(ringLayers) do
			if layer.Anchor.Parent then
				local angle = spinClock * spinRate * 4.2 * (1 + 0.06 * (k - 1)) + (k - 1) * 0.55
				layer.Anchor.CFrame = CFrame.new(position) * CFrame.new(0, layer.Height, 0) * CFrame.Angles(0, angle, 0)
			end
		end
	end
	 
	function api.SetRingCharge(charging)
		local boost = charging and 0.35 or 0
		for _, item in ipairs(ringBeams) do
			if item.Beam.Parent then
				item.Beam.Transparency = NumberSequence.new(math.min(1, item.A0 + boost), math.min(1, item.A1 + boost))
			end
		end
	end
	function api.SpinEffects(frame, index, phase)
		if not spinRing or not spinRing.Parent then
			spinRing = buildRing(frame.Position)
		end
		spinRate = index == 1 and 1 or 1.4
		api.PoseRing(frame.Position, 0)
		core.Afterimage(frame)
	end
	local function clearRing()
		if spinRing then
			Effects.Release(spinRing)
			spinRing = nil
		end
		ringLayers = nil
		ringBeams = {}
		spinClock = 0
	end
	 
	 
	do
		local warned = {}
		for _, name in ipairs({ "HitFx", "ChargeFx", "PassBurst", "PoseRing", "SetRingCharge", "SpinEffects" }) do
			local inner = api[name]
			api[name] = function(...)
				local ok, err = pcall(inner, ...)
				if not ok and not warned[name] then
					warned[name] = true
					warn("[P1TornadoSlash] " .. name .. " VFX failed: " .. tostring(err))
				end
			end
		end
	end
	function api.Pass(char, index, sharedTicks)
		if not core.Active() or not core.Alive(char) then
			return false
		end
		local pos = char.HumanoidRootPart.Position
		local offset = Vector3.new(pos.X - root.Position.X, 0, pos.Z - root.Position.Z)
		local direction = offset.Magnitude > 0.01 and offset.Unit or root.CFrame.LookVector
		local range = math.max(offset.Magnitude + 16, 40)
		local speed = b:GetAttribute(index == 1 and "TornadoFirstSpeed" or "TornadoSecondSpeed")
			or (index == 1 and 120 or 190)
		local duration = range / speed
		local elapsed, moved, lastEffect = 0, 0, -1
		local hit = sharedTicks or {}
		local p = core.Params(char)
		local moving = true
		local hover = 1.4
		local floor = core.FloorY(root.Position + Vector3.new(0, 3, 0), p)
		if not floor then
			return false
		end
		root.CFrame = CFrame.lookAt(
			Vector3.new(root.Position.X, floor + hover, root.Position.Z),
			Vector3.new(root.Position.X, floor + hover, root.Position.Z) + direction
		)
		local orientation = root.CFrame.Rotation
		b:SetAttribute("AttackState", "Tornado Slash: spinning pass " .. index)
		api.SpinEffects(root.CFrame, index, 0)
		api.PassBurst(root.Position, false)
		local cast = Effects.NewCast(actor, "GoldenTornadoActivePass", duration + 2)
		local visuals = {}
		local ownsHidden = false
		local function snapshot(object)
			if visuals[object] then
				return
			end
			if object:IsA("BasePart") or object:IsA("Decal") then
				visuals[object] = { Alpha = object.Transparency, Lease = Effects.LeaseId(object) }
			elseif
				object:IsA("ParticleEmitter")
				or object:IsA("Trail")
				or object:IsA("Beam")
				or object:IsA("Light")
				or object:IsA("BillboardGui")
				or object:IsA("SurfaceGui")
			then
				visuals[object] = { Enabled = object.Enabled }
			end
		end
		for _, object in ipairs(b:GetDescendants()) do
			snapshot(object)
		end
		if spinRing then
			for _, object in ipairs(spinRing:GetDescendants()) do
				snapshot(object)
			end
		end
		local function hide(hidden)
			if hidden then
				if not b:GetAttribute("IsGoldenClone") then
					return
				end
				ownsHidden = true
			elseif not ownsHidden then
				return
			else
				ownsHidden = false
			end
			for object, state in pairs(visuals) do
				if object.Parent and (state.Lease == nil or Effects.LeaseId(object) == state.Lease) then
					if state.Alpha ~= nil then
						object.Transparency = hidden and 1 or state.Alpha
					elseif state.Enabled ~= nil then
						object.Enabled = not hidden and state.Enabled
					end
				end
			end
		end
		local function update(dt, skipping)
			if not moving or not core.Active() or not core.Alive(char) or not root.Parent then
				moving = false
				return false
			end
			dt = math.min(math.max(0, dt), duration - elapsed)
			if dt <= 0.00001 then
				if elapsed >= duration - 0.00001 then
					moving = false
				end
				return moving
			end
			elapsed += dt
			local step = direction * speed * dt
			local old = root.Position
			local castFrame = CFrame.new(old) * orientation
			local wall = step.Magnitude > 0.01 and workspace:Blockcast(castFrame, Vector3.new(2.3, 2.7, 2.3), step, p)
			if wall then
				step = direction * math.max(0, wall.Distance - 0.25)
			end
			local nextPos = old + step
			local nextFloor = core.FloorY(nextPos + Vector3.new(0, 3, 0), p)
			if not nextFloor or math.abs(nextFloor + hover - old.Y) > 4 then
				moving = false
				return false
			end
			nextPos = Vector3.new(nextPos.X, nextFloor + hover, nextPos.Z)
			if not skipping then
				api.DamageSweep(old, nextPos, nil, hit)
			end
			local phase = elapsed * (index == 1 and 8 or 12) * math.pi
			root.CFrame = CFrame.new(nextPos) * orientation * CFrame.Angles(0, phase, 0)
			moved += step.Magnitude
			api.PoseRing(root.Position, dt)
			if not skipping and elapsed - lastEffect >= 0.05 then
				api.SpinEffects(root.CFrame, index, phase)
				lastEffect = elapsed
				Audio.Emit(actor, "TornadoCut", root)
				core.MotionLine(
					"TornadoGoldenWake",
					old - Vector3.new(0, 1, 0),
					nextPos - Vector3.new(0, 1, 0),
					0.65,
					gold,
					0.22
				)
			end
			if wall or elapsed >= duration - 0.00001 then
				moving = false
			end
			return moving
		end
		local motion = Projectiles.RegisterMotion(actor, {
			Cast = cast,
			Skill = "P1TornadoSlash",
			Moving = function()
				return moving and cast:Alive() and core.Active() and core.Alive(char)
			end,
			Hide = hide,
			Advance = function(seconds)
				local remaining = math.min(math.clamp(seconds, 0, 3), math.max(0, duration - elapsed))
				Locomotion.AdvancePose(actor, remaining)
				while remaining > 0.00001 and moving and cast:Alive() do
					local dt = math.min(remaining, 1 / 60)
					update(dt, true)
					remaining -= dt
				end
				return true
			end,
			Settle = function()
				if not root.Parent then
					return
				end
				local point = Projectiles.SafeReappearance(root.Position, direction, 4, p)
				local delta = point - root.Position
				if
					delta.Magnitude < 0.001
					or not workspace:Blockcast(root.CFrame, Vector3.new(2.3, 2.7, 2.3), delta, p)
				then
					local valid = Placement.Validate(actor, CFrame.new(point) * root.CFrame.Rotation, { Margin = 4 })
					if valid then
						root.CFrame = valid + Vector3.new(0, hover, 0)
					end
				end
				api.PoseRing(root.Position, 0)
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end,
		})
		cast.OnDispose = function()
			moving = false
			motion:Dispose()
			table.clear(visuals)
		end
		Audio.Loop(cast, actor, "TornadoWind", root)
		local sampledAt = Time.ActionNow(actor)
		while moving and cast:Alive() do
			if not Time.WaitForActor(actor) or not core.Active() or not core.Alive(char) then
				cast:Dispose()
				return false
			end
			local now = Time.ActionNow(actor)
			local dt = math.max(0, now - sampledAt)
			sampledAt = now
			if not motion:IsHidden() then
				update(dt, false)
			end
			if moving then
				Run.Heartbeat:Wait()
			end
		end
		cast:Dispose()
		if not core.Active() or not core.Alive(char) then
			return false
		end
		api.PassBurst(root.Position, true)
		core.Face(char)
		b:SetAttribute("LastTornadoPass" .. index .. "Speed", speed)
		b:SetAttribute("LastTornadoPass" .. index .. "Distance", moved)
		b:SetAttribute("LastTornadoPass" .. index .. "Duration", elapsed)
		b:SetAttribute("TornadoPassCount", (b:GetAttribute("TornadoPassCount") or 0) + 1)
		return true
	end
	function api.Combo(char)
		local lightSword
		local ticks = {}
		local result = core.Perform(char, "Tornado Slash", function()
			core.Face(char)
			lightSword = ranged.SummonLightSword(60)
			b:SetAttribute("AttackState", "Tornado Slash: summon golden sword")
			Audio.Emit(actor, "TornadoBuild", root)
			api.ChargeFx(0.34)
			core.PoseAngles({
				RightShoulder = { 65, 0, 75 },
				RightElbow = { 10, 0, 0 },
				LeftShoulder = { 65, 0, -75 },
				LeftElbow = { 10, 0, 0 },
				Waist = { 10, 0, 0 },
				RightHip = { -15, 0, 0 },
				LeftHip = { 15, 0, 0 },
			}, 0.15)
			if not core.WaitFor(0.34) then
				return false
			end
			b["Basic Sword"].Blade.SlashTrail.Enabled = true
			if not api.Pass(char, 1, ticks) then
				return false
			end
			b:SetAttribute("AttackState", "Tornado Slash: second wave charge")
			Audio.Emit(actor, "TornadoBuild", root)
			api.ChargeFx(0.5)
			core.PoseAngles(
				{ RightShoulder = { 95, 0, 35 }, LeftShoulder = { 95, 0, -35 }, Waist = { -8, 0, 0 } },
				0.12
			)
			api.SetRingCharge(true)
			local chargeStart = Time.ActionNow(actor)
			if not core.WaitFor(0.5) then
				return false
			end
			b:SetAttribute("LastTornadoChargeDuration", Time.ActionNow(actor) - chargeStart)
			api.SetRingCharge(false)
			if not api.Pass(char, 2, ticks) then
				return false
			end
			if not core.WaitFor(0.12) then
				return false
			end
			b:SetAttribute("CompletedTornadoSlashes", (b:GetAttribute("CompletedTornadoSlashes") or 0) + 1)
			return true
		end)
		clearRing()
		if lightSword and lightSword.Parent then
			Debris:AddItem(lightSword, 0)
		end
		return result
	end
	return api
end
