local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local TweenService = game:GetService("TweenService")

return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Status = require(BossSystem.Combat.StatusEffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Encounter = require(BossSystem.Players.PlayerEncounter)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local core = Registry.For(actor, "P1CombatCore")
	local api = {
		Damage = 12,
		Radius = 8,
		TrackingTime = Config.GroundChainsTrackingTime or 3.5,
		LockWarningTime = Config.GroundChainsLockWarningTime or 0.5,
		RestraintDuration = math.max(0.1, Config.GroundChainsRestraintDuration or 3),
	}
	api.WarningTime = api.TrackingTime + api.LockWarningTime
	local GOLD, BRIGHT = Style.GOLD, Style.BRIGHT
	local WHITE = Style.WHITE
	local HALF_PI, TAU = math.pi * 0.5, math.pi * 2
	local LINKS = 7  
	local random = Random.new()
	local CYLINDER = Enum.PartType.Cylinder

	local tweenOut = Visuals.tweenOut({})
	 
	local fxPart = Visuals.fxPart({
		core = core,
	})
	local flat = Visuals.flat({
		HALF_PI = HALF_PI,
	})
	local bend = Visuals.bend({})

	function api.Mark(position, trackedCharacter, options)
		options = options or {}
		local radius = options.Radius or api.Radius
		local trackingTime = math.max(0, options.TrackingTime or api.TrackingTime)
		local lockWarningTime = math.max(0, options.LockWarningTime or api.LockWarningTime)
		local warningTime = trackingTime + lockWarningTime
		local restraintDuration =
			math.clamp(options.RestraintDuration or api.RestraintDuration, 0.1, api.RestraintDuration)
		local damage = options.Damage == nil and api.Damage or options.Damage
		local ground = Placement.GroundPoint(position, { Margin = radius + 1, Clamp = true })
		if not ground then
			return nil
		end
		local cast =
			Effects.NewCast(actor, options.CastName or "GroundChainsTarget", warningTime + restraintDuration + 0.45)
		local owner = cast.owner
		local generation = owner:GetAttribute("PhaseGeneration") or 0
		local revision = owner:GetAttribute("MovementRevision") or 0
		local hideWarning = options.HideWarning == true
		local anchor = cast:Add(core.Part("GroundChainsAnchor", CFrame.new(ground), Vector3.one * 0.1, GOLD, 1))
		 
		 
		local marker = anchor
		if not hideWarning then
			marker = cast:Add(
				core.Part(
					"GroundChainsWarning",
					CFrame.new(ground + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
					Vector3.new(0.17, radius * 2, radius * 2),
					GOLD,
					0.46
				)
			)
			marker.Shape = Enum.PartType.Cylinder
		end
		Audio.Emit(actor, "GroundWarning", ground)
		local chains, members = {}, {}
		for index = 1, 4 do
			local first, last = Instance.new("Attachment"), Instance.new("Attachment")
			first.Parent, last.Parent = anchor, anchor
			local angle = index * math.pi * 0.5
			first.Position = Vector3.new(math.cos(angle) * radius * 0.65, 0.1, math.sin(angle) * radius * 0.65)
			last.Position = first.Position
			local beam = Instance.new("Beam")
			beam.Name = "GoldenGroundChain"
			beam.Attachment0 = first
			beam.Attachment1 = last
			beam.Width0, beam.Width1 = 0.38, 0.38
			beam.LightEmission = 1
			beam.FaceCamera = true
			beam.Color = ColorSequence.new(GOLD, BRIGHT)
			beam.Transparency = NumberSequence.new(0.12)
			beam.CurveSize0, beam.CurveSize1 = 1.5, -1.5
			beam.Segments = 6
			beam.Enabled = options.PreparingChains == true
			beam.Parent = anchor
			table.insert(chains, { Beam = beam, First = first, Last = last })
		end
		local function release()
			if next(members) then
				Audio.Emit(actor, "GroundBreak", anchor)
			end
			for character in pairs(members) do
				Status.ReleaseRestraint(character, cast)
			end
			table.clear(members)
		end
		cast.OnExpire, cast.OnDispose = release, release
		local record = {
			Cast = cast,
			Position = ground,
			Radius = radius,
			TrackingTime = trackingTime,
			WarningTime = warningTime,
			RestraintDuration = restraintDuration,
			Locked = false,
			TargetingMode = options.TargetingMode,
			Marker = not hideWarning and marker or nil,
			HideWarning = hideWarning,
		}
		if options.TargetingMode then
			marker:SetAttribute("TargetingMode", options.TargetingMode)
		end
		local elapsed, erupted, locked = 0, false, false
		local nativeSuppressed = false
		local visualHold = restraintDuration

		 
		local rim, fill, bars, sockets, spikes = nil, nil, {}, {}, {}
		local decorDone = false
		if not hideWarning then
			rim = fxPart(
				cast,
				"GoldenChainsRim",
				flat(ground + Vector3.new(0, 0.1, 0)),
				Vector3.new(0.13, radius * 2 + 1.6, radius * 2 + 1.6),
				BRIGHT,
				0.4,
				CYLINDER
			)
			fill = fxPart(
				cast,
				"GoldenChainsFill",
				flat(ground + Vector3.new(0, 0.16, 0)),
				Vector3.new(0.19, 0.5, 0.5),
				BRIGHT,
				0.6,
				CYLINDER
			)
			for index = 1, 3 do
				bars[index] = fxPart(
					cast,
					"GoldenChainsRune",
					CFrame.new(ground + Vector3.new(0, 0.2, 0)),
					Vector3.new(radius * 1.9, 0.1, 0.45),
					BRIGHT,
					0.25
				)
			end
			for index = 1, 4 do
				sockets[index] =
					fxPart(cast, "GoldenChainsSocket", flat(ground), Vector3.new(0.14, 1.6, 1.6), GOLD, 0.15, CYLINDER)
				spikes[index] =
					fxPart(cast, "GoldenChainsSpike", flat(ground), Vector3.new(0.2, 0.45, 0.45), BRIGHT, 0.3, CYLINDER)
			end
		end
		local updateDecor = Visuals.updateDecor({
			hideWarning = hideWarning,
			warningTime = warningTime,
			rim = rim,
			flat = flat,
			radius = radius,
			fill = fill,
			bars = bars,
			HALF_PI = HALF_PI,
			sockets = sockets,
			spikes = spikes,
			get_decorDone = function() return decorDone end,
			get_nativeSuppressed = function() return nativeSuppressed end,
			get_elapsed = function() return elapsed end,
			get_ground = function() return ground end,
			get_locked = function() return locked end,
		})
		local function fadeDecor()
			if hideWarning then
				return
			end
			decorDone = true
			local everything = { rim, fill }
			for _, item in ipairs(bars) do
				everything[#everything + 1] = item
			end
			for _, item in ipairs(sockets) do
				everything[#everything + 1] = item
			end
			for _, item in ipairs(spikes) do
				everything[#everything + 1] = item
			end
			for _, item in ipairs(everything) do
				Effects:Create(item, tweenOut(0.25), { Transparency = 1 }):Play()
			end
		end
		 
		local lockFlash = Visuals.lockFlash({
			hideWarning = hideWarning,
			rim = rim,
			BRIGHT = BRIGHT,
			bars = bars,
			WHITE = WHITE,
			sockets = sockets,
			fxPart = fxPart,
			cast = cast,
			flat = flat,
			radius = radius,
			CYLINDER = CYLINDER,
			Effects = Effects,
			tweenOut = tweenOut,
			get_ground = function() return ground end,
		})

		 
		local links, cuffs = {}, {}
		local shattered = false
		local eruptFx = Visuals.eruptFx({
			hideWarning = hideWarning,
			fxPart = fxPart,
			cast = cast,
			flat = flat,
			CYLINDER = CYLINDER,
			Effects = Effects,
			tweenOut = tweenOut,
			radius = radius,
			BRIGHT = BRIGHT,
			GOLD = GOLD,
			random = random,
			WHITE = WHITE,
			TweenService = TweenService,
			chains = chains,
			TAU = TAU,
			get_ground = function() return ground end,
		})
		local buildLinks = Visuals.buildLinks({
			chains = chains,
			LINKS = LINKS,
			fxPart = fxPart,
			cast = cast,
			BRIGHT = BRIGHT,
			GOLD = GOLD,
			links = links,
			get_ground = function() return ground end,
		})
		local updateLinks = Visuals.updateLinks({
			chains = chains,
			links = links,
			LINKS = LINKS,
			bend = bend,
			HALF_PI = HALF_PI,
			get_shattered = function() return shattered end,
			get_elapsed = function() return elapsed end,
		})
		local function shatter()
			shattered = true
			for _, set in ipairs(links) do
				for _, link in ipairs(set) do
					local dir =
						Vector3.new(random:NextNumber(-1, 1), random:NextNumber(0.2, 1), random:NextNumber(-1, 1)).Unit
					Effects:Create(link, tweenOut(0.25), {
						CFrame = link.CFrame + dir * random:NextNumber(2, 5),
						Size = link.Size * 0.4,
						Transparency = 1,
					}):Play()
				end
			end
			for _, set in pairs(cuffs) do
				for _, ring in ipairs(set) do
					Effects:Create(ring, tweenOut(0.25), { Size = ring.Size * 1.5, Transparency = 1 }):Play()
				end
			end
		end
		local addCuff = Visuals.addCuff({
			fxPart = fxPart,
			cast = cast,
			GOLD = GOLD,
			BRIGHT = BRIGHT,
			CYLINDER = CYLINDER,
			cuffs = cuffs,
			get_ground = function() return ground end,
		})
		local updateCuff = Visuals.updateCuff({
			cuffs = cuffs,
			HALF_PI = HALF_PI,
			get_elapsed = function() return elapsed end,
		})
		local dropCuff = Visuals.dropCuff({
			cuffs = cuffs,
		})

		local preview = not hideWarning
			and options.AllowFalseFuture
			and core.BeginTelegraph("P1.5GroundChains", {
				Duration = warningTime,
				Shape = "Circle",
				Valid = function()
					return cast:Alive() and not erupted
				end,
				Geometry = function()
					return { Position = ground, Radius = radius }
				end,
				SuppressNative = function(hidden)
					nativeSuppressed = hidden
					marker.Transparency = hidden and 1 or 0.55
				end,
				Reveal = function(geometry)
					ground = geometry.Position
					locked = true
					record.Locked = true
					record.Position = ground
					anchor.CFrame = CFrame.new(ground)
					marker.CFrame = CFrame.new(ground + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
					marker.Color = BRIGHT
					marker:SetAttribute("TemporalTruthRevealed", true)
					marker:SetAttribute("WarningState", "Locked")
					actor:SetAttribute("GroundChainsLockedPosition", ground)
					actor:SetAttribute("GroundChainsLockedAt", workspace:GetServerTimeNow())
					Audio.Emit(actor, "GroundLock", ground)
					lockFlash()
				end,
			})
		if preview then
			 
			 
			local previous = cast.OnDispose
			cast.OnDispose = function()
				if previous then
					previous()
				end
				preview.Cast:Dispose()
			end
		end
		cast:Step(function(dt)
			if
				owner:GetAttribute("PhaseTransitionInProgress")
				or owner:GetAttribute("AIEnabled") == false
				or (owner:GetAttribute("PhaseGeneration") or 0) ~= generation
				or (owner:GetAttribute("MovementRevision") or 0) ~= revision
			then
				cast:Dispose()
				return false
			end
			if Time.IsStopped(actor) then
				return true
			end
			elapsed += Time.EncounterDelta(actor, dt)
			if not locked then
				if options.PositionProvider then
					local desired = options.PositionProvider(elapsed, trackingTime, ground)
					if not desired then
						cast:Dispose()
						return false
					end
					local candidate = Placement.GroundPoint(desired, { Margin = radius + 1, Clamp = true })
					if candidate then
						ground = candidate
					end
				elseif trackedCharacter then
					if not core.Alive(trackedCharacter) then
						cast:Dispose()
						return false
					end
					local candidate = Placement.GroundPoint(
						trackedCharacter.HumanoidRootPart.Position,
						{ Margin = radius + 1, Clamp = true }
					)
					if candidate then
						ground = candidate
					end
				end
				anchor.CFrame = CFrame.new(ground)
				if not hideWarning then
					marker.CFrame = CFrame.new(ground + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
				end
				record.Position = ground
				actor:SetAttribute("GroundChainsTrackedPosition", ground)
				if elapsed >= trackingTime then
					locked = true
					record.Locked = true
					marker.Color = BRIGHT
					marker:SetAttribute("WarningState", "Locked")
					actor:SetAttribute("GroundChainsLockedPosition", ground)
					actor:SetAttribute("GroundChainsLockedAt", workspace:GetServerTimeNow())
					Audio.Emit(actor, "GroundLock", ground)
					lockFlash()
				end
			end
			if elapsed < warningTime then
				marker.Transparency = (hideWarning or nativeSuppressed) and 1
					or (locked and 0.32 or 0.55) + math.sin(elapsed * 13) * 0.12
				updateDecor()
				if options.PreparingChains then
					for index, item in ipairs(chains) do
						item.Last.Position = item.First.Position * 0.3
							+ Vector3.new(0, 2.5 + math.sin(elapsed * 7 + index) * 0.6, 0)
					end
				end
				return true
			end
			if not erupted then
				erupted = true
				Audio.Emit(actor, "GroundErupt", ground)
				if preview then
					preview.Cast:Dispose()
				end
				record.Erupted = true
				record.EruptedAt = workspace:GetServerTimeNow()
				record.EruptedEncounterAt = Time.EncounterNow(actor)
				actor:SetAttribute("GroundChainsEruptions", (actor:GetAttribute("GroundChainsEruptions") or 0) + 1)
				for _, item in ipairs(chains) do
					item.Beam.Enabled = true
				end
				fadeDecor()
				eruptFx()
				buildLinks()
				for _, character in ipairs(core.Characters()) do
					if core.Alive(character) then
						local offset = character.HumanoidRootPart.Position - ground
						local valid = math.abs(offset.Y) <= 7
							and Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius
							and Encounter.CanReceiveHit(character)
						if
							valid
							and (damage <= 0 or core.Damage(character, damage) > 0)
							and Status.ApplyStun(
								character,
								cast,
								restraintDuration,
								Config.GroundChainsRestunGrace or 0.9,
								{ AllowDefense = true, Family = "ChainStun" }
							)
						then
							members[character] = Time.EncounterNow(actor) + restraintDuration
							addCuff(character)
						end
					end
				end
				 
				 
				if next(members) == nil then
					visualHold = 0.35
				end
				if next(members) then
					record.TensionAudio = Audio.Loop(cast, actor, "GroundTension", anchor)
				end
				cast.expires = cast:Now() + visualHold + 0.3
			end
			local elapsedAfter = elapsed - warningTime
			local target
			local restraintNow = Time.EncounterNow(actor)
			for character, expires in pairs(members) do
				if core.Alive(character) and not Status.IsDebuffImmune(character) and restraintNow < expires then
					target = character.HumanoidRootPart.Position
					updateCuff(character)
				else
					Status.ReleaseRestraint(character, cast)
					members[character] = nil
					dropCuff(character)
				end
			end
			if not next(members) and record.TensionAudio then
				record.TensionAudio:Dispose()
				record.TensionAudio = nil
			end
			for _, item in ipairs(chains) do
				local goal = target or ground + Vector3.new(item.First.Position.X * 0.4, 8, item.First.Position.Z * 0.4)
				item.Last.WorldPosition = item.First.WorldPosition:Lerp(goal, math.clamp(elapsedAfter / 0.12, 0, 1))
				item.Beam.Transparency =
					NumberSequence.new(0.12 + 0.88 * math.clamp((elapsedAfter - visualHold) / 0.25, 0, 1))
			end
			updateLinks(target ~= nil)
			if elapsedAfter >= visualHold then
				if not shattered then
					shatter()
				end
				release()
			end
			marker.Transparency = hideWarning and 1 or math.clamp(0.7 + elapsedAfter * 0.3, 0, 1)
			if elapsedAfter >= visualHold + 0.25 then
				cast:Dispose()
				return false
			end
			return true
		end)
		actor:SetAttribute("GroundChainsMarkedPosition", ground)
		marker:SetAttribute("WarningState", trackingTime > 0 and "Tracking" or "Locking")
		return record
	end
	function api.CanUse(character)
		return (tonumber(actor:GetAttribute("Phase")) or 1) >= 1.5 and core.Active() and core.Alive(character)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P1.5GroundChains", function()
			core.Face(character)
			core.Melee.Pose("Windup3", 0.14)
			actor:SetAttribute("AttackState", "Ground Chains: marking target")
			if not api.Mark(character.HumanoidRootPart.Position, character, { AllowFalseFuture = true }) then
				return false
			end
			if not core.WaitFor(0.25) then
				return false
			end
			core.Melee.Pose("Slash3", 0.1)
			return core.WaitFor(0.2)
		end)
	end
	return api
end
