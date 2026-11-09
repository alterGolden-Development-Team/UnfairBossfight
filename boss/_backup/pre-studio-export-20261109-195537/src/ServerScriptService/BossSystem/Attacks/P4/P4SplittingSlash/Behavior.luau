local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Run = game:GetService("RunService")
	local Tween = game:GetService("TweenService")
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = Registry.For(actor, "P1CombatCore")
	local split = Registry.For(actor, "P1GoldenSplit")
	local api = { Cooldown = Config.SplittingSlashCooldown }
	local random = Random.new()
	local current

	local GOLD = Style.GOLD
	local AMBER = Style.AMBER
	local WHITE = Style.WHITE
	local DUST = Style.DUST
	local SPARKLE = Style.SPARKLE
	local SMOKE = Style.SMOKE
	local STAGE_STYLE = {
		{ Main = GOLD, Glow = AMBER },
		{ Main = Color3.fromRGB(255, 176, 50), Glow = Color3.fromRGB(255, 222, 140) },
		{ Main = Color3.fromRGB(255, 128, 48), Glow = Color3.fromRGB(255, 190, 110) },
		{ Main = Color3.fromRGB(255, 244, 200), Glow = Color3.fromRGB(255, 255, 240) },
	}

	local STAGE_COUNTS = { 1, 2, 4, 8 }
	local STAGE_SCALE = {
		{ Damage = 1.00, Width = 1.00, Length = 1.00, Tempo = 1.00, Chase = 0.8, Echo = false },
		{ Damage = 1.10, Width = 1.08, Length = 1.04, Tempo = 0.90, Chase = 1.0, Echo = true },
		{ Damage = 1.25, Width = 1.16, Length = 1.08, Tempo = 0.80, Chase = 1.2, Echo = true },
		{ Damage = 1.50, Width = 1.25, Length = 1.12, Tempo = 0.70, Chase = 1.4, Echo = true },
	}
	local CHASE_SPEED = Config.SplittingSlashHubChaseSpeed or 10
	local ECHO_WARN = Config.SplittingSlashEchoWarn or 0.55
	local MIN_LOCK = Config.SplittingSlashMinLock or 0.25

	local key = Visuals.key({})

	local shake = Visuals.shake({
		core = core,
	})
	local disc = Visuals.disc({
		core = core,
	})
	local pulse = Visuals.pulse({
		disc = disc,
		Effects = Effects,
	})
	local sparkEmitter = Visuals.sparkEmitter({
		SPARKLE = SPARKLE,
		key = key,
	})
	local dustEmitter = Visuals.dustEmitter({
		SMOKE = SMOKE,
		DUST = DUST,
		key = key,
	})

	local function sweepingArc(lane, groundY, cast, hit, style, damage)
		local center = lane.frame * CFrame.new(0, groundY + 3 - lane.frame.Y, -lane.length * 0.5)
		local anchor = cast:Add(core.Part("P3SweepingSlashArc", center, Vector3.one * 0.1, style.Main, 1))
		local lease = Effects.LeaseId(anchor)
		local points, beams = {}, {}
		local segments = 12
		for index = 0, segments do
			local t = index / segments
			local a = Instance.new("Attachment")
			a.Position = Vector3.new(
				math.sin(t * math.pi) * lane.width * 0.35,
				math.sin(t * math.pi) * 1.8,
				(t - 0.5) * lane.length
			)
			a.Parent = anchor
			points[index + 1] = a
		end
		for index = 1, segments do
			local beam = Instance.new("Beam")
			beam.Name = "WideGoldenSlashRibbon"
			beam.Attachment0 = points[index]
			beam.Attachment1 = points[index + 1]
			beam.Width0 = math.max(1, lane.width * 0.85)
			beam.Width1 = beam.Width0 * 0.8
			beam.FaceCamera = true
			beam.LightEmission = 0.5
			beam.Segments = 2
			beam.Color = ColorSequence.new(style.Main, style.Glow)
			beam.Transparency = NumberSequence.new(0.16)
			beam.Parent = anchor
			beams[index] = beam
		end

		local yaw = center.Rotation
		local mid = Vector3.new(center.X, groundY, center.Z)
		local strip = cast:Add(
			core.Part(
				"SplittingSlashLaneFlash",
				CFrame.new(mid + Vector3.new(0, 0.16, 0)) * yaw,
				Vector3.new(lane.width * 0.9, 0.12, lane.length),
				style.Glow,
				0.1
			)
		)
		strip.Material = Enum.Material.Neon
		Effects:Create(
			strip,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Transparency = 1, Size = Vector3.new(lane.width * 0.35, 0.12, lane.length) }
		):Play()
		local wall = cast:Add(
			core.Part(
				"SplittingSlashLaneWall",
				CFrame.new(mid + Vector3.new(0, 3.6, 0)) * yaw,
				Vector3.new(0.35, 7.2, lane.length),
				style.Main,
				0.5
			)
		)
		wall.Material = Enum.Material.Neon
		Effects:Create(
			wall,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1, Size = Vector3.new(0.1, 10, lane.length) }
		):Play()
		sparkEmitter(strip, style.Main, style.Glow, 12, 30, 25).EmissionDirection = Enum.NormalId.Top
		local sparks = strip:FindFirstChildOfClass("ParticleEmitter")
		if sparks then
			sparks:Emit(28)
		end
		cast:Schedule(0.7, function()
			Effects.Release(strip)
			Effects.Release(wall)
		end)

		local started = cast:Now()
		cast:Step(function(_, now)
			if not anchor.Parent or Effects.LeaseId(anchor) ~= lease then
				return false
			end
			local alpha = math.clamp((now - started) / 0.35, 0, 1)
			for index, beam in ipairs(beams) do
				local taper = math.sin((index - 0.5) * math.pi / segments)
				beam.Width0 = math.max(0.12, lane.width * 0.85 * taper * (1 - alpha * 0.65))
				beam.Width1 = beam.Width0 * 0.8
				beam.Transparency = NumberSequence.new(0.16 + 0.84 * alpha)
			end
			anchor.CFrame = center * CFrame.new((alpha - 0.5) * lane.width * 0.3, 0, 0)
			if alpha >= 1 then
				Effects.Release(anchor)
				return false
			end
			return true
		end)
		Audio.Emit(actor, "SplittingSlashRelease", center.Position)
		split.DamageLane(
			lane,
			nil,
			damage or Config.SplittingSlashDamage,
			hit,
			Config.SplittingSlashHeight,
			lane.frame.Position + lane.frame.LookVector * lane.length * 0.5
		)
	end
	function api.CanUse(character)
		return math.min(4, math.floor(actor:GetAttribute("Phase") or 1)) == 4 and core.Active() and core.Alive(character)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		local result = core.Perform(character, "P4SplittingSlash", function()
			local root = core.Root
			local revision = actor:GetAttribute("MovementRevision") or 0
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local cast = Effects.NewCast(actor, "P4SplittingSlashPattern", 30)
			current = cast
			local ground = Placement.GroundPoint(root.Position, { Margin = 4, Clamp = true })
			if not ground then
				cast:Dispose()
				return false
			end
			local base = root.CFrame
			local lastMotionFrame = base
			core.AirborneFloor = base.Y
			local airborne = base + Vector3.new(0, Config.SplittingSlashRiseHeight, 0)
			cast.OnDispose = function()
				if current == cast then
					current = nil
				end
				 
				local stillAtOwnedPosition = root.Parent and (root.Position - lastMotionFrame.Position).Magnitude < 0.1
				if
					root.Parent
					and ((actor:GetAttribute("MovementRevision") or 0) == revision or stillAtOwnedPosition)
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
				then
					root.CFrame = CFrame.new(root.Position.X, base.Y, root.Position.Z) * root.CFrame.Rotation
					core.AirborneFloor = nil
				end
			end
			local function valid()
				return cast:Alive()
					and core.Active()
					and core.Alive(character)
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
			end
			local function lift(frame, duration)
				local start = root.CFrame
				local began = Time.ActionNow(actor)
				repeat
					if not valid() then
						return false
					end
					local t = math.clamp((Time.ActionNow(actor) - began) / duration, 0, 1)
					root.CFrame = start:Lerp(frame, t * t * (3 - 2 * t))
					lastMotionFrame = root.CFrame
					if t >= 1 then
						return true
					end
					Run.Heartbeat:Wait()
				until false
			end
			core.Face(character)
			core.PoseAngles(
				{ RightShoulder = { 145, 0, -18 }, LeftShoulder = { 35, 0, -25 }, Waist = { -8, 0, 0 } },
				0.2
			)

			local floorSpot = ground + Vector3.new(0, 0.2, 0)
			pulse(cast, floorSpot, 4, 26, 0.4, AMBER, 0.3)
			local shadow = disc(cast, ground + Vector3.new(0, 0.12, 0), 2, GOLD, 0.9)
			Effects:Create(shadow, TweenInfo.new(0.35), { Size = Vector3.new(0.1, 16, 16), Transparency = 0.55 }):Play()
			local liftDust = cast:Add(
				core.Part(
					"SplittingSlashLiftDust",
					CFrame.new(ground + Vector3.new(0, 0.5, 0)),
					Vector3.one * 0.2,
					DUST,
					1
				)
			)
			dustEmitter(liftDust, 6):Emit(14)
			local aura = sparkEmitter(root, WHITE, GOLD, 2, 8, 180)
			aura.Rate = 40
			aura.Acceleration = Vector3.new(0, 2, 0)
			cast:Add(aura)

			if not lift(airborne, 0.35) then
				cast:Dispose()
				return false
			end
			for stage, count in ipairs(STAGE_COUNTS) do
				if not valid() then
					cast:Dispose()
					return false
				end
				local style = STAGE_STYLE[stage]
				local scale = STAGE_SCALE[stage]

				local rotationDuration = Config.SplittingSlashRotationDuration * scale.Tempo
				local slowdownDuration = math.max(0.05, Config.SplittingSlashSlowdownDuration * scale.Tempo)
				local baseLock = Config.SplittingSlashLockDuration
				local lockDuration = math.min(baseLock, math.max(MIN_LOCK, baseLock * scale.Tempo))
				local laneLength = Config.SplittingSlashLength * scale.Length
				local laneWidth = Config.SplittingSlashWidth * scale.Width
				local damage = Config.SplittingSlashDamage * scale.Damage
				local stageInterval = Config.SplittingSlashStageInterval * (0.5 + 0.5 * scale.Tempo)

				local point = Placement.GroundPoint(character.HumanoidRootPart.Position, { Margin = 3, Clamp = true })
				if not point then
					cast:Dispose()
					return false
				end
				local center = point + Vector3.new(0, 3, 0)
				local startAngle = random:NextNumber(0, math.pi)
				local spinRate = math.rad(Config.SplittingSlashSpinDegreesPerSecond)
					* (random:NextInteger(0, 1) == 0 and -1 or 1)
				local lanes, warnings = {}, {}
				for index = 1, count do
					local lane = { length = laneLength, width = laneWidth }
					local angle = startAngle + (index - 1) * math.pi / count
					local frame = CFrame.new(center) * CFrame.Angles(0, angle, 0)
					lane.frame = frame * CFrame.new(0, 0, lane.length * 0.5)
					local band, line = split.Warning(lane, point.Y)
					cast:Add(band)
					cast:Add(line)
					table.insert(lanes, lane)
					table.insert(warnings, { Band = band, Line = line })
				end

				local hubDiameter = math.max(5, laneWidth * 1.4)
				local hubRadius = hubDiameter * 0.5
				local hubSpot = point + Vector3.new(0, 0.9, 0)
				local hub = disc(cast, point + Vector3.new(0, 0.18, 0), hubDiameter, style.Main, 0.6)
				local hubCore = cast:Add(
					core.Part(
						"SplittingSlashHubCore",
						CFrame.new(point + Vector3.new(0, 1.2, 0)),
						Vector3.one * 2,
						WHITE,
						0.25
					)
				)
				hubCore.Shape = Enum.PartType.Ball
				hubCore.Material = Enum.Material.Neon
				local orbs = {}
				for index = 1, count do
					orbs[index] = {}
					for side = 1, 2 do
						local orb = cast:Add(
							core.Part("SplittingSlashOrb", CFrame.new(hubSpot), Vector3.one * 1.1, style.Glow, 0.1)
						)
						orb.Shape = Enum.PartType.Ball
						orb.Material = Enum.Material.Neon
						orbs[index][side] = orb
					end
				end
				pulse(cast, point + Vector3.new(0, 0.2, 0), 2, hubDiameter * 2.2, 0.35, style.Glow, 0.35)

				local function place(rotation)
					center = point + Vector3.new(0, 3, 0)
					hubSpot = point + Vector3.new(0, 0.9, 0)
					hub.CFrame = CFrame.new(point + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
					hubCore.CFrame = CFrame.new(point + Vector3.new(0, 1.2, 0))
					for index, lane in ipairs(lanes) do
						local frame = CFrame.new(center)
							* CFrame.Angles(0, startAngle + rotation + (index - 1) * math.pi / count, 0)
						lane.frame = frame * CFrame.new(0, 0, lane.length * 0.5)
						local cf = lane.frame * CFrame.new(0, point.Y + 0.12 - lane.frame.Y, -lane.length * 0.5)
						warnings[index].Band.CFrame = cf
						warnings[index].Line.CFrame = cf + Vector3.new(0, 0.08, 0)
						local look = lane.frame.LookVector
						orbs[index][1].CFrame = CFrame.new(hubSpot + look * hubRadius)
						orbs[index][2].CFrame = CFrame.new(hubSpot - look * hubRadius)
					end
				end

				actor:SetAttribute("AttackState", "Splitting Slash: rotating " .. count .. " splits")
				actor:SetAttribute("SplittingSlashStage", stage)
				local began = Time.ActionNow(actor)
				local lastNow = began
				local finalRotation = 0
				repeat
					if not valid() then
						cast:Dispose()
						return false
					end
					local now = Time.ActionNow(actor)
					local dt = math.clamp(now - lastNow, 0, 0.1)
					lastNow = now
					local elapsed = now - began
					local fast = math.min(elapsed, rotationDuration)
					local slowing = math.clamp(elapsed - rotationDuration, 0, slowdownDuration)
					 
					local rotation = spinRate * (fast + slowing - 0.5 * slowing * slowing / slowdownDuration)
					finalRotation = rotation

					if dt > 0 then
						local targetPoint = Placement.GroundPoint(
							character.HumanoidRootPart.Position,
							{ Margin = 3, Clamp = true }
						)
						if targetPoint then
							local flat = Vector3.new(targetPoint.X - point.X, 0, targetPoint.Z - point.Z)
							local distance = flat.Magnitude
							if distance > 0.05 then
								local settle = 1 - slowing / slowdownDuration
								local step = math.min(distance, CHASE_SPEED * scale.Chase * settle * dt)
								local moved = Placement.GroundPoint(point + flat.Unit * step, { Margin = 3, Clamp = true })
								if moved then
									point = moved
								end
							end
						end
					end

					place(rotation)
					if elapsed >= rotationDuration + slowdownDuration then
						break
					end
					Run.Heartbeat:Wait()
				until false
				actor:SetAttribute("AttackState", "Splitting Slash: locked warning " .. count)
				Effects:Create(hubCore, TweenInfo.new(0.2), { Size = Vector3.one * 3.4, Transparency = 0 }):Play()
				for _, pair in ipairs(orbs) do
					for _, orb in ipairs(pair) do
						orb.Color = WHITE
					end
				end
				pulse(cast, point + Vector3.new(0, 0.25, 0), hubDiameter * 2.6, hubDiameter * 0.8, 0.25, WHITE, 0.35)
				if not core.WaitFor(lockDuration) or not valid() then
					cast:Dispose()
					return false
				end
				for _, warning in ipairs(warnings) do
					Effects.Release(warning.Band)
					Effects.Release(warning.Line)
				end
				Effects.Release(hub)
				Effects.Release(hubCore)
				for _, pair in ipairs(orbs) do
					for _, orb in ipairs(pair) do
						Effects.Release(orb)
					end
				end
				local hit = {}
				core.PoseAngles(
					{ RightShoulder = { 10, 0, -30 }, LeftShoulder = { -15, 0, -20 }, Waist = { 20, 0, 0 } },
					0.08
				)
				actor:SetAttribute("AttackState", "Splitting Slash: locked strike " .. count)
				for _, lane in ipairs(lanes) do
					sweepingArc(lane, point.Y, cast, hit, style, damage)
				end
				local burst =
					cast:Add(core.Part("SplittingSlashBurst", CFrame.new(center), Vector3.one * 3, WHITE, 0.1))
				burst.Shape = Enum.PartType.Ball
				burst.Material = Enum.Material.Neon
				Effects:Create(
					burst,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = Vector3.one * (14 + stage * 3), Transparency = 1 }
				):Play()
				local light = Instance.new("PointLight")
				light.Color = style.Main
				light.Range = 40
				light.Brightness = 4
				light.Shadows = false
				light.Parent = burst
				Tween:Create(light, TweenInfo.new(0.4), { Brightness = 0 }):Play()
				sparkEmitter(burst, style.Main, style.Glow, 14, 34, 180):Emit(10 + stage * 6)
				pulse(cast, point + Vector3.new(0, 0.25, 0), 3, 18 + stage * 8, 0.45, style.Glow, 0.2)
				cast:Schedule(0.4, function()
					Effects.Release(burst)
				end)
				actor:SetAttribute("SplittingSlashVisual", "Sweeping arcs")
				actor:SetAttribute(
					"SplittingSlashPatternCount",
					(actor:GetAttribute("SplittingSlashPatternCount") or 0) + 1
				)
				actor:SetAttribute("LastSplittingSlashLineCount", count)
				shake(point, 0.16, 0.2 + stage * 0.1)

				if scale.Echo then
					local echoLanes, echoWarnings = {}, {}
					for index = 1, count do
						local lane = { length = laneLength, width = laneWidth }
						local angle = startAngle
							+ finalRotation
							+ (index - 1) * math.pi / count
							+ math.pi / (2 * count)
						local frame = CFrame.new(center) * CFrame.Angles(0, angle, 0)
						lane.frame = frame * CFrame.new(0, 0, lane.length * 0.5)
						local band, line = split.Warning(lane, point.Y)
						cast:Add(band)
						cast:Add(line)
						local cf = lane.frame * CFrame.new(0, point.Y + 0.12 - lane.frame.Y, -lane.length * 0.5)
						band.CFrame = cf
						line.CFrame = cf + Vector3.new(0, 0.08, 0)
						table.insert(echoLanes, lane)
						table.insert(echoWarnings, { Band = band, Line = line })
					end
					actor:SetAttribute("AttackState", "Splitting Slash: echo " .. count)
					pulse(cast, point + Vector3.new(0, 0.25, 0), hubDiameter * 0.8, hubDiameter * 2.4, 0.3, WHITE, 0.3)
					if not core.WaitFor(math.max(0.3, ECHO_WARN * scale.Tempo)) or not valid() then
						cast:Dispose()
						return false
					end
					for _, warning in ipairs(echoWarnings) do
						Effects.Release(warning.Band)
						Effects.Release(warning.Line)
					end
					local echoHit = {}
					local echoStyle = { Main = WHITE, Glow = style.Glow }
					for _, lane in ipairs(echoLanes) do
						sweepingArc(lane, point.Y, cast, echoHit, echoStyle, damage)
					end
					shake(point, 0.14, 0.15 + stage * 0.08)
				end

				if not core.WaitFor(stageInterval) then
					cast:Dispose()
					return false
				end
				core.PoseAngles({ RightShoulder = { 145, 0, -18 }, Waist = { -8, 0, 0 } }, 0.16)
			end
			if not lift(base, 0.3) then
				cast:Dispose()
				return false
			end
			 
			local landing = Effects.NewCast(actor, "P4SplittingSlashLanding", 0.8)
			pulse(landing, floorSpot, 4, 30, 0.4, AMBER, 0.3)
			local landDust = landing:Add(
				core.Part(
					"SplittingSlashLandingDust",
					CFrame.new(ground + Vector3.new(0, 0.5, 0)),
					Vector3.one * 0.2,
					DUST,
					1
				)
			)
			dustEmitter(landDust, 7):Emit(16)
			shake(ground, 0.25, 0.6)
			cast:Dispose()
			return true
		end)
		if current then
			current:Dispose()
		end
		return result
	end
	function api.Dispose()
		if current then
			current:Dispose()
		end
	end
	return api
end
