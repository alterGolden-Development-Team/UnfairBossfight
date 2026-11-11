local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local WIND = { LeftShoulder = { 30, 0, 100 }, LeftElbow = { 60, 0, 0 }, Waist = { 0, 40, 0 }, RightHip = { -30, 0, 0 }, RightKnee = { 40, 0, 0 } }
local LUNGE = { LeftShoulder = { 90, 0, -10 }, LeftElbow = { 0, 0, 0 }, Waist = { 20, -30, 0 }, LeftHip = { -50, 0, 0 }, RightHip = { 30, 0, 0 } }
 -- a quick slash in front of him: the gold crescent drawn, everyone in the arc hit (TAP deflects)
 -- the TAP shield for anyone in front of him who is about to be cut
 -- slide the boss to `goal` (kept on the arena floor) over `seconds`
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
			actor:SetAttribute("AttackState", "Intrusive Lunge")
			core.Face(target)
			core.PoseAngles(WIND, 0.12)
			local windup = c.Tell(S.Windup)
			c.Fx("P5Strikes", "RiverCharge", { Time = windup })
			if not c.Wait(windup) then return false end
			local from = c.Root.Position
			local dir = ((target.HumanoidRootPart.Position - from) * FLAT)
			dir = dir.Magnitude > 0.1 and dir.Unit or c.Root.CFrame.LookVector
			local length = S.Distance
			local wall = workspace:Raycast(from, dir * length, core.Params())
			if wall then length = math.max(wall.Distance - 3, 4) end
			local to = from + dir * length
			for _, char in ipairs(c.Targets()) do
				local along = (char.HumanoidRootPart.Position - from):Dot(dir)
				if along > 0 and along <= length then
					c.Warn(char, "Tap", along / length * S.Time + 0.12)
				end
			end
			core.PoseAngles(LUNGE, 0.04)
			c.Fx("P5Strikes", "RiverLunge", { From = from, To = to, Time = S.Time })
			pcall(Audio.Emit, actor, "ThrustBurst", c.Root)
			local hit, last = {}, from
			if not c.Over(S.Time, function(a)
				local p = from:Lerp(to, 1 - (1 - a) ^ 2)
				c.Root.CFrame = CFrame.lookAt(p, p + dir)
				c.Root.AssemblyLinearVelocity = Vector3.zero
				for _, char in ipairs(c.Targets()) do
					local q = char.HumanoidRootPart.Position
					local seg = p - last
					local t = seg:Dot(seg) > 1e-4 and math.clamp((q - last):Dot(seg) / seg:Dot(seg), 0, 1) or 0
					if not hit[char] and ((q - (last + seg * t)) * FLAT).Magnitude <= S.Width then
						hit[char] = true
						if not c.Deflected(char, "Tap") then
							c.Hit(char, S.Damage, p, { Knock = { Direction = dir, Speed = 45, Lift = 12, Duration = 0.3, Sustain = 0.08,
								AllowPlayerControl = false, ContainsArena = true } })
						end
					end
				end
				last = p
			end) then return false end
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
