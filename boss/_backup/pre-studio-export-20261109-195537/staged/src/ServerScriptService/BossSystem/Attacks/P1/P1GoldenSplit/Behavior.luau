local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Effects = require(BossSystem.Combat.EffectService)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local b = actor
	local core = Registry.For(b, "P1CombatCore")
	local root, h, melee = core.Root, core.Humanoid, core.Melee
	local Run = game:GetService("RunService")
	local Tween = Effects
	local Debris = Effects
	local api = {}
	local rng = Random.new()
	local gold = Style.gold
	local bright = Style.bright
	local deepGold = Style.deepGold
	local embers = Visuals.embers({
		gold = gold,
	})

	 
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
	 
	local bolt = Visuals.bolt({
		rng = rng,
		core = core,
		bright = bright,
		gold = gold,
	})
	 
	local fountain = Visuals.fountain({
		core = core,
		gold = gold,
		bright = bright,
		Debris = Debris,
	})

	api.TrailEffects = Visuals.TrailEffects({
		core = core,
		Tween = Tween,
		gold = gold,
		embers = embers,
		bright = bright,
		deepGold = deepGold,
		Debris = Debris,
	})
	function api.CreateLane(frame)
		local length = require(BossSystem.Combat.ArenaAttackRange).From(frame.Position, b:GetAttribute("SplitLength") or Config.SplitLength)
		local wall = workspace:Raycast(frame.Position, frame.LookVector * length, core.Params())
		if wall then
			length = math.max(1, wall.Distance - 0.3)
		end
		return {
			frame = frame,
			length = length,
			width = b:GetAttribute("SplitWidth") or Config.SplitWidth,
			nextTick = {},
		}
	end
	function api.CreateCross(frame)
		local cross = { lanes = {}, hit = {}, nextTick = {} }
		for index = 0, 3 do
			local lane = api.CreateLane(frame * CFrame.Angles(0, index * math.pi * 0.5, 0))
			lane.nextTick = cross.nextTick
			table.insert(cross.lanes, lane)
		end
		return cross
	end
	function api.InLane(lane, position, height)
		local p = lane.frame:PointToObjectSpace(position)
		return math.abs(p.X) <= lane.width * 0.5
			and p.Z <= 1
			and p.Z >= -lane.length
			and p.Y >= -4
			and p.Y <= (height or 24)
	end
	function api.DamageLane(lane, candidates, amount, hit, height, origin, onHit, skill)
		local count = 0
		for _, char in ipairs(candidates or core.Characters()) do
			if core.Alive(char) then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if
					not hit[hum]
					and api.InLane(lane, char.HumanoidRootPart.Position, height)
					and core.CanHit(char, origin or lane.frame.Position)
				then
					hit[hum] = true
					local dealt=core.Damage(char, amount,skill)
     if dealt>0 and onHit then onHit(char,dealt) end
					count += 1
				end
			end
		end
		return count
	end
	function api.TickTrail(lane, candidates, now)
		now = now or os.clock()
		local count = 0
		for _, char in ipairs(candidates or core.Characters()) do
			if core.Alive(char) then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if
					now >= (lane.nextTick[hum] or -math.huge)
					and api.InLane(lane, char.HumanoidRootPart.Position, 5)
					and core.CanHit(char, lane.frame.Position)
				then
					core.Damage(char, b:GetAttribute("SplitTickDamage") or 5)
					lane.nextTick[hum] = now + (b:GetAttribute("SplitTickInterval") or 0.5)
					count += 1
					b:SetAttribute("SplitTrailTicks", (b:GetAttribute("SplitTrailTicks") or 0) + 1)
					 
					flash(char.HumanoidRootPart.Position, 4, 0.18, bright)
				end
			end
		end
		return count
	end
	api.Warning = Visuals.Warning({
		h = h,
		root = root,
		core = core,
		gold = gold,
		Tween = Tween,
		bright = bright,
	})
	 
	function api.StrikeTemporary(lane, groundY, options, cast)
		Audio.Emit(b, "SwordSlash", lane.frame.Position)
		local height = options.Height or 24
		local center = lane.frame.Position + lane.frame.LookVector * lane.length * 0.5
		center = Vector3.new(center.X, groundY + height * 0.5, center.Z)
		local frame = CFrame.new(center) * lane.frame.Rotation
		local wall = core.Part("TemporaryGoldenSplit", frame, Vector3.new(lane.width, height, lane.length), gold, 0.18)
		wall.Material = Enum.Material.Neon
		local edge = not options.NoBrightEdge
				and core.Part(
					"TemporaryGoldenSplitEdge",
					frame,
					Vector3.new(0.3, height + 2, lane.length),
					bright,
					0.05
				)
			or nil
		if edge then
			edge.Material = Enum.Material.Neon
		end
		if cast then
			cast:Add(wall)
			if edge then
				cast:Add(edge)
			end
		end
		 
		Tween:Create(
			wall,
			TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1, Size = Vector3.new(lane.width * 1.4, height, lane.length) }
		):Play()
		if edge then
			Tween:Create(edge, TweenInfo.new(0.19), { Transparency = 1 }):Play()
		end
		if not cast then
			Debris:AddItem(wall, 0.28)
			if edge then
				Debris:AddItem(edge, 0.24)
			end
		end
		 
		local ground = Vector3.new(lane.frame.Position.X, groundY + 0.4, lane.frame.Position.Z)
		bolt(
			ground,
			ground + lane.frame.LookVector * lane.length,
			1.2,
			0.2,
			math.clamp(math.floor(lane.length / 5), 3, 16),
			0.35
		)
		fountain(Vector3.new(center.X, groundY + 0.3, center.Z), 14)
		local origin = options.Origin or lane.frame.Position + lane.frame.LookVector * lane.length * 0.5
		api.DamageLane(lane, nil, options.Damage or 20, options.Hit or {}, height, origin, options.OnHit, options.Skill)
		return wall, edge
	end
	function api.Strike(lane, sharedHit)
		local drop = h.HipHeight + root.Size.Y * 0.5 - 0.12
		local scar = core.Part(
			"GoldenSplitDamageTrail",
			lane.frame * CFrame.new(0, -drop, -lane.length * 0.5),
			Vector3.new(lane.width, 0.16, lane.length),
			gold,
			0.15
		)
		scar.Material = Enum.Material.Neon
		 
		Tween:Create(scar, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 0.6 })
			:Play()
		local lifetime = b:GetAttribute("SplitTrailLifetime") or 60
		scar:SetAttribute("Lifetime", lifetime)
		scar:SetAttribute("ExpiresAt", workspace:GetServerTimeNow() + lifetime)
		local lingering, pulses = api.TrailEffects(lane, drop, lifetime)
		core.KeepFor(scar, lifetime + 0.25)
		local cast = Effects.NewCast(actor, "GoldenSplitTrail", lifetime + 0.35)
		cast:Add(scar)
		cast:Add(lingering)
		 
		do
			local from = (lane.frame * CFrame.new(0, -drop + 0.4, -1)).Position
			local to = (lane.frame * CFrame.new(0, -drop + 0.4, -lane.length)).Position
			bolt(from, to, 1.3, 0.22, math.clamp(math.floor(lane.length / 4), 3, 24), 0.4)
		end
		 
		local segments = 14
		local segmentLength = lane.length / segments + 0.2
		for i = 0, segments - 1 do
			local t = (i + 0.5) / segments
			local height = 12 + 12 * math.abs(math.sin(i * 2.3))
			local roll = CFrame.Angles(0, 0, math.rad(-12 + 24 * math.sin(i)))
			local fullCf = lane.frame * CFrame.new(0, height * 0.5 - drop, -t * lane.length) * roll
			local lowCf = lane.frame * CFrame.new(0, height * 0.125 - drop, -t * lane.length) * roll
			local function erupt()
				local spike = core.Part(
					"GoldenSplitRaggedBlade",
					lowCf,
					Vector3.new(lane.width * 0.8, height * 0.25, segmentLength),
					gold,
					0.12
				)
				local edge = core.Part(
					"GoldenSplitBrightCut",
					lowCf,
					Vector3.new(0.45, height * 0.25 + 2, segmentLength + 0.1),
					bright,
					0.06
				)
				spike.Material = Enum.Material.Neon
				edge.Material = Enum.Material.Neon
				Tween:Create(
					spike,
					TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ CFrame = fullCf, Size = Vector3.new(lane.width * 0.8, height, segmentLength) }
				):Play()
				Tween:Create(
					edge,
					TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ CFrame = fullCf, Size = Vector3.new(0.45, height + 2, segmentLength + 0.1) }
				):Play()
				Tween:Create(
					spike,
					TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.09),
					{ Transparency = 1, Size = Vector3.new(lane.width * 1.2, height, segmentLength) }
				):Play()
				Tween:Create(
					edge,
					TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.09),
					{ Transparency = 1 }
				):Play()
				Debris:AddItem(spike, 0.5)
				Debris:AddItem(edge, 0.4)
				if i % 3 == 0 then
					fountain(fullCf.Position - Vector3.new(0, height * 0.5 - 0.3, 0), 16)
				end
			end
			local delay = t * 0.1
			if delay < 0.01 then
				erupt()
			else
				cast:Schedule(delay, erupt)
			end
		end
		local hitKey=sharedHit or {}
  api.DamageLane(lane, nil, b:GetAttribute("SplitDamage") or 30, hitKey, 24,nil,
   function(char) if actor:GetAttribute("CurrentAttackFile")=="P1GoldenSplit" then AttackDebuffs.Apply(actor,char,"Bleed",3,hitKey) end end,"P1GoldenSplit")
		 
		Audio.Loop(cast, actor, "SplitHum", scar)
		local elapsed = 0
		local finish = cast:Now() + lifetime
		cast:Step(function(dt, now)
			if now >= finish then
				for _, t in ipairs(pulses) do
					t:Cancel()
				end
				for _, v in ipairs(lingering:GetDescendants()) do
					if v:IsA("ParticleEmitter") or v:IsA("PointLight") then
						v.Enabled = false
					end
				end
				cast:Schedule(0.3, function()
					cast:Dispose()
				end)
				return false
			end
			elapsed += dt
			if elapsed >= 0.1 then
				elapsed = 0
				api.TickTrail(lane, nil, now)
			end
			return true
		end)

		return scar
	end
	function api.StrikeCross(cross)
		Audio.Emit(actor, "SplitActivate", root)
		local scars = {}
		for _, lane in ipairs(cross.lanes) do
			table.insert(scars, api.Strike(lane, cross.hit))
		end
		 
		do
			local drop = h.HipHeight + root.Size.Y * 0.5
			local feet = root.Position - Vector3.new(0, drop - 0.15, 0)
			disc(feet, 5, 52, 0.6, gold, 0.3)
			disc(feet, 3, 32, 0.4, bright, 0.15)
			flash(feet + Vector3.new(0, 2, 0), 12, 0.3, bright)
			flash(feet + Vector3.new(0, 2, 0), 20, 0.4, deepGold)
			local pillar = core.Part(
				"GoldenSplitPillar",
				CFrame.new(feet + Vector3.new(0, 18, 0)),
				Vector3.new(5, 36, 5),
				bright,
				0.2
			)
			pillar.Material = Enum.Material.Neon
			Tween:Create(
				pillar,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					CFrame = CFrame.new(feet + Vector3.new(0, 35, 0)),
					Size = Vector3.new(1.5, 70, 1.5),
					Transparency = 1,
				}
			):Play()
			Debris:AddItem(pillar, 0.4)
			for i = 1, 20 do
				local angle = i / 20 * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
				local d = Vector3.new(math.cos(angle), 0, math.sin(angle))
				core.MotionLine(
					"GoldenSplitImpactRay",
					feet + d * 4 + Vector3.new(0, 0.25, 0),
					feet + d * rng:NextNumber(14, 26) + Vector3.new(0, 0.25, 0),
					0.25,
					i % 2 == 0 and gold or bright,
					0.35
				)
			end
			fountain(feet, 28)
		end
		core.ScreenEffect("Shake", { Origin = root.Position, Radius = 180, Duration = 0.45, Intensity = 0.65 })
		b:SetAttribute("GoldenSplitCount", (b:GetAttribute("GoldenSplitCount") or 0) + 1)
		b:SetAttribute("LastSplitArmCount", #scars)
		return scars
	end
	 
	local startChargeVfx = Visuals.startChargeVfx({
		Effects = Effects,
		actor = actor,
		root = root,
		h = h,
		core = core,
		gold = gold,
		Tween = Tween,
		Debris = Debris,
		embers = embers,
		rng = rng,
		bright = bright,
		disc = disc,
	})
	function api.Combo(char)
		return core.Perform(char, "Golden Split", function()
			Audio.Emit(actor, "SplitCharge", root)
			core.Face(char)
			core.PoseAngles({
				RightShoulder = { 160, 0, -8 },
				RightElbow = { 8, 0, 0 },
				RightWrist = { -70, 0, 0 },
				Waist = { -8, 0, 0 },
				LeftShoulder = { 30, 0, -20 },
				LeftElbow = { 45, 0, 0 },
			}, 0.18)
			local cross = api.CreateCross(root.CFrame)
			local warnings = {}
			for _, lane in ipairs(cross.lanes) do
				local band, line = api.Warning(lane)
				table.insert(warnings, band)
				table.insert(warnings, line)
			end
			local function clearWarnings()
				for _, p in ipairs(warnings) do
					Debris:AddItem(p, 0)
				end
			end
			b:SetAttribute("AttackState", "Golden Split: sword raised / cross warning")
			local blade = b["Basic Sword"].Blade
			local warningTime = b:GetAttribute("SplitWarningTime") or 1
			local chargeVfx = startChargeVfx(blade, warningTime)
			local begin = os.clock()
			local waited = core.WaitFor(warningTime)
			chargeVfx:Dispose()
			if not waited then
				clearWarnings()
				return false
			end
			b:SetAttribute("LastSplitWarningTime", os.clock() - begin)
			clearWarnings()
			b:SetAttribute("AttackState", "Golden Split: sword ground slam")
			 
			flash(blade.Position, 9, 0.18, bright)
			core.PoseAngles({
				RightShoulder = { 10, 0, -12 },
				RightElbow = { 5, 0, 0 },
				RightWrist = { -75, 0, 0 },
				Waist = { 28, 0, 0 },
				LeftShoulder = { -15, 0, -20 },
				LeftElbow = { 35, 0, 0 },
				LeftHip = { -15, 0, 0 },
				RightHip = { 18, 0, 0 },
			}, 0.12)
			blade.SlashTrail.Enabled = true
			if not core.WaitFor(0.12) then
				return false
			end
			api.StrikeCross(cross)
			if not core.WaitFor(0.35) then
				return false
			end
			b:SetAttribute("CompletedGoldenSplits", (b:GetAttribute("CompletedGoldenSplits") or 0) + 1)
			return true
		end)
	end
	return api
end
