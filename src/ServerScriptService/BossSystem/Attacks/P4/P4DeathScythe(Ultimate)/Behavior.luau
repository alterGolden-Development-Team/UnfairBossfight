local BossSystem = script:FindFirstAncestor("BossSystem")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Style = require(script.Parent.Style)
local Visuals = require(script.Parent.Visuals)
local Effects = require(BossSystem.Combat.EffectService)
local Status = require(BossSystem.Combat.StatusEffectService)
local Cooldowns = require(BossSystem.Combat.AbilityCooldownService)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Encounter = require(BossSystem.Players.PlayerEncounter)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Dash = require(BossSystem.Players.R6DashService)
local Audio = require(BossSystem.Presentation.CombatAudio)
local NAME = "P4DeathScythe(Ultimate)"
local TAU = math.pi * 2
local WIND_TURNS = Style.WindupAngle / TAU  
local function smooth(a) return a * a * (3 - 2 * a) end
 
 
local function swingCurve(alpha) return 1 - (1 - alpha) ^ Style.SwingPower end
 
 
 
local function swungAt(alpha) return -WIND_TURNS + swingCurve(alpha) * (1 + WIND_TURNS) end
 
local function swingSpeed(alpha) return (1 - alpha) ^ (Style.SwingPower - 1) end

return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local api = { Cooldown = Style.Cooldown, IsUltimate = true, UltimatePhase = 4, ManagesCooldown = true }
	local current
	function api.CanUse(target)
		return not current and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4 and core.Active() and core.Alive(target)
			and (not actor:GetAttribute("IsGoldenClone") or actor:GetAttribute("PastClone") == true) and not actor:GetAttribute("PhaseTransitionInProgress")
			and not actor:GetAttribute("EncounterEnded") and not Time.IsStopped(actor)
			 -- Forced: P5 Wild Hunt ends on this scythe from inside its own ultimate, so it skips the gating
			and Placement.Contains(target.HumanoidRootPart.Position) and (api.Forced or Cooldowns.Ready(actor, NAME))
	end
	function api.Combo(target)
		if not api.CanUse(target) then return false end
		local goodbyeDuration = Audio.GetDuration("DeathScytheGoodbye", 2) or 1.42
		local haltDuration = math.max(Style.HaltDuration, goodbyeDuration + 0.12)
		 -- Quick (P5 Wild Hunt): no warning. He pulls the scythe out in a moment and goes straight to GOODBYE - no
		 -- GET READY / JUMP cue, no forming stage
		local quick = api.Quick == true
		local formation = quick and 0.35 or Style.FormationDuration
		local result = core.Perform(target, NAME, function()
			local bounds = Placement.GetBounds()
			local ground = Placement.GroundPoint(core.Root.Position, { Clamp = true })
			if not bounds or not ground then return false end
			Cooldowns.Start(actor, NAME, Style.Cooldown)
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local cast = Effects.NewCast(actor, NAME, 8)
			current = cast
			local token = Http:GenerateGUID(false)
			local lock = { TransitionControl = true }
			local held, connections, recipients = {}, {}, {}
			local goodbyeVoice
			local heads = actor:GetAttribute("DeathScytheHeadcount") or 0
			local height = Style.BaseSweepHeight + math.clamp(heads, 0, Style.MaxPowerHeads) * Style.HeightPerHead
			local targetPlayer = require(BossSystem.Combat.AttackTargetContinuity).Player(target)
			local targetRoot = target.HumanoidRootPart
   local actualTarget = require(BossSystem.Combat.AttackTargetContinuity).Character(target)
   local targetHumanoid = actualTarget and actualTarget:FindFirstChildOfClass("Humanoid")
			local targetPosition = targetRoot.Position
			local radius = 0
			for _, x in ipairs({ -bounds.HalfX, bounds.HalfX }) do
				for _, z in ipairs({ -bounds.HalfZ, bounds.HalfZ }) do
					radius = math.max(radius, (bounds.Frame:PointToWorldSpace(Vector3.new(x, 0, z)) - ground).Magnitude)
				end
			end
			radius = math.min(radius, Style.MaxReach or 400)
			core.Face(target)
			local bossFrame, bossAnchored = core.Root.CFrame, core.Root.Anchored
			Time.SetAnchored(core.Root, true)
			actor:SetAttribute("DeathScytheToken", token)
			actor:SetAttribute("DeathScytheHeadcount", heads)
			actor:SetAttribute("DeathScytheSweepHeight", height)
			actor:SetAttribute("DeathScytheReadyAt", workspace:GetServerTimeNow() + Style.Cooldown)
			actor:SetAttribute("DeathScytheTargetUserId", targetPlayer and targetPlayer.UserId or 0)
			local function valid()
				return cast:Alive() and core.Active() and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4
					and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
			end
			local function send(stage, duration, extra)
				for player in pairs(recipients) do
					if player.Parent == Players then
						local payload = { Owner = actor, Token = token, Stage = stage,
							Duration = duration, Headcount = actor:GetAttribute("DeathScytheHeadcount") or heads,
							TargetUserId = targetPlayer and targetPlayer.UserId or 0 }
						if extra then for key, value in pairs(extra) do payload[key] = value end end
						core.ScreenEffect("DeathScythe", payload, player)
					end
				end
			end
			local function release(character, record)
				if record.Released then return end
				record.Released = true
				if record.OwnsDamageGate then Encounter.SetDamageGate(character, cast, false) end
				Status.SetLocked(record.Player, lock, false)
				if character:GetAttribute("DeathScytheHaltToken") == token then
					character:SetAttribute("DeathScytheHaltToken", nil)
					if record.Root.Parent then
						Time.SetAnchored(record.Root, record.Anchored)
						if record.Humanoid.Health > 0 then
							record.Root.AssemblyLinearVelocity = record.Velocity
							record.Root.AssemblyAngularVelocity = record.AngularVelocity
						end
					end
				end
				for track, speed in pairs(record.Tracks) do pcall(function() track:AdjustSpeed(speed) end) end
			end
			local spinBase, spinPosition, spinRotation  
			cast.OnDispose = function()
				if goodbyeVoice then goodbyeVoice:Dispose() end
				for _, connection in ipairs(connections) do connection:Disconnect() end
				for character, record in pairs(held) do release(character, record) end
				 
				if spinBase and core.Root.Parent then
					core.Root.CFrame = CFrame.new(core.Root.Position) * spinBase.Rotation
				end
				spinBase = nil
				lock.closed = true
				send("End", 0)
				if actor:GetAttribute("DeathScytheToken") == token then
					actor:SetAttribute("DeathScytheToken", nil)
					actor:SetAttribute("DeathScytheStage", nil)
					actor:SetAttribute("DeathScytheTargetUserId", nil)
					if core.Root.Parent then Time.SetAnchored(core.Root, bossAnchored) end
				end
				if current == cast then current = nil end
			end
			local counted = false
			local function countTargetDeath()
				if counted or not valid() or (targetPlayer and targetPlayer:GetAttribute("ViewAsServer")) then return end
				counted = true
				actor:SetAttribute("DeathScytheHeadcount", (actor:GetAttribute("DeathScytheHeadcount") or 0) + 1)
			end
			if targetHumanoid then table.insert(connections, targetHumanoid.Died:Connect(countTargetDeath)) end
			local visual = Visuals.Build(core, cast, target, ground, radius + 4, height)
			 
			 
			local rig = actor:IsA("Model") and actor or core.Root.Parent
			local hand = rig:FindFirstChild("RightHand", true) or rig:FindFirstChild("Right Arm", true)
			local gripAttachment = hand and hand:FindFirstChild("RightGripAttachment")
			local function pivotPosition()
				if gripAttachment and gripAttachment.Parent then return gripAttachment.WorldPosition end
				if hand and hand.Parent then return (hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, 0)).Position end
				return (bossFrame * CFrame.new(3, 1, -1)).Position  
			end
			local function aim()
				local delta = (targetRoot.Parent and targetRoot.Position or targetPosition) - ground
				return math.atan2(delta.Z, delta.X) - 0.35
			end
			local bladeAngle = aim()
			 
			 
			 
			 
			local growSpan = math.max(formation + haltDuration, 0.001)
			local formingShare = formation / growSpan  
			local function grow(growth, angle)
				visual.Grow(growth, angle or bladeAngle, pivotPosition())
			end
			local function animate(seconds, callback, interval)  
				local began, lastVisual = os.clock(), -math.huge
				repeat
					if not valid() then return false end
					local elapsed = os.clock() - began
					local alpha = math.clamp(elapsed / math.max(seconds, 0.001), 0, 1)
					local draw = elapsed - lastVisual >= (interval or 1 / 30) or alpha == 1
					if draw then lastVisual = elapsed end
					for character, record in pairs(held) do
						if not record.Released then
							if record.Player.Character ~= character or not core.Alive(character) then
								release(character, record)
							else
								record.Root.CFrame = record.Frame
							end
						end
					end
					callback(alpha, draw)
					if alpha >= 1 then return true end
					Run.Heartbeat:Wait()
				until false
			end
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				if core.Alive(character) and Placement.Contains(character.HumanoidRootPart.Position) then recipients[player] = true end
			end
			actor:SetAttribute("DeathScytheStage", "Forming")
			actor:SetAttribute("AttackState", quick and "Death Scythe" or "Death Scythe: get ready")
			core.PoseAngles({ RightShoulder = { 135, 0, -35 }, LeftShoulder = { 85, 0, 40 } }, 0.1)
			grow(0)
			if not quick then send("Forming", Style.FormationDuration, { FormationDuration = Style.FormationDuration, HaltDuration = haltDuration,
				ImpactDuration = Style.ImpactDuration, SweepDuration = Style.SweepDuration, JumpCueLead = Style.JumpCueLead, Origin = ground, Radius = radius, SweepHeight = height })
			visual.Stage("Forming") end
			Audio.Emit(actor, "CataclysmStomp", core.Root)
			local cueAt, cued = quick and math.huge or math.max(Style.FormationDuration - Style.JumpCueLead, 0), false
			if not animate(formation, function(alpha, draw)
				if not cued and alpha * formation >= cueAt then
					cued = true  
					actor:SetAttribute("AttackState", "Death Scythe: JUMP!")
				end
				if draw then bladeAngle = aim(); grow(alpha * formingShare) end
			end) then return false end
			local targetDelta = (targetRoot.Parent and targetRoot.Position or targetPosition) - ground
			local startAngle = math.atan2(targetDelta.Z, targetDelta.X) - 0.35
			bladeAngle = startAngle
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				if not core.Alive(character) or not Placement.Contains(character.HumanoidRootPart.Position) then continue end
				if ((character.HumanoidRootPart.Position - ground) * Vector3.new(1, 0, 1)).Magnitude > radius + 4 then continue end
				local root, humanoid = character.HumanoidRootPart, character.Humanoid
				local leg = humanoid.RigType == Enum.HumanoidRigType.R6 and character:FindFirstChild("Right Leg")
				local standingHeight = root.Size.Y * 0.5 + humanoid.HipHeight + (leg and leg.Size.Y or 0)
				local delta = root.Position - ground
				local record = { Player = player, Root = root, Humanoid = humanoid, Frame = root.CFrame,
					Anchored = root.Anchored, Velocity = root.AssemblyLinearVelocity, AngularVelocity = root.AssemblyAngularVelocity,
					Tracks = {}, Safe = root.Position.Y - standingHeight > ground.Y + height,
					HitAt = ((startAngle - math.atan2(delta.Z, delta.X)) % TAU) / TAU }
				record.OwnsDamageGate = Encounter.SetDamageGate(character, cast, true)
				held[character] = record
				recipients[player] = true
				Dash.Cancel(player, "Death Scythe halt")
				Status.SetLocked(player, lock, true)
				character:SetAttribute("DeathScytheHaltToken", token)
				Time.SetAnchored(root, true)
				root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
				local animator = humanoid:FindFirstChildOfClass("Animator")
				if animator then
					for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
						record.Tracks[track] = track.Speed
						track:AdjustSpeed(0)
					end
				end
			end
			actor:SetAttribute("DeathScytheStage", "Halted")
			actor:SetAttribute("AttackState", "Death Scythe: GOODBYE")
			actor:SetAttribute("LastDialogue", "GOODBYE")
			send("Halted", haltDuration + Style.ImpactDuration + Style.SweepDuration, { HaltDuration = haltDuration,
				ImpactDuration = Style.ImpactDuration, SweepDuration = Style.SweepDuration, Origin = ground, Radius = radius, SweepHeight = height })
			visual.Stage("Halted")
			goodbyeVoice = Audio.StartFinite(actor, "DeathScytheGoodbye", core.Root, { Valid = valid })
			 
			 
			spinBase = core.Root.CFrame
			spinPosition, spinRotation = spinBase.Position, spinBase.Rotation
			local function turn(swung)
				 
				core.Root.CFrame = CFrame.new(spinPosition) * CFrame.Angles(0, swung * TAU, 0) * spinRotation
			end

			 
			 
			if not animate(haltDuration, function(alpha, draw)
				if draw then
					local swung = -WIND_TURNS * smooth(alpha)
					turn(swung)
					grow(formingShare + alpha * (1 - formingShare), startAngle - swung * TAU)
				end
			end, 0) then return false end

			 
			 
			 
			 
			local windAngle = startAngle + Style.WindupAngle
			visual.Stage("Impact")
			core.PoseAngles({ RightShoulder = { 25, 0, 65 }, LeftShoulder = { 20, 0, -40 }, Waist = { 0, -45, 0 } }, Style.ImpactDuration * 0.8)
			if not animate(Style.ImpactDuration, function(alpha, draw)
				if draw then visual.Hold(alpha, windAngle, pivotPosition()) end
			end, 0) then return false end

			 
			actor:SetAttribute("DeathScytheStage", "Sweeping")
			Audio.Emit(actor, "SplittingSlashRelease", core.Root)
			visual.Stage("Sweeping")
			visual.Latch(pivotPosition(), spinPosition, windAngle)  
			if not animate(Style.SweepDuration, function(alpha, draw)
				local swung = swungAt(alpha)
				if draw then
					turn(swung)
					visual.Sweep(startAngle - swung * TAU, swingSpeed(alpha))
				end
				for character, record in pairs(held) do
					if not record.Checked and swung >= record.HitAt then
						record.Checked = true
						if not record.Safe and not record.Released and record.Player.Character == character then
							if Encounter.ExecuteHit(character, Style.LivesCost, NAME, cast) then
								actor:SetAttribute("DeathScytheHits", (actor:GetAttribute("DeathScytheHits") or 0) + 1)
								if character == target then countTargetDeath() end
							end
						end
					end
				end
			end, 0) then return false end  
			core.Root.CFrame = spinBase  
			spinBase = nil
			visual.HideSweep()
			for character, record in pairs(held) do release(character, record) end
			send("End", 0)
			actor:SetAttribute("DeathScytheStage", "Recovering")
			visual.Stage("Recovering")
			return animate(0.2, function(alpha, draw) if draw then visual.Fade(alpha) end end)
		end)
		if current then current:Dispose() end
		return result
	end
	function api.Dispose()
		if current then current:Dispose() end
	end
	return api
end

