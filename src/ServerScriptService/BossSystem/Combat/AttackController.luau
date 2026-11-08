local BossSystem = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Registry = require(BossSystem.Combat.AttackRegistry)
local Selector = require(BossSystem.Combat.AttackSelector)
local Passives = require(BossSystem.Combat.PassiveController)
local Cooldowns = require(BossSystem.Combat.AbilityCooldownService)
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Locomotion = require(BossSystem.Boss.BossLocomotion)
local Modes = require(BossSystem.Combat.P5ModeService)
local api = {}
local running = setmetatable({}, { __mode = "k" })
 -- the phase 5 rhythm: fast without a mode, calm inside one (P5ModeService)
local function phase5Gap(actor)
	local gap = Modes.Active(actor) and (Config.Phase5ModeAttackGap or 0.75) or (Config.Phase5NormalAttackGap or 0.35)
	return gap * Difficulty.Get(actor).Recovery  -- the difficulty (and the Enraged Gate) sets the rhythm
end
 
local function showOpening(actor, seconds)
	local old = actor:FindFirstChild("MercyOpening")
	if old then
		old:Destroy()
	end
	local glow = Instance.new("Highlight")
	glow.Name = "MercyOpening"
	glow.FillColor = Difficulty.Get(actor).Color
	glow.OutlineColor = Color3.new(1, 1, 1)
	glow.FillTransparency = 0.72
	glow.OutlineTransparency = 0.1
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = actor
	task.delay(seconds, function()
		if glow.Parent then
			glow:Destroy()
		end
	end)
end
 
local function showTell(actor, seconds)
	local root = actor:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local Effects = require(BossSystem.Combat.EffectService)
	local Golden = require(BossSystem.Attacks.Shared.P4GoldenFX)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local ctx = Golden.Context(core)
	local cast = Effects.NewCast(actor, "AttackTell", seconds + 0.6)
	local color = Difficulty.Get(actor).Color
	Golden.FX.Glint(ctx, cast, root.Position + Vector3.new(0, 3.2, 0), color, 4, seconds + 0.1)
	Golden.FX.Ring(ctx, cast, CFrame.new(root.Position - Vector3.new(0, 2.8, 0)) * CFrame.Angles(math.pi / 2, 0, 0), 10, 2, seconds, color, 0.2, 0.45)
end
function api.Start(actor)
	if running[actor] then
		return
	end
	running[actor] = true
	local h = actor.Humanoid
	local normal = Registry.For(actor, "P1NormalSlash")
	local function entries(names)
		local result = {}
		local sliceStarted = os.clock()
		for _, name in ipairs(names) do
			if not actor.Parent or h.Health <= 0 or actor:GetAttribute("EncounterEnded") then return nil end
			table.insert(result, { Name = name, Skill = Registry.For(actor, name) })
			if os.clock() - sliceStarted >= 0.003 then
				game:GetService("RunService").Heartbeat:Wait()
				sliceStarted = os.clock()
			end
		end
		return result
	end
	local attacks = entries(Metadata.ActiveNames)
	local goldenHour = entries(Metadata.TimeStopNames)
	if not attacks or not goldenHour or not actor.Parent or actor:GetAttribute("EncounterEnded") then
		running[actor] = nil
		Registry.Release(actor)
		return
	end
	Passives.Start(actor, normal.GetTarget)
	task.spawn(function()
		local lastName, repeatCount, hourLast, hourRepeat, hourSequence, hourIndex
		local nextSetup = 0
		while actor.Parent and h.Health > 0 and not actor:GetAttribute("EncounterEnded") do
			require(BossSystem.Phases.PhaseController).Recover(actor)
			Modes.Update(actor)  -- phase 5 mode rotation (Space / Natural / Time)
			 -- anything that disposed the passive record (a transition's CancelOwner, a stun) brings it back once
			 -- the fight resumes; without this the Debuffer, Regeneration etc. stayed off for the rest of the fight
			if not Passives.Running(actor) and actor:GetAttribute("AIEnabled") ~= false
				and not actor:GetAttribute("PhaseTransitionInProgress") and not actor:GetAttribute("EncounterEnded") then
				Passives.Start(actor, normal.GetTarget)
			end
			local now = workspace:GetServerTimeNow()
			local target = normal.GetTarget()
			local stopped = Time.IsGoldenHour(actor)
			if
				actor:GetAttribute("AIEnabled") ~= false
				and not actor:GetAttribute("PhaseTransitionInProgress")
				and not actor:GetAttribute("PhaseTransitionQueued")  -- a phase change waits for this attack, then starts
				and not actor:GetAttribute("MysteriousGuyPunching")  -- the shadow caught someone; he is mid-punch
				and not actor:GetAttribute("ExecutionLocked")
				and not actor:GetAttribute("FutureSightDodging")
    and now>=(actor:GetAttribute("ClassStunnedUntil") or 0)
    and actor:GetAttribute("ClassStunFrame")==nil
			then
				 
				 
				if not stopped and not actor:GetAttribute("AttackInProgress") then
					Locomotion.UpdateApproach(actor, target, 0.1)
				end
				if stopped then
					local token = Time.ActiveStop(actor)
					if token and hourSequence ~= token.sequence then
						hourSequence = token.sequence
						hourLast = nil
						hourRepeat = 0
						hourIndex = 0
						nextSetup = now
					end
				end
				local ready = stopped and now >= nextSetup
					or not stopped and now >= (actor:GetAttribute("NextAttackAt") or 0)
					and workspace:GetServerTimeNow() >= (actor:GetAttribute("ClassStunnedUntil") or 0)  
				local chosen
				local comboPlanned = 1
				if not actor:GetAttribute("AttackInProgress") and target and ready then
					if not stopped then
						target = normal.GetTarget(true)
					end
					if stopped then
						 
						 
						 
						 
						 
						for offset = 1, #goldenHour do
							local index = ((hourIndex or 0) + offset - 1) % #goldenHour + 1
							local entry = goldenHour[index]
							if
								Cooldowns.Ready(actor, entry.Name)
								and (not entry.Skill.CanUse or entry.Skill.CanUse(target))
							then
								chosen = entry
								hourIndex = index
								break
							end
						end
					else
						local wanted = Selector.ComboCount(actor, nil, target)
						if wanted > 1 then
							local available = Selector.ReadyCount(attacks, target, actor, "Combo")
							 
							local phaseNow = actor:GetAttribute("Phase") or 0
							local need = phaseNow < 5 and math.min(4, math.floor(phaseNow)) == 4 and 3 or 2
							if available >= need then comboPlanned = math.min(wanted, available) end
						end
						chosen = Selector.Choose(
							attacks,
							target,
							lastName,
							repeatCount or 0,
							nil,
							actor:GetAttribute("Phase") or 1,
							actor,
							comboPlanned > 1 and "Combo" or "Active"
						)
					end
				end
				if chosen then
					actor:SetAttribute("AttackSelectionCategory", stopped and "GoldenHour" or "Active")
					local generation = actor:GetAttribute("PhaseGeneration") or 0
					local attackToken = {}
					actor:SetAttribute("ActiveAttackToken", tostring(attackToken))
					local planned = chosen.Skill.IsUltimate and 1 or comboPlanned
					local isCombo = planned > 1
					actor:SetAttribute("Phase4ComboActive", isCombo)
					actor:SetAttribute("Phase4ComboMovesPlanned", planned)
					actor:SetAttribute("Phase4ComboMovesCompleted", 0)
					local completed = 0
					local lastWasUltimate = false
					local function owns()
						return actor.Parent
							and h.Health > 0
							and not actor:GetAttribute("EncounterEnded")
							and actor:GetAttribute("AIEnabled") ~= false
							and not actor:GetAttribute("PhaseTransitionInProgress")
							and (actor:GetAttribute("PhaseGeneration") or 0) == generation
							and actor:GetAttribute("ActiveAttackToken") == tostring(attackToken)
					end
					actor:SetAttribute("AttackInProgress", true)
					actor:SetAttribute("AttackStartedAt", now)
					if isCombo then
						actor:SetAttribute("Phase4ComboStartedAt", now)
					end
					local move = 0
					local chained, comboFollowed = false, false
					while move < planned do  -- a while loop: a Phase 5 chain can extend `planned`
						move += 1
						if not owns() or not chosen or move > 1 and actor:GetAttribute("PhaseTransitionQueued") then
							break  -- a queued phase change ends the combo after the move in progress
						end
						if stopped then
							hourRepeat = chosen.Name == hourLast and (hourRepeat or 0) + 1 or 1
							hourLast = chosen.Name
							nextSetup = workspace:GetServerTimeNow() + Config.GoldenHourSetupInterval
						else
							repeatCount = chosen.Name == lastName and (repeatCount or 0) + 1 or 1
							lastName = chosen.Name
							actor:SetAttribute("LastAttackName", lastName)
							actor:SetAttribute("ConsecutiveAttackCount", repeatCount)
						end
						actor:SetAttribute("CurrentAttackFile", chosen.Name)
						 
						local tell = not stopped and (Difficulty.Mercy("Tell", actor) or 0) or 0
						if not stopped then
							tell = require(BossSystem.Combat.DifficultyPassive).Tell(actor, tell)  
						end
						local tuning = Metadata.Get(chosen.Name)
						if tuning and tuning.UnscaledDifficulty then tell = 0 end
						if tell > 0 then
							if chosen.Skill.IsUltimate then
								tell *= 1.6
							end
							actor:SetAttribute("AttackTell", chosen.Name)
							pcall(showTell, actor, tell)
							local tellEnds = workspace:GetServerTimeNow() + tell
							repeat
								task.wait(0.03)
							until not owns() or workspace:GetServerTimeNow() >= tellEnds
							if not owns() then
								break
							end
						end
						if not chosen.Skill.ManagesCooldown then
							Cooldowns.Start(actor, chosen.Name, chosen.Skill.Cooldown)
						end
						local debt = not stopped and Passives.OnAttackStarted(actor, chosen.Name, target)
						require(BossSystem.Presentation.CombatAudio).Attack(
							actor,
							chosen.Name,
							"Cast",
							actor:FindFirstChild("HumanoidRootPart")
						)
						lastWasUltimate = chosen.Skill.IsUltimate == true
						local ok, result = xpcall(chosen.Skill.Combo, debug.traceback, target)
						if not ok then
							warn(chosen.Name .. ": " .. tostring(result))
						end
						if chosen.Skill.IsUltimate and (not ok or result == false) then
							actor:SetAttribute("LastUltimateFailure", chosen.Name .. ": " .. (ok and "Cast cancelled or rejected" or tostring(result)))
							actor:SetAttribute("LastUltimateFailedAt", workspace:GetServerTimeNow())
						end
						Passives.OnAttackFinished(debt, ok and result ~= false)
						if ok and result ~= false then
							pcall(function()
								require(BossSystem.Combat.TPService).OnSkill(actor, chosen.Name, Metadata.Get(chosen.Name))
							end)
						end
						if not ok or result == false or not owns() then
							break
						end
						completed += 1
						actor:SetAttribute("Phase4ComboMovesCompleted", completed)
						-- Phase 5 chains (EncounterConfig.Phase5UltimateChain / Phase5Combos): straight into the
						-- next move with no gap - a phase 5 skill right after an ultimate, or a set follow-up
						-- (black hole -> dying star on the pull point, iris star -> borealis)
						local chainNow = false
						if not stopped and (actor:GetAttribute("Phase") or 0) >= 5 then
							if chosen.Skill.IsUltimate then
								if Config.Phase5UltimateChain ~= false and not chained then
									chained = true
									target = normal.GetTarget(true)
									local filler = target and Selector.Choose(attacks, target, lastName, repeatCount or 0, nil, actor:GetAttribute("Phase") or 5, actor, "Combo")
									if filler then
										chosen, planned, chainNow = filler, move + 1, true
									end
								end
							else
								local follow = Config.Phase5Combos and Config.Phase5Combos[chosen.Name]
								if follow and not comboFollowed and Modes.Allows(actor, follow) then
									for _, entry in ipairs(attacks) do
										if entry.Name == follow then
											-- the follow-up ignores its own cooldown (it restarts it when cast)
											local held = Cooldowns.Take(actor, follow)
											if entry.Skill.CanUse and entry.Skill.CanUse(target) then
												comboFollowed = true
												chosen, planned, chainNow = entry, move + 1, true
											else
												Cooldowns.Put(actor, follow, held)
											end
											break
										end
									end
								end
							end
						end
						if chosen.Skill.IsUltimate and not chainNow then break end
						if move < planned and not chainNow then
							local ends = workspace:GetServerTimeNow()
								+ ((actor:GetAttribute("Phase") or 0) >= 5 and phase5Gap(actor)
									or math.clamp(Config.Phase4ComboMoveGap or 0.2, 0.1, 0.6)) * Difficulty.Get(actor).Recovery
							repeat
								task.wait(0.03)
							until not owns() or workspace:GetServerTimeNow() >= ends
							if not owns() then
								break
							end
							target = normal.GetTarget(true)
							chosen = target
									and Selector.Choose(
										attacks,
										target,
										lastName,
										repeatCount or 0,
										nil,
										actor:GetAttribute("Phase") or 4,
										actor,
										"Combo"
									)
								or nil
						end
					end
					 
					if
						(actor:GetAttribute("PhaseGeneration") or 0) == generation
						and actor:GetAttribute("ActiveAttackToken") == tostring(attackToken)
					then
						local finishedAt = workspace:GetServerTimeNow()
						actor:SetAttribute("AttackInProgress", false)
						actor:SetAttribute("AttackEndedAt", finishedAt)
						local opening = not stopped and (Difficulty.Mercy("Opening", actor) or 0) or 0
						if opening > 0 and completed > 0 then
							if lastWasUltimate then
								opening *= 1.5
							end
							actor:SetAttribute("ExposedUntil", finishedAt + opening)
							pcall(showOpening, actor, opening)
						end
						actor:SetAttribute("ActiveAttackToken", nil)
						actor:SetAttribute("Phase4ComboActive", false)
						if isCombo then
							actor:SetAttribute("Phase4ComboFinishedAt", finishedAt)
							actor:SetAttribute(
								"Phase4CombosCompleted",
								(actor:GetAttribute("Phase4CombosCompleted") or 0) + 1
							)
						end
						if not stopped then
							local phase = actor:GetAttribute("Phase") or 1
							local gap = phase >= 5 and phase5Gap(actor)
								or phase >= 4 and (Config.Phase4NormalAttackInterval or 0.5)
								or phase >= 3 and Config.Phase3NormalAttackInterval
								or Config.NormalAttackInterval
							local delay = phase >= 4 and gap
								or gap * (actor:GetAttribute("AttackDelayMultiplier") or 1)
									* (actor:GetAttribute("LastMinuteAttackMultiplier") or 1)
							actor:SetAttribute("NextAttackAt", finishedAt + delay * Difficulty.Get(actor).Recovery)
							if isCombo then
								actor:SetAttribute("Phase4ComboReadyAt", finishedAt + Selector.ComboCooldown(actor))
							end
						end
					end
				end
				if not Time.IsGoldenHour(actor) and actor:GetAttribute("AttackSelectionCategory") == "GoldenHour" then
					actor:SetAttribute("AttackSelectionCategory", "Active")
					actor:SetAttribute("CurrentAttackFile", "Idle")
					actor:SetAttribute("NextAttackAt", math.min(actor:GetAttribute("NextAttackAt") or now, now + 0.15))
				end
			end
			local remaining = (Time.IsGoldenHour(actor) and nextSetup or (actor:GetAttribute("NextAttackAt") or 0))
				- workspace:GetServerTimeNow()
			task.wait(remaining > 0 and math.min(0.1, remaining) or 0.1)
		end
		running[actor] = nil
		Passives.Stop(actor)
		require(BossSystem.Combat.UltimateService).Cancel(actor, "Attack controller ended")
		Cooldowns.Clear(actor)
		Time.ClearOwner(actor)
		require(BossSystem.Boss.GoldenGuardService).Clear(actor)
		require(BossSystem.Mechanics.Clones.CloneController).CancelAll(actor)
		require(BossSystem.Mechanics.Reality.RealityController).Cancel(actor)
		require(BossSystem.Combat.CataclysmQTEService).CancelForActor(actor, "boss ended")
		Registry.Release(actor)
	end)
end
api.ActiveNames = Metadata.ActiveNames
api.GoldenHourNames = Metadata.TimeStopNames
return api