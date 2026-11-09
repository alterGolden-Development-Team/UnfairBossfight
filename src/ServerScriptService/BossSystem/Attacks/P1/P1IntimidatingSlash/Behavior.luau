local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local nextContact = setmetatable({}, { __mode = "k" })
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Projectiles = require(BossSystem.Combat.ProjectileService)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local b = actor
	local core = Registry.For(b, "P1CombatCore")
	local Tween = Effects
	local Debris = Effects
	local api = {}
	local rng = Random.new()
	local gold = Style.gold
	local bright = Style.bright
	local deepGold = Style.deepGold
	local profile = Visuals.profile({})

	 
	local disc = Visuals.disc({
		core = core,
		Tween = Tween,
		Debris = Debris,
	})
	 
	local flash = Visuals.flash({
		core = core,
		bright = bright,
		Tween = Tween,
		Debris = Debris,
	})
	 
	local addTrail = Visuals.addTrail({
		bright = bright,
		gold = gold,
	})

	api.CreateFlameTrail = Visuals.CreateFlameTrail({
		Effects = Effects,
		actor = actor,
		Status = Status,
		Placement = Placement,
		core = core,
		Config = Config,
		gold = gold,
		Audio = Audio,
		bright = bright,
		deepGold = deepGold,
		rng = rng,
	})
	api.CreateWave = Visuals.CreateWave({
		core = core,
		b = b,
		gold = gold,
		bright = bright,
		Tween = Tween,
		profile = profile,
		deepGold = deepGold,
		addTrail = addTrail,
		Time = Time,
		actor = actor,
	})
	function api.TickContact(wave, candidates, now, distance)
		if actor:GetAttribute("IsIllusion") then
			return 0
		end
		now = now or Time.EncounterNow(actor)
		distance = distance or 0
		local interval = Config.IntimidatingTickInterval
		local count = 0
		for _, char in ipairs(candidates or core.Characters()) do
			if core.Alive(char) then
				local h = char:FindFirstChildOfClass("Humanoid")
				local position = char.HumanoidRootPart.Position
				local p = wave.frame:PointToObjectSpace(position)
				local curve, thickness = profile(p.X, wave.width)
				if
					now + 0.0001 >= (nextContact[h] or -math.huge)
					and math.abs(p.X) <= wave.width * 0.5 + 1.7
					and math.abs(p.Y) <= wave.depth * 0.5 + 3
					and p.Z <= curve + thickness * 0.5 + 1.7
					and p.Z >= curve - distance - thickness * 0.5 - 1.7
				then
					local origin = wave.frame:PointToWorldSpace(
						Vector3.new(math.clamp(p.X, -wave.width * 0.5, wave.width * 0.5), p.Y, curve)
					)
					if core.CanHit(char, origin) then
						nextContact[h] = now + interval
						wave.nextTick[h] = nextContact[h]
						if core.Damage(char, Config.IntimidatingTickDamage,"P1IntimidatingSlash") > 0 then
       AttackDebuffs.Apply(actor,char,"Fear",2,wave)
							count += 1
						end
						b:SetAttribute("IntimidatingSlashTicks", (b:GetAttribute("IntimidatingSlashTicks") or 0) + 1)
						 
						flash(origin, 5, 0.18, bright)
					end
				end
			end
		end
		return count
	end
	function api.StepWave(wave, distance, candidates, now)
		if not wave.model.Parent then
			return false
		end
		local direction = wave.frame.LookVector
		local wall = distance > 0.001
			and workspace:Raycast(wave.frame.Position + direction * 16, direction * distance, core.Params())
		if wall then
			distance = math.max(0, wall.Distance - 0.2)
			wave.blocked = true
		end
		api.TickContact(wave, candidates, now, distance)
		wave.frame = wave.frame + direction * distance
		wave.model:PivotTo(wave.frame)
		wave.traveled += distance
		return not wave.blocked
	end
	function api.RetireWave(wave)
		if not wave.model.Parent then
			return
		end
		for _, pulse in ipairs(wave.pulses or {}) do
			pulse:Cancel()
		end
		for _, v in ipairs(wave.model:GetDescendants()) do
			if v:IsA("BasePart") then
				 
				Tween:Create(
					v,
					TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1, Size = v.Size * Vector3.new(1.6, 1.3, 1) }
				):Play()
			elseif v:IsA("ParticleEmitter") then
				v:Emit(12)
				v.Enabled = false
			elseif v:IsA("PointLight") or v:IsA("Trail") then
				v.Enabled = false
			end
		end
		core.KeepFor(wave.model, 0.7)
	end
	function api.FireWave()
		Audio.Emit(actor, "CrescentRelease", core.Root)
		local frame = core.Root.CFrame + core.Root.CFrame.LookVector * 4 + Vector3.new(0, 0.7, 0)
		 
		do
			local feet = core.Root.Position - Vector3.new(0, 2.7, 0)
			disc(feet, 4, 46, 0.55, gold, 0.35)
			disc(feet, 2, 28, 0.4, bright, 0.2)
			flash(frame.Position, 10, 0.25, bright)
			flash(frame.Position, 16, 0.35, deepGold)
			for i = 1, 16 do
				local angle = i / 16 * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
				local d = Vector3.new(math.cos(angle), 0, math.sin(angle))
				core.MotionLine(
					"IntimidatingReleaseRay",
					feet + d * 3 + Vector3.new(0, 0.2, 0),
					feet + d * rng:NextNumber(14, 22) + Vector3.new(0, 0.2, 0),
					0.22,
					i % 2 == 0 and gold or bright,
					0.35
				)
			end
		end
		local wave = api.CreateWave(frame)
		local flames = api.CreateFlameTrail(wave.width)
		wave.Flames = flames
		flames:Add(frame)
		local nextFlame = Config.GoldenFlameSegmentLength
		b:SetAttribute("IntimidatingSlashesReleased", (b:GetAttribute("IntimidatingSlashesReleased") or 0) + 1)
		local speed = b:GetAttribute("IntimidatingSlashSpeed") or 8
		local cast = Effects.NewCast(actor, "IntimidatingSlash", wave.lifetime + 0.8)
		cast:Add(wave.model)
		local retiring = false
		local skippedAge = 0
		local function update(dt, now)
			if retiring or not cast:Alive() then
				return false
			end
			local moving = now + skippedAge < wave.createdAt + wave.lifetime
				and api.StepWave(wave, dt * speed, nil, now)
			if wave.traveled >= nextFlame then
				flames:Add(wave.frame)
				nextFlame = wave.traveled + Config.GoldenFlameSegmentLength
			end
			if not moving then
				retiring = true
				flames:Stop()
				api.RetireWave(wave)
				cast:Schedule(0.71, function()
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
			Skill = "P1IntimidatingSlash",
			Moving = function()
				return not retiring and cast:Alive() and wave.model.Parent ~= nil
			end,
			Hide = function(hidden)
				if retiring then
					return
				end
				for _, pulse in ipairs(wave.pulses or {}) do
					if hidden and pulse.PlaybackState == Enum.PlaybackState.Playing then
						pulse:Pause()
					elseif not hidden and pulse.PlaybackState == Enum.PlaybackState.Paused then
						pulse:Play()
					end
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
				local now = cast:Now()
				while remaining > 0.0001 and not retiring and cast:Alive() do
					local dt = math.min(remaining, 1 / 30)
					skippedAge += dt
					update(dt, now)
					remaining -= dt
				end
				return not retiring
			end,
		})
		wave.Motion = motion
		cast.OnDispose = function()
			flames:Stop()
			if motion then
				motion:Dispose()
			end
		end
		cast:Step(function(dt, now)
			if retiring then
				return false
			end
			if motion:IsHidden() then
				return true
			end
			return update(dt, now)
		end)

		return wave
	end
	 
	local startChargeVfx = Visuals.startChargeVfx({
		Effects = Effects,
		actor = actor,
		gold = gold,
		Tween = Tween,
		Debris = Debris,
		core = core,
		rng = rng,
		bright = bright,
		disc = disc,
	})
	function api.Combo(char)
		return core.Perform(char, "Intimidating Slash", function()
			core.Face(char)
			b:SetAttribute("AttackState", "Intimidating Slash: charged stance")
			Audio.Emit(actor, "CrescentCharge", core.Root)
			core.PoseAngles({
				RightShoulder = { 75, -25, 45 },
				RightElbow = { 35, 0, 0 },
				RightWrist = { -45, 0, 0 },
				Waist = { -8, -25, 0 },
				LeftShoulder = { 40, 0, -30 },
				LeftElbow = { 55, 0, 0 },
			}, 0.2)
			local blade = b["Basic Sword"].Blade
			local aura = core.Part("IntimidatingSwordCharge", blade.CFrame, Vector3.new(1, 1, 1), bright, 0.25)
			aura.Shape = Enum.PartType.Ball
			aura.Material = Enum.Material.Neon
			Tween:Create(aura, TweenInfo.new(0.8), { Size = Vector3.new(8, 8, 8), Transparency = 1 }):Play()
			Debris:AddItem(aura, 0.9)
			local chargeTime = b:GetAttribute("IntimidatingSlashChargeTime") or 1.5
			local chargeVfx = startChargeVfx(blade, chargeTime)
			local begin = os.clock()
			local waited = core.WaitFor(chargeTime)
			chargeVfx:Dispose()
			if not waited or not core.Alive(char) then
				return false
			end
			b:SetAttribute("LastIntimidatingChargeDuration", os.clock() - begin)
			core.Face(char)
			core.Melee.Pose("Slash1", 0.12)
			blade.SlashTrail.Enabled = true
			 
			flash(blade.Position, 9, 0.2, bright)
			b:SetAttribute("AttackState", "Intimidating Slash: release")
			api.FireWave()
			if not core.WaitFor(0.25) then
				return false
			end
			b:SetAttribute("CompletedIntimidatingSlashes", (b:GetAttribute("CompletedIntimidatingSlashes") or 0) + 1)
			return true
		end)
	end
	return api
end
