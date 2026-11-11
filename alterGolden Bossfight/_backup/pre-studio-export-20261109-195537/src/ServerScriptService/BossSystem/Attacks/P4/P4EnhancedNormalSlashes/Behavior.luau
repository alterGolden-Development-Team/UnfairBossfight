local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")

return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Encounter = require(BossSystem.Players.PlayerEncounter)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Run = game:GetService("RunService")
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = Registry.For(actor, "P1CombatCore")
	local NAME = "P4EnhancedNormalSlashes"
	local GOLD = Style.GOLD
	local AMBER = Style.AMBER
	local WHITE = Style.WHITE
	local EMBER = Style.EMBER
	local DEEP = Style.DEEP
	local DUST = Style.DUST
	local SPARKLE = Style.SPARKLE
	local SMOKE = Style.SMOKE
	local api = { Cooldown = Config.P4EnhancedNormalCooldown or 12 }
	local current
	local waves = {}
	local rng = Random.new()

	local TILT = math.rad(22)
	local SPECS = {
		Normal = {
			PartName = "EnhancedNormalArc",
			Radius = 10,
			Tilt = -TILT,
			Sweep = math.rad(75),
			Direction = 1,
			Reach = 11.5,
			HalfAngle = math.rad(62),
		},

		Reverse = {
			PartName = "EnhancedReverseArc",
			Radius = 10,
			Tilt = TILT,
			Sweep = math.rad(75),
			Direction = -1,
			Reach = 11.5,
			HalfAngle = math.rad(62),
		},
		Uppercut = {
			PartName = "EnhancedUppercutArc",
			Radius = 8,
			Tilt = 0,
			Sweep = math.rad(75),
			Direction = 1,
			Uppercut = true,
			Big = true,
		},
		Cross = { Cross = true, Big = true, Tilt = 0 },
	}
	local REVERSE_POSE = "Slash2"

	local function flatDirection(from, to)
		local offset = to - from
		local flat = Vector3.new(offset.X, 0, offset.Z)
		if flat.Magnitude < 0.01 then
			return nil, 0
		end
		return flat.Unit, flat.Magnitude
	end

	local function steer(direction, want, maxStep)
		local sine = direction.Z * want.X - direction.X * want.Z
		local cosine = direction.X * want.X + direction.Z * want.Z
		local turn = math.clamp(math.atan2(sine, cosine), -maxStep, maxStep)
		local c, s = math.cos(turn), math.sin(turn)
		local turned = Vector3.new(direction.X * c + direction.Z * s, 0, -direction.X * s + direction.Z * c)
		if turned.Magnitude < 0.001 then
			return want
		end
		return turned.Unit
	end

	local function aimAt(character)
		local root = core.Root
		local targetRoot = character.Parent and character:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			return
		end
		local want = flatDirection(root.Position, targetRoot.Position)
		if want then
			root.CFrame = CFrame.lookAt(root.Position, root.Position + want)
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end

	local key = Visuals.key({})

	local taper = Visuals.taper({})
	local shake = Visuals.shake({
		core = core,
	})
	local function groundOf(position)
		return Placement.GroundPoint(position, { Margin = 4, Clamp = true }) or position - Vector3.new(0, 3, 0)
	end

	local disc = Visuals.disc({
		core = core,
	})

	local pulse = Visuals.pulse({
		disc = disc,
		Effects = Effects,
	})

	local ring = Visuals.ring({
		core = core,
		Effects = Effects,
	})
	local flash = Visuals.flash({
		core = core,
		Effects = Effects,
	})

	local glint = Visuals.glint({
		core = core,
		Effects = Effects,
		SPARKLE = SPARKLE,
		key = key,
	})

	local streak = Visuals.streak({
		core = core,
		Effects = Effects,
	})
	local scar = Visuals.scar({
		streak = streak,
		WHITE = WHITE,
	})
	local sparkEmitter = Visuals.sparkEmitter({
		SPARKLE = SPARKLE,
		key = key,
	})
	local streakEmitter = Visuals.streakEmitter({
		SPARKLE = SPARKLE,
		key = key,
	})
	local dustEmitter = Visuals.dustEmitter({
		SMOKE = SMOKE,
		DUST = DUST,
		key = key,
	})
	local burstSparks = Visuals.burstSparks({
		core = core,
		sparkEmitter = sparkEmitter,
		Effects = Effects,
	})
	local burstStreaks = Visuals.burstStreaks({
		core = core,
		streakEmitter = streakEmitter,
		Effects = Effects,
	})
	local burstDust = Visuals.burstDust({
		core = core,
		DUST = DUST,
		dustEmitter = dustEmitter,
		Effects = Effects,
	})

	local cutMark = Visuals.cutMark({
		core = core,
		Effects = Effects,
	})
	local slashMarks = Visuals.slashMarks({
		rng = rng,
		cutMark = cutMark,
		WHITE = WHITE,
		GOLD = GOLD,
	})
	local hitFx = Visuals.hitFx({
		flash = flash,
		glint = glint,
		ring = ring,
		WHITE = WHITE,
		slashMarks = slashMarks,
		burstSparks = burstSparks,
		burstStreaks = burstStreaks,
		GOLD = GOLD,
		EMBER = EMBER,
		shake = shake,
	})

	local function phaseValid(generation)
		return actor.Parent
			and core.Humanoid.Health > 0
			and not actor:GetAttribute("EncounterEnded")
			and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4
			and (actor:GetAttribute("PhaseGeneration") or 0) == generation
	end
	local function damage(character, amount)
		local actual = Encounter.Damage(character, amount, actor, nil, { Skill = NAME, IgnoreDefense = true })
		if actual > 0 then
			Audio.Attack(actor, NAME, "Impact", character.HumanoidRootPart)
		end
		return actual
	end
	function api.CanUse(character)
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		if not targetRoot then return false end
		local offset = targetRoot.Position - core.Root.Position
		local near = Vector3.new(offset.X, 0, offset.Z).Magnitude <= (Config.P4EnhancedNormalUseRange or 18)
			and math.abs(offset.Y) <= (Config.P4EnhancedNormalUseHeight or 8)
		return near and not current
			and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4
			and not actor:GetAttribute("IsGoldenClone")
			and core.Active()
			and core.Alive(character)
			and not actor:GetAttribute("PhaseTransitionInProgress")
	end

	local slashRibbon = Visuals.slashRibbon({
		core = core,
		GOLD = GOLD,
		taper = taper,
		AMBER = AMBER,
		WHITE = WHITE,
		EMBER = EMBER,
		DEEP = DEEP,
		key = key,
		Effects = Effects,
		sparkEmitter = sparkEmitter,
		streak = streak,
		rng = rng,
	})
	local groundArc = Visuals.groundArc({
		streak = streak,
		WHITE = WHITE,
		GOLD = GOLD,
	})
	local slashFx = Visuals.slashFx({
		slashRibbon = slashRibbon,
		groundOf = groundOf,
		core = core,
		AMBER = AMBER,
		Effects = Effects,
		pulse = pulse,
		burstSparks = burstSparks,
		GOLD = GOLD,
		WHITE = WHITE,
		flash = flash,
		glint = glint,
		ring = ring,
		burstDust = burstDust,
		scar = scar,
		groundArc = groundArc,
		shake = shake,
	})

	local function inStrike(frame, position, spec)
		local point = frame:PointToObjectSpace(position)
		if math.abs(point.Y) > 5 then
			return false
		end
		if spec.Uppercut then
			return math.abs(point.X) <= 6 and point.Z <= 2 and point.Z >= -10
		end
		local flatReach = math.sqrt(point.X * point.X + point.Z * point.Z)
		if flatReach > spec.Reach then
			return false
		end
		if flatReach <= 3 then
			return true
		end
		if point.Z > 1 then
			return false
		end
		return math.atan2(math.abs(point.X), -point.Z) <= spec.HalfAngle
	end
	local function melee(cast, frame, spec, amount, record)
		slashFx(cast, frame, spec)
		Audio.Emit(actor, "EnhancedNormalSwing", core.Root)
		local count = 0
		for _, character in ipairs(core.Characters()) do
			if core.Alive(character) and inStrike(frame, character.HumanoidRootPart.Position, spec) then
				local origin = frame.Position + Vector3.new(0, 1, 0)
				local blocked = workspace:Raycast(origin, character.HumanoidRootPart.Position - origin, core.Params())
				if not blocked then
					local actual = damage(character, amount)
					if actual > 0 then
						count += 1
						record.Damage[character] = (record.Damage[character] or 0) + actual
						hitFx(cast, character.HumanoidRootPart.Position, frame, spec)
						if spec.Uppercut then
							Runtime.Knockback(
								actor,
								character,
								frame.LookVector,
								{ Speed = 8, Lift = 38, Duration = 0.40, Sustain = 0.08, AllowPlayerControl = true }
							)
						end
					end
				end
			end
		end
		return count
	end

	local chargeFx = Visuals.chargeFx({
		groundOf = groundOf,
		pulse = pulse,
		AMBER = AMBER,
		disc = disc,
		GOLD = GOLD,
		Effects = Effects,
		sparkEmitter = sparkEmitter,
		WHITE = WHITE,
		Config = Config,
		core = core,
		ring = ring,
		glint = glint,
		key = key,
		SPARKLE = SPARKLE,
	})

	local dashFx = Visuals.dashFx({
		core = core,
		Effects = Effects,
		pulse = pulse,
		burstDust = burstDust,
		burstSparks = burstSparks,
		flash = flash,
		glint = glint,
		ring = ring,
		shake = shake,
		sparkEmitter = sparkEmitter,
		dustEmitter = dustEmitter,
		AMBER = AMBER,
		WHITE = WHITE,
		GOLD = GOLD,
		EMBER = EMBER,
		SPARKLE = SPARKLE,
		key = key,
	})

	local xTelegraph = Visuals.xTelegraph({
		core = core,
		Effects = Effects,
		groundOf = groundOf,
		GOLD = GOLD,
		WHITE = WHITE,
		glint = glint,
	})

	local xBody = Visuals.xBody({
		core = core,
		GOLD = GOLD,
		AMBER = AMBER,
		WHITE = WHITE,
		EMBER = EMBER,
		DEEP = DEEP,
		SPARKLE = SPARKLE,
		key = key,
		taper = taper,
		sparkEmitter = sparkEmitter,
		dustEmitter = dustEmitter,
		ring = ring,
		groundOf = groundOf,
	})
	local xRelease = Visuals.xRelease({
		flash = flash,
		glint = glint,
		ring = ring,
		streak = streak,
		WHITE = WHITE,
		AMBER = AMBER,
		GOLD = GOLD,
		burstSparks = burstSparks,
		pulse = pulse,
		burstDust = burstDust,
		shake = shake,
	})
	local xEndFx = Visuals.xEndFx({
		Effects = Effects,
		actor = actor,
		flash = flash,
		glint = glint,
		ring = ring,
		streak = streak,
		WHITE = WHITE,
		AMBER = AMBER,
		burstSparks = burstSparks,
		burstStreaks = burstStreaks,
		GOLD = GOLD,
		EMBER = EMBER,
		pulse = pulse,
		burstDust = burstDust,
		shake = shake,
	})
	local function xSettings()
		local width = math.clamp(Config.P4EnhancedNormalXWidth or 32, 20, 42)
		local range = math.clamp(Config.P4EnhancedNormalXRange or 70, 40, 110)
		local speed = math.clamp(Config.P4EnhancedNormalXSpeed or 180, 120, 240)
		return width, range, speed
	end
	local function releaseX(frame, generation)
		local width, range, speed = xSettings()
		local half = width * 0.5
		local cast = Effects.NewCast(actor, "P4EnhancedCrossSlash", range / speed + 0.5)
		waves[cast] = true
		cast.OnDispose = function()
			waves[cast] = nil
		end
		local body = xBody(cast, frame, width)
		local groundY = body.GroundY

		xRelease(cast, frame, groundY, width)

		local record = {
			Cast = cast,
			Anchor = body.Anchor,
			Frame = frame,
			Width = width,
			Range = range,
			Speed = speed,
			Traveled = 0,
			Hits = {},
		}
		api.LastWave = record
		Audio.Emit(actor, "RangedX", frame.Position)
		cast:Step(function(dt, now)
			if not phaseValid(generation) then
				cast:Dispose()
				return false
			end
			local distance = math.min(speed * math.min(dt, 0.08), range - record.Traveled)
			local delta = record.Frame.LookVector * distance

			local collision = workspace:Blockcast(record.Frame, Vector3.new(width, 5, 0.3), delta, core.Params())
			if collision then
				distance = math.max(0, collision.Distance - 0.1)
				delta = record.Frame.LookVector * distance
			end
			for _, character in ipairs(core.Characters()) do
				if core.Alive(character) and not record.Hits[character] then
					local point = record.Frame:PointToObjectSpace(character.HumanoidRootPart.Position)
					local onArm = math.min(math.abs(point.Y - point.X * 0.75), math.abs(point.Y + point.X * 0.75))
						<= 2.8
					if math.abs(point.X) <= half + 1 and onArm and point.Z <= 2 and point.Z >= -distance - 2 then
						local actual = damage(character, math.clamp(Config.P4EnhancedNormalXDamage or 18, 1, 50))
						if actual > 0 then
							record.Hits[character] = actual
							hitFx(cast, character.HumanoidRootPart.Position, record.Frame, SPECS.Cross)
						end
					end
				end
			end
			record.Frame += delta
			record.Traveled += distance
			body.Update(record.Frame, now, record.Traveled)
			if collision or record.Traveled >= range then
				xEndFx(record.Frame.Position, groundY, collision ~= nil, record.Frame.LookVector)
				cast:Dispose()
				return false
			end
			return true
		end)
		actor:SetAttribute(
			"EnhancedNormalXSlashesReleased",
			(actor:GetAttribute("EnhancedNormalXSlashesReleased") or 0) + 1
		)
		return record
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, NAME, function()
			local root = core.Root
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local cast = Effects.NewCast(actor, "P4EnhancedNormalSequence", 6)
			local record = { Cast = cast, Target = character, Damage = {}, Stages = {} }
			current = cast
			api.LastSequence = record
			cast.OnDispose = function()
				if current == cast then
					current = nil
				end
			end
			local function valid()
				return not cast.closed
					and phaseValid(generation)
					and core.Active()
					and (actor:GetAttribute("MovementRevision") or 0) == revision
					and not actor:GetAttribute("PhaseTransitionInProgress")
			end
			local function stage(name)
				actor:SetAttribute("EnhancedNormalSlashState", name)
				actor:SetAttribute("AttackState", "Enhanced normal slashes: " .. name)
				table.insert(record.Stages, name)
			end

			local jitter = math.clamp(Config.P4EnhancedNormalRhythmJitter or 0.08, 0, 0.25)
			local function beat(base)
				return core.WaitFor(base + rng:NextNumber(0, jitter))
			end

			local function travel(target, opts)
				local limit = opts.Distance or math.huge
				local direction = opts.Direction
				local stopRange = opts.StopRange
				local traveled, elapsed = 0, 0
				while traveled < limit do
					local dt = Run.Heartbeat:Wait()
					if not Time.WaitForActor(actor) or not valid() then
						return false, traveled
					end
					local step = math.min(dt, 0.08) * Time.BossRate(actor)
					local stride = math.min(opts.Speed * step, limit - traveled)
					elapsed += dt
					if opts.Time and elapsed > opts.Time then
						break
					end

					if opts.Homing and core.Alive(target) then
						local want, gap = flatDirection(root.Position, target.HumanoidRootPart.Position)
						if want then
							if gap <= stopRange then
								break
							end
							direction = opts.TurnRate and steer(direction, want, opts.TurnRate * step) or want
							stride = math.min(stride, gap - stopRange)
						end
					end
					local delta = direction * stride
					local blocked = workspace:Blockcast(root.CFrame, Vector3.new(2.3, 3, 2.3), delta, core.Params())
					if blocked then
						stride = math.max(0, blocked.Distance - 0.2)
						delta = direction * stride
					end
					local safe = Placement.Validate(
						actor,
						CFrame.lookAt(root.Position + delta, root.Position + delta + direction),
						{ Margin = 6 }
					)
					if not safe then
						break
					end
					root.CFrame = safe
					root.AssemblyLinearVelocity = Vector3.zero
					traveled += stride
					core.Afterimage(root.CFrame)
					if opts.OnStep then
						opts.OnStep(traveled, direction)
					end
					if blocked or stride < 0.01 then
						break
					end
				end
				return true, traveled
			end

			local lungeMax = math.clamp(Config.P4EnhancedNormalLunge or 10, 0, 20)
			local function lunge()
				if lungeMax <= 0 or not core.Alive(character) then
					return true
				end
				local want, gap = flatDirection(root.Position, character.HumanoidRootPart.Position)
				if not want or gap <= 8 then
					return true
				end
				local floor = groundOf(root.Position)
				burstDust(cast, floor + Vector3.new(0, 0.4, 0), 3, 4)
				local ok = travel(character, {
					Speed = 150,
					Distance = lungeMax,
					Time = 0.25,
					StopRange = 5.5,
					Homing = true,
					Direction = want,
				})
				return ok
			end

			local function pose(name, fallback, blend)
				local ok = pcall(core.Melee.Pose, name, blend)
				if not ok and fallback then
					core.Melee.Pose(fallback, blend)
				end
			end

			local function sequence()
				local homing = false
				local maxDashTime = math.clamp(Config.P4EnhancedNormalHomingMaxTime or 1.5, 0.5, 4)
				local turnRate = math.clamp(Config.P4EnhancedNormalDashTurnRate or 7, 2, 30)
				local stopRange = 6
				local reverse = Config.P4EnhancedNormalReverseSlash ~= false
				core.Face(character)
				core.Melee.Pose("Windup", 0.12)
				stage("Dash windup")
				local windup = math.clamp(Config.P4EnhancedNormalWindup or 0.35, 0.2, 0.7)
				local lock = math.min(0.1, windup * 0.3)
				local charge = chargeFx(cast, root, windup, character)

				local tracking = true
				cast:Step(function()
					if not tracking or not root.Parent then
						return false
					end
					aimAt(character)
					return true
				end)
				if not core.WaitFor(windup - lock) or not valid() then
					tracking = false
					return false
				end
				tracking = false
				if not core.Alive(character) then
					charge.Stop()
					return false
				end

				local lockedDirection, lockedGap =
					flatDirection(root.Position, character.HumanoidRootPart.Position)
				if not lockedDirection then
					lockedDirection = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
				end
				if not core.WaitFor(lock) or not valid() then
					return false
				end
				charge.Stop()
				if not core.Alive(character) then
					return false
				end
				local dashMax = math.clamp(Config.P4EnhancedNormalDashDistance or 40, 20, 55)
				local speed = math.clamp(Config.P4EnhancedNormalDashSpeed or 130, 90, 170)

				local distance = homing and math.huge or math.min(math.max(0, lockedGap - stopRange), dashMax)
				stage("Dash")
				local groundY = groundOf(root.Position).Y
				local fx = dashFx(cast, root, lockedDirection, groundY)
				local ok, traveled = travel(character, {
					Speed = speed,
					Distance = distance,
					Time = 0.35,
					StopRange = stopRange,
					Homing = homing,
					TurnRate = turnRate,
					Direction = lockedDirection,
					OnStep = fx.Update,
				})
				if not ok then
					return false
				end
				record.DashDistance = traveled
				fx.Finish(traveled)
				if not valid() then
					return false
				end

				aimAt(character)
				stage("Normal slash")
				local lead = math.clamp(Config.P4EnhancedNormalSlashLead or 0.08, 0, 0.3)
				if lead > 0 then
					core.Melee.Pose("Windup", 0.06)
					glint(cast, root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 1.5, 0), WHITE, 7, lead)
					if not core.WaitFor(lead) or not valid() then
						return false
					end
					aimAt(character)
				end
				core.Melee.Pose("Slash1", 0.08)
				record.NormalHits = melee(
					cast,
					root.CFrame,
					SPECS.Normal,
					math.clamp(Config.P4EnhancedNormalMeleeDamage or 12, 1, 50),
					record
				)

				if reverse then
					if not beat(0.2) or not valid() then
						return false
					end
					if not lunge() or not valid() then
						return false
					end
					aimAt(character)
					stage("Reverse slash")
					pose(REVERSE_POSE, "Slash1", 0.08)
					record.ReverseHits = melee(
						cast,
						root.CFrame,
						SPECS.Reverse,
						math.clamp(Config.P4EnhancedNormalReverseDamage or 10, 1, 50),
						record
					)
				end

				if not beat(0.22) or not valid() then
					return false
				end
				if not lunge() or not valid() then
					return false
				end
				aimAt(character)
				stage("Uppercut")
				core.PoseAngles(
					{ RightShoulder = { 155, 0, -25 }, LeftShoulder = { 20, 0, 20 }, Waist = { -15, 0, 0 } },
					0.1
				)
				record.UppercutHits = melee(
					cast,
					root.CFrame,
					SPECS.Uppercut,
					math.clamp(Config.P4EnhancedNormalUppercutDamage or 15, 1, 50),
					record
				)

				if not beat(0.28) or not valid() then
					return false
				end
				aimAt(character)
				stage("Large X slash")
				core.Melee.Pose("Windup", 0.08)
				local xFrame = root.CFrame * CFrame.new(0, 1, -3)
				local width, range = xSettings()
				local laneLength = range
				local obstruction = workspace:Blockcast(xFrame, Vector3.new(width, 5, 0.3), xFrame.LookVector * range, core.Params())
				if obstruction then
					laneLength = math.max(4, obstruction.Distance)
				end
				local chargeTime = math.clamp(Config.P4EnhancedNormalXCharge or 0.2, 0.1, 0.5)
				local hideLane = xTelegraph(cast, xFrame, width, laneLength, chargeTime)
				if not core.WaitFor(chargeTime) or not valid() then
					return false
				end
				hideLane()
				core.Melee.Pose("Slash3", 0.08)
				Audio.Emit(actor, "EnhancedNormalSwing", root)
				record.Wave = releaseX(root.CFrame * CFrame.new(0, 1, -3), generation)
				actor:SetAttribute(
					"EnhancedNormalCombosCompleted",
					(actor:GetAttribute("EnhancedNormalCombosCompleted") or 0) + 1
				)
				return core.WaitFor(0.12)
			end
			local ok, result = xpcall(sequence, debug.traceback)
			if not cast.closed then
				cast:Dispose()
			end
			if not ok then
				error(result, 0)
			end
			return result
		end)
	end
	function api.Dispose()
		if current then
			current:Dispose()
		end
		local pending = {}
		for cast in pairs(waves) do
			table.insert(pending, cast)
		end
		for _, cast in ipairs(pending) do
			cast:Dispose()
		end
	end
	return api
end
