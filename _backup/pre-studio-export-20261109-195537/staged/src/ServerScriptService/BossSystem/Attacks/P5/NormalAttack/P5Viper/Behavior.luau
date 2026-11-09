local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local S = require(script.Parent.Style)
local Placement = require(B.Encounter.ArenaPlacement)
local Time = require(B.Mechanics.Time.TimeEffectController)
local Status = require(B.Combat.StatusEffectService)
local Dash = require(B.Players.R6DashService)
local Players = game:GetService("Players")

local SPREAD = { RightShoulder = { 15, 0, 88 }, RightElbow = { 10, 0, 0 }, LeftShoulder = { 15, 0, -88 }, LeftElbow = { 10, 0, 0 },
	Waist = { -10, 0, 0 } }
local STRIKE = { RightShoulder = { 92, 0, -6 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 88, 0, 6 }, LeftElbow = { 0, 0, 0 },
	Waist = { 18, 0, 0 }, RightHip = { -30, 0, 0 }, LeftHip = { 25, 0, 0 } }

local function segmentDistance(point, a, b)
	local d = b - a
	local t = d:Dot(d) > 0.0001 and math.clamp((point - a):Dot(d) / d:Dot(d), 0, 1) or 0
	return (point - (a + d * t)).Magnitude
end

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local held = {}  -- the caught: character -> how to let them go

	local function release(char)
		local record = held[char]
		if not record then
			return
		end
		held[char] = nil
		Status.SetLocked(record.Player, record.Lock, false)
		record.Lock.closed = true
		if record.Root.Parent then
			Time.SetAnchored(record.Root, record.Anchored)
		end
	end
	local function releaseAll()
		for char in pairs(held) do
			release(char)
		end
	end
	 -- where the strike goes: straight at them and on past, stopped by walls and the arena edge
	local function plan(target)
		local root = c.Root
		local from = root.Position
		local aim = target.HumanoidRootPart.Position
		local flat = Vector3.new(aim.X - from.X, 0, aim.Z - from.Z)
		local dir = flat.Magnitude > 0.1 and flat.Unit or (root.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
		local length = S.Distance
		local wall = workspace:Raycast(from, dir * length, core.Params())
		if wall then
			length = math.max(wall.Distance - 3, 2)
		end
		local goal = from + dir * length
		local frame = Placement.Validate(actor, CFrame.lookAt(goal, goal + dir), { Margin = 6 })
		goal = frame and Vector3.new(frame.X, from.Y, frame.Z) or goal
		return from, goal, dir
	end

	function api.CanUse(target)
		local r = target and target:FindFirstChild("HumanoidRootPart")
		return c.CanStart(target) and r ~= nil and (r.Position - c.Root.Position).Magnitude <= S.NearRange
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local ok, result = pcall(core.Perform, target, S.Name, function()
			core.Face(target)
			core.PoseAngles(SPREAD, 0.12)
			actor:SetAttribute("AttackState", "Viper: coiled")
			local windup = c.Tell(S.Windup)
			 -- the warning: the strike's lane lights up and follows his aim until the last moment
			local from, goal, dir = plan(target)
			c.Send("ViperSpread", { Time = windup })
			c.Send("ViperTell", { From = from, To = goal, Width = S.Radius, Time = windup })
			for _, char in ipairs(c.Targets()) do
				if segmentDistance(char.HumanoidRootPart.Position, from, goal) <= S.Radius + 8 then
					c.Warn(char, "Hold", windup + S.DashTime)  -- Hold Deflect: the fangs turn away
				end
			end
			if not c.Wait(windup) then
				return false
			end
			local root = c.Root
			core.PoseAngles(STRIKE, 0.04)
			actor:SetAttribute("AttackState", "Viper: the strike")
			c.Send("ViperThrust", { From = from, To = goal, Time = S.DashTime })
			local last = from
			if not c.Over(S.DashTime, function(alpha)
				local p = from:Lerp(goal, 1 - (1 - alpha) ^ 2)
				root.CFrame = CFrame.lookAt(p, p + dir)
				root.AssemblyLinearVelocity = Vector3.zero
				for _, char in ipairs(c.Targets()) do
					local r = char.HumanoidRootPart
					if not held[char] and segmentDistance(r.Position, last, p) <= S.Radius and core.CanHit(char, p)
						and not c.Deflected(char, "Hold") then
						local player = Players:GetPlayerFromCharacter(char)
						held[char] = { Player = player, Root = r, Anchored = r.Anchored, Lock = { TransitionControl = true }, Y = r.Position.Y }
						pcall(Dash.Cancel, player, "Viper drag")
						Status.SetLocked(player, held[char].Lock, true)
						Time.SetAnchored(r, true)
						c.Send("ViperCatch", { Victim = char })
					end
				end
				 -- the caught ride on the fangs, just ahead of him
				for _, record in pairs(held) do
					if record.Root.Parent then
						local at = Vector3.new(p.X, record.Y, p.Z) + dir * S.Carry
						record.Root.CFrame = CFrame.lookAt(at, Vector3.new(p.X, record.Y, p.Z))
					end
				end
				last = p
			end) then
				return false
			end
			if next(held) and not c.Wait(S.Hold) then
				return false
			end
			 -- the fangs close: everyone dragged is hurt and thrown on ahead
			local caught = {}
			for char in pairs(held) do
				caught[#caught + 1] = char
			end
			releaseAll()
			for _, char in ipairs(caught) do
				if core.Alive(char) then
					c.Send("ViperBite", { Pos = char.HumanoidRootPart.Position })
					c.Hit(char, S.Damage, root.Position, { BreaksBlock = true, Knock = { Direction = dir, Speed = S.ThrowSpeed,
						Lift = S.ThrowLift, Duration = 0.35, Sustain = 0.08, AllowPlayerControl = true, ContainsArena = true } })
				end
			end
			if #caught > 0 then
				core.ScreenEffect("Shake", { Origin = root.Position, Radius = 90, Intensity = 0.5, Duration = 0.2 })
			end
			actor:SetAttribute("P5Vipers", (actor:GetAttribute("P5Vipers") or 0) + 1)
			return c.Wait(0.1)
		end)
		releaseAll()
		if not ok then
			warn("[P5Viper] " .. tostring(result))
			return false
		end
		return result
	end
	function api.Dispose()
		releaseAll()
	end
	return api
end
