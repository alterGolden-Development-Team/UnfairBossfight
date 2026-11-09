local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local S = require(script.Parent.Style)

local COIL = { RightShoulder = { -20, 0, 35 }, RightElbow = { 40, 0, 0 }, LeftShoulder = { 25, 0, -30 }, Waist = { 18, -25, 0 },
	RightHip = { -30, 0, 5 }, RightKnee = { 50, 0, 0 }, LeftHip = { -15, 0, -5 }, LeftKnee = { 45, 0, 0 } }
local RISE = { RightShoulder = { 175, 0, -10 }, RightElbow = { 5, 0, 0 }, LeftShoulder = { 30, 0, -25 }, Waist = { -14, 20, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			local count = math.random(S.MinStrikes, S.MaxStrikes)
			local last
			for strike = 1, count do
				local victim = c.RandomTarget(last)
				if not victim then
					break
				end
				last = victim
				if not c.Blink(c.Beside(victim, S.Distance, 0)) then
					if strike == 1 then
						return false
					end
					break
				end
				core.PoseAngles(COIL, 0.1)
				actor:SetAttribute("AttackState", ("Upper Cut: %d / %d"):format(strike, count))
				local point = c.Ground((core.Root.CFrame * CFrame.new(0, 0, -S.Reach)).Position)
				local windup = c.Tell(S.Windup)
				c.Warn(victim, "Tap", windup + 0.1)  -- Tap Deflect
				c.Send("UpperTell", { Pos = point, Time = windup })
				if not c.Wait(windup) then
					return false
				end
				core.PoseAngles(RISE, 0.06)
				c.Send("UpperSlash", { Frame = core.Root.CFrame, Pos = point, Height = S.Height })
				core.ScreenEffect("Shake", { Origin = point, Radius = 70, Intensity = 0.45, Duration = 0.2 })
				for _, char in ipairs(c.Targets()) do
					local p = char.HumanoidRootPart.Position
					local flat = Vector3.new(p.X - point.X, 0, p.Z - point.Z)
					if flat.Magnitude <= S.Radius and p.Y >= point.Y - 3 and p.Y <= point.Y + S.Height and not c.Deflected(char, "Tap") then
						local landed = c.Hit(char, S.Damage, point + Vector3.new(0, 2, 0), { BreaksBlock = true, Knock = {
							Direction = flat.Magnitude > 0.1 and flat or core.Root.CFrame.LookVector, Speed = 6, Lift = S.Lift,
							Duration = 0.3, Sustain = 0.08, AllowPlayerControl = true, ContainsArena = true } })
						if landed > 0 and math.random() < S.PierceChance then
							actor:SetAttribute("P5GoldenPierceArmedUntil", workspace:GetServerTimeNow() + S.PierceWindow)
							actor:SetAttribute("P5GoldenPierceVictim", char.Name)
						end
					end
				end
				actor:SetAttribute("P5UpperCutStrikes", (actor:GetAttribute("P5UpperCutStrikes") or 0) + 1)
				if strike < count and not c.Wait(S.Gap) then
					return false
				end
			end
			return c.Wait(0.25)
		end)
	end
	function api.Dispose() end
	return api
end
