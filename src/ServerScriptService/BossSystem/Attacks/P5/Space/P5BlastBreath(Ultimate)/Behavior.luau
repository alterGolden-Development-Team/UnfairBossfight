local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Encounter = require(B.Players.PlayerEncounter)
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
local BREATH = { Waist = { 20, 0, 0 }, RightShoulder = { 60, 0, 60 }, LeftShoulder = { 60, 0, -60 }, RightHip = { -30, 0, 0 }, RightKnee = { 40, 0, 0 } }
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local function sound(name, at) pcall(Audio.Emit, actor, name, at or c.Root) end
	 -- his root's height over the floor, so a move to a floor point keeps his feet on it
	local function lift() return c.Root.Position.Y - c.Ground(c.Root.Position).Y end
	api.IsUltimate = true
	api.UltimatePhase = 5
	 -- owed once by P5ModeService when the Space shield breaks; it doesn't wait on the ultimate timer
	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "Blast Breath")
			actor:SetAttribute("P5LastStand", nil)  -- paid (P5ModeService.LastStand leaves it owed until now)
			pcall(Encounter.Say, S.Line, nil, { Duration = 2.8 })
			local center = c.Center()
			c.Blink(CFrame.new(center + UP * lift()))
			core.Face(target)
			core.PoseAngles(CALL, 0.2)
			local sigil = c.Tell(S.Sigil)
			c.Fx("P5Ascend", "Sigil", { Time = sigil, Pos = center })
			sound("RoyalFinalCharge")
			if not c.Wait(sigil) then return false end
			core.PoseAngles(BREATH, 0.08)
			c.Fx("P5Ascend", "Breath", { Time = S.Breath, Range = S.Range, Base = S.Base, Spread = S.Spread })
			sound("RoyalFinalRelease")
			local tan = math.tan(math.rad(S.Spread))
			local ground = c.Ground(center)
			local t, nextTick, nextWave, wall = 0, 0, 0.4, true
			if not c.Over(S.Breath, function(_, dt)
				t += dt
				local root = c.Root
				 -- turning after his target, slower than they can run round him
				if not core.Alive(target) then target = c.RandomTarget() or target end
				if target and core.Alive(target) then
					local want = flat(target.HumanoidRootPart.Position - root.Position)
					local have = flat(root.CFrame.LookVector)
					if want and have then
						local diff = math.atan2(have:Cross(want).Y, have:Dot(want))
						local step = math.clamp(diff, -S.Turn * dt, S.Turn * dt)
						root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, step, 0) * root.CFrame.Rotation
					end
				end
				root.AssemblyLinearVelocity = Vector3.zero
				if t >= nextTick then
					nextTick += S.Tick
					local frame = root.CFrame
					for _, char in ipairs(c.Targets()) do
						local p = frame:PointToObjectSpace(char.HumanoidRootPart.Position)
						local along = -p.Z
						local half = S.Base + math.max(along, 0) * tan
						if along > 0 and along <= S.Range and math.abs(p.X) <= half and math.abs(p.Y) <= half + 4 then
							c.Hit(char, S.TickDamage, frame.Position)
						end
					end
				end
				if t >= nextWave then
					nextWave += S.WaveEvery
					if wall then
						c.WallWave(ground, { Speed = S.WallSpeed, Range = S.WaveRange, Height = S.WallHeight, Width = 8, Damage = S.WallDamage,
							Knock = knock(nil, 34, 14) })
					else
						c.Shockwave(ground, { Speed = S.GroundSpeed, Range = S.WaveRange, Width = 3, Height = 4, Damage = S.GroundDamage,
							Knock = knock(nil, 26, 12) })
					end
					wall = not wall
				end
			end) then return false end
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
