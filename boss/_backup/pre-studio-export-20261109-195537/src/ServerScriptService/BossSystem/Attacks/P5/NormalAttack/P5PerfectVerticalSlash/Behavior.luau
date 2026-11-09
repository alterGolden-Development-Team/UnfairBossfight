local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Audio = require(B.Presentation.CombatAudio)
local S = require(script.Parent.Style)
local Effects = require(B.Combat.EffectService)
local Runtime = require(B.Combat.CombatRuntime)

local HIGH = { RightShoulder = { 175, 0, 0 }, RightElbow = { 5, 0, 0 }, LeftShoulder = { 160, 0, 5 }, LeftElbow = { 20, 0, 0 },
	Waist = { -8, 0, 0 } }
local CHOP = { RightShoulder = { 40, 0, 0 }, RightElbow = { 0, 0, 0 }, LeftShoulder = { 35, 0, 5 }, LeftElbow = { 10, 0, 0 },
	Waist = { 30, 0, 0 }, RightHip = { -40, 0, 0 }, RightKnee = { 45, 0, 0 }, LeftHip = { 20, 0, 0 } }

local function segmentDistance(point, a, b)
	local d = b - a
	local t = d:Dot(d) > 0.0001 and math.clamp((point - a):Dot(d) / d:Dot(d), 0, 1) or 0
	return (point - (a + d * t)).Magnitude
end

return function(actor)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }

	function api.CanUse(target)
		return c.CanStart(target)
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		return core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(HIGH, 0.2)
			actor:SetAttribute("AttackState", "Perfect Vertical Slash")
			local stance = math.max(0.8, c.Tell(S.Stance))
			local lead = 0.7  -- the HOLD cue's time to fill
			c.Send("VerticalStance", { Time = stance })
			local warned = false
			if not c.Over(stance, function(alpha)
				if core.Alive(target) then core.Face(target) end
				if not warned and alpha * stance >= stance - lead then
					warned = true
					local look = c.Root.CFrame.LookVector * Vector3.new(1, 0, 1)
					for _, char in ipairs(c.Targets()) do
						local rel = char.HumanoidRootPart.Position - c.Root.Position
						if rel.Magnitude <= S.Range and (look.Magnitude < 0.01 or rel.Unit:Dot(look.Unit) > 0.6) then
							c.Warn(char, "Hold", lead + 0.15)
						end
					end
				end
			end) then
				return false
			end
			local ground = c.Ground(c.Root.Position)
			local look = c.Root.CFrame.LookVector * Vector3.new(1, 0, 1)
			look = look.Magnitude > 0.01 and look.Unit or Vector3.zAxis
			local lane = CFrame.lookAt(ground, ground + look)
			core.PoseAngles(CHOP, 0.04)
			pcall(Audio.Emit, actor, "NormalSwing", c.Root)
			c.Send("VerticalSwing", { Frame = lane })
			c.Send("VerticalSlash", { Frame = lane, Speed = S.Speed, Range = S.Range, Height = S.Height,
				FlameTime = (S.FireRange - S.BurstFirst) / S.BurstSpeed + S.FlameTime })
			core.ScreenEffect("Shake", { Origin = ground, Radius = 240, Intensity = 1.2, Duration = 0.35 })
			local started = os.clock()
			local hit, front = {}, 0
			if not c.Over(S.Range / S.Speed, function(_, dt)
				local back = front
				front = math.min(front + S.Speed * dt, S.Range)
				for _, char in ipairs(c.Targets()) do
					if not hit[char] then
						local p = lane:PointToObjectSpace(char.HumanoidRootPart.Position)
						if math.abs(p.X) <= S.HalfWidth + 1.5 and -p.Z >= back - 4 and -p.Z <= front + 3 and p.Y <= S.Height then
							hit[char] = true
							if c.Deflected(char, "Hold") then
								 -- turned away: thrown off to the side they stand on, clear of the slash and its fire
								local side = p.X >= 0 and lane.RightVector or -lane.RightVector
								if math.abs(p.X) < 0.5 then side = math.random() < 0.5 and lane.RightVector or -lane.RightVector end
								 -- the server takes the body for the throw: with player control the client keeps it and it barely moves
								pcall(Runtime.Knockback, actor, char, side, { Speed = S.DeflectPush, Lift = 10, Duration = 0.35, Sustain = 0.15,
									AllowPlayerControl = false, ContainsArena = true })
							else
								c.Hit(char, S.Damage, (lane * CFrame.new(0, 3, -front)).Position, { BreaksBlock = true })
							end
						end
					end
				end
			end) then
				return false
			end
			 -- the fire: a burst erupts every BurstGap studs down the line, each when the eruption front (BurstSpeed, from
			 -- the moment of the slash) reaches it; VFXEngine P5Strikes.VerticalBurst draws each one
			local columns = {}
			for dist = S.BurstFirst, S.FireRange, S.BurstGap do
				columns[#columns + 1] = { At = c.Ground(ground + look * dist), Time = dist / S.BurstSpeed }
			end
			local cast = Effects.NewCast(actor, "P5VerticalFlames", S.FireRange / S.BurstSpeed + S.FlameTime + 0.5)
			cast.PersistsThroughEmitterStun = true
			local tick = 0
			cast:Step(function(dt)
				local now = os.clock() - started
				if actor:GetAttribute("Phase") ~= 5 then
					cast:Dispose()
					return false
				end
				local live = false
				for _, col in ipairs(columns) do
					if not col.Up and now >= col.Time then
						col.Up = true
						c.Send("VerticalBurst", { Pos = col.At, Radius = S.BurstRadius, FlameTime = S.FlameTime })
						for _, char in ipairs(c.Targets()) do
							local p = char.HumanoidRootPart.Position
							if (Vector3.new(p.X, col.At.Y, p.Z) - col.At).Magnitude <= S.BurstRadius + 1 and p.Y - col.At.Y <= S.BurstHeight then
								c.Hit(char, S.BurstDamage, col.At)
							end
						end
					end
					if not col.Up or now < col.Time + S.FlameTime then
						live = true
					end
				end
				tick += dt
				if tick >= S.FlameTick then
					tick = 0
					for _, char in ipairs(c.Targets()) do
						local p = char.HumanoidRootPart.Position
						for _, col in ipairs(columns) do
							if col.Up and now < col.Time + S.FlameTime and p.Y - col.At.Y <= 14
								and (Vector3.new(p.X, col.At.Y, p.Z) - col.At).Magnitude <= S.BurstRadius then
								c.Burn(char, S.FlameDamage)
								break
							end
						end
					end
				end
				if not live then
					cast:Dispose()
					return false
				end
				return true
			end)
			actor:SetAttribute("P5VerticalSlashes", (actor:GetAttribute("P5VerticalSlashes") or 0) + 1)
			return c.Wait(0.1)
		end)
	end
	function api.Dispose() end
	return api
end
