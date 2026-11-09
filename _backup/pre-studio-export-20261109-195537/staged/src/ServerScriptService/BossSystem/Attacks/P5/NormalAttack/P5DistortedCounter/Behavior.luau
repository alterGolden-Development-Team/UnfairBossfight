local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Effects = require(B.Combat.EffectService)
local S = require(script.Parent.Style)
local Players = game:GetService("Players")

local GUARD = { RightShoulder = { 60, 0, 60 }, RightElbow = { 70, 0, 0 }, LeftShoulder = { 80, 0, -30 }, LeftElbow = { 40, 0, 0 }, Waist = { 0, 15, 0 } }
local ANSWER = { RightShoulder = { 90, 0, -5 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { -20, 0, -20 }, Waist = { 10, -15, 0 } }

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local stance

	 -- the answer: he turns on whoever struck and fires straight through them, even mid-attack
	local function answer(who)
		local player = Players:FindFirstChild(who)
		local char = player and player.Character
		if not char or not core.Alive(char) or not c.Valid() then
			return
		end
		actor:SetAttribute("P5Counters", (actor:GetAttribute("P5Counters") or 0) + 1)
		if not actor:GetAttribute("AttackInProgress") then
			core.Face(char)
			core.PoseAngles(ANSWER, 0.05)
		end
		c.Send("CounterCatch", {})
		task.wait(S.ShotDelay)
		if not core.Alive(char) or not c.Valid() then
			return
		end
		local origin = (core.Root.CFrame * CFrame.new(0, 1, -2.5)).Position
		c.Bolt(origin, char.HumanoidRootPart.Position - origin, { Speed = S.ShotSpeed, Range = S.ShotRange,
			Radius = S.ShotRadius, Damage = S.ShotDamage, Pierce = true, Look = "Pierce" })
		core.ScreenEffect("Shake", { Origin = origin, Radius = 90, Intensity = 0.4, Duration = 0.2 })
	end

	function api.CanUse(target)
		return c.CanStart(target) and not (stance and stance:Alive())
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(GUARD, 0.1)
			actor:SetAttribute("AttackState", "Distorted Counter")
			actor:SetAttribute("CounterCaughtBy", nil)
			actor:SetAttribute("CounterStanceUntil", workspace:GetServerTimeNow() + S.Stance)
			c.Send("CounterStance", { Time = S.Stance })
			 -- the stance outlives the cast: the circle follows him while he walks and fights on
			stance = Effects.NewCast(actor, "P5CounterStance", S.Stance + 0.5)
			stance.PersistsThroughEmitterStun = true
			stance:Step(function()
				local who = actor:GetAttribute("CounterCaughtBy")
				if who then
					actor:SetAttribute("CounterCaughtBy", nil)
					stance:Dispose()
					task.spawn(answer, who)
					return false
				end
				if not c.Valid() or workspace:GetServerTimeNow() >= (actor:GetAttribute("CounterStanceUntil") or 0) then
					actor:SetAttribute("CounterStanceUntil", 0)
					c.Send("CounterFade", {})
					stance:Dispose()
					return false
				end
				return true
			end)
			return c.Wait(S.Raise)
		end)
	end
	function api.Dispose()
		if stance then stance:Dispose() end
	end
	return api
end
