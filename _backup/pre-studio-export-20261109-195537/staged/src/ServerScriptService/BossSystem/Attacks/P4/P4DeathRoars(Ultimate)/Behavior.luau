local BossSystem = script:FindFirstAncestor("BossSystem")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local Style = require(script.Parent.Style)
local V = require(script.Parent.Visuals)
local Effects = require(BossSystem.Combat.EffectService)
local Cooldowns = require(BossSystem.Combat.AbilityCooldownService)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Encounter = require(BossSystem.Players.PlayerEncounter)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Audio = require(BossSystem.Presentation.CombatAudio)
local NAME = "P4DeathRoars(Ultimate)"
local TAU = math.pi * 2
local I, B = Style.Intro, Style.Barrage
 
local PIERCE = table.freeze({ Skill = NAME, IgnoreDefense = true, IgnoreIFrames = true, HealthDrain = true })
local FINISHER = table.freeze({ Skill = NAME, IgnoreDefense = true, IgnoreIFrames = true, ExactDamage = true, Finisher = true })
local function lerp(a, b, t) return a + (b - a) * t end

return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local api = { Cooldown = Style.Cooldown, IsUltimate = true, UltimatePhase = 4, ManagesCooldown = true }
	local rng = Random.new()
	local current
	function api.CanUse(target)
		return not current and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4 and core.Active() and core.Alive(target)
			and (not actor:GetAttribute("IsGoldenClone") or actor:GetAttribute("PastClone") == true) and not actor:GetAttribute("PhaseTransitionInProgress")
			and not actor:GetAttribute("EncounterEnded") and not Time.IsStopped(actor)
			and Placement.GetBounds() ~= nil and Cooldowns.Ready(actor, NAME)
	end
	function api.Combo(target)
		if not api.CanUse(target) then return false end
		local result = core.Perform(target, NAME, function()
			local bounds = Placement.GetBounds()
			if not bounds then return false end
			Cooldowns.Start(actor, NAME, Style.Cooldown)
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local cast = Effects.NewCast(actor, NAME, math.huge)
			current = cast
			local token = Http:GenerateGUID(false)
			local root = core.Root
			local original, anchored = root.CFrame, root.Anchored
			local priorInvulnerable = actor:GetAttribute("Invulnerable")
			local protection = Instance.new("ForceField")
			protection.Name = "DeathRoarsProtection"
			protection.Visible = false
			local ended = false
			local healthCaps={}
			local endAura, roarVoice, slashVoice, trail, roarEndsAt
			local function valid()
				return cast:Alive() and core.Active() and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4
					and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
			end
			local function waitFor(seconds)
				local ends = os.clock() + seconds
				repeat Run.Heartbeat:Wait() if not valid() then return false end until os.clock() >= ends
				return true
			end
			local function send(stage, data, onlyPlayer)
				data = data or {}
				data.Stage, data.Owner, data.Token = stage, actor, token
				data.Origin, data.Radius = data.Origin or root.Position, 800
				core.ScreenEffect("DeathRoars", data, onlyPlayer)
			end
			local function shake(intensity, duration)
				core.ScreenEffect("Shake", { Origin = root.Position, Radius = 400, Duration = duration, Intensity = intensity })
			end
			cast.OnDispose = function()
				for char,connection in pairs(healthCaps) do
				 connection:Disconnect()
				 if char.Parent and char:GetAttribute("DeathRoarsHealthCapToken")==token then
				  char:SetAttribute("DeathRoarsHealthCapToken",nil) char:SetAttribute("DeathRoarsHealthCap",nil)
				 end
				end
				protection:Destroy()
				if actor.Parent and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and not actor:GetAttribute("PhaseTransitionInProgress") then
					actor:SetAttribute("Invulnerable", priorInvulnerable)
				end
				if current == cast then current = nil end
				if endAura then endAura() end
				if roarVoice then roarVoice:Dispose() end
				if trail then trail.Enabled = false trail:Clear() end
				if not ended then
					ended = true
					pcall(send, "End", { Interrupted = true })
				end
				if actor.Parent then
					actor:SetAttribute("DeathRoarsActive", false)
					if not actor:GetAttribute("DeathRoarsRoarStoppedAt") then
						actor:SetAttribute("DeathRoarsRoarStoppedAt", workspace:GetServerTimeNow())
					end
					if (actor:GetAttribute("PhaseGeneration") or 0) == generation and (actor:GetAttribute("MovementRevision") or 0) == revision then
						local frame = Placement.Validate(actor, root.CFrame, { Margin = 8 }) or Placement.Validate(actor, original, { Margin = 8 })
						if frame then root.CFrame = frame end
						Time.SetAnchored(root, anchored)
					end
				end
			end
			actor:SetAttribute("Invulnerable", true)
			protection.Parent = actor
			actor:SetAttribute("DeathRoarsActive", true)
			actor:SetAttribute("DeathRoarsSwarms", 0)
			actor:SetAttribute("DeathRoarsRoarStoppedAt", nil)
			actor:SetAttribute("DeathRoarsFinisherStartedAt", nil)
			actor:SetAttribute("DeathRoarsFinisherRadius", nil)

			 
			local center = Placement.GroundPoint(bounds.Frame.Position, { Clamp = true }) or bounds.Frame.Position
			local floorY = center.Y
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
			local function bodyOf(char)
				return core.Alive(char) and char:FindFirstChild("HumanoidRootPart") or nil
			end
			local function targets()
				local list = {}
				for _, char in ipairs(core.Characters()) do
					if bodyOf(char) and Encounter.CanReceiveHit(char, false, true) then table.insert(list, char) end
				end
				return list
			end

			 
			local history = {}
			local function record()
				local now = os.clock()
				for _, char in ipairs(core.Characters()) do
					local hrp = bodyOf(char)
					if hrp then
						local list = history[char]
						if not list then list = {} history[char] = list end
						table.insert(list, { now, hrp.Position })
						while #list > 2 and list[2][1] < now - 1.5 do table.remove(list, 1) end
					end
				end
			end
			local function lagged(char, lag)
				local list = history[char]
				if not list or #list == 0 then local hrp = bodyOf(char) return hrp and hrp.Position end
				local at = os.clock() - lag
				for i = #list, 1, -1 do
					if list[i][1] <= at then return list[i][2] end
				end
				return list[1][2]
			end

			local lastFlash = {}
			local function capHealth(char,h)
			 if healthCaps[char] then return end
			 char:SetAttribute("DeathRoarsHealthCapToken",token) char:SetAttribute("DeathRoarsHealthCap",1)
			 healthCaps[char]=h.HealthChanged:Connect(function(health)
			  if health>1 and not cast.closed and char.Parent and char:GetAttribute("DeathRoarsHealthCapToken")==token then h.Health=1 end
			 end)
			end
			local tickCarry = 0
			local drainFraction=B.HealthFraction
			local function drain(dt)
				tickCarry += dt
				while tickCarry + 1e-6 >= B.TickEvery do
					tickCarry = math.max(0, tickCarry - B.TickEvery)
					for _, char in ipairs(core.Characters()) do
						local h = char:FindFirstChildOfClass("Humanoid")
						if h and h.Health > 0 and bodyOf(char)
							and Placement.Contains(char.HumanoidRootPart.Position) then
							local actual = Encounter.Damage(char, h.MaxHealth * drainFraction, actor, nil, PIERCE)
							if h.Health <= 1 then capHealth(char,h) end
							local player = Players:GetPlayerFromCharacter(char)
							local now = os.clock()
							if actual > 0 and player and now - (lastFlash[char] or 0) > 0.15 then
								lastFlash[char] = now
								pcall(send, "Hit", { Heavy = false }, player)
							end
						end
					end
				end
			end
			local function swarm(point, radius, count)
				V.Swarm(cast, point, radius, count)
				actor:SetAttribute("DeathRoarsSwarms", (actor:GetAttribute("DeathRoarsSwarms") or 0) + 1)
			end
			local function streak(lowOnly)
				local mid = randomPoint() + Vector3.new(0, lowOnly and rng:NextNumber(2, 10) or rng:NextNumber(3, 55), 0)
				local a = rng:NextNumber(0, TAU)
				local direction = Vector3.new(math.cos(a), rng:NextNumber(-0.45, 0.45), math.sin(a)).Unit
				local half = diagonal * rng:NextNumber(B.StreakSpan[1], B.StreakSpan[2]) / 2
				V.Streak(cast, mid - direction * half, mid + direction * half, rng:NextNumber(0.14, 0.32))
			end

			 
			local floorRoot = core.FloorY(center + Vector3.new(0, 8, 0), core.Params())
			if floorRoot then
				local look = target.HumanoidRootPart.Position
				local position = Vector3.new(center.X, floorRoot, center.Z)
				local frame = CFrame.lookAt(position, Vector3.new(look.X, position.Y, look.Z))
				frame = Placement.Validate(actor, frame, { Margin = 8 }) or frame
				Audio.Emit(actor, "TeleportWarp", root)
				actor:PivotTo(frame)
			end
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

			 
			actor:SetAttribute("AttackState", "Death Roars: cinematic")
			local arenaData = { ArenaFrame = bounds.Frame, HalfX = bounds.HalfX, HalfZ = bounds.HalfZ, FloorY = floorY }
			core.ScreenEffect("CombatAudioPreload", { Cue = "DeathRoarsSlash", Origin = root.Position, Radius = 800 })
			core.ScreenEffect("CombatAudioPreload", { Cue = "DeathRoarsRoar", Origin = root.Position, Radius = 800 })
			send("Intro", { Duration = I.Duration, Raise = I.Raise, Ignite = I.FirstStreaks, Center = center, ArenaFrame = arenaData.ArenaFrame, HalfX = arenaData.HalfX, HalfZ = arenaData.HalfZ, FloorY = floorY })
			V.Highlight(cast, actor, 0.85)
			core.Melee.Pose("Windup3", 0.35)
			Audio.Emit(actor, "RoyalFinalCharge", root)
			V.Gather(cast, tip, I.FirstStreaks, 48)
			endAura = V.Aura(cast, actor)
			if not waitFor(I.Raise) then return false end
			core.PoseAngles(Style.Poses.Raise, 0.25)
			if not waitFor(I.FirstStreaks - I.Raise) then return false end
			 
			V.Ignite(cast, tip(), center, math.max(bounds.HalfX, bounds.HalfZ) * 1.2)
			Audio.Emit(actor, "CataclysmSlam", root)
			roarVoice = Audio.Loop(cast, actor, "DeathRoarsRoar", root)
			local roarStartedAt = workspace:GetServerTimeNow()
			roarEndsAt = roarStartedAt + B.Duration
			actor:SetAttribute("DeathRoarsRoarStartedAt", roarStartedAt)
			actor:SetAttribute("DeathRoarsRoarEndsAt", roarEndsAt)
			shake(1.1, 0.9)
			for _ = 1, 24 do streak(false) end
			V.Swarm(cast, tip(), 8, 10, 0.15)
			local introEnds = os.clock() + I.Duration - I.FirstStreaks
			while os.clock() < introEnds do
				if not waitFor(0.12) then return false end
				streak(false)
				streak(true)
			end

			 
			actor:SetAttribute("AttackState", "Death Roars: barrage")
			local barrageDuration = math.max(0.1, roarEndsAt - workspace:GetServerTimeNow())
			drainFraction=math.max(B.HealthFraction,B.TickEvery/barrageDuration)
			send("Barrage", { Duration = barrageDuration, ArenaFrame = arenaData.ArenaFrame, HalfX = arenaData.HalfX, HalfZ = arenaData.HalfZ, FloorY = floorY })
			core.PoseAngles(Style.Poses.Command, 0.12)
			slashVoice = Audio.Loop(cast, actor, "DeathRoarsSlash", root)
			if trail then trail.Enabled = true end
			local began, last = os.clock(), os.clock()
			local streaks, randoms = 0, 0
			local nextFollow = {}
			local nextSwing, nextShake = began, began
			while true do
				Run.Heartbeat:Wait()
				if not valid() then return false end
				record()
				local now = os.clock()
				local elapsed = now - last
				local dt = math.min(elapsed, 0.1)
				last = now
				local progress = math.clamp((now - began) / barrageDuration, 0, 1)
				if workspace:GetServerTimeNow() >= roarEndsAt then break end
				drain(elapsed)
				streaks += dt * lerp(B.StreakStart, B.StreakEnd, progress)
				while streaks >= 1 do
					streaks -= 1
					streak(rng:NextNumber() < 0.35)
				end
				 
				for _, char in ipairs(targets()) do
					if now >= (nextFollow[char] or began + 0.3) then
						nextFollow[char] = now + lerp(B.FollowEvery[1], B.FollowEvery[2], progress) * rng:NextNumber(0.85, 1.15)
						local at = lagged(char, B.FollowLag)
						if at then
							swarm(at + Vector3.new(0, rng:NextNumber(-0.5, 1), 0), B.FollowRadius, rng:NextInteger(B.FollowCrescents[1], B.FollowCrescents[2]))
						end
					end
				end
				 
				randoms += dt * lerp(B.RandomStart, B.RandomEnd, progress)
				while randoms >= 1 do
					randoms -= 1
					local spot = randomPoint() + Vector3.new(0, 3, 0)
					V.Glint(cast, spot, B.RandomGlint)
					cast:Schedule(B.RandomGlint, function()
						if valid() then swarm(spot, B.SwarmRadius, rng:NextInteger(B.Crescents[1], B.Crescents[2])) end
					end)
				end
				if now >= nextSwing then
					nextSwing = now + rng:NextNumber(0.08, 0.14)
					local pose = table.clone(Style.Poses.Command)
					pose.RightShoulder = { 95 + rng:NextNumber(-40, 50), 0, 25 + rng:NextNumber(-45, 45) }
					pose.Waist = { 0, rng:NextNumber(-30, 15), 0 }
					core.PoseAngles(pose, 0.07)
				end
				if now >= nextShake then
					nextShake = now + 0.4
					shake(0.15 + 0.2 * progress, 0.35)
				end
			end

			for _,char in ipairs(core.Characters()) do
			 local h=char:FindFirstChildOfClass("Humanoid")
			 if h and h.Health>0 and bodyOf(char) and Placement.Contains(char.HumanoidRootPart.Position) then
			  Encounter.Damage(char,h.Health,actor,nil,PIERCE)
			  if h.Health<=1 then capHealth(char,h) end
			 end
			end
			if roarVoice then roarVoice:Dispose() end
			if slashVoice then slashVoice:Dispose() end
			actor:SetAttribute("DeathRoarsRoarStoppedAt", workspace:GetServerTimeNow())
			if trail then trail.Enabled = false trail:Clear() end
			if endAura then endAura() end
			for object, lease in pairs(cast.objects) do
				if lease == true or Effects.LeaseId(object) == lease.id then Effects.Release(object) end
			end
			table.clear(cast.objects)
			table.clear(cast.scheduled)
			table.clear(cast.steps)
			 
			local F = Style.Finale
			actor:SetAttribute("AttackState", "Death Roars: final roar")
			send("Finale", { Duration = F.Freeze + F.Sweep + F.After, Freeze = F.Freeze, Sweep = F.Sweep, After = F.After, Center = center })
			core.PoseAngles(Style.Poses.Raise, 0.2)
			local fadeHighlight = V.Highlight(cast, actor, 0.6)
			V.Gather(cast, tip, F.Freeze, 40)
			local giant = V.GiantBlade(cast, root, tip, F.BladeLength, F.Freeze * 0.85, floorY)
			Audio.Emit(actor, "RoyalFinalCharge", root)
			shake(0.25, F.Freeze)
			if not waitFor(F.Freeze) then return false end
			 
			send("Sweep", { Duration = F.Sweep })
			core.Melee.Pose("Slash3", F.Sweep)
			Audio.Emit(actor, "SplittingSlashRelease", root)
			local strike, forward
			local finaleHits = {}
			local function hitFinale(char, amount)
				if finaleHits[char] or not valid() then return end
				if Encounter.Damage(char, amount, actor, nil, FINISHER) > 0 then
					finaleHits[char] = true
					local player = Players:GetPlayerFromCharacter(char)
					if player then pcall(send, "Hit", { Heavy = true }, player) end
				end
			end
			local function swordHit(frame, size)
				if not valid() then return end
				for _, char in ipairs(core.Characters()) do
					local hrp = bodyOf(char)
					if hrp and not finaleHits[char] then
						local p = frame:PointToObjectSpace(hrp.Position)
						 
						if math.abs(p.X) <= size.X * 0.5 + 2
							and math.abs(p.Y) <= size.Y * 0.5 + 2
							and math.abs(p.Z) <= size.Z * 0.5 + 2 then
							hitFinale(char, F.SwordDamage)
						end
					end
				end
			end
			if giant then strike, forward = giant.Sweep(F.Sweep, swordHit) end
			strike = strike or center
			forward = forward or root.CFrame.LookVector
			if not waitFor(F.Sweep) then return false end
			 
			actor:SetAttribute("AttackState", "Death Roars: finishing burst")
			actor:SetAttribute("DeathRoarsFinisherStartedAt", workspace:GetServerTimeNow())
			send("Cut", { Duration = F.After, Impact = strike, Direction = forward })
			Audio.Loop(cast, actor, "RoyalFinalImpact", root)
			Audio.Emit(actor, "CataclysmSlam", root)
			local finishRadius = V.Finish(cast, center, bounds)
				or math.sqrt(bounds.HalfX ^ 2 + bounds.HalfZ ^ 2) + 4
			actor:SetAttribute("DeathRoarsFinisherRadius", finishRadius)
			local burstBorn = cast:Now()
			local priorReach = 0
			cast:Step(function(_, now)
				if not valid() then return false end
				local progress = math.clamp((now - burstBorn) / Style.Finish.Duration, 0, 1)
				local t = math.clamp(progress * 1.2, 0, 1)
				local reach = 4 + finishRadius * (1 - (1 - t) ^ 3)
				for _, char in ipairs(core.Characters()) do
					local hrp = bodyOf(char)
					if hrp and not finaleHits[char] and Placement.Contains(hrp.Position) then
						local p = hrp.Position
						local distance = Vector3.new(p.X - center.X, 0, p.Z - center.Z).Magnitude
						if distance >= math.max(0, priorReach - 3) and distance <= reach + 3
							and math.abs(p.Y - (floorY + 1)) <= F.BurstHeight then
							hitFinale(char, F.BurstDamage)
						end
					end
				end
				priorReach = reach
				return progress < 1
			end)
			V.Scar(cast, center, forward, floorY, math.sqrt(bounds.HalfX ^ 2 + bounds.HalfZ ^ 2) * 2.2)
			V.FinaleCut(cast, center, bounds)
			V.Ignite(cast, strike + Vector3.new(0, 1, 0), strike, math.max(bounds.HalfX, bounds.HalfZ) * 1.3)
			shake(1.6, 1)
			if not waitFor(F.After * 0.6) then return false end
			if fadeHighlight then fadeHighlight(0.6) end
			core.Melee.Pose("Idle", 0.4)
			if not waitFor(F.After * 0.4) then return false end
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
