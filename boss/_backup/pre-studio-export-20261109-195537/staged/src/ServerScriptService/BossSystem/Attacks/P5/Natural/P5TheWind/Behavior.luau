local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Deflect = require(B.Combat.DeflectService)
local Effects = require(B.Combat.EffectService)
local Encounter = require(B.Players.PlayerEncounter)
local Placement = require(B.Encounter.ArenaPlacement)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local S = require(script.Parent.Style)
local FLAT = Vector3.new(1, 0, 1)
local UP = Vector3.yAxis
local CALL = { RightShoulder = { 160, 0, 30 }, LeftShoulder = { 160, 0, -30 }, Waist = { -15, 0, 0 } }
local CROUCH = { Waist = { 35, 0, 0 }, RightHip = { -70, 0, 0 }, RightKnee = { 90, 0, 0 }, LeftHip = { -70, 0, 0 }, LeftKnee = { 90, 0, 0 },
	RightShoulder = { 20, 0, 30 }, LeftShoulder = { 20, 0, -30 } }
local TUCK = { Waist = { 60, 0, 0 }, RightHip = { -100, 0, 0 }, RightKnee = { 120, 0, 0 }, LeftHip = { -100, 0, 0 }, LeftKnee = { 120, 0, 0 },
	RightShoulder = { 60, 0, 0 }, LeftShoulder = { 60, 0, 0 } }
local KICK = { RightHip = { 95, 0, 0 }, RightKnee = { 0, 0, 0 }, LeftHip = { -30, 0, 0 }, LeftKnee = { 60, 0, 0 }, LeftShoulder = { 40, 0, -60 },
	Waist = { -30, 0, 0 } }
local SLAM = { RightShoulder = { 30, 0, 0 }, LeftShoulder = { 30, 0, 0 }, Waist = { 40, 0, 0 }, RightHip = { -50, 0, 0 }, RightKnee = { 70, 0, 0 },
	LeftHip = { -30, 0, 0 }, LeftKnee = { 50, 0, 0 } }
local THROW = { RightShoulder = { 150, 0, 0 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 40, 0, -40 }, Waist = { 25, 0, 0 } }
local STOMP_A = { RightHip = { 60, 0, 0 }, RightKnee = { 20, 0, 0 }, Waist = { 15, 0, 0 }, RightShoulder = { 30, 0, 50 }, LeftShoulder = { 30, 0, -50 } }
local STOMP_B = { LeftHip = { 60, 0, 0 }, LeftKnee = { 20, 0, 0 }, Waist = { 15, 0, 0 }, RightShoulder = { 30, 0, 50 }, LeftShoulder = { 30, 0, -50 } }
local function flat(v) v = v * FLAT return v.Magnitude > 0.1 and v.Unit or nil end
local function smooth(x) x = math.clamp(x, 0, 1) return x * x * (3 - 2 * x) end
local function knock(dir, speed, lift)
	return { Direction = dir, Speed = speed or 36, Lift = lift or 14, Duration = 0.3, Sustain = 0.07, AllowPlayerControl = false, ContainsArena = true }
end
local function holdLead() return (Config.DeflectHoldTime or 0.2) + 0.45 end
local RISE = { RightShoulder = { 170, 0, 10 }, RightElbow = { 0, 0, 0 }, Waist = { -20, 0, 0 } }
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
			actor:SetAttribute("AttackState", "The Wind")
			core.PoseAngles(CALL, 0.12)
			c.Fx("P5Ascend", "WindPull", { Time = S.Pull, Range = 90 })
			sound("TornadoBuild")
			 -- everyone is snapped in to him at once (within S.PullTime), before the cut can come
			local pull = c.Pull(function() return c.Root.Position end, { Range = S.PullRange, Distance = S.PullDistance, Time = S.PullTime, Once = true })
			local ok = c.Over(S.Pull, function(_, dt)
				if core.Alive(target) then core.Face(target) end
				pull.Step(dt or 0)
			end)
			if not ok then return false end
			if not core.Alive(target) then target = c.RandomTarget() end
			if target then core.Face(target) end
			core.PoseAngles(RISE, 0.06)
			local base = c.Ground(c.Root.Position)
			local lane = CFrame.lookAt(base, base + (flat(c.Root.CFrame.LookVector) or Vector3.zAxis))
			local tell = S.Tell  -- he charges this long (0.5s) after the pull, then cuts
			c.Fx("P5Ascend", "Lane", { Frame = lane, Length = S.Length, Width = S.HalfWidth, Time = tell })
			for _, char in ipairs(c.Targets()) do
				local p = lane:PointToObjectSpace(char.HumanoidRootPart.Position)
				if math.abs(p.X) <= S.HalfWidth + 4 and -p.Z >= -2 and -p.Z <= S.Length then
					c.Warn(char, "Tap", tell + math.max(-p.Z, 0) / S.Speed + 0.05)
				end
			end
			if not c.Wait(tell) then return false end
			core.PoseAngles(SLAM, 0.04)
			c.Fx("P5Ascend", "WindSlash", { Frame = lane, Length = S.Length, Speed = S.Speed, Width = S.HalfWidth })
			sound("TornadoCut")
			local hit, front = {}, 0
			if not c.Over(S.Length / S.Speed, function(_, dt)
				local last = front
				front = math.min(front + S.Speed * dt, S.Length)
				for _, char in ipairs(c.Targets()) do
					if not hit[char] then
						local p = lane:PointToObjectSpace(char.HumanoidRootPart.Position)
						if math.abs(p.X) <= S.HalfWidth and -p.Z >= last - 3 and -p.Z <= front + 1 and p.Y <= 14 then
							hit[char] = true
							if not c.Deflected(char, "Tap") then
								c.Hit(char, S.Damage, char.HumanoidRootPart.Position,
									{ Knock = knock(lane.RightVector * (p.X >= 0 and 1 or -1), 40, 14) })
							end
						end
					end
				end
			end) then return false end
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
