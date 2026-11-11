local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local ProjectileVFX = require(script.Impact)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
return function(actor)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Runtime = require(BossSystem.Combat.CombatRuntime)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Players = game:GetService("Players")
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local remote = game.ReplicatedStorage.BossCombatEffects
	local core = Registry.For(actor, "P1CombatCore")
	local api = { Cooldown = Config.P3ProjectileCooldown or 13 }
	local active = {}
	local random = Random.new()

	 
	local ACCENT = Style.ACCENT
	local WHITE = Style.WHITE
	local HOT = Style.HOT
	local DEEP = Style.DEEP
	local PANEL = Style.PANEL
	local SPARKLE = Style.SPARKLE
	local OUT = Enum.EasingDirection.Out
	local IN = Enum.EasingDirection.In
	local QUINT = Enum.EasingStyle.Quint
	local QUAD = Enum.EasingStyle.Quad
	local LINEAR = Enum.EasingStyle.Linear

	 
	local TELEGRAPH = false

	local function ownCast(name, duration)
		local cast = Effects.NewCast(actor, name, duration)
		active[cast] = true
		return cast
	end
	function api.CanUse(target)
		return math.floor(actor:GetAttribute("Phase") or 1) == 3
			and core.Active()
			and core.Alive(target)
			and require(BossSystem.Combat.AttackTargetContinuity).Player(target) ~= nil
	end
	function api.Combo(target,options)
  options=options or {}
  local fake=options.Fake==true
  local mis=Registry.For(actor,"P3Misdirection(Passive)")
  local clue=not fake and mis.CueEnabled("P3Projectile")
		if not (fake and core.Active() and core.Alive(target)) and not api.CanUse(target) then
			return false
		end
		local function perform(callback)
   if fake then return callback() end
   return core.Perform(target,"P3Projectile",callback)
  end
  return perform(function()
			local function predictImpact(seconds)
				local root = target:FindFirstChild("HumanoidRootPart")
				if not root then return nil end
				local velocity = root.AssemblyLinearVelocity
				velocity = Vector3.new(velocity.X, 0, velocity.Z)
				local humanoid = target:FindFirstChildOfClass("Humanoid")
				if velocity.Magnitude < 0.1 and humanoid then
					velocity = humanoid.MoveDirection * humanoid.WalkSpeed
				end
				local maxSpeed = Config.P3ProjectilePredictionMaxSpeed or 70
				if velocity.Magnitude > maxSpeed then velocity = velocity.Unit * maxSpeed end
				local lead = math.clamp(seconds, 0, Config.P3ProjectilePredictionMaxLead or 1.25)
				api.LastPredictionVelocity, api.LastPredictionLead = velocity, lead
				return Placement.GroundPoint(root.Position + velocity * lead, { Margin = 8, Clamp = true })
			end
			local point = predictImpact((Config.P3ProjectileWindup or 0.55) + (Config.P3ProjectileMaxTravel or 1.5))
			if not point then
				return false
			end
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local distance = (point - core.Root.Position).Magnitude

			 
			 
			local spacing = math.clamp(Config.P3ProjectileMirrorSpacing or 120, 24, 260)
			local minSeparation = math.clamp(Config.P3ProjectileMirrorMinSeparation or spacing * 0.285, 20, 260)
			local minPath = math.clamp(Config.P3ProjectileMinPathLength or 600, 100, 1400)
			local minimum = math.clamp(Config.P3ProjectileMinMirrors or 4, 3, 8)
			local maximum = math.clamp(Config.P3ProjectileMaxMirrors or 8, minimum, 10)
			local desiredPath = math.max(distance * 1.8, minPath)
			local count = math.clamp(math.floor(desiredPath / spacing + 0.5) - 1, minimum, maximum)
			local windup = math.clamp(Config.P3ProjectileWindup or 0.3, 0.2, 1.6)
			local height = math.clamp(Config.P3ProjectileMirrorHeight or 22, 12, 30)
			local radius = math.clamp(Config.P3ProjectileExplosionRadius or 30, 16, 48)
			local beamSpeed = math.clamp(Config.P3ProjectileBeamSpeed or 240, 40, 600)
			local maxTravel = math.clamp(Config.P3ProjectileMaxTravel or 1.5, 0.8, 5)

			local cast = ownCast("P3MirrorProjectile", windup + maxTravel + 3.5)
			api.LastCast = cast
   if fake then api.LastFakeCast=cast end
   cast.IsMisdirectionFake=fake
			api.LastImpactPoint = point
			api.LastMirrorCount = count
			actor:SetAttribute("P3ProjectileMirrorCount", count)
			local token = "MirrorProjectile:" .. tostring(generation) .. ":" .. tostring(cast.realBorn)
			cast.OnDispose = function()
				active[cast] = nil
			end
			local function valid()
				return cast:Alive()
					and math.floor(actor:GetAttribute("Phase") or 1) == 3
					and core.Active()
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
			end

			 
			local flatRing = Visuals.flatRing({
				cast = cast,
				core = core,
				Effects = Effects,
				QUINT = QUINT,
				OUT = OUT,
			})
			 
			local ringAlong = Visuals.ringAlong({
				cast = cast,
				core = core,
				Effects = Effects,
				QUINT = QUINT,
				OUT = OUT,
			})
			 
			local sphere = Visuals.sphere({
				cast = cast,
				core = core,
				Effects = Effects,
				QUINT = QUINT,
				OUT = OUT,
			})

			cast:Step(function()
				if not valid() then
					cast:Dispose()
					return false
				end
				return true
			end)
			if not fake then core.Face(target) end
			if not fake then core.PoseAngles({ RightShoulder = { 70, 0, -35 }, LeftShoulder = { 45, 0, 25 } }, 0.1) end
			if not fake then actor:SetAttribute("AttackState", "Projectile: summoned reflection path") end
			local origin = core.Root.Position + Vector3.new(0, 3, 0)
			local delta = point - origin
			local horizontal = Vector3.new(delta.X, 0, delta.Z)
			local direction = horizontal.Magnitude > 0.1 and horizontal.Unit or core.Root.CFrame.LookVector

			 
			 
			local points = { origin }
			local placed = { origin, point }
			local function nearestFlat(candidate)
				local nearest = math.huge
				for _, other in ipairs(placed) do
					local d = Vector3.new(candidate.X - other.X, 0, candidate.Z - other.Z).Magnitude
					if d < nearest then
						nearest = d
					end
				end
				return nearest
			end
			for index = 1, count do
				local prev = points[#points]
				local remaining = count - index + 1
				local best, bestScore
				local fallback, fallbackNearest = nil, -1
				for _ = 1, 96 do
					local angle = random:NextNumber(0, math.pi * 2)
					local length = spacing * random:NextNumber(0.9, 1.35)
					local ground = Placement.GroundPoint(
						Vector3.new(prev.X + math.cos(angle) * length, point.Y, prev.Z + math.sin(angle) * length),
						{ Margin = 8, Clamp = true }
					)
					if ground then
						local candidate = ground + Vector3.new(0, random:NextNumber(height - 6, height + 7), 0)
						local seg = (candidate - prev).Magnitude
						local toImpact = (candidate - point).Magnitude
						local nearest = nearestFlat(candidate)
						 
						if nearest > fallbackNearest then
							fallback, fallbackNearest = candidate, nearest
						end
						if nearest >= minSeparation then  
							local score = math.abs(seg - spacing)
								+ math.max(0, toImpact - spacing * 1.35 * remaining) * 0.8
							if remaining == 1 then
								score += math.abs(toImpact - spacing) * 0.8
							end
							if not bestScore or score < bestScore then
								best, bestScore = candidate, score
							end
						end
					end
				end
				best = best or fallback
				if not best then
					cast:Dispose()
					return false
				end
				points[#points + 1] = best
				placed[#placed + 1] = best
			end
			points[#points + 1] = point + Vector3.new(0, 0.4, 0)
			api.LastPoints = points

			 
			local segments = #points - 1
			local lengths, startTimes, travelTimes = {}, {}, {}
			local totalLength = 0
			for i = 1, segments do
				lengths[i] = (points[i + 1] - points[i]).Magnitude
				totalLength += lengths[i]
			end
			local speed = math.max(beamSpeed, totalLength / maxTravel)
			local clock = 0
			for i = 1, segments do
				startTimes[i] = clock
				travelTimes[i] = lengths[i] / speed
				clock += travelTimes[i]
			end
			local travelTotal = clock
			api.LastTravelTime = travelTotal
			api.LastPathLength = totalLength

			 
			if TELEGRAPH then
				local diameter = radius * 2
				local lead = windup + travelTotal
				local zone = cast:Add(
					core.Part(
						"ProjectileImpactZone",
						CFrame.new(point + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2),
						Vector3.new(0.2, diameter, diameter),
						ACCENT,
						0.82
					)
				)
				zone.Shape = Enum.PartType.Cylinder
				zone.Material = Enum.Material.Neon
				local fill = cast:Add(
					core.Part(
						"ProjectileImpactFill",
						CFrame.new(point + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.pi / 2),
						Vector3.new(0.2, 0.5, 0.5),
						WHITE,
						0.65
					)
				)
				fill.Shape = Enum.PartType.Cylinder
				fill.Material = Enum.Material.Neon
				Effects:Create(
					fill,
					TweenInfo.new(lead, QUAD, IN),
					{ Size = Vector3.new(0.2, diameter, diameter), Transparency = 0.35 }
				):Play()
				Effects.ReleaseAfter(zone, lead + 0.05)
				Effects.ReleaseAfter(fill, lead + 0.05)
			end

			 
			local normals, panels, frames, PW, PH = require(script.Mirrors).Create({
				count = count,
				points = points,
				windup = windup,
				cast = cast,
				valid = valid,
				core = core,
				PANEL = PANEL,
				Effects = Effects,
				OUT = OUT,
				ACCENT = ACCENT,
				ringAlong = ringAlong,
				DEEP = DEEP,
				HOT = HOT,
				SPARKLE = SPARKLE,
				WHITE = WHITE,
			})
			Audio.Emit(actor, "P3Snap", core.Root, { VolumeScale = 0.6 })
			if not core.WaitFor(windup) or not valid() then
				cast:Dispose()
				return false
			end
			if not fake then actor:SetAttribute("AttackState", "Projectile: reflected beam") end

			 
			for index = 1, segments do
				cast:Schedule(startTimes[index], function()
					if not valid() then
						return
					end
					local isFinal = index == segments
					if isFinal and core.Alive(target) then
						 
						point = predictImpact(travelTimes[index]) or point
						points[index + 1] = point + Vector3.new(0, 0.4, 0)
						api.LastImpactPoint = point
					end
					local a0, a1 = points[index], points[index + 1]
					local travel = math.max(travelTimes[index], 0.05)
					require(script.Beam).Draw({
						cast = cast,
						core = core,
						a0 = a0,
						ACCENT = ACCENT,
						Effects = Effects,
						travel = travel,
						LINEAR = LINEAR,
						a1 = a1,
						isFinal = isFinal,
						HOT = HOT,
						WHITE = WHITE,
						QUAD = QUAD,
						IN = IN,
						SPARKLE = SPARKLE,
						points = points,
						index = index,
						sphere = sphere,
						ringAlong = ringAlong,
						normals = normals,
						panels = panels,
					})
					
				end)
			end
			 
			cast:Schedule(travelTotal + 0.45, function()
				for index = 1, count do
					local panel, frame = panels[index], frames[index]
					if panel and panel.Parent then
						Effects:Create(
							panel,
							TweenInfo.new(0.35, QUAD, IN),
							{ Transparency = 1, Size = Vector3.new(PW + 3, PH + 3, 0.2) }
						):Play()
						local shards = Instance.new("ParticleEmitter")
						shards.Texture = SPARKLE
						shards.Rate = 0
						shards.Color = ColorSequence.new(ACCENT, WHITE)
						shards.Lifetime = NumberRange.new(0.5, 0.9)
						shards.Speed = NumberRange.new(8, 18)
						shards.SpreadAngle = Vector2.new(180, 180)
						shards.Drag = 3
						shards.LightEmission = 0.6
						shards.Size =
							NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
						shards.Parent = panel
						shards:Emit(16)
					end
					if frame and frame.Parent then
						Effects:Create(frame, TweenInfo.new(0.35), { Transparency = 1 }):Play()
					end
				end
			end)

			local function darken(character, player)
				if Status.IsDebuffImmune(character) then
					return
				end
				local duration = math.clamp(Config.P3ProjectileDarknessDuration or 18, 5, 30)
				local dark = ownCast("P3ProjectileSight", duration)
				local darkToken = token .. ":" .. tostring(player.UserId)
				if not Status.ApplyProjectileDarkness(character, duration, actor, darkToken) then dark:Dispose(); return end
				character:SetAttribute("ProjectileDarknessToken", darkToken)
				character:SetAttribute("ProjectileDarknessUntil", workspace:GetServerTimeNow() + duration)
				remote:FireClient(
					player,
					"P3ProjectileDarkness",
					{ Token = darkToken, Owner = actor, EndsAt = character:GetAttribute("ProjectileDarknessUntil") }
				)
				dark.OnDispose = function()
					active[dark] = nil
					Status.ClearProjectileDarkness(character, darkToken)
					if character.Parent and character:GetAttribute("ProjectileDarknessToken") == darkToken then
						character:SetAttribute("ProjectileDarknessToken", nil)
						character:SetAttribute("ProjectileDarknessUntil", 0)
					end
					if player.Parent == Players then
						remote:FireClient(player, "P3ProjectileDarknessEnd", { Token = darkToken })
					end
				end
				dark:Step(function()
					if
						math.floor(actor:GetAttribute("Phase") or 1) ~= 3
						or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
						or player.Character ~= character
						or Status.IsDebuffImmune(character)
						or (character:GetAttribute("ProjectileDarknessUntil") or 0) <= workspace:GetServerTimeNow()
						or not core.Alive(character)
					then
						dark:Dispose()
						return false
					end
					return true
				end)
			end

			if clue then
    cast:Schedule(math.max(0,travelTotal-(Config.P3MisdirectionClueLead or .25)),function()
     if valid() then mis.Cue(core,panels[#panels],points[#points-1]);actor:SetAttribute("MisdirectionRealClueAt",workspace:GetServerTimeNow()) end
    end)
   end
   if fake then
    cast:Schedule(math.max(0,travelTotal-.02),function()cast:Dispose();actor:SetAttribute("MisdirectionFakeVanishedAt",workspace:GetServerTimeNow())end)
   end
    
			cast:Schedule(travelTotal, function()
				if not valid() then
					return
				end
				if fake then cast:Dispose();return end
    local blastCenter = point + Vector3.new(0, radius * 0.35, 0)
				ProjectileVFX.Explode(core, cast, point, radius)

				Audio.Emit(actor, "GroundErupt", point, { VolumeScale = 0.8 })
				 
				for _, character in ipairs(core.Characters()) do
					local r = character:FindFirstChild("HumanoidRootPart")
					local player = Players:GetPlayerFromCharacter(character)
					if r and player and player.Character == character then
						local away = (r.Position - point).Magnitude
						if away <= radius * 3 then
							remote:FireClient(
								player,
								"P3ProjectileImpact",
								{ Intensity = math.clamp(1.2 - away / (radius * 3), 0.2, 1) }
							)
						end
					end
				end
				actor:SetAttribute("P3ProjectileBaseDamage", Config.P3ProjectileDamage or 35)
				local hitCount = 0
				for _, character in ipairs(core.Characters()) do
					local r = character:FindFirstChild("HumanoidRootPart")
					local player = Players:GetPlayerFromCharacter(character)
					 
					if
						r
						and player
						and player.Character == character
						and core.Alive(character)
						and (r.Position - blastCenter).Magnitude <= radius
					then
						local dealt = core.Damage(character, Config.P3ProjectileDamage or 35, "P3Projectile")
						if dealt > 0 then
							hitCount += 1
							darken(character, player)
							if not r.Anchored and not Status.IsStunProtected(character) then
								local push = Vector3.new(r.Position.X - point.X, 0, r.Position.Z - point.Z)
								push = push.Magnitude > 0.1 and push.Unit or direction
								local b = Placement.GetBounds()
								local pushSpeed = math.clamp(Config.P3ProjectileKnockback or 176, 20, 220)
								if b then
									local p = b.Frame:PointToObjectSpace(r.Position)
									local d = b.Frame:VectorToObjectSpace(push)
									local edgeX = (b.HalfX - 8 - math.abs(p.X)) / math.max(math.abs(d.X), 0.001)
									local edgeZ = (b.HalfZ - 8 - math.abs(p.Z)) / math.max(math.abs(d.Z), 0.001)
									pushSpeed = math.min(pushSpeed, math.max(0, math.min(edgeX, edgeZ)) / 0.8)
								end
								Runtime.Knockback(
									actor,
									character,
									push,
									{ Speed = pushSpeed, Lift = 35, Duration = 0.65, Sustain = 0.3, ContainsArena = true }
								)
							end
						end
					end
				end
				actor:SetAttribute("P3ProjectileHitPlayerCount", hitCount)
				actor:SetAttribute("P3ProjectileImpactAt", workspace:GetServerTimeNow())
			end)
			return core.WaitFor(travelTotal + 0.15)
		end)
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
