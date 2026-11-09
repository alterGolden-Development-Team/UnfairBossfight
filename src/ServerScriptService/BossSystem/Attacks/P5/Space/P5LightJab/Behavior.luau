local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Placement = require(B.Encounter.ArenaPlacement)
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local function knock(dir, speed, lift)
	return { Direction = dir, Speed = speed or 36, Lift = lift or 14, Duration = 0.3, Sustain = 0.07, AllowPlayerControl = false, ContainsArena = true }
end
local THRUST = { RightShoulder = { 90, 0, 0 }, RightElbow = { 0, 0, 0 }, Waist = { 10, -25, 0 }, RightHip = { -35, 0, 0 }, RightKnee = { 30, 0, 0 } }
local DRAW = { RightShoulder = { 70, 0, 20 }, RightElbow = { 60, 0, 0 }, Waist = { 5, 20, 0 }, RightHip = { -35, 0, 0 }, RightKnee = { 30, 0, 0 } }
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local function sound(name, at) pcall(Audio.Emit, actor, name, at or c.Root) end
	 -- his root's height over the floor, so a move to a floor point keeps his feet on it
	local function lift() return c.Root.Position.Y - c.Ground(c.Root.Position).Y end
	function api.CanUse(target)
		return c.CanStart(target) and (target.HumanoidRootPart.Position - c.Root.Position).Magnitude <= S.UseRange
	end
	-- a stab is a SPRAY of rapier dashes: Lanes lanes side by side, each with one or two dashes starting at different depths and
	-- leaving gaps between them (the gaps are the safe spots); every stab throws a new pattern
	local function pattern(reach, lanes)
		local list = {}
		for i = 1, lanes do
			local x = (i - (lanes + 1) / 2) * S.LaneGap
			local z = math.random() * reach * 0.3
			for _ = 1, math.random(1, 2) do
				local len = reach * (0.24 + math.random() * 0.3)
				if z + len > reach then len = reach - z end
				if len > 4 then list[#list + 1] = { X = x, Z0 = z, Len = len } end
				z += len + reach * (0.1 + math.random() * 0.16)
				if z >= reach - 4 then break end
			end
		end
		return list
	end
	-- anyone standing on one of the dashes is hit once per stab
	local function strike(frame, list, damage, push)
		for _, char in ipairs(c.Targets()) do
			local p = frame:PointToObjectSpace(char.HumanoidRootPart.Position)
			if math.abs(p.Y) <= 6 then
				for _, r in ipairs(list) do
					if math.abs(p.X - r.X) <= S.RapierRadius and -p.Z >= r.Z0 - 1 and -p.Z <= r.Z0 + r.Len + 1 then
						c.Hit(char, damage, frame.Position, push and { Knock = knock(frame.LookVector, 40, 10) } or nil)
						break
					end
				end
			end
		end
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Light Jab")
			core.Face(target)
			core.PoseAngles(DRAW, 0.1)
			local ready = c.Tell(S.Ready)
			c.Fx("P5Ascend", "JabReady", { Time = ready })
			sound("ThrustCharge")
			if not c.Wait(ready) then return false end
			-- Density (difficulty, Enraged Gate) adds lanes and stabs
			local lanes = math.max(2, c.Count(S.Lanes))
			for k = 1, c.Count(S.Jabs) do
				if core.Alive(target) then core.Face(target) end
				local root = c.Root
				local step = root.CFrame.LookVector * FLAT * S.Advance
				if Placement.Validate(actor, CFrame.new(root.Position + step), { Margin = 6 }) then
					root.CFrame = root.CFrame + step
				end
				root.AssemblyLinearVelocity = Vector3.zero
				core.PoseAngles(THRUST, 0.03)
				local list = pattern(S.Reach, lanes)
				c.Fx("P5Ascend", "Jab", { Frame = root.CFrame, Index = k, Pattern = list })
				if k % 3 == 1 then sound("ThrustStab") end
				strike(root.CFrame, list, S.Damage)
				if not c.Wait(S.Every * 0.5) then return false end
				core.PoseAngles(DRAW, 0.03)
				if not c.Wait(S.Every * 0.5) then return false end
			end
			-- the last one: full-length rapiers across the whole lane, and it throws you back
			if core.Alive(target) then core.Face(target) end
			core.PoseAngles(THRUST, 0.03)
			local finals, count = {}, math.max(3, c.Count(S.FinalRapiers))
			for i = 1, count do
				finals[i] = { X = (i - (count + 1) / 2) * S.LaneGap * 0.8, Z0 = 0, Len = S.FinalReach }
			end
			c.Fx("P5Ascend", "Jab", { Frame = c.Root.CFrame, Index = 0, Big = true, Pattern = finals })
			sound("ThrustBurst")
			strike(c.Root.CFrame, finals, S.FinalDamage, true)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
