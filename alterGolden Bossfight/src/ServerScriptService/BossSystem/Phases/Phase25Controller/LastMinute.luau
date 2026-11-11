-- Phase25Controller: the Last Minute ultimate: the clock sweeps and the collapse.
-- Registers its api.<Name> functions on the shared table from Core; init.luau requires this module.
local Core = require(script.Parent.Core)
local api, BossSystem, Config, Difficulty, Effects, GOLD, Locomotion, Placement, Runtime = Core.api, Core.BossSystem, Core.Config, Core.Difficulty, Core.Effects, Core.GOLD, Core.Locomotion, Core.Placement, Core.Runtime
local Story, Time, addPart, alive, launchEcho, pruneEchoes, random, recordFor, records = Core.Story, Core.Time, Core.addPart, Core.alive, Core.launchEcho, Core.pruneEchoes, Core.random, Core.recordFor, Core.records
local send = Core.send

 
local LastMinuteVFX = require(script.Parent.LastMinuteVFX)
local function closeEchoes(state)
	if not state or state.Closed then
		return
	end
	state.Closed = true
	if state.Queue then
		table.clear(state.Queue)
	end
	for _, cast in ipairs(state.Active) do
		cast:Dispose()
	end
	table.clear(state.Active)
end
local function clockSweep(actor, cast, boundary, final)
	local root = actor:FindFirstChild("HumanoidRootPart")
	local bounds = Placement.GetBounds()
	if not root or not bounds then
		return
	end
	local floor = Placement.GroundPoint(root.Position, { Margin = 4, Clamp = true })
	if not floor then
		return
	end
	local radius = math.sqrt(bounds.Width ^ 2 + bounds.Depth ^ 2)
	local center = floor + Vector3.new(0, 1, 0)
	local initial = random:NextNumber(0, math.pi * 2)
	local duration = Config.LastMinuteSweepDuration
	local warning = Config.LastMinuteSweepWarning
	 
	 
	local releaseAt = final and boundary - duration or boundary
	local warningAt = releaseAt - warning
	local bar
	local sweepVFX
	local function frame(angle)
		return CFrame.new(center) * CFrame.Angles(0, angle, 0)
	end
	cast:Schedule(math.max(0, warningAt), function()
		if not cast:Alive() or not actor:GetAttribute("LastMinuteActive") then
			return
		end
		local floorAtWarning = Placement.GroundPoint(root.Position, { Margin = 4, Clamp = true })
		if not floorAtWarning then
			return
		end
		center = floorAtWarning + Vector3.new(0, 1, 0)
		bar = addPart(
			cast,
			"LastMinuteClockHandSweep",
			frame(initial),
			Vector3.new(Config.LastMinuteSweepWidth, 2, radius * 2),
			GOLD,
			0.8
		)
		bar:SetAttribute("TimeStopExempt", true)
		sweepVFX = LastMinuteVFX.Sweep(cast, bar, warning)
		send(
			"LastMinuteSweepWarning",
			{ Origin = center, Angle = initial, Duration = warning, Width = Config.LastMinuteSweepWidth }
		)
	end)
	cast:Schedule(math.max(0, releaseAt), function()
		if not bar or not bar.Parent or not cast:Alive() or not actor:GetAttribute("LastMinuteActive") then
			return
		end
		if sweepVFX then
			sweepVFX:Release()
		end
		bar.Transparency = 0.12
		local began = cast:Now()
		local previous = initial
		local hits = {}
		local Encounter = require(BossSystem.Players.PlayerEncounter)
		cast:Step(function(_, now)
			if not bar.Parent or not actor:GetAttribute("LastMinuteActive") then
				return false
			end
			local t = math.clamp((now - began) / duration, 0, 1)
			local angle = initial + t * math.pi
			bar.CFrame = frame(angle)
			local samples = math.clamp(math.ceil(math.abs(angle - previous) / (math.pi / 90)), 1, 90)
			for _, character in ipairs(Runtime.Characters()) do
				local h = character:FindFirstChildOfClass("Humanoid")
				local r = character:FindFirstChild("HumanoidRootPart")
				if r and h and h.Health > 0 and not hits[character] and Placement.Contains(r.Position, 2) then
					 
					 
					local feet = r.Position - Vector3.new(0, 2.5, 0)
					for sample = 1, samples do
						local point = frame(previous + (angle - previous) * sample / samples):PointToObjectSpace(feet)
						if
							math.abs(point.X) <= bar.Size.X * 0.5 + r.Size.X * 0.5
							and math.abs(point.Y) <= bar.Size.Y * 0.5 + 0.5
							and math.abs(point.Z) <= bar.Size.Z * 0.5 + r.Size.Z * 0.5
						then
							hits[character] = true
							Encounter.Damage(character, Config.LastMinuteSweepDamage, actor)
							-- Borrowed Time: a hand that catches someone takes seconds back onto the clock
							local reclaim = Config.LastMinuteSweepReclaim or 0
							local full = actor:GetAttribute("LastMinuteTimeShield") or 0
							if reclaim > 0 and full > 0 then
								local perSecond = Config.LastMinuteShieldPerSecond or 70
								actor:SetAttribute("Shield", math.min(full, (actor:GetAttribute("Shield") or 0) + reclaim * perSecond))
								if not actor:GetAttribute("LastMinuteReclaimSaid") then
									actor:SetAttribute("LastMinuteReclaimSaid", true)
									pcall(Encounter.Say, "That second was mine. I'll take it back.", nil, { Duration = 2.5 })
								end
							end
							if sweepVFX then
								sweepVFX:Hit(feet)
							end
							break
						end
					end
				end
			end
			previous = angle
			if t >= 1 then
				if sweepVFX then
					sweepVFX:Finish()
					sweepVFX = nil
				end
				cast.objects[bar] = nil
				Effects.Release(bar)
				bar = nil
				table.clear(hits)
				return false
			end
			return true
		end)
	end)
end
local function startLastMinuteCollapse(actor, record)
	if
		not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or actor:GetAttribute("LastMinuteActive")
		or records[actor] ~= record
		or not actor:GetAttribute("LastMinuteUsed")
		or not actor:GetAttribute("ShieldDamageLocked")
	then
		return false
	end
	Time.ClearRates(actor)
	actor:SetAttribute("LastMinutePreparing", false)
	actor:SetAttribute("LastMinuteActive", true)
	-- Borrowed Time: the shield becomes the clock. Every point the players break steals 1/perSecond
	-- of a second from the countdown; breaking it all ends the minute early.
	local perSecond = Config.LastMinuteShieldPerSecond or 70
	local timeShield = math.max(1, math.floor(Config.LastMinuteDuration * perSecond * (Difficulty.Get(actor).Shield or 1)))
	actor:SetAttribute("ShieldDamageLocked", false)
	actor:SetAttribute("Shield", timeShield)
	actor:SetAttribute("LastMinuteTimeShield", timeShield)
	actor:SetAttribute("LastMinuteReclaimSaid", false)
	actor:SetAttribute("LastMinuteAttackMultiplier", Config.LastMinuteStages[1].IntervalMultiplier)
	actor:SetAttribute("LastMinutePhase25Weight", Config.LastMinuteStages[1].Phase25Weight)
	actor:SetAttribute("LastMinuteMissingFrameCount", 0)
	actor:SetAttribute(
		"LastMinuteMissingFrameReadyAt",
		workspace:GetServerTimeNow() + Config.MissingFrameLastMinuteSpacing
	)
	actor:SetAttribute("LastMinuteStage", 1)
	actor:SetAttribute("LastMinuteRevolution", 1)
	local startedAt = workspace:GetServerTimeNow()
	local ends = startedAt + Config.LastMinuteDuration
	actor:SetAttribute("LastMinuteEndsAt", ends)
	workspace:SetAttribute("LastMinuteEndsAt", ends)
	workspace:SetAttribute("LastMinuteActive", true)
	actor:SetAttribute(
		"NextAttackAt",
		math.min(actor:GetAttribute("NextAttackAt") or ends, workspace:GetServerTimeNow() + 0.1)
	)
	local cast = Effects.NewCast(actor, "LastMinuteCollapse", Config.LastMinuteDuration + 0.8)
	cast.TimeStopExempt = true
	record.LastMinute = cast
	local generation = actor:GetAttribute("PhaseGeneration") or 0
	local root = actor.HumanoidRootPart
	local function followingClockFrame()
		local forward = root.CFrame.LookVector
		forward = Vector3.new(forward.X, 0, forward.Z)
		if forward.Magnitude < 0.001 then
			forward = Vector3.new(0, 0, -1)
		else
			forward = forward.Unit
		end
		local position = root.Position
			+ Vector3.new(0, Config.LastMinuteClockHeight, 0)
			- forward * Config.LastMinuteClockBehindOffset
		return CFrame.lookAt(position, position + forward)
	end
	local clockFrame = followingClockFrame()
	local clockPosition = clockFrame.Position
	local radius = Config.LastMinuteClockRadius
	local clockScale = radius / 50
	local face = addPart(
		cast,
		"AncientRomanTemporalClock",
		clockFrame,
		Vector3.new(Config.LastMinuteClockDiameter, Config.LastMinuteClockDiameter, 0.1),
		GOLD,
		1
	)
	face:SetAttribute("TimeStopExempt", true)
	local attachments, beams, cracks = {}, {}, {}
	for index = 1, 24 do
		local a = Instance.new("Attachment")
		local theta = (index - 1) * math.pi * 2 / 24
		a.Position = Vector3.new(math.cos(theta) * radius, math.sin(theta) * radius, 0)
		a.Parent = face
		attachments[index] = a
	end
	for index = 1, 24 do
		local b = Instance.new("Beam")
		b.Name = "LastMinuteAncientClockRim"
		b.Attachment0 = attachments[index]
		b.Attachment1 = attachments[index % 24 + 1]
		b.Width0 = 0.8 * clockScale
		b.Width1 = b.Width0
		b.LightEmission = 1
		b.FaceCamera = true
		b.Segments = 1
		b.Color = ColorSequence.new(GOLD, Color3.fromRGB(175, 113, 25))
		b.Transparency = NumberSequence.new(0.1)
		b:SetAttribute("TimeStopExempt", true)
		b.Parent = face
		beams[index] = b
	end
	 
	 
	for index = 1, 12 do
		local a = Instance.new("Attachment")
		local theta = index * 2.399963
		a.Position = Vector3.new(math.cos(theta) * radius * 0.18, math.sin(theta) * radius * 0.18, 0)
		a.Parent = face
		local b = Instance.new("Beam")
		b.Name = "LastMinuteClockCrack"
		b.Attachment0 = a
		b.Attachment1 = attachments[(index * 2) % 24 + 1]
		b.Width0 = 0.14 * clockScale
		b.Width1 = 0.5 * clockScale
		b.LightEmission = 1
		b.FaceCamera = true
		b.Segments = 1
		b.Color = ColorSequence.new(Color3.fromRGB(255, 249, 178), GOLD)
		b.Transparency = NumberSequence.new(1)
		b:SetAttribute("TimeStopExempt", true)
		b.Parent = face
		cracks[index] = b
	end
	local hands = {
		addPart(cast, "RomanClockSecondHand", face.CFrame, Vector3.new(0.8, 40, 0.6) * clockScale, GOLD, 0.05),
		addPart(
			cast,
			"RomanClockHourHand",
			face.CFrame,
			Vector3.new(1.2, 24, 0.7) * clockScale,
			Color3.fromRGB(215, 159, 41),
			0.1
		),
	}
	local center = addPart(cast, "RomanClockCenter", clockFrame, Vector3.new(2.6, 2.6, 0.8) * clockScale, GOLD, 0.05)
	center.Shape = Enum.PartType.Ball
	local numerals = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII" }
	local labels = {}
	for _, side in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "RomanClockFace"
		gui.CanvasSize = Vector2.new(1024, 1024)
		gui.Face = side
		gui.LightInfluence = 0
		gui.AlwaysOnTop = false
		gui.Parent = face
		for index, numeral in ipairs(numerals) do
			local theta = index * math.pi * 2 / 12
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Size = UDim2.fromOffset(100, 100)
			label.Position = UDim2.fromScale(0.5 + math.sin(theta) * 0.365, 0.5 - math.cos(theta) * 0.365)
			label.Font = Enum.Font.Garamond
			label.TextSize = 86
			label.TextColor3 = GOLD
			label.TextStrokeColor3 = Color3.fromRGB(88, 49, 6)
			label.TextStrokeTransparency = 0.2
			label.Text = numeral
			label.Parent = gui
			table.insert(labels, { Label = label, Theta = theta, Index = index })
		end
	end
	for _, object in ipairs(hands) do
		object:SetAttribute("TimeStopExempt", true)
	end
	center:SetAttribute("TimeStopExempt", true)
	local lastMinuteVFX = LastMinuteVFX.Clock(actor, cast, {
		Face = face,
		Hands = hands,
		Center = center,
		Attachments = attachments,
		Labels = labels,
		Radius = radius,
		Scale = clockScale,
	})
	local began = cast:Now()
	local accumulated = 0
	local resolved = false
	local ending = false
	local lastTick = 0
	local stageIndex = 1
	local nextVisual = 0
	local completedRevolutions = 0
	local Clones = require(BossSystem.Mechanics.Clones.CloneController)
	local echoes = {
		Cast = cast,
		Active = {},
		Queue = {},
		Closed = false,
		Replaying = false,
		NextLaunchAt = began,
		VFX = lastMinuteVFX,
	}
	record.Echoes = echoes
	local pressure = { Active = {}, NextAt = began + 1.4, Sequence = 0 }
	local Projectile = require(BossSystem.Combat.ProjectileService)
	local targeting = require(BossSystem.Combat.AttackRegistry).For(actor, "P1NormalSlash")
	local function pressureVolley(stage)
		pruneEchoes(pressure)
		if
			#pressure.Active >= Config.LastMinutePressureMaxActive
			or actor:GetAttribute("ExecutionLocked")
			or actor:GetAttribute("PhaseTransitionInProgress")
			or Time.IsStopped(actor)
		then
			return false
		end
		local character = targeting.GetTarget()
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		if not alive(character) or not targetRoot then
			return false
		end
		pressure.Sequence += 1
		local kind = pressure.Sequence % 3 == 0 and "Time" or "Golden"
		local count = math.min(
			kind == "Time" and math.ceil(stage.PressureCount * 0.5) or stage.PressureCount,
			Projectile.Capacity(actor, kind)
		)
		if count <= 0 then
			return false
		end
		local positions = {}
		local axis = random:NextNumber(0, math.pi * 2)
		local aim = targetRoot.Position
		for index = 1, count do
			 
			 
			local angle = axis + (index % 2 == 0 and math.pi * 0.8 or 0) + (index / count - 0.5) * 0.7
			local distance = random:NextNumber(40, 65)
			local ground
			for attempt = 1, 4 do
				local candidate = aim + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
				local point = Placement.GroundPoint(candidate, { Margin = 5, Clamp = true })
				local valid = point and Vector3.new(point.X - aim.X, 0, point.Z - aim.Z).Magnitude >= 24
				if valid then
					for _, previous in ipairs(positions) do
						if Vector3.new(previous.X - point.X, 0, previous.Z - point.Z).Magnitude < 2.5 then
							valid = false
							break
						end
					end
				end
				if valid then
					ground = point
					break
				end
				angle += 2.399963
			end
			if not ground then
				return false
			end
			positions[index] = ground + Vector3.new(0, 3.5 + (index % 3) * 0.45, 0)
		end
		local result = Projectile.Burst(actor, character, {
			Kind = kind,
			Count = count,
			SpawnPositions = positions,
			PreparedAim = aim,
			Speed = Config.LastMinutePressureSpeed,
			Damage = Config.LastMinutePressureDamage,
			Skill = kind == "Time" and "P2TimeBullets" or "P2GoldenBullets",
			LockedTrajectory = true,
			LaunchDelay = Config.LastMinutePressureWarning,
			NoMuzzleFlash = true,
			SpreadDegrees = 8,
			MaxHits = 3,
			FlightLifetime = 2.5,
			CollapsePause = stageIndex >= 3 and 0.18 or 0,
		})
		if type(result) == "table" and result.Cast then
			table.insert(pressure.Active, result.Cast)
			actor:SetAttribute("LastMinutePressureVolleys", (actor:GetAttribute("LastMinutePressureVolleys") or 0) + 1)
			return true
		end
		return false
	end
	 -- sweeps are released as the clock (real time + stolen time) crosses each revolution
	local shownStolen, stoleAll, midnightSwept, endedAt = 0, false, false, 0
	local SWEEP_LEAD = Config.LastMinuteSweepWarning + 0.05
	local function finish(normal)
		if resolved then
			return
		end
		resolved = true
		closeEchoes(echoes)
		closeEchoes(pressure)
		if record.Echoes == echoes then
			record.Echoes = nil
		end
		actor:SetAttribute("LastMinutePreparing", false)
		actor:SetAttribute("LastMinuteActive", false)
		actor:SetAttribute("ShieldDamageLocked", false)
		actor:SetAttribute("LastMinuteAttackMultiplier", 1)
		actor:SetAttribute("LastMinuteEndsAt", 0)
		actor:SetAttribute("LastMinutePhase25Weight", 1)
		actor:SetAttribute("LastMinuteStage", 0)
		actor:SetAttribute("LastMinuteMissingFrameInterval", nil)
		actor:SetAttribute("LastMinuteRevolution", 0)
		actor:SetAttribute("LastMinuteMissingFrameReadyAt", 0)
		workspace:SetAttribute("LastMinuteActive", false)
		workspace:SetAttribute("LastMinuteEndsAt", 0)
		send("LastMinuteEnd", { Completed = normal == true })
		if
			alive(actor)
			and actor:GetAttribute("Phase") == 2.5
			and not actor:GetAttribute("Phase3IntroActive")
			and (actor:GetAttribute("PhaseGeneration") or 0) == generation
		then
			if normal then
				pcall(function()
					require(BossSystem.Players.PlayerEncounter).Say(stoleAll and "...You stole my last minute. Then take the next hour too." or "Time's up.", nil, { Duration = 3 })
				end)
				actor:SetAttribute("LastMinuteCompleted", true)
				send("Shake", { Origin = root.Position, Radius = 450, Duration = 0.65, Intensity = 1.6 })
				actor:SetAttribute("Shield", 0)
				require(BossSystem.Presentation.CharacterEffects).ShieldBreak(actor)
				require(BossSystem.Phases.PhaseController).ShieldBroken(actor)
			elseif not cast.CancelReason then
				task.defer(api.RecoverLastMinute, actor, "Interrupted countdown")
			end
		end
	end
	cast.OnDispose = function()
		if record.LastMinute == cast then
			record.LastMinute = nil
		end
		 
		 
		finish(false)
	end
	cast:Step(function(dt, now)
		if
			not alive(actor)
			or actor:GetAttribute("Phase") ~= 2.5
			or (actor:GetAttribute("PhaseGeneration") or 0) ~= generation
		then
			cast:Dispose()
			return false
		end
		local shieldNow = actor:GetAttribute("Shield") or 0
		local stolen = math.clamp((timeShield - shieldNow) / perSecond, 0, Config.LastMinuteDuration)
		if shieldNow <= 1 then
			stolen = Config.LastMinuteDuration
			stoleAll = true
		end
		if math.abs(stolen - shownStolen) >= 0.05 then
			shownStolen = stolen
			local endsAt = startedAt + Config.LastMinuteDuration - stolen
			actor:SetAttribute("LastMinuteEndsAt", endsAt)
			workspace:SetAttribute("LastMinuteEndsAt", endsAt)
			actor:SetAttribute("LastMinuteStolen", stolen)
		end
		local elapsed = ending and Config.LastMinuteDuration + (now - endedAt) or math.min(now - began + stolen, Config.LastMinuteDuration)
		local follow = 1 - math.exp(-math.min(dt, 0.15) * Config.LastMinuteClockFollowResponsiveness)
		clockFrame = clockFrame:Lerp(followingClockFrame(), follow)
		clockPosition = clockFrame.Position
		local tremble = stageIndex >= 4 and math.sin(elapsed * 55) * 0.3 * (stageIndex - 3) or 0
		face.CFrame = clockFrame * CFrame.new(tremble, math.sin(elapsed * 61) * math.abs(tremble), 0)
		center.CFrame = face.CFrame
		while Config.LastMinuteStages[stageIndex + 1] and elapsed >= Config.LastMinuteStages[stageIndex + 1].At do
			stageIndex += 1
			local stage = Config.LastMinuteStages[stageIndex]
			actor:SetAttribute("LastMinuteStage", stageIndex)
			actor:SetAttribute("LastMinuteRevolution", stageIndex)
			actor:SetAttribute("LastMinuteAttackMultiplier", stage.IntervalMultiplier)
			actor:SetAttribute("LastMinutePhase25Weight", stage.Phase25Weight)
			send("LastMinuteStage", { Stage = stageIndex, Origin = clockPosition })
		end
		local tick = math.min(Config.LastMinuteDuration, math.floor(elapsed))
		local burst = tick - lastTick > 3
		local pendingSweep = nil
		while lastTick < tick and not ending do
			lastTick += 1
			local revolution = math.ceil(lastTick / Config.LastMinuteRevolutionDuration)
			if not burst or lastTick == tick then
				send("LastMinuteTick", {
				Stage = stageIndex,
					Revolution = revolution,
					NumeralIndex = (lastTick - 1) % 12 + 1,
					Final = lastTick == Config.LastMinuteDuration,
					Origin = clockPosition,
				})
				if lastMinuteVFX then
					lastMinuteVFX.Tick(lastTick, stageIndex)
				end
			end
			if lastTick % Config.LastMinuteRevolutionDuration == 0 then
				completedRevolutions = revolution
				pendingSweep = revolution
				send(
					"LastMinuteRevolution",
					{ Revolution = revolution, Final = revolution == 5, Origin = clockPosition }
				)
				if lastMinuteVFX then
					lastMinuteVFX.Revolution(revolution, revolution == 5)
				end
				send(
					"Shake",
					{
						Origin = root.Position,
						Radius = 450,
						Duration = 0.2 + revolution * 0.045,
						Intensity = 0.35 + revolution * 0.18,
					}
				)
			end
			if lastTick == 59 then
				send("LastMinuteVisualHitch", { Duration = 0.15, Origin = clockPosition })
			end
		end
		if pendingSweep and pendingSweep < 5 and not ending then
			clockSweep(actor, cast, SWEEP_LEAD, false)
		end
		 -- midnight: one last sweep timed to finish as the clock runs out
		if not midnightSwept and not ending
			and elapsed >= Config.LastMinuteDuration - (SWEEP_LEAD + Config.LastMinuteSweepDuration + 0.2) then
			midnightSwept = true
			clockSweep(actor, cast, SWEEP_LEAD, false)
		end
		for index, hand in ipairs(hands) do
			 
			 
			local angle = -lastTick * math.pi * 2 / (index == 1 and Config.LastMinuteRevolutionDuration or 144)
			if stageIndex >= 3 and not ending then
				local phase = elapsed - math.floor(elapsed)
				if phase > 0.72 and phase < 0.86 then
					angle += math.pi / 6 * (phase - 0.72) / 0.14
				end
			end
			if ending then
				angle -= math.max(0, elapsed - Config.LastMinuteDuration) * 22
			end
			hand.CFrame = face.CFrame * CFrame.Angles(0, 0, angle) * CFrame.new(0, hand.Size.Y * 0.5, 0.15 * index)
		end
		if elapsed >= nextVisual then
			nextVisual = elapsed + 0.05
			local collapse = ending and math.clamp((elapsed - Config.LastMinuteDuration) / 0.5, 0, 1) or 0
			for index, attachment in ipairs(attachments) do
				local theta = (index - 1) * math.pi * 2 / 24
				local detached = completedRevolutions >= 3 and index % 3 == 0
				local orbit = detached and elapsed * 0.22 or 0
				local spread = 1 + collapse * 0.8 + (detached and 0.12 + 0.06 * math.sin(elapsed * 2 + index) or 0)
				attachment.Position = Vector3.new(
					math.cos(theta + orbit) * radius * spread,
					math.sin(theta + orbit) * radius * spread,
					detached and math.sin(elapsed + index) * 8 or 0
				)
				local beam = beams[index]
				beam.Transparency = NumberSequence.new(
					ending and collapse or 0.06 + 0.13 * (1 + math.sin(elapsed * (8 + stageIndex * 3) + index)) * 0.5
				)
				beam.Width0 = (0.8 + stageIndex * 0.08) * clockScale
				beam.Width1 = beam.Width0
			end
			for index, crack in ipairs(cracks) do
				crack.Transparency =
					NumberSequence.new(ending and collapse or index <= completedRevolutions * 3 and 0.08 or 1)
			end
			for _, data in ipairs(labels) do
				local label = data.Label
				local drift = completedRevolutions >= 3 and elapsed * 0.11 or 0
				local distance = 0.365
					+ (completedRevolutions >= 4 and 0.045 * math.sin(elapsed * 2 + data.Index) or 0)
					+ collapse * 0.3
				local jitter = elapsed >= 58 and math.sin(elapsed * 55 + data.Index) * 0.01 or 0
				label.Position = UDim2.fromScale(
					0.5 + math.sin(data.Theta + drift) * distance + jitter,
					0.5 - math.cos(data.Theta + drift) * distance
				)
				label.Rotation = completedRevolutions >= 4 and math.sin(elapsed * 4 + data.Index) * 15 or 0
				label.TextTransparency = collapse
				label.TextStrokeTransparency = 0.2 + 0.8 * collapse
			end
			if ending then
				for _, hand in ipairs(hands) do
					hand.Transparency = collapse
				end
				center.Transparency = collapse
			end
		end
		if ending then
			return true
		end
		if now >= pressure.NextAt then
			local stage = Config.LastMinuteStages[stageIndex]
			pressure.NextAt = now + stage.PressureInterval
			pressureVolley(stage)
		end
		pruneEchoes(echoes)
		if
			echoes.Queue[1]
			and echoes.Queue[1].At <= now
			and now >= echoes.NextLaunchAt
			and #echoes.Active < Config.LastMinuteEchoMaxActive
		then
			local job = table.remove(echoes.Queue, 1)
			if now - job.At < 2 then
				launchEcho(actor, echoes, job)
			end
		end
		accumulated += dt
		if accumulated >= 0.15 then
			local stage = Config.LastMinuteStages[stageIndex]
			local advance = stage.TemporalAdvance * math.min(accumulated, 0.3)
			accumulated = 0
			Time.AdvanceDeferred(actor, advance, false, { MaxCount = 4 })
			Clones.AdvanceDeferred(actor, advance, false, 4)
			if stageIndex == #Config.LastMinuteStages then
				Time.FlushDeferred(actor, { MaxCount = 4, Interval = 0.15 })
				Clones.AdvanceDeferred(actor, 60, true, 4)
			end
		end
		if elapsed >= Config.LastMinuteDuration then
			ending = true
			endedAt = now
			closeEchoes(echoes)
			closeEchoes(pressure)
			Time.FlushDeferred(actor, { MaxCount = 4, Interval = 0.15 })
			Clones.AdvanceDeferred(actor, 60, true, 4)
			actor:SetAttribute("LastMinuteAttackMultiplier", 1)
			if lastMinuteVFX then
				lastMinuteVFX.Shatter()
			end
			send("LastMinuteShatter", { Origin = clockPosition })
			cast:Schedule(0.5, function()
				finish(true)
				cast:Dispose()
			end)
		end
		return true
	end)
	send("LastMinute", { ClockOnly = true, Stage = 1, Origin = clockPosition })
	pcall(function()
		require(BossSystem.Players.PlayerEncounter).Say("Every blow you land steals a second from me. Spend them wisely.", nil, { Duration = 3.4 })
	end)
	return true
end

function api.BeginLastMinute(actor)
  
 if alive(actor) and actor:GetAttribute("Phase") == 2.5 and not Difficulty.Get(actor).Ultimates then
  if actor:GetAttribute("PhaseTransitionInProgress") then return false end
  actor:SetAttribute("LastMinuteUsed", true)
  actor:SetAttribute("LastMinuteCompleted", true)
  actor:SetAttribute("Shield", 0)
  return require(BossSystem.Phases.PhaseController).BeginPhase3(actor)
 end
	if
		not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or actor:GetAttribute("LastMinuteUsed")
		or actor:GetAttribute("LastMinuteActive")
		or actor:GetAttribute("LastMinutePreparing")
	then
		return false
	end
	local shield = actor:GetAttribute("Shield") or 0
	if shield <= 0 or shield > Config.LastMinuteShieldGate then
		return false
	end
	local record = recordFor(actor)
	local ultimates = require(BossSystem.Combat.UltimateService)
	if not ultimates.Ready(actor) then
		if not record.UltimateQueued then
			record.UltimateQueued = true
			actor:SetAttribute("LastMinuteQueued", true)
			task.spawn(function()
				while records[actor] == record and alive(actor) and actor:GetAttribute("Phase") == 2.5
						and not actor:GetAttribute("LastMinuteUsed") and (actor:GetAttribute("Shield") or 0) > 0 do
					if ultimates.Ready(actor) then
						record.UltimateQueued = false
						actor:SetAttribute("LastMinuteQueued", false)
						api.BeginLastMinute(actor)
						return
					end
					game:GetService("RunService").Heartbeat:Wait()
				end
				record.UltimateQueued = false
				if actor.Parent then actor:SetAttribute("LastMinuteQueued", false) end
			end)
		end
		return false
	end
	local ultimateHandle = ultimates.Begin(actor, "P2.5LastMinute(Ultimate)")
	if not ultimateHandle then return false end
	if record.Transition then record.Transition:Dispose() end
	 
	 
	actor:SetAttribute("LastMinuteUsed", true)
	actor:SetAttribute("ShieldDamageLocked", true)
	actor:SetAttribute("Shield", Config.LastMinuteShieldGate)
	actor:SetAttribute("LastMinutePreparing", true)
	actor:SetAttribute("PhaseTransitionInProgress", true)
	actor:SetAttribute("TransitionKeepsTemporal", true)
	actor:SetAttribute("Invulnerable", true)
	actor:SetAttribute("AttackInProgress", true)
	actor:SetAttribute("ActiveAttackToken", nil)
	actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
	local generation = actor:GetAttribute("PhaseGeneration") or 0
	local root = actor.HumanoidRootPart
	local frame = Placement.Validate(actor, root.CFrame) or root.CFrame
	local lines = Story.LastMinute
		or { "Hm...", "Looks like we're running out of time.", "Then let's make this last minute count." }
	local preludeDuration = Story.Duration(lines)
	local prelude = Effects.NewCast(actor, "LastMinutePrelude", preludeDuration + 1)
	prelude.TimeStopExempt = true
	record.Transition = prelude
	local completed = false
	local pose = Locomotion.Pose(actor, { RightShoulder = { 15, 0, -15 }, LeftShoulder = { 0, 0, -8 } }, 0.2, true)
	local function owns()
		return alive(actor)
			and actor:GetAttribute("Phase") == 2.5
			and records[actor] == record
			and (actor:GetAttribute("PhaseGeneration") or 0) == generation
			and not actor:GetAttribute("Phase3IntroActive")
	end
	local function retryGate()
		if owns() and not prelude.CancelReason then
			task.defer(api.RecoverLastMinute, actor, "Interrupted opening")
		end
	end
	prelude:Step(function()
		if not owns() then
			prelude:Dispose()
			return false
		end
		root.CFrame = frame
		root.AssemblyLinearVelocity = Vector3.zero
		return true
	end)
	prelude.OnDispose = function()
		if record.Transition ~= prelude then
			return
		end
		record.Transition = nil
		actor:SetAttribute("LastMinutePreparing", false)
		local valid = owns()
		if valid then
			actor:SetAttribute("PhaseTransitionInProgress", false)
			actor:SetAttribute("TransitionKeepsTemporal", false)
			actor:SetAttribute("Invulnerable", false)
			actor:SetAttribute("AttackInProgress", false)
			actor:SetAttribute("AIEnabled", true)
			actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.15)
		end
		local ok, err = pcall(Locomotion.ReleasePose, actor, pose, 0.18)
		if not ok then
			warn("Last Minute prelude pose cleanup: " .. tostring(err))
		end
		if not completed then
			retryGate()
		end
	end
	task.spawn(function()
		local ok, result = xpcall(function()
			LastMinuteVFX.Prelude(actor, prelude, preludeDuration)
			return Story.Play(actor, lines, {
				Prefix = "LastMinute",
				Valid = function()
					return prelude:Alive() and owns()
				end,
			})
		end, debug.traceback)
		if not ok then
			warn("Last Minute prelude: " .. tostring(result))
		end
		completed = ok and result == true and prelude:Alive() and owns()
		prelude:Dispose()
		if completed and owns() then
			local startedOk, started = xpcall(startLastMinuteCollapse, debug.traceback, actor, record)
			if not startedOk then
				warn("Last Minute construction: " .. tostring(started))
				local partial = record.LastMinute
				if partial then
					record.LastMinute = nil
					partial:Dispose()
				end
				closeEchoes(record.Echoes)
				record.Echoes = nil
				if owns() then
					actor:SetAttribute("LastMinuteActive", false)
					actor:SetAttribute("LastMinuteEndsAt", 0)
					actor:SetAttribute("LastMinuteAttackMultiplier", 1)
					actor:SetAttribute("LastMinutePhase25Weight", 1)
					actor:SetAttribute("LastMinuteStage", 0)
					actor:SetAttribute("LastMinuteRevolution", 0)
					workspace:SetAttribute("LastMinuteActive", false)
					workspace:SetAttribute("LastMinuteEndsAt", 0)
				end
			end
			if not startedOk or not started then
				retryGate()
			end
		end
	end)
	ultimates.Finish(ultimateHandle)
	return true
end

 
 
function api.RecoverLastMinute(actor, reason)
	if not alive(actor) or actor:GetAttribute("Phase") ~= 2.5
		or actor:GetAttribute("Phase3IntroActive") or actor:GetAttribute("LastMinuteCompleted") then return false end
	local record = records[actor]
	if api.IsActive(actor) or (record and record.UltimateQueued) then return false end
	api.Cancel(actor, reason or "Last Minute recovery")
	local ultimates = require(BossSystem.Combat.UltimateService)
	ultimates.Cancel(actor, reason or "Last Minute recovery")
	for _, name in ipairs({ "LastMinuteUsed", "LastMinutePreparing", "LastMinuteActive",
		"Phase25TransitionInProgress", "PhaseTransitionInProgress", "TransitionKeepsTemporal",
		"Invulnerable", "AttackInProgress", "ShieldDamageLocked" }) do actor:SetAttribute(name, false) end
	actor:SetAttribute("LastMinuteEndsAt", 0)
	workspace:SetAttribute("LastMinuteActive", false)
	workspace:SetAttribute("LastMinuteEndsAt", 0)
	actor:SetAttribute("AIEnabled", true)
	actor:SetAttribute("LastMinuteRecoveryReason", reason or "Lost cast")
	actor:SetAttribute("LastMinuteRecoveryCount", (actor:GetAttribute("LastMinuteRecoveryCount") or 0) + 1)
	actor:SetAttribute("Shield", Config.LastMinuteShieldGate)
	api.BeginLastMinute(actor)
	return true
end

return api
