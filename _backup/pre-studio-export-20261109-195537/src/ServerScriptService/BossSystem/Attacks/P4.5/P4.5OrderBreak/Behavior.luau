 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local Style = require(script.Parent.Style)
local Effects = require(BossSystem.Combat.EffectService)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Golden = require(BossSystem.Attacks.Shared.P4GoldenFX)
local FX = Golden.FX
local Run = game:GetService("RunService")

local SKILL = "P4.5OrderBreak"
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local TRACK_TURN = math.rad(32)  
local YELLOW, AMBER, WHITE = Style.Yellow, Style.Amber, Style.White

return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local ctx = Golden.Context(core)
	local api = { Cooldown = Style.Cooldown }
	local current
	local function phaseOk()
		return (actor:GetAttribute("Phase") == 4.5 or actor:GetAttribute("Phase") == 5)
	end
	function api.CanUse(target)
		return not current
			and phaseOk()
			and core.Active()
			and core.Alive(target)
			and not actor:GetAttribute("EncounterEnded")
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and not Time.IsStopped(actor)
			and (target.HumanoidRootPart.Position - core.Root.Position).Magnitude <= Style.Range
	end

	local function hand()
		local arm = actor:FindFirstChild("RightHand") or actor:FindFirstChild("Right Arm")
		return arm and arm.Position or core.Root.Position + Vector3.new(0, 1.5, 0)
	end
	local function flatAim(from, target)
		local tp = core.Alive(target) and target.HumanoidRootPart.Position or from + core.Root.CFrame.LookVector * 10
		local d = Vector3.new(tp.X - from.X, 0, tp.Z - from.Z)
		return d.Magnitude > 0.1 and d.Unit or Vector3.new(core.Root.CFrame.LookVector.X, 0, core.Root.CFrame.LookVector.Z).Unit
	end

	 
	 
	local function laser(cast)
		local host = FX.Anchor(ctx, cast, CFrame.new(core.Root.Position))
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = host, host
		local layers = {}
		for _, spec in ipairs({
			{ Style.VisualWidth * 1.6, ColorSequence.new(AMBER, YELLOW), 0.55, 0.85 },
			{ Style.VisualWidth * 0.8, ColorSequence.new(YELLOW, WHITE:Lerp(YELLOW, 0.4)), 0.08, 1 },
			{ Style.VisualWidth * 0.26, ColorSequence.new(WHITE), 0, 1 },
		}) do
			local b = Instance.new("Beam")
			b.Attachment0, b.Attachment1 = a0, a1
			b.FaceCamera, b.Segments, b.LightEmission, b.LightInfluence = true, 2, spec[4], 0
			b.Color = spec[2]
			b.Width0, b.Width1 = 0, 0
			b.Parent = host
			table.insert(layers, { b, spec[1], spec[3] })
		end
		 
		local stream = FX.Emitter(a0, {
			Color = ColorSequence.new(WHITE, YELLOW),
			Size = FX.Keyed({ 0, 0.5 }, { 1, 0 }),
			Transparency = FX.Keyed({ 0, 0 }, { 0.8, 0.2 }, { 1, 1 }),
			Lifetime = NumberRange.new(0.4, 0.8),
			Speed = NumberRange.new(80, 140),
			SpreadAngle = Vector2.new(3, 3),
			EmissionDirection = Enum.NormalId.Right,
			Rate = 0,
		})
		local muzzleLight = Instance.new("PointLight")
		muzzleLight.Color, muzzleLight.Range, muzzleLight.Brightness, muzzleLight.Shadows = YELLOW, 22, 0, false
		muzzleLight.Parent = a0
		local endLight = Instance.new("PointLight")
		endLight.Color, endLight.Range, endLight.Brightness, endLight.Shadows = YELLOW, 18, 0, false
		endLight.Parent = a1
		local function set(from, to, power, t)
			host.CFrame = CFrame.new(from)
			a0.Position = Vector3.zero
			a1.Position = to - from
			 
			local dir = (to - from).Magnitude > 0.01 and (to - from).Unit or Vector3.xAxis
			a0.CFrame = CFrame.fromMatrix(Vector3.zero, dir, math.abs(dir.Y) > 0.98 and Vector3.zAxis or Vector3.yAxis)
			local flicker = 1 + 0.08 * math.sin(t * 60) + 0.05 * math.sin(t * 23)
			for _, l in ipairs(layers) do
				local b, w, a = l[1], l[2], l[3]
				b.Width0 = w * power * flicker * 1.15  
				b.Width1 = w * power * flicker
				local alpha = a + (1 - a) * (1 - power)
				b.Transparency = FX.Keyed({ 0, alpha }, { 0.92, alpha }, { 1, math.min(1, alpha + 0.5) })
			end
			stream.Rate = 160 * power
			muzzleLight.Brightness = 6 * power
			endLight.Brightness = 4 * power
		end
		return set, host
	end

	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local result = core.Perform(target, SKILL, function()
			local root = core.Root
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local cast = Effects.NewCast(actor, SKILL, Style.Windup + Style.Duration + Style.Recovery + 2)
			current = cast
			cast.OnDispose = function()
				if current == cast then
					current = nil
				end
			end
			local function valid()
				return cast:Alive()
					and core.Active()
					and phaseOk()
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
					and not actor:GetAttribute("EncounterEnded")
					and not actor:GetAttribute("PhaseTransitionInProgress")
			end
			local function fail()
				cast:Dispose()
				return false
			end
			local floor = Placement.GroundPoint(root.Position, { Clamp = true })
			local floorY = floor and floor.Y or root.Position.Y - 3
			local function beamEnd(from, dir)
				local reach = Style.Range
				local wall = workspace:Raycast(from, dir * reach, core.Params())
				if wall then
					reach = math.max(2, (wall.Position - from).Magnitude)
				end
				return from + dir * reach, reach
			end

			 
			actor:SetAttribute("AttackState", "Order Break: charging")
			core.Face(target)
			core.PoseAngles({ RightShoulder = { 90, 0, -10 }, LeftShoulder = { 20, 0, 30 }, Waist = { 0, -20, 0 } }, 0.15)
			Audio.Emit(actor, "ThrustCharge", root)
			local inhaleHost = FX.Anchor(ctx, cast, hand(), Style.Windup + 0.3)
			inhaleHost.Size = Vector3.one * 14
			local inhale = FX.Emitter(inhaleHost, {
				Color = ColorSequence.new(WHITE, YELLOW),
				Size = FX.Keyed({ 0, 0.15 }, { 0.6, 0.5 }, { 1, 0.15 }),
				Transparency = FX.Keyed({ 0, 1 }, { 0.3, 0.1 }, { 1, 0 }),
				Lifetime = NumberRange.new(0.35),
				Speed = NumberRange.new(-20),
				Shape = Enum.ParticleEmitterShape.Sphere,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
				Rate = 120,
			})
			local orb = FX.Temp(ctx, cast, "OrderBreakCharge", CFrame.new(hand()), Vector3.one * 0.3, WHITE, 0.05, Style.Windup + 0.15)
			orb.Shape = Enum.PartType.Ball
			local aimHost = FX.Anchor(ctx, cast, hand(), Style.Windup + 0.1)
			local aimA, aimB = Instance.new("Attachment"), Instance.new("Attachment")
			aimA.Parent, aimB.Parent = aimHost, aimHost
			local aimBeam = Instance.new("Beam")
			aimBeam.Attachment0, aimBeam.Attachment1 = aimA, aimB
			aimBeam.FaceCamera, aimBeam.LightEmission, aimBeam.LightInfluence = true, 1, 0
			aimBeam.Color = ColorSequence.new(YELLOW)
			aimBeam.Parent = aimHost
			 
			local lane = FX.Temp(ctx, cast, "OrderBreakLane", CFrame.new(root.Position), Vector3.new(Style.Width, 0.06, 1), YELLOW, 0.85, Style.Windup + 0.1)
			local dir = flatAim(root.Position, target)
			 
			local lockBefore = Difficulty.Mercy("OrderBreakLockBefore") or Style.LockBefore
			local track = Difficulty.Mercy("OrderBreakTrack") == true
			local started = os.clock()
			while true do
				local dt = Run.Heartbeat:Wait()
				if not valid() or not Time.WaitForActor(actor) then
					return fail()
				end
				local t = os.clock() - started
				if t >= Style.Windup then
					break
				end
				local k = t / Style.Windup
				if t < Style.Windup - lockBefore then
					dir = flatAim(root.Position, target)
					root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
				end
				local from = hand()
				local to, reach = beamEnd(from, dir)
				inhaleHost.CFrame = CFrame.new(from)
				orb.CFrame = CFrame.new(from)
				orb.Size = Vector3.one * (0.3 + 2.2 * k ^ 1.5) * (1 + 0.08 * math.sin(t * 50))
				aimHost.CFrame = CFrame.new(from)
				aimB.Position = to - from
				local locked = t >= Style.Windup - lockBefore
				local w = locked and 0.6 or 0.18
				aimBeam.Width0, aimBeam.Width1 = w, w
				aimBeam.Transparency = NumberSequence.new(locked and (math.floor(t * 30) % 2 == 0 and 0 or 0.5) or 0.35)
				local groundFrom = Vector3.new(from.X, floorY + 0.08, from.Z)
				local mid = groundFrom + dir * reach * 0.5
				lane.CFrame = CFrame.lookAt(mid, mid + dir)
				lane.Size = Vector3.new(Style.Width, 0.06, reach)
				lane.Transparency = 0.85 - 0.35 * k
			end
			inhale.Enabled = false
			FX.Release(cast, aimHost)
			FX.Release(cast, lane)
			FX.Release(cast, orb)

			 
			actor:SetAttribute("AttackState", "Order Break: laser")
			core.PoseAngles({ RightShoulder = { 95, 0, -5 }, LeftShoulder = { 30, 0, 40 }, Waist = { 8, -25, 0 } }, 0.05)
			Audio.Emit(actor, "ThrustBurst", root)
			local from0 = hand()
			FX.Flash(ctx, cast, from0, WHITE, 6, 0.15, 0)
			FX.Ring(ctx, cast, CFrame.lookAt(from0, from0 + dir), 1, 12, 0.35, YELLOW, 0, 0.7)
			FX.Shake(ctx, from0, 120, 0.3, 0.5)
			FX.Tint(ctx, from0, YELLOW, 0.5, 0.25, 160)
			local setLaser = laser(cast)
			local fireStart = os.clock()
			local nextTick, ringAt = 0, 0
			local totals = {}
			while true do
				local fdt = Run.Heartbeat:Wait()
				if not valid() or not Time.WaitForActor(actor) then
					return fail()
				end
				local t = os.clock() - fireStart
				 
				if track and core.Alive(target) then
					local want = flatAim(root.Position, target)
					local angle = math.acos(math.clamp(dir:Dot(want), -1, 1))
					if angle > 1e-3 then
						local step = math.min(angle, TRACK_TURN * fdt)
						dir = dir:Lerp(want, step / angle).Unit
						root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
					end
				end
				if t >= Style.Duration then
					break
				end
				actor:SetAttribute("OrderBreakAim", dir)  
				local from = hand()
				local to, reach = beamEnd(from, dir)
				 
				local power = math.min(1, t / 0.08) * math.clamp((Style.Duration - t) / 0.2, 0, 1)
				setLaser(from, to, power, t)
				 
				if t - ringAt > 0.12 then
					ringAt = t
					local at = from + dir * (reach * math.random())
					FX.Ring(ctx, cast, CFrame.lookAt(at, at + dir), 2, Style.Width * 1.6, 0.25, YELLOW, 0.2, 0.3)
					FX.Sparks(ctx, cast, to, YELLOW, WHITE, 5, 10, 26, 0.4)
				end
				 
				if t >= nextTick then
					nextTick = t + Style.TickInterval
					for _, char in ipairs(core.Characters()) do
						if core.Alive(char) then
							local p = char.HumanoidRootPart.Position
							local rel = p - from
							local along = rel:Dot(dir)
							local side = rel - dir * along
							local sideFlat = Vector3.new(side.X, 0, side.Z).Magnitude
							if along >= -2 and along <= reach and sideFlat <= Style.Width * 0.5 + 1.5 and math.abs(side.Y) <= Style.Height * 0.5 then
								local closeness = 1 - math.clamp(along / Style.Range, 0, 1)
								local amount = Style.TickDamageFar + (Style.TickDamageNear - Style.TickDamageFar) * closeness
								local dealt = core.Damage(char, math.floor(amount + 0.5), SKILL)
								if dealt > 0 then
									totals[char] = (totals[char] or 0) + dealt
									FX.Flash(ctx, cast, p, YELLOW, 3 + 3 * closeness, 0.12, 0.2)
									FX.Streaks(ctx, cast, p, dir, YELLOW, WHITE, 6, 40, 30, 60, 1.6)
									local speed = Style.KnockbackFar + (Style.KnockbackNear - Style.KnockbackFar) * closeness
									Runtime.Knockback(actor, char, dir, { Speed = speed, Lift = 1 + 2 * closeness, Duration = Style.KnockbackDuration, Sustain = Style.KnockbackSustain, ContainsArena = true })
								end
							end
						end
					end
				end
			end
			local best = 0
			for _, v in pairs(totals) do
				best = math.max(best, v)
			end
			actor:SetAttribute("OrderBreakMaxTotalDamage", best)
			setLaser(hand(), hand() + dir, 0, 0)
			local ok = core.WaitFor(Style.Recovery) and valid()
			cast:Schedule(0.6, function()
				cast:Dispose()
			end)
			if current == cast then
				current = nil
			end
			return ok
		end)
		return result
	end
	function api.Dispose()
		if current then
			current:Dispose()
		end
	end
	return api
end
