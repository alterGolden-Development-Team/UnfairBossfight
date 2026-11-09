local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local S = require(script.Parent.Style)
local UP = Vector3.yAxis
local CALL = { RightShoulder = { 160, 0, 30 }, LeftShoulder = { 160, 0, -30 }, Waist = { -15, 0, 0 } }
 -- a quick slash in front of him: the gold crescent drawn, everyone in the arc hit (TAP deflects)
 -- the TAP shield for anyone in front of him who is about to be cut
 -- slide the boss to `goal` (kept on the arena floor) over `seconds`
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	 -- he is free - walking and starting his other attacks - while the rings keep forming and cutting on their own
	local running, token = false, nil
	local function hold(mine, seconds)
		return c.Over(seconds, function()
			if token ~= mine then return false end
			if actor:GetAttribute("Phase") ~= 5 or actor:GetAttribute("PhaseTransitionInProgress") then return false end
		end) and token == mine
	end
	local function ring(mine, target)
		local center = c.Ground(target.HumanoidRootPart.Position)
		local n = c.Count(S.Swords)
		local spin = math.random() * math.pi * 2
		local swords = {}
		for i = 1, n do
			local a = spin + (i - 1) * math.pi * 2 / n
			swords[i] = center + Vector3.new(math.cos(a), 0, math.sin(a)) * S.Radius + UP * S.Height
		end
		local aim = c.Tell(S.Aim)
		c.Fx("P5Ascend", "SwordRing", { Points = swords, Center = center + UP * 2.5, Time = aim, Stagger = S.Stagger, Speed = S.Speed,
			Reach = S.Radius * 2 })
		if not hold(mine, aim) then return false end
		 -- they fly: everyone near a sword's line as it passes is cut (a few times at most)
		local hits = {}
		local flight = S.Radius * 2 / S.Speed
		local t = 0
		return c.Over(flight + n * S.Stagger, function(_, dt)
			if token ~= mine then return false end
			t += dt
			for i, from in ipairs(swords) do
				local u = t - (i - 1) * S.Stagger
				if u > 0 and u <= flight then
					local dir = ((center + UP * 2.5) - from).Unit
					local p = from + dir * S.Speed * u
					for _, char in ipairs(c.Targets()) do
						local key = char.Name .. i
						if not hits[key] and (char.HumanoidRootPart.Position - p).Magnitude <= S.Width + 1
							and (hits[char] or 0) < S.MaxHits then
							hits[key] = true
							hits[char] = (hits[char] or 0) + 1
							if not c.Deflected(char, "Tap") then
								c.Hit(char, S.Damage, p)
							end
						end
					end
				end
			end
		end) and token == mine
	end
	function api.CanUse(target)
		return c.CanStart(target) and not running
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Sword Dancer")
			core.Face(target)
			core.PoseAngles(CALL, 0.12)
			local mine = {}
			token, running = mine, true
			actor:SetAttribute("P5BG_" .. S.Name, true)
			task.spawn(function()
				local ok, err = pcall(function()
					local who = target
					for round = 1, S.Summons do
						if not who or not core.Alive(who) then who = c.RandomTarget() end
						if not who then break end
						if not ring(mine, who) then break end
						if round < S.Summons and not hold(mine, S.RoundGap) then break end
						who = c.RandomTarget() or who  -- each new ring forms round someone (anyone) again
					end
				end)
				if not ok then warn("[" .. S.Name .. "] " .. tostring(err)) end
				if token == mine then running = false actor:SetAttribute("P5BG_" .. S.Name, nil) end
			end)
			return c.Wait(0.35)  -- just the call: he moves on straight away
		end)
	end
	function api.Dispose()
		token, running = nil, false
		actor:SetAttribute("P5BG_" .. S.Name, nil)
	end
	return api
end
