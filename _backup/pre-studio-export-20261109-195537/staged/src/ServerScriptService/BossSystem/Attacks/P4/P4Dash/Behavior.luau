 
 
 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local Style = require(script.Parent.Style)
local Effects = require(BossSystem.Combat.EffectService)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Golden = require(BossSystem.Attacks.Shared.P4GoldenFX)
local FX = Golden.FX
local Run = game:GetService("RunService")

local BODY = {
	"Head", "UpperTorso", "LowerTorso", "RightUpperArm", "LeftUpperArm", "RightLowerArm", "LeftLowerArm",
	"RightUpperLeg", "LeftUpperLeg", "RightLowerLeg", "LeftLowerLeg",
	"Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg",
}
local STAR_ORDER = { 1, 3, 5, 2, 4 }  

return function(actor)
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local ctx = Golden.Context(core)
	local api = { Cooldown = Style.Cooldown }
	local rng = Random.new()
	local current
	local function phaseOk()
		return math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4
	end
	function api.CanUse(target)
		return not current
			and phaseOk()
			and core.Active()
			and core.Alive(target)
			and not actor:GetAttribute("EncounterEnded")
			and not actor:GetAttribute("PhaseTransitionInProgress")
			and not Time.IsStopped(actor)
			and Placement.Contains(target.HumanoidRootPart.Position)
			and Placement.GetBounds() ~= nil
	end

	local function pickMode()
		local total = 0
		for _, w in Style.ModeWeights do  
			total += w
		end
		local roll = rng:NextNumber(0, total)
		for _, mode in ipairs({ "Regular", "DrawNear", "ErranticPhaser" }) do
			roll -= Style.ModeWeights[mode] or 0
			if roll <= 0 then
				return mode
			end
		end
		return "Regular"
	end

	 
	local function afterimage(cast, tint)
		for _, name in ipairs(BODY) do
			local body = actor:FindFirstChild(name)
			if body and body:IsA("BasePart") then
				local ghost = FX.Temp(ctx, cast, "P4DashAfterimage", body.CFrame, body.Size, tint, 0.35, Style.AfterimageLife + 0.05)
				FX.Tween(ghost, Style.AfterimageLife, { Transparency = 1, Size = body.Size * 0.85 })
			end
		end
	end

	function api.Combo(target)
		if not api.CanUse(target) then
			return false
		end
		local result = core.Perform(target, "P4Dash", function()
			local mode = pickMode()
			local count = Style.Dashes[mode] or 4
			actor:SetAttribute("P4DashMode", mode)
			actor:SetAttribute("AttackState", "Dash: " .. (Style.ModeNames[mode] or mode))
			local root = core.Root
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local startGround = Placement.GroundPoint(root.Position, { Clamp = true })
			if not startGround then
				return false
			end
			local standing = math.max(2.5, root.Position.Y - startGround.Y)
			local bounds = Placement.GetBounds()
			local cast = Effects.NewCast(actor, "P4Dash", 12)
			current = cast
			local anchored = root.Anchored
			local tookAnchor = false
			cast.OnDispose = function()
				if tookAnchor and root.Parent and (actor:GetAttribute("MovementRevision") or 0) == revision then
					Time.SetAnchored(root, anchored)
					root.AssemblyLinearVelocity = Vector3.zero
				end
				if current == cast then
					current = nil
				end
			end
			local function valid()
				return cast:Alive()
					and core.Active()
					and phaseOk()
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
					and not actor:GetAttribute("EncounterEnded")
					and not actor:GetAttribute("PhaseTransitionInProgress")
			end
			local function fail()
				cast:Dispose()
				return false
			end

			 
			local star = {}
			do
				local spin = rng:NextNumber(0, math.pi * 2)
				local rx = (bounds.HalfX - Style.ArenaMargin) * Style.RegularStarScale
				local rz = (bounds.HalfZ - Style.ArenaMargin) * Style.RegularStarScale
				local vertices = {}
				for i = 1, 5 do
					local a = spin + (i - 1) / 5 * math.pi * 2
					vertices[i] = bounds.Frame:PointToWorldSpace(Vector3.new(math.cos(a) * rx, 0, math.sin(a) * rz))
				end
				local nearest, best = 1, math.huge
				for i, v in ipairs(vertices) do
					local d = (Vector3.new(v.X, 0, v.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
					if d < best then
						nearest, best = i, d
					end
				end
				local startAt = table.find(STAR_ORDER, nearest) or 1
				for k = 0, 4 do
					star[k + 1] = vertices[STAR_ORDER[(startAt + k) % 5 + 1]]
				end
			end

			local function focus()
				if core.Alive(target) then
					return target
				end
				for _, char in ipairs(core.Characters()) do
					if core.Alive(char) then
						target = char
						return char
					end
				end
			end
			local function destination(index, from)
				local want
				if mode == "Regular" then
					want = star[(index - 1) % #star + 1]
				else
					local who = focus()
					if not who then
						return nil
					end
					local p = who.HumanoidRootPart.Position
					if mode == "DrawNear" then
						local flat = Vector3.new(p.X - from.X, 0, p.Z - from.Z)
						want = flat.Magnitude > 0.5 and p + flat.Unit * Style.DrawNearOvershoot or p
					else
						local a = rng:NextNumber(0, math.pi * 2)
						local r = rng:NextNumber(Style.ErranticMin, Style.ErranticMax)
						want = p + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
					end
				end
				local floor = Placement.GroundPoint(want, { Clamp = true, Margin = Style.ArenaMargin })
				return floor and Vector3.new(floor.X, floor.Y + standing, floor.Z), floor
			end

			local function scan(from, to, hit)
				local delta = to - from
				local flat = Vector3.new(delta.X, 0, delta.Z)
				for _, char in ipairs(core.Characters()) do
					if not hit[char] and core.Alive(char) then
						local p = char.HumanoidRootPart.Position
						local offset = Vector3.new(p.X - from.X, 0, p.Z - from.Z)
						local t = flat:Dot(flat) > 0 and math.clamp(offset:Dot(flat) / flat:Dot(flat), 0, 1) or 0
						local closest = from + delta * t
						if Vector3.new(p.X - closest.X, 0, p.Z - closest.Z).Magnitude <= Style.HitRadius
							and math.abs(p.Y - closest.Y) <= Style.HitHeight
							and core.CanHit(char, closest)
						then
							hit[char] = true
							if core.Damage(char, Style.Damage, "P4Dash") > 0 then
								core.Melee.HitFx(p)
								local dir = flat.Magnitude > 0.01 and flat.Unit or Vector3.zAxis
								FX.Impact(ctx, cast, p, Golden.CRIMSON, Golden.WHITE, 0.75, { Direction = dir, Spread = 50, Shake = 0.35, Tint = 0.4 })
								FX.Crescent(ctx, cast, CFrame.lookAt(p, p + dir) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-40, 40))) * CFrame.new(0, 0, 3),
									5, math.rad(130), 1.1, Golden.CRIMSON, Golden.WHITE, 0.2)
							end
						end
					end
				end
			end

			 
			Audio.Emit(actor, "ThrustCharge", root)
			core.PoseAngles({ RightShoulder = { 20, 0, -60 }, LeftShoulder = { 30, 0, 40 }, Waist = { 20, 0, 0 } }, 0.1)
			afterimage(cast, Golden.ROSE)
			FX.Ring(ctx, cast, CFrame.new(startGround + Vector3.new(0, 0.2, 0)) * CFrame.Angles(math.pi / 2, 0, 0), 2, 16, 0.35, Golden.CRIMSON, 0, 0.5)

			Time.SetAnchored(root, true)
			tookAnchor = true
			local total, legs = 0, 0
			for index = 1, count do
				if not valid() then
					return fail()
				end
				local from = root.Position
				local dest, floor = destination(index, from)
				if not dest then
					break
				end
				local delta = dest - from
				local flatDelta = Vector3.new(delta.X, 0, delta.Z)
				 
				local wall = flatDelta.Magnitude > 0.1
					and workspace:Blockcast(CFrame.new(from), Vector3.new(3, 4, 3), flatDelta, core.Params())
				if wall then
					flatDelta = flatDelta.Unit * math.max(0, wall.Distance - 0.5)
				end
				if flatDelta.Magnitude >= Style.MinLeg then
					local direction = flatDelta.Unit
					local length = flatDelta.Magnitude
					local floorY = floor and floor.Y or from.Y - standing

					 
					root.CFrame = CFrame.lookAt(from, from + direction)
					local tele = index == 1 and Style.FirstTelegraph or Style.Telegraph
					 -- no ground lane: the glint on the boss is the only tell
					FX.Glint(ctx, cast, from + Vector3.new(0, 1.5, 0), Golden.CRIMSON, 3.5, tele)
					if not core.WaitFor(tele) or not valid() then
						return fail()
					end

					 
					core.PoseAngles({ RightShoulder = { 60, 0, -100 }, LeftShoulder = { 10, 0, 70 }, Waist = { 25, 0, 0 } }, 0.04)
					Audio.Emit(actor, "ThrustBurst", root)
					FX.Flash(ctx, cast, from, Golden.WHITE, 5, 0.12, 0)
					FX.Ring(ctx, cast, CFrame.lookAt(from, from + direction), 1, 9, 0.25, Golden.CRIMSON, 0, 0.4, 12)
					FX.Streaks(ctx, cast, from, -direction, Golden.CRIMSON, Golden.WHITE, 10, 35, 30, 60, 2.4)
					local hit = {}
					local travelled, ghostClock = 0, Style.AfterimageInterval
					local tint = false
					while travelled < length do
						local dt = Run.Heartbeat:Wait()
						if not valid() or not Time.WaitForActor(actor) or not valid() then
							return fail()
						end
						local step = math.min(length - travelled, Style.Speed * math.min(dt, 0.05) * Time.BossRate(actor))
						if step > 0 then
							local a = root.Position
							local ahead = from + direction * (travelled + step)
							local g = Placement.GroundPoint(ahead, { Clamp = true })
							local b = Vector3.new(ahead.X, (g and g.Y or floorY) + standing, ahead.Z)
							root.CFrame = CFrame.lookAt(b, b + direction)
							ghostClock += dt
							if ghostClock >= Style.AfterimageInterval then
								ghostClock = 0
								tint = not tint
								afterimage(cast, tint and Golden.CRIMSON or Golden.DEEP)
							end
							core.MotionLine("P4DashTrail", a, b, 2.4, Golden.CRIMSON, 0.28)
							core.MotionLine("P4DashTrailCore", a, b, 0.45, Golden.WHITE, 0.2)
							scan(a, b, hit)
							travelled += step
						end
					end
					local stop = root.Position
					legs += 1
					total += length
					 
					local skid = Vector3.new(stop.X, floorY + 0.15, stop.Z)
					FX.Shockwave(ctx, cast, CFrame.new(skid), 2, 12, 0.3, Golden.CRIMSON, 0.3)
					FX.Sparks(ctx, cast, skid + Vector3.new(0, 0.5, 0), Golden.CRIMSON, Golden.GOLD, 10, 10, 26, 0.4)
					FX.Smoke(ctx, cast, skid, Golden.DUST, 3, 4, 12, 2)
					if not core.WaitFor(Style.Pause) or not valid() then
						return fail()
					end
				end
			end
			actor:SetAttribute("P4DashLegs", legs)
			actor:SetAttribute("P4DashDistance", total)
			 
			if core.Alive(target) then
				core.Face(target)
			end
			local here = root.Position
			FX.Ring(ctx, cast, CFrame.new(here) * CFrame.Angles(math.pi / 2, 0, 0), 14, 2, 0.25, Golden.ROSE, 0, 0.5)
			FX.Flash(ctx, cast, here, Golden.CRIMSON, 7, 0.2, 0.2)
			local ok = core.WaitFor(Style.Recovery) and valid()
			cast:Schedule(0.5, function()
				cast:Dispose()
			end)
			if tookAnchor and root.Parent then
				Time.SetAnchored(root, anchored)
				root.AssemblyLinearVelocity = Vector3.zero
				tookAnchor = false
			end
			if current == cast then
				current = nil
			end
			return ok
		end)
		return result
	end
	function api.Dispose()
		if current then
			current:Dispose()
		end
	end
	return api
end
