local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local S = require(script.Parent.Style)

local RAISE = { RightShoulder = { 170, 0, -25 }, RightElbow = { 20, 0, 0 }, LeftShoulder = { 60, 0, 40 }, Waist = { -12, -25, 0 } }
local RIP = { RightShoulder = { 40, 0, 40 }, RightElbow = { 5, 0, 0 }, LeftShoulder = { -20, 0, -20 }, Waist = { 18, 30, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	local function aimAt(target)
		local origin = (core.Root.CFrame * CFrame.new(0, S.Height, -3)).Position
		local aim = target.HumanoidRootPart.Position
		local flat = Vector3.new(aim.X - origin.X, 0, aim.Z - origin.Z)
		return flat.Magnitude > 0.1 and CFrame.lookAt(origin, origin + flat) or CFrame.new(origin) * core.Root.CFrame.Rotation
	end

	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Claw Forward: drawing")
			core.Face(target)
			core.Melee.Pose("Windup", 0.15)
			c.Send("ClawTell", { Time = S.Windup })
			if not c.Wait(S.Windup) then
				return false
			end
			for swing = 1, S.Swings do
				if not core.Alive(target) then
					target = core.Melee.GetTarget()
				end
				if not target or not c.Valid() then
					return false
				end
				core.Face(target)
				core.Melee.Pose(swing % 2 == 1 and "Slash1" or "Slash2", 0.07)
				actor:SetAttribute("AttackState", "Claw Forward: " .. swing)
				c.FireClaw(aimAt(target), { Speed = S.Speed, Range = S.Range, Width = S.Width, Spread = S.Spread,
					Roll = math.rad(S.Roll) * (swing % 2 == 1 and 1 or -1), Damage = S.Damage,
					HitHalfWidth = S.HitHalfWidth, HitHeight = S.HitHeight, Deflect = "Tap" })
				if not c.Wait(S.Gap) then
					return false
				end
			end
			 -- the finisher: he winds the whole arm back and rips one giant claw down the field
			if not core.Alive(target) then
				target = core.Melee.GetTarget()
			end
			if not target then
				return true
			end
			core.Face(target)
			core.PoseAngles(RAISE, S.FinalWindup * 0.8)
			actor:SetAttribute("AttackState", "Claw Forward: the final claw")
			c.Send("ClawTell", { Time = S.FinalWindup, Final = true })
			if not c.Wait(S.FinalWindup) then
				return false
			end
			core.Face(target)
			core.PoseAngles(RIP, 0.06)
			core.ScreenEffect("Shake", { Origin = core.Root.Position, Radius = 160, Intensity = 0.6, Duration = 0.3 })
			c.FireClaw(aimAt(target), { Speed = S.FinalSpeed, Range = S.Range, Width = S.FinalWidth, Spread = S.FinalSpread,
				Count = S.FinalCount, Roll = math.rad(S.Roll), Damage = S.FinalDamage, HitHalfWidth = S.FinalHalfWidth,
				HitHeight = S.FinalHeight, Final = true })
			actor:SetAttribute("P5ClawForwardSwings", (actor:GetAttribute("P5ClawForwardSwings") or 0) + S.Swings + 1)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
