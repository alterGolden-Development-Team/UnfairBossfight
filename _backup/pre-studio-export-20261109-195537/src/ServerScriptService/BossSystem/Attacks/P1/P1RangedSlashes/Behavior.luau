local Observer = require(script:FindFirstAncestor("BossSystem").Players.PlayerObserver)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Projectiles = require(BossSystem.Combat.ProjectileService)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local b = actor
	local h = b:WaitForChild("Humanoid")
	local root = b:WaitForChild("HumanoidRootPart")
	local melee = Registry.For(b, "P1NormalSlash")
	local core = Registry.For(b, "P1CombatCore")
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Players = game:GetService("Players")
	local Run = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local Tween = Effects
	local Debris = Effects
	local runtime = require(BossSystem.Combat.CombatRuntime)
	local api = {}
	local effects = Instance.new("Folder")
	effects.Name = "AlterGoldenRangedSlashes"
	effects.Parent = runtime.Effects
	Effects.TrackContainer(effects, actor)
	local GOLD = Style.GOLD
	local AMBER = Style.AMBER
	local WHITE = Style.WHITE
	local rng = Random.new()
	local function active()
		return core.Active()
	end
	local function alive(char)
  return core.Alive(char)
 end
	local characters = runtime.Characters
	local params = runtime.FilterFor(b, effects)
	local function waitFor(seconds)
		return core.WaitFor(seconds)
	end
	local function face(char)
		if not alive(char) then
			return
		end
		local pos = char.HumanoidRootPart.Position
		local flat = Vector3.new(pos.X, root.Position.Y, pos.Z)
		if (flat - root.Position).Magnitude > 0.01 then
			root.CFrame = CFrame.lookAt(root.Position, flat)
		end
	end
	local function floorY(pos, p)
		return core.FloorY(pos + Vector3.new(0, 10, 0), p)
	end
	local part = Visuals.part({
		Effects = Effects,
	})
	function api.Backstep(char)
		if not alive(char) then
			return false
		end
		local p = params(char)
		local start = Time.ActionNow(b)
		local movedUntil = 0
		local distance = 0
		local range = b:GetAttribute("RangedBackstepDistance") or 14
		local duration = 0.22
		local hover = b:GetAttribute("DashHoverHeight") or 1.8
		b:SetAttribute("AttackState", "Ranged slash: backward dash")
		melee.Pose("Dash", 0.08)
		face(char)
		local y = floorY(root.Position, p)
		if y then
			root.CFrame = CFrame.new(root.Position.X, y + hover, root.Position.Z) * root.CFrame.Rotation
		end
		repeat
			if not active() or not alive(char) then
				return false
			end
			local time = math.min(Time.ActionNow(b) - start, duration)
			local step = -root.CFrame.LookVector * (range / duration) * math.max(0, time - movedUntil)
			movedUntil = time
			local pos = root.Position + step
			local floor = floorY(pos, p)
			if not floor then
				break
			end
			pos = Vector3.new(pos.X, floor + hover, pos.Z)
			step = pos - root.Position
			local wall = workspace:Blockcast(root.CFrame, Vector3.new(2.3, 2.7, 2.3), step, p)
			if wall then
				break
			end
			distance += step.Magnitude
			root.CFrame = CFrame.new(pos) * root.CFrame.Rotation
			face(char)
			if step.Magnitude > 0.1 then
				local ghost = part(
					effects,
					"BackstepAfterimage",
					root.CFrame,
					Vector3.new(2, 3, 1),
					Color3.fromRGB(255, 220, 75),
					0.82
				)
				Tween:Create(ghost, TweenInfo.new(0.18), { Transparency = 1 }):Play()
				Debris:AddItem(ghost, 0.2)
			end
			Run.Heartbeat:Wait()
		until Time.ActionNow(b) - start >= duration
		 
		local remainder = range / duration * math.max(0, duration - movedUntil)
		if remainder > 0.01 then
			local step = -root.CFrame.LookVector * remainder
			local floor = floorY(root.Position + step, p)
			if floor and not workspace:Blockcast(root.CFrame, Vector3.new(2.3, 2.7, 2.3), step, p) then
				local pos = root.Position + step
				pos = Vector3.new(pos.X, floor + hover, pos.Z)
				distance += (pos - root.Position).Magnitude
				root.CFrame = CFrame.new(pos) * root.CFrame.Rotation
			end
		end
		b:SetAttribute("LastRangedBackstepDistance", distance)
		return active() and alive(char)
	end
	local makeSparks = Visuals.makeSparks({})

	local key = Visuals.key({})
	 
	local taper = Visuals.taper({})
	local burstSparks = Visuals.burstSparks({
		part = part,
		effects = effects,
		GOLD = GOLD,
		makeSparks = makeSparks,
		key = key,
		Debris = Debris,
	})
	local flashBall = Visuals.flashBall({
		part = part,
		effects = effects,
		WHITE = WHITE,
		Tween = Tween,
		Debris = Debris,
	})
	local streakBar = Visuals.streakBar({
		part = part,
		effects = effects,
		WHITE = WHITE,
		Tween = Tween,
		Debris = Debris,
	})
	 
	api.HitFx = Visuals.HitFx({
		flashBall = flashBall,
		WHITE = WHITE,
		rng = rng,
		streakBar = streakBar,
		burstSparks = burstSparks,
	})
	 
	api.LaunchFx = Visuals.LaunchFx({
		flashBall = flashBall,
		AMBER = AMBER,
		part = part,
		effects = effects,
		Tween = Tween,
		Debris = Debris,
		burstSparks = burstSparks,
	})
	 
	api.EndFx = Visuals.EndFx({
		flashBall = flashBall,
		WHITE = WHITE,
		burstSparks = burstSparks,
	})

	api.CreateWave = Visuals.CreateWave({
		effects = effects,
		b = b,
		part = part,
		GOLD = GOLD,
		makeSparks = makeSparks,
		WHITE = WHITE,
		AMBER = AMBER,
		key = key,
		taper = taper,
	})
	function api.StepWave(wave, distance, candidates)
		if not wave.model.Parent then
			return false
		end
		distance = math.min(distance, wave.range - wave.traveled)
		local delta = wave.frame.LookVector * distance
		local wall = workspace:Raycast(wave.frame.Position, delta, params())
		if wall then
			distance = math.max(0, wall.Distance - 0.1)
			delta = wave.frame.LookVector * distance
			wave.blocked = true
		end
		for _, char in ipairs(candidates or characters()) do
			if alive(char) then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local point = wave.frame:PointToObjectSpace(char.HumanoidRootPart.Position)
				if
					not wave.hit[hum]
					and math.abs(point.X) <= wave.width * 0.5 + 1.7
					and math.abs(point.Y - 0.7) <= 3.25
					and point.Z <= 2
					and point.Z >= -distance - 2
				then
					local rayStart = wave.frame:PointToWorldSpace(
						Vector3.new(math.clamp(point.X, -wave.width * 0.5, wave.width * 0.5), 0.7, 0)
					)
					local obstruction =
						workspace:Raycast(rayStart, char.HumanoidRootPart.Position - rayStart, params(char))
					if
						not obstruction
						and not char:GetAttribute("Invulnerable")
						and not char:FindFirstChildOfClass("ForceField")
					then
						wave.hit[hum] = true
						if core.Damage(char, wave.damage) > 0 then
							Audio.Emit(actor, "RangedImpact", char.HumanoidRootPart)
							api.HitFx(char.HumanoidRootPart.Position)
						end
						b:SetAttribute("RangedHits", (b:GetAttribute("RangedHits") or 0) + 1)
					end
				end
			end
		end
		wave.frame = wave.frame + delta
		wave.model:PivotTo(wave.frame)
		wave.traveled += distance
		return not wave.blocked and wave.traveled < wave.range
	end
	function api.RetireWave(wave)
		if wave.blocked then
			api.EndFx(wave)
		end
		for _, v in ipairs(wave.model:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Light") then
				v.Enabled = false
			elseif v:IsA("Beam") then
				TweenService:Create(v, TweenInfo.new(0.15), { Width0 = 0, Width1 = 0 }):Play()
			end
		end
		for _, p in ipairs(wave.model:GetChildren()) do
			if p:IsA("BasePart") then
				Tween:Create(p, TweenInfo.new(0.15), { Transparency = 1 }):Play()
			end
		end
		Debris:AddItem(wave.model, 0.17)
	end
	function api.FireWave(char, index, sharedHit, damage, options)
		options = options or {}
		if not alive(char) then
			return false
		end
		if not options.Frame then
			face(char)
		end
		local origin = root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 1, 0)
		local goal = char.HumanoidRootPart.Position
		local direction = Vector3.new(goal.X - origin.X, 0, goal.Z - origin.Z)
		if direction.Magnitude < 0.01 then
			direction = root.CFrame.LookVector
		end
		local frame = options.Frame or CFrame.lookAt(origin, origin + direction)
		local speed = options.Speed or b:GetAttribute("RangedSlashSpeed") or 225
		local finalDamage = (damage or b:GetAttribute("RangedSlashDamage") or 5) * (options.DamageScale or 1)
		local launchDelay = 0
		if not options.IsLastMinuteEcho then
			local snapshot = table.freeze({ Frame = frame, Index = index, Speed = speed, Damage = finalDamage })
			launchDelay = require(BossSystem.Phases.Phase25Controller).OnTemporalEmission(
				actor,
				"P1RangedSlashes",
				snapshot,
				function(saved, echo)
					echo.Frame = saved.Frame
					echo.Speed = saved.Speed
					return api.FireWave(char, saved.Index, nil, saved.Damage, echo)
				end
			) or 0
		end
		local wave = api.CreateWave(frame, index)
		wave.damage = finalDamage
		if sharedHit then
			wave.hit = sharedHit
		end
		b:SetAttribute("RangedSlashCount", (b:GetAttribute("RangedSlashCount") or 0) + 1)
		if options.Transparency then
			for _, p in ipairs(wave.model:GetDescendants()) do
				if p:IsA("BasePart") and p.Transparency < 1 then
					p.Transparency = options.Transparency
				end
			end
		end
		local cast = Effects.NewCast(
			actor,
			options.IsLastMinuteEcho and "LastMinuteSlashEcho" or "RangedSlash",
			wave.range / speed + launchDelay + 1
		)
		wave.Cast = cast
		local launchAt = cast:Now() + launchDelay
		cast:Add(wave.model)
		local retiring = false
		local audible = false
		local function update(dt)
			if retiring or not cast:Alive() then
				return false
			end
			if cast:Now() < launchAt then
				return true
			end
			if not audible then
				audible = true
				Audio.Emit(actor, "RangedLaunch", wave.frame.Position)
				Audio.Emit(actor, "RangedWhoosh", wave.frame.Position)
				if not options.IsLastMinuteEcho and not options.Transparency then
					api.LaunchFx(wave.frame)
				end
			end
			if not api.StepWave(wave, dt * speed) then
				retiring = true
				api.RetireWave(wave)
				cast:Schedule(0.18, function()
					cast:Dispose()
				end)
				return false
			end
			return true
		end
		local visuals = {}
		for _, object in ipairs(wave.model:GetDescendants()) do
			if object:IsA("BasePart") then
				visuals[object] = { Alpha = object.Transparency, Lease = Effects.LeaseId(object) }
			elseif
				object:IsA("ParticleEmitter")
				or object:IsA("Trail")
				or object:IsA("Beam")
				or object:IsA("Light")
			then
				visuals[object] = { Enabled = object.Enabled }
			end
		end
		local motion
		motion = Projectiles.RegisterMotion(actor, {
			Cast = cast,
			Skill = "P1RangedSlashes",
			Moving = function()
				return cast:Now() >= launchAt and not retiring and cast:Alive() and wave.model.Parent ~= nil
			end,
			Hide = function(hidden)
				if retiring then
					return
				end
				for object, snapshot in pairs(visuals) do
					if object.Parent then
						if snapshot.Alpha ~= nil and Effects.LeaseId(object) == snapshot.Lease then
							object.Transparency = hidden and 1 or snapshot.Alpha
						elseif snapshot.Enabled ~= nil then
							object.Enabled = not hidden and snapshot.Enabled
						end
					end
				end
			end,
			Advance = function(seconds)
				local remaining = math.clamp(seconds, 0, 3)
				while remaining > 0.0001 and not retiring and cast:Alive() do
					local dt = math.min(remaining, 1 / 30)
					update(dt)
					remaining -= dt
				end
				return not retiring
			end,
		})
		wave.Motion = motion
		cast.OnDispose = function()
			if motion then
				motion:Dispose()
			end
		end
		cast:Step(function(dt)
			if retiring then
				return false
			end
			if motion:IsHidden() then
				return true
			end
			return update(dt)
		end)

		return wave
	end
	api.SummonLightSword = Visuals.SummonLightSword({
		b = b,
		Debris = Debris,
	})
	function api.FireX(char)
		Audio.Emit(actor, "RangedX", root)
		local hit = {}
		local damage = b:GetAttribute("RangedXDamage") or 10
		local a = api.FireWave(char, 1, hit, damage)
		local c = api.FireWave(char, 2, hit, damage)
		b:SetAttribute("RangedXCount", (b:GetAttribute("RangedXCount") or 0) + 1)
		return a, c
	end
	function api.Combo(char)
		return core.Perform(char, "Ranged slash", function()
			b:SetAttribute("CurrentSkill", "Ranged slash")
			if not api.Backstep(char) then
				return false
			end
			b:SetAttribute("AttackState", "Ranged slash: wind-up")
			melee.Pose("Windup", 0.15)
			Audio.Emit(actor, "RangedSummon", root)
			local light = b["Basic Sword"].Blade.WindupLight
			light.Brightness = 4
			local lockedFirstFrame
			local warned, corrupted = core.WaitForTelegraph("P1RangedSlashes", 0.32, {
				Shape = "Line",
				Valid = function()
					return active() and alive(char)
				end,
				Geometry = function()
					local origin = lockedFirstFrame and lockedFirstFrame.Position
						or root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 1, 0)
					local target = char.HumanoidRootPart.Position
					local direction = lockedFirstFrame and lockedFirstFrame.LookVector
						or Vector3.new(target.X - origin.X, 0, target.Z - origin.Z)
					if direction.Magnitude < 0.01 then
						direction = root.CFrame.LookVector
					end
					return {
						Origin = origin,
						Direction = direction.Unit,
						Length = b:GetAttribute("RangedSlashRange") or 220,
						Width = 0.35,
					}
				end,
				Reveal = function(geometry)
					lockedFirstFrame = CFrame.lookAt(geometry.Origin, geometry.Origin + geometry.Direction)
				end,
			})
			if not warned then
				return false
			end
			local waves = Difficulty.Design("RangedSlashes", "Waves", 6, b)
			for index = 1, waves do
				if not alive(char) or not active() then
					return false
				end
				local swing = index % 2 == 1 and 1 or 2
				face(char)
				melee.Pose("Slash" .. swing, 0.12)
				b:SetAttribute("AttackState", "Ranged slash " .. index)
				api.FireWave(char, swing, nil, nil, index == 1 and corrupted and { Frame = lockedFirstFrame } or nil)
				if index < waves then
					if not waitFor(Difficulty.Design("RangedSlashes", "Gap", 0.2, b)) then
						return false
					end
					melee.Pose(swing == 1 and "Windup2" or "Windup", 0.10)
					if not waitFor(Difficulty.Design("RangedSlashes", "Windup", 0.12, b)) then
						return false
					end
				end
			end
			b:SetAttribute("AttackState", "Ranged slash 7: light sword X wind-up")
			local lightSword = api.SummonLightSword()
			core.PoseAngles({
				RightShoulder = { 110, 0, 25 },
				RightElbow = { 30, 0, 0 },
				LeftShoulder = { 110, 0, -25 },
				LeftElbow = {
					30,
					0,
					0,
				},
			}, 0.15)
			if not waitFor(Difficulty.Design("RangedSlashes", "XWindup", 0.35, b)) then
				if lightSword then
					Debris:AddItem(lightSword, 0)
				end
				return false
			end
			core.PoseAngles({
				RightShoulder = { 65, 0, -60 },
				RightElbow = { 8, 0, 0 },
				LeftShoulder = { 65, 0, 60 },
				LeftElbow = {
					8,
					0,
					0,
				},
			}, 0.12)
			b:SetAttribute("AttackState", "Ranged slash 7: golden X")
			api.FireX(char)
			if not waitFor(0.18) then
				return false
			end
			if lightSword then
				Debris:AddItem(lightSword, 0.1)
			end
			b:SetAttribute("CompletedRangedCombos", (b:GetAttribute("CompletedRangedCombos") or 0) + 1)
			b:SetAttribute("AttackState", "Ranged slash: recovery")
			light.Brightness = 0
			return true
		end)
	end
	function api.Dispose()  
	end
	return api
end
