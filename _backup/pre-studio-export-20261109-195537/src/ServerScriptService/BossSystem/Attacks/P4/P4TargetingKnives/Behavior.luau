local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Aim = require(BossSystem.Combat.AttackTargetContinuity)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Projectiles = require(BossSystem.Combat.ProjectileService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Players = game:GetService("Players")
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = Registry.For(actor, "P1CombatCore")
	local random = Random.new()
	local active = {}
	local COOLDOWN_SCALE = 0.8
	local INTERVAL_SCALE = 0.85
	local function CUE_SCALE() return Difficulty.Design("TargetingKnives", "CueScale", 0.8) end
	local DEFAULT_FLIGHT_SPEED = 12000  
	local DAMAGE_SCALE = 1.2
	local HIT_RADIUS = 2.3
	local function EXTRA_KNIVES() return Difficulty.Design("TargetingKnives", "Extra", 1) end
	local PERPENDICULAR_ORDER = true
	local function HUNTER_EVERY() return Difficulty.Design("TargetingKnives", "HunterEvery", 2) end
	local function HUNTER_TURN() return Difficulty.Design("TargetingKnives", "HunterTurn", Config.P4KnifeHunterTurnRate or 2.2) end
	local HUNTER_MIN_SPEED = 5
	local api = { Cooldown = (Config.P4KnifeCooldown or 14) * COOLDOWN_SCALE }

	local GOLD = Style.GOLD
	local AMBER = Style.AMBER
	local EMBER = Style.EMBER
	local RED = Style.RED
	local WHITE = Style.WHITE
	local SPARKLE = Style.SPARKLE
	local RIFT_LEAD = 0.15

	local CUE_SPAWN = "P4KnifeSpawn"
	local CUE_LOCK = "P4KnifeLock"
	local CUE_LAUNCH = "P4KnifeLaunch"
	local CUE_HIT = "P4KnifeHit"

	local key = Visuals.key({})
	local flightTrail = Visuals.flightTrail({ core = core, Effects = Effects, Style = Style })

	local function living(character)
  if Aim.Valid(character) then return true end
		local player = character and Players:GetPlayerFromCharacter(character)
		return player
			and player.Character == character
			and not player:GetAttribute("PermanentlyDefeated")
			and not player:GetAttribute("ViewAsServer")
			and core.Alive(character)
	end

	local sound = Visuals.sound({
		Audio = Audio,
		actor = actor,
	})
	local shake = Visuals.shake({
		core = core,
	})
	local disc = Visuals.disc({
		core = core,
	})
	local pulse = Visuals.pulse({
		disc = disc,
		Effects = Effects,
	})
	local sparkEmitter = Visuals.sparkEmitter({
		SPARKLE = SPARKLE,
		key = key,
	})
	local burstSparks = Visuals.burstSparks({
		core = core,
		sparkEmitter = sparkEmitter,
		Effects = Effects,
	})

	local function sectorOrder(count)
		local order, used = {}, {}
		local wanted = PERPENDICULAR_ORDER and count / 4 or count / 2
		local previous = random:NextInteger(1, count)
		order[1] = previous
		used[previous] = true
		for index = 2, count do
			local bestScore, candidates = -math.huge, {}
			for sector = 1, count do
				if not used[sector] then
					local distance = math.abs(sector - previous)
					distance = math.min(distance, count - distance)
					local score = -math.abs(distance - wanted)
					if score > bestScore + 1e-6 then
						bestScore = score
						candidates = { sector }
					elseif math.abs(score - bestScore) <= 1e-6 then
						table.insert(candidates, sector)
					end
				end
			end
			local pick = candidates[random:NextInteger(1, #candidates)]
			used[pick] = true
			order[index] = pick
			previous = pick
		end
		return order
	end
	local function moveAxis(character)
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return nil
		end
		local velocity = root.AssemblyLinearVelocity
		local flat = Vector3.new(velocity.X, 0, velocity.Z)
		if flat.Magnitude < HUNTER_MIN_SPEED then
			return nil
		end
		return flat.Unit
	end
	local function steerOffset(character, offset, dt)
		local axis = moveAxis(character)
		if not axis then
			return offset
		end
		local flat = Vector3.new(offset.X, 0, offset.Z)
		local distance = flat.Magnitude
		if distance < 0.01 then
			return offset
		end
		local want = axis
		if want:Dot(flat.Unit) < 0 then
			want = -want
		end
		local current = math.atan2(flat.Z, flat.X)
		local diff = math.atan2(want.Z, want.X) - current
		diff = math.atan2(math.sin(diff), math.cos(diff))
		local limit = HUNTER_TURN() * dt
		local nextAngle = current + math.clamp(diff, -limit, limit)
		local candidate = Vector3.new(math.cos(nextAngle) * distance, offset.Y, math.sin(nextAngle) * distance)
		local root = character:FindFirstChild("HumanoidRootPart")
		if
			root
			and not Placement.GroundPoint(
				root.Position + Vector3.new(candidate.X, 0, candidate.Z),
				{ Margin = 6, Clamp = false }
			)
		then
			return offset
		end
		return candidate
	end
	local function spawnPoint(position, radius, angle)
		local minimum = radius * 0.75
		local function safe(point, clamp)
			local ground = Placement.GroundPoint(point, { Margin = 6, Clamp = clamp == true })
			if not ground then
				return nil
			end
			local delta = ground - position
			return Vector3.new(delta.X, 0, delta.Z).Magnitude >= minimum and ground or nil
		end
		for attempt = 0, 7 do
			local a = angle + attempt * math.pi * 0.25
			local point = safe(position + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius), false)
			if point then
				return point
			end
		end
		local bounds = Placement.GetBounds()
		if not bounds then
			return nil
		end
		local inward = bounds.Frame.Position - position
		inward = Vector3.new(inward.X, 0, inward.Z)
		if inward.Magnitude < 0.01 then
			return nil
		end
		local point = position + inward.Unit * radius
		return safe(point, false) or safe(point, true)
	end

	function api.CanUse(target)
		if math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) ~= 4 or not core.Active() or Projectiles.Capacity(actor, "Golden") < 1 then
			return false
		end
		if living(target) then
			return true
		end
		for _, c in ipairs(core.Characters()) do
			if living(c) then
				return true
			end
		end
		return false
	end
	function api.Release(target)
		if not api.CanUse(target) then
			return false
		end
		local targets = {}
		for _, c in ipairs(core.Characters()) do
			if living(c) then
				table.insert(targets, Aim.For(c))
			end
		end
		if #targets == 0 and living(target) then
			targets = { target }
		end
		if #targets == 0 then
			return false
		end

		local boss = actor:FindFirstChildOfClass("Humanoid")
		local health = 1
		if boss and boss.MaxHealth > 0 then
			health = math.clamp(boss.Health / boss.MaxHealth, 0, 1)
		end

		 
		local capacity = Projectiles.Capacity(actor, "Golden")
		local maxKnives = math.min(math.clamp(math.floor(Config.P4KnifeMaxKnives or 36), 6, 48), capacity)
		local pincer = Config.P4KnifePincer ~= false
		local follow = Config.P4KnifeFollowPlayer ~= false
		local extra = pincer and 1 or 0
		local perPlayer = math.clamp(math.floor(Config.P4KnifePerPlayerCount or 6) + EXTRA_KNIVES(), 2, 10)
		perPlayer = math.max(1, math.min(perPlayer, math.floor(maxKnives / #targets) - extra))
		local total = #targets * (perPlayer + extra)
		local interval = math.max(
			0.2,
			math.clamp(Config.P4KnifePersonalInterval or 0.4, 0.25, 0.8) * INTERVAL_SCALE * (1 - 0.2 * (1 - health))
		)
		local stagger = interval / #targets
		local aim = math.clamp(Config.P4KnifeAimDuration or 1.5, 1, 2.5)
		local cue = math.max(0.1, math.clamp(Config.P4KnifeReactionCue or 0.22, 0.1, 0.4) * CUE_SCALE())
		local radius = math.clamp(Config.P4KnifeSpawnRadius or 22, 16, 30)
		local speed = math.clamp(Config.P4KnifeSpeed or DEFAULT_FLIGHT_SPEED, 120, 24000)
		local generation = actor:GetAttribute("PhaseGeneration") or 0

		local lastSpawn = (#targets - 1) * stagger + (perPlayer - 1) * interval + 0.06
		local duration = lastSpawn + RIFT_LEAD + aim + cue + 0.2
		local cast = Effects.NewCast(actor, "P4SequentialTargetingKnives", duration + 2.4)
		local result =
			{ Cast = cast, Count = total, Records = {}, Bursts = {}, Targets = #targets, Duration = duration }
		api.LastBurst = result
		active[cast] = true
		cast.OnDispose = function()
			active[cast] = nil
			for _, burst in ipairs(result.Bursts) do
				burst.Cast:Dispose()
			end
		end
		cast:Step(function()
			local bossHumanoid = actor:FindFirstChildOfClass("Humanoid")
			if
				math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) ~= 4
				or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
				or not actor.Parent
				or not bossHumanoid
				or bossHumanoid.Health <= 0
				or actor:GetAttribute("EncounterEnded")
			then
				cast:Dispose()
				return false
			end
			return true
		end)

		if core.Root then
			local aura = sparkEmitter(core.Root, WHITE, GOLD, 2, 8, 180)
			aura.Rate = 30
			aura.Acceleration = Vector3.new(0, 2, 0)
			cast:Add(aura)
			cast:Schedule(duration, function()
				aura.Rate = 0
			end)
		end

		local function onStop(record, _, hitCharacter)
			if cast.closed then
				return
			end
			local position = record.Position
			if hitCharacter then
				burstSparks(cast, position, RED, AMBER, 16, 180)
				pulse(cast, position, 2, 9, 0.22, WHITE, 0.3)
				shake(position, 14, 0.12, 0.25)
				sound(CUE_HIT, position)
			else
				burstSparks(cast, position, GOLD, AMBER, 6, 70)
				local direction = record.Direction or record.InitialDirection
				if direction then
					local ghost = cast:Add(
						core.Part(
							"P4KnifeStuck",
							CFrame.lookAt(position - direction * 0.9, position + direction),
							Vector3.new(0.45, 0.14, 1.8),
							RED,
							0.1
						)
					)
					ghost.Material = Enum.Material.Neon
					Effects:Create(
						ghost,
						TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ Transparency = 1, Size = Vector3.new(0.1, 0.05, 0.6) }
					):Play()
					cast:Schedule(0.65, function()
						Effects.Release(ghost)
					end)
				end
			end
		end

		local function launchKnife(character, angle, color, big, pitch, hunt)
			if not living(character) or Projectiles.Capacity(actor, "Golden") < 1 then
				return
			end
			local isHunter = hunt ~= nil
			if isHunter then
				local axis = moveAxis(character)
				if axis then
					local dir = hunt == "behind" and -axis or axis
					angle = math.atan2(dir.Z, dir.X)
				end
			end
			local point = spawnPoint(character.HumanoidRootPart.Position, radius, angle)
			if not point then
				return
			end
			local knifeSpot = Vector3.new(point.X, character.HumanoidRootPart.Position.Y, point.Z)

			pulse(cast, point + Vector3.new(0, 0.2, 0), 2, big and 14 or 10, 0.3, AMBER, 0.35)
			burstSparks(cast, point + Vector3.new(0, 0.6, 0), GOLD, AMBER, big and 12 or 7, 60)
			sound(CUE_SPAWN, point)
			local pad = disc(cast, point + Vector3.new(0, 0.15, 0), big and 14 or 10, color, 0.6)
			local padLease = Effects.LeaseId(pad)
			local function padAlive()
				return pad.Parent ~= nil and Effects.LeaseId(pad) == padLease
			end
			local function dropPad()
				if padAlive() then
					Effects.Release(pad)
				end
			end
			Effects:Create(
				pad,
				TweenInfo.new(RIFT_LEAD + aim, Enum.EasingStyle.Linear),
				{ Size = Vector3.new(0.1, 2.4, 2.4), Transparency = 0.35 }
			):Play()

			cast:Schedule(RIFT_LEAD, function()
				if not living(character) or Projectiles.Capacity(actor, "Golden") < 1 then
					dropPad()
					return
				end
				knifeSpot = Vector3.new(knifeSpot.X, character.HumanoidRootPart.Position.Y, knifeSpot.Z)
				local burst = Projectiles.Burst(actor, character, {
					Kind = "Golden",
					Visual = "Knife",
					Count = 1,
					SpawnPositions = { knifeSpot },
					LockedTrajectory = true,
					HorizontalAim = true,
					HomingDuration = 0,
					FollowTargetDuringAim = follow,
					PreserveAfterCue = true,
					KnifeTurnsRed = true,
					ArrowWarnings = false,
					AimDuration = aim,
					ReactionCue = cue,
					Speed = speed,
					MaxDistance = math.clamp(Config.P4KnifeRange or 180, 100, 200),
					FlightLifetime = 2,
					Damage = (Config.P4KnifeDamage or 16) * DAMAGE_SCALE,
					HitRadius = HIT_RADIUS,
					MaxHits = 1,
					NoMuzzleFlash = true,
					ShotCue = CUE_LAUNCH,
					OnStop = onStop,
     Skill = "P4TargetingKnives",
     OnHit = function(character) AttackDebuffs.Apply(actor,character,"DeathMark",8,cast) end,
					OnTravel = function(_, from, to)
						flightTrail(cast, from, to)
					end,
				})
				if not burst then
					dropPad()
					return
				end
				local record = burst.Records[1]
				record.Target = character
				local offset = record.TrackingOffset
				if offset then
					record.SpawnDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
				else
					local delta = point - character.HumanoidRootPart.Position
					record.SpawnDistance = Vector3.new(delta.X, 0, delta.Z).Magnitude
				end
				table.insert(result.Bursts, burst)
				table.insert(result.Records, record)
				actor:SetAttribute("P4KnivesSpawned", (actor:GetAttribute("P4KnivesSpawned") or 0) + 1)
				if record.Trail then
					record.Trail.Lifetime = Style.FlightTrailLifetime
					record.Trail.Color = ColorSequence.new(EMBER, RED)
				end
				burstSparks(cast, knifeSpot, GOLD, AMBER, 5, 180)

				local baseOffset = record.TrackingOffset
				local function groundBelow()
					return Vector3.new(record.Position.X, point.Y + 0.15, record.Position.Z)
				end
				local lastStep = nil
				cast:Step(function(_, now)
					if not padAlive() then
						return false
					end
					if record.Removed then
						dropPad()
						return false
					end
					local dt = lastStep and math.clamp(now - lastStep, 0, 0.1) or 0
					lastStep = now
					if baseOffset and record.State == "Aiming" then
						if isHunter and dt > 0 then
							baseOffset = steerOffset(character, baseOffset, dt)
						end
						record.TrackingOffset = baseOffset
					end
					pad.CFrame = CFrame.new(groundBelow()) * CFrame.Angles(0, 0, math.pi * 0.5)
					return true
				end)

				cast:Schedule(aim, function()
					if not padAlive() then
						return
					end
					pad.Color = RED
					pad.Transparency = 0.1
					pulse(cast, groundBelow() + Vector3.new(0, 0.1, 0), 2.5, big and 11 or 7, 0.2, WHITE, 0.3)
					sound(CUE_LOCK, record.Position, pitch)
				end)
				cast:Schedule(aim + cue, function()
					pulse(cast, groundBelow() + Vector3.new(0, 0.1, 0), 2.5, big and 20 or 13, 0.28, RED, 0.3)
					burstSparks(cast, record.Position, RED, AMBER, big and 14 or 8, 80)
					cast:Schedule(0.12, dropPad)
				end)
			end)
		end

		for playerIndex, character in ipairs(targets) do
			local order = sectorOrder(perPlayer)
			local base = random:NextNumber(0, math.pi * 2)
			local sector = math.pi * 2 / perPlayer
			for slot = 1, perPlayer do
				local jitter = slot == 1 and 0 or random:NextNumber(-0.06, 0.06)
				local at = math.max(0, (playerIndex - 1) * stagger + (slot - 1) * interval + jitter)
				local angle = base + (order[slot] - 1) * sector + random:NextNumber(-0.3, 0.3) * sector
				local final = slot == perPlayer
				local progress = perPlayer > 1 and (slot - 1) / (perPlayer - 1) or 0
				local color = GOLD:Lerp(EMBER, progress)
				local hunter = HUNTER_EVERY() > 0 and not (final and pincer) and slot % HUNTER_EVERY() == 0
				local huntSide = hunter and (math.floor(slot / HUNTER_EVERY()) % 2 == 1 and "ahead" or "behind") or nil
				cast:Schedule(at, function()
					if final and pincer then
						launchKnife(character, angle, WHITE, true, 1.5, HUNTER_EVERY() > 0 and "ahead" or nil)
						launchKnife(character, angle + math.pi, WHITE, true, 1.5, HUNTER_EVERY() > 0 and "behind" or nil)
					elseif hunter then
						launchKnife(character, angle, WHITE, true, 1.25, huntSide)
					else
						launchKnife(character, angle, color, false, 1 + progress * 0.35)
					end
				end)
			end
		end
		actor:SetAttribute("LastP4KnifeTargetCount", #targets)
		actor:SetAttribute("LastP4KnifeFacingCount", total)
		return result
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		if not living(target) then
			target = nil
			for _, c in ipairs(core.Characters()) do
				if living(c) then
					target = c
					break
				end
			end
			if not target then
				return false
			end
		end
		return core.Perform(target, "P4TargetingKnives", function()
			core.Face(target)
			core.PoseAngles({ RightShoulder = { 65, 0, -30 }, LeftShoulder = { 65, 0, 30 } }, 0.15)
			actor:SetAttribute("AttackState", "Targeting Knives: sequential yellow aims")
			local result = api.Release(target)
			if not result then
				return false
			end
			 
			return core.WaitFor(0.25)
		end)
	end
	function api.Active()
		return next(active) ~= nil
	end
	function api.Dispose()
		local pending = {}
		for cast in pairs(active) do
			table.insert(pending, cast)
		end
		for _, cast in ipairs(pending) do
			cast:Dispose()
		end
	end
	return api
end
