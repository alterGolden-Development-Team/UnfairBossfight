local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Registry = require(B.Combat.AttackRegistry)
local Placement = require(B.Encounter.ArenaPlacement)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local CALL = { RightShoulder = { 160, 0, 30 }, LeftShoulder = { 160, 0, -30 }, Waist = { -15, 0, 0 } }
local THROW_R = { RightShoulder = { 90, 0, -10 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 30, 0, -20 }, Waist = { 8, -15, 0 } }
local ATTRIBUTES = { "GildedThreadSpeed", "GildedThreadLifetime", "GildedThreadSegmentLifetime" }
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local function sound(name, at) pcall(Audio.Emit, actor, name, at or c.Root) end
	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Enhanced Glided Thread")
			core.Face(target)
			core.PoseAngles(CALL, 0.12)
			 -- the Phase 1.5 thread does the drawing, bouncing and burning; this attack only places and fires seven of them
			local thread = Registry.For(actor, "P1.5GildedThread")
			local n = c.Count(S.Threads)
			local tell = c.Tell(S.Tell)
			local stagger = S.Stagger * Difficulty.Get(actor).Recovery
			 -- the ring: n points evenly round him at his own height, the whole ring turned a random amount; where the arena
			 -- wall is too close a point is pulled in
			local root = c.Root
			local turn = math.random() * math.pi * 2
			local points = {}
			for i = 1, n do
				local a = turn + (i - 1) / n * math.pi * 2
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				local p = root.Position + dir * S.Ring
				if not Placement.Contains(p, 6) then
					p = root.Position + dir * 5
				end
				points[i] = Vector3.new(p.X, root.Position.Y + 0.3, p.Z)
			end
			c.Fx("P5Ascend", "ThreadRing", { Points = points, Time = tell, Stagger = 0, Center = Vector3.new(root.Position.X, root.Position.Y + 0.3, root.Position.Z), Radius = S.Ring })
			sound("ThreadSummon")
			if not c.Wait(tell) then return false end
			local speed = Difficulty.Design("GildedThread", "Speed", 125, actor) * S.SpeedScale
			 -- point (a ring that blooms, nothing aimed); the threads bounce off the walls and come back
			local center = root.Position * FLAT
			core.PoseAngles(CALL, 0.06)
			for i = 1, n do
				do
					local from = points[i]
					local delta = (from * FLAT - center)
					local a = turn + (i - 1) / n * math.pi * 2
					local dir = delta.Magnitude > 0.1 and delta.Unit or Vector3.new(math.cos(a), 0, math.sin(a))
					 -- the thread reads its speed and lifetimes from these when it is released
					actor:SetAttribute("GildedThreadSpeed", speed)
					actor:SetAttribute("GildedThreadLifetime", S.Lifetime)
					actor:SetAttribute("GildedThreadSegmentLifetime", S.SegmentLifetime)
					local ok, err = pcall(thread.Release, dir, { Origin = from, Damage = S.DamageScale })
					for _, name in ipairs(ATTRIBUTES) do actor:SetAttribute(name, nil) end
					if not ok then warn("[" .. S.Name .. "] " .. tostring(err)) end
				end
			end
			core.PoseAngles(THROW_R, 0.04)
			actor:SetAttribute("P5GlidedThreads", (actor:GetAttribute("P5GlidedThreads") or 0) + 1)
			return c.Wait(0.2)
		end)
	end
	function api.Dispose()
		for _, name in ipairs(ATTRIBUTES) do actor:SetAttribute(name, nil) end
	end
	return api
end
