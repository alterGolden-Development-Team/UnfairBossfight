local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local Effects = require(B.Combat.EffectService)
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
			actor:SetAttribute("AttackState", "Plasma Ball")
			core.Face(target)
			core.PoseAngles(CALL, 0.12)
			local n = c.Count(S.Balls)
			local balls = {}
			 -- every ball rolls in one background cast, so he can move on after the last throw
			local cast = Effects.NewCast(actor, "P5PlasmaBalls", n * (S.Tell + S.Every) + S.Range / S.Speed + 1)
			cast.PersistsThroughEmitterStun = true
			cast:Step(function()
				if actor:GetAttribute("Phase") ~= 5 then
					cast:Dispose()
					return false
				end
				local now = os.clock()
				local live = false
				for i, b in ipairs(balls) do
					local dist = math.min(S.Speed * (now - b.At), S.Range)
					if dist < S.Range then live = true end
					local radius = (S.Size0 + (S.Size1 - S.Size0) * dist / S.Range) / 2
					local p = b.From + b.Dir * dist
					for _, char in ipairs(c.Targets()) do
						 -- tick damage: every S.Tick seconds while they are inside this ball
						local key = char.Name .. "#" .. i
						if not b.Hit[key] or now >= b.Hit[key] then
							local rel = char.HumanoidRootPart.Position - p
							if dist < S.Range and (rel * FLAT).Magnitude <= radius + 1.5 and math.abs(rel.Y) <= radius + 3 then
								b.Hit[key] = now + S.Tick
								c.Hit(char, S.TickDamage, p)
							end
						end
					end
				end
				if not live and #balls >= n then
					cast:Dispose()
					return false
				end
				return true
			end)
			local spin = math.random() * math.pi * 2
			local aimed = 0
			for i = 1, n do
				local origin = c.Ground(c.Root.Position)
				local dir
				local targets = c.Targets()
				if aimed < S.Aimed and targets[aimed + 1] then
					aimed += 1
					dir = flat(targets[aimed].HumanoidRootPart.Position - origin)
				end
				if not dir then
					local a = spin + i * math.pi * 2 / n + (math.random() - 0.5) * 0.7
					dir = Vector3.new(math.cos(a), 0, math.sin(a))
				end
				c.Root.CFrame = CFrame.lookAt(c.Root.Position, c.Root.Position + dir)
				local tell = math.max(0.2, c.Tell(S.Tell))
				c.Fx("P5Ascend", "PlasmaArrows", { Origin = origin, Dirs = { dir }, Time = tell, Length = 40 })
				core.PoseAngles(CALL, 0.08)
				if not c.Wait(tell) then return false end
				core.PoseAngles(THROW, 0.04)
				local from = origin + UP * S.Height
				c.Fx("P5Ascend", "PlasmaBalls", { Origin = from, Dirs = { dir }, Speed = S.Speed, Range = S.Range, Size0 = S.Size0, Size1 = S.Size1 })
				sound("RangedLaunch")
				balls[#balls + 1] = { From = from, Dir = dir, At = os.clock(), Hit = {} }
				if not c.Wait(S.Every) then return false end
			end
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
