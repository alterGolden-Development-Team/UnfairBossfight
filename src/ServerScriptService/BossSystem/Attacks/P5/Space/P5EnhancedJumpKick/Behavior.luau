local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local UP = Vector3.yAxis
local CROUCH = { Waist = { 35, 0, 0 }, RightHip = { -70, 0, 0 }, RightKnee = { 90, 0, 0 }, LeftHip = { -70, 0, 0 }, LeftKnee = { 90, 0, 0 },
	RightShoulder = { 20, 0, 30 }, LeftShoulder = { 20, 0, -30 } }
local TUCK = { Waist = { 60, 0, 0 }, RightHip = { -100, 0, 0 }, RightKnee = { 120, 0, 0 }, LeftHip = { -100, 0, 0 }, LeftKnee = { 120, 0, 0 },
	RightShoulder = { 60, 0, 0 }, LeftShoulder = { 60, 0, 0 } }
local KICK = { RightHip = { 95, 0, 0 }, RightKnee = { 0, 0, 0 }, LeftHip = { -30, 0, 0 }, LeftKnee = { 60, 0, 0 }, LeftShoulder = { 40, 0, -60 },
	Waist = { -30, 0, 0 } }
local function flat(v) v = v * FLAT return v.Magnitude > 0.1 and v.Unit or nil end
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local function sound(name, at) pcall(Audio.Emit, actor, name, at or c.Root) end
	 -- his root's height over the floor, so a move to a floor point keeps his feet on it
	local function lift() return c.Root.Position.Y - c.Ground(c.Root.Position).Y end
	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Enhanced Jump Kick")
			core.Face(target)
			core.PoseAngles(CROUCH, 0.08)
			if not c.Wait(c.Tell(S.Crouch)) then return false end
			local from = c.Root.Position
			local h = lift()
			local gap = (target.HumanoidRootPart.Position - from) * FLAT
			local toward = flat(gap) or c.Root.CFrame.LookVector
			local top = from + UP * S.Rise + toward * math.min(gap.Magnitude * 0.4, 20)
			sound("FallingCharge")
			core.PoseAngles(TUCK, 0.06)
			if not c.Over(S.RiseTime, function(a)
				local p = from:Lerp(top, 1 - (1 - a) ^ 2)
				c.Root.CFrame = CFrame.lookAt(p, p + toward)
				c.Root.AssemblyLinearVelocity = Vector3.zero
			end) then return false end
			local r = core.Alive(target) and target.HumanoidRootPart
			local aim = c.Ground(r and (r.Position + r.AssemblyLinearVelocity * FLAT * S.Predict) or from)
			local hang = c.Tell(S.Hang)
			c.Fx("P5Ascend", "KickMark", { Pos = aim, Time = hang + S.KickTime, Radius = S.Radius })  -- a red mark (the Jump Kick's is gold)
			local face = flat(aim - top) or toward
			if not c.Over(hang, function()
				c.Root.CFrame = CFrame.lookAt(top, top + face)
				c.Root.AssemblyLinearVelocity = Vector3.zero
			end) then return false end
			local land = aim + UP * h
			 -- feet first: leaning back along the drop, the kicking leg out in front
			core.PoseAngles(KICK, 0.04)
			c.Fx("P5Ascend", "Dive", { From = top, To = land, Time = S.KickTime, Kick = true, Tint = "Enhanced" })
			sound("FallingDescend")
			if not c.Over(S.KickTime, function(a)
				local p = top:Lerp(land, a * a)
				c.Root.CFrame = CFrame.lookAt(p, p + face) * CFrame.Angles(math.rad(40), 0, 0)
				c.Root.AssemblyLinearVelocity = Vector3.zero
			end) then return false end
			c.Root.CFrame = CFrame.lookAt(land, land + face)
			c.Explode(aim, S.Radius, 0, { Look = "Red", Shake = 1.4 })  -- the red blast is only drawn here; the damage is below
			 -- the kick ignores i-frames (the dash, class invulnerability) and defense
			for _, char in ipairs(c.Targets()) do
				local rel = char.HumanoidRootPart.Position - aim
				local flat = Vector3.new(rel.X, 0, rel.Z)
				if flat.Magnitude <= S.Radius and rel.Y <= 18 then
					c.PierceHit(char, S.Damage, aim + UP * 2, { Knock = { Direction = flat.Magnitude > 0.1 and flat or Vector3.zAxis, Speed = 38, Lift = 18,
						Duration = 0.3, Sustain = 0.1, AllowPlayerControl = false, ContainsArena = true } })
				end
			end
			sound("FallingImpact", aim)
			c.Shockwave(aim, { Speed = S.WaveSpeed, Range = S.WaveRange, Width = 3, Height = 4, Damage = S.WaveDamage })
			core.PoseAngles(CROUCH, 0.08)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
