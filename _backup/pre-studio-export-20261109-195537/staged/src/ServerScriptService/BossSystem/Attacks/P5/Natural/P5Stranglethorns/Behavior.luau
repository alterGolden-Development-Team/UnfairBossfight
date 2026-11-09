local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local S = require(script.Parent.Style)
local SLAM = { RightShoulder = { 30, 0, 20 }, LeftShoulder = { 30, 0, -20 }, Waist = { 30, 0, 0 }, RightHip = { -40, 0, 0 }, RightKnee = { 50, 0, 0 },
	LeftHip = { -40, 0, 0 }, LeftKnee = { 50, 0, 0 } }

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
		local ok, result = pcall(core.Perform, target, S.Name, function()
			core.Face(target)
			core.PoseAngles(SLAM, 0.12)
			actor:SetAttribute("AttackState", "Stranglethorns")
			if not c.Wait(c.Tell(S.Tell)) then return false end
			pcall(Audio.Emit, actor, "EarthRise", c.Root)
			 -- no root line any more: areas of thorns break out of the ground at random spots, instantly
			actor:SetAttribute("AttackState", "Stranglethorns: the thickets")
			local arenaMiddle = c.Center()
			 -- every other area lands on a player (scattered a little), the rest anywhere in the arena
			local function pick(k)
				local list = c.Targets()
				local base, scatter
				if k % 2 == 1 and #list > 0 then
					base, scatter = list[math.random(1, #list)].HumanoidRootPart.Position, S.Near
				else
					base, scatter = arenaMiddle, S.Wide
				end
				local ang, dist = math.random() * math.pi * 2, math.sqrt(math.random()) * scatter
				return c.Ground(base + Vector3.new(math.cos(ang), 0, math.sin(ang)) * dist)
			end
			local function snap(center)
				c.Send("ThicketSnap", { Pos = center, Radius = S.Radius })
				pcall(Audio.Emit, actor, "GroundErupt", center)
				core.ScreenEffect("Shake", { Origin = center, Radius = 180, Intensity = 0.9, Duration = 0.3 })
				for _, char in ipairs(c.Targets()) do
					local rel = char.HumanoidRootPart.Position - center
					if Vector3.new(rel.X, 0, rel.Z).Magnitude <= S.Radius and rel.Y <= 10 then
						c.Hit(char, S.SnapDamage, center, { Knock = { Direction = Vector3.yAxis, Speed = 2, Lift = S.SnapLift, Duration = 0.3,
							Sustain = 0.08, AllowPlayerControl = false, ContainsArena = true } })
					end
				end
			end
			local total = c.Count(S.Areas)
			local spawned, t, nextAt, pending = 0, 0, 0, {}
			if not c.Over(S.Duration + S.Grow + 0.1, function(_, dt)
				t += dt
				while spawned < total and t >= nextAt do
					spawned += 1
					nextAt += S.Duration / total * (0.4 + math.random() * 1.2)
					local center = pick(spawned)
					c.Send("Thicket", { Pos = center, Radius = S.Radius, Time = S.Grow })
					pending[#pending + 1] = { At = t + S.Grow, Pos = center }
				end
				for i = #pending, 1, -1 do
					if t >= pending[i].At then
						snap(pending[i].Pos)
						table.remove(pending, i)
					end
				end
			end) then return false end
			for _, p in ipairs(pending) do
				snap(p.Pos)
			end
			actor:SetAttribute("P5Stranglethorns", (actor:GetAttribute("P5Stranglethorns") or 0) + 1)
			return c.Wait(0.1)
		end)
		c.ReleaseAll()
		if not ok then
			warn("[" .. S.Name .. "] " .. tostring(result))
			return false
		end
		return result
	end
	function api.Dispose()
		c.ReleaseAll()
	end
	return api
end
