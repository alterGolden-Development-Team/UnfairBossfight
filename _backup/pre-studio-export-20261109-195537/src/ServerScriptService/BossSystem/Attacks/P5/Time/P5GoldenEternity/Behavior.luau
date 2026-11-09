local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Time = require(B.Mechanics.Time.TimeEffectController)
local Encounter = require(B.Players.PlayerEncounter)
local S = require(script.Parent.Style)

local RAISE = { RightShoulder = { 160, 0, 10 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 20, 0, -30 }, Waist = { -10, 0, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	 -- real time: inside the stop only he moves, so his steps are counted on the wall clock
	local function real(seconds)
		local ends = os.clock() + seconds
		while os.clock() < ends do
			if not c.Valid() then
				return false
			end
			task.wait()
		end
		return true
	end

	function api.CanUse(target)
		return c.CanStart(target) and not Time.IsStopped(actor)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(RAISE, 0.12)
			actor:SetAttribute("AttackState", "Golden Eternity")
			local tell = c.Tell(S.Tell)
			c.Send("EternityTell", { Time = tell })
			pcall(Encounter.Say, S.Line, nil, { Duration = 2 })
			if not c.Wait(tell) then
				return false
			end
			local stop = Time.StopTime(actor, S.StopTime)
			if not stop then
				return false
			end
			local started = os.clock()
			actor:SetAttribute("AttackState", "Golden Eternity: time has stopped")
			local blades = c.Count(S.Blades)
			local marked = {}
			for _, char in ipairs(c.Targets()) do
				if os.clock() - started > S.StopTime - 0.7 then
					break
				end
				if core.Alive(char) and c.Blink(c.Behind(char, S.Distance)) then
					core.Face(char)
					core.Melee.Pose(#marked % 2 == 0 and "Slash1" or "Slash2", 0.05)
					c.Send("FrozenBlades", { Pos = char.HumanoidRootPart.Position, Count = blades, Radius = S.BladeRadius,
						Seed = math.random(1, 1e6) })
					marked[#marked + 1] = char
					if not real(S.PerVictim) then
						break
					end
				end
			end
			 -- the shield cue on everyone with blades around them, timed to the moment time resumes
			local left = math.max(S.StopTime - (os.clock() - started), 0)
			for _, char in ipairs(marked) do
				c.Warn(char, "Hold", math.max(left, 0.6))
			end
			if not real(left) then
				stop:Dispose("cancelled")
				return false
			end
			if not stop.closed then
				stop:Dispose("completed")
			end
			 -- time resumes: every blade strikes and a shockwave rolls out of him
			actor:SetAttribute("AttackState", "Golden Eternity: time resumes")
			c.Send("BladesRelease", {})
			local ground = c.Ground(core.Root.Position)
			c.Shockwave(ground, { Speed = S.WaveSpeed, Range = S.WaveRange, Width = S.WaveWidth, Height = S.WaveHeight,
				Damage = S.WaveDamage })
			core.ScreenEffect("Shake", { Origin = ground, Radius = 500, Intensity = 1.1, Duration = 0.5 })
			for _, char in ipairs(marked) do
				if core.Alive(char) and not c.Deflected(char, "Hold") then
					c.Hit(char, S.BladeDamage * blades, char.HumanoidRootPart.Position + Vector3.new(0, 4, 0), { BreaksBlock = true })
				end
			end
			actor:SetAttribute("P5GoldenEternities", (actor:GetAttribute("P5GoldenEternities") or 0) + 1)
			return c.Wait(0.5)
		end)
	end
	function api.Dispose() end
	return api
end
