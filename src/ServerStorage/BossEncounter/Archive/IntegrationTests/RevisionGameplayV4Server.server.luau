local BossSystem = game:GetService("ServerScriptService"):WaitForChild("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
print("REVISION_V6_DRIVER_BOOT")
-- Temporary actual Studio server integration driver; removed after testing.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local system = game.ServerScriptService:WaitForChild("BossSystem")
local Registry = require(BossSystem.Combat.AttackRegistry)
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Status = require(BossSystem.Combat.StatusEffectService)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Encounter = require(BossSystem.Players.PlayerEncounter)
local Clones = require(BossSystem.Mechanics.Clones.CloneController)
local Reality = require(BossSystem.Mechanics.Reality.RealityController)
local Phase25 = require(BossSystem.Phases.Phase25Controller)
local Cooldowns = require(BossSystem.Combat.AbilityCooldownService)
local Selector = require(BossSystem.Combat.AttackSelector)
local Sword = require(BossSystem.Players.R6SwordCombat)
local Dash = require(BossSystem.Players.R6DashService)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Arena = require(BossSystem.Encounter.ArenaController)
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local PlayerConfig = require(Shared:WaitForChild("Config"):WaitForChild("PlayerConfig"))
local Immunity = require(BossSystem.Players.PlayerImmunity)
local Phase = require(BossSystem.Phases.PhaseController)
local Phase3Intro = require(BossSystem.Phases.Phase3Intro)
local Weapon = require(BossSystem.Boss.WeaponController)
local remote = Replicated:FindFirstChild("RevisionGameplayV4Test")
local resuming = remote ~= nil and workspace:GetAttribute("EncounterStarted") == true
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "RevisionGameplayV4Test"
	remote.Parent = Replicated
end
local ready, responses = {}, {}
if resuming then
	for _, p in ipairs(Players:GetPlayers()) do
		ready[p] = true
	end
end
local serial = 0
local boss, player, character, humanoid, root
local steps = {}
local function marker(name, ...)
	local message = { Name = name, Data = { ... }, At = workspace:GetServerTimeNow() }
	table.insert(steps, message)
	workspace:SetAttribute("RevisionTestSteps", Http:JSONEncode(steps))
	workspace:SetAttribute("RevisionTestStage", name)
	remote:FireAllClients("TestMarker", { Name = name, Error = name == "FAIL" and tostring(select(1, ...)) or nil })
	local output = { ... }
	for i, value in ipairs(output) do
		if type(value) == "table" then
			output[i] = Http:JSONEncode(value)
		end
	end
	print("REVISION_TEST_" .. name, table.unpack(output))
end
local function waitFor(fn, seconds, message)
	local ends = os.clock() + seconds
	repeat
		local result = fn()
		if result then
			return result
		end
		assert(os.clock() < ends, message or "Test state timed out")
		Run.Heartbeat:Wait()
	until false
end
local function sleep(seconds)
	local ends = os.clock() + seconds
	while os.clock() < ends do
		Run.Heartbeat:Wait()
	end
end
local connection = remote.OnServerEvent:Connect(function(p, kind, id, value)
	if kind == "Ready" then
		ready[p] = true
	elseif p == player and kind == "Done" then
		responses[id] = value
	elseif p == player and kind == "Failure" then
		responses[id] = { Error = tostring(value) }
	end
end)
local function client(kind, data)
	serial += 1
	data = data or {}
	data.Id = serial
	local id = serial
	remote:FireClient(player, kind, data)
	local result = waitFor(function()
		return responses[id]
	end, 20, "Client command failed: " .. kind)
	assert(type(result) ~= "table" or not result.Error, tostring(type(result) == "table" and result.Error))
	return result
end
local function bindCurrent()
	character = waitFor(function()
		local c = player.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		return c
			and c:FindFirstChild("HumanoidRootPart")
			and h
			and h.Health > 0
			and c:GetAttribute("BaseWalkSpeed")
			and c
	end, 15, "Actual player failed to initialize")
	humanoid = character:FindFirstChildOfClass("Humanoid")
	root = character.HumanoidRootPart
end
local function protect()
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if c and h and h.Health > 0 then
			Encounter.CancelDefense(p)
			require(BossSystem.Players.PlayerBlessing).Cancel(p)
			Status.Clear(p)
			Dash.Cancel(p, "Integration preparation")
			c:SetAttribute("RespawnInvulnerableUntil", workspace:GetServerTimeNow() + 600)
			c:SetAttribute("DashInvulnerableUntil", 0)
			c:SetAttribute("Stamina", PlayerConfig.MaxStamina)
			h.Health = h.MaxHealth
			Immunity.Refresh(c)
		end
	end
end
local function pause()
	boss:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 600)
	boss:SetAttribute("CloneEnabled", false)
	boss:SetAttribute("UnstoppableDisabled", true)
	require(BossSystem.Combat.PassiveController).Stop(boss)
end
local holdSelection = true
local hold = Run.Heartbeat:Connect(function()
	if boss and boss.Parent and holdSelection then
		pause()
	end
end)
local function placePlayer(position, lookAt)
	local goal = CFrame.lookAt(position, lookAt or position + Vector3.new(0, 0, -1))
	goal = assert(Placement.Validate(character, goal, { Margin = 6 }), "Invalid player test placement")
	root.CFrame = goal
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	humanoid:Move(Vector3.zero, false)
	return goal
end
local function setPhase(phase)
	boss:SetAttribute("PhaseGeneration", (boss:GetAttribute("PhaseGeneration") or 0) + 1)
	boss:SetAttribute("MovementRevision", (boss:GetAttribute("MovementRevision") or 0) + 1)
	Reality.Cancel(boss)
	Phase25.Cancel(boss, "Test stage")
	Effects.CancelOwner(boss, "Test stage")
	Time.ClearOwner(boss)
	Clones.CancelAll(boss, "Test stage")
	require(BossSystem.Boss.GoldenGuardService).Clear(boss)
	Phase3Intro.ClearVisual(boss)
	Weapon.SetUnarmed(boss, phase == 3)
	boss.Humanoid.Health = Config.BossMaxHealth
	for _, name in ipairs({
		"PhaseTransitionInProgress",
		"Phase25TransitionInProgress",
		"Phase3IntroActive",
		"Phase2ShieldBreakSequenceActive",
		"Phase4TransitionInProgress",
		"ShieldBreakInProgress",
		"ShieldCloneGateActive",
		"Phase4ComboActive",
		"ExecutionLocked",
		"Invulnerable",
		"AttackInProgress",
		"ParryActive",
		"ShieldBroken",
		"LastMinuteUsed",
		"LastMinutePreparing",
		"LastMinuteActive",
		"ShieldDamageLocked",
		"LinkedProtection",
		"Phase3LinkedActive",
		"Phase4LinkedActive",
		"EtherealAcumenActive",
		"FutureSightDodging",
	}) do
		boss:SetAttribute(name, false)
	end
	boss:SetAttribute("ActiveAttackToken", nil)
	boss:SetAttribute("IsGoldenClone", false)
	boss:SetAttribute("Phase15Triggered", true)
	boss:SetAttribute("Phase2Triggered", true)
	boss:SetAttribute("Phase25Triggered", phase >= 2.5)
	boss:SetAttribute("Phase3Triggered", phase >= 3)
	boss:SetAttribute("Phase4Triggered", phase >= 4)
	boss:SetAttribute(
		"PhaseTitleOverride",
		phase == 3 and Config.Phase3Title or phase == 4 and Config.Phase4Title or nil
	)
	boss.Humanoid.DisplayName = phase == 3 and Config.Phase3Title or phase == 4 and Config.Phase4Title or boss.Name
	local shield = phase == 3 and Config.Phase3ShieldMaxHealth or phase == 4 and Config.Phase4ShieldMaxHealth or 5000
	boss:SetAttribute("Shield", shield)
	boss:SetAttribute("MaxShield", shield)
	boss:SetAttribute("Defense", 0)
	boss:SetAttribute("FutureSightCharges", 0)
	boss:SetAttribute("FutureSightReadyAt", 0)
	boss:SetAttribute("Phase", phase)
	boss:SetAttribute("AIEnabled", true)
	Cooldowns.Clear(boss)
	pause()
	protect()
	waitFor(function()
		return Registry.For(boss, "P1CombatCore").Active()
	end, 10, "Cancelled prior attack did not release core")
end
local audioLimitations = {}
local screamAvailable = false
workspace:SetAttribute("RevisionTestFinished", false)
local ok, err = xpcall(function()
	player = waitFor(function()
		local participants = Players:GetPlayers()
		if #participants < 3 then
			return
		end
		for _, p in ipairs(participants) do
			local c = p.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			if
				not ready[p]
				or not c
				or not c:FindFirstChild("HumanoidRootPart")
				or not h
				or h.Health <= 0
				or h.RigType ~= Enum.HumanoidRigType.R6
				or not c:GetAttribute("BaseWalkSpeed")
				or c:GetAttribute("R6AppearanceFinished") ~= true
			then
				return
			end
		end
		return participants[1]
	end, 160, "Three actual initialized R6 test clients never connected")
	bindCurrent()
	protect()
	marker("START", #Players:GetPlayers())
	assert(humanoid.RigType == Enum.HumanoidRigType.R6, "Expected actual R6 client")
	if not resuming then
		local entry = Arena.Ensure()
		placePlayer(entry.PolyStar.Core.Position + Vector3.new(7, 0, 0), entry.PolyStar.Core.Position)
		sleep(1)
		entry.Prompt.PromptButtonHoldBegan:Connect(function(p)
			marker("NATIVE_HOLD_BEGIN", p.Name)
		end)
		entry.Prompt.Triggered:Connect(function(p)
			marker("NATIVE_HOLD_TRIGGER", p.Name)
		end)
		client("NativePrompt", { Duration = 2.25 })
		waitFor(function()
			return workspace:GetAttribute("EncounterStarted")
		end, 5, "Native prompt failed")
	end
	marker("TIMER_STARTED", client("TimerStarted"))
	waitFor(function()
		return workspace:GetAttribute("BossEncounterReady")
	end, 80, "Boss entrance failed")
	boss = assert(workspace:FindFirstChild("alterGolden, the Nothing"))
	pause()
	protect()
	marker("ACTUAL_ENTRANCE_READY")
	local Metadata = require(BossSystem.Combat.AbilityMetadata)
	local names = 0
	for _, name in ipairs(Metadata.ActiveNames) do
		assert(Registry.For(boss, name), "Missing active factory: " .. name)
		names += 1
	end
	for _, name in ipairs(Metadata.TimeStopNames) do
		local module = assert(Registry.Module(name))
		assert(module.Parent == system.Attacks.P2.GoldenClock, "TimeStop mini attack outside P2 folder")
		assert(Registry.For(boss, name))
		names += 1
	end
	assert(
		Registry.Module("P2GoldenClock(Ultimate)").Parent == system.Attacks.P2.GoldenClock,
		"Ultimate not grouped under P2"
	)
	for _, name in ipairs({
		"P2.5StolenSecond",
		"P2.5FalseFuture",
		"P2.5MissingFrame",
		"P2.5LastMinute(Ultimate)",
		"P2.5FutureSight(Passive)",
	}) do
		local meta = assert(Metadata.Get(name))
		assert(not meta.CanClone and not meta.CanHourDebt, "P2.5 copy restriction missing")
		assert(Registry.For(boss, name), "Missing P2.5 factory")
	end
	marker("ALL_FACTORY_AND_FOLDER_WIRING", names)

	do
		setPhase(2.5)
		protect()
		local bounds = assert(Placement.GetBounds())
		boss.HumanoidRootPart.CFrame = assert(Placement.Validate(boss, CFrame.new(bounds.Frame.Position)))
		placePlayer(boss.HumanoidRootPart.Position + Vector3.new(0, 0, -24), boss.HumanoidRootPart.Position)
		local gun = assert(Registry.For(boss, "P2.5CircularBarrage"))
		local before = boss:GetAttribute("CircularBarrageBeamsReleased") or 0
		local shots = boss:GetAttribute("CircularBarrageShotsReleased") or 0
		local finished, result, held, beams = false, nil, false, 0
		task.spawn(function()
			result = gun.Combo(character)
			finished = true
		end)
		waitFor(function()
			return boss:GetAttribute("CircularBarrageGunHeld")
		end, 2, "Barrage never held its gun")
		local observed = waitFor(function()
			return Runtime.Effects:FindFirstChild("CircularBarrageGrip", true)
		end, 2, "Gun grip missing")
		local arm = boss:FindFirstChild("Right Arm") or boss:FindFirstChild("RightHand")
		assert(arm and (observed.Position - arm.Position).Magnitude < 4, "Gun floated away from the boss arm")
		held = true
		local deadline = os.clock() + 8
		repeat
			if Runtime.Effects:FindFirstChild("CircularBarrageBeam", true) then
				beams += 1
			end
			assert(
				not Runtime.Effects:FindFirstChild("GoldenBullet", true),
				"Gun barrage still emits travelling bullets"
			)
			assert(os.clock() < deadline, "Finite beam barrage did not finish")
			Run.Heartbeat:Wait()
		until finished
		assert(result and held and beams > 0, "Beam barrage failed its actual visual sequence")
		assert(
			(boss:GetAttribute("CircularBarrageBeamsReleased") or 0) - before == Config.CircularBarrageShotCount,
			"Beam count unbounded/incorrect"
		)
		assert(
			(boss:GetAttribute("CircularBarrageShotsReleased") or 0) - shots == 24
				and boss:GetAttribute("CircularBarrageSpinDegrees") == 360,
			"Gun did not complete finite 360-degree turn"
		)
		assert(not boss:GetAttribute("CircularBarrageGunHeld"), "Barrage gun hold state leaked")
		marker("V5_HAND_HELD_GUN_24_SERVER_BEAMS_LEFT_360", beams)
	end

	do
		setPhase(4)
		protect()
		local bounds = assert(Placement.GetBounds())
		boss.HumanoidRootPart.CFrame = assert(Placement.Validate(boss, CFrame.new(bounds.Frame.Position)))
		boss:SetAttribute("ParryActive", false)
		boss:SetAttribute("Invulnerable", false)
		boss:SetAttribute("Defense", 0)
		local oldRange = 8
		local goal =
			assert(Placement.Validate(character, CFrame.new(boss.HumanoidRootPart.Position + Vector3.new(0, 0, 8.7))))
		root.CFrame = CFrame.lookAt(goal.Position, boss.HumanoidRootPart.Position)
		root.AssemblyLinearVelocity = Vector3.zero
		assert(
			Sword.Range == PlayerConfig.Sword.HitRange and Sword.Range > oldRange and Sword.Range <= 10,
			"Sword modest centralized reach not wired"
		)
		local shield = boss:GetAttribute("Shield")
		assert(
			Sword.Hit(
				character,
				boss,
				root.CFrame,
				{},
				nil,
				{ Direct = true, Kind = "PlayerSword", Attacker = character, Sequence = 9876501 }
			),
			"New sword reach did not hit actual boss at8.7studs"
		)
		assert(
			shield - boss:GetAttribute("Shield") == PlayerConfig.GetSwordDamage(),
			"Sword hitbox changed centralized multiplayer damage"
		)
		root.CFrame = CFrame.lookAt(goal.Position + Vector3.new(0, 0, 0.6), boss.HumanoidRootPart.Position)
		assert(
			not Sword.Hit(
				character,
				boss,
				root.CFrame,
				{},
				nil,
				{ Direct = true, Kind = "PlayerSword", Attacker = character, Sequence = 9876502 }
			),
			"Sword exceeds configured9stud reach"
		)
		marker("V6_ACTUAL_CENTRAL_SWORD_REACH_MULTIPLAYER_DAMAGE_BOUNDARY", Sword.Range, PlayerConfig.GetSwordDamage())
	end

	-- Append inside the V6 actual three-client server driver's xpcall. Reuses its
	-- client UploadedAudioV3/CinematicLockV3 plus ui_audio_v6_client_test_body.luau; no old edits.
	do
		local Audio = require(BossSystem.Presentation.CombatAudio)
		local AudioConfig = require(Shared:WaitForChild("Config"):WaitForChild("CombatAudioConfig"))
		local Story = require(BossSystem.Encounter.EncounterStory)
		local Metadata = require(BossSystem.Combat.AbilityMetadata)
		local bounds = assert(Placement.GetBounds())
		local function living()
			local result, states = {}, {}
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				local h = c and c:FindFirstChildOfClass("Humanoid")
				local r = c and c:FindFirstChild("HumanoidRootPart")
				states[#states + 1] = {
					Player = p.Name,
					Character = c and c.Name or "nil",
					CharacterParent = c and c.Parent and c.Parent:GetFullName() or "nil",
					Health = h and h.Health or -1,
					Root = r and r:GetFullName() or "nil",
					Lives = p:GetAttribute("LivesRemaining"),
					Position = r and { r.Position.X, r.Position.Y, r.Position.Z } or nil,
					InsideArena = r and Arena.Contains(r.Position, 0) or false,
					ExecutionPending = p:GetAttribute("ExecutionPending") == true,
				}
				if c and h and h.Health > 0 and r then
					result[#result + 1] = { Player = p, Character = c, Humanoid = h }
				end
			end
			assert(
				#result >= 3,
				"V6 requires three actual alive initialized clients; stage="
					.. tostring(workspace:GetAttribute("RevisionTestStage"))
					.. "; states="
					.. game:GetService("HttpService"):JSONEncode(states)
			)
			return result
		end
		local function eachClient(kind, data)
			local primary = player
			local results = {}
			local passed, failure = xpcall(function()
				for _, item in ipairs(living()) do
					player = item.Player
					results[player.Name] = client(kind, table.clone(data or {}))
				end
			end, debug.traceback)
			player = primary
			if not passed then
				error(failure, 0)
			end
			return results
		end
		local function rootedParticipants(stage)
			local states = {}
			for _, item in ipairs(living()) do
				local r = assert(
					item.Character:FindFirstChild("HumanoidRootPart"),
					"Missing root at " .. stage .. ": " .. item.Player.Name
				)
				local inside = Arena.Contains(r.Position, 0)
				states[item.Player.Name] = {
					Root = r.Name,
					Position = { r.Position.X, r.Position.Y, r.Position.Z },
					InsideArena = inside,
					Health = item.Humanoid.Health,
					Lives = item.Player:GetAttribute("LivesRemaining"),
				}
				assert(
					inside and r.Position.Y >= bounds.Frame.Y - 10,
					"Player left the arena at "
						.. stage
						.. ": "
						.. item.Player.Name
						.. " "
						.. game:GetService("HttpService"):JSONEncode(states[item.Player.Name])
				)
			end
			return states
		end
		local function groundBoss()
			local frame = assert(Placement.Validate(boss, CFrame.new(bounds.Frame.Position)))
			boss.HumanoidRootPart.CFrame = frame
			boss.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			return frame
		end

		setPhase(1.5)
		protect()
		local standing = groundBoss()
		placePlayer(standing.Position + Vector3.new(0, 0, -18), standing.Position)
		local bow = assert(Registry.For(boss, "P1.5RoyalBow(Ultimate)"))
		local released = boss:GetAttribute("RoyalBowArrowsReleased") or 0
		local impacts = boss:GetAttribute("RoyalBowImpacts") or 0
		local finalImpacts = boss:GetAttribute("RoyalBowFinalImpacts") or 0
		local yellow, particles, chainWarnings, forbidden = 0, 0, 0, {}
		local visualFailure
		local diameters = {}
		local banned = {
			RoyalBowArrowWarning = true,
			RoyalBowFinalWarning = true,
			RoyalBowExecutionCoreWarning = true,
			RoyalBowImpactRing = true,
		}
		local observer = Runtime.Effects.DescendantAdded:Connect(function(object)
			if object:IsA("BasePart") and banned[object.Name] then
				forbidden[#forbidden + 1] = object.Name
			end
			if object:IsA("BasePart") and object.Name == "GroundChainsWarning" and object.Transparency < 1 then
				chainWarnings += 1
			end
			if
				object:IsA("BasePart")
				and (object.Name == "RoyalBowImpactExplosion" or object.Name == "RoyalBowFinisherExplosion")
			then
				local color = object.Color
				local radius = object.Name == "RoyalBowFinisherExplosion" and bow.FinalRadius or bow.ImpactRadius
				local expected = radius * 2
				diameters[object.Name] = object.Size.X
				if math.abs(object.Size.X - expected) > 0.01 or math.abs(object.Size.Z - expected) > 0.01 then
					visualFailure = "Royal Bow impact does not immediately show its real AoE diameter: " .. object.Name
				end
				if color.R > 0.9 and color.G > 0.65 and color.B < 0.3 and object.Transparency >= 0.25 then
					yellow += 1
				end
			elseif object:IsA("ParticleEmitter") and object.Name == "RoyalBowYellowImpactParticles" then
				particles += 1
			end
		end)
		local naturalOK, naturalFailure = xpcall(function()
			local finished, result = false, nil
			task.spawn(function()
				result = bow.Combo(character)
				finished = true
			end)
			waitFor(function()
				return boss.HumanoidRootPart.Position.Y > standing.Y + 65
			end, 8, "Royal Bow did not ascend naturally")
			waitFor(function()
				return finished
			end, 18, "Whole Royal Bow five-arrow sequence did not finish")
			assert(result == true, "Natural Royal Bow Combo failed")
			assert(
				(boss:GetAttribute("RoyalBowArrowsReleased") or 0) - released == 5,
				"Royal Bow did not fire exactly five arrows"
			)
			assert(
				(boss:GetAttribute("RoyalBowImpacts") or 0) - impacts == 5
					and (boss:GetAttribute("RoyalBowFinalImpacts") or 0) - finalImpacts == 1,
				"Royal Bow did not land five impacts including its final execution"
			)
			assert(
				#forbidden == 0,
				"Royal Bow still created arrow warning/radius rings: " .. table.concat(forbidden, ", ")
			)
			assert(yellow == 5 and particles == 5, "Royal Bow yellow explosion/particles absent or excessively white")
			assert(chainWarnings > 0, "Royal Bow did not restore visible chain warnings")
			assert(not visualFailure, visualFailure)
			assert(math.abs(boss.HumanoidRootPart.Position.Y - standing.Y) < 2, "Royal Bow did not return to its floor")
		end, debug.traceback)
		observer:Disconnect()
		assert(naturalOK, naturalFailure)
		marker(
			"V6_ROYAL_BOW_CHAIN_WARNINGS_FIVE_EXACT_RADIUS_YELLOW_IMPACTS",
			{
				Arrows = 5,
				Impacts = 5,
				Yellow = yellow,
				Particles = particles,
				ChainWarnings = chainWarnings,
				Diameters = diameters,
			}
		)

		-- Interrupt during ascent, while animate is actually yielding at Heartbeat.
		setPhase(1.5)
		protect()
		standing = groundBoss()
		local cancelled = false
		task.spawn(function()
			bow.Combo(character)
			cancelled = true
		end)
		waitFor(function()
			return boss.HumanoidRootPart.Position.Y > standing.Y + 10
		end, 8, "Royal cancellation did not enter its ascent")
		boss:SetAttribute("PhaseGeneration", (boss:GetAttribute("PhaseGeneration") or 0) + 1)
		boss:SetAttribute("MovementRevision", (boss:GetAttribute("MovementRevision") or 0) + 1)
		boss:SetAttribute("PhaseTransitionInProgress", true)
		boss:SetAttribute("AIEnabled", false)
		local owned = boss.HumanoidRootPart.CFrame + Vector3.new(12, 0, 0)
		boss.HumanoidRootPart.CFrame = owned
		waitFor(function()
			return cancelled
		end, 2, "Cancelled Royal Bow coroutine retained ownership")
		assert(
			(boss.HumanoidRootPart.Position - owned.Position).Magnitude < 0.05,
			"Royal Bow wrote a stale CFrame after yielding into a transition"
		)
		marker("V6_ROYAL_BOW_POST_HEARTBEAT_CANCELLATION")

		-- Exact uploaded finite assets are required for this gate, not guessed.
		setPhase(1.5)
		protect()
		standing = groundBoss()
		local length, reason = Audio.GetDuration("P1ShieldBreakScream")
		assert(type(length) == "number" and length > 0, "P1 gate scream unavailable: " .. tostring(reason))
		local orphan, interrupted = Audio.StartFinite(boss, "P1ShieldBreakScream", boss.HumanoidRootPart, {
			Pitch = 1,
			Valid = function()
				return false
			end,
		})
		assert(not orphan and interrupted == "Interrupted", "Finite audio emitted after losing ownership")
		local participants = living()
		local immune = participants[#participants]
		Time.SetPlayerTimer(immune.Character, "DefensiveUntil", 60)
		immune.Character:SetAttribute("DefensiveActive", true)
		Status.SetDebuffImmunity(immune.Character, true)
		local observationFailure, frames, shockwaves = nil, 0, 0
		local screamStart = boss:GetAttribute("ShieldBreakRoarStartedAt") or 0
		local gateSampler = Run.Heartbeat:Connect(function()
			local ends = boss:GetAttribute("ShieldBreakScreamEndsAt") or 0
			if
				(boss:GetAttribute("ShieldBreakRoarStartedAt") or 0) > screamStart
				and workspace:GetServerTimeNow() < ends - 0.03
			then
				frames += 1
				if
					not boss:GetAttribute("ShieldBreakInProgress")
					or not boss:GetAttribute("PhaseTransitionInProgress")
					or boss:GetAttribute("AIEnabled") ~= false
					or Clones.Count(boss, "ShieldGate") ~= 0
				then
					observationFailure = "Boss released combat or summoned clones before the full scream ended"
				end
				for _, item in ipairs(participants) do
					local c, p, h = item.Character, item.Player, item.Humanoid
					if
						not c:GetAttribute("ShieldBreakCinematicLocked")
						or not p:GetAttribute("ShieldBreakCinematicLocked")
						or not Status.IsMovementLocked(p)
						or h.WalkSpeed ~= 0
						or h:GetStateEnabled(Enum.HumanoidStateType.Jumping)
						or c:GetAttribute("Chained")
						or c.HumanoidRootPart.Anchored
					then
						observationFailure =
							"An alive player could move/jump, missed control, or was visually chained during the scream"
					end
				end
				if Runtime.Effects:FindFirstChild("GoldenRoarGroundWave", true) then
					shockwaves += 1
				end
			end
		end)
		local gateOK, gateFailure = xpcall(function()
			boss:SetAttribute("Phase2Triggered", false)
			boss:SetAttribute("ShieldCloneGateCompletedAt", 0)
			boss:SetAttribute("ShieldBroken", false)
			boss.Humanoid.Health = Config.Phase2HealthThreshold
			boss:SetAttribute("AttackInProgress", true)
			boss:SetAttribute("ActiveAttackToken", "V6InterruptedAttack")
			boss:SetAttribute("Shield", 1)
			placePlayer(standing.Position + standing.LookVector * 5, standing.Position)
			assert(
				Sword.Hit(
					character,
					boss,
					root.CFrame,
					{},
					nil,
					{ Direct = true, Kind = "PlayerSword", Attacker = character }
				),
				"Native sword did not break the P1 shield"
			)
			waitFor(function()
				return boss:GetAttribute("ShieldBreakInProgress")
			end, 2, "P1 shield-break did not own its transition")
			assert(
				not boss:GetAttribute("AttackInProgress") and boss:GetAttribute("ActiveAttackToken") == nil,
				"Shield break retained the old attack token"
			)
			waitFor(function()
				return (boss:GetAttribute("ShieldBreakRoarStartedAt") or 0) > screamStart
			end, Story.Duration(Story.ShieldBreak) + 12, "Whole P1 dialogue never led to its loaded scream")
			local ends = boss:GetAttribute("ShieldBreakScreamEndsAt")
			assert(
				math.abs(boss:GetAttribute("ShieldBreakScreamDuration") - length) < 0.05,
				"P1 scream length was guessed/truncated"
			)
			marker(
				"V6_P1_WHOLE_SCREAM_CLIENT_CONTROL",
				client("CinematicLockV3", { Stage = "Active", Duration = length })
			)
			waitFor(function()
				return boss:GetAttribute("ShieldCloneGateActive") and Clones.Count(boss, "ShieldGate") == 2
			end, length + 5, "Boss never reached its wall perch and summoned two echoes")
			assert(not observationFailure, observationFailure)
			assert(frames > 3 and shockwaves > 0, "Whole scream/yellow shockwave was not observed")
			assert(
				(boss:GetAttribute("ShieldBreakRoarFinishedAt") or 0) >= ends - 0.03,
				"Players released before actual scream completion"
			)
			for _, item in ipairs(participants) do
				assert(
					not item.Character:GetAttribute("ShieldBreakCinematicLocked")
						and not item.Player:GetAttribute("ShieldBreakCinematicLocked")
						and not Status.IsMovementLocked(item.Player),
					"Scream left cinematic control during the clone fight"
				)
			end
			assert(
				not boss:GetAttribute("Phase2Triggered")
					and boss:GetAttribute("Invulnerable")
					and boss:GetAttribute("AIEnabled") == false,
				"Phase2/boss combat bypassed the two-clone gate"
			)
			assert(not Phase.BeginPhase2(boss), "Health threshold bypassed the active clone gate")
			local perch = assert(boss:GetAttribute("ShieldCloneGatePerchFrame"))
			assert(
				perch.Y > standing.Y + 6 and (boss.HumanoidRootPart.Position - perch.Position).Magnitude < 0.2,
				"Boss did not hold its validated wall top"
			)
			assert(
				type(boss:GetAttribute("ShieldCloneGatePerchPart")) == "string",
				"Perch has no validated real map support"
			)
			local copies = {}
			for _, copy in ipairs(Runtime.Summons:GetChildren()) do
				local ref = copy:FindFirstChild("EncounterOwner")
				if copy:GetAttribute("IsShieldGateClone") and ref and ref.Value == boss then
					copies[copy:GetAttribute("ShieldGateIndex")] = copy
				end
			end
			for index = 1, 2 do
				local copy = assert(copies[index])
				local h = assert(copy:FindFirstChildOfClass("Humanoid"))
				assert(
					copy:GetAttribute("Phase") == 1
						and copy:GetAttribute("DamageableClone")
						and not copy:GetAttribute("IsLinkedClone"),
					"Gate echo uses linked/incorrect phase mechanics"
				)
				assert(
					h.MaxHealth == 1000
						and h.Health == 1000
						and copy:GetAttribute("Shield") == 0
						and copy:GetAttribute("MaxShield") == 0,
					"Gate echo HP/shield incorrect"
				)
				assert(copy.HumanoidRootPart.CanQuery, "Native sword cannot query the gate echo")
				waitFor(function()
					return not copy:GetAttribute("Invulnerable")
				end, 3, "Gate echo stayed immune after appearing")
			end
			marker("V6_THREE_CLIENT_TWO_1000_HP_GATE_HUD", eachClient("UIV6", { Stage = "Gate" }))
			for index = 1, 2 do
				local copy = copies[index]
				waitFor(function()
					return copy:GetAttribute("CloneSelectedAttack")
				end, 8, "Gate echo did not choose a normal mechanic")
				local meta = assert(Metadata.Get(copy:GetAttribute("CloneSelectedAttack")))
				assert(meta.NativePhase == 1 and not meta.Ultimate, "Gate echo copied a non-P1 mechanic or Ultimate")
			end
			local damagePerHit = Sword.Damage * PlayerConfig.GetSwordDamageMultiplier()
			local actualHits = 0
			for index = 1, 2 do
				local copy = copies[index]
				local h = copy.Humanoid
				local previous = h.Health
				local prefix = "ShieldGateClone" .. index
				local deadline = os.clock() + 20
				while h.Health > 0 and os.clock() < deadline do
					-- Validate each live position while the echo performs real mechanics.
					local copyRoot = copy.HumanoidRootPart
					local safe =
						Placement.Validate(character, copyRoot.CFrame + copyRoot.CFrame.LookVector * 5, { Margin = 6 })
					if safe then
						root.CFrame =
							CFrame.lookAt(safe.Position, Vector3.new(copyRoot.Position.X, safe.Y, copyRoot.Position.Z))
						root.AssemblyLinearVelocity = Vector3.zero
						copy:SetAttribute("ParryActive", false)
						require(BossSystem.Boss.GoldenGuardService).Clear(copy)
						local healthBefore = h.Health
						if
							Sword.Hit(
								character,
								copy,
								root.CFrame,
								{},
								nil,
								{ Direct = true, Kind = "PlayerSword", Attacker = character }
							)
						then
							actualHits += 1
							assert(
								math.abs(healthBefore - h.Health - math.min(healthBefore, damagePerHit)) < 0.01,
								"Native clone sword damage did not clamp the live scaled configuration to remaining HP"
							)
						end
					end
					Run.Heartbeat:Wait()
				end
				assert(
					h.Health <= 0 and previous == 1000,
					"Actual scaled native sword failed to defeat its damageable echo"
				)
				waitFor(function()
					return boss:GetAttribute(prefix .. "Alive") == false and boss:GetAttribute(prefix .. "Health") == 0
				end, 2, "Defeated echo HP HUD did not update")
				if index == 1 then
					assert(
						boss:GetAttribute("ShieldCloneGateActive") and not boss:GetAttribute("Phase2Triggered"),
						"Gate completed after only one real defeat"
					)
				end
			end
			waitFor(function()
				return boss:GetAttribute("Phase2Triggered")
			end, 4, "Two defeats did not return the boss to the floor and begin Phase2")
			assert(
				(boss:GetAttribute("ShieldCloneGateDefeatedCount") or 0) == 2
					and not boss:GetAttribute("ShieldCloneGateActive"),
				"Gate counts/ownership did not finish cleanly"
			)
			local floor = assert(Placement.Validate(boss, boss.HumanoidRootPart.CFrame))
			assert(
				math.abs(boss.HumanoidRootPart.Position.Y - floor.Y) < 0.3,
				"Phase2 started while boss was still on its perch"
			)
			local phase2Duration = Config.Phase2PauseDuration
				+ Story.Duration(Story.Phase2BeforeIdentity)
				+ Story.Duration(Story.Phase2Identity)
				+ Story.Duration(Story.Phase2Power)
				+ Story.Duration(Story.Phase2Art)
				+ Story.Duration(Story.Phase2AfterTime)
			waitFor(function()
				return boss:GetAttribute("Phase") == 2 and not boss:GetAttribute("PhaseTransitionInProgress")
			end, phase2Duration + 8, "Whole Phase2 story never completed")
			assert(
				boss:GetAttribute("AIEnabled")
					and not boss:GetAttribute("AttackInProgress")
					and boss:GetAttribute("ActiveAttackToken") == nil,
				"Phase2 retained the old stuck attack state"
			)
			assert(
				not boss:GetAttribute("Invulnerable") and not boss:GetAttribute("ExecutionLocked"),
				"Phase2 retained cinematic protection/control"
			)
			marker("V6_P1_FULL_SCREAM_WALL_TWO_NATIVE_SWORD_DEFEATS_AND_PHASE2", {
				Clients = #participants,
				Scream = length,
				Frames = frames,
				Hits = actualHits,
				Participants = rootedParticipants("first gate/whole Phase2 cleanup"),
			})
			local started = boss:GetAttribute("AttackStartedAt") or 0
			holdSelection = false
			boss:SetAttribute("NextAttackAt", workspace:GetServerTimeNow())
			waitFor(function()
				return (boss:GetAttribute("AttackStartedAt") or 0) > started
			end, 5, "Boss AI did not attack after the whole scream/gate/story")
			holdSelection = true
			pause()
			marker("V6_REAL_BOSS_AI_RESUMES_AFTER_GATE", boss:GetAttribute("CurrentAttackFile"))
		end, debug.traceback)
		gateSampler:Disconnect()
		holdSelection = true
		assert(gateOK, gateFailure)

		-- Cancelling the owned waiting gate cannot fake either death or Phase2.
		setPhase(1.5)
		protect()
		local cancelStanding = groundBoss()
		-- The preceding native AI proof/first roar may leave clients near an arena
		-- edge. Prepare this independent cancellation case on validated floor;
		-- never wait for or heal an alive Humanoid whose body was destroyed.
		local cancellationParticipants = living()
		for index, item in ipairs(cancellationParticipants) do
			assert(
				item.Player.Character == item.Character,
				"Cancellation fixture character changed before placement: " .. item.Player.Name
			)
			local r = assert(
				item.Character:FindFirstChild("HumanoidRootPart"),
				"Cancellation fixture lost root before placement: " .. item.Player.Name
			)
			local point = cancelStanding.Position + Vector3.new((index - 2) * 8, 0, 8)
			local frame = assert(
				Placement.Validate(item.Character, CFrame.lookAt(point, cancelStanding.Position), { Margin = 8 }),
				"Cancellation fixture has no safe central player position: " .. item.Player.Name
			)
			r.CFrame = frame
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
			item.Humanoid:Move(Vector3.zero, false)
		end
		-- Refresh header handles only from the actual current primary character.
		character = assert(player.Character)
		humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
		root = assert(character:FindFirstChild("HumanoidRootPart"))
		marker("V6_SECOND_GATE_VALIDATED_CENTRAL_PARTICIPANTS", #cancellationParticipants)
		boss:SetAttribute("Phase2Triggered", false)
		boss:SetAttribute("ShieldCloneGateCompletedAt", 0)
		boss:SetAttribute("ShieldBroken", false)
		boss:SetAttribute("Shield", 0)
		if not boss:GetAttribute("ShieldBreakInProgress") then
			assert(Phase.ShieldBroken(boss, character))
		end
		waitFor(
			function()
				return boss:GetAttribute("ShieldCloneGateActive") and Clones.Count(boss, "ShieldGate") == 2
			end,
			Story.Duration(Story.ShieldBreak) + length + 14,
			"Cancellation fixture never reached its actual waiting gate"
		)
		Effects.CancelOwner(boss, "V6 owned gate cancellation")
		waitFor(function()
			return Clones.Count(boss, "ShieldGate") == 0
		end, 3, "Cancelled gate retained its own echoes")
		assert(
			not boss:GetAttribute("ShieldCloneGateActive")
				and not boss:GetAttribute("ShieldBreakInProgress")
				and not boss:GetAttribute("PhaseTransitionInProgress")
				and not boss:GetAttribute("Phase2Triggered"),
			"Gate cancellation left ownership or falsely advanced Phase2"
		)
		assert(
			boss:GetAttribute("AIEnabled")
				and not boss:GetAttribute("AttackInProgress")
				and boss:GetAttribute("ActiveAttackToken") == nil,
			"Gate cancellation retained a stuck attack"
		)
		assert(
			(boss:GetAttribute("ShieldCloneGateDefeatedCount") or 0) == 0
				and (boss:GetAttribute("ShieldCloneGateCompletedAt") or 0) == 0,
			"Cancellation was counted as an actual defeat"
		)
		local safe = assert(Placement.Validate(boss, boss.HumanoidRootPart.CFrame))
		assert(
			math.abs(boss.HumanoidRootPart.Position.Y - safe.Y) < 0.3,
			"Cancelled boss remained stranded on its wall"
		)
		marker(
			"V6_CANCELLED_WAITING_GATE_RELEASES_CLONES_AND_ATTACK_STATE",
			eachClient("CinematicLockV3", { Stage = "Cleanup" }),
			rootedParticipants("second gate cancellation cleanup")
		)

		-- The music preference changes only its own mix and survives a hidden boss HUD.
		setPhase(4)
		protect()
		groundBoss()
		sleep(1)
		assert(not bow.CanUse(character), "Royal Bow escaped its strict Phase1.5 pool")
		marker("V6_THREE_CLIENT_SETTINGS_MUSIC_MUTE_NEUTRAL_SFX", eachClient("UIV6", { Stage = "Music" }))

		-- Retired Ultimate cues are absent; current attacks play known quiet clips.
		for _, name in ipairs({
			"CardSummon",
			"CardThrow",
			"CardBurst",
			"EnhancedNormalDraw",
			"EnhancedNormalSwing",
			"EnhancedNormalImpact",
			"EnhancedRangedLaunch",
			"MirrorCast",
			"MirrorBeam",
			"ProjectileCast",
			"MirrorImpact",
		}) do
			local cue = assert(AudioConfig.Cues[name], "Missing V6 quiet cue " .. name)
			assert(cue.VolumeCap and cue.VolumeCap <= 0.22, "V6 cue lacks quiet gain cap: " .. name)
			for _, layer in ipairs(cue.Layers) do
				assert(layer.Volume <= 0.22, "V6 layer exceeds quiet gain: " .. name)
			end
		end
		assert(not AudioConfig.Attacks["P4AscensionToHell(Ultimate)"], "Removed Ultimate remains in soundboard")
		for _, name in ipairs({ "AscensionCry", "AscensionDeclare", "AscensionBell", "AscensionImpact" }) do
			assert(
				not AudioConfig.Cues[name] and not AudioConfig.UploadedCues[name],
				"Retired cue still exists: " .. name
			)
		end
		task.delay(0.4, function()
			for _, name in ipairs({
				"CardSummon",
				"CardThrow",
				"CardBurst",
				"EnhancedNormalDraw",
				"EnhancedNormalSwing",
				"EnhancedNormalImpact",
			}) do
				assert(Audio.Emit(boss, name, boss.HumanoidRootPart), "New soundboard event did not emit: " .. name)
				sleep(0.12)
			end
		end)
		marker("V6_REAL_POOLED_CARDS_AND_ENHANCED_SWORD_QUIET_CUES", client("UIV6", { Stage = "QuietCues" }))
		local finite
		task.delay(0.4, function()
			finite = assert(Audio.StartFinite(boss, "P1ShieldBreakScream", boss.HumanoidRootPart, {
				Valid = function()
					return boss.Parent and boss:GetAttribute("Phase") == 4
				end,
			}))
			Audio.Emit(boss, "EnhancedRangedLaunch", boss.HumanoidRootPart)
			Audio.Emit(boss, "MirrorCast", boss.HumanoidRootPart)
			Audio.Emit(boss, "ProjectileCast", boss.HumanoidRootPart)
		end)
		local audio = client("UploadedAudioV3", {
			Window = math.min(10, math.max(4, length + 1)),
			RequireLoaded = true,
			RequireCues = { "P1ShieldBreakScream", "EnhancedRangedLaunch", "MirrorCast", "ProjectileCast" },
		})
		waitFor(function()
			return finite and finite:IsComplete()
		end, length + 9, "Finite scream did not complete its actual clip")
		finite:Dispose()
		marker("V6_QUIET_KNOWN_AUDIO_FULL_LENGTH_NO_ATTACK_DUCK", audio)

		-- Real finite server effects feed the same walking/Dash resolver. Each
		-- actual client then predicts a Dash and receives ordinary server approval.
		setPhase(3)
		protect()
		groundBoss()
		local primary = player
		local mappedResults = {}
		local mappedOK, mappedFailure = xpcall(function()
			for index, item in ipairs(living()) do
				Reality.Cancel(boss)
				Dash.Cancel(item.Player, "V6 mapped Dash preparation")
				local char = item.Character
				local r = char.HumanoidRootPart
				Status.Clear(item.Player)
				Encounter.CancelDefense(item.Player)
				char:SetAttribute("DefensiveActive", false)
				Time.SetPlayerTimer(char, "DefensiveUntil", 0)
				Status.SetDebuffImmunity(char, false)
				char:SetAttribute("Stamina", PlayerConfig.MaxStamina)
				local frame = assert(
					Placement.Validate(
						char,
						CFrame.new(bounds.Frame.Position + Vector3.new(25 + (index - 1) * 12, 0, 20)),
						{ Margin = 8 }
					)
				)
				r.CFrame = frame
				r.AssemblyLinearVelocity = Vector3.zero
				r.AssemblyAngularVelocity = Vector3.zero
				local previous = char:GetAttribute("DashSequence") or 0
				assert(Reality.ControlDistortion(boss, char), "Actual distorted effects failed to start")
				player = item.Player
				local value = client("UIV6", { Stage = "DashMapping" })
				assert(
					value.Approved
						and value.Sequence > previous
						and (char:GetAttribute("DashSequence") or 0) == value.Sequence,
					"Actual server never approved the distorted input Dash"
				)
				assert(
					math.abs((char:GetAttribute("DashStartedAt") or 0) - value.RequestedAt) < 0.17,
					"Server mapped Dash timestamp did not match the real client request"
				)
				mappedResults[player.Name] = value
				Dash.Cancel(item.Player, "V6 mapped Dash cleanup")
			end
		end, debug.traceback)
		player = primary
		Reality.Cancel(boss)
		for _, item in ipairs(living()) do
			Dash.Cancel(item.Player, "V6 mapped Dash cleanup")
		end
		if not mappedOK then
			error(mappedFailure, 0)
		end
		marker("V6_THREE_CLIENT_HIDDEN_SWAP_UI_AND_AUTHORITATIVE_DISTORTED_DASH", mappedResults)
	end

	-- Actual full-duration P1 roar containment. Append before later UI/P4 tests.
	do
		local Story = require(BossSystem.Encounter.EncounterStory)
		local Audio = require(BossSystem.Presentation.CombatAudio)
		local bounds = assert(Placement.GetBounds())
		setPhase(1.5)
		protect()
		local bossFrame = assert(Placement.Validate(boss, CFrame.new(bounds.Frame.Position), { Margin = 8 }))
		boss.HumanoidRootPart.CFrame = bossFrame
		boss.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
		boss:SetAttribute("Phase2Triggered", false)
		boss:SetAttribute("ShieldCloneGateCompletedAt", 0)
		boss:SetAttribute("ShieldBroken", false)
		boss:SetAttribute("Shield", 0)
		local participants = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			local r = c and c:FindFirstChild("HumanoidRootPart")
			assert(c and h and h.Health > 0 and r, "Near-wall roar needs each initialized live character")
			table.insert(participants, { Player = p, Character = c, Humanoid = h, Root = r })
		end
		assert(#participants >= 3, "Near-wall roar requires three actual players")
		local wallFrames = {}
		for _, margin in ipairs({ 10, 14, 18, 22 }) do
			for _, offset in ipairs({
				Vector3.new(bounds.HalfX - margin, 0, 0),
				Vector3.new(-bounds.HalfX + margin, 0, 0),
				Vector3.new(0, 0, bounds.HalfZ - margin),
				Vector3.new(0, 0, -bounds.HalfZ + margin),
			}) do
				local point = bounds.Frame:PointToWorldSpace(offset)
				if (point - bossFrame.Position).Magnitude < (Config.ShieldBreakRoarRadius or 450) - 10 then
					local frame = Placement.Validate(participants[1].Character, CFrame.new(point), { Margin = 6 })
					if frame then
						table.insert(wallFrames, frame)
					end
				end
			end
			if #wallFrames >= 2 then
				break
			end
		end
		assert(#wallFrames >= 2, "No actual validated near-wall positions within the roar radius")
		for index, item in ipairs(participants) do
			local frame = index <= 2 and wallFrames[index]
				or assert(
					Placement.Validate(item.Character, bossFrame + Vector3.new(8 + index * 3, 0, 8), { Margin = 6 })
				)
			item.Root.CFrame = frame
			item.Root.AssemblyLinearVelocity = Vector3.zero
			item.Root.AssemblyAngularVelocity = Vector3.zero
			item.Start = frame.Position
			item.MaxMove = 0
			item.MaxLift = 0
		end
		local length, reason = Audio.GetDuration("P1ShieldBreakScream")
		assert(type(length) == "number" and length > 0, "Near-wall scream unavailable: " .. tostring(reason))
		local previous = boss:GetAttribute("ShieldBreakRoarStartedAt") or 0
		local failure, frames = nil, 0
		local observer = Run.Heartbeat:Connect(function()
			if (boss:GetAttribute("ShieldBreakRoarStartedAt") or 0) <= previous then
				return
			end
			frames += 1
			for _, item in ipairs(participants) do
				local r = item.Character:FindFirstChild("HumanoidRootPart")
				if item.Player.Character ~= item.Character or r ~= item.Root or item.Humanoid.Health <= 0 then
					failure = "Near-wall roar lost a real character/root or killed a player"
				elseif not Placement.Contains(r.Position, 4) or r.Position.Y < bounds.Frame.Y - 0.25 then
					failure = "Physical roar escaped the arena or fell beneath its floor"
				else
					item.MaxMove = math.max(item.MaxMove, (r.Position - item.Start).Magnitude)
					item.MaxLift = math.max(item.MaxLift, r.Position.Y - item.Start.Y)
				end
			end
		end)
		local roarOK, roarError = xpcall(function()
			assert(Phase.ShieldBroken(boss, character), "Near-wall roar failed to claim its gate")
			waitFor(function()
				return (boss:GetAttribute("ShieldBreakRoarStartedAt") or 0) > previous
			end, Story.Duration(Story.ShieldBreak) + 12, "Near-wall whole scream never began")
			local ends = boss:GetAttribute("ShieldBreakScreamEndsAt")
			assert(
				math.abs(boss:GetAttribute("ShieldBreakScreamDuration") - length) < 0.05,
				"Near-wall containment shortened the scream"
			)
			waitFor(function()
				return (boss:GetAttribute("ShieldBreakRoarFinishedAt") or 0) >= ends - 0.03
			end, length + 3, "Near-wall full scream never released")
			waitFor(function()
				return boss:GetAttribute("ShieldCloneGateActive") and Clones.Count(boss, "ShieldGate") == 2
			end, 5, "Contained roar did not finish its normal wall/clone sequence")
			Effects.CancelOwner(boss, "Near-wall regression cleanup")
			sleep(0.35)
			assert(not failure, failure)
			assert(frames >= math.max(3, length * 20), "Containment was not sampled through the full scream")
			local result = {}
			for _, item in ipairs(participants) do
				assert(
					item.Root.Parent and item.Humanoid.Health > 0 and Placement.Contains(item.Root.Position, 4),
					"A root was destroyed after containment ownership returned"
				)
				assert(item.MaxMove > 1 and item.MaxLift > 1, "Containment removed the physical roar impulse/lift")
				assert(
					not item.Character:GetAttribute("ShieldBreakCinematicLocked")
						and not Status.IsMovementLocked(item.Player),
					"Contained roar retained cinematic control"
				)
				local velocity = item.Root.AssemblyLinearVelocity
				assert(
					Vector3.new(velocity.X, 0, velocity.Z).Magnitude < 12,
					"Old horizontal roar momentum remained after release"
				)
				table.insert(result, { Player = item.Player.Name, Move = item.MaxMove, Lift = item.MaxLift })
			end
			marker(
				"V6_FULL_SCREAM_NEAR_WALL_PHYSICAL_KNOCKBACK_CONTAINED",
				{ Duration = length, Frames = frames, Players = result }
			)
		end, debug.traceback)
		observer:Disconnect()
		assert(roarOK, roarError)
	end

	do
		local Story = require(BossSystem.Encounter.EncounterStory)
		local Weapon = require(BossSystem.Boss.WeaponController)
		local expectedStory = Story.Phase3After
		setPhase(2)
		boss:SetAttribute("Phase4Triggered", false)
		boss:SetAttribute("Phase3DialogueIndex", nil)
		boss:SetAttribute("Phase3LastDialogue", nil)
		boss:SetAttribute("Phase3Triggered", false)
		boss:SetAttribute("Shield", 0)
		if not Phase3Intro.Active(boss) then
			assert(Phase.BeginPhase3(boss, character), "Retained P2 shield break did not enter Phase 3")
		end
		waitFor(function()
			return boss:GetAttribute("Phase3IntroActive") and boss:GetAttribute("Phase2ShieldBreakSequenceActive")
		end, 4, "Natural intro music gate did not start")
		marker("V4_NATURAL_SHIELD_BREAK_MUSIC_STOP", client("MusicGateV2", { Stage = "Stop", Window = 0.3 }))
		waitFor(function()
			return boss:GetAttribute("Phase3GravityActive")
		end, 30, "Retained intro did not enter gravity/wave stage")
		marker("V4_NATURAL_PHASE3_INTRO_MUSIC_SILENCE", client("MusicGateV2", { Stage = "Intro", Window = 0.4 }))
		local seen = {}
		local deadline = os.clock() + 65
		repeat
			local index = boss:GetAttribute("Phase3DialogueIndex")
			if index then
				seen[index] = boss:GetAttribute("Phase3LastDialogue")
				assert(seen[index] == expectedStory[index], "Natural intro presented a superseded dialogue line")
			end
			assert(os.clock() < deadline, "Natural Phase 3 intro did not complete")
			Run.Heartbeat:Wait()
		until boss:GetAttribute("Phase") == 3 and not boss:GetAttribute("Phase3IntroActive")
		for index, line in ipairs(expectedStory) do
			assert(seen[index] == line, "Natural intro omitted exact user dialogue line " .. index)
		end
		assert(
			boss.Humanoid.MaxHealth == 5000 and boss.Humanoid.Health == 5000,
			"Phase 3 did not initialize exactly 5,000 HP"
		)
		assert(
			boss:GetAttribute("MaxShield") == 8500 and boss:GetAttribute("Shield") == 8500,
			"Phase 3 did not initialize the complete 8,500 shield"
		)
		assert(
			boss.Name == "alterGolden, the Nothing"
				and boss.Humanoid.DisplayName == "alterGolden, Illusionist"
				and boss:GetAttribute("PhaseTitleOverride") == "alterGolden, Illusionist",
			"Illusionist title broke the stable boss model binding"
		)
		assert(
			boss:GetAttribute("Phase3WavesReleased") == Config.Phase3WaveCount,
			"Retained P2 shield-break polygon barrage was removed"
		)
		assert(
			boss:GetAttribute("UnarmedCombat") and not boss:FindFirstChild("Basic Sword"),
			"Phase 3 unarmed presentation did not park the native sword"
		)
		assert(not Reality.Start(boss) and Clones.Count(boss, "Linked") == 0, "Puppeteer appeared before Phase 4")
		marker(
			"V4_NATURAL_PHASE3_SIX_DIALOGUE_5000_HP_8500_SHIELD_ILLUSIONIST",
			6,
			8500,
			client("MusicGateV2", { Stage = "Complete" })
		)
	end

	-- Native three-client tests; append within the existing server xpcall.
	do
		local function isolate()
			setPhase(3)
			boss:SetAttribute("AttackInProgress", true)
			local bounds = assert(Placement.GetBounds())
			boss.HumanoidRootPart.CFrame = assert(Placement.Validate(boss, CFrame.new(bounds.Frame.Position)))
			boss.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			placePlayer(boss.HumanoidRootPart.Position + Vector3.new(0, 0, -22), boss.HumanoidRootPart.Position)
			return bounds
		end
		local function living()
			local values = {}
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				local h = c and c:FindFirstChildOfClass("Humanoid")
				if c and h and h.Health > 0 then
					Encounter.CancelDefense(p)
					require(BossSystem.Players.PlayerBlessing).Cancel(p)
					Status.Clear(p)
					Dash.Cancel(p, "V6 actual skill preparation")
					c:SetAttribute("RespawnInvulnerableUntil", 0)
					c:SetAttribute("DashInvulnerableUntil", 0)
					c:SetAttribute("Invulnerable", false)
					for _, v in ipairs(c:GetChildren()) do
						if v:IsA("ForceField") then
							v:Destroy()
						end
					end
					h.Health = h.MaxHealth
					Immunity.Refresh(c)
					c.HumanoidRootPart.Anchored = false
					table.insert(values, { Player = p, Character = c, Root = c.HumanoidRootPart, Humanoid = h })
				end
			end
			assert(#values >= 3, "V6 Phase 3 tests require three alive initialized clients")
			table.sort(values, function(a, b)
				if a.Player == b.Player then
					return false
				end
				if a.Player == player then
					return true
				end
				if b.Player == player then
					return false
				end
				return a.Player.UserId < b.Player.UserId
			end)
			return values
		end
		local function copies()
			local values = {}
			for _, value in ipairs(Runtime.Summons:GetChildren()) do
				local owner = value:FindFirstChild("EncounterOwner")
				if value:GetAttribute("IsIllusion") and owner and owner.Value == boss then
					table.insert(values, value)
				end
			end
			return values
		end
		isolate()
		assert(
			not Reality.Start(boss) and not boss:FindFirstChild("GoldenBackHalo", true),
			"Removed Puppeteer/back halo remains"
		)
		local mirror = Registry.For(boss, "P3Illusion")
		local done, result = false, nil
		local torso = boss:FindFirstChild("Torso") or boss:FindFirstChild("UpperTorso")
		local alpha = torso.Transparency
		task.spawn(function()
			result = mirror.Combo(character)
			done = true
		end)
		local beam = waitFor(function()
			return Runtime.Effects:FindFirstChild("IllusionYellowDashBeam", true)
		end, 1, "Far mirror entry beam missing")
		local endpoints = {}
		for _, value in ipairs(beam:GetChildren()) do
			if value:IsA("Attachment") then
				table.insert(endpoints, value.WorldPosition)
			end
		end
		assert(
			#endpoints == 2 and (endpoints[2] - endpoints[1]).Magnitude >= Config.IllusionMirrorDashDistance - 1,
			"Mirror entry beam remains short"
		)
		local layers = 0
		for _, v in ipairs(beam:GetChildren()) do
			if v:IsA("Beam") then
				layers += 1
			end
		end
		local rims = 0
		for _, v in ipairs(Runtime.Effects:GetDescendants()) do
			if v.Name == "IllusionPortalRotatingRim" then
				rims += 1
			end
		end
		assert(layers == 3 and rims == 32, "Layered yellow trail/rotating mirrored portal was not wired")
		assert(
			torso.Transparency == 1 and boss:GetAttribute("IllusionOutlineHidden"),
			"Mirror did not hide body/outline"
		)
		waitFor(function()
			return Clones.Count(boss, "Illusion") == 2
		end, 2, "Far mirror exits did not create two fakes")
		waitFor(function()
			return done
		end, 3, "Far mirror did not finish finite beam dashes")
		assert(result and torso.Transparency == alpha, "Far mirror left real body invisible")
		local fakes = copies()
		assert(
			#fakes == 2 and boss:GetAttribute("IllusionOutlineHidden"),
			"Outline returned before fake mimic lifetime"
		)
		local positions = {}
		for _, fake in ipairs(fakes) do
			positions[fake] = fake.HumanoidRootPart.Position
		end
		local offset
		for _, candidate in ipairs({
			Vector3.new(4, 0, 0),
			Vector3.new(-4, 0, 0),
			Vector3.new(0, 0, 4),
			Vector3.new(0, 0, -4),
		}) do
			local clear = Placement.Validate(boss, boss.HumanoidRootPart.CFrame + candidate) ~= nil
			for _, fake in ipairs(fakes) do
				if not Placement.Validate(fake, fake.HumanoidRootPart.CFrame + candidate) then
					clear = false
				end
			end
			if clear then
				offset = candidate
				break
			end
		end
		assert(offset, "No clear movement fixture for mirror copies")
		boss.HumanoidRootPart.CFrame += offset
		sleep(0.2)
		for _, fake in ipairs(fakes) do
			assert(
				(fake.HumanoidRootPart.Position - positions[fake] - offset).Magnitude < 0.5,
				"Fake failed to mimic movement"
			)
			assert(
				(fake:GetAttribute("CloneAttackCount") or 0) == 0 and fake:GetAttribute("CloneState") == "Mirroring",
				"Harmless fake started independent attacks"
			)
		end
		waitFor(function()
			return Clones.Count(boss, "Illusion") == 0
		end, Config.IllusionDuration + 1, "Far fakes exceeded finite duration")
		waitFor(function()
			return not boss:GetAttribute("IllusionOutlineHidden")
		end, 1.5, "Mirror outline ownership did not restore")
		marker("V6_FAR_MIRROR_TWO_HARMLESS_MIMICS_AND_OUTLINE_LIFECYCLE", #fakes)
		isolate()
		done = false
		task.spawn(function()
			mirror.Combo(character)
			done = true
		end)
		waitFor(function()
			return torso.Transparency == 1
		end, 1, "Mirror interruption fixture did not start")
		setPhase(4)
		waitFor(function()
			return done
		end, 2, "Interrupted mirror coroutine survived")
		assert(
			torso.Transparency == alpha and not boss:GetAttribute("IllusionOutlineHidden"),
			"Interrupted mirror left body/outline hidden"
		)
		marker("V6_MIRROR_PHASE_CANCEL_RESTORES_BODY_AND_OUTLINE")

		marker("V6_SPATIAL_FOG_BASELINE", client("EtherealV6", { Stage = "Baseline" }))
		local bounds = isolate()
		local participants = living()
		local ult = Registry.For(boss, "P3EtherealAcumen(Ultimate)")
		assert(
			ult.Cooldown == 120 and Config.EtherealAcumenDamage == 5,
			"Ultimate cooldown/card damage differs from explicit request"
		)
		local center = bounds.Frame.Position
		for index, value in ipairs(participants) do
			local position = center + Vector3.new((index - 1) * 14 - 7, 0, -24)
			if index >= 3 then
				local safe
				for _, x in ipairs({ 0.9, -0.9 }) do
					for _, z in ipairs({ 0.9, -0.9 }) do
						local p = bounds.Frame:PointToWorldSpace(Vector3.new(bounds.HalfX * x, 0, bounds.HalfZ * z))
						safe = safe or Placement.Validate(value.Character, CFrame.new(p), { Margin = 6 })
					end
				end
				assert(safe, "No clear actual corner for avoidable Ultimate fixture")
				value.Root.CFrame = safe
				assert(not ult.Contains(safe.Position), "Arena corner lies in Ultimate hitbox")
			else
				value.Root.CFrame = assert(Placement.Validate(value.Character, CFrame.new(position)))
			end
			value.Root.AssemblyLinearVelocity = Vector3.zero
		end
		local corner = participants[3]
		local cornerHP = corner.Humanoid.Health
		boss:SetAttribute("EtherealChargeStartedAt", nil)
		boss:SetAttribute("EtherealCubeStartedAt", nil)
		done = false
		result = nil
		local began = workspace:GetServerTimeNow()
		task.spawn(function()
			result = ult.Combo(character)
			done = true
		end)
		waitFor(function()
			return boss:GetAttribute("EtherealChargeStartedAt")
		end, 2, "Sky Ultimate did not begin charge after high ascent")
		assert(
			boss.HumanoidRootPart.Position.Y - center.Y >= Config.EtherealAcumenRiseHeight - 1,
			"Ultimate boss failed to fly high"
		)
		marker("V6_ETHEREAL_EXACT_SHORT_TYPEWRITER_CHARGE", client("EtherealV6", { Stage = "Charge" }))
		local cube = waitFor(function()
			return Runtime.Effects:FindFirstChild("EtherealTesseractAnchor", true)
		end, 5, "Large cube did not follow 3.5 second charge")
		assert(
			boss:GetAttribute("EtherealCubeStartedAt") - boss:GetAttribute("EtherealChargeStartedAt") >= 3.4,
			"Ultimate shortened requested recharge"
		)
		local edges = 0
		for _, v in ipairs(cube:GetChildren()) do
			if v:IsA("Beam") then
				edges += 1
			end
		end
		assert(
			edges == 32
				and cube:GetAttribute("CubeDimension") == Config.EtherealAcumenTesseractSize
				and cube:GetAttribute("CubeDimension") <= 70
				and (boss.HumanoidRootPart.Position - cube.Position).Magnitude < 1,
			"Smaller real32edge tesseract/Boss-inside layout differs"
		)
		local turn = cube.CFrame
		sleep(0.25)
		assert(cube.CFrame.LookVector:Dot(turn.LookVector) < 0.9999, "Outer tesseract is not rotating")
		local card = waitFor(function()
			return Runtime.Effects:FindFirstChild("EtherealCenterShotCard", true)
		end, 1.5, "Large center card missing")
		assert(card.Size.X >= 5 and card.Size.Y >= 7, "Center cards remained tiny")
		waitFor(function()
			return ult.Captures[character] and ult.Captures[participants[2].Character]
		end, 2, "Nearby real players did not enter physical sky orbit")
		assert(
			not ult.Captures[corner.Character] and not corner.Character:GetAttribute("EtherealOrbitActive"),
			"Safe corner player was captured"
		)
		local states = {}
		for c, state in pairs(ult.Captures) do
			states[c] = state
		end
		marker("V6_ETHEREAL_CAPTURED_REAL_CLIENT_ROTATING_CAMERA", client("EtherealV6", { Stage = "Orbit" }))
		waitFor(function()
			for _, state in pairs(states) do
				if state.LastCardDamage then
					assert(state.LastCardDamage == 5, "Center card actual undefended damage is not exactly5")
					return true
				end
			end
		end, 2, "Center card did not deal real fixed5 damage")
		waitFor(function()
			local p = cube.CFrame:PointToObjectSpace(root.Position)
			return root.Position.Y - center.Y >= Config.EtherealAcumenOrbitHeight - 4
				and math.max(math.abs(p.X), math.abs(p.Z)) > cube:GetAttribute("CubeDimension") * 0.5
		end, 5, "Captured player did not reach high physical orbit outside cube")
		assert(
			boss:GetAttribute("EtherealAcumenOrbitRadius") > cube:GetAttribute("CubeDimension") * 0.5 * math.sqrt(2),
			"Orbit aim lies inside rotating outer corners"
		)
		waitFor(function()
			return done
		end, Config.EtherealAcumenDuration + 3, "Large Ultimate exceeded full finite lifecycle")
		assert(
			result
				and workspace:GetServerTimeNow() - began >= Config.EtherealAcumenRiseDuration + 3.5 + 15 - 0.15
				and boss:GetAttribute("EtherealAcumenCardCount") == 15
				and ult.LastCast.closed,
			"Ultimate did not last15seconds/launch15cards"
		)
		assert(
			corner.Humanoid.Health == cornerHP and not corner.Character:GetAttribute("EtherealOrbitActive"),
			"Corner player received avoidable Ultimate damage/capture"
		)
		for c, state in pairs(states) do
			assert(
				state.ReleaseKind == "RandomDrop"
					and state.ReturnFrame
					and Placement.Validate(c, state.ReturnFrame, { Margin = 10 }),
				"Natural orbit did not choose safe random ground drop"
			)
			assert(
				not state.Constraint.Parent
					and not state.Attachment.Parent
					and not c:GetAttribute("EtherealOrbitActive"),
				"Natural orbit constraint/status leaked"
			)
			if state.TookOwnership then
				assert(
					state.Root:GetNetworkOwnershipAuto() == state.Automatic,
					"Orbit did not restore network ownership"
				)
			end
		end
		sleep(0.8)
		for c, state in pairs(states) do
			local floor = assert(Placement.GroundPoint(state.Root.Position, { Margin = 8 }))
			assert(
				state.Root.Position.Y >= floor.Y + 1 and state.Root.Position.Y < floor.Y + 5,
				"Random drop did not land safely"
			)
		end
		marker(
			"V6_ETHEREAL_15_SECONDS_15_FIXED5_CARDS_CORNER_SAFE_RANDOM_DROP",
			client("EtherealV6", { Stage = "Cleanup" })
		)

		bounds = isolate()
		participants = living()
		for index, value in ipairs(participants) do
			value.Root.CFrame = assert(
				Placement.Validate(
					value.Character,
					CFrame.new(bounds.Frame.Position + Vector3.new((index - 2) * 14, 0, -24))
				)
			)
			value.Root.AssemblyLinearVelocity = Vector3.zero
		end
		done = false
		task.spawn(function()
			ult.Combo(character)
			done = true
		end)
		waitFor(function()
			for _, value in ipairs(participants) do
				if not ult.Captures[value.Character] then
					return
				end
			end
			return true
		end, 6, "Ultimate cancel fixture did not physically capture every nearby real player")
		local cancelled = ult.LastCast
		local cancelStates = {}
		for c, state in pairs(ult.Captures) do
			cancelStates[c] = state
		end
		local dead = participants[2]
		local corpseState = assert(cancelStates[dead.Character])
		dead.Humanoid.Health = 0
		waitFor(function()
			return not corpseState.Constraint.Parent and not ult.Captures[dead.Character]
		end, 1, "Dead sky capture retained physical control")
		assert(
			corpseState.Root:GetNetworkOwner() == nil and not dead.Character:GetAttribute("EtherealOrbitActive"),
			"Dead release stole ragdoll server ownership or retained camera status"
		)
		marker("V6_ETHEREAL_DEATH_RELEASE_PRESERVES_SERVER_RAGDOLL_OWNERSHIP")
		setPhase(4)
		waitFor(function()
			return done
		end, 2, "Cancelled sky Ultimate coroutine survived")
		assert(
			cancelled.closed and not boss:GetAttribute("EtherealAcumenActive"),
			"Cancelled sky cube survived phase transition"
		)
		for c, state in pairs(cancelStates) do
			assert(
				not state.Constraint.Parent
					and not state.Attachment.Parent
					and not c:GetAttribute("EtherealOrbitActive")
					and (c == dead.Character or state.ReleaseKind == "Cancelled"),
				"Interrupted orbit launched player or leaked constraint"
			)
		end
		marker(
			"V6_ETHEREAL_ALL_NEARBY_THREE_PLAYERS_PHASE_CAMERA_AND_PHYSICS_CLEANUP",
			#participants,
			client("EtherealV6", { Stage = "Cleanup" })
		)
		waitFor(function()
			local c = dead.Player.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			return c
				and c ~= dead.Character
				and h
				and h.Health > 0
				and c:GetAttribute("R6AppearanceFinished") == true
				and c:GetAttribute("BaseWalkSpeed")
		end, 15, "Actual captured secondary player did not finish safe respawn")

		isolate()
		participants = living()
		local projectile = Registry.For(boss, "P3Projectile")
		participants[2].Root.CFrame =
			assert(Placement.Validate(participants[2].Character, root.CFrame + Vector3.new(12, 0, 0)))
		participants[3].Root.CFrame =
			assert(Placement.Validate(participants[3].Character, root.CFrame + Vector3.new(45, 0, 0)))
		local secondHP = participants[2].Humanoid.Health
		local before = humanoid.Health
		local oldImpact = boss:GetAttribute("P3ProjectileImpactAt")
		done = false
		result = nil
		local shotAt = workspace:GetServerTimeNow()
		task.spawn(function()
			result = projectile.Combo(character)
			done = true
		end)
		waitFor(function()
			return Runtime.Effects:FindFirstChild("ProjectileAirMirror", true)
		end, 1, "Air mirrors were not summoned")
		local panels = 0
		for _, v in ipairs(Runtime.Effects:GetDescendants()) do
			if v.Name == "ProjectileAirMirror" then
				panels += 1
			end
		end
		assert(
			panels == projectile.LastMirrorCount
				and panels >= 3
				and panels <= 10
				and #projectile.LastPoints == panels + 2,
			"Distance-based mirror/segment count incorrect"
		)
		assert(
			not Runtime.Effects:FindFirstChild("ProjectileGroundImpactWarning", true),
			"Removed ground AoE warning remains"
		)
		local anchor = waitFor(function()
			return Runtime.Effects:FindFirstChild("ProjectileGoldenReflectionBeam", true)
		end, 2, "Fast fixed golden bounce segments missing")
		local segment = assert(anchor:FindFirstChild("FixedGoldenMirrorSegment"))
		assert(
			segment.Color.Keypoints[1].Value.R > 0.8 and segment.Color.Keypoints[1].Value.G > 0.6,
			"Mirrored beam is not yellow/gold"
		)
		waitFor(function()
			return boss:GetAttribute("P3ProjectileImpactAt") ~= oldImpact
		end, 2, "Mirrored beam did not impact fixed player ground")
		assert(workspace:GetServerTimeNow() - shotAt < 1.1, "Nearby mirrored projectile remained slow")
		assert(
			before - humanoid.Health == Config.P3ProjectileDamage
				and secondHP - participants[2].Humanoid.Health == Config.P3ProjectileDamage
				and Config.P3ProjectileDamage == 35,
			"Larger no-warning mirror AoE did not deal real fixed35 to both targets"
		)
		assert(
			root.AssemblyLinearVelocity.Magnitude > 1
				and character:GetAttribute("ProjectileDarknessUntil") > workspace:GetServerTimeNow(),
			"Impact omitted knockback/spatial darkness"
		)
		marker(
			"V6_MIRROR_GOLD_FAST_FIXED35_LARGER_AOE_NO_WARNING",
			panels,
			client("EtherealV6", { Stage = "ProjectileSight", Active = true })
		)
		waitFor(function()
			return done
		end, 2, "Mirror projectile coroutine survived finite release")
		assert(result, "Mirror projectile failed")
		sleep(4)
		assert(
			character:GetAttribute("ProjectileDarknessUntil") > workspace:GetServerTimeNow(),
			"Spatial darkness ended before7.5seconds"
		)
		waitFor(function()
			return (character:GetAttribute("ProjectileDarknessUntil") or 0) == 0
		end, 4.5, "Projectile darkness exceeded7.5seconds")
		marker(
			"V6_MIRROR_PROJECTILE_7_5_SECONDS_NATURAL_SPATIAL_FOG_CLEANUP",
			client("EtherealV6", { Stage = "ProjectileSight", Active = false })
		)

		bounds = isolate()
		participants = living()
		local nearCount = projectile.LastMirrorCount
		local far
		for _, x in ipairs({ 1, -1 }) do
			for _, z in ipairs({ 1, -1 }) do
				local position =
					bounds.Frame:PointToWorldSpace(Vector3.new(x * (bounds.HalfX - 18), 0, z * (bounds.HalfZ - 18)))
				local frame = Placement.Validate(character, CFrame.new(position), { Margin = 8 })
				if frame and (frame.Position - boss.HumanoidRootPart.Position).Magnitude > 80 then
					far = far or frame
				end
			end
		end
		assert(far, "No clear far mirror-shot fixture")
		root.CFrame = far
		root.AssemblyLinearVelocity = Vector3.zero
		oldImpact = boss:GetAttribute("P3ProjectileImpactAt")
		done = false
		task.spawn(function()
			projectile.Combo(character)
			done = true
		end)
		waitFor(function()
			return projectile.LastMirrorCount > nearCount
		end, 1, "Far shot did not summon more mirrors")
		assert(
			projectile.LastMirrorCount <= 10 and #projectile.LastPoints == projectile.LastMirrorCount + 2,
			"Far shot exceeded bounded mirror count"
		)
		waitFor(function()
			return boss:GetAttribute("P3ProjectileImpactAt") ~= oldImpact
		end, 2, "Far golden beam failed to reach sampled ground point")
		local farCount = projectile.LastMirrorCount
		setPhase(4)
		waitFor(function()
			return done
		end, 2, "Far mirror cancellation did not end core")
		marker(
			"V6_FAR_SHOT_MORE_MIRRORS_PHASE_FOG_CLEANUP",
			nearCount,
			farCount,
			client("EtherealV6", { Stage = "ProjectileSight", Active = false })
		)

		isolate()
		participants = living()
		placePlayer(boss.HumanoidRootPart.Position + Vector3.new(0, 0, -18), boss.HumanoidRootPart.Position)
		local cards = Registry.For(boss, "P3Cards")
		assert(cards.CanUse(character), "New P3Cards not usable through native registry")
		before = humanoid.Health
		assert(cards.Combo(character), "New P3Cards native volley failed")
		assert(
			boss:GetAttribute("P3CardsLaunched") >= 5
				and boss:GetAttribute("P3CardsLaunched") <= 6
				and #cards.Records == boss:GetAttribute("P3CardsLaunched")
				and cards.LastCast:Alive(),
			"Card count/released concurrent-flight lifecycle incorrect"
		)
		local hit = waitFor(function()
			for _, record in ipairs(cards.Records) do
				if (record.LastDamage or 0) > 0 then
					return record
				end
			end
		end, 1.5, "Swept zigzag cards failed real player collision/damage")
		local expected = Config.P3CardsDamage * (Config.Phase3PlayerDamageMultiplier or 0.65)
		assert(
			math.abs(hit.LastDamage - expected) < 0.01 and humanoid.Health < before,
			"Cards bypassed centralized Phase3 damage pipeline"
		)
		local lateral = false
		for _, record in ipairs(cards.Records) do
			if record.Part.Parent then
				local travelled = record.Part.Position - record.Origin
				local perpendicular = travelled - record.Direction * travelled:Dot(record.Direction)
				if perpendicular.Magnitude > 0.2 then
					lateral = true
				end
			end
		end
		assert(lateral, "Released cards are not zigzagging")
		waitFor(function()
			return cards.LastCast.closed
		end, 4, "Zigzag card cast exceeded bounded range/lifetime")
		assert(not Runtime.Effects:FindFirstChild("P3ThrownZigzagCard", true), "Expired card geometry leaked")
		marker("V6_NEW_SIX_SWEPT_ZIGZAG_CARDS_NATIVE_DAMAGE_AND_FINITE_CLEANUP", #cards.Records, hit.LastDamage)
		isolate()
		living()
		done = false
		task.spawn(function()
			cards.Combo(character)
			done = true
		end)
		waitFor(function()
			return Runtime.Effects:FindFirstChild("P3ThrownZigzagCard", true)
		end, 1, "Cards cancel fixture did not release")
		local cancelledCards = cards.LastCast
		setPhase(4)
		waitFor(function()
			return done and cancelledCards.closed
		end, 2, "Card volley survived phase cancellation")
		assert(not Runtime.Effects:FindFirstChild("P3ThrownZigzagCard", true), "Cancelled cards leaked")
		marker("V6_ZIGZAG_CARDS_PHASE_CLEANUP")
	end

	-- Actual phase 4 mechanics; appended inside the server driver's xpcall.
	do
		local Metadata = require(BossSystem.Combat.AbilityMetadata)
		local Story = require(BossSystem.Encounter.EncounterStory)
		local core = Registry.For(boss, "P1CombatCore")
		local bounds = assert(Placement.GetBounds())
		local function arenaPair(distance)
			local frame = assert(Placement.Validate(boss, CFrame.new(bounds.Frame.Position), { Margin = 8 }))
			boss.HumanoidRootPart.CFrame = frame
			boss.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
			placePlayer(frame.Position + Vector3.new(0, 0, -distance), frame.Position)
			core.Face(character)
		end
		local function exposeTarget()
			Encounter.CancelDefense(player)
			Status.Clear(player)
			Dash.Cancel(player, "Ascension fixture")
			character:SetAttribute("RespawnInvulnerableUntil", 0)
			character:SetAttribute("DashInvulnerableUntil", 0)
			character:SetAttribute("Stamina", PlayerConfig.MaxStamina)
			Immunity.Refresh(character)
			for _, v in ipairs(character:GetChildren()) do
				if v:IsA("ForceField") then
					v:Destroy()
				end
			end
			humanoid.Health = humanoid.MaxHealth
		end
		setPhase(4)
		arenaPair(24)
		local activeCount = 0
		for _, name in ipairs(Metadata.ActiveNames) do
			if Metadata.Available(name, 4) then
				local entry = Metadata.Get(name)
				assert(entry.NativePhase == 4, "Phase4 selected a prohibited native phase: " .. name)
				activeCount += 1
			end
		end
		assert(
			activeCount == 5 and not Metadata.Get("P4Swap(Linked)") and not Metadata.Get("P4AscensionToHell(Ultimate)"),
			"P4 linked swap survived retirement"
		)
		assert(
			Metadata.Available("P3Projectile", 3) and not Metadata.Available("P3Projectile", 4),
			"P3 projectile phase gate missing"
		)
		assert(
			not Metadata.Available("P1GildedCataclysm(Ultimate)", 4)
				and not Metadata.Available("P1.5RoyalBow(Ultimate)", 4),
			"P4 still retains old phase Ultimates"
		)
		assert(
			Config.Phase4ShieldMaxHealth == 2500 and Config.Phase4NormalAttackInterval == 0.6,
			"Phase4 requested shield/gap not centralized"
		)
		local passiveCount = 0
		for _, name in ipairs(Metadata.PassiveNames) do
			if Metadata.PassiveAvailable(name, 4) then
				assert(Metadata.Get(name).NativePhase == 4, "P4 retained an earlier phase passive")
				passiveCount += 1
			end
		end
		assert(
			passiveCount == 1 and not Metadata.Available("P4EnhancedNormalSlashes", 3),
			"P4 native passive/normal slash gates incorrect"
		)
		assert(
			Metadata.Available("P3Cards", 3)
				and not Metadata.Available("P3Cards", 4)
				and not Metadata.CanCopy("P3Cards", "HourDebt"),
			"New P3 card pool gates incorrect"
		)
		assert(
			not system.Attacks.P4:FindFirstChild("P4AscensionToHell(Ultimate)"),
			"Retired Ascension module remains installed"
		)
		marker("V6_PHASE4_FIVE_NATIVE_ACTIVE_ONE_PASSIVE_NO_EARLIER_PHASES", activeCount, passiveCount)

		-- Real shield damage consumes P3 overflow, plays the short story once,
		-- then commits a fresh shield while carrying the current health.
		setPhase(3)
		arenaPair(24)
		boss.Humanoid.Health = 4321
		boss:SetAttribute("BossHealth", 4321)
		local hp = boss.Humanoid.Health
		local damage = Registry.For(boss, "BossDamageService")
		assert(damage.ApplyDamage(100, character, {}), "Partial P3 shield damage rejected")
		assert(
			boss:GetAttribute("Phase") == 3 and boss:GetAttribute("Shield") == Config.Phase3ShieldMaxHealth - 100,
			"P3 entered P4 before its entire shield broke"
		)
		assert(damage.ApplyDamage(100000, character, {}), "P3 final shield damage rejected")
		assert(
			boss:GetAttribute("Phase4TransitionInProgress") and boss.Humanoid.Health == hp,
			"P3 overkill escaped the shield gate"
		)
		waitFor(function()
			return boss:GetAttribute("Phase") == 4 and not boss:GetAttribute("PhaseTransitionInProgress")
		end, 12, "Natural P4 short story never completed")
		assert(
			boss.Humanoid.Health == hp
				and boss:GetAttribute("Shield") == 2500
				and boss:GetAttribute("MaxShield") == 2500,
			"P4 did not carry HP/create2500 shield"
		)
		assert(
			boss:FindFirstChild("Basic Sword")
				and not boss:GetAttribute("Phase4LinkedActive")
				and not boss:GetAttribute("LinkedProtection"),
			"P4 weapon/obsolete Puppet state incorrect"
		)
		assert(
			boss:GetAttribute("LastDialogue") == Story.Phase4After[#Story.Phase4After],
			"P4 short dialogue did not finish"
		)
		sleep(0.15)
		assert(not Runtime.Summons:FindFirstChild("alterGolden's Puppeteer"), "True Clone returned in phase4")
		marker("V6_NATURAL_P3_SHIELD_P4_SHORT_STORY_HP_CARRY", hp, boss:GetAttribute("Shield"))

		setPhase(4)
		arenaPair(24)
		local regeneration = Registry.For(boss, "P4Regeneration(Passive)")
		hp = boss.Humanoid.Health
		boss:SetAttribute("Shield", 1000)
		assert(
			math.abs(regeneration.Apply(character, 100) - 20) < 0.001,
			"P4 damage did not regenerate configurable shield fraction"
		)
		assert(boss:GetAttribute("Shield") == 1020 and boss.Humanoid.Health == hp, "Regeneration changed HP")
		boss:SetAttribute("Shield", 2495)
		assert(
			regeneration.Apply(character, 100) == 5 and boss:GetAttribute("Shield") == 2500,
			"Regeneration overflowed shield cap"
		)
		boss:SetAttribute("Shield", 1000)
		exposeTarget()
		require(BossSystem.Combat.PassiveController).Start(boss, function()
			return character
		end)
		local actual = Encounter.Damage(character, 10, boss)
		assert(
			actual > 0
				and math.abs(boss:GetAttribute("Shield") - (1000 + actual * Config.Phase4RegenerationFraction))
					< 0.01,
			"Actual damage authority did not dispatch P4 shield regeneration"
		)
		assert(boss.Humanoid.Health == hp, "Actual damage regeneration healed HP")
		pause()
		protect()
		marker("V6_PHASE4_ACTUAL_REGEN_SHIELD_ONLY_CAP", actual)

		-- Pure probability boundaries and the actual director's pacing. Temporary
		-- module overrides exercise scheduling without launching unrelated hazards.
		local minRng = {
			NextNumber = function()
				return 0.349
			end,
			NextInteger = function(_, a)
				return a
			end,
		}
		local maxRng = {
			NextNumber = function()
				return 0.349
			end,
			NextInteger = function(_, _, b)
				return b
			end,
		}
		local missRng = {
			NextNumber = function()
				return 0.35
			end,
		}
		assert(
			Selector.ComboCount(boss, minRng) == 2
				and Selector.ComboCount(boss, maxRng) == 5
				and Selector.ComboCount(boss, missRng) == 1,
			"35% combo/2-5 boundary incorrect"
		)
		local entries = {}
		for _, name in ipairs(Metadata.ActiveNames) do
			table.insert(entries, { Name = name, Skill = Registry.For(boss, name) })
		end
		assert(Selector.ReadyCount(entries, character, boss) >= 2, "Director fixture lacks two eligible skills")
		local originalChoose, originalCount = Selector.Choose, Selector.ComboCount
		local calls = {}
		local plan = 3
		local fake = {
			Name = "P4EnhancedRangedSlashes",
			Skill = {
				Cooldown = 0,
				Combo = function()
					table.insert(calls, workspace:GetServerTimeNow())
					return true
				end,
			},
		}
		local scheduleOk, scheduleError = xpcall(function()
			Selector.Choose = function()
				return fake
			end
			Selector.ComboCount = function()
				return plan
			end
			holdSelection = false
			boss:SetAttribute("NextAttackAt", workspace:GetServerTimeNow())
			boss:SetAttribute("AttackDelayMultiplier", 1)
			boss:SetAttribute("LastMinuteAttackMultiplier", 1)
			waitFor(function()
				return #calls >= 3 and not boss:GetAttribute("AttackInProgress")
			end, 4, "Actual three-move director combo did not finish")
			holdSelection = true
			assert(
				boss:GetAttribute("Phase4ComboMovesPlanned") == 3
					and boss:GetAttribute("Phase4ComboMovesCompleted") == 3,
				"Director combo count incorrect"
			)
			assert(
				calls[2] - calls[1] >= Config.Phase4ComboMoveGap - 0.05
					and calls[3] - calls[2] >= Config.Phase4ComboMoveGap - 0.05,
				"Combo attacks overlapped"
			)
			local gap = (boss:GetAttribute("NextAttackAt") or 0) - (boss:GetAttribute("AttackEndedAt") or 0)
			assert(math.abs(gap - 3) < 0.12, "Director did not wait3seconds after combo")
			plan = 1
			table.clear(calls)
			holdSelection = false
			boss:SetAttribute("NextAttackAt", workspace:GetServerTimeNow())
			waitFor(function()
				return #calls >= 1 and not boss:GetAttribute("AttackInProgress")
			end, 3, "Ordinary director attack did not finish")
			holdSelection = true
			gap = (boss:GetAttribute("NextAttackAt") or 0) - (boss:GetAttribute("AttackEndedAt") or 0)
			assert(math.abs(gap - 0.6) < 0.12, "Ordinary phase4 attack gap differs from.6seconds")
			marker("V6_DIRECTOR_REAL_3_MOVE_COMBO_3S_COOLDOWN_NORMAL_06", gap)
		end, debug.traceback)
		holdSelection = true
		Selector.Choose = originalChoose
		Selector.ComboCount = originalCount
		pause()
		assert(scheduleOk, scheduleError)

		setPhase(4)
		arenaPair(30)
		local knives = Registry.For(boss, "P4TargetingKnives")
		local burst = assert(knives.Release(character), "V6 sequential knives rejected")
		assert(
			burst.Targets == #Players:GetPlayers()
				and burst.Count
					== math.min(#Players:GetPlayers() * Config.P4KnifePerPlayerCount, Config.P4KnifeMaxKnives),
			"Knives skipped real living players or exceeded their bound"
		)
		local knife = waitFor(function()
			for _, r in ipairs(burst.Records) do
				if r.Target == character and r.State == "Aiming" then
					return r
				end
			end
		end, 2, "Selected player's real golden knife did not appear")
		local aimAt = workspace:GetServerTimeNow()
		local offset = knife.Position - root.Position
		assert(
			math.abs(Vector3.new(offset.X, 0, offset.Z).Magnitude - Config.P4KnifeSpawnRadius) < 1
				and Config.P4KnifeSpawnRadius >= 22,
			"Knife did not materialize far enough away"
		)
		assert(
			knife.Body:GetAttribute("GoldenKnife")
				and knife.Body.Material == Enum.Material.Metal
				and knife.Guard
				and #knife.KnifeParts >= 5,
			"Golden knife assembly is incomplete"
		)
		assert(
			(knife.Guard.Position - (knife.Body.CFrame * CFrame.new(0, 0, 1.18)).Position).Magnitude < 0.05,
			"Knife guard is detached from its blade"
		)
		local hasPoint, hasGrip = false, false
		for _, item in ipairs(knife.KnifeParts) do
			if item.Part.Name == "TargetedKnifePoint" then
				hasPoint = true
				assert(item.Part:FindFirstChildOfClass("SpecialMesh"), "Knife point lost tapered geometry")
			end
			if item.Part.Name == "TargetedKnifeGrip" then
				hasGrip = true
			end
			assert(
				(item.Part.Position - (knife.Body.CFrame * item.Offset).Position).Magnitude < 0.05,
				"Knife visual part not following its shared assembly"
			)
		end
		assert(hasPoint and hasGrip, "Golden knife missing point/hilt")
		local first = knife.InitialDirection
		local sideways = Vector3.new(-first.Z, 0, first.X).Unit
		placePlayer(root.Position + sideways * 8, boss.HumanoidRootPart.Position)
		sleep(0.2)
		assert(
			(knife.InitialDirection - first).Magnitude > 0.12 and knife.State == "Aiming",
			"1.5second yellow aiming did not track the moving player"
		)
		waitFor(function()
			return knife.State == "Cue"
		end, 2, "Knife did not commit its red heading")
		local redAt = workspace:GetServerTimeNow()
		local locked = knife.InitialDirection
		local at = knife.Position
		assert(
			redAt - aimAt >= 1.25 and knife.Body.Color.R > knife.Body.Color.G * 2,
			"Knife shortened yellow aim or omitted red cue"
		)
		local oldCharacter, oldHumanoid = character, humanoid
		oldHumanoid.Health = 0
		assert(oldHumanoid.Health <= 0, "Knife target did not actually die after red commitment")
		local respawnDone = false
		task.spawn(function()
			player:LoadCharacter()
			respawnDone = true
		end)
		waitFor(function()
			return knife.State == "Flying" or knife.Removed and (knife.Position - at).Magnitude > 1
		end, 0.25, "Fast red knife was cancelled when its original target died")
		assert(workspace:GetServerTimeNow() - redAt < 0.22, "Knife paused too long after turning red")
		assert(
			(knife.InitialDirection - locked).Magnitude < 0.001 and Config.P4KnifeSpeed == 230,
			"Committed knife changed heading or lost fast launch speed"
		)
		sleep(0.06)
		assert((knife.Travelled or 0) >= 5, "Fast knife failed its actual swept travel")
		waitFor(function()
			return respawnDone and player.Character ~= oldCharacter
		end, 15, "Actual dead knife target failed to respawn")
		bindCurrent()
		waitFor(function()
			return character:GetAttribute("R6AppearanceFinished") == true
		end, 12, "Knife respawn appearance did not finish")
		protect()
		knives.Dispose()
		marker("V6_GOLDEN_3D_KNIVES_FAR_15S_TRACK_RED_FAST_DEAD_TARGET_SURVIVES", burst.Targets, burst.Count)

		setPhase(4)
		arenaPair(30)
		local nearWall
		for _, x in ipairs({ 1, -1 }) do
			for _, z in ipairs({ 1, -1 }) do
				local corner =
					bounds.Frame:PointToWorldSpace(Vector3.new(x * (bounds.HalfX - 8), 0, z * (bounds.HalfZ - 8)))
				nearWall = nearWall or Placement.Validate(character, CFrame.new(corner), { Margin = 7 })
			end
		end
		assert(nearWall, "No clear actual near-wall knife fixture")
		root.CFrame = nearWall
		root.AssemblyLinearVelocity = Vector3.zero
		local edge = assert(knives.Release(character))
		waitFor(function()
			for _, r in ipairs(edge.Records) do
				if r.Target == character then
					return r
				end
			end
		end, 2, "Near-wall knife did not find an inward valid spawn")
		sleep(0.8)
		local edgeCount = 0
		for _, r in ipairs(edge.Records) do
			if r.Target == character then
				edgeCount += 1
				assert(
					r.SpawnDistance >= Config.P4KnifeSpawnRadius * 0.75,
					"Clamping spawned an unavoidable knife too close to the near-wall player"
				)
			end
		end
		assert(edgeCount >= 1, "Near-wall golden knife fixture omitted its target")
		knives.Dispose()
		protect()
		marker("V6_NEAR_WALL_KNIFE_SPACING_BOUNDED_INWARD_SEARCH", edgeCount)

		setPhase(4)
		local near = bounds.Frame:PointToWorldSpace(Vector3.new(0, 0, -bounds.HalfZ * 0.72))
		local far = bounds.Frame:PointToWorldSpace(Vector3.new(0, 0, bounds.HalfZ * 0.72))
		boss.HumanoidRootPart.CFrame = assert(Placement.Validate(boss, CFrame.lookAt(near, far), { Margin = 14 }))
		placePlayer(far, boss.HumanoidRootPart.Position)
		local rift = Registry.For(boss, "P4RiftColumn")
		assert(rift.Combo(character), "Wide long rift did not release")
		local columns = rift.LastColumns
		local count = #columns / 2
		assert(
			count >= 3 and #columns <= 24 and Config.P4RiftColumnRange == 145,
			"Long rift range/count not centralized"
		)
		for i = 1, count do
			assert(
				columns[i].Radius == 12 and (columns[i].Point - columns[#columns - i + 1].Point).Magnitude < 0.001,
				"Wide rift lost exact reverse path/12stud damage radius"
			)
		end
		local span = (columns[count].Point - columns[1].Point).Magnitude
		assert(span >= math.min(100, bounds.HalfZ * 1.1), "Rift did not cover a longer arena path")
		local warning = waitFor(function()
			return Runtime.Effects:FindFirstChild("RiftMainColumnWarning", true)
		end, 1, "Wide yellow rift warning missing")
		assert(
			math.abs(warning.Size.Y - 24) < 0.01 and warning.Color.R > warning.Color.B * 2,
			"Rift warning and requested AoE radius disagree"
		)
		local plume = waitFor(function()
			return Runtime.Effects:FindFirstChild("GoldenRiftExplosionColumn", true)
		end, 1.5, "Large golden rift explosion missing")
		assert(
			math.abs(plume.Size.Y - 24) < 0.01 and plume.Transparency >= 0.7,
			"Rift large AoE/low brightness incorrect"
		)
		waitFor(function()
			return plume.Parent and plume.Size.X >= 20
		end, 0.3, "Rift explosion did not grow into a proper column")
		assert(
			not Runtime.Effects:FindFirstChild("MainPurpleGroundRift", true)
				and not Runtime.Effects:FindFirstChild("MainRiftPurpleCrack", true),
			"Ground path lines returned"
		)
		waitFor(function()
			return rift.LastCast.closed
		end, 6, "Long rift outbound/return cleanup leaked")
		marker("V6_RIFT_145_RANGE_12_RADIUS_YELLOW_LARGE_OUTBOUND_RETURN", span, #columns)

		setPhase(4)
		arenaPair(26)
		exposeTarget()
		Time.SetPlayerTimer(character, "DefensiveUntil", 60)
		character:SetAttribute("DefensiveActive", true)
		Status.SetDebuffImmunity(character, true)
		local health = humanoid.Health
		local normal = Registry.For(boss, "P4EnhancedNormalSlashes")
		assert(
			normal.CanUse(character) and normal.Cooldown == Config.P4EnhancedNormalCooldown,
			"New enhanced normal factory unavailable"
		)
		local completed = boss:GetAttribute("EnhancedNormalCombosCompleted") or 0
		local visualCount = 0
		local watch = Runtime.Effects.DescendantAdded:Connect(function(v)
			if v.Name == "EnhancedXGoldenSwordRibbon" then
				visualCount += 1
			end
		end)
		local normalOk, normalError = xpcall(function()
			assert(normal.Combo(character), "Actual enhanced normal Combo failed")
			local record = assert(normal.LastSequence)
			assert(
				record.DashDistance >= 18 and record.NormalHits >= 1 and record.UppercutHits >= 1,
				"Enhanced combo did not dash, slash and uppercut a real defending player"
			)
			assert(
				table.concat(record.Stages, ",") == "Dash windup,Dash,Normal slash,Uppercut,Large X slash",
				"Enhanced normal stage order incorrect"
			)
			waitFor(function()
				return record.Wave.Hits[character]
			end, 1, "Large X swept slash missed the actual stationary defending player")
			local expected = Config.P4EnhancedNormalMeleeDamage
				+ Config.P4EnhancedNormalUppercutDamage
				+ Config.P4EnhancedNormalXDamage
			assert(
				math.abs(
					record.Damage[character]
						- (Config.P4EnhancedNormalMeleeDamage + Config.P4EnhancedNormalUppercutDamage)
				) < 0.01,
				"Melee/uppercut were reduced by defensive90percent"
			)
			assert(
				math.abs(health - humanoid.Health - expected) < 0.01
					and math.abs(record.Wave.Hits[character] - Config.P4EnhancedNormalXDamage) < 0.01,
				"Authoritative enhanced damage did not bypass defense precisely"
			)
			assert(
				visualCount == 2 and record.Wave.Width == 32 and record.Wave.Range == 70,
				"Large X has missing/unbounded visual arms"
			)
			assert(
				(boss:GetAttribute("EnhancedNormalCombosCompleted") or 0) == completed + 1,
				"Finite enhanced sequence did not complete exactly once"
			)
			waitFor(function()
				return record.Wave.Cast.closed
			end, 2, "Released X slash exceeded its finite range")
			marker("V6_ENHANCED_DASH_NORMAL_UPPERCUT_LARGE_X_MEDIUM_45_IGNORES_DEFENSE", expected, record.DashDistance)
		end, debug.traceback)
		watch:Disconnect()
		assert(normalOk, normalError)

		-- IgnoreDefense never bypasses other authorities, and the exact skill
		-- cannot grant this exception outside the real Phase4 owner.
		character:SetAttribute("DashInvulnerableUntil", workspace:GetServerTimeNow() + 0.5)
		Immunity.Refresh(character)
		assert(
			Encounter.Damage(character, 20, boss, nil, { Skill = "P4EnhancedNormalSlashes", IgnoreDefense = true }) == 0,
			"Enhanced defense bypass ignored Dash immunity"
		)
		character:SetAttribute("DashInvulnerableUntil", 0)
		Immunity.Refresh(character)
		local force = Instance.new("ForceField")
		force.Visible = false
		force.Parent = character
		assert(
			Encounter.Damage(character, 20, boss, nil, { Skill = "P4EnhancedNormalSlashes", IgnoreDefense = true }) == 0,
			"Enhanced defense bypass ignored ForceField"
		)
		force:Destroy()
		setPhase(3)
		exposeTarget()
		Time.SetPlayerTimer(character, "DefensiveUntil", 60)
		character:SetAttribute("DefensiveActive", true)
		Status.SetDebuffImmunity(character, true)
		local expected = require(BossSystem.Combat.DamageService).Resolve(
			20 * Config.Phase3PlayerDamageMultiplier,
			Encounter.Defense
		)
		local actual =
			Encounter.Damage(character, 20, boss, nil, { Skill = "P4EnhancedNormalSlashes", IgnoreDefense = true })
		assert(math.abs(actual - expected) < 0.01, "Defense bypass leaked outside phase4")
		marker("V6_ENHANCED_IGNORE_DEFENSE_PRESERVES_DASH_FORCEFIELD_PHASE_AUTHORITY", actual)

		setPhase(4)
		arenaPair(42)
		local finished = false
		task.spawn(function()
			normal.Combo(character)
			finished = true
		end)
		waitFor(function()
			return boss:GetAttribute("EnhancedNormalSlashState") == "Dash"
		end, 2, "Cancellation fixture did not reach enhanced dash")
		setPhase(3)
		local owned = boss.HumanoidRootPart.CFrame + Vector3.new(8, 0, 0)
		boss.HumanoidRootPart.CFrame = owned
		waitFor(function()
			return finished
		end, 3, "Cancelled enhanced dash coroutine survived")
		assert(
			(boss.HumanoidRootPart.Position - owned.Position).Magnitude < 0.1,
			"Enhanced dash wrote stale movement after transition"
		)
		assert(normal.LastSequence.Cast.closed, "Enhanced sequence lease survived interruption")
		setPhase(4)
		arenaPair(26)
		local before = boss:GetAttribute("EnhancedNormalXSlashesReleased") or 0
		finished = false
		task.spawn(function()
			normal.Combo(character)
			finished = true
		end)
		waitFor(function()
			return (boss:GetAttribute("EnhancedNormalXSlashesReleased") or 0) > before
		end, 3, "X cancellation fixture did not release")
		local wave = normal.LastWave
		setPhase(3)
		waitFor(function()
			return finished
		end, 3, "Interrupted X parent sequence survived")
		assert(
			wave.Cast.closed and not wave.Anchor.Parent,
			"Phase transition leaked the independent X visual/damage lease"
		)
		protect()
		pause()
		marker("V6_ENHANCED_DASH_AND_RELEASED_X_PHASE_CANCEL_OWNERSHIP_SAFE")
	end

	setPhase(4)
	require(BossSystem.Combat.PassiveController).Start(boss, function()
		return character
	end)
	marker("V6_FINAL_UI_SHIELDS_HEARTS_QUIET_MUSIC", client("UI", { Phase = 4 }))
	marker("V6_FINAL_CENTERED_UI_NO_PUPPETEER", client("UIV5", {}))
	pause()
	boss:SetAttribute("AIEnabled", false)
	if #audioLimitations == 0 then
		marker("PASS", #steps)
	else
		marker("MECHANICS_PASS_AUDIO_BLOCKED", audioLimitations)
	end
end, debug.traceback)
if not ok then
	marker("FAIL", tostring(err))
end
hold:Disconnect()
if boss and boss.Parent then
	pause()
	boss:SetAttribute("AIEnabled", false)
end
workspace:SetAttribute("RevisionTestMechanicsSuccess", ok)
workspace:SetAttribute("RevisionTestSuccess", ok and #audioLimitations == 0)
workspace:SetAttribute(
	"RevisionTestError",
	not ok and tostring(err) or #audioLimitations > 0 and table.concat(audioLimitations, "; ") or ""
)
workspace:SetAttribute("RevisionTestFinished", true)
connection:Disconnect()
print("REVISION_V6_TEST_FINISHED", ok, tostring(err or ""))
