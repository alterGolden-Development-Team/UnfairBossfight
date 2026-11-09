local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local UP = Vector3.yAxis
local CALL = { RightShoulder = { 160, 0, 30 }, LeftShoulder = { 160, 0, -30 }, Waist = { -15, 0, 0 } }
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local function sound(name, at) pcall(Audio.Emit, actor, name, at or c.Root) end
	 -- his root's height over the floor, so a move to a floor point keeps his feet on it
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
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Ultra Red")
			core.Face(target)
			core.PoseAngles(CALL, 0.12)
			local center = c.Center()
			local tell = c.Tell(S.Tell)
			local warm = c.Tell(S.Warm)
			local stop = c.Tell(S.StopTell)
			local lines = math.max(1, c.Count(S.Lines))
			local start = math.random() * math.pi
			local spin = (math.random() < 0.5 and -1 or 1) * S.Spin
			 -- the lines turn on the server clock, so every client draws them where the server hurts
			local at = workspace:GetServerTimeNow() + tell
			c.Fx("P5Ascend", "RedOrb", { Pos = center, Orb = center + UP * S.OrbHeight, At = at, Tell = tell, Radius = S.BlastRadius,
				Lines = lines, HalfWidth = S.HalfWidth, Start = start, Spin = spin, Inner = S.Inner, Outer = S.Outer, Warm = warm,
				SpinTime = S.SpinTime, Stop = stop, Final = S.FinalRadius, OrbScale = S.OrbScale, OrbSize = S.OrbSize })
			sound("RoyalFinalCharge")
			background(function(mine)
				if not hold(mine, tell) then return end
				c.Explode(center, S.BlastRadius, S.BlastDamage, { Look = "Red", Shake = 1.6 })
				sound("HandExplosion", center)
				local nextTick = 0
				if not hold(mine, 0) then return end
				local ok = c.Over(warm + S.SpinTime, function()
					if token ~= mine then return false end
					local now = workspace:GetServerTimeNow()
					if now - at < warm or now < nextTick then
						return
					end
					nextTick = now + S.Tick
					local turn = start + spin * (now - at)
					for _, char in ipairs(c.Targets()) do
						local pos = char.HumanoidRootPart.Position
						local rel = (pos - center) * FLAT
						if pos.Y - center.Y <= 9 then
							for k = 0, lines - 1 do
								local a = turn + k * math.pi / lines
								local dir = Vector3.new(math.cos(a), 0, math.sin(a))
								local along = math.abs(rel:Dot(dir))
								local across = math.abs(rel:Dot(Vector3.new(-dir.Z, 0, dir.X)))
								if across <= S.HalfWidth and along >= S.Inner and along <= S.Outer then
									c.Hit(char, S.TileDamage, pos)
									break
								end
							end
						end
					end
				end)
				if not ok or token ~= mine then return end
				if not hold(mine, stop) then return end  -- (the explosion itself comes without a warning)
				for _, char in ipairs(c.Targets()) do
					if ((char.HumanoidRootPart.Position - center) * FLAT).Magnitude <= S.FinalRadius + 6 then
						-- (no warning: the second explosion shows no hint)
					end
				end
								c.Explode(center, S.FinalRadius, S.FinalDamage, { Look = "Red", Shake = 2.2, Height = 40 })
				sound("HandExplosion", center)
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
