 
 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local Style = require(script.Parent.Style)
local Effects = require(BossSystem.Combat.EffectService)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Crimson = require(BossSystem.Attacks.Shared.P4GoldenFX)
local FX = Crimson.FX
local Run = game:GetService("RunService")

local SKILL = "P4.5FlowerField"
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
 
local function FIELD_DURATION()
	return Style.FieldDuration * (Difficulty.Mercy("FlowerDuration") or 1)
end
local GOLD = Color3.fromRGB(246, 172, 28)
local BRIGHT = Color3.fromRGB(255, 222, 96)
local HEART = Color3.fromRGB(255, 118, 24)
local UP = Vector3.yAxis

return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local ctx = Crimson.Context(core)
	local api = { Cooldown = Style.Cooldown }
	local rng = Random.new()
	local current
	local nextTick = setmetatable({}, { __mode = "k" })  
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
			and Placement.Contains(target.HumanoidRootPart.Position)
	end

	 
	local function pattern(center)
		local spin = rng:NextNumber(0, math.pi * 2)
		local points = {}
		for i = 1, 5 do
			local angle = spin + (i - 1) * math.pi * 2 / 5
			points[i] = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * Style.OuterRadius
		end
		return points
	end

	 
	 
	local function petal(fields, color, alpha)
		local p = FX.Temp(ctx, fields, "GoldenLotusPetal", CFrame.new(), Vector3.new(0.1, 0.1, 0.1), color, alpha)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		return p
	end
	local function flower(fields, base, scale, delay, parts)
		local spin = rng:NextNumber(0, math.pi * 2)
		local heart = petal(fields, HEART, 0)
		heart.CFrame = CFrame.new(base)
		table.insert(parts, heart)
		local petals = {}
		for ring = 1, 2 do
			for k = 1, 6 do
				local ang = spin + (k - 1) / 6 * math.pi * 2 + (ring == 2 and math.pi / 6 or 0)
				local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
				local reach = (ring == 1 and 1.05 or 0.6) * scale
				local lift = math.rad(ring == 1 and 16 or 46)
				local size = Vector3.new(0.75, 0.16, 1.9) * scale * (ring == 1 and 1 or 0.72)
				local p = petal(fields, ring == 1 and GOLD or BRIGHT, ring == 1 and 0.05 or 0)
				local openCF = CFrame.lookAt(base, base + out) * CFrame.Angles(lift, 0, 0) * CFrame.new(0, 0.15 * scale, -reach)
				 
				local budCF = CFrame.lookAt(base, base + out) * CFrame.Angles(math.rad(85), 0, 0) * CFrame.new(0, 0.2 * scale, -0.2 * scale)
				p.CFrame, p.Size = budCF, size * 0.25
				table.insert(petals, { Part = p, Open = openCF, Bud = budCF, Size = size, Ring = ring })
				table.insert(parts, p)
			end
		end
		fields:Schedule(delay, function()
			if not heart.Parent then
				return
			end
			FX.Tween(heart, 0.3, { CFrame = CFrame.new(base + Vector3.new(0, 0.35 * scale, 0)), Size = Vector3.new(0.9, 0.55, 0.9) * scale },
				Enum.EasingStyle.Back)
			for _, pt in ipairs(petals) do
				FX.Tween(pt.Part, 0.18, { Size = pt.Size * 0.7 })
				fields:Schedule(0.12 + (pt.Ring == 2 and 0.06 or 0), function()
					if pt.Part.Parent then
						FX.Tween(pt.Part, 0.38, { CFrame = pt.Open, Size = pt.Size }, Enum.EasingStyle.Back)
					end
				end)
			end
			fields:Schedule(0.45, function()
				if heart.Parent then
					FX.Glint(ctx, fields, base + Vector3.new(0, 0.6 * scale, 0), GOLD, 2.4 * scale, 0.35)
				end
			end)
		end)
		return { Heart = heart, Petals = petals, Base = base, Scale = scale }
	end
	local function wilt(f)
		for _, pt in ipairs(f.Petals) do
			if pt.Part.Parent then
				FX.Tween(pt.Part, 0.45, { CFrame = pt.Bud - Vector3.new(0, 0.6 * f.Scale, 0), Size = pt.Size * 0.3, Transparency = 1 })
			end
		end
		if f.Heart.Parent then
			FX.Tween(f.Heart, 0.45, { Size = Vector3.one * 0.1, Transparency = 1 })
		end
	end

	 
	local function bloom(fields, ground, generation)
		local r = Style.FieldRadius
		local parts = {}
		local fill = Crimson.Disc(ctx, fields, "FlowerFieldFill", ground + Vector3.new(0, 0.04, 0), 0.5, GOLD, 0.86)
		FX.Tween(fill, 0.3, { Size = Vector3.new(0.06, r * 2, r * 2) }, Enum.EasingStyle.Back)
		table.insert(parts, fill)
		local ringHost = FX.Temp(ctx, fields, "FlowerFieldRing", CFrame.new(ground + Vector3.new(0, 0.2, 0)), Vector3.one * 0.2, GOLD, 1)
		table.insert(parts, ringHost)
		local setOuter = FX.CurvedRing(ringHost, "XZ")
		local setInner = FX.CurvedRing(ringHost, "XZ")
		 
		local all = {}
		local count = Style.FlowersPerField or 7
		for i = 1, count do
			local pos, scale
			if i == 1 then
				pos, scale = ground, Style.FlowerScale[2] * 1.2
			else
				local ang = (i - 2) / (count - 1) * math.pi * 2 + rng:NextNumber(-0.25, 0.25)
				local d = r * rng:NextNumber(0.5, 0.72)
				pos = ground + Vector3.new(math.cos(ang) * d, 0, math.sin(ang) * d)
				scale = rng:NextNumber(Style.FlowerScale[1], Style.FlowerScale[2])
			end
			table.insert(all, flower(fields, pos, scale, 0.05 + i * 0.05, parts))
		end
		local anchor = FX.Anchor(ctx, fields, ground + Vector3.new(0, 0.4, 0))
		anchor.Size = Vector3.new(r * 1.7, 0.2, r * 1.7)
		table.insert(parts, anchor)
		local pollen = FX.Emitter(anchor, {
			Color = FX.Grad(BRIGHT, GOLD, HEART),
			Size = FX.Seq(0.45, 0.3, 0),
			Transparency = FX.Seq(0, 0.2, 1),
			Lifetime = NumberRange.new(1.5, 2.5),
			Speed = NumberRange.new(1, 3),
			SpreadAngle = Vector2.new(20, 20),
			Acceleration = Vector3.new(0, 1.2, 0),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-120, 120),
			Rate = 22,
		})
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness, light.Shadows = GOLD, math.min(30, r * 1.8), 0.9, false
		light.Parent = anchor
		local born = fields:Now()
		local wilted = false
		local scanAt = 0
		fields:Step(function(_, now)
			if not fill.Parent then
				return false
			end
			if not actor.Parent or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation then
				fields:Dispose()
				return false
			end
			local age = now - born
			local open = 1 - (1 - math.clamp(age / 0.3, 0, 1)) ^ 3
			local fade = wilted and math.clamp((age - (FIELD_DURATION() - 0.5)) / 0.5, 0, 1) or 0
			local breathe = math.sin(age * 3)
			setOuter(math.max(0.5, r * open), 0.95 + 0.15 * breathe, fade, ColorSequence.new(GOLD))
			setInner(math.max(0.3, (r - 1.1) * open), 0.28, math.min(1, 0.35 + fade), ColorSequence.new(BRIGHT))
			fill.Transparency = math.min(1, 0.85 + 0.04 * breathe + 0.15 * fade)
			if not wilted and age >= FIELD_DURATION() - 0.5 then
				wilted = true
				pollen.Enabled = false
				FX.Tween(light, 0.5, { Brightness = 0 })
				for _, f in ipairs(all) do
					wilt(f)
				end
			end
			if age >= FIELD_DURATION() then
				for _, part in ipairs(parts) do
					FX.Release(fields, part)
				end
				return false
			end
			 
			if not wilted and age > 0.25 and now - scanAt >= 0.1 then
				scanAt = now
				local clock = os.clock()
				for _, char in ipairs(core.Characters()) do
					if core.Alive(char) and clock >= (nextTick[char] or 0) then
						local p = char.HumanoidRootPart.Position
						if Vector3.new(p.X - ground.X, 0, p.Z - ground.Z).Magnitude <= r
							and p.Y - ground.Y <= Style.FieldHeight and p.Y >= ground.Y - 2 then
							nextTick[char] = clock + Style.FieldTick
							if core.Damage(char, Style.FieldDamage, SKILL) > 0 then
								local feet = Vector3.new(p.X, ground.Y + 0.5, p.Z)
								FX.Sparks(ctx, fields, feet, GOLD, BRIGHT, 10, 6, 16, 0.45)
								FX.Streaks(ctx, fields, feet, UP, GOLD, BRIGHT, 8, 25, 14, 28, 1.4)
								actor:SetAttribute("FlowerFieldTicks", (actor:GetAttribute("FlowerFieldTicks") or 0) + 1)
							end
						end
					end
				end
			end
			return true
		end)
	end

	 
	local function throwBomb(fields, from, ground, generation)
		local flight = Style.BombFlight * rng:NextNumber(0.92, 1.08)
		 
		local markAnchor, setMark = Crimson.BeamRing(ctx, fields, "FlowerBombMarker", ground + Vector3.new(0, 0.18, 0), Style.FieldRadius, Crimson.CRIMSON, 0.35, 28)
		local markBorn = fields:Now()
		fields:Step(function(_, now)
			if not markAnchor.Parent then
				return false
			end
			local k = math.clamp((now - markBorn) / flight, 0, 1)
			setMark(Style.FieldRadius * (1.35 - 0.35 * k), 0.6 - 0.5 * k, 0.25 + 0.35 * k)
			if k >= 1 then
				FX.Release(fields, markAnchor)
				return false
			end
			return true
		end)
		 
		local bud = FX.Temp(ctx, fields, "FlowerBomb", CFrame.new(from), Vector3.one * 1.3, BRIGHT, 0)
		bud.Shape = Enum.PartType.Ball
		local wrap = {}
		for i = 1, 5 do
			local p = FX.Temp(ctx, fields, "FlowerBombPetal", CFrame.new(from), Vector3.new(0.7, 0.18, 1.5), i % 2 == 0 and GOLD or BRIGHT, 0)
			local pm = Instance.new("SpecialMesh")
			pm.MeshType = Enum.MeshType.Sphere
			pm.Parent = p
			wrap[i] = p
		end
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(0, 0.45, 0), Vector3.new(0, -0.45, 0)
		a0.Parent, a1.Parent = bud, bud
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Color = FX.Grad(BRIGHT, GOLD, Crimson.CRIMSON)
		trail.Transparency = FX.Seq(0.1, 1)
		trail.Lifetime = 0.35
		trail.LightEmission = 1
		trail.FaceCamera = true
		trail.Parent = bud
		local born = fields:Now()
		local peak = math.max(from.Y, ground.Y) + Style.BombArc
		fields:Step(function(_, now)
			if not bud.Parent then
				return false
			end
			if not actor.Parent or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation then
				fields:Dispose()
				return false
			end
			local t = math.clamp((now - born) / flight, 0, 1)
			local flat = from:Lerp(ground, t)
			local y = (1 - t) ^ 2 * from.Y + 2 * (1 - t) * t * (peak * 2 - (from.Y + ground.Y) / 2) + t ^ 2 * ground.Y
			local pos = Vector3.new(flat.X, y + 0.6, flat.Z)
			bud.CFrame = CFrame.new(pos)
			local spin = (now - born) * 14
			for i, p in ipairs(wrap) do
				local a = spin + (i - 1) / 5 * math.pi * 2
				local out = Vector3.new(math.cos(a), 0.3, math.sin(a))
				p.CFrame = CFrame.lookAt(pos + out * 0.75, pos + out * 2)
			end
			if t >= 1 then
				FX.Release(fields, bud)
				for _, p in ipairs(wrap) do
					FX.Release(fields, p)
				end
				 
				local at = ground + Vector3.new(0, 0.6, 0)
				FX.Flash(ctx, fields, at, Crimson.WHITE, 7, 0.12, 0)
				FX.Flash(ctx, fields, at, GOLD, Style.FieldRadius * 2.2, 0.3, 0.35)
				FX.Shockwave(ctx, fields, CFrame.new(ground + Vector3.new(0, 0.1, 0)), 1, Style.FieldRadius * 2.2, 0.3, BRIGHT, 0.15)
				FX.Ring(ctx, fields, CFrame.new(at) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), 1, Style.FieldRadius * 1.6, 0.3, GOLD, 0, 0.35, 14)
				FX.Sparks(ctx, fields, at, GOLD, BRIGHT, 22, 14, 34, 0.6)
				FX.Streaks(ctx, fields, at, UP, GOLD, Crimson.WHITE, 10, 55, 30, 60, 2.2)
				FX.Light(ctx, fields, at, GOLD, 6, 20, 0.3)
				FX.Shake(ctx, at, 50, 0.15, 0.2)
				for _, char in ipairs(core.Characters()) do
					if core.Alive(char) then
						local p = char.HumanoidRootPart.Position
						if Vector3.new(p.X - at.X, 0, p.Z - at.Z).Magnitude <= Style.BombBlastRadius + 1.5 and math.abs(p.Y - at.Y) <= 7
							and core.CanHit(char, at + Vector3.new(0, 1, 0)) then
							if core.Damage(char, Style.BombDamage, SKILL) > 0 then
								core.Melee.HitFx(p)
							end
						end
					end
				end
				bloom(fields, ground, generation)
				return false
			end
			return true
		end)
	end

	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local result = core.Perform(target, SKILL, function()
			local root = core.Root
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local startGround = Placement.GroundPoint(root.Position, { Clamp = true })
			if not startGround then
				return false
			end
			local start = root.Position
			local standing = math.max(2.5, start.Y - startGround.Y)
			local cast = Effects.NewCast(actor, SKILL, Style.LeapTime + Style.HangTime + Style.DescendTime + Style.Recovery + 2)
			current = cast
			local anchored = root.Anchored
			local tookAnchor = false
			local landed = false
			local function land()
				if landed then
					return
				end
				landed = true
				if root.Parent and (actor:GetAttribute("MovementRevision") or 0) == revision then
					local g = Placement.GroundPoint(root.Position, { Clamp = true }) or startGround
					root.CFrame = CFrame.new(g.X, g.Y + standing, g.Z) * root.CFrame.Rotation
					if tookAnchor then
						Time.SetAnchored(root, anchored)
					end
					root.AssemblyLinearVelocity = Vector3.zero
				end
			end
			cast.OnDispose = function()
				land()
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
			local function move(duration, path)
				local t = 0
				while t < duration do
					local dt = Run.Heartbeat:Wait()
					if not valid() or not Time.WaitForActor(actor) or not valid() then
						return false
					end
					t += dt * Time.BossRate(actor)
					path(math.clamp(t / duration, 0, 1))
				end
				return true
			end
			local function facing(position)
				local tp = core.Alive(target) and target.HumanoidRootPart.Position or position + root.CFrame.LookVector
				local flat = Vector3.new(tp.X, position.Y, tp.Z)
				return (flat - position).Magnitude > 0.1 and CFrame.lookAt(position, flat) or CFrame.new(position) * root.CFrame.Rotation
			end

			 
			actor:SetAttribute("AttackState", "Flower Field: leap")
			core.PoseAngles({ RightShoulder = { -20, 0, -30 }, LeftShoulder = { -20, 0, 30 }, Waist = { 20, 0, 0 } }, 0.08)
			Audio.Emit(actor, "ThrustCharge", root)
			local feet = startGround + Vector3.new(0, 0.1, 0)
			FX.Shockwave(ctx, cast, CFrame.new(feet), 2, 22, 0.4, GOLD, 0.2)
			FX.Smoke(ctx, cast, feet, Crimson.DUST, 5, 8, 18, 2)
			FX.Sparks(ctx, cast, feet + Vector3.new(0, 1, 0), GOLD, BRIGHT, 24, 14, 32, 0.6)
			Time.SetAnchored(root, true)
			tookAnchor = true
			local apex = start + Vector3.new(0, Style.LeapHeight, 0)
			core.PoseAngles({ RightShoulder = { 160, 0, -20 }, LeftShoulder = { 150, 0, 20 }, Waist = { -10, 0, 0 } }, Style.LeapTime)
			if not move(Style.LeapTime, function(a)
				local e = 1 - (1 - a) ^ 3
				root.CFrame = facing(start:Lerp(apex, e))
				if a > 0.15 then
					core.Afterimage(root.CFrame)
				end
			end) then
				return fail()
			end

			 
			actor:SetAttribute("AttackState", "Flower Field: flower bombs")
			local who = core.Alive(target) and target or nil
			if not who then
				return fail()
			end
			local aim = Placement.GroundPoint(who.HumanoidRootPart.Position, { Clamp = true, Margin = Style.OuterRadius + Style.FieldRadius + 1 }) or startGround
			local fields = Effects.NewCast(actor, SKILL .. "Fields", Style.HangTime + Style.BombFlight * 1.2 + FIELD_DURATION() + 2)
			local halo = FX.Temp(ctx, cast, "FlowerFieldHalo", CFrame.new(apex) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.1, 2, 2), GOLD, 0.2,
				Style.HangTime + 0.2)
			halo.Shape = Enum.PartType.Cylinder
			FX.Tween(halo, Style.HangTime, { Size = Vector3.new(0.05, 18, 18), Transparency = 1 })
			FX.Ring(ctx, cast, CFrame.new(apex) * CFrame.Angles(math.pi / 2, 0, 0), 2, 14, Style.HangTime, Crimson.CRIMSON, 0, 0.4, 10)
			FX.Glint(ctx, cast, apex + Vector3.new(0, 2, 0), GOLD, 8, 0.4)
			FX.Shake(ctx, apex, 90, 0.3, 0.3)
			 
			local safe = Crimson.Disc(ctx, fields, "FlowerFieldSafeMark", Vector3.new(aim.X, aim.Y + 0.04, aim.Z), (Style.OuterRadius - Style.FieldRadius) * 1.6, BRIGHT, 0.92,
				Style.BombFlight + 1.2)
			FX.Tween(safe, Style.BombFlight + 1.1, { Transparency = 1 })
			local points = pattern(Vector3.new(aim.X, aim.Y, aim.Z))
			 
			if Difficulty.Mercy("FlowerCenterBomb") and core.Alive(who) then
				local p = who.HumanoidRootPart.Position
				table.insert(points, Vector3.new(p.X, aim.Y, p.Z))
			end
			local thrown = 0
			for i, p in ipairs(points) do
				local ground = Placement.GroundPoint(p, { Margin = Style.FieldRadius, Clamp = true })
				if ground then
					thrown += 1
					cast:Schedule(i * Style.BombStagger, function()
						if valid() then
							local hand = ctx.Root.Position + Vector3.new(0, 1.5, 0)
							local okHand, h = pcall(function()
								local arm = actor:FindFirstChild(i % 2 == 0 and "RightHand" or "LeftHand") or actor:FindFirstChild(i % 2 == 0 and "Right Arm" or "Left Arm")
								return arm and arm.Position
							end)
							local from = okHand and h or hand
							throwBomb(fields, from, ground, generation)
							FX.Flash(ctx, cast, from, BRIGHT, 2.5, 0.1, 0)
						end
					end)
				end
			end
			actor:SetAttribute("FlowerFieldBombs", thrown)
			local throwTime = math.max(Style.HangTime, #points * Style.BombStagger + 0.1)
			local swap = false
			if not move(throwTime, function(a)
				local phase = math.floor(a * 6)
				if (phase % 2 == 0) ~= swap then
					swap = phase % 2 == 0
					core.PoseAngles(swap and { RightShoulder = { 120, 0, -80 }, LeftShoulder = { 40, 0, 30 } }
						or { RightShoulder = { 40, 0, -30 }, LeftShoulder = { 120, 0, 80 } }, 0.05)
				end
				root.CFrame = facing(apex + Vector3.new(0, math.sin(a * math.pi) * 1.2, 0))
			end) then
				return fail()
			end

			 
			actor:SetAttribute("AttackState", "Flower Field: landing")
			local top = root.Position
			local bottom = Vector3.new(start.X, startGround.Y + standing, start.Z)
			core.PoseAngles({ RightShoulder = { 30, 0, -50 }, LeftShoulder = { 30, 0, 50 }, Waist = { 10, 0, 0 } }, Style.DescendTime)
			if not move(Style.DescendTime, function(a)
				root.CFrame = facing(top:Lerp(bottom, a * a))
			end) then
				return fail()
			end
			land()
			FX.Shockwave(ctx, cast, CFrame.new(feet), 2, 16, 0.3, GOLD, 0.25)
			FX.Smoke(ctx, cast, feet, Crimson.DUST, 4, 6, 14, 2)
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
