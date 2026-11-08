local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local S = require(script.Parent.Style)

local RAISE = { RightShoulder = { 165, 0, -10 }, RightElbow = { 15, 0, 0 }, LeftShoulder = { 40, 0, 20 }, Waist = { -10, 0, 0 } }
local CHOP = { RightShoulder = { 40, 0, -5 }, RightElbow = { 5, 0, 0 }, LeftShoulder = { -15, 0, -15 }, Waist = { 20, 0, 0 } }
local COIL = { RightShoulder = { 70, 0, 85 }, RightElbow = { 20, 0, 0 }, LeftShoulder = { 40, 0, -40 }, Waist = { 0, -55, 0 } }
local SWEEP = { RightShoulder = { 70, 0, -85 }, RightElbow = { 5, 0, 0 }, LeftShoulder = { 40, 0, 40 }, Waist = { 0, 60, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	local function flatTo(target)
		local d = target.HumanoidRootPart.Position - core.Root.Position
		d = Vector3.new(d.X, 0, d.Z)
		return d.Magnitude > 0.1 and d.Unit or core.Root.CFrame.LookVector, d.Magnitude
	end
	 -- a quick lunge in when the target is out of reach
	local function closeIn(target)
		local dir, dist = flatTo(target)
		if dist <= S.Reach then return true end
		local start = core.Root.CFrame
		local goal = start.Position + dir * math.min(dist - S.Reach * 0.6, 40)
		core.Afterimage(start)
		return c.Over(S.LungeTime, function(alpha)
			local p = start.Position:Lerp(goal, alpha)
			core.Root.CFrame = CFrame.lookAt(p, p + dir)
			core.Root.AssemblyLinearVelocity = Vector3.zero
		end)
	end

	local swing = {}
	function swing.Space(target)
		for index = 1, 2 do
			core.Face(target)
			core.Melee.Pose(index == 1 and "Slash1" or "Slash2", 0.06)
			local frame = core.Root.CFrame
			c.Send("WeaponSlash", { Mode = "Space", Kind = "Slash", Frame = frame, Index = index, Radius = S.SaberRadius })
			for _, char in ipairs(c.Targets()) do
				if c.InArc(frame, char.HumanoidRootPart.Position, S.SaberRadius, 70) then
					c.Hit(char, S.SaberDamage, frame.Position)
				end
			end
			if not c.Wait(S.SaberGap) then return false end
		end
		local dir = flatTo(target)
		local origin = core.Root.Position + dir * 2 + Vector3.new(0, 1, 0)
		for k = 1, S.StarCount do
			local yaw = math.rad((k - (S.StarCount + 1) / 2) * S.StarSpread)
			c.Bolt(origin, CFrame.Angles(0, yaw, 0):VectorToWorldSpace(dir), { Speed = S.StarSpeed, Range = S.StarRange,
				Radius = 2, Damage = S.StarDamage, Look = "Star" })
		end
		return true
	end
	function swing.Natural(target)
		core.Face(target)
		core.PoseAngles(COIL, S.SweepWindup * 0.8)
		if not c.Wait(S.SweepWindup) then return false end
		core.PoseAngles(SWEEP, 0.08)
		local frame = core.Root.CFrame
		c.Send("WeaponSlash", { Mode = "Natural", Kind = "Sweep", Frame = frame, Radius = S.SweepRadius })
		for _, char in ipairs(c.Targets()) do
			if c.InArc(frame, char.HumanoidRootPart.Position, S.SweepRadius, S.SweepHalfAngle) then
				c.Hit(char, S.SweepDamage, frame.Position)
			end
		end
		return true
	end
	function swing.Time(target)
		core.Face(target)
		core.PoseAngles(RAISE, S.ChopWindup * 0.8)
		if not c.Wait(S.ChopWindup) then return false end
		core.PoseAngles(CHOP, 0.06)
		local frame = core.Root.CFrame
		local function chop(damage, echo)
			c.Send("WeaponSlash", { Mode = "Time", Kind = "Chop", Frame = frame, Length = S.ChopLength, Echo = echo })
			for _, char in ipairs(c.Targets()) do
				local p = frame:PointToObjectSpace(char.HumanoidRootPart.Position)
				if math.abs(p.X) <= S.ChopHalfWidth and p.Z <= 1 and p.Z >= -S.ChopLength and math.abs(p.Y) <= 7 then
					c.Hit(char, damage, frame.Position)
				end
			end
		end
		chop(S.ChopDamage, false)
		 -- the same chop again a beat later, from where it fell: time repeating itself
		task.delay(S.EchoDelay, function()
			if actor.Parent and actor:GetAttribute("Phase") == 5 and actor:GetAttribute("P5Weapon") == "Time" then
				chop(S.EchoDamage, true)
			end
		end)
		return true
	end

	function api.CanUse(target)
		return c.CanStart(target) and swing[actor:GetAttribute("P5Weapon") or ""] ~= nil
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local mode = actor:GetAttribute("P5Weapon")
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Mode weapon: " .. mode)
			if not closeIn(target) or not core.Alive(target) then
				return false
			end
			if not swing[mode](target) then
				return false
			end
			return c.Wait(0.15)
		end)
	end
	function api.Dispose() end
	return api
end
