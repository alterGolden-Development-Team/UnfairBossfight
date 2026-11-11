 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local Style = require(script.Parent.Style)
local Effects = require(BossSystem.Combat.EffectService)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Golden = require(BossSystem.Attacks.Shared.P4GoldenFX)
local FX = Golden.FX
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)

return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local ctx = Golden.Context(core)
	local api = { Cooldown = Style.Cooldown }
	local current
	local function phaseOk()
		return (actor:GetAttribute("Phase") or 0) >= 4
	end
	function api.CanUse(target)
		return not current
			and phaseOk()
			and core.Active()
			and core.Alive(target)
			and not actor:GetAttribute("EncounterEnded")
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and not Time.IsStopped(actor)
			and (target.HumanoidRootPart.Position - core.Root.Position).Magnitude <= Style.UseRange
	end

	 
	local function inGap(a, gaps)
		if not gaps then
			return false
		end
		for _, g in ipairs(gaps) do
			local d = math.abs((a - g.Angle + math.pi) % (math.pi * 2) - math.pi)
			if d <= g.Half then
				return true
			end
		end
		return false
	end

	 
	 
	local function releaseWall(center, floorY, generation, opts)
		opts = opts or {}
		local speed = opts.Speed or Style.WallSpeed
		local damage = opts.Damage or Style.WallDamage
		local clearance = opts.Clearance
		local gaps = opts.Gaps
		local maxR = Style.WallMaxRadius
		local life = maxR / speed + 0.4
		local wall = Effects.NewCast(actor, "P5EnhancedBurstWall", life)
		local segs = Style.WallSegments
		local h = opts.Height or Style.WallHeight
		local body, crest = table.create(segs), table.create(segs)
		local open = table.create(segs)
		for i = 1, segs do
			local a = (i - 1) / segs * math.pi * 2
			open[i] = inGap(a, gaps)
			body[i] = wall:Add(core.Part("P5EnhancedBurstWall", CFrame.new(center), Vector3.new(1, h, 1), Golden.CRIMSON, open[i] and 1 or 0.2))
			crest[i] = wall:Add(core.Part("P5EnhancedBurstWallCrest", CFrame.new(center), Vector3.new(0.4, 0.35, 1), Golden.WHITE, open[i] and 1 or 0.05))
		end
		local radius, hit, dustAt, scarAt = 2, {}, 0, 0
		local born = wall:Now()
		wall:Step(function(dt, now)
			if not actor.Parent or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation or actor:GetAttribute("EncounterEnded") then
				wall:Dispose()
				return false
			end
			local previous = radius
			radius = math.min(maxR, radius + speed * dt)
			local k = radius / maxR
			local alpha = 0.15 + 0.85 * k ^ 3
			local arc = 2 * math.pi * radius / segs * 1.12
			local height = h * (1 - 0.35 * k) * (1 + 0.08 * math.sin((now - born) * 30))
			for i = 1, segs do
				local a = (i - 1) / segs * math.pi * 2
				local out = Vector3.new(math.cos(a), 0, math.sin(a))
				local base = center + out * radius
				local facing = CFrame.lookAt(base, base + Vector3.new(-out.Z, 0, out.X))
				body[i].CFrame = facing + Vector3.new(0, height * 0.5, 0)
				body[i].Size = Vector3.new(Style.WallThickness * (1 - 0.4 * k), height, arc)
				body[i].Transparency = open[i] and 1 or alpha
				crest[i].CFrame = facing + Vector3.new(0, height + 0.1, 0)
				crest[i].Size = Vector3.new(0.4, 0.35, arc)
				crest[i].Transparency = open[i] and 1 or math.min(1, alpha + 0.05)
			end
			 
			if now - scarAt > 0.07 and k < 0.85 then
				scarAt = now
				for _ = 1, 2 do
					local i = math.random(1, segs)
					if not open[i] then
						local a = (i - 1) / segs * math.pi * 2
						local out = Vector3.new(math.cos(a), 0, math.sin(a))
						FX.Sparks(ctx, wall, center + out * radius + Vector3.new(0, height, 0), Golden.GOLD, Golden.WHITE, 3, 6, 16, 0.35)
					end
				end
			end
			 
			if now - dustAt > 0.1 and k < 0.9 then
				dustAt = now
				for _ = 1, 3 do
					local a = math.random() * math.pi * 2
					FX.Smoke(ctx, wall, center + Vector3.new(math.cos(a), 0.5, math.sin(a)) * radius, Golden.DUST, 4, 2, 10, 2)
				end
			end
			 
			for _, char in ipairs(core.Characters()) do
				if not hit[char] and core.Alive(char) then
					local p = char.HumanoidRootPart.Position
					local flatOff = Vector3.new(p.X - center.X, 0, p.Z - center.Z)
					local d = flatOff.Magnitude
					local reach = Style.WallThickness + 1.5
					local low = clearance == nil or p.Y - floorY <= height + clearance
					local gap = gaps and d > 0.1 and inGap(math.atan2(flatOff.Z, flatOff.X) % (math.pi * 2), gaps)
					if d >= previous - reach and d <= radius + reach and low and not gap and p.Y >= floorY - 3 then
						hit[char] = true
						if core.Damage(char, damage, "P5EnhancedBurst") > 0 then
							core.Melee.HitFx(p)
							FX.Impact(ctx, wall, p, Golden.CRIMSON, Golden.WHITE, 0.8, { Shake = 0.4, Tint = 0.45 })
							Runtime.Knockback(actor, char, Vector3.new(p.X - center.X, 0, p.Z - center.Z),
								{ Speed = Style.WallKnockback, Lift = 28, Duration = 0.4, Sustain = 0.15, ContainsArena = true })
						end
					end
				end
			end
			if radius >= maxR then
				wall:Dispose()
				return false
			end
			return true
		end)
	end

	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local result = core.Perform(target, "P5EnhancedBurst", function()
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local root = core.Root
			local origin = root.Position
			local ground = Placement.GroundPoint(origin, { Clamp = true })
			local floorY = ground and ground.Y or origin.Y - 3
			local center = Vector3.new(origin.X, floorY + 0.08, origin.Z)
			local cast = Effects.NewCast(actor, "P5EnhancedBurst", Style.Windup + Style.Recovery + Style.SecondDelay + Style.SecondWindup + 3)
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
					and not actor:GetAttribute("EncounterEnded")
					and not actor:GetAttribute("PhaseTransitionInProgress")
			end

			 
			actor:SetAttribute("AttackState", "Burst: gathering")
			core.PoseAngles({ RightShoulder = { 25, 0, -45 }, LeftShoulder = { 25, 0, 45 }, Waist = { -15, 0, 0 } }, Style.Windup * 0.6)
			Audio.Emit(actor, "ThrustCharge", root)
			local zone = Golden.Disc(ctx, cast, "P5EnhancedBurstZone", center, Style.CoreRadius * 2, Golden.CRIMSON, 0.85, Style.Windup + 0.1)
			FX.Tween(zone, Style.Windup, { Transparency = 0.55 }, Enum.EasingStyle.Quad)
			FX.Ring(ctx, cast, CFrame.new(center + Vector3.new(0, 0.2, 0)) * CFrame.Angles(math.pi / 2, 0, 0), Style.CoreRadius * 2.6, 3,
				Style.Windup, Golden.ROSE, 0, 0.5)
			local orb = FX.Temp(ctx, cast, "P5EnhancedBurstCore", CFrame.new(origin), Vector3.one * 0.6, Golden.WHITE, 0.05, Style.Windup + 0.1)
			orb.Shape = Enum.PartType.Ball
			FX.Tween(orb, Style.Windup, { Size = Vector3.one * 7 }, Enum.EasingStyle.Quad)
			local halo = FX.Temp(ctx, cast, "P5EnhancedBurstHalo", CFrame.new(origin), Vector3.one * 16, Golden.CRIMSON, 0.9, Style.Windup + 0.1)
			halo.Shape = Enum.PartType.Ball
			FX.Tween(halo, Style.Windup, { Size = Vector3.one * 5, Transparency = 0.5 }, Enum.EasingStyle.Quad)
			local inhaleHost = FX.Anchor(ctx, cast, origin, Style.Windup + 0.3)
			inhaleHost.Size = Vector3.one * 30
			local inhale = FX.Emitter(inhaleHost, {
				Color = FX.Grad(Golden.WHITE, Golden.GOLD),
				Size = FX.Keyed({ 0, 0.2 }, { 0.6, 0.7 }, { 1, 0.25 }),
				Transparency = FX.Keyed({ 0, 1 }, { 0.3, 0.1 }, { 1, 0 }),
				Lifetime = NumberRange.new(0.45),
				Speed = NumberRange.new(-32),
				Shape = Enum.ParticleEmitterShape.Sphere,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
				Rate = 140,
			})
			cast:Schedule(Style.Windup, function()
				inhale.Enabled = false
			end)
			FX.Shake(ctx, origin, 80, Style.Windup, 0.25)
			if not core.WaitFor(Style.Windup) or not valid() then
				cast:Dispose()
				return false
			end

			 
			actor:SetAttribute("AttackState", "Burst: detonation")
			core.PoseAngles({ RightShoulder = { 100, 0, -95 }, LeftShoulder = { 100, 0, 95 }, Waist = { 12, 0, 0 } }, 0.06)
			Audio.Emit(actor, "ThrustBurst", root)
			core.Afterimage(root.CFrame)
			local dome = FX.Temp(ctx, cast, "P5EnhancedBurstDome", CFrame.new(origin), Vector3.one * 4, Golden.WHITE, 0, 0.45)
			dome.Shape = Enum.PartType.Ball
			FX.Tween(dome, 0.18, { Size = Vector3.one * Style.CoreRadius * 2.2, Transparency = 1 })
			local shell = FX.Temp(ctx, cast, "P5EnhancedBurstShell", CFrame.new(origin), Vector3.one * 6, Golden.CRIMSON, 0.2, 0.6)
			shell.Shape = Enum.PartType.Ball
			FX.Tween(shell, 0.45, { Size = Vector3.one * Style.CoreRadius * 2.6, Transparency = 1 })
			FX.Impact(ctx, cast, origin, Golden.CRIMSON, Golden.WHITE, 2.2, { Ground = CFrame.new(center), Dust = Golden.DUST, Shake = 1.1, Tint = 0.9 })
			FX.Beam(ctx, cast, center, center + Vector3.new(0, 70, 0), 9, Golden.CRIMSON, Golden.WHITE, 0.5)
			FX.Spikes(ctx, cast, center, 16, Style.CoreRadius * 0.75, 11, Golden.CRIMSON, Golden.GOLD, 1, 35)
			FX.Debris(ctx, cast, center + Vector3.new(0, 1, 0), 14, Color3.fromRGB(70, 50, 50), 1, 50, Enum.Material.Slate, 1.1)
			FX.Streaks(ctx, cast, origin, Vector3.yAxis, Golden.CRIMSON, Golden.WHITE, 40, 180, 70, 140, 4)
			for i = 1, 3 do
				cast:Schedule(i * 0.06, function()
					FX.Ring(ctx, cast, CFrame.new(origin + Vector3.new(0, i * 2.5, 0)) * CFrame.Angles(math.pi / 2, 0, i), 4, Style.CoreRadius * (2.4 - i * 0.3),
						0.4, i == 2 and Golden.GOLD or Golden.ROSE, 0, 0.9)
				end)
			end
			local scorch = Golden.Disc(ctx, cast, "P5EnhancedBurstScorch", center + Vector3.new(0, 0.02, 0), Style.CoreRadius * 2.1, Golden.DEEP, 0.3, 1.6)
			scorch.Material = Enum.Material.SmoothPlastic
			FX.Tween(scorch, 1.5, { Transparency = 1 })

			local hits = 0
			for _, char in ipairs(core.Characters()) do
				if core.Alive(char) then
					local p = char.HumanoidRootPart.Position
					if Vector3.new(p.X - origin.X, 0, p.Z - origin.Z).Magnitude <= Style.CoreRadius and math.abs(p.Y - origin.Y) <= 12
						and core.CanHit(char, origin) then
						if core.Damage(char, Style.CoreDamage, "P5EnhancedBurst") > 0 then
							hits += 1
							core.Melee.HitFx(p)
							Runtime.Knockback(actor, char, Vector3.new(p.X - origin.X, 0, p.Z - origin.Z),
								{ Speed = 55, Lift = 40, Duration = 0.45, Sustain = 0.15, ContainsArena = true })
						end
					end
				end
			end
			actor:SetAttribute("P5EnhancedBurstCoreHits", hits)
			releaseWall(center, floorY, generation, { Clearance = Style.WallClearance })
			actor:SetAttribute("P5EnhancedBurstWallsReleased", (actor:GetAttribute("P5EnhancedBurstWallsReleased") or 0) + 1)

			 
			 
			if Style.SecondWave and Difficulty.Mercy("BurstSecondWave") ~= false then
				if not core.WaitFor(Style.SecondDelay) or not valid() then
					cast:Dispose()
					return false
				end
				actor:SetAttribute("AttackState", "Burst: second wave")
				local spin = math.random() * math.pi * 2
				local gaps = {}
				local gapCount = Difficulty.Mercy("BurstGaps") or Style.SecondGaps
				local gapDegrees = Style.SecondGapDegrees * (Difficulty.Mercy("BurstGapScale") or 1)
				for i = 1, gapCount do
					gaps[i] = { Angle = (spin + (i - 1) / gapCount * math.pi * 2) % (math.pi * 2), Half = math.rad(gapDegrees) / 2 }
				end
				 
				for _, g in ipairs(gaps) do
					local out = Vector3.new(math.cos(g.Angle), 0, math.sin(g.Angle))
					local len = Style.WallMaxRadius * 0.8
					local mid = center + out * (len / 2 + 4) + Vector3.new(0, 0.06, 0)
					local lane = FX.Temp(ctx, cast, "P5EnhancedBurstGapLane", CFrame.lookAt(mid, mid + out), Vector3.new(0.4, 0.08, len), Golden.WHITE, 0.6,
						Style.SecondWindup + 1.2)
					FX.Tween(lane, Style.SecondWindup, { Size = Vector3.new(2 * (len / 2 + 4) * math.tan(g.Half) * 0.5, 0.08, len), Transparency = 0.45 })
					cast:Schedule(Style.SecondWindup + 0.6, function()
						if lane.Parent then
							FX.Tween(lane, 0.5, { Transparency = 1 })
						end
					end)
					FX.Glint(ctx, cast, center + out * 10 + Vector3.new(0, 2, 0), Golden.GOLD, 4, Style.SecondWindup)
				end
				core.PoseAngles({ RightShoulder = { 170, 0, -10 }, LeftShoulder = { 170, 0, 10 }, Waist = { -10, 0, 0 } }, Style.SecondWindup * 0.7)
				local orb2 = FX.Temp(ctx, cast, "P5EnhancedBurstCore2", CFrame.new(origin + Vector3.new(0, 4, 0)), Vector3.one * 0.6, Golden.WHITE, 0.05, Style.SecondWindup + 0.1)
				orb2.Shape = Enum.PartType.Ball
				FX.Tween(orb2, Style.SecondWindup, { Size = Vector3.one * 5 })
				FX.Ring(ctx, cast, CFrame.new(center + Vector3.new(0, 0.3, 0)) * CFrame.Angles(math.pi / 2, 0, 0), Style.CoreRadius * 2, 2, Style.SecondWindup, Golden.GOLD, 0, 0.6)
				Audio.Emit(actor, "ThrustCharge", root)
				if not core.WaitFor(Style.SecondWindup) or not valid() then
					cast:Dispose()
					return false
				end
				core.PoseAngles({ RightShoulder = { 60, 0, -100 }, LeftShoulder = { 60, 0, 100 }, Waist = { 15, 0, 0 } }, 0.06)
				Audio.Emit(actor, "ThrustBurst", root)
				FX.Impact(ctx, cast, origin, Golden.CRIMSON, Golden.WHITE, 1.6, { Ground = CFrame.new(center), Dust = Golden.DUST, Shake = 0.9, Tint = 0.7 })
				FX.Beam(ctx, cast, center, center + Vector3.new(0, 60, 0), 6, Golden.GOLD, Golden.WHITE, 0.4)
				releaseWall(center, floorY, generation, {
					Height = Style.SecondHeight,
					Speed = Style.SecondSpeed,
					Damage = Style.SecondDamage,
					Gaps = gaps,
				})
				actor:SetAttribute("P5EnhancedBurstWallsReleased", (actor:GetAttribute("P5EnhancedBurstWallsReleased") or 0) + 1)
			end

			local ok = core.WaitFor(Style.Recovery) and valid()
			cast:Schedule(1.2, function()
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
