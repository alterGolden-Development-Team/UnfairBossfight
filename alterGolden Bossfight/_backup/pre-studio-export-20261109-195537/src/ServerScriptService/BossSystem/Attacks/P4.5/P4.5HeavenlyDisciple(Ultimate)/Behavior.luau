 
 
 
 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local Style = require(script.Parent.Style)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
 
local function HEAL() return Style.Heal * Difficulty.Get().BossSustain end
local V = require(script.Parent.Visuals)
local Effects = require(BossSystem.Combat.EffectService)
local Cooldowns = require(BossSystem.Combat.AbilityCooldownService)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Encounter = require(BossSystem.Players.PlayerEncounter)
local Status = require(BossSystem.Combat.StatusEffectService)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Golden = require(BossSystem.Attacks.Shared.P4GoldenFX)
local NAME = "P4.5HeavenlyDisciple(Ultimate)"
local I, R, Q = Style.Intro, Style.Rain, Style.Quills
 
local BALANCE = table.freeze({ Skill = NAME, ExactDamage = true })
local STUN_TOKEN = "HeavenlyDiscipleStun"
local UP = Vector3.yAxis

 
local function inPhase(actor)
	local phase = actor:GetAttribute("Phase")
	return phase == 4.5 or phase == 5
end

return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local ctx = Golden.Context(core)
	local api = { Cooldown = Style.Cooldown, IsUltimate = true, UltimatePhase = 4.5, ManagesCooldown = true }
	local rng = Random.new()
	local current
	function api.CanUse(target)
		return not current and inPhase(actor) and core.Active() and core.Alive(target)
			and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("PhaseTransitionInProgress")
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
			local cast = Effects.NewCast(actor, NAME, 50)
			current = cast
			local token = Http:GenerateGUID(false)
			local root = core.Root
			local original, anchored = root.CFrame, root.Anchored
			local ended, stopAura, restored = false, nil, false
			local rainOver = false  
			local function restore()
				if restored or not actor.Parent then return end
				restored = true
				actor:SetAttribute("HeavenlyDiscipleActive", false)
				if (actor:GetAttribute("PhaseGeneration") or 0) == generation and (actor:GetAttribute("MovementRevision") or 0) == revision then
					local frame = Placement.Validate(actor, root.CFrame, { Margin = 8 }) or Placement.Validate(actor, original, { Margin = 8 })
					if frame then root.CFrame = frame end
					Time.SetAnchored(root, anchored)
				end
			end
			local function valid()
				return cast:Alive() and core.Active() and inPhase(actor)
					and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
			end
			local function send(stage, data, onlyPlayer)
				data = data or {}
				data.Stage, data.Owner, data.Token = stage, actor, token
				data.Origin, data.Radius = data.Origin or root.Position, 900
				core.ScreenEffect("HeavenlyDisciple", data, onlyPlayer)
			end
			local function shake(intensity, duration)
				core.ScreenEffect("Shake", { Origin = root.Position, Radius = 400, Duration = duration, Intensity = intensity })
			end
			cast.OnDispose = function()
				if current == cast then current = nil end
				rainOver = true
				if stopAura then stopAura() end
				if not ended then
					ended = true
					pcall(send, "End", { Interrupted = true })
				end
				restore()
			end
			actor:SetAttribute("HeavenlyDiscipleActive", true)
			actor:SetAttribute("HeavenlyDiscipleArrows", 0)
			actor:SetAttribute("HeavenlyDiscipleArrowsScheduled", 0)
			actor:SetAttribute("HeavenlyDiscipleRandomArrows", 0)
			actor:SetAttribute("HeavenlyDiscipleAimedArrows", 0)
			actor:SetAttribute("HeavenlyDiscipleVolleys", 0)
			actor:SetAttribute("HeavenlyDiscipleBarrageComplete", false)
			actor:SetAttribute("HeavenlyDiscipleQuills", 0)
			actor:SetAttribute("HeavenlyDiscipleQuillHits", 0)
			actor:SetAttribute("HeavenlyDiscipleHealed", 0)

			 
			local center = Placement.GroundPoint(bounds.Frame.Position, { Clamp = true }) or bounds.Frame.Position
			local floorY = center.Y
			local starPosition = center + Vector3.new(0, Style.StarHeight, 0)
			local function bodyOf(char)
				return core.Alive(char) and char:FindFirstChild("HumanoidRootPart") or nil
			end
			 
			local function targets()
				local list = {}
				for _, char in ipairs(core.Characters()) do
					if bodyOf(char) then table.insert(list, char) end
				end
				return list
			end
			local function ground(position)
				local g = Placement.GroundPoint(position, { Clamp = true })
				return g and Vector3.new(g.X, g.Y, g.Z) or Vector3.new(position.X, floorY, position.Z)
			end
			local function randomGround()
				local p = bounds.Frame:PointToWorldSpace(Vector3.new(rng:NextNumber(-1, 1) * bounds.HalfX * 0.9, 0, rng:NextNumber(-1, 1) * bounds.HalfZ * 0.9))
				return ground(Vector3.new(p.X, floorY + 4, p.Z))
			end
			local function clampToArena(p)
				local l = bounds.Frame:PointToObjectSpace(p)
				local x = math.clamp(l.X, -bounds.HalfX * 0.92, bounds.HalfX * 0.92)
				local z = math.clamp(l.Z, -bounds.HalfZ * 0.92, bounds.HalfZ * 0.92)
				local w = bounds.Frame:PointToWorldSpace(Vector3.new(x, 0, z))
				return ground(Vector3.new(w.X, floorY + 4, w.Z))
			end

			 
			local total = math.max(4, math.floor(R.Count))
			local finalCount = math.clamp(math.floor(R.FinalVolley), 1, total - 1)
			local barrageCount = total - finalCount
			local volleySize = math.clamp(math.floor(R.VolleySize or 5), 1, 12)
			local volleyInterval = math.max(0.08, R.VolleyInterval or 0.2)
			local volleyCount = math.ceil(barrageCount / volleySize)
			local barrageLength = (volleyCount - 1) * volleyInterval
			local judgementAt = barrageLength + R.Telegraph + 0.25
			local rainLength = judgementAt + R.JudgementTelegraph + 0.1
			actor:SetAttribute("HeavenlyDisciplePlannedArrows", total)
			actor:SetAttribute("HeavenlyDiscipleImpactRadius", R.Radius)

			 
			local plannedLength = I.Star + I.Charge + I.Draw + I.Flight + I.Bloom + rainLength + 1.4
			local healed, healCarry, nextHealPulse = 0, 0, 0
			local function heal(dt)
				if healed >= HEAL() then return end
				local h = actor:FindFirstChildOfClass("Humanoid")
				if not h or h.Health <= 0 then return end
				local amount = math.min(HEAL() - healed, HEAL() * dt / plannedLength)
				healed += amount
				healCarry += amount
				local before = h.Health
				h.Health = math.min(h.MaxHealth, before + amount)
				if h.Health ~= before then actor:SetAttribute("BossHealth", h.Health) end
				actor:SetAttribute("HeavenlyDiscipleHealed", healed)
				if healCarry >= 2.5 and os.clock() >= nextHealPulse then
					healCarry, nextHealPulse = 0, os.clock() + 0.9
					V.HealPulse(ctx, cast, root)
				end
			end
			 
			local crackleRate, crackleCarry = 2, 0
			local tether, tetherAt = false, 0
			local function crackle(dt)
				crackleCarry += dt * crackleRate
				while crackleCarry >= 1 do
					crackleCarry -= 1
					V.Crackle(ctx, cast, root.Position, 14)
				end
				if tether and os.clock() >= tetherAt then
					tetherAt = os.clock() + rng:NextNumber(0.22, 0.4)
					local hand = actor:FindFirstChild("RightHand") or root
					pcall(Golden.FX.Bolt, ctx, cast, hand.Position,
						starPosition - UP * 20 + Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4)),
						Style.Electric, Style.White, 0.28, nil, 14, 0.16, true)
				end
			end
			 
			local floorRoot = core.FloorY(center + Vector3.new(0, 8, 0), core.Params())
			local lift, liftGoal = 0, 0
			local frameHooks = {}
			local function tick(dt)
				heal(dt)
				crackle(dt)
				if lift ~= liftGoal then
					local step = dt * 7
					lift = lift < liftGoal and math.min(liftGoal, lift + step) or math.max(liftGoal, lift - step * 1.6)
				end
				if floorRoot and (lift > 0.001 or liftGoal > 0) then
					local bob = math.sin(os.clock() * 2.2) * 0.35 * math.min(1, lift / Style.Levitate)
					root.CFrame = CFrame.new(root.Position.X, floorRoot + lift + bob, root.Position.Z) * root.CFrame.Rotation
				end
				for _, hook in ipairs(frameHooks) do hook(dt) end
			end
			local function waitFor(seconds)
				local ends = os.clock() + seconds
				local last = os.clock()
				repeat
					Run.Heartbeat:Wait()
					if not valid() then return false end
					local now = os.clock()
					tick(math.min(now - last, 0.1))
					last = now
				until now >= ends
				return true
			end

			 
			local lastFlash = {}
			local function hurt(char, amount, stun)
				local dealt = Encounter.Damage(char, amount, actor, nil, BALANCE) or 0
				local stunned = false
				if dealt > 0 and stun then
					local ok, result = pcall(Status.ApplyStun, char, STUN_TOKEN, R.Stun, R.StunGrace * (Difficulty.Mercy("HeavenlyStunGrace") or 1), { Family = "HeavenlyArrow" })
					stunned = ok and result == true
				end
				if dealt > 0 then
					local player = Players:GetPlayerFromCharacter(char)
					local now = os.clock()
					if player and (stunned or now - (lastFlash[char] or 0) > 0.12) then
						lastFlash[char] = now
						pcall(send, "Hit", { Stun = stunned, Quill = not stun }, player)
					end
				end
				return dealt
			end

			 
			 
			 
			 
			local quills = {}
			local quillCast = Effects.NewCast(actor, NAME .. " Quills", 60)
			local function quillsValid()
				return actor.Parent and inPhase(actor) and not actor:GetAttribute("EncounterEnded")
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
			end
			local function nearest(position)
				local best, bestDistance
				for _, char in ipairs(targets()) do
					local d = (char.HumanoidRootPart.Position - position).Magnitude
					if not bestDistance or d < bestDistance then best, bestDistance = char, d end
				end
				return best, bestDistance
			end
			local lastQuillNow = quillCast:Now()
			quillCast:Step(function(_, now)
				local dt = math.clamp(now - lastQuillNow, 0, 0.1)
				lastQuillNow = now
				if not quillsValid() then
					for _, q in ipairs(quills) do q.Visual.Pop(false) end
					table.clear(quills)
					task.defer(function() quillCast:Dispose() end)
					return false
				end
				local list = nil
				for i = #quills, 1, -1 do
					local q = quills[i]
					q.Age += dt
					if not q.Visual.Alive() then
						table.remove(quills, i)
						continue
					end
					if q.Age >= Q.Life then
						q.Visual.Pop(false)
						table.remove(quills, i)
						continue
					end
					local previous = q.Position
					if q.Age < Q.Rise then
						 
						q.Velocity *= math.max(0, 1 - 4 * dt)
					else
						if not q.Locked or q.Age >= q.Retarget or not bodyOf(q.Target) then
							q.Target = nearest(q.Position)
							q.Retarget = q.Age + 0.45
							if not q.Locked and q.Target then
								q.Locked = true
								q.Visual.Lock()
							end
						end
						local hrp = q.Target and bodyOf(q.Target)
						if hrp then
							local hunt = q.Age - Q.Rise
							local speed = Q.Speed[1] + (Q.Speed[2] - Q.Speed[1]) * math.clamp(hunt / 1.4, 0, 1)
							local turn = Q.Turn[1] + (Q.Turn[2] - Q.Turn[1]) * math.clamp(hunt / 1.8, 0, 1)
							local aim = hrp.Position + hrp.AssemblyLinearVelocity * 0.08
							local desired = aim - q.Position
							desired = desired.Magnitude > 0.01 and desired.Unit * speed or q.Velocity
							q.Velocity = q.Velocity:Lerp(desired, math.clamp(turn * dt, 0, 1))
							if q.Velocity.Magnitude < speed * 0.6 then
								q.Velocity = (q.Velocity.Magnitude > 0.01 and q.Velocity.Unit or desired.Unit) * speed * 0.6
							end
						else
							 
							q.Velocity = q.Velocity:Lerp(Vector3.new(math.cos(q.Age * 2), 0.2, math.sin(q.Age * 2)) * 8, math.clamp(2 * dt, 0, 1))
						end
					end
					q.Position += q.Velocity * dt
					if q.Position.Y < floorY + 0.8 then q.Position = Vector3.new(q.Position.X, floorY + 0.8, q.Position.Z) end
					 
					local hitChar
					if q.Age >= Q.Rise then
						list = list or targets()
						local seg = q.Position - previous
						local segSq = seg:Dot(seg)
						for _, char in ipairs(list) do
							local p = char.HumanoidRootPart.Position
							local t = segSq > 1e-6 and math.clamp((p - previous):Dot(seg) / segSq, 0, 1) or 0
							if ((previous + seg * t) - p).Magnitude <= Q.HitRadius then
								hitChar = char
								break
							end
						end
					end
					if hitChar then
						hurt(hitChar, Q.Damage, false)
						actor:SetAttribute("HeavenlyDiscipleQuillHits", (actor:GetAttribute("HeavenlyDiscipleQuillHits") or 0) + 1)
						q.Visual.Pop(true)
						table.remove(quills, i)
						continue
					end
					if q.Velocity.Magnitude > 0.1 then
						q.Visual.Set(CFrame.lookAt(q.Position, q.Position + q.Velocity))
					end
				end
				if rainOver and #quills == 0 then
					quillCast:Schedule(0.6, function() quillCast:Dispose() end)
					return false
				end
				return true
			end)
			local function spawnQuills(at)
				for _ = 1, rng:NextInteger(Q.Min, Q.Max) do
					if #quills >= Q.Cap then break end
					local visual = V.Quill(ctx, quillCast, at + Vector3.new(0, 1.2, 0))
					if visual then
						local a = rng:NextNumber(0, math.pi * 2)
						local out = Vector3.new(math.cos(a), 1.7, math.sin(a)).Unit
						visual.Set(CFrame.lookAt(at + Vector3.new(0, 1.2, 0), at + Vector3.new(0, 1.2, 0) + out))
						table.insert(quills, { Visual = visual, Position = at + Vector3.new(0, 1.2, 0), Velocity = out * rng:NextNumber(18, 26),
							Age = rng:NextNumber(0, 0.12), Retarget = 0 })
						actor:SetAttribute("HeavenlyDiscipleQuills", (actor:GetAttribute("HeavenlyDiscipleQuills") or 0) + 1)
					end
				end
			end

			 
			 
			local function arrow(spot, telegraph, scale, options)
				options = options or {}
				actor:SetAttribute("HeavenlyDiscipleArrowsScheduled", (actor:GetAttribute("HeavenlyDiscipleArrowsScheduled") or 0) + 1)
				local radius = options.Radius or R.Radius
				V.Mark(ctx, cast, starPosition, spot, radius, telegraph)
				cast:Schedule(math.max(0, telegraph - R.Flight), function()
					if not valid() then return end
					local from = starPosition + Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(-3, 3), rng:NextNumber(-6, 6))
					V.Arrow(ctx, cast, from, spot + Vector3.new(0, 0.5, 0), R.Flight, scale, function(_, dir)
						if not valid() then return end
						V.Impact(ctx, cast, spot, dir, scale, radius)
						Audio.Emit(actor, scale > 1.6 and "RoyalFinalImpact" or "RainImpact", root)
						actor:SetAttribute("HeavenlyDiscipleArrows", (actor:GetAttribute("HeavenlyDiscipleArrows") or 0) + 1)
						if options.OnLand then pcall(options.OnLand) end
						for _, char in ipairs(core.Characters()) do
							local hrp = bodyOf(char)
							if hrp then
								local offset = hrp.Position - spot
								if Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius + 1 and math.abs(offset.Y) <= 7 then
									hurt(char, R.Damage, true)
								end
							end
						end
						spawnQuills(spot)
					end)
				end)
			end
			local function aimedSpot()
				local list = targets()
				if #list == 0 then return randomGround(), false end
				local hrp = list[rng:NextInteger(1, #list)].HumanoidRootPart
				local v = hrp.AssemblyLinearVelocity
				local lead = hrp.Position + Vector3.new(v.X, 0, v.Z) * (R.Lead or 0.35)
				local a = rng:NextNumber(0, math.pi * 2)
				local d = R.Spread * rng:NextNumber() ^ 1.5
				return clampToArena(lead + Vector3.new(math.cos(a) * d, 2, math.sin(a) * d)), true
			end

			 
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

			 
			actor:SetAttribute("AttackState", "Heavenly Disciple: the star")
			send("Intro", {
				Star = I.Star, Charge = I.Charge, Draw = I.Draw, Flight = I.Flight, Bloom = I.Bloom,
				StarPosition = starPosition, Center = center, Length = plannedLength,
			})
			stopAura = V.Aura(ctx, cast, actor, root)
			core.PoseAngles(Style.Poses.Summon, 0.3)
			Audio.Emit(actor, "RoyalSummon", root)
			local star = V.Star(ctx, cast, starPosition, I.Star)
			Golden.FX.Glint(ctx, cast, starPosition, Style.Yellow, 34, 0.7)
			pcall(Golden.FX.Beam, ctx, cast, root.Position + UP * 3, starPosition, 0.6, Style.Bright, Style.White, I.Star * 0.8)
			if not waitFor(I.Star) then return false end

			 
			actor:SetAttribute("AttackState", "Heavenly Disciple: charge")
			core.PoseAngles(Style.Poses.Charge, 0.2)
			crackleRate = 16
			Audio.Emit(actor, "RoyalFinalCharge", root)
			Golden.FX.Shockwave(ctx, cast, CFrame.new(Vector3.new(root.Position.X, floorY + 0.15, root.Position.Z)), 2, 32, 0.6, Style.Electric, 0.2)
			shake(0.35, I.Charge)
			if not waitFor(I.Charge * 0.45) then return false end
			local bow = V.Bow(ctx, cast, actor, root)
			if bow then
				bow.Aim = function()
					local hand = actor:FindFirstChild("LeftHand") or root
					local d = starPosition - hand.Position
					return d.Magnitude > 0.1 and d.Unit or Vector3.yAxis
				end
			end
			if not waitFor(I.Charge * 0.55) then return false end

			 
			actor:SetAttribute("AttackState", "Heavenly Disciple: draw")
			core.PoseAngles(Style.Poses.Draw, 0.25)
			crackleRate = 6
			Audio.Emit(actor, "RoyalDraw", root)
			if bow then bow.Nock(true) end
			local drawStart = os.clock()
			table.insert(frameHooks, function()
				if bow then bow.Draw(math.clamp((os.clock() - drawStart) / I.Draw, 0, 1)) end
			end)
			if not waitFor(I.Draw) then return false end

			 
			actor:SetAttribute("AttackState", "Heavenly Disciple: release")
			local from = bow and bow.NockWorld or root.Position + Vector3.new(0, 3, 0)
			table.remove(frameHooks)  
			if bow then bow.Release() end
			core.PoseAngles(Style.Poses.Release, 0.06)
			Audio.Emit(actor, "RoyalRelease", root)
			send("Release", { Flight = I.Flight, From = from, To = starPosition })
			shake(0.5, 0.3)
			V.Arrow(ctx, cast, from, starPosition, I.Flight, 2.2, nil)
			Golden.FX.Ring(ctx, cast, CFrame.lookAt(from, starPosition), 1, 10, 0.35, Style.Bright, 0, 0.8, 1)
			if not waitFor(I.Flight) then return false end

			 
			actor:SetAttribute("AttackState", "Heavenly Disciple: bloom")
			if star then star.Flare() end
			Audio.Emit(actor, "RoyalImpact", root)
			send("Bloom", { StarPosition = starPosition, Bloom = I.Bloom })
			shake(0.9, 0.6)
			if not waitFor(I.Bloom * 0.35) then return false end
			if bow then bow.Dissolve(0.4) end
			core.PoseAngles(Style.Poses.Conduct, 0.3)
			liftGoal = Style.Levitate
			if not waitFor(I.Bloom * 0.65) then return false end

			 
			actor:SetAttribute("AttackState", "Heavenly Disciple: stardust")
			crackleRate, tether = 3, true
			send("Rain", { Duration = rainLength })
			Audio.Emit(actor, "RainSummon", root)
			local rainStart = os.clock()
			local function rainWait(untilElapsed)
				local left = untilElapsed - (os.clock() - rainStart)
				return waitFor(math.max(0, left))
			end
			local function pulse(strength)
				if star then star.Pulse(strength) end
			end

			 
			 
			actor:SetAttribute("AttackState", "Heavenly Disciple: arrow storm")
			local arrowsLeft = barrageCount
			local aimedLeft = math.floor(barrageCount * math.clamp(R.AimedShare or 0.3, 0, 1) + 0.5)
			for volley = 1, volleyCount do
				if not rainWait((volley - 1) * volleyInterval) then return false end
				for shot = 1, math.min(volleySize, arrowsLeft) do
					local aimed = rng:NextInteger(1, arrowsLeft) <= aimedLeft
					local spot, actuallyAimed
					if aimed then
						spot, actuallyAimed = aimedSpot()
						aimedLeft -= 1
					else
						spot = randomGround()
					end
					arrowsLeft -= 1
					local counter = actuallyAimed and "HeavenlyDiscipleAimedArrows" or "HeavenlyDiscipleRandomArrows"
					actor:SetAttribute(counter, (actor:GetAttribute(counter) or 0) + 1)
					arrow(spot, R.Telegraph, 1)
				end
				actor:SetAttribute("HeavenlyDiscipleVolleys", volley)
				pulse(0.3)
			end
			actor:SetAttribute("HeavenlyDiscipleBarrageComplete", true)

			 
			if not rainWait(judgementAt) then return false end
			actor:SetAttribute("AttackState", "Heavenly Disciple: judgement")
			core.PoseAngles(Style.Poses.Judgement, 0.2)
			do
				local list = targets()
				local spots = {}
				for _, char in ipairs(list) do table.insert(spots, ground(char.HumanoidRootPart.Position + UP * 2)) end
				if #spots == 0 then table.insert(spots, randomGround()) end
				local great = math.min(#spots, finalCount)
				local ring = finalCount - great
				local perSpot = math.max(1, math.ceil(ring / great))
				local telegraph = R.JudgementTelegraph
				send("Final", { Duration = telegraph })
				Audio.Emit(actor, "RoyalFinalCharge", root)
				pulse(1.2)
				shake(0.4, telegraph)
				crackleRate = 12
				for k = 1, great do
					V.Seal(ctx, cast, spots[k], R.JudgementRing + 2, telegraph)
					arrow(spots[k], telegraph, R.JudgementScale, { Radius = R.Radius * 1.5 })
				end
				for k = 1, ring do
					local around = spots[(k - 1) % great + 1]
					local index = math.floor((k - 1) / great)
					local a = index / perSpot * math.pi * 2
					arrow(clampToArena(around + Vector3.new(math.cos(a) * R.JudgementRing, 0, math.sin(a) * R.JudgementRing)), telegraph, 1.3)
				end
				if not waitFor(telegraph + 0.1) then return false end
				send("Judged", {})
				shake(1.1, 0.6)
			end
			rainOver = true

			 
			actor:SetAttribute("AttackState", "Heavenly Disciple: fade")
			crackleRate, tether = 0, false
			liftGoal = 0
			if star then star.Collapse(0.8) end
			send("Collapse", {})
			core.Melee.Pose("Idle", 0.4)
			if not waitFor(1) then return false end
			 
			heal(plannedLength)
			if stopAura then stopAura() end
			ended = true
			restore()
			send("End", {})
			 
			cast:Schedule(0.6, function() cast:Dispose() end)
			if current == cast then current = nil end
			return true
		end)
		if current and not result then current:Dispose() end
		return result
	end
	function api.Dispose()
		if current then current:Dispose() end
	end
	return api
end
