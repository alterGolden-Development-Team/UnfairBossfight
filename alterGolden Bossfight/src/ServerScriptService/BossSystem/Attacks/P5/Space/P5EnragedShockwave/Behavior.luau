local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local S = require(script.Parent.Style)
local CALL = { RightShoulder = { 160, 0, 30 }, LeftShoulder = { 160, 0, -30 }, Waist = { -15, 0, 0 } }
local STOMP_A = { RightHip = { 60, 0, 0 }, RightKnee = { 20, 0, 0 }, Waist = { 15, 0, 0 }, RightShoulder = { 30, 0, 50 }, LeftShoulder = { 30, 0, -50 } }
local STOMP_B = { LeftHip = { 60, 0, 0 }, LeftKnee = { 20, 0, 0 }, Waist = { 15, 0, 0 }, RightShoulder = { 30, 0, 50 }, LeftShoulder = { 30, 0, -50 } }
local function knock(dir, speed, lift)
	return { Direction = dir, Speed = speed or 36, Lift = lift or 14, Duration = 0.3, Sustain = 0.07, AllowPlayerControl = false, ContainsArena = true }
end
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
			actor:SetAttribute("AttackState", "Enraged Shockwave")
			core.Face(target)
			core.PoseAngles(CALL, 0.1)
			local tell = c.Tell(S.Tell)
			c.Fx("P5Ascend", "Stomp", { Pos = c.Ground(c.Root.Position), Time = tell, Charge = true })
			sound("Roar")
			if not c.Wait(tell) then return false end
			local gap = math.max(0.2, c.Tell(S.Gap))
			for k = 1, c.Count(S.Waves) do
				core.PoseAngles(k % 2 == 0 and STOMP_A or STOMP_B, 0.04)
				local at = c.Ground(c.Root.Position)
				c.Fx("P5Ascend", "Stomp", { Pos = at })
				sound(k % 3 == 1 and "GroundBreak" or "CataclysmStomp")
				core.ScreenEffect("Shake", { Origin = at, Radius = 240, Intensity = 0.5, Duration = 0.2 })
				c.Shockwave(at, { Speed = S.Speed, Range = S.Range, Width = S.Width, Height = 4, Damage = S.Damage, Knock = knock(nil, 26, 12) })
				if not c.Wait(gap) then return false end
			end
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
