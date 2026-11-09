local BossSystem = script:FindFirstAncestor("BossSystem")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local Strike = require(BossSystem.Attacks.Shared.P5StrikeCore)
local S = require(script.Parent.Style)
local V = require(BossSystem.Attacks.P4["P4DeathRoars(Ultimate)"].Visuals)  -- the P4 roar's yellow slash storm visuals
local Effects = require(BossSystem.Combat.EffectService)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Encounter = require(BossSystem.Players.PlayerEncounter)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)

local TAU = math.pi * 2
local I, R, W = S.Intro, S.Roar, S.Storm
-- the tick: a flat share of max HP that ignores defense and dash i-frames (the answer to it is Deflect)
local TICK = table.freeze({ Skill = S.Name, IgnoreDefense = true, IgnoreIFrames = true, ExactDamage = true })
local function lerp(a, b, t) return a + (b - a) * t end

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local rng = Random.new()
	local current

	function api.CanUse(target)
		return not current and c.CanStart(target) and not actor:GetAttribute("EncounterEnded")
			and not Time.IsStopped(actor) and Placement.GetBounds() ~= nil
	end

	function api.Combo(target)
		if not api.CanUse(target) then return false end
		local result = core.Perform(target, S.Name, function()
			local bounds = Placement.GetBounds()
			if not bounds then return false end
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local cast = Effects.NewCast(actor, S.Name, math.huge)
			current = cast
			local token = Http:GenerateGUID(false)
			local root = core.Root
			local original, anchored = root.CFrame, root.Anchored
			local priorInvulnerable = actor:GetAttribute("Invulnerable")
			local protection
			if S.Invulnerable then
				protection = Instance.new("ForceField")
				protection.Name = "DeathRoarProtection"
				protection.Visible = false
			end
			local ended = false
			local endAura, roarVoice, slashVoice, trail, fadeHighlight

			local function valid()
				return cast:Alive() and c.Valid() and not actor:GetAttribute("EncounterEnded")
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
			end
			local function waitFor(seconds)
				local ends = os.clock() + seconds
				repeat Run.Heartbeat:Wait() if not valid() then return false end until os.clock() >= ends
				return true
			end
			-- the client stages of the P4 roar ("DeathRoars"); NoText keeps its "DEATH ROARS" title card off the screen
			local function send(stage, data, onlyPlayer)
				data = data or {}
				data.Stage, data.Owner, data.Token = stage, actor, token
				data.Origin, data.Radius, data.NoText = data.Origin or root.Position, 800, true
				core.ScreenEffect("DeathRoars", data, onlyPlayer)
			end
			local function shake(intensity, duration)
				core.ScreenEffect("Shake", { Origin = root.Position, Radius = 400, Duration = duration, Intensity = intensity })
			end

			cast.OnDispose = function()
				if protection then protection:Destroy() end
				if S.Invulnerable and actor.Parent and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and not actor:GetAttribute("PhaseTransitionInProgress") then
					actor:SetAttribute("Invulnerable", priorInvulnerable)
				end
				if current == cast then current = nil end
				if endAura then endAura() endAura = nil end
				if roarVoice then roarVoice:Dispose() end
				if slashVoice then slashVoice:Dispose() end
				if trail then trail.Enabled = false trail:Clear() end
				if not ended then
					ended = true
					pcall(send, "End", { Interrupted = true })
				end
				if actor.Parent and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision then
					local frame = Placement.Validate(actor, root.CFrame, { Margin = 8 })
						or Placement.Validate(actor, original, { Margin = 8 })
					if frame then root.CFrame = frame end
					Time.SetAnchored(root, anchored)
				end
			end
			if S.Invulnerable then
				actor:SetAttribute("Invulnerable", true)
				protection.Parent = actor
			end

			local center = Placement.GroundPoint(bounds.Frame.Position, { Clamp = true }) or bounds.Frame.Position
			local floorY = center.Y
			local arenaData = { ArenaFrame = bounds.Frame, HalfX = bounds.HalfX, HalfZ = bounds.HalfZ, FloorY = floorY }
			local arenaCell = rng:NextInteger(0, 8)
			local diagonal = math.sqrt(bounds.HalfX ^ 2 + bounds.HalfZ ^ 2) * 2
			local function randomPoint()
				local cell = arenaCell
				arenaCell = (arenaCell + 1) % 9
				local x = ((cell % 3 + rng:NextNumber()) / 3 * 2 - 1) * bounds.HalfX
				local z = ((math.floor(cell / 3) + rng:NextNumber()) / 3 * 2 - 1) * bounds.HalfZ
				local point = bounds.Frame:PointToWorldSpace(Vector3.new(x, 0, z))
				return Vector3.new(point.X, floorY, point.Z)
			end
			local function swarm(point, radius, count) V.Swarm(cast, point, radius, count) end
			local function streak(lowOnly)
				local mid = randomPoint() + Vector3.new(0, lowOnly and rng:NextNumber(2, 10) or rng:NextNumber(3, 55), 0)
				local a = rng:NextNumber(0, TAU)
				local direction = Vector3.new(math.cos(a), rng:NextNumber(-0.45, 0.45), math.sin(a)).Unit
				local half = diagonal * rng:NextNumber(W.StreakSpan[1], W.StreakSpan[2]) / 2
				V.Streak(cast, mid - direction * half, mid + direction * half, rng:NextNumber(0.14, 0.32))
			end

			-- he takes the middle of the arena, facing his target
			local targetRoot = target:FindFirstChild("HumanoidRootPart")
			local floorRoot = core.FloorY(center + Vector3.new(0, 8, 0), core.Params())
			if floorRoot then
				local position = Vector3.new(center.X, floorRoot, center.Z)
				local look = targetRoot and targetRoot.Position or (position + root.CFrame.LookVector)
				c.Blink(CFrame.lookAt(position, Vector3.new(look.X, position.Y, look.Z)))
			end
			revision = actor:GetAttribute("MovementRevision") or 0  -- the blink above is ours, not an outside push
			Time.SetAnchored(root, true)
			core.Face(target)
			local sword = actor:FindFirstChild("Basic Sword")
			local blade = sword and sword:FindFirstChild("Blade")
			trail = blade and blade:FindFirstChild("SlashTrail")
			local function tip()
				if blade and blade.Parent then
					local size, frame = blade.Size, blade.CFrame
					local axis, half = frame.UpVector, size.Y / 2
					if size.X > size.Y and size.X > size.Z then axis, half = frame.RightVector, size.X / 2
					elseif size.Z > size.Y then axis, half = frame.LookVector, size.Z / 2 end
					local a, b = frame.Position + axis * half, frame.Position - axis * half
					return (a - root.Position).Magnitude > (b - root.Position).Magnitude and a or b
				end
				return root.Position + Vector3.new(0, 7, 0)
			end

			-- wind-up: the sword rises, gold gathers in the blade
			local tell = c.Tell(1)
			local raise, ignite, settle = I.Raise * tell, I.FirstStreaks * tell, math.max(0, (I.Duration - I.FirstStreaks) * tell)
			core.ScreenEffect("CombatAudioPreload", { Cue = "DeathRoarsSlash", Origin = root.Position, Radius = 800 })
			core.ScreenEffect("CombatAudioPreload", { Cue = "DeathRoarsRoar", Origin = root.Position, Radius = 800 })
			send("Intro", { Duration = ignite + settle, Raise = raise, Ignite = ignite, Center = center,
				ArenaFrame = arenaData.ArenaFrame, HalfX = arenaData.HalfX, HalfZ = arenaData.HalfZ, FloorY = floorY })
			fadeHighlight = V.Highlight(cast, actor, 0.85)
			core.Melee.Pose("Windup3", 0.35)
			Audio.Emit(actor, "RoyalFinalCharge", root)
			V.Gather(cast, tip, ignite, 48)
			endAura = V.Aura(cast, actor)
			if not waitFor(raise) then return false end
			core.PoseAngles(S.Poses.Raise, 0.25)
			if not waitFor(ignite - raise) then return false end

			-- the roar ignites: 5 seconds start counting here
			V.Ignite(cast, tip(), center, math.max(bounds.HalfX, bounds.HalfZ) * 1.2)
			Audio.Emit(actor, "CataclysmSlam", root)
			roarVoice = Audio.Loop(cast, actor, "DeathRoarsRoar", root)
			shake(1.1, 0.9)
			for _ = 1, 24 do streak(false) end
			V.Swarm(cast, tip(), 8, 10, 0.15)

			local roarStart = os.clock()
			local roarEnd = roarStart + R.Duration
			local barrageAt = roarStart + settle
			local barrageSent = false
			local ticks = math.max(1, math.floor(R.Duration / R.TickEvery + 1e-6))
			local tickIndex, warnedTick = 1, 0
			-- a Hold needs time to fill, so its shield cue starts earlier than a Tap's
			local lead = R.Deflect == "Hold" and (Config.DeflectHoldTime or 0.5) + 0.3 or (Config.DeflectWarnLead or 0.5)

			-- the roar lands on everyone in the arena; whoever Deflects it takes nothing
			local function tick()
				for _, char in ipairs(c.Targets()) do
					local h = char:FindFirstChildOfClass("Humanoid")
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if h and h.Health > 0 and hrp and Placement.Contains(hrp.Position) and not c.Deflected(char, R.Deflect) then
						local dealt = Encounter.Damage(char, h.MaxHealth * R.TickFraction, actor, nil, TICK)
						local player = Players:GetPlayerFromCharacter(char)
						if dealt > 0 and player then pcall(send, "Hit", { Heavy = true }, player) end
					end
				end
				actor:SetAttribute("P5DeathRoarTicks", (actor:GetAttribute("P5DeathRoarTicks") or 0) + 1)
			end

			local last = os.clock()
			local streaks, randoms = 0, 0
			local nextFollow = {}
			local nextIntro, nextSwing, nextShake = roarStart, roarStart, roarStart
			while true do
				Run.Heartbeat:Wait()
				if not valid() then return false end
				local now = os.clock()
				local dt = math.min(now - last, 0.1)
				last = now

				-- the slash storm proper begins once the short settle after the ignition is over
				if not barrageSent and now >= barrageAt then
					barrageSent = true
					send("Barrage", { Duration = math.max(0.1, roarEnd - now), ArenaFrame = arenaData.ArenaFrame,
						HalfX = arenaData.HalfX, HalfZ = arenaData.HalfZ, FloorY = floorY })
					core.PoseAngles(S.Poses.Command, 0.12)
					slashVoice = Audio.Loop(cast, actor, "DeathRoarsSlash", root)
					if trail then trail.Enabled = true end
				end

				-- ticks: shield cue first, then the hit
				while tickIndex <= ticks do
					local tickAt = roarStart + tickIndex * R.TickEvery
					if warnedTick < tickIndex and now >= tickAt - lead then
						warnedTick = tickIndex
						for _, char in ipairs(c.Targets()) do c.Warn(char, R.Deflect, math.max(0, tickAt - now) + 0.15) end
					end
					if now < tickAt then break end
					tickIndex += 1
					tick()
				end

				if barrageSent then
					local progress = math.clamp((now - barrageAt) / math.max(0.1, roarEnd - barrageAt), 0, 1)
					streaks += dt * lerp(W.StreakStart, W.StreakEnd, progress)
					while streaks >= 1 do
						streaks -= 1
						streak(rng:NextNumber() < 0.35)
					end
					for _, char in ipairs(c.Targets()) do
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp and now >= (nextFollow[char] or barrageAt + 0.3) then
							nextFollow[char] = now + lerp(W.FollowEvery[1], W.FollowEvery[2], progress) * rng:NextNumber(0.85, 1.15)
							swarm(hrp.Position + Vector3.new(0, rng:NextNumber(-0.5, 1), 0), W.FollowRadius,
								rng:NextInteger(W.FollowCrescents[1], W.FollowCrescents[2]))
						end
					end
					randoms += dt * lerp(W.RandomStart, W.RandomEnd, progress)
					while randoms >= 1 do
						randoms -= 1
						local spot = randomPoint() + Vector3.new(0, 3, 0)
						V.Glint(cast, spot, W.RandomGlint)
						cast:Schedule(W.RandomGlint, function()
							if valid() then swarm(spot, W.SwarmRadius, rng:NextInteger(W.Crescents[1], W.Crescents[2])) end
						end)
					end
					if now >= nextSwing then
						nextSwing = now + rng:NextNumber(0.08, 0.14)
						local pose = table.clone(S.Poses.Command)
						pose.RightShoulder = { 95 + rng:NextNumber(-40, 50), 0, 25 + rng:NextNumber(-45, 45) }
						pose.Waist = { 0, rng:NextNumber(-30, 15), 0 }
						core.PoseAngles(pose, 0.07)
					end
					if now >= nextShake then
						nextShake = now + 0.4
						shake(0.15 + 0.2 * progress, 0.35)
					end
				elseif now >= nextIntro then
					nextIntro = now + 0.12
					streak(false)
					streak(true)
				end

				if tickIndex > ticks and now >= roarEnd then break end
			end

			-- the roar falls silent: no finale, he just lowers the blade
			if roarVoice then roarVoice:Dispose() end
			if slashVoice then slashVoice:Dispose() end
			if trail then trail.Enabled = false trail:Clear() end
			if endAura then endAura() endAura = nil end
			core.Melee.Pose("Idle", 0.4)
			if fadeHighlight then fadeHighlight(S.Recover) end
			if not waitFor(S.Recover) then return false end
			ended = true
			cast:Dispose()
			send("End", {})
			return true
		end)
		if current then current:Dispose() end
		return result
	end

	function api.Dispose()
		if current then current:Dispose() end
	end
	return api
end