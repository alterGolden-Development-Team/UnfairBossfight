local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Effects = require(B.Combat.EffectService)
local S = require(script.Parent.Style)
local function holdLead() return (Config.DeflectHoldTime or 0.2) + 0.45 end
local CAST = { RightShoulder = { 120, 0, 20 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 120, 0, -20 }, LeftElbow = { 10, 0, 0 }, Waist = { -10, 0, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local running
	function api.CanUse(target)
		return c.CanStart(target) and not (running and running:Alive())
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(CAST, 0.15)
			actor:SetAttribute("AttackState", "Aurora Curtain")
			if not c.Wait(c.Tell(S.Tell)) then
				return false
			end
			 -- the sweeps, laid out now and run by a background cast: he is free again as soon as he has called them
			local center = c.Ground(target.HumanoidRootPart.Position)
			local spin = math.random() * math.pi * 2
			local warn = c.Tell(S.Warn)
			local reach = S.Distance * 2
			local speed = reach / S.SweepTime
			local sweeps, at = {}, 0
			for i = 1, S.Sweeps do
				local a = spin + (i - 1) * (math.pi * 2 / 3) + (math.random() - 0.5) * 0.4
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				local start = center - dir * S.Distance
				sweeps[i] = { Frame = CFrame.lookAt(start, start + dir), WarnAt = at, GoAt = at + warn, Front = 0, Hit = {}, Cued = {} }
				at += warn + S.SweepTime + S.SweepGap
			end
			local cast = Effects.NewCast(actor, S.Name, at + 1)
			cast.PersistsThroughEmitterStun = true
			running = cast
			local t = 0
			cast:Step(function(dt)
				t += dt
				if actor:GetAttribute("Phase") ~= 5 or actor:GetAttribute("PhaseTransitionInProgress") then
					cast:Dispose()
					return false
				end
				local live = false
				for _, sw in ipairs(sweeps) do
					if not sw.Warned and t >= sw.WarnAt then
						sw.Warned = true
						c.Send("CurtainWarn", { Frame = sw.Frame, Span = S.Span, Time = warn })
					end
					if not sw.Sent and t >= sw.GoAt then
						sw.Sent = true
						c.Send("Curtain", { Frame = sw.Frame, Span = S.Span, Height = S.Height, Distance = reach, Time = S.SweepTime })
					end
					local u = t - sw.GoAt
					if u < S.SweepTime then
						live = true
					end
					if u >= 0 and u <= S.SweepTime then
						local back = sw.Front
						sw.Front = math.min(u * speed, reach)
						for _, char in ipairs(c.Targets()) do
							if not sw.Hit[char] then
								local p = sw.Frame:PointToObjectSpace(char.HumanoidRootPart.Position)
								local along = -p.Z
								if math.abs(p.X) <= S.Span / 2 and p.Y <= S.Height and along >= 0 then
									local ahead = along - sw.Front
									 -- the HOLD shield as the wall closes in on them
									if not sw.Cued[char] and ahead > 0 and ahead <= speed * holdLead() then
										sw.Cued[char] = true
										c.Warn(char, "Hold", ahead / speed + 0.1)
									end
									if along >= back - S.Thickness and along <= sw.Front + 1 then
										sw.Hit[char] = true
										if not c.Deflected(char, "Hold") then
											c.Hit(char, S.Damage, char.HumanoidRootPart.Position)
										end
									end
								end
							end
						end
					end
				end
				if not live then
					cast:Dispose()
					return false
				end
				return true
			end)
			actor:SetAttribute("P5AuroraCurtains", (actor:GetAttribute("P5AuroraCurtains") or 0) + 1)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose()
		if running then
			running:Dispose()
		end
	end
	return api
end
