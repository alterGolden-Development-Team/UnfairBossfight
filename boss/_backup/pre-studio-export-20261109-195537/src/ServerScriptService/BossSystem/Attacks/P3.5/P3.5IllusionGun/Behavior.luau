--[[
 P3.5 Illusion Gun: the boss draws True Illusion's card gun and fires one kind of suit round per cast
 at a target, picked from the four suits:
   Spade    a fan of cards              Ace (heart)  cards that home in for a moment
   Diamond  a rapid straight burst      Club         one heavy shell that leaves a burning pool
 The gun model, cards and visuals are shared with P3.5TrueIllusion(Ultimate); numbers are in Style.
]]
local B = script:FindFirstAncestor("BossSystem")
local Registry = require(B.Combat.AttackRegistry)
local Effects = require(B.Combat.EffectService)
local Runtime = require(B.Combat.CombatRuntime)
local Audio = require(B.Presentation.CombatAudio)
local Run = game:GetService("RunService")
local TI = script.Parent.Parent["P3.5TrueIllusion(Ultimate)"]
local TIStyle = require(TI.Style)
local V = require(TI.Visuals)
local Launcher = require(TI.Launcher)
local S = require(script.Parent.Style)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local NAME = "P3.5IllusionGun"
local ORDER = { "Spade", "Ace", "Diamond", "Club" }
local MAX_LEAD = 60

local function aimFrame(pos, dir)
	local up = math.abs(dir.Y) > 0.97 and Vector3.xAxis or Vector3.yAxis
	return CFrame.lookAt(pos, pos + dir, up)
end
local function pose(name, pitch)
	local out = {}
	for joint, angles in pairs(TIStyle.Poses[name] or {}) do out[joint] = { angles[1], angles[2], angles[3] } end
	if pitch and out.RightShoulder then out.RightShoulder[1] += math.clamp(pitch, -45, 60) end
	return out
end
local function spin(dir, degrees)
	return CFrame.fromAxisAngle(Vector3.yAxis, math.rad(degrees)):VectorToWorldSpace(dir)
end

return function(actor)
	local core = Registry.For(actor, "P1CombatCore")
	local misdirection = Registry.For(actor, "P3Misdirection(Passive)")
	local rng = Random.new()
	local current
	local api = { Cooldown = S.Cooldown }
	function api.CanUse(target)
		return not current and actor:GetAttribute("Phase") == 3.5 and core.Active() and core.Alive(target)
			and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("IsIllusion")
			and not actor:GetAttribute("PhaseTransitionInProgress") and not actor:GetAttribute("TrueIllusionActive")
	end

	 -- one suit per cast, drawn from KindWeights (Spade, Ace, Diamond, Club)
	local function pickKinds()
		local sum = 0
		for _, w in ipairs(S.KindWeights) do sum += w end
		local roll, total = rng:NextNumber() * sum, 0
		for i, w in ipairs(S.KindWeights) do
			total += w
			if w > 0 and roll <= total then return { ORDER[i] } end
		end
		return { ORDER[1] }
	end

	function api.Combo(target)
		if not api.CanUse(target) then return false end
		return core.Perform(target, NAME, function()
			local root = core.Root
			local generation = actor:GetAttribute("PhaseGeneration") or 0
			local revision = actor:GetAttribute("MovementRevision") or 0
			local kinds = pickKinds()
			local cast = Effects.NewCast(actor, NAME, 4 + #kinds * 2)
			current = cast
			local projectiles, hidden = {}, {}
			cast.OnDispose = function()
				local live = {}
				for p in pairs(projectiles) do live[#live + 1] = p end
				for _, p in ipairs(live) do p:Dispose() end
				for item, alpha in pairs(hidden) do if item.Parent then item.Transparency = alpha end end
				if current == cast then current = nil end
			end
			local function valid()
				return not cast.closed and core.Active() and actor:GetAttribute("Phase") == 3.5
					and (actor:GetAttribute("PhaseGeneration") or 0) == generation
					and (actor:GetAttribute("MovementRevision") or 0) == revision
					and not actor:GetAttribute("PhaseTransitionInProgress") and not actor:GetAttribute("EncounterEnded")
			end
			local function waitFor(seconds)
				local ends = os.clock() + seconds
				repeat Run.Heartbeat:Wait() if not valid() then return false end until os.clock() >= ends
				return true
			end
			 -- every exit (finished, interrupted or errored) disposes the cast, which puts the sword back
			local function run()

			 -- swap the sword for the card gun
			local sword = actor:FindFirstChild("Basic Sword")
			if sword then
				for _, item in ipairs(sword:GetDescendants()) do
					if (item:IsA("BasePart") or item:IsA("Decal")) and item.Transparency < 1 then
						hidden[item] = item.Transparency
						item.Transparency = 1
					end
				end
			end
			local gun = Launcher.Build({ Cast = cast, Style = TIStyle, Actor = actor, V = V, Parent = Runtime.Effects })
			gun:Attach()
			cast:Step(function(dt)
				if not valid() then cast:Dispose() return false end
				gun:Step(dt, root.CFrame * CFrame.new(1.8, 1, -0.8))
				return true
			end)
			gun:Reveal(S.Draw)
			core.PoseAngles(pose("Ready"), 0.15)
			actor:SetAttribute("AttackState", "Illusion Gun: " .. table.concat(kinds, ", "))
			if not waitFor(S.Draw) then return false end

			local function hazard(point, spec)
				local radius = spec.Radius * S.Club.HazardScale
				local zone = Effects.NewCast(actor, "IllusionGunHazard", S.Club.Hazard + 1.2)
				projectiles[zone] = true
				zone.OnDispose = function() projectiles[zone] = nil end
				local center = V.Hazard(zone, point, spec, radius, S.Club.Hazard, actor) or point
				local age, last = 0, {}
				zone:Step(function(dt)
					if not valid() then zone:Dispose() return false end
					age += dt
					if age >= S.Club.Hazard then zone:Dispose() return false end
					local now = os.clock()
					for _, char in ipairs(core.Characters()) do
						if core.Alive(char) and (not last[char] or now - last[char] >= S.Club.Tick) then
							local off = char.HumanoidRootPart.Position - center
							if Vector3.new(off.X, 0, off.Z).Magnitude <= radius and math.abs(off.Y) <= 7 then
								last[char] = now
								core.Damage(char, S.Club.TickDamage, NAME)
							end
						end
					end
					return true
				end)
			end

			 -- one card round: flies straight (or homes briefly), bursts on the first player, wall or at range.
			 -- A Misdirection decoy (opts.Fake) passes through players and bursts harmlessly at its point.
			local function fire(spec, direction, opts)
				opts = opts or {}
				local fake = opts.Fake == true
				local range = fake and math.min(S.Range, opts.FakeDistance or S.Range) or S.Range
				local origin = gun:Muzzle()
				local speed = S.Speed * (opts.SpeedScale or 1)
				local rocketCast = Effects.NewCast(actor, "IllusionGunRound", range / speed + 0.6)
				projectiles[rocketCast] = true
				rocketCast.OnDispose = function() projectiles[rocketCast] = nil end
				local rocket = V.Rocket(rocketCast, spec, origin, direction, { Scale = opts.Scale })
				local position, traveled, age, done, cued = origin, 0, 0, false, false
				local function burst(point, wall)
					if done then return end
					done = true
					if valid() then
						V.Burst(actor, point, spec, core.Params(), direction)
						Audio.Emit(actor, "CardBurst", point)
						for _, char in ipairs(not fake and core.Characters() or {}) do
							if core.Alive(char) and (char.HumanoidRootPart.Position - point).Magnitude <= spec.Radius + 2 and core.CanHit(char, point) then
								core.Damage(char, spec.Damage, NAME)
							end
						end
						if opts.Hazard and not fake then hazard(point, spec) end
					end
					rocketCast:Dispose()
				end
				rocketCast:Step(function(dt)
					if not valid() then rocketCast:Dispose() return false end
					dt = math.min(dt, 0.08)
					age += dt
					local homing = opts.Homing
					if homing and age < homing.Duration and core.Alive(homing.Target) then
						local to = homing.Target.HumanoidRootPart.Position - position
						if to.Magnitude > 1 then
							local want = to.Unit
							local angle = math.acos(math.clamp(direction:Dot(want), -1, 1))
							if angle > 1e-3 then
								local turned = direction:Lerp(want, math.min(1, homing.Turn * dt / angle))
								if turned.Magnitude > 1e-3 then direction = turned.Unit end
							end
						end
					end
					if opts.Clue and not cued and core.Alive(opts.ClueTarget) then
						local along = (opts.ClueTarget.HumanoidRootPart.Position - position):Dot(direction)
						if along <= speed * (Config.P3MisdirectionClueLead or 0.25) then
							cued = true
							pcall(misdirection.Cue, core, rocket, position)
						end
					end
					local length = math.min(speed * dt, range - traveled)
					local delta = direction * length
					local wall = workspace:Raycast(position, delta, core.Params())
					local limit = wall and wall.Distance or length
					local first, firstDistance
					for _, char in ipairs(not fake and core.Characters() or {}) do
						if core.Alive(char) then
							local offset = char.HumanoidRootPart.Position - position
							local along = math.clamp(offset:Dot(direction), 0, limit)
							if (offset - direction * along).Magnitude <= 2.6 and (not firstDistance or along < firstDistance) then
								first, firstDistance = char, along
							end
						end
					end
					if first then burst(position + direction * firstDistance) return false end
					if wall then burst(wall.Position + wall.Normal * 0.5, true) return false end
					position += delta
					traveled += length
					rocket.CFrame = aimFrame(position, direction)
					if traveled >= range then burst(position) return false end
					return true
				end)
			end

			local function aimAt(char)
				local from = gun:Muzzle()
				local p = char.HumanoidRootPart.Position
				local v = char.HumanoidRootPart.AssemblyLinearVelocity
				v = Vector3.new(v.X, 0, v.Z)
				if v.Magnitude > MAX_LEAD then v = v.Unit * MAX_LEAD end
				local at = p + v * ((p - from).Magnitude / S.Speed) * S.Lead
				local d = at - from
				local flat = Vector3.new(d.X, 0, d.Z).Magnitude
				return d.Magnitude > 0.01 and d.Unit or root.CFrame.LookVector, math.deg(math.atan2(d.Y, math.max(flat, 0.1)))
			end

			for index, kind in ipairs(kinds) do
				if not valid() then return false end
				if not core.Alive(target) then
					target = Registry.For(actor, "P1NormalSlash").GetTarget(true)
					if not core.Alive(target) then break end
				end
				local spec = TIStyle.Suits[kind]
				local pattern = S[kind]
				gun:SetSuit({ Symbol = spec.Symbol, Color = spec.Color })
				core.Face(target)
				local dir, pitch = aimAt(target)
				core.PoseAngles(pose("Aim", pitch), 0.12)
				gun:Charge(spec, S.Aim)
				if not waitFor(S.Aim) then return false end
				dir, pitch = aimAt(target)
				 -- Misdirection: the same volley also goes out at a decoy point, harmless; the real rounds flash
				 -- just before they arrive
				local decoy = misdirection.TryEmission and misdirection.TryEmission(NAME, target)
				local turn, decoyDistance
				if decoy then
					local to = decoy - gun:Muzzle()
					if to.Magnitude > 1 then
						turn, decoyDistance = CFrame.fromRotationBetweenVectors(dir, to.Unit), to.Magnitude
						actor:SetAttribute("MisdirectionIllusionGunAt", workspace:GetServerTimeNow())
					end
				end
				local function shot(direction, opts)
					V.Muzzle(cast, gun:Muzzle(), direction, { Color = spec.Color })
					gun:Recoil(kind == "Club" and 1.6 or 0.8)
					opts = opts or {}
					if turn then
						local decoyOpts = table.clone(opts)
						decoyOpts.Fake, decoyOpts.FakeDistance, decoyOpts.Homing = true, decoyDistance, nil
						fire(spec, turn:VectorToWorldSpace(direction), decoyOpts)
						opts.Clue, opts.ClueTarget = true, target
					end
					fire(spec, direction, opts)
				end
				if kind == "Spade" then
					for i = 1, pattern.Count do
						local offset = (i - (pattern.Count + 1) / 2) * (pattern.Spread / math.max(pattern.Count - 1, 1)) * 2
						shot(spin(dir, offset))
					end
				elseif kind == "Ace" then
					for i = 1, pattern.Count do
						local offset = (i - (pattern.Count + 1) / 2) * (pattern.Spread / math.max(pattern.Count - 1, 1)) * 2
						shot(spin(dir, offset), { Homing = { Target = target, Turn = pattern.Turn, Duration = pattern.Homing } })
					end
				elseif kind == "Diamond" then
					for i = 1, pattern.Count do
						if not valid() then return false end
						if core.Alive(target) then dir = aimAt(target) end
						shot(dir)
						if i < pattern.Count and not waitFor(pattern.Interval) then return false end
					end
				else
					shot(dir, { Hazard = true, Scale = 1.6, SpeedScale = 0.75 })
				end
				gun:Fired()
				Audio.Emit(actor, "ProjectileCast", root.Position)
				core.PoseAngles(pose("Recoil", pitch), 0.05)
				if index < #kinds and not waitFor(S.Gap) then return false end
			end

			core.PoseAngles(pose("Ready"), 0.15)
			gun:Dismiss(S.Holster)
			if not waitFor(S.Holster + 0.2) then return false end
			 -- let the rounds already in the air finish before the cast closes
			local settle = os.clock() + S.Range / S.Speed
			while next(projectiles) and os.clock() < settle and valid() do Run.Heartbeat:Wait() end
			return true
			end
			local ok, result = xpcall(run, debug.traceback)
			cast:Dispose()
			if not ok then error(result, 0) end
			return result
		end)
	end
	function api.Dispose() if current then current:Dispose() end end
	return api
end
