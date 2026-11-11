local B = script:FindFirstAncestor("BossSystem")
local Registry = require(B.Combat.AttackRegistry)
local Effects = require(B.Combat.EffectService)
local Runtime = require(B.Combat.CombatRuntime)
local Placement = require(B.Encounter.ArenaPlacement)
local Timeline = require(script.Parent.Timeline)
local Encounter = require(B.Players.PlayerEncounter)
local Audio = require(B.Presentation.CombatAudio)
local Ultimate = require(B.Combat.UltimateService)
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Style = require(script.Parent.Style)
local V = require(script.Parent.Visuals)
local Launcher = require(script.Parent.Launcher)
local Cards = require(script.Parent.Cards)
local Finale = require(script.Parent.Finale)
local Config=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local NAME = "P3.5TrueIllusion(Ultimate)"
local TAU = math.pi * 2
local M = Style.Mechanics or {}
local POSES = Style.Poses or {}
local MAX_LEAD_SPEED = 60

local function aimFrame(pos, dir)
	local up = math.abs(dir.Y) > 0.97 and Vector3.xAxis or Vector3.yAxis
	return CFrame.lookAt(pos, pos + dir, up)
end
local function flatVelocity(char)
	local v = char.HumanoidRootPart.AssemblyLinearVelocity
	v = Vector3.new(v.X, 0, v.Z)
	if v.Magnitude > MAX_LEAD_SPEED then v = v.Unit * MAX_LEAD_SPEED end
	return v
end
local function predict(char, origin, speed, lead)
	local pos = char.HumanoidRootPart.Position
	local aimAt = pos
	if lead > 0 then
		local vel = flatVelocity(char) * lead
		local t = (pos - origin).Magnitude / speed
		aimAt = pos + vel * t
		t = (aimAt - origin).Magnitude / speed
		aimAt = pos + vel * t
	end
	local d = aimAt - origin
	return d.Magnitude > 0.01 and d.Unit or nil
end
local function pose(name, overrides)
	local out = {}
	for joint, angles in pairs(POSES[name] or {}) do out[joint] = { angles[1], angles[2], angles[3] } end
	for joint, angles in pairs(overrides or {}) do out[joint] = angles end
	return out
end
local function distanceToSegment(point, a, b)
	local ab = b - a
	local t = math.clamp((point - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (point - (a + ab * t)).Magnitude
end

return function(actor)
	local core = Registry.For(actor, "P1CombatCore")
	local normal = Registry.For(actor, "P1NormalSlash")
	local rng = Random.new()
 local misdirection=Registry.For(actor,"P3Misdirection(Passive)")
	local current
	local api = { Cooldown = Style.Cooldown }
	function api.CanUse(target)
		return not current and actor:GetAttribute("Phase") == 3.5 and actor:GetAttribute("Shield") == 1
			and not actor:GetAttribute("TrueIllusionCompleted") and not actor:GetAttribute("IsGoldenClone")
			and not actor:GetAttribute("IsIllusion") and not actor:GetAttribute("PhaseTransitionInProgress")
			and core.Active() and core.Alive(target) and Ultimate.Ready(actor, NAME)
	end
	local function runSequence(target)
		return core.Perform(target, NAME, function()
			local root = core.Root
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local original = root.CFrame
			local anchored = root.Anchored
			local cast = Effects.NewCast(actor, NAME, Timeline.EndAt + 5)
			cast.TimeStopExempt = true
			local musicStartedAt = workspace:GetServerTimeNow()
			local naturalEnd = false
			current = cast
			local token = Http:GenerateGUID(false)
			local folder = Instance.new("Folder"); folder.Name = "TrueIllusionClones"; folder.Parent = Runtime.Summons; cast:Add(folder)
			local gun, fan, finale
			local projectiles = {}
			local remaining = {}
			local frames = {}
			local log = {}
			local hiddenSword = {}
			local ended = false
			api.LastCast = cast; api.LastSequence = log
			actor:SetAttribute("TrueIllusionActive", true)
			actor:SetAttribute("TrueIllusionCloneCount", Style.CloneCount)
			actor:SetAttribute("TrueIllusionSwitches", 0)
			actor:SetAttribute("TrueIllusionClonesRemaining", 0)
			actor:SetAttribute("TrueIllusionFinale", false)
			actor:SetAttribute("TrueIllusionToken", token)
			actor:SetAttribute("TrueIllusionMusicStartedAt", musicStartedAt)
			actor:SetAttribute("TrueIllusionMusicEndsAt", musicStartedAt + Timeline.EndAt)
			actor:SetAttribute("TrueIllusionPaused", false)
			local function elapsed() return workspace:GetServerTimeNow() - musicStartedAt end
			local function damageAllowed() return Timeline.Attacking(elapsed()) and not cast.closed end
			local function valid()
				return not cast.closed and core.Active() and actor:GetAttribute("Phase") == 3.5
					and actor:GetAttribute("Shield") == 1
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
					and not actor:GetAttribute("PhaseTransitionInProgress") and not actor:GetAttribute("EncounterEnded")
			end
			local function waitFor(seconds)
				local ends = os.clock() + seconds
				repeat Run.Heartbeat:Wait() if not valid() then return false end until os.clock() >= ends
				return true
			end
			local function waitUntil(at)
				while elapsed() < at do
					Run.Heartbeat:Wait()
					if not valid() then return false end
				end
				return valid()
			end
			local function send(stage, data)
				data = data or {}
				data.Stage, data.Owner, data.Token = stage, actor, token
				data.Origin = data.Origin or root.Position
				data.Radius = data.Radius or 600
				core.ScreenEffect("TrueIllusion", data)
			end
			local function shake(origin, intensity, duration)
				core.ScreenEffect("Shake", { Origin = origin, Radius = 200, Duration = duration or 0.3, Intensity = intensity or 0.4 })
			end
			local function finish()
				if ended or cast.closed then return end
				if not valid() then cast:Dispose(); return end
				actor:SetAttribute("TrueIllusionFinishElapsed", elapsed())  
				actor:SetAttribute("TrueIllusionFinishRun", 1)
				naturalEnd, ended = true, true
				actor:SetAttribute("TrueIllusionCompleted", true)
				actor:SetAttribute("TrueIllusionEndedAt", workspace:GetServerTimeNow())
				send("End", {})
				cast:Dispose()
				actor:SetAttribute("Shield", 0)
				actor:SetAttribute("ShieldBroken", true)
				require(B.Presentation.CharacterEffects).ShieldBreak(actor)
				require(B.Phases.PhaseController).BeginPhase4(actor, target)
			end
			cast.OnDispose = function()
				if current == cast then current = nil end
				for projectile in pairs(projectiles) do projectile:Dispose() end
				table.clear(projectiles)
				if not ended then
					ended = true
					pcall(send, "End", { Interrupted = true })
				end
				for item, alpha in pairs(hiddenSword) do
					if item.Parent then item.Transparency = alpha end
				end
				if actor.Parent then
					actor:SetAttribute("TrueIllusionActive", false)
					actor:SetAttribute("TrueIllusionPaused", false)
					actor:SetAttribute("TrueIllusionMusicStartedAt", nil)
					actor:SetAttribute("TrueIllusionMusicEndsAt", nil)
					actor:SetAttribute("TrueIllusionFinale", false)
					actor:SetAttribute("TrueIllusionClonesRemaining", 0)
					if actor:GetAttribute("TrueIllusionToken") == token then actor:SetAttribute("TrueIllusionToken", nil) end
					if (actor:GetAttribute("PhaseGeneration") or 0) == generation and (actor:GetAttribute("MovementRevision") or 0) == revision then
						local frame = Placement.Validate(actor, root.CFrame, { Margin = 8 }) or Placement.Validate(actor, original, { Margin = 8 })
						if frame then root.CFrame = frame end
						root.Anchored = anchored
					end
				end
			end
			local cueIndex = 1
			local paused = false
			cast:Step(function(dt)
				if not valid() then cast:Dispose() return false end
				local time = elapsed()
				if time >= Timeline.EndAt then
					finish()
					return false
				end
				local breakActive = time >= Timeline.PauseAt and time < Timeline.ResumeAt
				if breakActive and not paused then
					paused = true
					actor:SetAttribute("TrueIllusionPaused", true)
					actor:SetAttribute("TrueIllusionPausedAt", workspace:GetServerTimeNow())
					actor:SetAttribute("AttackState", "True Illusion: ENOUGH")
					local clearing = {}
					for projectile in pairs(projectiles) do table.insert(clearing, projectile) end
					for _, projectile in ipairs(clearing) do projectile:Dispose() end
					if gun then gun:Fired() end
					core.PoseAngles(pose("Ready"), 0.12)
				elseif paused and not breakActive then
					paused = false
					actor:SetAttribute("TrueIllusionPaused", false)
					actor:SetAttribute("TrueIllusionResumedAt", workspace:GetServerTimeNow())
				end
				local latest
				while Timeline.Cues[cueIndex] and Timeline.Cues[cueIndex].At <= time do
					latest = Timeline.Cues[cueIndex]
					cueIndex += 1
				end
				if latest and time < latest.Until then
					Encounter.Say(latest.Text, nil, {
						Duration = latest.Until - latest.At, LyricSoundtrack = true,
						StartedAt = musicStartedAt + latest.At, Owner = actor, Token = token,
						IllusionLyrics = latest.Illusion == true,
					})
				end
				if not valid() then cast:Dispose(); return false end
				if gun then gun:Step(dt, root.CFrame * CFrame.new(1.8, 1, -0.8)) end
				if fan then fan:Step() end
				return true
			end)

			local sword = actor:FindFirstChild("Basic Sword")
			if sword and sword.Parent == actor then
				for _, item in ipairs(sword:GetDescendants()) do
					if (item:IsA("BasePart") or item:IsA("Decal")) and item.Transparency < 1 then
						hiddenSword[item] = item.Transparency
						item.Transparency = 1
					end
				end
			end

			local poseSerial = 0
			local function aimPose(targetPosition, recoil)
				local pitch = 0
				if gun and targetPosition then
					local from = gun:Muzzle()
					local delta = targetPosition - from
					local flat = Vector3.new(delta.X, 0, delta.Z).Magnitude
					pitch = math.deg(math.atan2(delta.Y, math.max(flat, 0.1)))
				end
				local name = recoil and "Recoil" or "Aim"
				local base = POSES[name] and POSES[name].RightShoulder or { 92, -8, 24 }
				return pose(name, { RightShoulder = { base[1] + math.clamp(pitch, -45, 60), base[2], base[3] } })
			end
			local function kick(targetPosition)
				poseSerial += 1
				local serial = poseSerial
				core.PoseAngles(aimPose(targetPosition, true), 0.035)
				cast:Schedule(0.07, function()
					if serial == poseSerial and valid() then core.PoseAngles(aimPose(targetPosition), 0.12) end
				end)
			end

			local function hazard(point, spec)
				if not damageAllowed() then return end
				local cfg = M.Hazard
				local radius = spec.Radius * cfg.Scale
				local zone = Effects.NewCast(actor, "TrueIllusionHazard", cfg.Duration + 1.2)
				projectiles[zone] = true
				zone.OnDispose = function() projectiles[zone] = nil end
				local center = V.Hazard(zone, point, spec, radius, cfg.Duration, actor) or point
				local age, last = 0, {}
				zone:Step(function(dt)
					if not valid() or not damageAllowed() then zone:Dispose(); return false end
					age += dt
					if age >= cfg.Duration then return false end
					local now = os.clock()
					for _, char in ipairs(core.Characters()) do
						if core.Alive(char) and (not last[char] or now - last[char] >= cfg.Tick) then
							local off = char.HumanoidRootPart.Position - center
							if Vector3.new(off.X, 0, off.Z).Magnitude <= radius and math.abs(off.Y) <= 7 then
								last[char] = now
								core.Damage(char, cfg.Damage, NAME)
							end
						end
					end
					return true
				end)
			end

			local function hitArea(point, radius, damage, group)
				if not damageAllowed() then return end
				for _, char in ipairs(core.Characters()) do
					if core.Alive(char) and not (group and group[char]) then
						local off = char.HumanoidRootPart.Position - point
						if Vector3.new(off.X, 0, off.Z).Magnitude <= radius + 2 and math.abs(off.Y) <= radius + 4
							and core.CanHit(char, point + Vector3.new(0, 1.5, 0)) then
							if group then group[char] = true end
							core.Damage(char, damage, NAME)
						end
					end
				end
			end

			local function fire(spec, direction, speed, opts)
				if not damageAllowed() then return end
				opts = opts or {}
				local origin = opts.Origin or gun:Muzzle()
				local range = opts.Range or Style.Range
				local delay = opts.Delay or 0
				local homing = opts.Homing
				local group = opts.HitGroup
    local fake=opts.Fake==true
    local cued=false
				local rocketCast = Effects.NewCast(actor, "TrueIllusionRocket", range / speed + delay + 0.6)
				projectiles[rocketCast] = true
				rocketCast.OnDispose = function() projectiles[rocketCast] = nil end
				local rocket = V.Rocket(rocketCast, spec, origin, direction, { Scale = opts.Scale, Lite = opts.Lite })
				local position = origin
				local traveled = 0
				local age = 0
				local done = false
				local function burst(point, wall)
					if done then return end done = true
					if valid() and damageAllowed() then
						if wall and opts.Quiet then
							V.Fizzle(Effects.NewCast(actor, "TrueIllusionFizzle", 0.6), point, spec.Color)
						else
							V.Burst(actor, point, spec, core.Params(), direction); Audio.Emit(actor, "CardBurst", point)
						end
						for _, char in ipairs(not fake and core.Characters() or {}) do
							if core.Alive(char) and not (group and group[char])
								and (char.HumanoidRootPart.Position - point).Magnitude <= spec.Radius + 2
								and core.CanHit(char, point) then
								if group then group[char] = true end
								local dealt=core.Damage(char,spec.Damage,NAME)
							end
						end
						if not fake and opts.Hazard and M.Hazard then hazard(point, spec) end
					end
					rocketCast:Dispose()
				end
				rocketCast:Step(function(dt)
					if not valid() or not damageAllowed() then rocketCast:Dispose(); return false end
					dt = math.min(dt, 0.08)
					age += dt
					if age < delay then return true end
					if homing and age - delay < homing.Duration and (homing.Point or core.Alive(homing.Target)) then
						local to = (homing.Point or homing.Target.HumanoidRootPart.Position) - position
						if to.Magnitude > 1 then
							local want = to.Unit
							local angle = math.acos(math.clamp(direction:Dot(want), -1, 1))
							if angle > 1e-3 then
								local turned = direction:Lerp(want, math.min(1, homing.Turn * dt / angle))
								if turned.Magnitude > 1e-3 then direction = turned.Unit end
							end
						end
					end
					if opts.Clue and not cued and core.Alive(opts.ClueTarget) then
      local along=(opts.ClueTarget.HumanoidRootPart.Position-position):Dot(direction)
      if along<=speed*(Config.P3MisdirectionClueLead or .25) then
       cued=true;misdirection.Cue(core,rocket,position)
       actor:SetAttribute("MisdirectionTrueIllusionClueAt",workspace:GetServerTimeNow())
      end
     end
     if fake and traveled>=math.max(0,(opts.FakeDistance or range)-speed*.02) then
      burst(position);return false
     end
     local length = math.min(speed * dt, range - traveled)
					local delta = direction * length
					local wall = workspace:Raycast(position, delta, core.Params())
					local limit = wall and wall.Distance or length
					local first, firstDistance
					for _, char in ipairs(core.Characters()) do
						if core.Alive(char) then
							local offset = char.HumanoidRootPart.Position - position
							local along = math.clamp(offset:Dot(direction), 0, limit)
							if (offset - direction * along).Magnitude <= 2.6 and (not firstDistance or along < firstDistance) then
								first = char; firstDistance = along
							end
						end
					end
					if first then burst(position + direction * firstDistance); return false end
					if wall then burst(wall.Position + wall.Normal * 0.5, true); return false end
					position += delta; traveled += length
					rocket.CFrame = aimFrame(position, direction)
					if traveled >= range then rocketCast:Dispose(); return false end
					return true
				end)
			end

			local function finaleSequence()
				local F = Style.Finale
				if not F then return true end
				local P, S, A = F.Prison, F.Slam, F.Ace
				local suit = Style.Suits[F.Suit] or Style.Suits.Spade
				assert(#remaining == 0 and #log == Style.CloneCount, "Royal Flush requires every clone to attack")
    actor:SetAttribute("TrueIllusionFinale", true)
    actor:SetAttribute("TrueIllusionFinaleStartedAt", workspace:GetServerTimeNow())
				actor:SetAttribute("AttackState", "True Illusion: Royal Flush")
				local target = normal.GetTarget(true)
				if not core.Alive(target) then return false end

				local bounds = Placement.GetBounds and Placement.GetBounds()
				if bounds then
					local center = Placement.GroundPoint(bounds.Frame.Position, { Clamp = true })
					local floorY = center and core.FloorY(center + Vector3.new(0, 6, 0), core.Params())
					if floorY then
						local position = Vector3.new(center.X, floorY, center.Z)
						local look = target.HumanoidRootPart.Position
						local frame = CFrame.lookAt(position, Vector3.new(look.X, position.Y, look.Z))
						frame = Placement.Validate(actor, frame, { Margin = 8 }) or frame
						V.Teleport(cast, actor, root.Position, frame.Position)
						Audio.Emit(actor, "TeleportWarp", root)
						actor:PivotTo(frame)
					end
				end
				core.Face(target)
				local ground = V.GroundPoint(root.Position, 14, actor) or (root.Position - Vector3.new(0, 4, 0))
				gun:SetSuit({ Symbol = suit.Symbol, Color = Style.Gold })
				core.PoseAngles(pose("Deal"), 0.18)
				local line1 = 0.6
				send("Finale", { Ranks = F.Ranks, Symbol = suit.Symbol, DealInterval = F.Deal.Interval, DealFlight = F.Deal.Flight,
					TitleAt = line1 + 0.05, Origin = ground })
				Audio.Emit(actor, "RoyalSummon", root)
				if not waitFor(0.25) then return false end
				fan:Hide(0.15)
				local dealTime = finale:Deal(ground, root.CFrame.LookVector, fan:WorldFrames())
				if not waitFor(math.max(0, dealTime - 0.25)) then return false end
				core.PoseAngles(pose("SkyShot"), 0.12)
				if not waitFor(0.14) then return false end
				gun:Recoil(1.4)
				V.Muzzle(cast, gun:Muzzle(), Vector3.yAxis, { Color = Style.Gold })
				V.Pillar(cast, gun:Muzzle(), Style.Gold, 60, 0.6, 0.45)
				Audio.Emit(actor, "RoyalFinalRelease", root)
				shake(root.Position, 0.5, 0.35)


				for wave = 1, P.Waves do
					if not valid() then return false end
					target = normal.GetTarget(true)
					if not core.Alive(target) then return false end
					core.PoseAngles(aimPose(target.HumanoidRootPart.Position), 0.12)
					local center = target.HumanoidRootPart.Position
					send("Card", { Index = wave, Kind = "Prison" })
					finale:Dive(wave, center, P.Dive)
					Audio.Emit(actor, "LanceLaunch", root)
					if not waitFor(P.Dive) then return false end
					finale:Shatter(wave)
					Audio.Emit(actor, "CardBurst", center)
					local group = {}
					 -- two rings close at once (inner and outer), each with its own gap
					for _, ring in ipairs({ { Radius = P.Radius, Count = P.Count }, { Radius = P.OuterRadius or P.Radius, Count = P.OuterCount or P.Count } }) do
						local gapAt = rng:NextInteger(1, ring.Count)
						local turn = rng:NextNumber(0, TAU)
						V.PrisonRing(cast, center, ring.Radius, P.Telegraph, actor)
						for i = 1, ring.Count do
							if (i - gapAt) % ring.Count >= P.Gap then
								local a = turn + (i - 1) / ring.Count * TAU
								local origin = center + Vector3.new(math.cos(a), 0, math.sin(a)) * ring.Radius
								local spec = { Symbol = suit.Symbol, Color = Style.Suits[Style.Order[(i - 1) % #Style.Order + 1]].Color, Damage = P.Damage, Radius = P.BurstRadius }
								fire(spec, (center - origin).Unit, P.Speed, { Origin = origin, Delay = P.Telegraph, Range = ring.Radius * 2 + 15, HitGroup = group, Quiet = true, Lite = true })
							end
						end
					end
					Audio.Emit(actor, "ProjectileCast", root.Position)
					if not waitFor(P.Telegraph + P.WaveGap) then return false end
				end

				local slam = 0
				for index = 3, 4 do
					for repeatIndex = 1, S.Slams do
						if not valid() then return false end
						slam += 1
						target = normal.GetTarget(true)
						if not core.Alive(target) then return false end
						local tele = S.Telegraph[slam] or S.Telegraph[#S.Telegraph]
						local spot = target.HumanoidRootPart.Position + flatVelocity(target) * S.Lead
						local landing = V.DangerZone(cast, spot, S.Radius + 1.5, tele, actor) or spot
						local toward = root.Position - landing
						send("Card", { Index = index, Kind = "Slam" })
						core.PoseAngles(aimPose(landing), 0.12)
						finale:Hover(index, landing, 12, math.max(tele - S.Fall, 0.05), toward)
						Audio.Emit(actor, "GroundWarning", landing)
						if not waitFor(math.max(tele - S.Fall, 0.05)) then return false end
						finale:Slam(index, landing, S.Fall, toward)
						if not waitFor(S.Fall) then return false end
						V.Shockwave(cast, landing, suit.Color, S.Radius, actor)
						V.Burst(actor, landing + Vector3.new(0, 1, 0), { Symbol = suit.Symbol, Color = suit.Color, Radius = S.Radius }, core.Params(), Vector3.new(0, -1, 0))
						Audio.Emit(actor, "CataclysmSlam", landing)
						shake(landing, 0.6, 0.3)
						hitArea(landing, S.Radius, S.Damage, {})
						if S.Spray then  -- the slam sprays cards outward along the ground
							local sprayGroup = {}
							local turn = rng:NextNumber(0, TAU)
							for i = 1, S.Spray.Count do
								local a = turn + (i - 1) / S.Spray.Count * TAU
								local dir = Vector3.new(math.cos(a), 0, math.sin(a))
								fire({ Symbol = suit.Symbol, Color = suit.Color, Damage = S.Spray.Damage, Radius = S.Spray.Radius }, dir, S.Spray.Speed,
									{ Origin = landing + Vector3.new(0, 2, 0) + dir * 2, Delay = 0, Range = S.Spray.Range, HitGroup = sprayGroup, Quiet = true, Lite = true })
							end
						end
						if not waitFor(S.Stuck) then return false end
						if repeatIndex < S.Slams then finale:Lift(index, 0.2) else finale:Shatter(index) end
					end
				end

				if not valid() then return false end
				target = normal.GetTarget(true)
				if not core.Alive(target) then return false end
				send("Card", { Index = 5, Kind = "Ace" })
				local aimPoint = target.HumanoidRootPart.Position
				local locked = false
				core.Face(target)
				core.PoseAngles(aimPose(aimPoint), 0.15)
				local aceSpec = { Symbol = suit.Symbol, Color = Style.Gold, Radius = A.Radius }
				gun:SetSuit({ Symbol = suit.Symbol, Color = Style.Gold })
				gun:Charge(aceSpec, A.Charge)
				finale:Lens(5, function() return gun:Muzzle() end, function() return aimPoint end)
				local line = finale:TrackLine(function() return gun:Muzzle() end, function() return aimPoint end, A.Charge + 0.05)
				Audio.Emit(actor, "RoyalFinalCharge", root)
				local chargeBegan = os.clock()
				repeat
					Run.Heartbeat:Wait()
					if not valid() then return false end
					local elapsed = os.clock() - chargeBegan
					if not locked then
						if core.Alive(target) then
							aimPoint = target.HumanoidRootPart.Position
							core.Face(target)
							core.PoseAngles(aimPose(aimPoint), 0.08)
						end
						if elapsed >= A.Charge - A.Lock then
							locked = true
							if line then line.Lock() end
							V.DangerZone(cast, aimPoint, A.Radius + 1, A.Lock, actor)
							Audio.Emit(actor, "GroundWarning", aimPoint)
						end
					end
				until elapsed >= A.Charge
				local from = gun:Muzzle()
				local direction = aimPoint - from
				direction = direction.Magnitude > 0.1 and direction.Unit or root.CFrame.LookVector
				local hit = workspace:Raycast(from, direction * A.Range, core.Params())
				local impact = hit and hit.Position or (from + direction * A.Range)
				finale:Shatter(5)
				finale:Beam(from, impact, A.Width * 0.8)
				gun:Recoil(1.8)
				gun:Fired()
				kick(impact)
				send("Strike", { From = from, To = impact, Origin = impact })
				Audio.Emit(actor, "RoyalFinalRelease", root)
				local group = {}
				for _, char in ipairs(core.Characters()) do
					if damageAllowed() and core.Alive(char) and distanceToSegment(char.HumanoidRootPart.Position, from, impact) <= A.Width then
						group[char] = true
						core.Damage(char, A.Damage, NAME)
					end
				end
				hitArea(impact, A.Radius, A.Damage, group)
				V.Shockwave(cast, impact, Style.Gold, A.Radius + 4, actor)
				V.Burst(actor, impact + Vector3.new(0, 1, 0), { Symbol = suit.Symbol, Color = Style.Gold, Radius = A.Radius }, core.Params(), direction)
				Audio.Emit(actor, "RoyalFinalImpact", impact)
				shake(impact, 0.9, 0.5)
				 -- royal pillars erupt one after another along the beam's path
				local pillars = A.Pillars
				if pillars then
					local pillarGroup = {}
					for i = 1, pillars.Count do
						if not waitFor(pillars.Gap) then return false end
						local at = from:Lerp(impact, i / pillars.Count)
						local spot = V.GroundPoint(at, 30, actor) or at
						V.Pillar(cast, spot, Style.Gold, 50, 0.5, 0.4)
						V.Shockwave(cast, spot, i % 2 == 0 and Style.White or Style.Gold, pillars.Radius, actor)
						V.Burst(actor, spot + Vector3.new(0, 1, 0), { Symbol = suit.Symbol, Color = Style.Gold, Radius = pillars.Radius }, core.Params(), Vector3.yAxis)
						hitArea(spot, pillars.Radius, pillars.Damage, pillarGroup)
						shake(spot, 0.5, 0.25)
					end
					Audio.Emit(actor, "RoyalFinalImpact", impact)
				end
				if not waitFor(0.6) then return false end
				finale:Clear(0.4)
				V.Finale(actor, root.Position)
				return true
			end

			local function run()
				root.Anchored = true
				gun = Launcher.Build({ Cast = cast, Style = Style, Actor = actor, V = V, Parent = Runtime.Effects })
				gun:Attach()
				gun:SetSuit(Style.Suits.Spade)
				gun:Reveal((Style.Intro and Style.Intro.RevealTime) or 0.45)
				fan = Cards.Fan({ Actor = actor, Style = Style, Cast = cast, Parent = Runtime.Effects, Ranks = Style.Finale and Style.Finale.Ranks, Suit = Style.Finale and Style.Finale.Suit })
				fan:Attach()
				fan:Show(0.35)
				finale = Finale.New({ Style = Style, V = V, Cards = Cards, Effects = Effects, Cast = cast, Actor = actor, Parent = Runtime.Effects })
				core.PoseAngles(pose("Ready"), 0.2)
				local hand = actor:FindFirstChild("RightHand")
				V.CardConverge(cast, hand and hand.Position or root.Position, { Style.White, Style.Gold, Style.Suits.Spade.Color }, 14, 7, 0.4)
				Audio.Emit(actor, "CloneMaterialize", root)
				cast:Schedule(0.35, function() if gun then gun:Twirl((Style.Intro and Style.Intro.TwirlTime) or 0.7) end end)

				for i = 1, Style.CloneCount do
					local frame
					for attempt = 1, 30 do
						local candidate = Placement.Random(actor, rng, { Margin = 10, Attempts = 8 })
						if candidate then
							local clear = true
							for _, used in ipairs(frames) do if (candidate.Position - used.Position).Magnitude < Style.CloneSpacing then clear = false; break end end
							if clear then frame = candidate; break end
						end
					end
					if not frame then return false end
					table.insert(frames, frame)
					if i % 10 == 0 then Run.Heartbeat:Wait() end
				end
				local here = root.Position
				table.sort(frames, function(a, b) return (a.Position - here).Magnitude < (b.Position - here).Magnitude end)
				local line1 = Timeline.CloneWaveAt
				local line2 = Timeline.AttackStart - line1
				local wave = (Style.Intro and Style.Intro.CloneWave) or 1.4
				send("Intro", { Duration = Timeline.AttackStart + 0.3, Line1 = line1, Line2 = line2, CloneWave = wave,
					TitleAt = Timeline.AttackStart - 0.4, CloneCount = Style.CloneCount, Facing = root.CFrame.LookVector })
				local spawned, waveStart = 0, nil
				local function startWave()
					if waveStart then return end
					waveStart = os.clock()
					cast:Step(function()
						if not valid() then return false end
						local due = math.min(#frames, math.floor((os.clock() - waveStart) / wave * #frames + 1))
						local budget = 4
						while spawned < due and budget > 0 do
							spawned += 1
							budget -= 1
							local frame = frames[spawned]
							table.insert(remaining, V.Clone(actor, frame, folder, spawned))
							actor:SetAttribute("TrueIllusionClonesRemaining", spawned)
							V.Summon(cast, frame.Position, actor)
							if spawned % 6 == 0 then Audio.Emit(actor, "CloneMaterialize", frame.Position) end
						end
						return spawned < #frames
					end)
				end
				if not waitUntil(Timeline.CloneWaveAt) then return false end
				startWave()
				while spawned < #frames do
					if not waitFor(0.05) then return false end
				end
				actor:SetAttribute("TrueIllusionClonesSummoned", #remaining)
				Audio.Emit(actor, "EntranceReveal", root)
				if not waitUntil(Timeline.AttackStart) then return false end

				local lastSuit
				for index = 1, Style.CloneCount do
					 
					if not waitUntil(Timeline.VolleyAt(index, Style.CloneCount)) then return false end
					if not valid() then return false end
					target = normal.GetTarget(true)
					if not core.Alive(target) then return false end
					local slot = rng:NextInteger(1, #remaining)
					local copy = table.remove(remaining, slot)
					local frame = copy.HumanoidRootPart.CFrame
					V.Teleport(cast, actor, root.Position, frame.Position)
					actor:PivotTo(frame)
					copy:Destroy()
					core.Face(target)
					core.PoseAngles(pose("Ready"), 0.05)
					local progress = (index - 1) / (Style.CloneCount - 1)
					local windup = Style.WindupStart + (Style.WindupEnd - Style.WindupStart) * progress
     if index > Timeline.BreakFor(Style.CloneCount) then
      local secondProgress = (index - Timeline.BreakFor(Style.CloneCount) - 1) / (Style.CloneCount - Timeline.BreakFor(Style.CloneCount) - 1)
      windup = 0.18 - 0.08 * secondProgress
     end
					 
					local pace = math.min(1, Timeline.CloneCount / Style.CloneCount)
					windup *= pace
					local gap = (Style.GapStart + (Style.GapEnd - Style.GapStart) * progress) * pace
					local speed = Style.SpeedStart + (Style.SpeedEnd - Style.SpeedStart) * progress
					local lead = (M.LeadStart or 0) + ((M.LeadEnd or 0) - (M.LeadStart or 0)) * progress
					local suit
					if index <= (M.ShuffleAfter or math.huge) then
						suit = Style.Order[(index - 1) % #Style.Order + 1]
					else
						repeat suit = Style.Order[rng:NextInteger(1, #Style.Order)] until suit ~= lastSuit or #Style.Order < 2
					end
					lastSuit = suit
					local spec = Style.Suits[suit]
					gun:SetSuit(spec)
					actor:SetAttribute("TrueIllusionSuit", suit)
					actor:SetAttribute("TrueIllusionSwitches", index)
					actor:SetAttribute("TrueIllusionClonesRemaining", #remaining)
					actor:SetAttribute("TrueIllusionWindup", windup)
					actor:SetAttribute("AttackState", "True Illusion: " .. suit .. " " .. index .. "/" .. Style.CloneCount)
					core.PoseAngles(aimPose(target.HumanoidRootPart.Position), math.min(0.12, windup * 0.4))
					gun:Charge(spec, windup)
     local fakePoint=misdirection.TryEmission(NAME,target,rng)
     local fakeOrigin
     if fakePoint then
      local fakeClone=#remaining>0 and remaining[rng:NextInteger(1,#remaining)]
      fakeOrigin=fakeClone and fakeClone.HumanoidRootPart.Position+Vector3.yAxis or gun:Muzzle()
      V.CloneCharge(cast,fakeOrigin,spec,windup,fakePoint)
      Audio.Emit(actor,"CardSummon",fakeOrigin)
     end
					Audio.Emit(actor, "CardSummon", root)
					local X = M.Crossfire
					local shooter
					if X and progress >= X.Start and index % X.Every == 0 and #remaining > 0 then
						shooter = remaining[rng:NextInteger(1, #remaining)]
						local crossSpec = { Symbol = "♠", Color = Style.Suits.Spade.Color, Radius = X.Radius, Damage = X.Damage }
						shooter:SetAttribute("TrueIllusionCrossfire", true)
						V.CloneCharge(cast, shooter.HumanoidRootPart.Position + Vector3.new(0, 1, 0), crossSpec, windup, target.HumanoidRootPart.Position)
					end
					if not waitFor(windup) then return false end
					if not core.Alive(target) then return false end
					local function aimFrom(origin, amount)
						local d = core.Alive(target) and predict(target, origin, speed, amount)
						return d or root.CFrame.LookVector
					end
					local isHoming = M.Homing and suit == M.Homing.Suit
					local isHazard = M.Hazard and suit == M.Hazard.Suit
					local baseLead = isHoming and 0 or (isHazard and math.min(1, lead + 0.15) or lead)
					local direction = aimFrom(gun:Muzzle(), baseLead)
					local entry = { Index = index, Suit = suit, Windup = windup, Gap = gap, Speed = speed, Lead = baseLead, Shots = 0, At = elapsed() }
					table.insert(log, entry)
					if shooter and shooter.Parent and shooter:FindFirstChild("HumanoidRootPart") and core.Alive(target) then
						local o = shooter.HumanoidRootPart.Position + Vector3.new(0, 1, 0)
						local cs = X.SpeedScale * speed
						local d = predict(target, o, cs, lead) or (target.HumanoidRootPart.Position - o).Unit
						local crossSpec = { Symbol = "♠", Color = Style.Suits.Spade.Color, Radius = X.Radius, Damage = X.Damage }
						for s = 1, X.Count do
							local angle = math.rad((s - (X.Count + 1) / 2) * X.Spread)
							fire(crossSpec, CFrame.Angles(0, angle, 0):VectorToWorldSpace(d), cs, { Origin = o, DebuffKey=entry })
						end
						V.Muzzle(cast, o, d, crossSpec)
						entry.Crossfire = true
					end
					if shooter and shooter.Parent then shooter:SetAttribute("TrueIllusionCrossfire", nil) end
					for shot = 1, spec.Count do
						if not valid() then return false end
						local aim
						if spec.Interval then
							aim = aimFrom(gun:Muzzle(), shot % 2 == 1 and lead or 0)
						else
							local angle = math.rad((shot - (spec.Count + 1) / 2) * spec.Spread)
							aim = CFrame.Angles(0, angle, 0):VectorToWorldSpace(direction)
						end
						fire(spec, aim, speed, {
							Homing = isHoming and { Target = target, Turn = M.Homing.Turn, Duration = M.Homing.Duration } or nil,
							Hazard = isHazard,
       DebuffKey=entry, Clue=fakePoint~=nil, ClueTarget=target,
						})
      if fakePoint then
       local delta=fakePoint-fakeOrigin
       local fakeDirection=delta.Magnitude>.01 and delta.Unit or aim
       if not spec.Interval then
        local angle=math.rad((shot-(spec.Count+1)/2)*spec.Spread)
        fakeDirection=CFrame.Angles(0,angle,0):VectorToWorldSpace(fakeDirection)
       end
       fire(spec,fakeDirection,speed,{Origin=fakeOrigin,Fake=true,FakeDistance=delta.Magnitude,
        Homing=isHoming and {Point=fakePoint,Turn=M.Homing.Turn,Duration=M.Homing.Duration} or nil})
       V.Muzzle(cast,fakeOrigin,fakeDirection,spec)
       Audio.Emit(actor,"ProjectileCast",fakeOrigin)
       actor:SetAttribute("TrueIllusionFakeRocketsFired",(actor:GetAttribute("TrueIllusionFakeRocketsFired") or 0)+1)
      end
						entry.Shots += 1
						actor:SetAttribute("TrueIllusionRocketsFired", (actor:GetAttribute("TrueIllusionRocketsFired") or 0) + 1)
						Audio.Emit(actor, "ProjectileCast", gun:Muzzle())
						V.Muzzle(cast, gun:Muzzle(), aim, spec)
						if shot == 1 or not spec.Interval then
							gun:Recoil(spec.Interval and 0.5 or (spec.Radius >= 8 and 1.6 or 1))
							if core.Alive(target) then kick(target.HumanoidRootPart.Position) end
						end
						if spec.Interval and shot < spec.Count and not waitFor((index > Timeline.BreakFor(Style.CloneCount) and spec.Interval * 0.5 or spec.Interval) * math.min(1, Timeline.CloneCount / Style.CloneCount)) then return false end
					end
					gun:Fired()

				end

				if not waitUntil(Timeline.FinaleAt) then return false end
				if not finaleSequence() then return false end
				gun:Dismiss(0.4)
				fan:Hide(0.2)
				V.Sparks(cast, gun:Muzzle(), { Count = 12, Card = true, Speed = { 8, 20 }, Life = { 0.5, 0.8 }, Gravity = 16,
					Colors = { Style.White, Style.Gold }, Size = Vector3.new(0.5, 0.72, 0.04) })
				if waitUntil(Timeline.EndAt) then finish() end
				return naturalEnd
			end
			actor:SetAttribute("TrueIllusionCompleted", false)
			local ok, result = xpcall(run, debug.traceback)
			cast:Dispose()
			if not ok then error(result, 0) end
			return naturalEnd or result
		end)
	end
	function api.Combo(target)
		if not api.CanUse(target) then return false end
		return runSequence(target)
	end
	function api.Dispose() if current and current.Dispose then current:Dispose() end end
	return api
end
