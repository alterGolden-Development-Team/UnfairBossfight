local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local S = require(script.Parent.Style)

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	 -- the draw over his victim: violet for a feint, red for the real cut
	local function draw(victim, real)
		local windup = c.Tell(real and S.Windup or S.FeintWindup)
		core.Face(victim)
		core.Melee.Pose("Windup", 0.08)
		actor:SetAttribute("AttackState", real and "Assassination: marked" or "Assassination: feint")
		c.Send("AssassinTell", { Time = windup, Victim = victim, Fake = not real })
		return c.Wait(windup)
	end

	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			local victim = c.RandomTarget() or target
			local feints = math.random(0, S.MaxFeints)
			for index = 0, feints do  -- the last pass is the real one
				local real = index == feints
				if not core.Alive(victim) then
					victim = c.RandomTarget()
				end
				if not victim or not c.Blink(c.Behind(victim, S.Distance)) or not draw(victim, real) then
					return false
				end
				if real then
					break
				end
				 -- the feint: a false cut that hurts no one, then he comes again from behind
				core.Melee.Pose("Slash1", 0.05)
				c.Send("BlackSlash", { Frame = core.Root.CFrame, Index = 1, Radius = S.Radius, Fake = true })
				actor:SetAttribute("P5AssassinationFeints", (actor:GetAttribute("P5AssassinationFeints") or 0) + 1)
				if not c.Wait(S.FeintGap) then
					return false
				end
			end
			for index = 1, S.Slashes do
				if not core.Alive(victim) then
					break
				end
				core.Face(victim)
				core.Melee.Pose(index % 2 == 1 and "Slash1" or "Slash2", 0.05)
				local frame = core.Root.CFrame
				c.Send("BlackSlash", { Frame = frame, Index = index, Radius = S.Radius })
				for _, char in ipairs(c.Targets()) do
					if c.InArc(frame, char.HumanoidRootPart.Position, S.Radius, S.HalfAngle) then
						c.Execute(char, S.LivesCost, frame.Position)
					end
				end
				if index < S.Slashes and not c.Wait(S.SlashGap) then
					return false
				end
			end
			return c.Wait(0.2)
		end)
	end
	function api.Dispose() end
	return api
end
