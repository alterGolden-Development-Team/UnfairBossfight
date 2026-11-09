local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local UP = Vector3.yAxis
local CALL = { RightShoulder = { 160, 0, 30 }, LeftShoulder = { 160, 0, -30 }, Waist = { -15, 0, 0 } }
local function flat(v) v = v * FLAT return v.Magnitude > 0.1 and v.Unit or nil end
local function knock(dir, speed, lift)
	return { Direction = dir, Speed = speed or 36, Lift = lift or 14, Duration = 0.3, Sustain = 0.07, AllowPlayerControl = false, ContainsArena = true }
end
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local function sound(name, at) pcall(Audio.Emit, actor, name, at or c.Root) end
	 -- his root's height over the floor, so a move to a floor point keeps his feet on it
	local function lift() return c.Root.Position.Y - c.Ground(c.Root.Position).Y end
	local running, token = false, nil
	 -- waits inside the background cast; false once it was cancelled (Dispose, a new phase) or the fight moved on
	local function hold(mine, seconds)
		return c.Over(seconds, function()
			if token ~= mine then return false end
		end) and token == mine
	end
	local function background(fn)
		local mine = {}
		token, running = mine, true
		actor:SetAttribute("P5BG_" .. S.Name, true)  -- a cast still running in the background (P5SwordDancer waits for a clear stage)
		task.spawn(function()
			local ok, err = pcall(fn, mine)
			if not ok then warn("[" .. S.Name .. "] " .. tostring(err)) end
			if token == mine then running = false actor:SetAttribute("P5BG_" .. S.Name, nil) end
		end)
	end
	function api.CanUse(target)
		return c.CanStart(target) and not running
	end
	 -- the star hangs high over the middle of the map and stays there: it does not follow him
	local skyAt = c.Center() + UP * S.SkyHeight
	local function orbAt()
		return skyAt
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Ultra Blue")
			core.Face(target)
			core.PoseAngles(CALL, 0.15)
			local n = c.Count(S.Beams)
			local rise = c.Tell(S.Rise)
			local pulse = math.max(0.45, c.Tell(S.Pulse))
			local throwTell = c.Tell(S.ThrowTell)
			skyAt = c.Center() + UP * S.SkyHeight
			c.Fx("P5Ascend", "BlueOrb", { Time = rise + n * (pulse + S.BeamGap) + throwTell + 0.1, Height = S.SkyHeight, Size = S.OrbSize, Rise = rise,
				Pos = skyAt })
			sound("RoyalSummon")
			local first = target
			background(function(mine)
				if not hold(mine, rise) then return end
				for _ = 1, n do
					local victim = c.RandomTarget()
					if not victim or not core.Alive(victim) then break end
					c.Fx("P5Ascend", "BluePulse", { Time = pulse, Victim = victim })
					c.Warn(victim, "Tap", pulse + 0.05)
					if not hold(mine, pulse) then return end
					if core.Alive(victim) then
						local from = orbAt()
						local dir = victim.HumanoidRootPart.Position - from
						dir = dir.Magnitude > 0.1 and dir.Unit or -UP
						local length = S.BeamRange
						 -- no range limit (BeamRange is only the longest a single beam part can be drawn): it stops at the ground or a wall
						local wall = workspace:Raycast(from, dir * length, core.Params())
						if wall then length = math.max(wall.Distance, 4) end
						c.Fx("P5Ascend", "BlueBeam", { From = from, To = from + dir * length, Width = S.BeamWidth })
						sound("RangedLaunch")
						for _, char in ipairs(c.Targets()) do
							local q = char.HumanoidRootPart.Position
							local along = (q - from):Dot(dir)
							if along > 0 and along <= length + 3 and (q - (from + dir * along)).Magnitude <= S.BeamWidth + 1.5
								and not c.Deflected(char, "Tap") then
								c.Hit(char, S.BeamDamage, from, { Knock = knock(flat(dir) or Vector3.zAxis, 30, 10) })
							end
						end
					end
					if not hold(mine, S.BeamGap) then return end
				end
				local aimAt = core.Alive(first) and first or c.RandomTarget()
				if not aimAt then return end
				local r = aimAt.HumanoidRootPart
				local aim = c.Ground(r.Position + r.AssemblyLinearVelocity * FLAT * S.Predict)
				c.Fx("P5Ascend", "BlueThrow", { From = orbAt(), To = aim, Tell = throwTell, Time = S.ThrowTime, Core = S.CoreRadius })
				if not hold(mine, throwTell) then return end
				sound("LanceLaunch")
				if not hold(mine, S.ThrowTime) then return end
				sound("HandExplosion", aim)
				core.ScreenEffect("Shake", { Origin = aim, Radius = 300, Intensity = 1.6, Duration = 0.5 })
				for _, char in ipairs(c.Targets()) do
					local rel = char.HumanoidRootPart.Position - aim
					if (rel * FLAT).Magnitude <= S.CoreRadius and rel.Y <= 20 then
						c.Hit(char, S.CoreDamage, aim + UP * 2, { Knock = knock(flat(rel) or Vector3.zAxis, 50, 24) })
					end
				end
				-- (one explosion and that is all: no growing shell)
			end)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose()
		token, running = nil, false
		actor:SetAttribute("P5BG_" .. S.Name, nil)
	end
	return api
end
