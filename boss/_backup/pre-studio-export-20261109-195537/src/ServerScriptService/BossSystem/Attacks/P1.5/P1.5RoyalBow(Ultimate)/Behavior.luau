local script = script.Parent
local Style = require(script.Style)
local Visuals = require(script.Visuals)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
return function(actor)
	local Audio = require(BossSystem.Presentation.CombatAudio)
	local Registry = require(BossSystem.Combat.AttackRegistry)
	local Effects = require(BossSystem.Combat.EffectService)
	local Placement = require(BossSystem.Encounter.ArenaPlacement)
	local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
	local Encounter = require(BossSystem.Players.PlayerEncounter)
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local Run = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local Debris = game:GetService("Debris")
	local random = Random.new()
	local core = Registry.For(actor, "P1CombatCore")
	local ownerReference = actor:FindFirstChild("EncounterOwner")
	local owner = ownerReference and ownerReference:IsA("ObjectValue") and ownerReference.Value or actor
	local api = {
		IsUltimate = true,
		UltimatePhase = 1.5,
		Cooldown = 45,
		ArrowDamage = Config.RoyalBowArrowDamage or 50,
		ImpactRadius = Config.RoyalBowImpactRadius or 28,
		FinalRadius = Config.RoyalBowFinalImpactRadius or 60,
		WarningTime = 0.85,
		ExecutionRadius = Config.RoyalBowExecutionRadius or 10,
		FinalWarningTime = Config.RoyalBowFinalWarningTime or 1.6,
	}
	local GOLD, BRIGHT = Style.GOLD, Style.BRIGHT
	local STONE = Style.STONE
	local WHITE = Style.WHITE  
	local HOT = Style.HOT  
	local UPRIGHT = CFrame.Angles(0, 0, math.pi * 0.5)
	local GRAVITY = 120
	 
	local CHAIN_TINT = { Direct = HOT, Predictive = GOLD, EscapePath = BRIGHT, Surround = GOLD }

	local function easeOut(t)
		return 1 - (1 - t) ^ 3
	end  

	local part = Visuals.part({
		core = core,
	})
	local beam = Visuals.beam({
		BRIGHT = BRIGHT,
		GOLD = GOLD,
	})

	local disc = Visuals.disc({
		part = part,
	})
	local ball = Visuals.ball({
		part = part,
	})
	local point = Visuals.point({})
	local link = Visuals.link({})
	local ring = Visuals.ring({
		point = point,
		link = link,
	})
	local setAlpha = Visuals.setAlpha({})
	 
	local recolor = Visuals.recolor({})
	 
	local resizeRing = Visuals.resizeRing({})

	local sparkEmitter = Visuals.sparkEmitter({
		BRIGHT = BRIGHT,
		GOLD = GOLD,
	})
	local dustEmitter = Visuals.dustEmitter({})
	local converge = Visuals.converge({})

	 
	local screenGrade = Visuals.screenGrade({
		Effects = Effects,
		actor = actor,
		Lighting = Lighting,
		Debris = Debris,
		Time = Time,
	})

	local crackField = Visuals.crackField({
		point = point,
		link = link,
		BRIGHT = BRIGHT,
		GOLD = GOLD,
		random = random,
	})
	local growStrands = Visuals.growStrands({})

	 
	local expandingRing = Visuals.expandingRing({
		Effects = Effects,
		actor = actor,
		part = part,
		GOLD = GOLD,
		ring = ring,
		BRIGHT = BRIGHT,
		Time = Time,
		resizeRing = resizeRing,
		setAlpha = setAlpha,
	})
	local sparkBurst = Visuals.sparkBurst({
		Effects = Effects,
		actor = actor,
		part = part,
		GOLD = GOLD,
		sparkEmitter = sparkEmitter,
	})
	local groundPuff = Visuals.groundPuff({
		Effects = Effects,
		actor = actor,
		part = part,
		GOLD = GOLD,
		dustEmitter = dustEmitter,
		sparkEmitter = sparkEmitter,
		expandingRing = expandingRing,
	})
	local lightColumn = Visuals.lightColumn({
		disc = disc,
		UPRIGHT = UPRIGHT,
		BRIGHT = BRIGHT,
	})
	local fadeAway = Visuals.fadeAway({
		Effects = Effects,
	})

	 
	 
	local lightSpikes = Visuals.lightSpikes({
		Effects = Effects,
		actor = actor,
		random = random,
		disc = disc,
		UPRIGHT = UPRIGHT,
		BRIGHT = BRIGHT,
		GOLD = GOLD,
		Time = Time,
		easeOut = easeOut,
	})

	 
	 
	 
	 
	 
	 
	 
	 
	local chainSigil = Visuals.chainSigil({
		CHAIN_TINT = CHAIN_TINT,
		GOLD = GOLD,
		Effects = Effects,
		actor = actor,
		part = part,
		setAlpha = setAlpha,
		ring = ring,
		BRIGHT = BRIGHT,
		point = point,
		link = link,
		HOT = HOT,
		WHITE = WHITE,
		disc = disc,
		UPRIGHT = UPRIGHT,
		sparkEmitter = sparkEmitter,
		expandingRing = expandingRing,
		random = random,
		Time = Time,
		resizeRing = resizeRing,
		easeOut = easeOut,
		recolor = recolor,
		sparkBurst = sparkBurst,
	})

	local chainTethers = Visuals.chainTethers({
		Effects = Effects,
		actor = actor,
		part = part,
		GOLD = GOLD,
		point = point,
		link = link,
		BRIGHT = BRIGHT,
		Time = Time,
		core = core,
		setAlpha = setAlpha,
		recolor = recolor,
		HOT = HOT,
	})

	 
	 
	 
	local summonSigil = Visuals.summonSigil({
		Effects = Effects,
		actor = actor,
		part = part,
		GOLD = GOLD,
		ring = ring,
		BRIGHT = BRIGHT,
		link = link,
		point = point,
		sparkEmitter = sparkEmitter,
		Time = Time,
		setAlpha = setAlpha,
	})

	 
	local skyMotes = Visuals.skyMotes({
		Effects = Effects,
		actor = actor,
		part = part,
		GOLD = GOLD,
		sparkEmitter = sparkEmitter,
	})

	 
	 
	local buildBow = Visuals.buildBow({
		part = part,
		GOLD = GOLD,
		beam = beam,
		Effects = Effects,
		actor = actor,
		Time = Time,
		easeOut = easeOut,
	})

	local halo = Visuals.halo({
		core = core,
		Effects = Effects,
		actor = actor,
		part = part,
		GOLD = GOLD,
		ring = ring,
		BRIGHT = BRIGHT,
		link = link,
		point = point,
		Time = Time,
		setAlpha = setAlpha,
	})

	local windup = Visuals.windup({
		Effects = Effects,
		actor = actor,
		part = part,
		GOLD = GOLD,
		link = link,
		BRIGHT = BRIGHT,
		ball = ball,
		sparkEmitter = sparkEmitter,
		converge = converge,
		ring = ring,
		Time = Time,
		setAlpha = setAlpha,
	})
	local releaseBurst = Visuals.releaseBurst({
		expandingRing = expandingRing,
		sparkBurst = sparkBurst,
		core = core,
	})

	 
	 
	local telegraph = Visuals.telegraph({
		Effects = Effects,
		actor = actor,
		part = part,
		GOLD = GOLD,
		ring = ring,
		disc = disc,
		UPRIGHT = UPRIGHT,
		api = api,
		BRIGHT = BRIGHT,
		link = link,
		point = point,
		Time = Time,
		resizeRing = resizeRing,
		easeOut = easeOut,
		setAlpha = setAlpha,
	})

	local blastPlumes = Visuals.blastPlumes({
		random = random,
		part = part,
		GOLD = GOLD,
		Effects = Effects,
	})

	local aftermath = Visuals.aftermath({
		Effects = Effects,
		actor = actor,
		part = part,
		GOLD = GOLD,
		disc = disc,
		UPRIGHT = UPRIGHT,
		ring = ring,
		BRIGHT = BRIGHT,
		api = api,
		dustEmitter = dustEmitter,
		sparkEmitter = sparkEmitter,
		GRAVITY = GRAVITY,
		crackField = crackField,
		random = random,
		STONE = STONE,
		screenGrade = screenGrade,
		Time = Time,
		setAlpha = setAlpha,
		growStrands = growStrands,
	})

	function api.Impact(position, final)
		local radius = final and api.FinalRadius or api.ImpactRadius
		local cast =
			Effects.NewCast(actor, final and "RoyalBowFinalImpact" or "RoyalBowGoldenImpact", final and 1.5 or 1)
		if final then
			Audio.Emit(actor, "RoyalFinalVacuum", position)
			cast:Schedule(0.12, function()
				Audio.Emit(actor, "RoyalFinalImpact", position)
			end)
		else
			Audio.Emit(actor, "RoyalImpact", position)
		end
		local center = position + Vector3.new(0, 0.12, 0)
		local damageHeight = final and 28 or 13
		local orb = part(
			cast,
			final and "RoyalBowFinisherExplosion" or "RoyalBowImpactExplosion",
			CFrame.new(center),
			Vector3.new(radius * 2, damageHeight * 2, radius * 2),
			Color3.fromRGB(255, 224, 41),
			0.42
		)
		orb.Shape = Enum.PartType.Ball
		orb:SetAttribute("RoyalBowDamageRadius", radius)
		orb:SetAttribute("RoyalBowDamageHeight", damageHeight)
		Effects:Create(orb, TweenInfo.new(final and 0.85 or 0.45, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
		Effects.ReleaseAfter(orb, final and 1.2 or 0.8)

		 
		local flashTime = final and 0.5 or 0.3
		local flash = disc(
			cast,
			"RoyalBowImpactFlash",
			CFrame.new(center) * UPRIGHT,
			Vector3.new(0.2, radius * 0.8, radius * 0.8),
			WHITE,
			0
		)
		Effects:Create(
			flash,
			TweenInfo.new(flashTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.2, radius * 2.3, radius * 2.3), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(flash, flashTime + 0.1)
		local domeTime = final and 0.55 or 0.35
		local dome = ball(cast, "RoyalBowImpactDome", CFrame.new(center), Vector3.one * radius * 0.4, BRIGHT, 0.55)
		Effects:Create(
			dome,
			TweenInfo.new(domeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.one * radius * 2.1, Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(dome, domeTime + 0.1)
		expandingRing(CFrame.new(center), false, 3, radius * 1.3, final and 0.7 or 0.45, final and 3 or 2, 48)
		cast:Schedule(0.1, function()
			expandingRing(CFrame.new(center), false, 2, radius * 0.9, 0.4, final and 2 or 1.2, 40)
		end)
		lightSpikes(position, radius, final)

		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "RoyalBowYellowImpactParticles"
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 176, 24))
		sparks.Rate = 0
		sparks.Lifetime = NumberRange.new(0.25, 0.7)
		sparks.Speed = NumberRange.new(14, 32)
		sparks.Acceleration = Vector3.new(0, -6, 0)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.LightEmission = 0.35
		sparks.LightInfluence = 0.2
		sparks.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		sparks.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, final and 2.4 or 1.4),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparks.Parent = orb
		sparks:Emit(final and 42 or 24)
		orb:SetAttribute("RoyalBowBlastPlumeCount", blastPlumes(cast, position, radius, damageHeight, final))
		aftermath(position, radius, damageHeight, final)
		local killed = false
		for _, character in ipairs(core.Characters()) do
			if core.Alive(character) then
				local offset = character.HumanoidRootPart.Position - position
				local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if offset.Y >= -2 and offset.Y <= (final and 28 or 13) and distance <= radius then
					if final then
      if distance<=api.ExecutionRadius then
       if Encounter.ExecuteHit(character,1,"Royal Bow central execution") then
        killed=true
        actor:SetAttribute("RoyalBowExecutionKills",(actor:GetAttribute("RoyalBowExecutionKills") or 0)+1)
        actor:SetAttribute("RoyalBowExecutedLifeCost",1)
       end
      else
       core.Damage(character,150,"P1.5RoyalBow(Ultimate)")
      end
					else
						core.Damage(character, api.ArrowDamage)
					end
				end
			end
		end
		if killed then
			Encounter.Say("Worthless as ever.")
		end
		core.ScreenEffect("Shake", {
			Origin = position,
			Radius = final and 420 or 130,
			Duration = final and 1.2 or 0.45,
			Intensity = final and 1 or 0.45,
		})
		actor:SetAttribute("RoyalBowImpacts", (actor:GetAttribute("RoyalBowImpacts") or 0) + 1)
		if final then
			actor:SetAttribute("RoyalBowFinalImpacts", (actor:GetAttribute("RoyalBowFinalImpacts") or 0) + 1)
		end
		return cast
	end

	function api.PrepareArrowChains(position, target, index, preparationTime)
		local final = index == 5
		local count = math.clamp(
			math.floor(final and (Config.RoyalBowChainMarkerCount or 8) or (Config.RoyalBowNormalChainCount or 2)),
			2,
			12
		)
		local radius = Config.RoyalBowChainRadius or 3.5
		local ringRadius = math.max(Config.RoyalBowChainRingRadius or 18, radius * 2 + 5)
		local approachRadius =
			math.max(Config.RoyalBowChainApproachRadius or 8, (radius * 2 + 2) * count / (math.pi * 2))
		local predictionTime = Config.RoyalBowChainPredictionTime or 0.45
		local baseAngle = random:NextNumber(0, math.pi * 2)
		local turn = random:NextNumber(-0.65, 0.65)
		local lockWarning = math.clamp(Config.RoyalBowChainLockWarningTime or 0.18, 0.12, 0.35)
		local records = {}
		local groundChains = Registry.For(actor, "P1.5GroundChains")
		for chainIndex = 1, count do
			local mode
			if chainIndex == 1 then
				mode = "Direct"
			elseif not final then
				mode = index % 2 == 1 and "Predictive" or "EscapePath"
			elseif chainIndex % 3 == 2 then
				mode = "Predictive"
			elseif chainIndex % 3 == 0 then
				mode = "EscapePath"
			else
				mode = "Surround"
			end
			local trackingTime = mode == "Direct"
					and math.min(
						Config.RoyalBowChainDirectTrackingTime or 0.35,
						math.max(0.15, preparationTime - lockWarning)
					)
				or math.max(0.15, preparationTime - lockWarning)
			local angle = baseAngle + (chainIndex - 1) * math.pi * 2 / count
			local jitter = random:NextNumber(-0.1, 0.1)
			local currentRecord
			local function predictedPosition(elapsed)
				local focus, velocity = position, Vector3.zero
				if target then
					if not core.Alive(target) then
						return nil
					end
					focus = target.HumanoidRootPart.Position
					velocity = target.HumanoidRootPart.AssemblyLinearVelocity
				end
				if mode == "Direct" then
					return Placement.GroundPoint(focus, { Margin = radius + 1, Clamp = true })
				end
				local flatVelocity = Vector3.new(velocity.X, 0, velocity.Z)
				local forecast = flatVelocity * predictionTime
				if forecast.Magnitude > 12 then
					forecast = forecast.Unit * 12
				end
				local progress = math.clamp(elapsed / math.max(trackingTime, 0.05), 0, 1)
				local distance = ringRadius + (approachRadius - ringRadius) * progress
				local heading = angle + turn * progress + math.sin(elapsed * 3 + chainIndex) * jitter
				if mode == "Predictive" then
					focus += forecast
				elseif mode == "EscapePath" then
					local escape = flatVelocity
					if escape.Magnitude < 1 and target then
						escape = target.HumanoidRootPart.CFrame.LookVector
					end
					escape = Vector3.new(escape.X, 0, escape.Z)
					if escape.Magnitude < 0.01 then
						escape = Vector3.new(0, 0, -1)
					end
					heading = math.atan2(escape.Z, escape.X)
						+ (chainIndex % 2 == 0 and 0.55 or -0.55)
						+ turn * progress * 0.35
				end
				for attempt = 0, 5 do
					local candidateAngle = heading + (attempt % 2 == 0 and 1 or -1) * math.ceil(attempt / 2) * 0.28
					local candidate = Placement.GroundPoint(
						focus + Vector3.new(math.cos(candidateAngle), 0, math.sin(candidateAngle)) * distance,
						{ Margin = radius + 1, Clamp = true }
					)
					local separated = candidate ~= nil
					if candidate then
						for _, other in ipairs(records) do
							if
								other ~= currentRecord
								and not other.Cast.closed
								and (other.Position - candidate).Magnitude < radius * 2 + 0.8
							then
								separated = false
								break
							end
						end
					end
					if separated then
						return candidate
					end
				end
				return currentRecord and currentRecord.Position or nil
			end
			local ground = predictedPosition(0)
			if ground then
				currentRecord = groundChains.Mark(ground, nil, {
					TrackingTime = trackingTime,
					LockWarningTime = lockWarning,
					Radius = radius,
					RestraintDuration = Config.RoyalBowChainRestraintDuration or 3,
					Damage = 0,
					CastName = final and "RoyalBowFinalTrackingChain" or "RoyalBowArrowTrackingChain",
					PositionProvider = predictedPosition,
					PreparingChains = true,
					TargetingMode = mode,
				})
				if currentRecord then
					records[#records + 1] = currentRecord
					 
					if Config.RoyalBowChainOverlay ~= false then
						chainSigil(currentRecord, {
							Mode = mode,
							Final = final,
							Radius = radius,
							Count = count,
							TrackingTime = trackingTime,
							Life = preparationTime,
							Position = ground,
						})
					end
				end
			end
		end
		 
		if Config.RoyalBowChainOverlay ~= false then
			chainTethers(records, target, position, preparationTime, math.max(preparationTime - lockWarning, 0.15))
		end
		actor:SetAttribute("RoyalBowChainMarkerCount", #records)
		actor:SetAttribute("RoyalBowChainRingRadius", ringRadius)
		actor:SetAttribute("RoyalBowArrow" .. index .. "ChainCount", #records)
		actor:SetAttribute("RoyalBowChainPredictionTime", predictionTime)
		return records
	end

	function api.CreateFinisherChains(position, target)
		return api.PrepareArrowChains(position, target, 5, api.FinalWarningTime)
	end

	 
	 
	function api.FireArrow(origin, targetPosition, index, target, hooks)
		local position = Placement.GroundPoint(targetPosition, { Margin = 6, Clamp = true })
		if not position then
			return nil
		end
		local final = index == 5
		local warning = final and api.FinalWarningTime or api.WarningTime
		local speed = final and 255 or 220
		local aimPoint = position + Vector3.new(0, 0.6, 0)
		local direction = (aimPoint - origin).Unit
		local length = (aimPoint - origin).Magnitude
		local flight = length / speed
		local radius = final and api.FinalRadius or api.ImpactRadius
		local cast = Effects.NewCast(actor, "RoyalBowArrow", warning + (position - origin).Magnitude / speed + 0.3)
		Audio.Emit(actor, final and "RoyalFinalCharge" or "RoyalDraw", origin)
		local generation = owner:GetAttribute("PhaseGeneration") or 0
		local chainRecords = api.PrepareArrowChains(position, target, index, warning)
		local completed, launched = false, false
		local charging = windup(origin, position, direction, warning, final)
		local marker = telegraph(position, radius, final, warning + flight)
		if final then
			core.ScreenEffect("Shake", { Origin = origin, Radius = 300, Duration = warning, Intensity = 0.25 })
			screenGrade({
				Brightness = -0.08,
				Contrast = 0.15,
				Saturation = -0.15,
				Tint = Color3.fromRGB(255, 235, 190),
				Bloom = 0.9,
			}, 0.4, math.max(warning - 0.2, 0.1), 0.6)
		end
		cast.OnDispose = function()
			charging:Dispose()
			marker:Dispose()
			if not completed then
				for _, record in ipairs(chainRecords) do
					record.Cast:Dispose()
				end
			end
		end
		local arrow = part(
			cast,
			final and "RoyalBowFinalArrow" or "RoyalBowArrow",
			CFrame.new(origin),
			Vector3.new(final and 1.9 or 0.75, final and 1.9 or 0.75, final and 32 or 19),
			BRIGHT,
			0.12
		)
		arrow.Material = Enum.Material.Neon
		local fin = part(
			cast,
			"RoyalBowArrowWings",
			CFrame.new(origin),
			Vector3.new(final and 10 or 5, 0.22, final and 7 or 4),
			GOLD,
			0.12
		)
		local head = ball(
			cast,
			"RoyalBowArrowHead",
			CFrame.new(origin),
			Vector3.new(final and 3.2 or 1.7, final and 3.2 or 1.7, final and 7 or 3.6),
			BRIGHT,
			0
		)
		local shell = ball(
			cast,
			"RoyalBowArrowGlow",
			CFrame.new(origin),
			Vector3.new(arrow.Size.X * 3.4, arrow.Size.Y * 3.4, arrow.Size.Z * 1.1),
			GOLD,
			0.72
		)
		local shellSize = shell.Size
		local arrowLight = Instance.new("PointLight")
		arrowLight.Color = GOLD
		arrowLight.Range = 40
		arrowLight.Brightness = 3
		arrowLight.Shadows = false
		arrowLight.Parent = shell
		sparkEmitter(arrow, final and 80 or 40, final and 1.4 or 0.8)
		local wingA, wingB = Instance.new("Attachment"), Instance.new("Attachment")
		wingA.Position, wingB.Position = Vector3.new(fin.Size.X * 0.5, 0, 0), Vector3.new(-fin.Size.X * 0.5, 0, 0)
		wingA.Parent, wingB.Parent = fin, fin
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = wingA, wingB
		trail.Lifetime = final and 0.6 or 0.4
		trail.LightEmission = 1
		trail.FaceCamera = true
		trail.Color = ColorSequence.new(BRIGHT, GOLD)
		trail.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		trail.Parent = fin
		 
		local bodyA, bodyB = Instance.new("Attachment"), Instance.new("Attachment")
		bodyA.Position, bodyB.Position = Vector3.new(0, arrow.Size.Y * 1.4, 0), Vector3.new(0, -arrow.Size.Y * 1.4, 0)
		bodyA.Parent, bodyB.Parent = arrow, arrow
		local softTrail = Instance.new("Trail")
		softTrail.Attachment0, softTrail.Attachment1 = bodyA, bodyB
		softTrail.Lifetime = final and 0.9 or 0.6
		softTrail.LightEmission = 1
		softTrail.FaceCamera = true
		softTrail.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 176, 24))
		softTrail.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
		softTrail.WidthScale =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
		softTrail.Parent = arrow
		local dust = sparkEmitter(arrow, final and 60 or 30, final and 1.1 or 0.7)
		dust.Speed = NumberRange.new(1, 4)
		dust.Lifetime = NumberRange.new(0.6, 1.2)
		dust.Acceleration = Vector3.new(0, -4, 0)

		local elapsed = 0
		local function draw(tip)
			local frame = CFrame.lookAt(tip, tip + direction)
			arrow.CFrame = frame * CFrame.new(0, 0, arrow.Size.Z * 0.5)
			fin.CFrame = frame * CFrame.new(0, 0, arrow.Size.Z * 0.7)
			head.CFrame = frame * CFrame.new(0, 0, head.Size.Z * 0.5)
			shell.CFrame = arrow.CFrame
			shell.Size = shellSize * (1 + 0.12 * math.sin(elapsed * 45))  
		end
		draw(origin)
		 
		local ringGap = math.max(length / 6, 12)
		local nextRing, ringsLeft = ringGap * 0.5, 6
		cast:Step(function(dt)
			if
				not owner.Parent
				or (owner:GetAttribute("Phase") or 1) ~= api.UltimatePhase
				or (owner:GetAttribute("PhaseGeneration") or 0) ~= generation
				or owner:GetAttribute("PhaseTransitionInProgress")
			then
				cast:Dispose()
				return false
			end
			if Time.IsStopped(actor) then
				return true
			end
			elapsed += Time.EncounterDelta(actor, dt)
			if elapsed < warning then
				if hooks and hooks.Draw then
					hooks.Draw(elapsed / warning)
				end
				return true
			end
			if not launched then
				launched = true
				Audio.Emit(actor, final and "RoyalFinalRelease" or "RoyalRelease", arrow)
				charging:Dispose()
				releaseBurst(origin, direction, final)
				if hooks and hooks.Release then
					hooks.Release()
				end
			end
			local progress = math.clamp((elapsed - warning) * speed / length, 0, 1)
			local travelled = length * progress
			draw(origin + direction * travelled)
			while ringsLeft > 0 and travelled >= nextRing do
				ringsLeft -= 1
				local at = origin + direction * nextRing
				expandingRing(
					CFrame.lookAt(at, at + direction),
					true,
					1,
					final and 9 or 5,
					0.3,
					final and 1.2 or 0.7,
					18
				)
				nextRing += ringGap
			end
			if progress >= 1 then
				completed = true
				api.Impact(position, final)
				cast:Dispose()
				return false
			end
			return true
		end)
		actor:SetAttribute("RoyalBowArrowsReleased", (actor:GetAttribute("RoyalBowArrowsReleased") or 0) + 1)
		return {
			Cast = cast,
			Position = position,
			Index = index,
			WarningTime = warning,
			Chains = chainRecords[1],
			ChainMarkers = chainRecords,
			FlightDuration = length / speed,
		}
	end
	function api.CanUse(character)
		return (tonumber(actor:GetAttribute("Phase")) or 1) == api.UltimatePhase
			and actor:GetAttribute("IsGoldenClone") ~= true
			and core.Active()
			and core.Alive(character)
	end
	function api.Combo(character)
		if not api.CanUse(character) then
			return false
		end
		return core.Perform(character, "P1.5RoyalBow(Ultimate)", function()
			local cast = Effects.NewCast(actor, "RoyalBowAerialCaster", 20)
			local root = core.Root
			local start = root.CFrame
			local standing = Placement.Validate(actor, start, { Margin = 5 }) or start
			local sky = standing + Vector3.new(0, 85, 0)
			local groundPoint = Placement.GroundPoint(standing.Position, { Margin = 2, Clamp = true })
			local groundY = groundPoint and groundPoint.Y or standing.Y - 3
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local movementRevision = actor:GetAttribute("MovementRevision") or 0
			local mood, crown, sigil, motes
			core.AirborneFloor = standing.Y
			local function ownsMovement()
				return not cast.closed
					and root.Parent
					and core.Active()
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == movementRevision
					and not actor:GetAttribute("PhaseTransitionInProgress")
			end
			local function animate(goal, seconds, each)
				local from, elapsed = root.CFrame, 0
				while elapsed < seconds do
					if not ownsMovement() then
						return false
					end
					local dt = Run.Heartbeat:Wait()
					if not ownsMovement() then
						return false
					end
					elapsed += dt * Time.BossRate(actor)
					local alpha = math.sin(math.clamp(elapsed / seconds, 0, 1) * math.pi * 0.5)
					root.CFrame = from:Lerp(goal, alpha)
					root.AssemblyLinearVelocity = Vector3.zero
					if each then
						each(alpha)
					end
				end
				return true
			end
			local function sequence()
				actor:SetAttribute("AttackState", "Royal Bow: announcing shots")
				core.Melee.Pose("Idle", 0.15)
				local intro = Config.RoyalBowIntro or "Prepare to see some of my amazing shots."
				if not Encounter.SayAndWait(intro, actor) then
					return false
				end
				actor:SetAttribute("RoyalBowIntroCompletedAt", workspace:GetServerTimeNow())
				actor:SetAttribute("AttackState", "Royal Bow: ascending")
				actor:SetAttribute("RoyalBowAscendStartedAt", workspace:GetServerTimeNow())
				core.Melee.Pose("Windup3", 0.18)
				mood = screenGrade({
					Brightness = -0.05,
					Contrast = 0.1,
					Saturation = -0.08,
					Tint = Color3.fromRGB(255, 238, 200),
					Bloom = 0.6,
				}, 0.8, math.huge, 1.2)
				 
				screenGrade({ Brightness = 0.22, Bloom = 1.2, Tint = BRIGHT, Blur = 6 }, 0.05, 0.05, 0.5)
				groundPuff(Vector3.new(standing.X, groundY, standing.Z), 18)
				expandingRing(CFrame.new(standing.X, groundY + 0.4, standing.Z), false, 3, 52, 0.8, 3, 56)
				cast:Schedule(0.18, function()
					expandingRing(CFrame.new(standing.X, groundY + 0.4, standing.Z), false, 2, 34, 0.6, 2, 48)
				end)
				core.ScreenEffect(
					"Shake",
					{ Origin = standing.Position, Radius = 300, Duration = 0.8, Intensity = 0.4 }
				)
				sigil = summonSigil(standing.X, groundY, standing.Z)
				motes = skyMotes(standing.X, groundY, standing.Z)
				crown = halo()
				local lift, column = lightColumn(cast, groundY, standing.X, standing.Z, 8)
				local ascended = animate(sky, 0.85, function()
					lift(root.Position.Y)
				end)
				fadeAway(column, 0.6)
				if not ascended then
					return false
				end
				 
				local bow, bowControl = buildBow(cast, root)
				Audio.Emit(actor, "RoyalSummon", bow)
				for _, y in ipairs({ 24, 0, -24 }) do
					sparkEmitter(point(bow, Vector3.new(0, y, 0)), y == 0 and 10 or 22, 1.2)
				end
				local bowLight = Instance.new("PointLight")
				bowLight.Color = GOLD
				bowLight.Range = 60
				bowLight.Brightness = 2.5
				bowLight.Shadows = false
				bowLight.Parent = bow
				sparkBurst(bow.Position, 60, 1.6, 34)
				expandingRing(bow.CFrame, true, 4, 30, 0.6, 2)
				screenGrade({ Brightness = 0.1, Bloom = 0.9, Tint = BRIGHT }, 0.03, 0.03, 0.4)  
				local prepared = {}
				for index = 1, 5 do
					prepared[index] = part(
						cast,
						"RoyalBowPreparedArrow",
						root.CFrame * CFrame.new((index - 3) * 3, 3, -7),
						Vector3.new(0.35, 0.35, 18),
						GOLD,
						0.25
					)
					prepared[index].Material = Enum.Material.Neon
					sparkBurst(prepared[index].Position, 10, 0.8, 14)
				end
				actor:SetAttribute("AttackState", "Royal Bow: drawing five arrows")
				core.Melee.PoseAngles({ RightShoulder = { 45, -25, -10 }, LeftShoulder = { 80, 0, -40 } }, 0.2)
				if not core.WaitFor(0.6) then
					return false
				end
				for index = 1, 5 do
					local target = core.Alive(character) and character or core.Melee.GetTarget()
					if not target or not core.Active() then
						return false
					end
					core.Face(target)
					bow.CFrame = root.CFrame * CFrame.new(0, 3, -7)
					actor:SetAttribute(
						"AttackState",
						index == 5 and "Royal Bow: final arrow" or "Royal Bow: arrow " .. index
					)
					sparkBurst(prepared[index].Position, 14, 0.9, 18)
					 
					Effects:Create(
						prepared[index],
						TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ CFrame = bow.CFrame, Transparency = 0.7 }
					):Play()
					Effects.ReleaseAfter(prepared[index], 0.22)
					core.Melee.PoseAngles({ RightShoulder = { 70, 15, 15 }, LeftShoulder = { 80, 0, -40 } }, 0.08)
					if index == 5 then
						 
						Effects:Create(
							bowLight,
							TweenInfo.new(api.FinalWarningTime, Enum.EasingStyle.Quad),
							{ Brightness = 9, Range = 110 }
						):Play()
						expandingRing(bow.CFrame, true, 4, 48, 0.9, 3, 48)
					end
					local shot = api.FireArrow(
						root.CFrame:PointToWorldSpace(Vector3.new(0, 3, -7)),
						target.HumanoidRootPart.Position,
						index,
						target,
						{ Draw = bowControl.Draw, Release = bowControl.Release }
					)
					if not shot then
						return false
					end
					if not core.WaitFor(index == 5 and shot.WarningTime + shot.FlightDuration + 0.18 or 0.95) then
						return false
					end
					core.Melee.PoseAngles({ RightShoulder = { 45, -25, -10 }, LeftShoulder = { 80, 0, -40 } }, 0.12)
				end
				actor:SetAttribute("AttackState", "Royal Bow: descending")
				crown.Close()
				mood.Release()
				sigil.Close()
				motes.Stop()
				sparkBurst(bow.Position, 40, 1.4, 30)
				Effects.Release(bow)
				local drop, dropColumn = lightColumn(cast, groundY, standing.X, standing.Z, 8)
				local landed = animate(standing, 0.6, function()
					drop(root.Position.Y)
				end)
				fadeAway(dropColumn, 0.6)
				if landed then
					groundPuff(Vector3.new(standing.X, groundY, standing.Z), 24)
					expandingRing(CFrame.new(standing.X, groundY + 0.4, standing.Z), false, 3, 40, 0.6, 2.5, 48)  
					core.ScreenEffect(
						"Shake",
						{ Origin = standing.Position, Radius = 300, Duration = 0.5, Intensity = 0.6 }
					)
				end
				return landed
			end
			local ok, result = xpcall(sequence, debug.traceback)
			if crown then
				crown.Close()
			end
			if mood then
				mood.Release()
			end
			if sigil then
				sigil.Close()
			end
			if motes then
				motes.Stop()
			end
			cast:Dispose()
			if
				root.Parent
				and (actor:GetAttribute("PhaseGeneration") or 0) == generation
				and (actor:GetAttribute("MovementRevision") or 0) == movementRevision
				and not actor:GetAttribute("PhaseTransitionInProgress")
			then
				local safe = Placement.Validate(actor, root.CFrame, { Margin = 5 }) or standing
				root.CFrame = safe
				root.AssemblyLinearVelocity = Vector3.zero
			end
			core.AirborneFloor = nil
			if not ok then
				error(result, 0)
			end
			return result
		end)
	end
	return api
end
