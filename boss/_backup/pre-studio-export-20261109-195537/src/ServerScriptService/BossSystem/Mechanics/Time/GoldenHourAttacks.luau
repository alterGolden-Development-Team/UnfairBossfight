local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Effects = require(BossSystem.Combat.EffectService)
local Registry = require(BossSystem.Combat.AttackRegistry)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local Status = require(BossSystem.Combat.StatusEffectService)
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Audio = require(BossSystem.Presentation.CombatAudio)
local VFX = require(BossSystem.Mechanics.Time.GoldenHourVFX)
local random = Random.new()
local owners = setmetatable({}, { __mode = "k" })
local GOLD, WHITE = VFX.GOLD, VFX.WHITE
local api = {}

local function frozenGlints(parent, label, count)
	 
	 
	return VFX.Emitter(parent, {
		Name = label,
		Count = count,
		Life = NumberRange.new(0.4, 0.8),
		Speed = NumberRange.new(0.5, 1.2),
		Size0 = 0.22,
		Size1 = 0,
		Fade0 = 0.15,
	})
end

local function segmentDistance(point, a, b)
	local delta = b - a
	local t = delta:Dot(delta) > 0.001 and math.clamp((point - a):Dot(delta) / delta:Dot(delta), 0, 1) or 0
	return (point - a - delta * t).Magnitude
end

local function formationFor(actor, stop, target)
	if stop.GoldenFormation then
		return stop.GoldenFormation
	end
	local ground = Placement.GroundPoint(target, { Clamp = true, Margin = 5 })
	if not ground then
		return nil
	end
	local bounds = Placement.GetBounds()
	if not bounds then
		return nil
	end
	local formation = {
		Frame = CFrame.new(ground) * bounds.Frame.Rotation,
		Bounds = bounds,
		Ordinal = 0,
		Kinds = {},
		KindCount = 0,
		SeedAngle = random:NextNumber(0, math.pi * 2),
		Reserved = {},
		ProjectileBursts = {},
		Missiles = {},
		Mines = {},
		Slashes = {},
	}
	stop.GoldenFormation = formation
	 
	 
	 
	actor:SetAttribute("GoldenHourSafeFrame", nil)
	actor:SetAttribute("GoldenHourSafeWidth", nil)
	actor:SetAttribute("GoldenHourFormationVersion", "Dispersed")
	actor:SetAttribute("GoldenHourPreparedKindCount", 0)
	actor:SetAttribute("GoldenHourPreparedObjectCount", 0)
	return formation
end

function api.Factory(actor, name)
	local core = Registry.For(actor, "P1CombatCore")
	local skill = {}

	function skill.CanUse(character)
		local metadata = Metadata.Get(name)
		return metadata
			and metadata.TimeStopOnly
			and not actor:GetAttribute("IsGoldenClone")
			and core.Active()
			and core.Alive(character)
			and Time.IsGoldenHour(actor)
			and (owners[actor] or 0) < Config.GoldenHourMaxPreparedCasts
	end

	function skill.Combo(character)
		 
		 
		if not skill.CanUse(character) then
			return false
		end
		local generation = actor:GetAttribute("PhaseGeneration") or 0
		local target = character.HumanoidRootPart.Position
		local cast = Effects.NewCast(actor, name, 6)
		local stop = Time.ActiveStop(actor)
		local formation = formationFor(actor, stop, target)
		if not formation then
			cast:Dispose()
			return false
		end
		formation.Ordinal += 1
		local ordinal = formation.Ordinal
		if not formation.Kinds[name] then
			formation.Kinds[name] = true
			formation.KindCount += 1
			actor:SetAttribute("GoldenHourPreparedKindCount", formation.KindCount)
		end
		local subscription
		local childCasts = {}
		local stunTokens = {}
		owners[actor] = (owners[actor] or 0) + 1
		actor:SetAttribute("GoldenHourPrepared", owners[actor])
		cast.OnDispose = function()
			if subscription then
				subscription:Disconnect()
				subscription = nil
			end
			for stunned, token in pairs(stunTokens) do
				Status.ReleaseRestraint(stunned, token)
			end
			table.clear(stunTokens)
			owners[actor] = math.max(0, (owners[actor] or 0) - 1)
			if actor.Parent then
				actor:SetAttribute("GoldenHourPrepared", owners[actor])
			end
		end
		subscription = stop:OnFinished(function(reason)
			if reason ~= "completed" then
				for _, child in ipairs(childCasts) do
					child:Dispose()
				end
				cast:Dispose()
			end
		end)

		local function piece(label, frame, size, color, alpha)
			return cast:Add(core.Part(label, frame, size, color or GOLD, alpha or 0.08))
		end
		local function safeGround(position)
			return Placement.GroundPoint(position, { Margin = 9, Clamp = true })
		end
		local function threatGround(kind, index, count, minGap)
			local reserved = formation.Reserved[kind]
			if not reserved then
				reserved = {}
				formation.Reserved[kind] = reserved
			end
			for attempt = 0, 17 do
				local angle = index * 2.399963 + ordinal * 1.113 + attempt * 0.71 + formation.SeedAngle
				local radius = 12 + ((index * 11 + ordinal * 7 + attempt * 5) % 64)
				local desired
				if (index + ordinal + attempt) % 3 ~= 0 then
					desired = formation.Frame:PointToWorldSpace(
						Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
					)
				else
					local bounds = formation.Bounds
					desired = bounds.Frame:PointToWorldSpace(
						Vector3.new(
							math.sin(angle * 1.7) * math.max(0, bounds.HalfX - 18) * 0.85,
							0,
							math.cos(angle * 1.3) * math.max(0, bounds.HalfZ - 18) * 0.85
						)
					)
				end
				local point = safeGround(desired)
				if point then
					local separated = true
					for _, previous in ipairs(reserved) do
						if
							(Vector3.new(point.X, 0, point.Z) - Vector3.new(previous.X, 0, previous.Z)).Magnitude
							< minGap
						then
							separated = false
							break
						end
					end
					if separated then
						reserved[#reserved + 1] = point
						return point
					end
				end
			end
		end

		 
		local function buildPortal(origin, delay)
			local frame = CFrame.lookAt(origin, target)
			local part = piece("FrozenGoldenPortal", frame, Vector3.one * 0.1, GOLD, 1)
			local records = {}
			VFX.Circle(
				part,
				3.6,
				18,
				{ Plane = "XY", Label = "PortalRim", Width = 0.22, Color = GOLD, Alpha = 0.1, Collect = records }
			)
			VFX.Circle(
				part,
				2.9,
				18,
				{ Plane = "XY", Label = "PortalRimInner", Width = 0.1, Color = WHITE, Alpha = 0.35, Collect = records }
			)
			VFX.Cog(
				part,
				1.7,
				2.4,
				6,
				{ Plane = "XY", Label = "PortalCog", Width = 0.18, Color = WHITE, Alpha = 0.15, Collect = records }
			)
			part:SetAttribute("TemporalState", "Suspended")
			frozenGlints(part, "SuspendedPortalShards", 6)
			return { Part = part, Frame = frame, Delay = delay, Records = records, Position = origin }
		end

		local missiles, marks, mines, portals = {}, {}, {}, {}
		local spawnedProjectiles = 0
		local isBlade = name == "ClockBlades"
		local count = isBlade and (Config.ClockBladeCount or 6)
			or name == "FrozenGoldenLances" and (Config.ClockLanceCount or 8)
			or 0

		 
		for index = 1, count do
			local start, aim, landing
			if isBlade then
				local point = threatGround("Blade", index, count, 9)
				if not point then
					continue
				end
				start = point + Vector3.new(0, 48 + (index % 4) * 10 + (ordinal % 3) * 5, 0)
				aim = point
				landing = piece(
					"FrozenClockBladeLanding",
					CFrame.new(point + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
					Vector3.new(0.12, 2, 2),
					GOLD,
					0.66
				)
				landing.Shape = Enum.PartType.Cylinder
				landing.Material = Enum.Material.Neon
				landing:SetAttribute("TemporalState", "Suspended")
				 
				VFX.Circle(
					landing,
					4.5,
					14,
					{
						Plane = "YZ",
						Height = 0.08,
						Label = "BladeLandingRing",
						Width = 0.16,
						Color = GOLD,
						Alpha = 0.15,
					}
				)
				VFX.Spokes(landing, 4, 3.2, 5.8, {
					Plane = "YZ",
					Height = 0.08,
					Label = "BladeLandingTick",
					Width = 0.2,
					Color = WHITE,
					Alpha = 0.2,
					Offset = math.pi / 4,
				})
			else
				local point = threatGround("Lance", index, count, 8)
				if not point then
					continue
				end
				start = point + Vector3.new(0, 3.2 + (index % 3) * 6, 0)
				local angle = (index + ordinal) * 2.399963
				aim = target + Vector3.new(math.cos(angle) * 5, 0.2, math.sin(angle) * 5)
			end
			local direction = (aim - start).Unit
			local frame = CFrame.lookAt(start, start + direction)
			local shaft = piece(name .. "Shaft", frame, Vector3.new(0.42, 0.42, 15), GOLD, 0.22)
			local releaseDelay = Config.TimeResumeGrace + 0.08 * index + (ordinal % 4) * 0.1
			shaft:SetAttribute("TemporalState", "Suspended")
			shaft:SetAttribute("TemporalReleaseDelay", releaseDelay)
			local head = piece(name .. "Point", frame * CFrame.new(0, 0, -9), Vector3.new(1.8, 0.65, 3.5), WHITE, 0.34)
			local headMesh = Instance.new("SpecialMesh")
			headMesh.MeshType = Enum.MeshType.Wedge
			headMesh.Parent = head
			 
			VFX.Ribbon(
				shaft,
				{ Vector3.new(0, 0, 7.8), Vector3.new(0, 0, -7.8) },
				false,
				{ Label = name .. "BladeCore", Width = 0.16, Color = WHITE, Alpha = 0.08 }
			)
			local guardWidth = isBlade and 2 or 0.5
			VFX.Ribbon(
				shaft,
				{ Vector3.new(-guardWidth, 0, 5.8), Vector3.new(guardWidth, 0, 5.8) },
				false,
				{ Label = name .. "Guard", Width = 0.6, Color = GOLD, Alpha = 0.08 }
			)

			local guides = {}
			if isBlade then
				 
				VFX.Ribbon(shaft, {
					Vector3.new(0, 0, -10.6),
					Vector3.new(0.95, 0, -6.8),
					Vector3.new(0.5, 0, 4.8),
					Vector3.new(0, 0, 5.6),
					Vector3.new(-0.5, 0, 4.8),
					Vector3.new(-0.95, 0, -6.8),
				}, true, { Label = name .. "Edge", Width = 0.14, Color = WHITE, Alpha = 0.05 })
				local tip = Instance.new("Attachment")
				tip.Name = "BladeTip"
				tip.Position = Vector3.new(0, 0, -10.6)
				tip.Parent = shaft
				local mark = Instance.new("Attachment")
				mark.Name = "BladeMark"
				mark.Parent = landing
				VFX.Link(
					tip,
					mark,
					{ Label = "BladeFallLine", Width0 = 0.05, Width1 = 0.45, Color = WHITE, Alpha = 0.5, Alpha1 = 0.85 }
				)
			else
				 
				for ring = 1, 2 do
					VFX.Circle(shaft, 1.5 + ring * 0.8, 8, {
						Plane = "XY",
						Height = -12 - ring * 4.5,
						Label = "LanceRing",
						Width = 0.16,
						Color = GOLD,
						Alpha = 0.15,
					})
				end
				guides = VFX.Ribbon(
					shaft,
					{ Vector3.new(0, 0, -11), Vector3.new(0, 0, -75) },
					false,
					{ Label = "LanceAimLine", Width0 = 0.35, Width1 = 0.05, Color = WHITE, Alpha = 0.3, Alpha1 = 0.95 }
				)
			end
			local trail = VFX.Trail(shaft, 6.8, isBlade and 0.8 or 0.5, isBlade and 0.3 or 0.22)

			table.insert(missiles, {
				Parts = { shaft, head },
				Offsets = { CFrame.identity, CFrame.new(0, 0, -9) },
				Position = start,
				Direction = direction,
				Speed = isBlade and 118 or 235,
				Age = 0,
				Landing = landing,
				Delay = releaseDelay,
				Trail = trail,
				Guides = guides,
				LaunchBurst = not isBlade,
				Damage = isBlade and Config.GoldenHourBladeDamage or Config.GoldenHourLanceDamage,
				Hit = {},
			})
			formation.Missiles[#formation.Missiles + 1] = missiles[#missiles]
		end

		if name == "FrozenGoldenBullets" then
			local Projectiles = require(BossSystem.Combat.ProjectileService)
			local total = Config.GoldenHourGoldenBulletsPerVolley or 48
			for index = 1, 3 do
				local point = threatGround("BulletOrigin", index, 3, 16)
				if not point then
					for _, child in ipairs(childCasts) do
						child:Dispose()
					end
					cast:Dispose()
					return false
				end
				local origin = point + Vector3.new(0, 4 + (index - 1) * 5 + (ordinal % 3) * 3, 0)
				local burstCount = math.floor(total / 3) + (index <= total % 3 and 1 or 0)
				local launchDelay = Config.TimeResumeGrace + 0.14 * index + (ordinal % 4) * 0.2
				local burst = Projectiles.Burst(actor, character, {
					Kind = "Golden",
					Count = burstCount,
					Origin = origin,
					Damage = Config.GoldenHourBulletDamage,
					PreparedAim = target,
					SpawnRadius = 5,
					SpawnHeightSpread = 6,
					HomingDuration = Config.GoldenHourHomingDuration or 5.5,
					HomingTurnRate = Config.GoldenHourHomingTurnRate or 1.8,
					NoMuzzleFlash = true,
					LaunchDelay = launchDelay,
				})
				if burst then
					table.insert(childCasts, burst.Cast)
					spawnedProjectiles += burst.Count
					formation.ProjectileBursts[#formation.ProjectileBursts + 1] = burst
					portals[#portals + 1] = buildPortal(origin, launchDelay)
				end
			end
			local delayed = Projectiles.Burst(actor, character, {
				Kind = "Time",
				Count = Config.GoldenHourTimeBulletsPerVolley or 2,
				Origin = core.Root.Position + Vector3.new(0, 3, 0),
				PreparedAim = target,
				Damage = Config.TimeBulletDamage,
				LaunchDelay = Config.TimeResumeGrace + 0.7 + (ordinal % 4) * 0.12,
			})
			if delayed then
				table.insert(childCasts, delayed.Cast)
				spawnedProjectiles += delayed.Count
				formation.ProjectileBursts[#formation.ProjectileBursts + 1] = delayed
			end
		elseif name == "TemporalSlashMarks" then
			for index = 1, (Config.ClockSlashCount or 4) do
				local ground = threatGround("Slash", index, Config.ClockSlashCount or 4, 11)
				if not ground then
					continue
				end
				local angle = ((index + ordinal) % 4) * math.pi * 0.25
					+ (ordinal % 3) * 0.07
					+ formation.SeedAngle * 0.08
				local frame = CFrame.new(ground + Vector3.new(0, 0.12, 0))
					* formation.Frame.Rotation
					* CFrame.Angles(0, angle, 0)
				local marker = piece("DormantTemporalSlashMark", frame, Vector3.new(7, 0.1, 90), GOLD, 0.78)
				local coreLine = piece(
					"TemporalSlashMarkCore",
					frame + Vector3.new(0, 0.1, 0),
					Vector3.new(0.25, 0.12, 90),
					WHITE,
					0.08
				)
				marker:SetAttribute("TemporalState", "Suspended")
				local releaseDelay = Config.TimeResumeGrace + 0.22 + index * 0.2 + (ordinal % 4) * 0.2
				marker:SetAttribute("TemporalReleaseDelay", releaseDelay)
				local strands = VFX.Ribbon(marker, {
					Vector3.new(-5, 0.2, -46),
					Vector3.new(5, 0.2, -46),
					Vector3.new(5, 0.2, 46),
					Vector3.new(-5, 0.2, 46),
				}, true, { Label = "FrozenSlashOutline", Width = 0.16, Color = GOLD, Alpha = 0.08 })
				local fracture = VFX.Ribbon(marker, {
					Vector3.new(0, 0.65, -45),
					Vector3.new(-1.6, 1.9, -30),
					Vector3.new(1.4, 0.8, -15),
					Vector3.new(-1.4, 2.3, 0),
					Vector3.new(1.6, 1, 15),
					Vector3.new(-1.2, 1.8, 30),
					Vector3.new(0, 0.65, 45),
				}, false, { Label = "FrozenSlashFracture", Width = 0.3, Color = WHITE, Alpha = 0.08 })
				 
				local gate = VFX.Ribbon(marker, {
					Vector3.new(0, 0.3, -46),
					Vector3.new(0, 12.3, -46),
					Vector3.new(0, 12.3, 46),
					Vector3.new(0, 0.3, 46),
				}, true, { Label = "FrozenSlashGate", Width = 0.18, Color = WHITE, Alpha = 0.3 })
				for _, list in ipairs({ fracture, gate }) do
					for _, strand in ipairs(list) do
						strands[#strands + 1] = strand
					end
				end
				frozenGlints(marker, "SuspendedTemporalShards", 8)
				table.insert(marks, {
					Frame = frame,
					Marker = marker,
					Core = coreLine,
					Strands = strands,
					Delay = releaseDelay,
					Hit = {},
				})
				formation.Slashes[#formation.Slashes + 1] = marks[#marks]
			end
		elseif name == "TimeMines" then
			for index = 1, (Config.ClockMineCount or 8) do
				local ground = threatGround("Mine", index, Config.ClockMineCount or 8, 14)
				if not ground then
					continue
				end
				local marker = piece(
					"DormantTimeMine",
					CFrame.new(ground + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2),
					Vector3.new(0.16, 16, 16),
					GOLD,
					0.74
				)
				marker.Shape = Enum.PartType.Cylinder
				local orb = piece(
					"TimeMineClockCore",
					CFrame.new(ground + Vector3.new(0, 3, 0)),
					Vector3.one * 1.2,
					WHITE,
					0.12
				)
				orb.Shape = Enum.PartType.Ball
				orb.Material = Enum.Material.Neon
				marker:SetAttribute("TemporalState", "Suspended")
				local releaseDelay = Config.TimeResumeGrace + 1.15 + index * 0.24 + (ordinal % 4) * 0.22
				marker:SetAttribute("TemporalReleaseDelay", releaseDelay)
				 
				VFX.Circle(marker, 10, 14, {
					Plane = "YZ",
					Height = 0.2,
					Label = "FrozenTimeMineBoundary",
					Width = 0.2,
					Color = GOLD,
					Alpha = 0.08,
				})
				VFX.Spokes(
					marker,
					4,
					8.4,
					11,
					{
						Plane = "YZ",
						Height = 0.2,
						Label = "FrozenTimeMineTick",
						Width = 0.35,
						Color = WHITE,
						Alpha = 0.2,
					}
				)
				 
				VFX.Ribbon(orb, {
					Vector3.new(-1.5, 1.7, 0),
					Vector3.new(1.5, 1.7, 0),
					Vector3.new(-1.5, -1.7, 0),
					Vector3.new(1.5, -1.7, 0),
					Vector3.new(-1.5, 1.7, 0),
				}, false, { Label = "SuspendedTimeMineHourglass", Width = 0.26, Color = WHITE, Alpha = 0.08 })
				VFX.Circle(orb, 2.6, 8, { Label = "SuspendedTimeMineHalo", Width = 0.16, Color = GOLD, Alpha = 0.2 })
				frozenGlints(orb, "SuspendedTimeMineShards", 6)
				table.insert(mines, { Position = ground, Marker = marker, Core = orb, Delay = releaseDelay })
				formation.Mines[#formation.Mines + 1] = mines[#mines]
			end
		end

		local started = cast:Now()
		cast:Step(function(dt, now)
			if
				(actor:GetAttribute("PhaseGeneration") or 0) ~= generation
				or actor:GetAttribute("PhaseTransitionInProgress")
			then
				cast:Dispose()
				return false
			end
			local elapsed = now - started

			 
			for _, record in ipairs(missiles) do
				if record.Done then
					continue
				end
				if not record.Resumed then
					record.Resumed = true
					record.Parts[1]:SetAttribute("TemporalState", "Arming")
				end
				if elapsed < record.Delay then
					 
					if record.Landing then
						local progress = math.clamp(elapsed / record.Delay, 0, 1)
						if progress ~= record.Progress then
							record.Progress = progress
							local diameter = 2 + 7 * progress
							record.Landing.Size = Vector3.new(0.12, diameter, diameter)
							record.Landing.Transparency = 0.66
								- 0.24 * progress
								- 0.08 * progress * math.sin(elapsed * (14 + 30 * progress))
						end
					end
					continue
				end
				if not record.Released then
					record.Released = true
					record.Parts[1]:SetAttribute("TemporalState", "Released")
					record.Trail.Enabled = true
					for _, beam in ipairs(record.Guides) do
						beam.Enabled = false
					end
					if record.LaunchBurst then
						VFX.Sparks(piece, record.Position, 0.6)
					end
					Audio.Emit(actor, "SwordSlash", record.Position)
				end
				record.Age += dt
				local from = record.Position
				local travel = record.Direction * record.Speed * math.min(dt, 0.1)
				local collision = workspace:Spherecast(from, 0.65, travel, core.Params())
				local to = collision and collision.Position or from + travel
				local hit = false
				for _, char in ipairs(core.Characters()) do
					if
						core.Alive(char)
						and not record.Hit[char]
						and segmentDistance(char.HumanoidRootPart.Position, from, to) <= 3.6
					then
						record.Hit[char] = true
						if core.Damage(char, record.Damage,name)>0 then
       if name=="ClockBlades" then AttackDebuffs.Apply(actor,char,"Bleed",3,cast)
       elseif name=="FrozenGoldenLances" and not char:GetAttribute("TimeFrozen") then AttackDebuffs.Apply(actor,char,"JumpLock",1,cast) end
      end
						hit = true
					end
				end
				record.Position = to
				local frame = CFrame.lookAt(to, to + record.Direction)
				for index, p in ipairs(record.Parts) do
					p.CFrame = frame * record.Offsets[index]
				end
				if hit or collision or record.Age > 2.7 then
					record.Done = true
					record.Trail.Enabled = false
					VFX.Impact(piece, to, 8, 1)
					for _, p in ipairs(record.Parts) do
						Effects.Release(p)
					end
					if record.Landing then
						Effects.Release(record.Landing)
						record.Landing = nil
					end
				end
			end

			 
			for _, record in ipairs(marks) do
				if record.Done then
					local alpha = math.clamp((now - record.FadeAt) / 0.3, 0, 1)
					if alpha ~= record.FadeAlpha then
						record.FadeAlpha = alpha
						local transparency = NumberSequence.new(0.08 + 0.92 * alpha)
						for _, strand in ipairs(record.Strands) do
							strand.Transparency = transparency
						end
					end
					continue
				end
				if not record.Resumed then
					record.Resumed = true
					record.Marker:SetAttribute("TemporalState", "Arming")
				end
				if elapsed < record.Delay then
					local progress = math.clamp(elapsed / record.Delay, 0, 1)
					if progress ~= record.Progress then
						record.Progress = progress
						record.Marker.Transparency = 0.78
							- 0.3 * progress
							- 0.1 * progress * math.sin(elapsed * (12 + 40 * progress))
					end
					continue
				end
				record.Done = true
				record.Marker:SetAttribute("TemporalState", "Released")
				record.FadeAt = now
				Audio.Emit(actor, "SwordSlash", record.Marker.Position)
				 
				local flash =
					piece("GoldenSlashFlash", record.Frame * CFrame.new(0, 5, 0), Vector3.new(1.2, 14, 90), WHITE, 0.1)
				flash.Material = Enum.Material.Neon
				VFX.Emitter(flash, {
					Name = "SlashSparks",
					Count = 70,
					Speed = NumberRange.new(10, 28),
					Life = NumberRange.new(0.3, 0.8),
					Size0 = 0.6,
					Acceleration = Vector3.new(0, -45, 0),
					Spread = Vector2.new(35, 35),
				})
				Effects:Create(
					flash,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = Vector3.new(10, 14, 90), Transparency = 1 }
				):Play()
				Effects.ReleaseAfter(flash, 0.4)
				for _, char in ipairs(core.Characters()) do
					if core.Alive(char) then
						local p = record.Frame:PointToObjectSpace(char.HumanoidRootPart.Position)
						if math.abs(p.X) <= 5 and math.abs(p.Z) <= 46 and p.Y >= -2 and p.Y <= 12 then
							if core.Damage(char, Config.GoldenHourSlashDamage,name)>0 then AttackDebuffs.Apply(actor,char,"TemporalWound",5,cast) end
						end
					end
				end
				Effects:Create(record.Marker, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				Effects:Create(record.Core, TweenInfo.new(0.3), { Transparency = 1 }):Play()
			end

			 
			for _, record in ipairs(mines) do
				if record.Done then
					continue
				end
				if not record.Resumed then
					record.Resumed = true
					record.Marker:SetAttribute("TemporalState", "Arming")
				end
				if elapsed < record.Delay then
					 
					local progress = math.clamp(elapsed / record.Delay, 0, 1)
					if progress ~= record.Progress then
						record.Progress = progress
						local spinAngle = elapsed * 4 + elapsed * elapsed * 6
						record.Core.Size = Vector3.one * (1.2 + 1.1 * progress * progress)
						record.Core.CFrame = CFrame.new(record.Position + Vector3.new(0, 3, 0))
							* CFrame.Angles(0, spinAngle, 0)
						record.Marker.Transparency = 0.74
							- 0.24 * progress
							- 0.08 * progress * math.sin(elapsed * (12 + 30 * progress))
					end
					continue
				end
				record.Done = true
				VFX.Impact(piece, record.Position + Vector3.new(0, 0.5, 0), 11, 1.4)
				VFX.Pillar(piece, record.Position, 38, 3.2, 0.45)
				Effects.Release(record.Marker)
				Effects.Release(record.Core)
				for _, char in ipairs(core.Characters()) do
					if core.Alive(char) and (char.HumanoidRootPart.Position - record.Position).Magnitude <= 10 then
						local applied = core.Damage(char, Config.GoldenHourMineDamage,name)
      if applied>0 then AttackDebuffs.Apply(actor,char,"CooldownFreeze",1.5,cast) end
						if
							applied > 0
							and Status.ApplyStun(
								char,
								record,
								Config.GoldenHourMineStunDuration or 1,
								Config.GoldenHourMineRestunGrace or 0.9,
								{ AllowDefense = true, Family = "ChainStun" }
							)
						then
							stunTokens[char] = record
							actor:SetAttribute(
								"GoldenHourMineStuns",
								(actor:GetAttribute("GoldenHourMineStuns") or 0) + 1
							)
						end
					end
				end
			end

			 
			for _, record in ipairs(portals) do
				if record.Done then
					continue
				end
				if elapsed < record.Delay then
					 
					local roll = elapsed * (3 + 10 * math.clamp(elapsed / record.Delay, 0, 1))
					if roll ~= record.Roll then
						record.Roll = roll
						record.Part.CFrame = record.Frame * CFrame.Angles(0, 0, roll)
					end
					continue
				end
				if not record.Fired then
					record.Fired = true
					record.Part:SetAttribute("TemporalState", "Released")
					VFX.Flash(piece, record.Position, 4)
					VFX.Sparks(piece, record.Position, 0.8)
				end
				local fade = math.clamp((elapsed - record.Delay) / 0.3, 0, 1)
				VFX.ApplyOpacity(record.Records, 1 - fade)
				if fade >= 1 then
					record.Done = true
					Effects.Release(record.Part)
				end
			end
			return true
		end)

		actor:SetAttribute("LastGoldenHourAttack", name)
		actor:SetAttribute("GoldenHourSetupCount", (actor:GetAttribute("GoldenHourSetupCount") or 0) + 1)
		actor:SetAttribute(
			"GoldenHourPreparedObjectCount",
			(actor:GetAttribute("GoldenHourPreparedObjectCount") or 0)
				+ #missiles
				+ #marks
				+ #mines
				+ spawnedProjectiles
		)
		return true
	end

	return skill
end

return api
