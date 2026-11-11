local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local b = actor
	local core = Registry.For(b, "P1CombatCore")
	local h, root, melee, effects = core.Humanoid, core.Root, core.Melee, core.Effects
	local Run = game:GetService("RunService")
	local Tween = Effects
	local Debris = Effects
	local api = {}
	local rng = Random.new()
	local gold = Style.gold
	local bright = Style.bright
	local deepGold = Style.deepGold
	local active, alive, characters, params = core.Active, core.Alive, core.Characters, core.Params
	local floorY, waitFor, face, part, canHit, motionLine =
		core.FloorY, core.WaitFor, core.Face, core.Part, core.CanHit, core.MotionLine

	 
	local disc = Visuals.disc({
		part = part,
		Tween = Tween,
		Debris = Debris,
	})
	 
	local glowBall = Visuals.glowBall({
		part = part,
		bright = bright,
		Tween = Tween,
		Debris = Debris,
	})
	 
	local bolt = Visuals.bolt({
		rng = rng,
		motionLine = motionLine,
		bright = bright,
		gold = gold,
	})
	 
	local radial = Visuals.radial({
		rng = rng,
		motionLine = motionLine,
		gold = gold,
		bright = bright,
	})
	 
	local fountain = Visuals.fountain({
		part = part,
		gold = gold,
		bright = bright,
		Debris = Debris,
	})

	function api.DamageCircle(center, hit, candidates, radius, inner)
		radius = radius or b:GetAttribute("FallingBladeRadius") or 225
		inner = inner or 0
		for _, char in ipairs(candidates or characters()) do
			if alive(char) then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local offset = char.HumanoidRootPart.Position - center
				local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if
					not hit[hum]
					and distance <= radius
					and distance >= inner
					and offset.Y >= -2
					and offset.Y <= (b:GetAttribute("FallingWaveHeight") or 10) + 2
					and canHit(char, center + Vector3.new(0, 2, 0))
				then
					hit[hum] = true
					if core.Damage(char, b:GetAttribute("FallingBladeDamage") or 22,"P1FallingBlade")>0 and inner==0 and distance<=12 then AttackDebuffs.Apply(actor,char,"Vulnerability",3,hit) end
					b:SetAttribute("FallingBladeHits", (b:GetAttribute("FallingBladeHits") or 0) + 1)
					 
					glowBall(char.HumanoidRootPart.Position, 7, 0.25, bright)
				end
			end
		end
	end
	api.CreateShockwave = Visuals.CreateShockwave({
		Audio = Audio,
		actor = actor,
		b = b,
		Effects = Effects,
		part = part,
		gold = gold,
		bright = bright,
		Tween = Tween,
		Debris = Debris,
		glowBall = glowBall,
		deepGold = deepGold,
		disc = disc,
		radial = radial,
		rng = rng,
		bolt = bolt,
		fountain = fountain,
	})
	function api.StepShockwave(wave, alpha, candidates)
		alpha = math.clamp(alpha, 0, 1)
		local r = 1 + (wave.radius - 1) * alpha
		api.DamageCircle(wave.center, wave.hit, candidates, r + 3, math.max(0, wave.previous - 3))
		wave.previous = r
		for _, item in ipairs(wave.pieces) do
			local direction = Vector3.new(math.cos(item.angle), 0, math.sin(item.angle))
			local length = 2 * r * math.sin(math.pi / wave.segments) + 0.12
			item.p.CFrame = CFrame.new(wave.center + direction * r + Vector3.new(0, wave.height * 0.5, 0))
				* CFrame.Angles(0, -item.angle, 0)
			item.p.Size = Vector3.new(6, wave.height, length)
			item.p.Transparency = 0.32 + 0.45 * alpha
			item.edge.CFrame = CFrame.new(wave.center + direction * (r + 2.8) + Vector3.new(0, wave.height, 0))
				* CFrame.Angles(0, -item.angle, 0)
			item.edge.Size = Vector3.new(0.6, 0.5, length + 0.18)
			item.edge.Transparency = 0.05 + 0.7 * alpha
		end
		if wave.floor and wave.floor.Parent then
			wave.floor.Size = Vector3.new(0.2, 2 * r, 2 * r)
			wave.floor.Transparency = 0.8 + 0.2 * alpha
		end
		b:SetAttribute("LastShockwaveRadius", r)
	end
	function api.Shockwave(center)
		local wave = api.CreateShockwave(center)
		local begin = wave.cast:Now()
		wave.cast:Step(function(_, now)
			local alpha = math.clamp((now - begin) / wave.duration, 0, 1)
			api.StepShockwave(wave, alpha)
			if alpha >= 1 then
				for _, item in ipairs(wave.pieces) do
					Tween:Create(item.p, TweenInfo.new(0.15), { Transparency = 1 }):Play()
					Tween:Create(item.edge, TweenInfo.new(0.15), { Transparency = 1 }):Play()
					for _, child in ipairs(item.p:GetChildren()) do
						if child:IsA("ParticleEmitter") then
							child.Enabled = false
						end
					end
				end
				if wave.floor and wave.floor.Parent then
					Tween:Create(wave.floor, TweenInfo.new(0.24), { Transparency = 1 }):Play()
				end
				return false
			end
			return true
		end)
		return active()
	end
	 
	local function moveAir(goal, duration, char, trail)
		local start = root.Position
		local begin = Time.ActionNow(actor)
		local p = params(char)
		repeat
			if not Time.WaitForActor(actor) or not active() or not alive(char) then
				return false
			end
			local t = math.clamp((Time.ActionNow(actor) - begin) / duration, 0, 1)
			local pos = start:Lerp(goal, t)
			local step = pos - root.Position
			local wall = step.Magnitude > 0.01 and workspace:Blockcast(root.CFrame, Vector3.new(2.3, 2.7, 2.3), step, p)
			if wall then
				root.CFrame = CFrame.new(root.Position + step.Unit * math.max(0, wall.Distance - 0.2))
					* root.CFrame.Rotation
				return false
			end
			if step.Magnitude > 3 then
				core.Afterimage(root.CFrame)
			end
			if trail and step.Magnitude > 0.5 then
				trail(root.Position, pos)
			end
			root.CFrame = CFrame.new(pos) * root.CFrame.Rotation
			if t >= 1 then
				return true
			end
			Run.Heartbeat:Wait()
		until false
	end
	local riseTrail = Visuals.riseTrail({
		motionLine = motionLine,
		deepGold = deepGold,
		gold = gold,
		bright = bright,
	})
	local slamTrail = Visuals.slamTrail({
		motionLine = motionLine,
		deepGold = deepGold,
		gold = gold,
		bright = bright,
		bolt = bolt,
	})
	function api.JumpToward(char)
		if not active() or not alive(char) then
			return false
		end
		face(char)
		local p = params(char)
		local y,groundY = floorY(root.Position, p)
		if not y then
			return false
		end
		local start = Vector3.new(root.Position.X, y, root.Position.Z)
  local floorPoint=Vector3.new(start.X,groundY,start.Z)
		core.AirborneFloor = y
		b:SetAttribute("AttackState", "Falling Blade: rising")
		melee.Pose("Windup3", 0.15)
		local height = b:GetAttribute("FallingJumpHeight") or 40
		 
		do
			local ground = floorPoint + Vector3.new(0, 0.11, 0)
			disc(ground, 4, 34, 0.45, gold, 0.35)
			disc(ground, 2, 20, 0.3, bright, 0.2)
			glowBall(start + Vector3.new(0, 2, 0), 10, 0.25, bright)
			fountain(start, 24)
			radial(ground, Vector3.xAxis, Vector3.zAxis, 14, 2, 14, 0.22, 0.3)
			motionLine("FallingBladeLaunchGlow", start, start + Vector3.new(0, height, 0), 3, deepGold, 0.35)
			motionLine("FallingBladeLaunchBeam", start, start + Vector3.new(0, height, 0), 1, bright, 0.35)
		end
		if not moveAir(start + Vector3.new(0, height, 0), 0.45, char, riseTrail) then
			return false
		end
		b:SetAttribute("LastFallingJumpHeight", root.Position.Y - y)
		b:SetAttribute("AttackState", "Falling Blade: sky charge")
		local aura = part("FallingBladeSkyAura", root.CFrame, Vector3.new(8, 8, 8), gold, 0.85)
		aura.Shape = Enum.PartType.Ball
		aura.Material = Enum.Material.Neon
		local audioCast = Effects.NewCast(actor, "FallingSwordAirHum", (b:GetAttribute("FallingHangTime") or 2) + 1)
		Audio.Loop(audioCast, actor, "FallingHum", aura)
		local begin = Time.ActionNow(actor)
		local hold = b:GetAttribute("FallingHangTime") or 2
		 
		 
		local extras = {}
		local function addExtra(object)
			table.insert(extras, object)
			return object
		end
		local function cleanupExtras()
			for _, object in ipairs(extras) do
				Debris:AddItem(object, 0)
			end
		end
		local coreBall = addExtra(part("FallingBladeSkyCore", root.CFrame, Vector3.new(4, 4, 4), bright, 0.2))
		coreBall.Shape = Enum.PartType.Ball
		coreBall.Material = Enum.Material.Neon
		local orbiters = {}
		for i = 1, 6 do
			local orb = addExtra(
				part("FallingBladeOrbit", root.CFrame, Vector3.new(1.1, 1.1, 1.1), i % 2 == 0 and gold or bright, 0.1)
			)
			orb.Shape = Enum.PartType.Ball
			orb.Material = Enum.Material.Neon
			table.insert(orbiters, orb)
		end
		local rise = math.max(4, root.Position.Y - y)
		local beam = addExtra(
			part(
				"FallingBladeSkyBeam",
				CFrame.new(start + Vector3.new(0, rise * 0.5, 0)),
				Vector3.new(1.5, rise, 1.5),
				gold,
				0.65
			)
		)
		beam.Material = Enum.Material.Neon
		Tween:Create(
			beam,
			TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.85 }
		):Play()
		local groundDisc = addExtra(
			part(
				"FallingBladeGatherDisc",
				CFrame.new(floorPoint + Vector3.new(0, 0.11, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				Vector3.new(0.2, 6, 6),
				gold,
				0.6
			)
		)
		groundDisc.Shape = Enum.PartType.Cylinder
		groundDisc.Material = Enum.Material.Neon
		Tween:Create(
			groundDisc,
			TweenInfo.new(hold, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = Vector3.new(0.2, 34, 34), Transparency = 0.3 }
		):Play()
		local skyLight = Instance.new("PointLight")
		skyLight.Color = gold
		skyLight.Brightness = 1
		skyLight.Range = 14
		skyLight.Parent = aura
		Tween:Create(
			skyLight,
			TweenInfo.new(hold, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Brightness = 6, Range = 40 }
		):Play()
		local prevT, streakTimer, ringTimer = 0, 0, 0
		repeat
			if not Time.WaitForActor(actor) or not active() or not alive(char) then
				audioCast:Dispose()
				Debris:AddItem(aura, 0)
				cleanupExtras()
				return false
			end
			face(char)
			aura.CFrame = root.CFrame
			local t = Time.ActionNow(actor) - begin
			local dt = math.max(0, t - prevT)
			prevT = t
			local progress = math.clamp(t / hold, 0, 1)
			aura.Size = Vector3.one * (8 + math.sin(t * 12) * 0.7)
			coreBall.CFrame = root.CFrame
			coreBall.Size = Vector3.one * (3.5 + math.sin(t * 16) * 0.6 + progress * 2)
			for i, orb in ipairs(orbiters) do
				local angle = t * (4 + progress * 4) + i * math.pi / 3
				orb.CFrame = CFrame.new(
					root.Position + Vector3.new(math.cos(angle) * 7, math.sin(t * 3 + i) * 2, math.sin(angle) * 7)
				)
			end
			streakTimer += dt
			if streakTimer >= 0.07 then
				streakTimer = 0
				for _ = 1, 1 + math.floor(progress * 3) do
					local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.5, 1), rng:NextNumber(-1, 1))
					dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.yAxis
					local radius = rng:NextNumber(10, 18) * (1 - progress * 0.3)
					motionLine(
						"FallingBladeChargeStreak",
						root.Position + dir * radius,
						root.Position + dir * radius * 0.2,
						0.12 + progress * 0.12,
						rng:NextNumber() > 0.5 and gold or bright,
						0.18
					)
				end
			end
			ringTimer += dt
			if ringTimer >= 0.4 - 0.2 * progress then
				ringTimer = 0
				disc(floorPoint + Vector3.new(0, 0.11, 0), 30 - 8 * progress, 4, 0.45, gold, 0.6)
			end
			Run.Heartbeat:Wait()
		until Time.ActionNow(actor) - begin >= hold
		b:SetAttribute("LastFallingHangTime", Time.ActionNow(actor) - begin)
		audioCast:Dispose()
		Debris:AddItem(aura, 0)
		cleanupExtras()
		 
		local target = char.HumanoidRootPart.Position
		local delta = Vector3.new(target.X - start.X, 0, target.Z - start.Z)
		local maxDistance = b:GetAttribute("FallingJumpDistance") or 80
		if delta.Magnitude > maxDistance then
			delta = delta.Unit * maxDistance
		end
		local goal = Vector3.new(start.X + delta.X, root.Position.Y, start.Z + delta.Z)
		local landingY = floorY(goal, p)
		if not landingY then
			goal = start
			landingY = y
		end
		goal = Vector3.new(goal.X, landingY, goal.Z)
		core.AirborneFloor = landingY
		b:SetAttribute("AttackState", "Falling Blade: sky slam")
		api.DownwardPose(0.05)
		Audio.Emit(actor, "FallingDescend", root)
		 
		do
			local sky = root.Position
			glowBall(sky, 16, 0.25, bright)
			radial(sky, Vector3.xAxis, Vector3.zAxis, 16, 2, 14, 0.22, 0.3)
			motionLine("FallingBladeSlamBeam", sky, goal, 1.8, bright, 0.25)
			motionLine("FallingBladeSlamBeamGlow", sky, goal, 5, deepGold, 0.3)
			bolt(sky, goal, 2, 0.25, 8, 0.3)
		end
		local landed = moveAir(goal, 0.18, char, slamTrail)
		local floor = floorY(root.Position, p)
		if not landed and floor then
			root.CFrame = CFrame.new(root.Position.X, floor, root.Position.Z) * root.CFrame.Rotation
		end
		if not floor then
			return false
		end
		b:SetAttribute(
			"LastFallingJumpDistance",
			(Vector3.new(root.Position.X, start.Y, root.Position.Z) - start).Magnitude
		)
		core.AirborneFloor = nil
		return active() and alive(char)
	end
	api.DownwardPose = Visuals.DownwardPose({
		core = core,
	})
	function api.FallingBlade(char)
		return require(BossSystem.Boss.GoldenGuardService).Run(actor, function()
			return core.Perform(char, "Falling Blade", function()
				face(char)
				b:SetAttribute("AttackState", "Falling Blade: wind-up")
				melee.Pose("Windup3", 0.16)
				Audio.Emit(actor, "FallingCharge", root)
				 
				local blade = b["Basic Sword"].Blade
				local light = Instance.new("PointLight")
				light.Color = gold
				light.Brightness = 0
				light.Range = 10
				light.Parent = blade
				Debris:AddItem(light, 6)
				Tween:Create(
					light,
					TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Brightness = 4, Range = 22 }
				):Play()
				do
					local _,groundY=floorY(root.Position,params(char))
     local feet=Vector3.new(root.Position.X,groundY or root.Position.Y-3,root.Position.Z)+Vector3.new(0,0.11,0)
					disc(feet, 20, 3, 0.3, gold, 0.5)
					glowBall(blade.Position, 5, 0.25, bright)
					for _ = 1, 6 do
						local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 1), rng:NextNumber(-1, 1))
						dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.yAxis
						local radius = rng:NextNumber(8, 13)
						motionLine(
							"FallingBladeWindupStreak",
							blade.Position + dir * radius,
							blade.Position + dir * radius * 0.2,
							0.14,
							rng:NextNumber() > 0.5 and gold or bright,
							0.2
						)
					end
				end
				if not waitFor(Difficulty.Design("FallingBlade", "Windup", 0.3, actor)) then
					return false
				end
				blade.SlashTrail.Enabled = true
				local jumped = api.JumpToward(char)
				Debris:AddItem(light, 0)
				if not jumped then
					return false
				end
				local _, ground = floorY(root.Position, params(char))
				if not ground then
					return false
				end
				b:SetAttribute("AttackState", "Falling Blade: massive shockwave")
				core.ScreenEffect("Shake", { Origin = root.Position, Radius = 240, Duration = 0.85, Intensity = 0.65 })
				if not api.Shockwave(Vector3.new(root.Position.X, ground + 0.18, root.Position.Z)) then
					return false
				end
				 
				for slam = 2, Difficulty.Design("FallingBlade", "Slams", 1, actor) do
					if not core.Alive(char) then
						break
					end
					b:SetAttribute("AttackState", "Falling Blade: second strike")
					melee.Pose("Windup3", 0.1)
					if not waitFor(0.18) then
						return false
					end
					if not api.JumpToward(char) then
						break
					end
					local _, ground2 = floorY(root.Position, params(char))
					if not ground2 then
						break
					end
					core.ScreenEffect("Shake", { Origin = root.Position, Radius = 240, Duration = 0.85, Intensity = 0.75 })
					if not api.Shockwave(Vector3.new(root.Position.X, ground2 + 0.18, root.Position.Z)) then
						return false
					end
					b:SetAttribute("FallingBladeSlams", slam)
				end
				b:SetAttribute("CompletedFallingBlades", (b:GetAttribute("CompletedFallingBlades") or 0) + 1)
				b:SetAttribute("AttackState", "Falling Blade: recovery")
				if not waitFor(0.24) then
					return false
				end
				b["Basic Sword"].Blade.SlashTrail.Enabled = false
				melee.Pose("Idle", 0.18)
				return true
			end)
		end)
	end

	api.Combo = api.FallingBlade
	return api
end
