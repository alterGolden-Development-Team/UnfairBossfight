local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Projectiles = require(BossSystem.Combat.ProjectileService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Locomotion = require(BossSystem.Boss.BossLocomotion)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local b = actor
	local core = Registry.For(b, "P1CombatCore")
	local h, root, melee, effects, motors = core.Humanoid, core.Root, core.Melee, core.Effects, core.Motors
	local Run = game:GetService("RunService")
	local Tween = Effects
	local Debris = Effects
	local api = {}
	local gold = Style.gold
	local bright = Style.bright
	local deepGold = Style.deepGold
	local rng = Random.new()
	local active, alive, characters, params = core.Active, core.Alive, core.Characters, core.Params
	local floorY, waitFor, face, part, canHit, motionLine =
		core.FloorY, core.WaitFor, core.Face, core.Part, core.CanHit, core.MotionLine

	 
	local bolt = Visuals.bolt({
		rng = rng,
		motionLine = motionLine,
		bright = bright,
	})
	 
	local radial = Visuals.radial({
		rng = rng,
		motionLine = motionLine,
		gold = gold,
		bright = bright,
	})
	 
	local flash = Visuals.flash({
		part = part,
		bright = bright,
		Tween = Tween,
		Debris = Debris,
	})
	 
	local groundSparks = Visuals.groundSparks({
		rng = rng,
		motionLine = motionLine,
		gold = gold,
		bright = bright,
	})

	function api.IsNear(char)
		return alive(char)
			and (
				b:GetAttribute("CloneMode") == "HourDebt"
				or (char.HumanoidRootPart.Position - root.Position).Magnitude
					<= (b:GetAttribute("ThrustTriggerRange") or 50)
			)
	end
	function api.DamageThrust(frame, distance, hit, candidates)
		local reach = b:GetAttribute("ThrustReach") or 12
		for _, char in ipairs(candidates or characters()) do
			if alive(char) then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local offset = frame:PointToObjectSpace(char.HumanoidRootPart.Position)
				if
					not hit[hum]
					and math.abs(offset.X) <= (b:GetAttribute("ThrustHitboxWidth") or 15) * 0.5
					and math.abs(offset.Y) <= 4
					and offset.Z <= 1.5
					and offset.Z >= -distance - reach
					and canHit(char, frame.Position)
				then
					hit[hum] = true
					if core.Damage(char, b:GetAttribute("ThrustDamage") or 14,"P1GoldenThrust")>0 then AttackDebuffs.Apply(actor,char,"Rupture",3,hit) end
					b:SetAttribute("ThrustHits", (b:GetAttribute("ThrustHits") or 0) + 1)
				end
			end
		end
	end
	local stabPose = Visuals.stabPose({
		core = core,
	})
	function api.Lunge(char)
		if not active() or not alive(char) then
			return false
		end
		face(char)
		local p = params(char)
		local direction = root.CFrame.LookVector
		local rotation = root.CFrame.Rotation
		local range = b:GetAttribute("ThrustLungeDistance") or 45
		local duration = math.max(0.025, b:GetAttribute("ThrustDashDuration") or 0.12)
		local elapsed, moved = 0, 0
		local hit = {}
		local moving = true
		local cast = Effects.NewCast(actor, "GoldenThrustActiveDash", duration + 2)
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
		b:SetAttribute("AttackState", "Golden Thrust: lightning dash")
		stabPose(true, 0.035)
		Audio.Emit(actor, "ThrustBurst", root)
		local start = root.CFrame
		core.Afterimage(start)
		 
		do
			local groundStart = start.Position - Vector3.new(0, 2.6, 0)
			radial(start.Position, start.RightVector, start.UpVector, 14, 1.5, 7, 0.16, 0.28)
			radial(groundStart + Vector3.new(0, 0.15, 0), Vector3.xAxis, Vector3.zAxis, 12, 2, 10, 0.2, 0.3)
			flash(start.Position, 7, 0.2, bright)
			flash(start.Position, 11, 0.28, deepGold)
			groundSparks(groundStart, 6)
		end
		local function update(dt, skipping)
			if not moving or not active() or not alive(char) or not root.Parent then
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
			local step = direction * range / duration * dt
			local old = root.CFrame
			local wall = step.Magnitude > 0.01 and workspace:Blockcast(old, Vector3.new(2.3, 2.7, 2.3), step, p)
			if wall then
				step = direction * math.max(0, wall.Distance - 0.2)
			end
			local pos = root.Position + step
			local ground = floorY(pos, p)
			if not ground or math.abs(ground - root.Position.Y) > 4 then
				moving = false
				return false
			end
			if not skipping then
				api.DamageThrust(old, step.Magnitude, hit)
			end
			root.CFrame = CFrame.new(pos.X, ground, pos.Z) * rotation
			moved += step.Magnitude
			if not skipping then
				local a, z = old.Position, root.Position
				 
				motionLine("GoldenThrustGlow", a, z, 1.8, deepGold, 0.22)
				motionLine("GoldenThrustDashTrail", a, z, 0.9, gold, 0.3)
				motionLine(
					"GoldenThrustBrightCore",
					a + Vector3.new(0, 0.5, 0),
					z + Vector3.new(0, 0.5, 0),
					0.18,
					bright,
					0.25
				)
				if step.Magnitude > 1 then
					bolt(a + Vector3.new(0, 0.3, 0), z + Vector3.new(0, 0.3, 0), 1.5, 0.14)
					groundSparks(Vector3.new(z.X, ground, z.Z), 2)
				end
				if step.Magnitude > 2 then
					for fraction = 0.25, 1, 0.25 do
						core.Afterimage(old + step * fraction)
					end
				end
			end
			if wall or elapsed >= duration - 0.00001 then
				moving = false
			end
			return moving
		end
		local motion = Projectiles.RegisterMotion(actor, {
			Cast = cast,
			Skill = "P1GoldenThrust",
			Moving = function()
				return moving and cast:Alive() and active() and alive(char)
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
					local valid = Placement.Validate(actor, CFrame.new(point) * rotation, { Margin = 4 })
					if valid then
						root.CFrame = valid
					end
				end
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end,
		})
		cast.OnDispose = function()
			moving = false
			motion:Dispose()
			table.clear(visuals)
		end
		local sampledAt = Time.ActionNow(actor)
		while moving and cast:Alive() do
			if not Time.WaitForActor(actor) or not active() or not alive(char) then
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
		if not active() or not alive(char) then
			return false
		end
		b:SetAttribute("LastThrustLungeDistance", moved)
		b:SetAttribute("LastThrustDashDuration", elapsed)
		Audio.Emit(actor, "ThrustStab", root)
		for i = 1, 8 do
			local angle = i * math.pi / 4
			local offset = start.RightVector * math.cos(angle) * 7.5 + start.UpVector * math.sin(angle) * 2.4
			motionLine(
				"GoldenThrustSpeedLine",
				start.Position + offset,
				root.Position + offset,
				0.12,
				i % 2 == 0 and gold or bright,
				0.3
			)
		end
		 
		do
			local finish = root.Position
			local side = direction:Cross(Vector3.yAxis)
			side = side.Magnitude > 0.01 and side.Unit or Vector3.xAxis
			radial(finish, side, Vector3.yAxis, 16, 2, 10, 0.2, 0.3)
			for _ = 1, 8 do
				local spread = side * rng:NextNumber(-3, 3) + Vector3.new(0, rng:NextNumber(-1, 3), 0)
				motionLine(
					"GoldenThrustSpray",
					finish + direction * 2,
					finish + direction * rng:NextNumber(7, 13) + spread,
					0.14,
					rng:NextNumber() > 0.5 and gold or bright,
					0.25
				)
			end
			flash(finish, 9, 0.22, bright)
			flash(finish, 15, 0.32, deepGold)
			groundSparks(finish - Vector3.new(0, 2.6, 0), 8)
		end
		local width = b:GetAttribute("ThrustHitboxWidth") or 15
		local wakeCFrame = start * CFrame.new(0, -2.7, -(moved + 12) * 0.5)
		local lane = part("GoldenThrustWideWake", wakeCFrame, Vector3.new(width, 0.3, moved + 12), gold, 0.72)
		local laneCore = part(
			"GoldenThrustWakeCore",
			wakeCFrame * CFrame.new(0, 0.05, 0),
			Vector3.new(width * 0.3, 0.34, moved + 12),
			bright,
			0.45
		)
		Tween:Create(lane, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 })
			:Play()
		Debris:AddItem(lane, 0.43)
		Tween:Create(
			laneCore,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1, Size = Vector3.new(0.2, 0.34, moved + 12) }
		):Play()
		Debris:AddItem(laneCore, 0.28)
		b:SetAttribute("GoldenThrustCount", (b:GetAttribute("GoldenThrustCount") or 0) + 1)
		return true
	end
	function api.GoldenThrust(char)
		if not api.IsNear(char) then
			return false
		end
		return core.Perform(char, "Golden Thrust", function()
			local begin = Time.ActionNow(actor)
			for index = 1, 5 do
				if not active() or not alive(char) then
					return false
				end
				b["Basic Sword"].Blade.SlashTrail.Enabled = false
				face(char)
				stabPose(false, 0.035)
				b:SetAttribute("AttackState", "Golden Thrust: charging " .. index)
				Audio.Emit(actor, "ThrustCharge", root)
				local chargeBegin = Time.ActionNow(actor)
				if not waitFor(Config.ThrustChargeInterval) then
					return false
				end
				b:SetAttribute("LastThrustChargeDuration", Time.ActionNow(actor) - chargeBegin)
				b["Basic Sword"].Blade.SlashTrail.Enabled = true
				b:SetAttribute("AttackState", "Golden Thrust: lightning dash " .. index)
				if not api.Lunge(char) then
					return false
				end
			end
			b["Basic Sword"].Blade.SlashTrail.Enabled = false
			b:SetAttribute("LastThrustComboDuration", Time.ActionNow(actor) - begin)
			b:SetAttribute("CompletedGoldenThrusts", (b:GetAttribute("CompletedGoldenThrusts") or 0) + 1)
			b:SetAttribute("AttackState", "Golden Thrust: recovery")
			melee.Pose("Idle", 0.18)
			return true
		end)
	end

	api.Combo = api.GoldenThrust
	api.CanUse = api.IsNear
	return api
end
