local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Projectiles = require(BossSystem.Combat.ProjectileService)
	local core = Registry.For(actor, "P1CombatCore")
	local api = {}
	local GOLD = Style.GOLD
	local BRIGHT = Style.BRIGHT
	local WHITE_HOT = Style.WHITE_HOT
	local AMBER = Style.AMBER
	local EMBER = Style.EMBER
	local LIFETIME = 30
	local function THREAD_LIFETIME() return Difficulty.Design("GildedThread", "ThreadLifetime", 8) end
	 
	 
	local SEGMENT_LENGTH = 32
	local MAX_SEGMENTS = 48
	local CONTACT_INTERVAL = 0.5

	local function CHARGE_TIME() return Difficulty.Design("GildedThread", "ChargeTime", 0.4) end
	local CORE_WIDTH = 0.18  
	local GLOW_WIDTH = 1.2  
	local HOT_TIME = 0.45  
	local FADE_TIME = 1.4  
	local STYLE_RATE = 1 / 15  
	local MAX_IMPACTS = 6  
	local IMPACT_TIME = 0.09  
	local EFFECT_LINGER = 0.8  
	local SPHERE_ALPHA = 0.3  
	local HALO_ALPHA = 0.8
	local PARTICLE_TEXTURE = ""  
	local RIBBON_TEXTURE = ""  

	local HEAT = ColorSequence.new(BRIGHT, GOLD)
	local FADE_OUT = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.6, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})

	local function distanceSquaredToSegment(point, a, b)
		local delta = b - a
		local t = delta:Dot(delta) > 0.0001 and math.clamp((point - a):Dot(delta) / delta:Dot(delta), 0, 1) or 0
		return (point - (a + delta * t)):Dot(point - (a + delta * t))
	end

	local part = Visuals.part({
		Effects = Effects,
		Runtime = Runtime,
	})

	local emitter = Visuals.emitter({
		PARTICLE_TEXTURE = PARTICLE_TEXTURE,
	})

	 
	 
	 
	local buildHeadFx = Visuals.buildHeadFx({
		GOLD = GOLD,
		emitter = emitter,
		FADE_OUT = FADE_OUT,
		HEAT = HEAT,
		BRIGHT = BRIGHT,
		AMBER = AMBER,
	})

	 
	local createSlot = Visuals.createSlot({
		RIBBON_TEXTURE = RIBBON_TEXTURE,
	})

	 
	 
	 
	local styleSlot = Visuals.styleSlot({
		WHITE_HOT = WHITE_HOT,
		BRIGHT = BRIGHT,
		CORE_WIDTH = CORE_WIDTH,
		GLOW_WIDTH = GLOW_WIDTH,
		GOLD = GOLD,
		AMBER = AMBER,
		EMBER = EMBER,
	})

	 
	 
	local playCharge = Visuals.playCharge({
		Effects = Effects,
		actor = actor,
		CHARGE_TIME = CHARGE_TIME(),
		part = part,
		WHITE_HOT = WHITE_HOT,
		GOLD = GOLD,
		emitter = emitter,
		HEAT = HEAT,
		core = core,
	})

	function api.Release(direction)
		local root = core.Root
		local origin = root.Position + Vector3.new(0, 0.3, 0) + direction * 4
		local cast = Effects.NewCast(actor, "P1.5GildedThread", LIFETIME + THREAD_LIFETIME() + 0.3)
		local anchor = part("GildedThreadPool", Vector3.new(0.1, 0.1, 0.1), GOLD, 1)
		anchor.CFrame = CFrame.identity
		cast:Add(anchor)
		local sphere = part("GildedThreadSphere", Vector3.new(2.8, 2.8, 2.8), GOLD, SPHERE_ALPHA)
		sphere.Shape = Enum.PartType.Ball
		sphere.CFrame = CFrame.new(origin)
		Audio.Emit(actor, "ThreadLaunch", origin)
		cast:Add(sphere)
		local halo = part("GildedThreadSphereHalo", Vector3.new(3.8, 3.8, 3.8), GOLD, HALO_ALPHA)
		halo.Shape = Enum.PartType.Ball
		halo.CFrame = sphere.CFrame
		cast:Add(halo)
		 
		local heart = part("GildedThreadSphereCore", Vector3.new(1.4, 1.4, 1.4), WHITE_HOT, 0)
		heart.Shape = Enum.PartType.Ball
		heart.CFrame = sphere.CFrame
		cast:Add(heart)
		local headFx = buildHeadFx(sphere)

		local slots = {}
		local nextSlot = 1
		local currentSlot
		local position = origin
		local age = 0
		local projectileAge = 0
		local generation = true
		local damageClock = 0
		local styleClock = 0
		local lingerUntil
		local threadDebounce = setmetatable({}, { __mode = "k" })
		local sphereDebounce = setmetatable({}, { __mode = "k" })
		local humLoop
		local params = core.Params()
		local speed = actor:GetAttribute("GildedThreadSpeed") or Difficulty.Design("GildedThread", "Speed", 125, actor)
		local projectileLifetime = math.clamp(actor:GetAttribute("GildedThreadLifetime") or LIFETIME, 0.5, LIFETIME)
		local segmentLifetime =
			math.clamp(actor:GetAttribute("GildedThreadSegmentLifetime") or THREAD_LIFETIME(), 1, THREAD_LIFETIME())
		 
		local fadeTime = math.min(FADE_TIME, segmentLifetime * 0.4)

		 
		 
		local impacts, nextImpact = {}, 1
		local createImpact = Visuals.createImpact({
			anchor = anchor,
			emitter = emitter,
			WHITE_HOT = WHITE_HOT,
			AMBER = AMBER,
			BRIGHT = BRIGHT,
			GOLD = GOLD,
		})

		local function impactFx(at, normal, strength)
			local slot = impacts[nextImpact]
			if not slot then
				slot = createImpact()
				impacts[nextImpact] = slot
			end
			nextImpact = nextImpact % MAX_IMPACTS + 1
			local up = math.abs(normal.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis
			slot.att.CFrame = CFrame.lookAt(at, at + normal, up)
			slot.sparks.Rate = 260 * (strength or 1)
			slot.sparks.Enabled = true
			slot.flash.Enabled = true
			slot.offAt = age + IMPACT_TIME
		end

		 
		local function acquire(start)
			local slot = slots[nextSlot]
			if not slot then
				slot = createSlot(anchor)
				slots[nextSlot] = slot
			end
			 
			 
			if slot.active and slot.expiresAt > age then
				return nil
			end
			nextSlot = nextSlot % MAX_SEGMENTS + 1
			slot.start = start
			slot.finish = start
			slot.a.Position = start
			slot.b.Position = start
			slot.expiresAt = age + segmentLifetime
			slot.active = true
			slot.stage = 0
			slot.settleAt = nil
			styleSlot(slot, 0)
			slot.beam.Enabled = true
			slot.glow.Enabled = true
			return slot
		end

		 
		local function closeSlot(slot)
			slot.settleAt = age + HOT_TIME
		end

		local function drawPath(a, b, finishSegment)
			if (b - a).Magnitude < 0.001 then
				return
			end
			if not currentSlot then
				currentSlot = acquire(a)
			end
			if currentSlot then
				currentSlot.finish = b
				currentSlot.b.Position = b
				currentSlot.expiresAt = age + segmentLifetime
				if finishSegment or (b - currentSlot.start).Magnitude >= SEGMENT_LENGTH then
					closeSlot(currentSlot)
					currentSlot = nil
				end
			end
		end

		local function applyContact(character, amount)
			local dealt = core.Damage(character, amount)
			if dealt > 0 then
				AttackDebuffs.Apply(actor,character,"Rupture",3,cast)
			end
			return dealt
		end

		local function sweepSphere(a, b)
			for _, character in ipairs(core.Characters()) do
				if core.Alive(character) and age >= (sphereDebounce[character] or 0) then
					local targetRoot = character:FindFirstChild("HumanoidRootPart")
					if targetRoot and distanceSquaredToSegment(targetRoot.Position, a, b) <= 3.2 * 3.2 then
						sphereDebounce[character] = age + 1
						if applyContact(character, Config.GildedThreadSphereDamage) > 0 then
							threadDebounce[character] = age + CONTACT_INTERVAL
							Audio.Emit(actor, "ThreadSphereHit", targetRoot)
							impactFx(targetRoot.Position, Vector3.yAxis, 1.3)
						end
					end
				end
			end
		end

		local function stopGeneration()
			if not generation then
				return
			end
			generation = false
			if humLoop then
				humLoop:Dispose()
				humLoop = nil
			end
			if currentSlot then
				closeSlot(currentSlot)
			end
			currentSlot = nil
			 
			if cast:Alive() then
				impactFx(position, Vector3.yAxis, 0.8)
			end
			headFx.Stop(false)
			Effects.Release(sphere)
			Effects.Release(halo)
			Effects.Release(heart)
			 
		end

		local function advance(dt)
			local remaining = speed * dt
			 
			for _ = 1, 5 do
				if remaining <= 0.001 then
					break
				end
				local step = direction * remaining
				local hit = workspace:Spherecast(position, 1.4, step, params)
				local traveled = hit and math.max(0, hit.Distance - 0.03) or remaining
				local destination = position + direction * traveled
				sweepSphere(position, destination)
				drawPath(position, destination, hit ~= nil)
				position = destination
				remaining -= traveled
				if not hit then
					break
				end
				local normal = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
				if normal.Magnitude < 0.1 then
					 
					stopGeneration()
					break
				end
				normal = normal.Unit
				Audio.Emit(actor, "ThreadBounce", position)
				impactFx(position, normal, 1)
				direction = (direction - 2 * direction:Dot(normal) * normal).Unit
				position += normal * 0.06
				remaining = math.max(0, remaining - 0.06)
			end
			if generation then
				sphere.CFrame = CFrame.new(position)
				halo.CFrame = sphere.CFrame
				heart.CFrame = sphere.CFrame
			end
		end

		local function damageThreads()
			for _, character in ipairs(core.Characters()) do
				if core.Alive(character) and age >= (threadDebounce[character] or 0) then
					local targetRoot = character:FindFirstChild("HumanoidRootPart")
					if not targetRoot then
						continue
					end
					for _, slot in ipairs(slots) do
						if
							slot.active
							and slot.expiresAt > age
							and distanceSquaredToSegment(targetRoot.Position, slot.start, slot.finish) <= 1.9 * 1.9
						then
							 
							threadDebounce[character] = age + CONTACT_INTERVAL
							if applyContact(character, Config.GildedThreadContactDamage) > 0 then
								Audio.Emit(actor, "ThreadContact", targetRoot)
								impactFx(targetRoot.Position, Vector3.yAxis, 0.7)
							end
							break
						end
					end
				end
			end
		end

		 
		local function restyle()
			for _, slot in ipairs(slots) do
				if slot.active then
					local remaining = slot.expiresAt - age
					if remaining <= fadeTime then
						slot.stage = 2
						styleSlot(slot, 2, remaining / fadeTime)
					elseif slot.stage == 0 and slot.settleAt and age >= slot.settleAt then
						slot.stage = 1
						styleSlot(slot, 1)
					end
				end
			end
		end

		local motion
		local sphereLease, haloLease, heartLease =
			Effects.LeaseId(sphere), Effects.LeaseId(halo), Effects.LeaseId(heart)
		local function updateProjectile(dt)
			projectileAge += dt
			if generation then
				if projectileAge >= projectileLifetime or not sphere.Parent then
					stopGeneration()
				else
					advance(math.min(dt, 0.12))
				end
			end
		end
		motion = Projectiles.RegisterMotion(actor, {
			Cast = cast,
			Skill = "P1.5GildedThread",
			Moving = function()
				return generation and not cast.closed and sphere.Parent ~= nil
			end,
			Hide = function(hidden)
				if not generation then
					return
				end
				if Effects.LeaseId(sphere) == sphereLease then
					sphere.Transparency = hidden and 1 or SPHERE_ALPHA
				end
				if Effects.LeaseId(halo) == haloLease then
					halo.Transparency = hidden and 1 or HALO_ALPHA
				end
				if Effects.LeaseId(heart) == heartLease then
					heart.Transparency = hidden and 1 or 0
				end
				headFx.SetVisible(not hidden)
			end,
			Advance = function(seconds)
				local remaining = math.clamp(seconds, 0, 3)
				while remaining > 0.0001 and generation and cast:Alive() do
					local dt = math.min(remaining, 1 / 30)
					updateProjectile(dt)
					remaining -= dt
				end
				return generation
			end,
		})
		cast.OnDispose = function()
			if motion then
				motion:Dispose()
			end
			headFx.Stop(true)
		end
		humLoop = Audio.Loop(cast, actor, "ThreadHum", sphere)
		cast:Step(function(dt)
			age += dt
			 
			 
			if not motion:IsHidden() then
				updateProjectile(dt)
			end
			local activeCount = 0
			for _, slot in ipairs(slots) do
				if slot.active then
					if slot.expiresAt <= age then
						slot.active = false
						slot.beam.Enabled = false
						slot.glow.Enabled = false
					else
						activeCount += 1
					end
				end
			end
			styleClock += dt
			if styleClock >= STYLE_RATE then
				styleClock = 0
				restyle()
			end
			for _, slot in ipairs(impacts) do
				if slot.offAt and age >= slot.offAt then
					slot.offAt = nil
					slot.sparks.Enabled = false
					slot.flash.Enabled = false
				end
			end
			damageClock += dt
			if damageClock >= 0.1 then
				damageClock = 0
				damageThreads()
			end
			if not generation and activeCount == 0 then
				 
				lingerUntil = lingerUntil or age + EFFECT_LINGER
				if age >= lingerUntil then
					cast:Dispose()
					return false
				end
			end
			return true
		end)
		actor:SetAttribute("GildedThreadsReleased", (actor:GetAttribute("GildedThreadsReleased") or 0) + 1)
		 
		impactFx(origin, direction, 1.6)
		return {
			Cast = cast,
			StopProjectile = stopGeneration,
			Slots = slots,
			Sphere = sphere,
			Motion = motion,
			MaxSegments = MAX_SEGMENTS,
			SegmentLifetime = segmentLifetime,
			ContactInterval = CONTACT_INTERVAL,
		}
	end

	function api.CanUse(character)
		return (tonumber(actor:GetAttribute("Phase")) or 1) >= 1.5 and core.Active() and core.Alive(character)
	end

	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P1.5GildedThread", function()
			core.Face(character)
			actor:SetAttribute("AttackState", "Gilded Thread: gathering light")
			Audio.Emit(actor, "ThreadSummon", core.Root)
			playCharge(character)
			core.Melee.Pose("Windup", 0.12)
			if not core.WaitFor(CHARGE_TIME()) or not core.Alive(character) then
				return false
			end
			local delta = character.HumanoidRootPart.Position - core.Root.Position
			local direction = Vector3.new(delta.X, 0, delta.Z)
			if direction.Magnitude < 0.01 then
				direction = core.Root.CFrame.LookVector
			end
			direction = direction.Unit
			core.Melee.Pose("Slash1", 0.1)
			actor:SetAttribute("AttackState", "Gilded Thread: release")
			api.Release(direction)
			return core.WaitFor(0.18)
		end)
	end

	function api.Dispose()
		 
	end
	api.Constants = {
		ProjectileLifetime = LIFETIME,
		ThreadLifetime = THREAD_LIFETIME(),
		MaxSegments = MAX_SEGMENTS,
		ContactInterval = CONTACT_INTERVAL,
	}
	api.DistanceSquaredToSegment = distanceSquaredToSegment
	return api
end
