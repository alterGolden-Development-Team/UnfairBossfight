local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local S = require(script.Parent.Style)
local Placement = require(B.Encounter.ArenaPlacement)
local Time = require(B.Mechanics.Time.TimeEffectController)
local Status = require(B.Combat.StatusEffectService)
local Dash = require(B.Players.R6DashService)
local Players = game:GetService("Players")

local CHARGE = { RightShoulder = { -40, 0, 30 }, RightElbow = { 80, 0, 0 }, LeftShoulder = { 60, 0, -20 }, LeftElbow = { 30, 0, 0 },
	Waist = { 10, 45, 0 }, RightHip = { -35, 0, 0 }, RightKnee = { 50, 0, 0 }, LeftHip = { -20, 0, 0 }, LeftKnee = { 30, 0, 0 } }
local LUNGE = { RightShoulder = { 95, 0, -5 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { -30, 0, -40 }, Waist = { 20, -30, 0 },
	RightHip = { -40, 0, 0 }, LeftHip = { 30, 0, 0 } }

local function segmentDistance(point, a, b)
	local d = b - a
	local t = d:Dot(d) > 0.0001 and math.clamp((point - a):Dot(d) / d:Dot(d), 0, 1) or 0
	return (point - (a + d * t)).Magnitude
end

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local held = {}

	local function releaseAll()
		for char, record in pairs(held) do
			held[char] = nil
			Status.SetLocked(record.Player, record.Lock, false)
			record.Lock.closed = true
			if record.Root.Parent then
				Time.SetAnchored(record.Root, record.Anchored)
			end
		end
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
			core.PoseAngles(CHARGE, 0.12)
			actor:SetAttribute("AttackState", "Scarlet River")
			local charge = c.Tell(S.Charge)
			pcall(Audio.Emit, actor, "ThrustCharge", c.Root)
			c.Send("RiverCharge", { Time = charge, Hold = charge + S.DashTime + S.Hold + 0.3 })
			if not c.Wait(charge) then
				return false
			end
			local root = c.Root
			local from = root.Position
			local aim = core.Alive(target) and target.HumanoidRootPart.Position or from + root.CFrame.LookVector
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
			core.PoseAngles(LUNGE, 0.04)
			pcall(Audio.Emit, actor, "ThrustBurst", root)
			c.Send("RiverLunge", { From = from, To = goal, Time = S.DashTime })
			local last = from
			if not c.Over(S.DashTime, function(alpha)
				local p = from:Lerp(goal, 1 - (1 - alpha) ^ 2)
				root.CFrame = CFrame.lookAt(p, p + dir)
				root.AssemblyLinearVelocity = Vector3.zero
				for _, char in ipairs(c.Targets()) do
					local r = char.HumanoidRootPart
					if not held[char] and segmentDistance(r.Position, last, p) <= S.Radius and core.CanHit(char, p) then
						local player = Players:GetPlayerFromCharacter(char)
						held[char] = { Player = player, Root = r, Anchored = r.Anchored, Lock = { TransitionControl = true }, Y = r.Position.Y }
						pcall(Dash.Cancel, player, "Scarlet River")
						Status.SetLocked(player, held[char].Lock, true)
						Time.SetAnchored(r, true)
						c.Send("RiverCatch", { Victim = char, Time = S.DashTime + S.Hold })
					end
				end
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
			local caught = {}
			for char in pairs(held) do
				caught[#caught + 1] = char
			end
			releaseAll()
			for _, char in ipairs(caught) do
				if core.Alive(char) then
					pcall(Audio.Emit, actor, "ThrustStab", char.HumanoidRootPart)
					c.Send("RiverPierce", { Pos = char.HumanoidRootPart.Position, Dir = dir })
					c.Hit(char, S.PierceDamage, root.Position, { BreaksBlock = true, Knock = { Direction = dir, Speed = S.ThrowSpeed,
						Lift = S.ThrowLift, Duration = 0.35, Sustain = 0.08, AllowPlayerControl = true, ContainsArena = true } })
				end
			end
			if #caught > 0 then
				core.ScreenEffect("Shake", { Origin = root.Position, Radius = 100, Intensity = 0.7, Duration = 0.25 })
			end
			actor:SetAttribute("P5ScarletRivers", (actor:GetAttribute("P5ScarletRivers") or 0) + 1)
			return c.Wait(0.1)
		end)
		releaseAll()
		if not ok then
			warn("[P5ScarletRiver] " .. tostring(result))
			return false
		end
		return result
	end
	function api.Dispose()
		releaseAll()
	end
	return api
end
