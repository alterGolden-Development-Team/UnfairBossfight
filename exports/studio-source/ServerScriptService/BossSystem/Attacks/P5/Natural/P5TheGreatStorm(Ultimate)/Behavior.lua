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
return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local function sound(name, at) pcall(Audio.Emit, actor, name, at or c.Root) end
	 -- his root's height over the floor, so a move to a floor point keeps his feet on it
	local function lift() return c.Root.Position.Y - c.Ground(c.Root.Position).Y end
	api.IsUltimate = true
	api.UltimatePhase = 5
	 -- owed once by P5ModeService when the Natural shield breaks; it doesn't wait on the ultimate timer
	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			actor:SetAttribute("AttackState", "The Great Storm")
			actor:SetAttribute("P5LastStand", nil)  -- paid (P5ModeService.LastStand leaves it owed until now)
			pcall(Encounter.Say, S.Line, nil, { Duration = 2.8 })
			local center = c.Center()
			c.Blink(CFrame.new(center + UP * lift()))
			core.PoseAngles(CALL, 0.2)
			local from = c.Root.Position
			local top = from + UP * S.Height
			local tell = math.max(0.4, c.Tell(S.Tell))
			c.Fx("P5Ascend", "Storm", { Pos = center, Time = S.Rise + S.Storm + tell + S.Become + S.StarFall + 1.5, Rise = S.Rise })
			sound("RainSummon")
			if not c.Over(S.Rise, function(a)
				c.Root.CFrame = CFrame.new(from:Lerp(top, smooth(a))) * c.Root.CFrame.Rotation
				c.Root.AssemblyLinearVelocity = Vector3.zero
			end) then return false end
			local n = c.Count(S.Bolts)
			local every = S.Storm / n
			local pending, t, nextBolt = {}, 0, 0
			if not c.Over(S.Storm + tell, function(_, dt)
				t += dt
				c.Root.CFrame = CFrame.new(top) * c.Root.CFrame.Rotation
				c.Root.AssemblyLinearVelocity = Vector3.zero
				while t >= nextBolt and nextBolt < S.Storm do
					nextBolt += every
					local targets = c.Targets()
					local pos
					if #targets > 0 and math.random() < S.Near then
						local r = targets[math.random(#targets)].HumanoidRootPart
						local a, off = math.random() * math.pi * 2, math.random() * S.Spread
						pos = r.Position + r.AssemblyLinearVelocity * FLAT * S.Predict + Vector3.new(math.cos(a) * off, 0, math.sin(a) * off)
					else
						local a, d = math.random() * math.pi * 2, math.sqrt(math.random()) * S.ArenaRadius
						pos = center + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
					end
					pos = c.Ground(pos)
					pending[#pending + 1] = { Pos = pos, At = t + tell }
					c.Fx("P5Ascend", "Bolt", { Pos = pos, Tell = tell, Radius = S.Radius, Sky = center.Y + 140 })  -- the bolts start at the cloud roof, not up where he is
				end
				for i = #pending, 1, -1 do
					local b = pending[i]
					if t >= b.At then
						table.remove(pending, i)
						if i % 3 == 0 then pcall(Audio.Emit, actor, "JudgmentImpact", b.Pos) end
						for _, char in ipairs(c.Targets()) do
							local rel = char.HumanoidRootPart.Position - b.Pos
							if (rel * FLAT).Magnitude <= S.Radius and rel.Y <= 24 then
								c.Hit(char, S.Damage, b.Pos + UP * 2)
							end
						end
					end
				end
			end) then return false end
			 -- he becomes the star, then collapses onto the middle of the arena
			c.Fx("P5Ascend", "StarForm", { Pos = center, Become = S.Become, Time = S.StarFall, Radius = S.StarRadius })
			sound("RoyalFinalCharge")
			if not c.Over(S.Become, function()
				c.Root.CFrame = CFrame.new(top) * c.Root.CFrame.Rotation
				c.Root.AssemblyLinearVelocity = Vector3.zero
			end) then return false end
			sound("FallingDescend")
			if not c.Over(S.StarFall, function(a)
				c.Root.CFrame = CFrame.new(top:Lerp(from, a * a * a)) * c.Root.CFrame.Rotation
				c.Root.AssemblyLinearVelocity = Vector3.zero
			end) then return false end
			c.Root.CFrame = CFrame.new(from) * c.Root.CFrame.Rotation
			c.Fx("P5Strikes", "StarImpact", { Pos = center, Radius = S.StarRadius, Big = true })
			sound("FallingImpact", center)
			core.ScreenEffect("Shake", { Origin = center, Radius = 900, Intensity = 2.5, Duration = 0.8 })
			c.WallWave(center, { Speed = S.WallSpeed, Range = S.WallRange, Height = S.WallHeight, Width = 10, Lethal = S.Lives })
			core.PoseAngles(CROUCH, 0.06)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
