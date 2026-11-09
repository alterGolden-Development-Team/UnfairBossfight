local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Run = game:GetService("RunService")
	local core = Registry.For(actor, "P1CombatCore")
	local api = {
		Damage = Config.BlockGrabDamage or 15,
		WaveDamage = Config.BlockGrabWaveDamage or 10,
		WaveRadius = Config.BlockGrabWaveRadius or 28,
		WaveDuration = Config.BlockGrabWaveDuration or 0.9,
		AimTime = Config.BlockGrabAimTime or 0.45,
		ProjectileSpeed = Config.BlockGrabSpeed or 120,
	}
	local GOLD, BRIGHT, EARTH = Color3.fromRGB(255, 212, 31), Color3.fromRGB(255, 250, 181), Color3.fromRGB(104, 85, 56)
	local DEEP = Style.DEEP
	local DUST = Style.DUST
	local random = Random.new()

	local function closest(point, from, finish)
		local delta = finish - from
		local length = delta:Dot(delta)
		local fraction = length > 0.001 and math.clamp((point - from):Dot(delta) / length, 0, 1) or 0
		return (point - (from + delta * fraction)).Magnitude, fraction
	end

	 
	local disc = Visuals.disc({
		core = core,
		Effects = Effects,
	})
	 
	local glowBall = Visuals.glowBall({
		core = core,
		BRIGHT = BRIGHT,
		Effects = Effects,
	})
	 
	local bolt = Visuals.bolt({
		random = random,
		core = core,
		BRIGHT = BRIGHT,
		GOLD = GOLD,
	})
	 
	local radial = Visuals.radial({
		random = random,
		core = core,
		GOLD = GOLD,
		BRIGHT = BRIGHT,
	})
	 
	local fountain = Visuals.fountain({
		core = core,
		GOLD = GOLD,
		BRIGHT = BRIGHT,
		Effects = Effects,
	})
	 
	local dustPuff = Visuals.dustPuff({
		core = core,
		EARTH = EARTH,
		DUST = DUST,
		Effects = Effects,
	})
	 
	local debris = Visuals.debris({
		random = random,
		core = core,
		GOLD = GOLD,
		EARTH = EARTH,
		Effects = Effects,
	})

	local chunk = Visuals.chunk({
		random = random,
		core = core,
		EARTH = EARTH,
		GOLD = GOLD,
		BRIGHT = BRIGHT,
		DUST = DUST,
	})
	local setChunkEmission = Visuals.setChunkEmission({})

	function api.Shockwave(position, excludedCharacter)
		Audio.Emit(actor, "BlockWave", position)
		local cast = Effects.NewCast(actor, "BlockGrabSmallShockwave", api.WaveDuration + 0.2)
		local anchor = cast:Add(
			core.Part("BlockGrabWaveAnchor", CFrame.new(position + Vector3.new(0, 0.16, 0)), Vector3.one * 0.1, GOLD, 1)
		)
		local count = 32
		local points = {}
		for index = 1, count do
			local point = Instance.new("Attachment")
			point.Parent = anchor
			points[index] = point
		end
		local beams, glows, emitters = {}, {}, {}
		for index, point in ipairs(points) do
			local beam = Instance.new("Beam")
			beam.Name = "BlockGrabJumpWave"
			beam.Attachment0 = point
			beam.Attachment1 = points[index % #points + 1]
			beam.Width0, beam.Width1 = 0.8, 0.8
			beam.FaceCamera = true
			beam.LightEmission = 1
			beam.Color = ColorSequence.new(BRIGHT, GOLD)
			beam.Transparency = NumberSequence.new(0.12)
			beam.Parent = anchor
			beams[index] = beam
			 
			local glow = Instance.new("Beam")
			glow.Name = "BlockGrabJumpWaveGlow"
			glow.Attachment0 = point
			glow.Attachment1 = points[index % #points + 1]
			glow.Width0, glow.Width1 = 2.6, 2.6
			glow.FaceCamera = true
			glow.LightEmission = 1
			glow.Color = ColorSequence.new(GOLD, DEEP)
			glow.Transparency = NumberSequence.new(0.65)
			glow.Parent = anchor
			glows[index] = glow
			 
			if index % 2 == 0 then
				local dust = Instance.new("ParticleEmitter")
				dust.Name = "BlockGrabWaveDust"
				dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
				dust.Color = ColorSequence.new(DUST, EARTH)
				dust.Rate = 8
				dust.Lifetime = NumberRange.new(0.5, 0.9)
				dust.Speed = NumberRange.new(1, 4)
				dust.SpreadAngle = Vector2.new(60, 60)
				dust.EmissionDirection = Enum.NormalId.Top
				dust.Rotation = NumberRange.new(0, 360)
				dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5) })
				dust.Transparency =
					NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
				dust.Parent = point
				table.insert(emitters, { Emitter = dust, Rate = 8 })
			end
			if index % 4 == 0 then
				local spark = Instance.new("ParticleEmitter")
				spark.Name = "BlockGrabWaveSparks"
				spark.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				spark.Color = ColorSequence.new(BRIGHT, GOLD)
				spark.LightEmission = 1
				spark.Rate = 14
				spark.Lifetime = NumberRange.new(0.3, 0.7)
				spark.Speed = NumberRange.new(4, 9)
				spark.SpreadAngle = Vector2.new(50, 50)
				spark.EmissionDirection = Enum.NormalId.Top
				spark.Size =
					NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
				spark.Parent = point
				table.insert(emitters, { Emitter = spark, Rate = 14 })
			end
		end
		local flash = cast:Add(
			core.Part(
				"BlockGrabImpactFlash",
				CFrame.new(position + Vector3.new(0, 1, 0)),
				Vector3.one * 2,
				BRIGHT,
				0.12
			)
		)
		flash.Shape = Enum.PartType.Ball
		flash.Material = Enum.Material.Neon
		Effects:Create(flash, TweenInfo.new(0.3), { Size = Vector3.new(15, 5, 15), Transparency = 1 }):Play()
		Effects.ReleaseAfter(flash, 0.4)
		 
		do
			local ground = position + Vector3.new(0, 0.2, 0)
			disc(ground, 4, api.WaveRadius * 2.2, 0.5, GOLD, 0.4)
			disc(ground, 2, api.WaveRadius * 1.4, 0.35, BRIGHT, 0.25)
			glowBall(position + Vector3.new(0, 2, 0), 14, 0.3, DEEP)
			dustPuff(position, 22)
			fountain(position, 24)
			debris(position, 8)
			for i = 1, 8 do
				local angle = i / 8 * math.pi * 2 + random:NextNumber(-0.2, 0.2)
				local d = Vector3.new(math.cos(angle), 0, math.sin(angle))
				bolt(
					ground + d * 2,
					ground + d * random:NextNumber(api.WaveRadius * 0.3, api.WaveRadius * 0.85),
					1.2,
					0.2,
					6,
					0.4
				)
			end
		end
		local elapsed, previous, hits = 0, 0, {}
		cast:Step(function(dt)
			elapsed += dt
			local progress = math.clamp(elapsed / api.WaveDuration, 0, 1)
			local radius = 1 + (api.WaveRadius - 1) * progress
			for index, point in ipairs(points) do
				local angle = index * math.pi * 2 / #points
				point.Position = Vector3.new(math.cos(angle) * radius, 0.28, math.sin(angle) * radius)
				beams[index].Transparency = NumberSequence.new(0.12 + 0.82 * progress)
				glows[index].Transparency = NumberSequence.new(0.6 + 0.4 * progress)
				local width = 0.8 * (1 - progress * 0.5)
				beams[index].Width0, beams[index].Width1 = width, width
			end
			for _, item in ipairs(emitters) do
				item.Emitter.Rate = item.Rate * (1 - progress)
			end
			for _, character in ipairs(core.Characters()) do
				if character ~= excludedCharacter and core.Alive(character) and not hits[character] then
					local offset = character.HumanoidRootPart.Position - position
					local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
					if
						offset.Y >= -1
						and offset.Y <= 4.7
						and distance >= math.max(0, previous - 2.5)
						and distance <= radius + 2.5
					then
						hits[character] = true
						core.Damage(character, api.WaveDamage)
						glowBall(character.HumanoidRootPart.Position, 6, 0.22, BRIGHT)
					end
				end
			end
			previous = radius
			return progress < 1
		end)
		actor:SetAttribute("BlockGrabShockwaves", (actor:GetAttribute("BlockGrabShockwaves") or 0) + 1)
		return cast
	end
	function api.Throw(origin, targetPosition, body, existingCast)
		local ground = Placement.GroundPoint(targetPosition, { Margin = 5, Clamp = true })
		if not ground then
			if existingCast then
				existingCast:Dispose()
			end
			return nil
		end
		local cast = existingCast or Effects.NewCast(actor, "BlockGrabEarthProjectile", 5)
		body = body or chunk(cast, CFrame.new(origin))
		Audio.Emit(actor, "BlockLaunch", body)
		local goal = ground + Vector3.new(0, body.Size.Y * 0.5, 0)
		local duration = math.max(0.25, (goal - origin).Magnitude / api.ProjectileSpeed)
		 
		do
			local direction = (goal - origin)
			direction = direction.Magnitude > 0.01 and direction.Unit or Vector3.zAxis
			local side = direction:Cross(Vector3.yAxis)
			side = side.Magnitude > 0.01 and side.Unit or Vector3.xAxis
			glowBall(origin, 9, 0.22, BRIGHT)
			radial(origin, side, side:Cross(direction), 10, 1.5, 7, 0.15, 0.25)
			fountain(origin, 10)
			setChunkEmission(body, 60, 80)
			local light = body:FindFirstChild("BlockGrabGlow")
			if light then
				light.Brightness = 3
				light.Range = 20
			end
			local outline = body:FindFirstChild("GoldenBlockGrabEnergy")
			if outline then
				outline.FillTransparency = 0.35
			end
		end
		local elapsed, previous = 0, origin
		cast:Step(function(dt)
			elapsed += dt
			local progress = math.clamp(elapsed / duration, 0, 1)
			local position = origin:Lerp(goal, progress) + Vector3.new(0, math.sin(progress * math.pi) * 4, 0)
			local step = position - previous
			 
			 
			local wall = step.Magnitude > 0.001
				and workspace:Blockcast(CFrame.new(previous), body.Size * 0.8, step, core.Params())
			local hitCharacter, hitTime
			for _, character in ipairs(core.Characters()) do
				if core.Alive(character) then
					local distance, fraction = closest(character.HumanoidRootPart.Position, previous, position)
					if distance <= body.Size.Magnitude * 0.4 and (not hitTime or fraction < hitTime) then
						hitCharacter, hitTime = character, fraction
					end
				end
			end
			if wall and (not hitTime or wall.Distance <= step.Magnitude * hitTime) then
				position = previous + step.Unit * wall.Distance
				hitCharacter = nil
				progress = 1
			elseif hitCharacter then
				position = previous:Lerp(position, hitTime)
				core.Damage(hitCharacter, api.Damage)
				progress = 1
			end
			 
			if (position - previous).Magnitude > 0.3 then
				core.MotionLine("BlockGrabThrowGlow", previous, position, 3, DEEP, 0.25)
				core.MotionLine("BlockGrabThrowTrail", previous, position, 1.3, GOLD, 0.3)
				core.MotionLine("BlockGrabThrowCore", previous, position, 0.35, BRIGHT, 0.3)
			end
			body.CFrame = CFrame.new(position) * CFrame.Angles(progress * 1.8, progress * 4.3, progress * 0.8)
			if progress >= 1 then
				Audio.Emit(actor, "BlockImpact", position)
				local center = Placement.GroundPoint(position, { Margin = 2, Clamp = true }) or ground
				 
				setChunkEmission(body, 0, 0)
				glowBall(position, 12, 0.25, BRIGHT)
				debris(position, 8)
				if hitCharacter then
					glowBall(hitCharacter.HumanoidRootPart.Position, 9, 0.25, BRIGHT)
				end
				api.Shockwave(center, hitCharacter)
				core.ScreenEffect("Shake", { Origin = center, Radius = 75, Duration = 0.25, Intensity = 0.3 })
				actor:SetAttribute("BlockGrabImpacts", (actor:GetAttribute("BlockGrabImpacts") or 0) + 1)
				cast:Dispose()
				return false
			end
			previous = position
			return true
		end)
		actor:SetAttribute("BlockGrabsThrown", (actor:GetAttribute("BlockGrabsThrown") or 0) + 1)
		return { Cast = cast, Body = body, Position = ground }
	end
	 
	local startAimVfx = Visuals.startAimVfx({
		Effects = Effects,
		actor = actor,
		core = core,
		GOLD = GOLD,
		BRIGHT = BRIGHT,
		random = random,
	})
	function api.CanUse(character)
		return core.Active() and core.Alive(character)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P1BlockGrab", function()
			core.Face(character)
			core.Melee.Pose("Windup3", 0.15)
			local ground = Placement.GroundPoint(
				core.Root.CFrame:PointToWorldSpace(Vector3.new(5, 0, -3)),
				{ Margin = 6, Clamp = true }
			)
			if not ground then
				return false
			end
			local cast = Effects.NewCast(actor, "BlockGrabEarthProjectile", 6)
			local body = chunk(cast, CFrame.new(ground - Vector3.new(0, 3, 0)))
			local start, elapsed = body.Position, 0
			actor:SetAttribute("AttackState", "Block Grab: tearing earth")
			Audio.Emit(actor, "BlockCrack", body)
			 
			do
				local floor = ground + Vector3.new(0, 0.15, 0)
				disc(floor, 3, 20, 0.4, GOLD, 0.4)
				glowBall(ground + Vector3.new(0, 1, 0), 7, 0.22, BRIGHT)
				dustPuff(ground, 18)
				debris(ground, 6)
				fountain(ground, 14)
				for i = 1, 8 do
					local angle = i / 8 * math.pi * 2 + random:NextNumber(-0.2, 0.2)
					local d = Vector3.new(math.cos(angle), 0, math.sin(angle))
					bolt(floor + d * 2, floor + d * random:NextNumber(8, 15), 1, 0.18, 5, 0.4)
				end
			end
			local tetherTimer, emitting = 0, false
			while elapsed < 0.4 do
				if not core.Active() or not core.Alive(character) then
					cast:Dispose()
					return false
				end
				local dt = Run.Heartbeat:Wait()
				elapsed += dt * Time.BossRate(actor)
				local goal = core.Root.CFrame:PointToWorldSpace(Vector3.new(5, 4, -3))
				body.CFrame = CFrame.new(start:Lerp(goal, math.sin(math.clamp(elapsed / 0.4, 0, 1) * math.pi * 0.5)))
				if not emitting and elapsed > 0.08 then
					emitting = true
					setChunkEmission(body, 35, 30)
				end
				tetherTimer += dt
				if tetherTimer >= 0.05 then
					tetherTimer = 0
					core.MotionLine(
						"BlockGrabTether",
						core.Root.Position + Vector3.new(0, 1, 0),
						body.Position,
						0.15,
						GOLD,
						0.12
					)
				end
			end
			setChunkEmission(body, 0, 12)
			actor:SetAttribute("AttackState", "Block Grab: aiming")
			local aimVfx = startAimVfx(body, api.AimTime)
			local waited = core.WaitFor(api.AimTime)
			aimVfx:Dispose()
			if not waited or not core.Alive(character) then
				cast:Dispose()
				return false
			end
			core.Melee.Pose("Slash3", 0.1)
			api.Throw(body.Position, character.HumanoidRootPart.Position, body, cast)
			return core.WaitFor(0.18)
		end)
	end
	return api
end
