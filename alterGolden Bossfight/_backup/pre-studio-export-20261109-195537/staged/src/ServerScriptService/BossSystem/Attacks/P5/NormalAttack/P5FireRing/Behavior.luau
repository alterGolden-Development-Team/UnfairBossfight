local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local S = require(script.Parent.Style)
local Effects = require(B.Combat.EffectService)

local WIND = { RightShoulder = { 20, 0, 95 }, RightElbow = { 20, 0, 0 }, LeftShoulder = { 30, 0, -40 }, Waist = { 0, 80, 0 },
	RightHip = { -35, 0, 0 }, RightKnee = { 50, 0, 0 }, LeftHip = { -25, 0, 0 }, LeftKnee = { 40, 0, 0 } }
local SPIN = { RightShoulder = { 85, 0, -60 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { -10, 0, -50 }, Waist = { 0, -80, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	function api.CanUse(target)
		 -- only up close: the spin is around him
		return c.CanStart(target) and (target.HumanoidRootPart.Position - c.Root.Position).Magnitude <= S.UseRange
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(WIND, 0.15)
			actor:SetAttribute("AttackState", "Fire Ring")
			local windup = c.Tell(S.Windup)
			pcall(Audio.Emit, actor, "CrescentCharge", c.Root)
			c.Send("FireRingTell", { Time = windup, Radius = S.Radius })
			if not c.Wait(windup) then
				return false
			end
			core.PoseAngles(SPIN, 0.06)
			local center = c.Ground(c.Root.Position)
			pcall(Audio.Emit, actor, "CrescentRelease", c.Root)
			c.Send("FireRingCut", { Pos = center, Radius = S.Radius })
			core.ScreenEffect("Shake", { Origin = center, Radius = 160, Intensity = 0.8, Duration = 0.3 })
			for _, char in ipairs(c.Targets()) do
				local rel = char.HumanoidRootPart.Position - center
				local flat = Vector3.new(rel.X, 0, rel.Z)
				if flat.Magnitude <= S.Radius and rel.Y <= S.Height then
					c.Hit(char, S.Damage, center + Vector3.new(0, 2, 0), { Knock = { Direction = flat.Magnitude > 0.1 and flat or Vector3.zAxis,
						Speed = 30, Lift = 14, Duration = 0.25, Sustain = 0.05, AllowPlayerControl = true, ContainsArena = true } })
				end
			end
			 -- the ring of golden fire on the cut's edge
			c.Send("FireRing", { Pos = center, Radius = S.Radius, Time = S.FireTime, Band = S.FireBand })
			pcall(Audio.Emit, actor, "CrescentFlame", center)
			local cast = Effects.NewCast(actor, "P5FireRing", S.FireTime + 0.5)
			cast.PersistsThroughEmitterStun = true
			local elapsed, tick = 0, 0
			cast:Step(function(dt)
				elapsed += dt
				tick += dt
				if elapsed >= S.FireTime or actor:GetAttribute("Phase") ~= 5 then
					cast:Dispose()
					return false
				end
				if tick >= S.FireTick then
					tick = 0
					for _, char in ipairs(c.Targets()) do
						local rel = char.HumanoidRootPart.Position - center
						if math.abs(Vector3.new(rel.X, 0, rel.Z).Magnitude - S.Radius) <= S.FireBand and rel.Y <= 16 then
							c.Burn(char, S.FireDamage)
						end
					end
				end
				return true
			end)
			actor:SetAttribute("P5FireRings", (actor:GetAttribute("P5FireRings") or 0) + 1)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
