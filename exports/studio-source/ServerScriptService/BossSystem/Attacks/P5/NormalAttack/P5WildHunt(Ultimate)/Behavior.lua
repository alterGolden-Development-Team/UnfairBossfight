local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Ultimate = require(B.Combat.UltimateService)
local Cooldowns = require(B.Combat.AbilityCooldownService)
local Placement = require(B.Encounter.ArenaPlacement)
local Ruin = require(B.Encounter.ArenaRuin)
local Encounter = require(B.Players.PlayerEncounter)
local S = require(script.Parent.Style)
local SCYTHE = "P4DeathScythe(Ultimate)"

local LUNGE = { RightShoulder = { 30, 0, 60 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 30, 0, -60 }, Waist = { 25, 0, 0 },
	RightHip = { -35, 0, 0 }, LeftHip = { 20, 0, 0 } }
local CROUCH = { RightShoulder = { 20, 0, 50 }, LeftShoulder = { 20, 0, -50 }, Waist = { 35, 0, 0 },
	RightHip = { -50, 0, 0 }, RightKnee = { 70, 0, 0 }, LeftHip = { -50, 0, 0 }, LeftKnee = { 70, 0, 0 } }
local BITE = { RightShoulder = { 110, 0, 20 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 70, 0, -20 }, Waist = { 15, 0, 0 } }
local ROAR = { RightShoulder = { 150, 0, 40 }, LeftShoulder = { 150, 0, -40 }, Waist = { -15, 0, 0 } }

local function segmentDistance(point, a, b)
	local d = b - a
	local t = d:Dot(d) > 0.0001 and math.clamp((point - a):Dot(d) / d:Dot(d), 0, 1) or 0
	return (point - (a + d * t)).Magnitude
end

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown, IsUltimate = true, UltimatePhase = 5 }
	local scythe  -- his own Death Scythe for the finale (the P4 ultimate, outside its own phase gating)

	local function flatTo(target)
		local d = target.HumanoidRootPart.Position - core.Root.Position
		d = Vector3.new(d.X, 0, d.Z)
		return d.Magnitude > 0.1 and d.Unit or core.Root.CFrame.LookVector, d.Magnitude
	end
	local function aimAt(target)
		local origin = (core.Root.CFrame * CFrame.new(0, 1, -3)).Position
		local dir = flatTo(target)
		return CFrame.lookAt(origin, origin + dir)
	end
	 -- a dash from where he is to `goal` over `seconds`, hitting everyone within `radius` of the path once
	local function dash(goal, seconds, radius, damage)
		local from = core.Root.Position
		local dir = Vector3.new(goal.X - from.X, 0, goal.Z - from.Z)
		dir = dir.Magnitude > 0.1 and dir.Unit or core.Root.CFrame.LookVector
		local hit, last = {}, from
		return c.Over(seconds, function(alpha)
			local p = from:Lerp(goal, alpha)
			core.Root.CFrame = CFrame.lookAt(p, p + dir)
			core.Root.AssemblyLinearVelocity = Vector3.zero
			if damage then
				for _, char in ipairs(c.Targets()) do
					if not hit[char] and segmentDistance(char.HumanoidRootPart.Position, last, p) <= radius then
						hit[char] = true
						if not c.Deflected(char, "Tap") then c.Hit(char, damage, last) end
					end
				end
			end
			last = p
		end)
	end
	 -- every attack of the hunt starts with him blinking in next to his prey, a random side each time (false when there is no room)
	local function blinkNear(target, distance)
		if not target or not core.Alive(target) then
			return false
		end
		return c.Blink(c.Beside(target, distance or S.BlinkDistance, math.random() * math.pi * 2))
	end
	local function onFloor(position)
		local frame = Placement.Validate(actor, CFrame.new(position), { Margin = 7 })
		return frame and frame.Position or position
	end

	function api.CanUse(target)
		return c.CanStart(target) and Ultimate.Ready(actor, S.Name)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local done = core.Perform(target, S.Name, function()
			 -- 1. two lunges: through the prey and on past, then straight back
			actor:SetAttribute("AttackState", "Wild Hunt: the lunge")
			for pass = 1, 2 do
				if not core.Alive(target) then target = core.Melee.GetTarget() end
				if not target then return false end
				blinkNear(target, S.LungeFrom)  -- each lunge comes out of a blink beside them, not from where he stood
				local dir = flatTo(target)
				local goal = onFloor(target.HumanoidRootPart.Position + dir * S.LungeOvershoot)
				goal = Vector3.new(goal.X, core.Root.Position.Y, goal.Z)
				local windup = c.Tell(S.LungeWindup)
				for _, char in ipairs(c.Targets()) do  -- Tap Deflect: the shield shows on whoever is in the lunge's path
					if segmentDistance(char.HumanoidRootPart.Position, core.Root.Position, goal) <= S.LungeRadius + 8 then
						c.Warn(char, "Tap", windup + S.LungeTime)
					end
				end
				core.PoseAngles(CROUCH, 0.05)
				if not c.Wait(windup) then
					return false
				end
				core.PoseAngles(LUNGE, 0.06)
				c.Send("HuntLunge", { From = core.Root.Position, To = goal, Time = S.LungeTime })
				if not dash(goal, S.LungeTime, S.LungeRadius, S.LungeDamage) or not c.Wait(S.LungePause) then
					return false
				end
			end
			 -- 2. the hunt: he slices the air over and over and every cut flies as a claw (Tap Deflect)
			actor:SetAttribute("AttackState", "Wild Hunt: the hunt")
			for slice = 1, S.Slices do
				if not core.Alive(target) then target = core.Melee.GetTarget() end
				if not target then return false end
				blinkNear(target, S.SliceFrom)  -- every cut is made from a fresh blink next to them
				core.Face(target)
				core.Melee.Pose(slice % 2 == 1 and "Slash1" or "Slash2", 0.05)
				c.Send("HuntSlice", { Frame = aimAt(target), Index = slice })
				local roll = math.rad(25 + math.random() * 40) * (slice % 2 == 1 and 1 or -1)
				c.FireClaw(aimAt(target), { Speed = S.SliceSpeed, Range = S.SliceRange, Width = S.SliceWidth, Spread = S.SliceSpread,
					Roll = roll, Damage = S.SliceDamage, HitHalfWidth = S.SliceHalfWidth, HitHeight = S.SliceHeight, Deflect = "Tap" })
				if not c.Wait(S.SliceGap) then return false end
			end
			 -- 3. he drags himself along the ground into a ferocious bite and a piercing shot (Hold Deflect)
			if not core.Alive(target) then target = core.Melee.GetTarget() end
			if not target then return false end
			actor:SetAttribute("AttackState", "Wild Hunt: the bite")
			blinkNear(target, S.DragDistance)  -- he blinks in, then drags himself the rest of the way into the bite
			local dir, dist = flatTo(target)
			local goal = onFloor(core.Root.Position + dir * math.clamp(dist - 6, 4, S.DragDistance))
			goal = Vector3.new(goal.X, core.Root.Position.Y, goal.Z)
			for _, char in ipairs(c.Targets()) do  -- everyone ahead gets the HOLD cue for the bite and the shot
				local rel = char.HumanoidRootPart.Position - core.Root.Position
				if rel.Magnitude <= S.PierceRange and rel.Unit:Dot(dir) > 0.5 then
					c.Warn(char, "Hold", S.DragTime + 0.35)
				end
			end
			core.PoseAngles(CROUCH, 0.08)
			c.Send("HuntDrag", { From = core.Root.Position, To = goal, Time = S.DragTime })
			if not dash(goal, S.DragTime) then return false end
			core.PoseAngles(BITE, 0.05)
			local frame = core.Root.CFrame
			c.Send("HuntBite", { Frame = frame })
			for _, char in ipairs(c.Targets()) do
				if c.InArc(frame, char.HumanoidRootPart.Position, S.BiteRadius, S.BiteHalfAngle)
					and not c.Deflected(char, "Hold") then
					c.Hit(char, S.BiteDamage, frame.Position, { BreaksBlock = true })
				end
			end
			local origin = (frame * CFrame.new(0, 1, -3)).Position
			c.Bolt(origin, frame.LookVector, { Speed = S.PierceSpeed, Range = S.PierceRange, Radius = S.PierceRadius,
				Damage = S.PierceDamage, Pierce = true, Deflect = "Hold", Look = "Pierce" })
			core.ScreenEffect("Shake", { Origin = origin, Radius = 120, Intensity = 0.6, Duration = 0.25 })
			if not c.Wait(0.35) then return false end
			 -- 4. he stops dead and everything around him explodes (Hold Deflect)
			actor:SetAttribute("AttackState", "Wild Hunt: the burst")
			blinkNear(target, S.BurstFrom)  -- the burst goes off right beside them
			core.PoseAngles(ROAR, 0.1)
			local brace = c.Tell(S.BurstWindup)
			for _, char in ipairs(c.Targets()) do
				if (char.HumanoidRootPart.Position - core.Root.Position).Magnitude <= S.BurstRadius + 6 then
					c.Warn(char, "Hold", brace + 0.1)
				end
			end
			if not c.Wait(brace) then
				return false
			end
			local ground = c.Ground(core.Root.Position)
			c.Send("HuntBurst", { Pos = ground, Radius = S.BurstRadius })
			c.Shockwave(ground, { Speed = S.WaveSpeed, Range = S.WaveRange, Width = 6, Height = 4, Damage = S.WaveDamage,
				Knock = { Speed = 30, Lift = 16, Duration = 0.25, Sustain = 0.05, AllowPlayerControl = true, ContainsArena = true } })
			c.Spikes({ ground }, { Radius = S.SpikeRadius, Damage = S.SpikeDamage, Tall = 1.3, Count = 14, Height = 22 })
			core.ScreenEffect("Shake", { Origin = ground, Radius = 200, Intensity = 1, Duration = 0.4 })
			for _, char in ipairs(c.Targets()) do
				local rel = char.HumanoidRootPart.Position - ground
				if Vector3.new(rel.X, 0, rel.Z).Magnitude <= S.BurstRadius and rel.Y <= S.BurstRadius and not c.Deflected(char, "Hold") then
					c.Hit(char, S.BurstDamage, ground + Vector3.new(0, 2, 0), { Knock = { Direction = rel, Speed = 40,
						Lift = 20, Duration = 0.3, Sustain = 0.08, AllowPlayerControl = true, ContainsArena = true } })
				end
			end
			return c.Wait(S.BurstPause)
		end)
		if not done then
			return false
		end
		scythe = scythe or require(B.Attacks.P4[SCYTHE])(actor)
		Cooldowns.Take(actor, SCYTHE)
		if not core.Alive(target) then target = core.Melee.GetTarget() end
		if target then
			actor:SetAttribute("AttackState", "Wild Hunt: Death Scythe")
			scythe.Forced, scythe.Quick = true, true  -- no warning: he pulls it and says goodbye
			pcall(scythe.Combo, target)
			scythe.Forced, scythe.Quick = false, false
		end
		 -- 6. the first Wild Hunt of the fight burns the world outside the arena
		if actor:GetAttribute("Phase") == 5 and not actor:GetAttribute("EncounterEnded") and Ruin.Ruin(actor) then
			actor:SetAttribute("WildHuntRuined", true)
			pcall(Encounter.Say, S.RuinLine, nil, { Duration = 3 })
		end
		actor:SetAttribute("P5WildHunts", (actor:GetAttribute("P5WildHunts") or 0) + 1)
		return true
	end
	function api.Dispose()
		if scythe and scythe.Dispose then scythe.Dispose() end
	end
	return api
end
