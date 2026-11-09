local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
 
local TweenService = game:GetService("TweenService")
return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Projectiles = require(BossSystem.Combat.ProjectileService)
	local core = Registry.For(actor, "P1CombatCore")
	local api = { Damage = 22, WarningTime = 0.65, ProjectileSpeed = 250, ProjectileRadius = 3.5 }
	local GOLD, BRIGHT = Style.GOLD, Style.BRIGHT
	local DEEP, WHITE = Style.DEEP, Style.WHITE
	local HALF_PI = math.pi * 0.5
	local random = Random.new()
	local OUT = Enum.EasingStyle.Quad

	local part = Visuals.part({
		core = core,
	})
	local function squaredDistance(point, from, finish)
		local delta = finish - from
		local length = delta:Dot(delta)
		local t = length > 0.001 and math.clamp((point - from):Dot(delta) / length, 0, 1) or 0
		local offset = point - (from + delta * t)
		return offset:Dot(offset), t
	end
	 
	local burstRing = Visuals.burstRing({
		part = part,
		HALF_PI = HALF_PI,
		Effects = Effects,
		OUT = OUT,
	})

	 
	 
	api.CreateSpear = Visuals.CreateSpear({
		part = part,
		GOLD = GOLD,
		HALF_PI = HALF_PI,
		WHITE = WHITE,
		BRIGHT = BRIGHT,
		Effects = Effects,
	})

	 
	function api.Launch(origin, direction, options)
		options = options or {}
		local launchDelay = 0
		local damage = api.Damage * (options.DamageScale or 1)
		if not options.IsLastMinuteEcho then
			local snapshot = table.freeze({ Origin = origin, Direction = direction })
			launchDelay = require(BossSystem.Phases.Phase25Controller).OnTemporalEmission(
				actor,
				"P1.5GoldenLance",
				snapshot,
				function(saved, echo)
					return api.Launch(saved.Origin, saved.Direction, echo)
				end
			) or 0
		end
		local cast = Effects.NewCast(
			actor,
			options.IsLastMinuteEcho and "LastMinuteLanceEcho" or "GoldenLanceProjectile",
			2.5 + launchDelay
		)
		local launchAt = cast:Now() + launchDelay
		local visual = api.CreateSpear(cast, CFrame.lookAt(origin, origin + direction), options.Transparency or 0.05)
		local shaft, tip = visual.Shaft, visual.Tip

		 
		local trails = {}
		local ribbon = Visuals.ribbon({
			shaft = shaft,
			visual = visual,
			trails = trails,
		})
		ribbon("GoldenLanceRibbon", 1.1, BRIGHT, GOLD, 0.35, 0.25)
		ribbon("GoldenLanceRibbonCore", 0.22, WHITE, BRIGHT, 0.22, 0)

		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "GoldenLanceSparks"
		sparks.Color = ColorSequence.new(BRIGHT, GOLD)
		sparks.LightEmission = 1
		sparks.Rate = 90
		sparks.Lifetime = NumberRange.new(0.25, 0.5)
		sparks.Speed = NumberRange.new(3, 10)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.Drag = 2
		sparks.Rotation = NumberRange.new(0, 360)
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) })
		sparks.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		sparks.Parent = shaft
		visual:AddExtra(sparks)

		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Brightness = 2.5
		light.Range = 22
		light.Shadows = false
		light.Parent = shaft
		visual:AddExtra(light)

		local position, distance, hit = origin, 0, {}
		local hitNormal
		local function draw()
			visual:Draw(CFrame.lookAt(position, position + direction))
		end
		draw()
		local moving = true
		local flightStarted = false
		local wasFrozen = false

		local impactFx = Visuals.impactFx({
			direction = direction,
			Effects = Effects,
			actor = actor,
			part = part,
			BRIGHT = BRIGHT,
			OUT = OUT,
			burstRing = burstRing,
			GOLD = GOLD,
			random = random,
			TweenService = TweenService,
			get_hitNormal = function() return hitNormal end,
			get_position = function() return position end,
		})

		local function update(dt, skip)
			if not moving or not cast:Alive() then
				return false
			end
			if cast:Now() < launchAt then
				return true
			end
			local frozen = Time.IsStopped(actor)
			if frozen ~= wasFrozen then
				wasFrozen = frozen
				sparks.TimeScale = frozen and 0 or 1
			end
			if frozen then
				return true
			end
			if not flightStarted then
				flightStarted = true
				Audio.Emit(actor, "LanceLaunch", shaft)
				Audio.Loop(cast, actor, "LanceFlight", shaft)
				local muzzle = Effects.NewCast(actor, "GoldenLanceLaunchFlash", 0.5)
				local launchFrame = CFrame.lookAt(position, position + direction)
				burstRing(muzzle, launchFrame * CFrame.new(0, 0, -3), 3, 20, BRIGHT, 0.1, 0.4)
				burstRing(muzzle, launchFrame * CFrame.new(0, 0, -9), 2, 12, GOLD, 0.35, 0.45)
			end
			local step = direction
				* api.ProjectileSpeed
				* (skip and dt or Time.EncounterDelta(actor, math.min(dt, 0.12)))
			local wall = step.Magnitude > 0.001 and workspace:Spherecast(position, 1.1, step, core.Params())
			local finish = wall and position + step.Unit * math.max(0, wall.Distance - 0.05) or position + step
			if wall then
				hitNormal = wall.Normal
			end
			for _, character in ipairs(core.Characters()) do
				if core.Alive(character) and not hit[character] then
					local separation = squaredDistance(character.HumanoidRootPart.Position, position, finish)
					if separation <= api.ProjectileRadius * api.ProjectileRadius then
						hit[character] = true
						if core.Damage(character, damage,"P1.5GoldenLance")>0 then AttackDebuffs.Apply(actor,character,"Vulnerability",3,cast) end
					end
				end
			end
			distance += (finish - position).Magnitude
			position = finish
			draw()
			if wall or distance >= 420 then
				moving = false
				Audio.Emit(actor, "LanceImpact", position)
				impactFx()
				cast:Dispose()
				return false
			end
			return true
		end

		local visuals = {}
		for _, piece in ipairs(visual.Pieces) do
			visuals[piece.Body] = { Lease = Effects.LeaseId(piece.Body), Transparency = piece.Body.Transparency }
		end
		local motion
		motion = Projectiles.RegisterMotion(actor, {
			Cast = cast,
			Skill = "P1.5GoldenLance",
			Moving = function()
				return cast:Now() >= launchAt and moving and cast:Alive()
			end,
			Hide = function(hidden)
				if not moving then
					return
				end
				for body, snapshot in pairs(visuals) do
					if body.Parent and Effects.LeaseId(body) == snapshot.Lease then
						body.Transparency = hidden and 1 or snapshot.Transparency
					end
				end
				for _, trail in ipairs(trails) do
					if trail.Parent then
						trail.Enabled = not hidden
					end
				end
				if sparks.Parent then
					sparks.Enabled = not hidden
				end
				if light.Parent then
					light.Enabled = not hidden
				end
			end,
			Advance = function(seconds)
				local remaining = math.clamp(seconds, 0, 3)
				while remaining > 0.0001 and moving and cast:Alive() do
					local dt = math.min(remaining, 1 / 30)
					update(dt, true)
					remaining -= dt
				end
				return moving
			end,
			Settle = function()
				position = Projectiles.SafeReappearance(position, direction, api.ProjectileRadius + 2, core.Params())
				draw()
			end,
		})
		cast.OnDispose = function()
			moving = false
			if motion then
				motion:Dispose()
			end
			visual:Cleanup()
		end
		cast:Step(function(dt)
			if motion:IsHidden() then
				return true
			end
			return update(dt, false)
		end)
		actor:SetAttribute("GoldenLancesLaunched", (actor:GetAttribute("GoldenLancesLaunched") or 0) + 1)
		return { Cast = cast, Shaft = shaft, Tip = tip, Visual = visual, Motion = motion }
	end

	function api.CanUse(character)
		return (tonumber(actor:GetAttribute("Phase")) or 1) >= 1.5 and core.Active() and core.Alive(character)
	end

	 
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		api.WarningTime = Difficulty.Design("GoldenLance", "Warning", 0.65, actor)
		local leadTime = Difficulty.Design("GoldenLance", "Lead", 0.12, actor)
		local leadCap = Difficulty.Design("GoldenLance", "LeadCap", 3, actor)
		return core.Perform(character, "P1.5GoldenLance", function()
			core.Face(character)
			core.Melee.Pose("Windup", 0.14)
			actor:SetAttribute("AttackState", "Golden Lance: trajectory warning")
			Audio.Emit(actor, "LanceSummon", core.Root)
			local origin = core.Root.CFrame:PointToWorldSpace(Vector3.new(5, 2.5, -2))
			local target = character.HumanoidRootPart.Position + Vector3.new(0, 0.6, 0)
			local delta = target - origin
			local direction = delta.Magnitude > 0.01 and delta.Unit or core.Root.CFrame.LookVector
			local cast = Effects.NewCast(actor, "GoldenLanceWarning", api.WarningTime + 1.3)
			local visual = api.CreateSpear(cast, CFrame.lookAt(origin, origin + direction), 0.75)
			visual:Reveal(0.25)
			cast.OnDispose = function()
				visual:Cleanup()
			end
			local finish = origin + direction * math.min(math.max(delta.Magnitude + 65, 80), 420)

			local anchor = part(cast, "GoldenLanceTrajectoryAnchor", Vector3.one * 0.1, GOLD, 1)
			local first, last = Instance.new("Attachment"), Instance.new("Attachment")
			first.Parent, last.Parent = anchor, anchor
			first.WorldPosition, last.WorldPosition = origin, finish
			local beam = Instance.new("Beam")
			beam.Name = "GoldenLanceTrajectory"
			beam.Attachment0 = first
			beam.Attachment1 = last
			beam.Width0, beam.Width1 = 0.18, 0.18
			beam.Color = ColorSequence.new(GOLD, BRIGHT)
			beam.Transparency = NumberSequence.new(0.25)
			beam.LightEmission = 1
			beam.FaceCamera = true
			beam.Parent = anchor

			 
			local charge = part(cast, "GoldenLanceChargeRing", Vector3.new(0.16, 16, 16), BRIGHT, 0.6)
			charge.Shape = Enum.PartType.Cylinder
			Effects:Create(
				charge,
				TweenInfo.new(api.WarningTime, OUT, Enum.EasingDirection.Out),
				{ Size = Vector3.new(0.16, 3, 3), Transparency = 0.05 }
			):Play()
			local began = cast:Now()
			cast:Step(function(_, now)
				if not cast:Alive() then
					return false
				end
				local frame = CFrame.lookAt(origin, origin + direction)
				visual:Draw(frame)
				charge.CFrame = frame * CFrame.new(0, 0, -2.5) * CFrame.Angles(0, HALF_PI, 0)
				local pulse = 0.18 + 0.07 * math.sin((now - began) * 30)
				beam.Width0, beam.Width1 = pulse, pulse
				return true
			end)

			Audio.Emit(actor, "LanceWarning", origin)
			local trajectoryLocked = false
			local ready = core.WaitForTelegraph("P1.5GoldenLance", api.WarningTime, {
				Shape = "Line",
				Valid = function()
					return core.Active() and core.Alive(character) and cast:Alive()
				end,
				Geometry = function()
					if not trajectoryLocked then
						local current = character.HumanoidRootPart.Position + Vector3.new(0, 0.6, 0)
						local movement = character.HumanoidRootPart.AssemblyLinearVelocity * leadTime
						if movement.Magnitude > leadCap then
							movement = leadCap > 0 and movement.Unit * leadCap or Vector3.zero
						end
						local delta = current + movement - origin
						direction = delta.Magnitude > 0.01 and delta.Unit or core.Root.CFrame.LookVector
					end
					return { Origin = origin, Direction = direction, Length = (finish - origin).Magnitude, Width = 0.18 }
				end,
				Reveal = function(geometry)
					trajectoryLocked = true
					origin = geometry.Origin
					direction = geometry.Direction
					finish = origin + direction * geometry.Length
					first.WorldPosition, last.WorldPosition = origin, finish
					visual:Draw(CFrame.lookAt(origin, origin + direction))
				end,
				SuppressNative = function(hidden)
					beam.Enabled = not hidden
				end,
				Hide = function(hidden)
					visual:SetHidden(hidden)
					beam.Enabled = not hidden
				end,
			})
			cast:Dispose()
			if not ready then
				return false
			end
			core.Melee.Pose("Slash3", 0.09)
			api.Launch(origin, direction)
			 
			for lance = 2, Difficulty.Design("GoldenLance", "Lances", 1, actor) do
				core.Melee.Pose("Windup", 0.08)
				if not core.WaitFor(0.32) or not core.Alive(character) then
					break
				end
				local from = core.Root.CFrame:PointToWorldSpace(Vector3.new(-5, 2.5, -2))
				local aim = character.HumanoidRootPart.Position + Vector3.new(0, 0.6, 0) + character.HumanoidRootPart.AssemblyLinearVelocity * leadTime
				local d = aim - from
				core.Melee.Pose("Slash3", 0.09)
				api.Launch(from, d.Magnitude > 0.01 and d.Unit or core.Root.CFrame.LookVector)
				actor:SetAttribute("GoldenLanceVolley", lance)
			end
			return core.WaitFor(0.18)
		end)
	end
	return api
end
