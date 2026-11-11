--[[
 P5MatterBeam - the Golden-matter Beam and the Double Golden-matter Beam (Attacks/P5/NormalAttack; each Behavior
 passes its own Style). He gathers golden matter in his palm for Charge seconds, pulling everyone within PullRange
 toward him (a LinearVelocity in the ground plane with a limited force, so they can fight it), while a gold fan on the
 floor shows each beam's sweep (a full circle at Sweep 360). Then Beams beams (Spread degrees apart) fire Range studs out
 and sweep clockwise through Sweep degrees in SweepTime, hold for Pause, and sweep back. A beam about to pass over
 someone puts up their TAP shield; anyone it passes through without deflecting is burned for TickDamage every Tick seconds while the beam is on them (the pull holds on to them for the whole sweep).
 VFXEngine.Effects.P5Arsenal MatterCharge / MatterBeam draw it on the same timeline.
]]
local B = script:FindFirstAncestor("BossSystem")
local Strike = require(B.Attacks.Shared.P5StrikeCore)
local Effects = require(B.Combat.EffectService)
local Audio = require(B.Presentation.CombatAudio)
local Net = require(game.ReplicatedStorage.VFXEngine.Net)
local FLAT = Vector3.new(1, 0, 1)
local CHARGE = { RightShoulder = { 95, 0, -20 }, RightElbow = { 25, 0, 0 }, RightWrist = { -60, 0, 0 }, LeftShoulder = { 40, 0, -30 },
	LeftElbow = { 60, 0, 0 }, Waist = { 0, -30, 0 }, RightHip = { -25, 0, 0 }, RightKnee = { 35, 0, 0 }, LeftHip = { 15, 0, 0 } }
local FIRE = { RightShoulder = { 90, 0, -5 }, RightElbow = { 0, 0, 0 }, RightWrist = { -80, 0, 0 }, LeftShoulder = { 20, 0, -40 },
	LeftElbow = { 70, 0, 0 }, Waist = { -8, -15, 0 } }

local function look(a)
	return CFrame.Angles(0, a, 0).LookVector
end
local function angleOf(v)
	return math.atan2(-v.X, -v.Z)
end
 -- does a beam turning from angle a1 to a2 (a small step) pass over angle theta?
local function crosses(a1, a2, theta)
	local step = a2 - a1
	local d = (theta - a1 + math.pi) % (2 * math.pi) - math.pi
	return step ~= 0 and math.sign(d) == math.sign(step) and math.abs(d) <= math.abs(step)
end
local function smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
 -- where the beam points `t` seconds after it fires (the client draws the same curve)
local function angleAt(t, start, sweep, S)
	if t <= S.SweepTime then
		return start + sweep * smooth(t / S.SweepTime), 1
	elseif t <= S.SweepTime + S.Pause then
		return start + sweep, 0
	end
	return start + sweep * (1 - smooth((t - S.SweepTime - S.Pause) / S.SweepTime)), 2
end

return function(actor, S)
	local c = Strike.Context(actor, S.Name)
	local core = c.Core
	local api = { Cooldown = S.Cooldown }
	local function send(stage, data)
		data.Boss = actor
		Net.Send("P5Arsenal", stage, data)
	end
	 -- close range only (EncounterConfig.P5BeamUseRange, or the Style's UseRange): far away he doesn't pick the beams, and
	 -- Combat/P5CloseIn blinks him in beside a far target so they come up
	function api.CanUse(target)
		if not c.CanStart(target) then
			return false
		end
		local range = S.UseRange or require(game.ReplicatedStorage.BossShared.Config.EncounterConfig).P5BeamUseRange or 38
		return ((target.HumanoidRootPart.Position - c.Root.Position) * Vector3.new(1, 0, 1)).Magnitude <= range
	end
	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local pull
		local result = core.Perform(target, S.Name, function()
			core.Face(target)
			core.PoseAngles(CHARGE, 0.15)
			actor:SetAttribute("AttackState", S.Label .. ": charging")
			local root = c.Root
			local aimDir = (target.HumanoidRootPart.Position - root.Position) * FLAT
			aimDir = aimDir.Magnitude > 0.1 and aimDir.Unit or (root.CFrame.LookVector * FLAT).Unit
			local aim = math.atan2(-aimDir.X, -aimDir.Z)
			local half = math.rad(S.Sweep) / 2
			local start, sweep = aim + half, -2 * half  -- clockwise; a full circle starts behind him, so it reaches them halfway
			local spread = math.rad(S.Spread)
			local offsets = {}
			for i = 1, S.Beams do
				offsets[i] = S.Beams > 1 and spread * ((i - 1) / (S.Beams - 1) - 0.5) or 0
			end
			local charge = math.max(0.9, c.Tell(S.Charge))
			local ground = c.Ground(root.Position)
			send("MatterCharge", { Origin = ground, Start = start, Sweep = sweep, Offsets = offsets, Range = S.Range, Width = S.Width,
				Time = charge })
			pcall(Audio.Emit, actor, "CrescentCharge", root)
			 -- the pull: everyone in reach drifts toward him while he charges
			pull = Effects.NewCast(actor, S.Name .. "Pull", charge + S.SweepTime * 2 + S.Pause + 1)
			local records = {}
			 -- the pull never lets go: it runs through the charge AND the whole spinning sweep, until the beam is off
			local function pullStep()
				local center = root.Position
				for _, char in ipairs(c.Targets()) do
					local r = char.HumanoidRootPart
					local rec = records[char]
					if not rec then
						local a = pull:Add(Instance.new("Attachment"))
						a.Name = "MatterPullAttachment"
						a.Parent = r
						local f = pull:Add(Instance.new("LinearVelocity"))
						f.Name = "MatterPull" f.Attachment0 = a f.RelativeTo = Enum.ActuatorRelativeTo.World
						f.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
						f.PrimaryTangentAxis = Vector3.xAxis f.SecondaryTangentAxis = Vector3.zAxis
						f.ForceLimitsEnabled = true f.ForceLimitMode = Enum.ForceLimitMode.PerAxis
						f.MaxPlanarAxesForce = Vector2.zero f.PlaneVelocity = Vector2.zero f.Enabled = false f.Parent = r
						rec = { Root = r, Force = f }
						records[char] = rec
					end
					local d = (center - r.Position) * FLAT
					local mass = r.AssemblyMass
					if d.Magnitude < 9 or d.Magnitude > S.PullRange or mass <= 0 then
						rec.Force.Enabled = false
					else
						local v = d.Unit * S.PullSpeed
						rec.Force.PlaneVelocity = Vector2.new(v.X, v.Z)
						rec.Force.MaxPlanarAxesForce = Vector2.one * (mass * S.PullAccel)
						rec.Force.Enabled = true
					end
				end
			end
			if not c.Over(charge, pullStep) then
				return false
			end
			core.PoseAngles(FIRE, 0.05)
			actor:SetAttribute("AttackState", S.Label .. "!")
			send("MatterBeam", { Origin = ground, Start = start, Sweep = sweep, Offsets = offsets, SweepTime = S.SweepTime, Pause = S.Pause,
				Range = S.Range, Width = S.Width })
			pcall(Audio.Emit, actor, "CrescentRelease", root)
			core.ScreenEffect("Shake", { Origin = ground, Radius = 160, Intensity = 0.7, Duration = 0.3 })
			local from = root.Position
			local hits, cued = {}, {}
			local t = 0
			local total = S.SweepTime * 2 + S.Pause
			local lead = 0.5
			local swept = c.Over(S.SweepTime * 2 + S.Pause, function(_, dt)
				t += dt
				local base, pass = angleAt(t, start, sweep, S)
				local face = look(base)
				root.CFrame = CFrame.lookAt(from, from + face)
				root.AssemblyLinearVelocity = Vector3.zero
				pullStep()
				 -- the pause at the end of a sweep is still the beam: it keeps burning whoever is in it (same pass as the sweep before)
				local live = pass == 0 and 1 or pass
				for _, char in ipairs(c.Targets()) do
					local key = char.Name .. live
					local rel = (char.HumanoidRootPart.Position - from)
					local flat = rel * FLAT
					if hits[key] ~= false and flat.Magnitude <= S.Range + 1 and rel.Y <= 12 then
						 -- the TAP shield, just before a beam comes round onto them
						if not cued[key] then
							local theta = angleOf(flat)
							local prev = base
							for step = 1, 10 do
								local at = math.min(t + step * lead / 10, total)
								local nextAngle, nextPass = angleAt(at, start, sweep, S)
								if nextPass == pass then
									for _, off in ipairs(offsets) do
										if crosses(prev + off, nextAngle + off, theta) then
											cued[key] = true
											c.Warn(char, "Tap", at - t + 0.12)
											break
										end
									end
								end
								if cued[key] then break end
								prev = nextAngle
							end
						end
						for _, off in ipairs(offsets) do
							local dir = look(base + off)
							local along = flat:Dot(dir)
							if along > -1 and (flat - dir * along).Magnitude <= S.Width then
								 -- tick damage: the first touch of a pass can be turned away (TAP, immune for the rest of that pass); if
								 -- not, the beam burns them every Tick seconds for as long as they stand in it
								if hits[key] == nil then
									if c.Deflected(char, "Tap") then hits[key] = false else hits[key] = 0 end
								end
								if hits[key] ~= false and t >= hits[key] then
									hits[key] = t + S.Tick
									c.Burn(char, S.TickDamage)
								end
								break
							end
						end
					end
				end
			end)
			if pull then
				pull:Dispose()
				pull = nil
			end
			return swept and c.Wait(0.3)
		end)
		if pull then
			pull:Dispose()
		end
		return result
	end
	function api.Dispose() end
	return api
end
