--[[
 P5StrikeCore - shared plumbing for the Phase 5 normal attacks (Attacks/P5/NormalAttack: Claw Forward,
 Assassination, Upper Cut, Butterfly, Distorted Counter, Golden Pierce, Slam, Viper, Horrifying Ground, and the
 Wild Hunt and Night Tearer ultimates). Each cast runs inside P1CombatCore.Perform and keeps its hit
 volumes on the server; every visual is a P5Strikes cue the clients draw (VFXEngine.Effects.P5Strikes).
]]
local B = script:FindFirstAncestor("BossSystem")
local Registry = require(B.Combat.AttackRegistry)
local Encounter = require(B.Players.PlayerEncounter)
local Placement = require(B.Encounter.ArenaPlacement)
local Runtime = require(B.Combat.CombatRuntime)
local Net = require(game.ReplicatedStorage.VFXEngine.Net)
local Effects = require(B.Combat.EffectService)
local Deflect = require(B.Combat.DeflectService)
local Audio = require(B.Presentation.CombatAudio)
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
 -- the P1.5 Teleportation flash and sounds, shared by every P5 blink
local Teleport = B.Attacks["P1.5"]["P1.5Teleportation"]
local TeleportStyle = require(Teleport.Style)
local teleportFlash = require(Teleport.Visuals).flash({
	Placement = Placement, Effects = Effects, Runtime = Runtime, GOLD = TeleportStyle.GOLD, BRIGHT = TeleportStyle.BRIGHT,
})
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local api = {}

function api.Context(actor, name)
	local core = Registry.For(actor, "P1CombatCore")
	local ctx = { Actor = actor, Core = core, Root = core.Root, Name = name }

	function ctx.Valid()
		return core.Active() and actor:GetAttribute("Phase") == 5 and not actor:GetAttribute("PhaseTransitionInProgress")
	end
	function ctx.CanStart(target)
		return actor:GetAttribute("Phase") == 5 and core.Active() and core.Alive(target)
			and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("IsIllusion")
			and not actor:GetAttribute("PhaseTransitionInProgress")
	end
	 -- windups and warnings stretch or shrink with the difficulty's Telegraph (the Enraged Gate's included)
	function ctx.Tell(seconds)
		return seconds * Difficulty.Get(actor).Telegraph
	end
	 -- how many beams, slices or spikes for the difficulty's Density
	function ctx.Count(n)
		return Difficulty.Count(n, actor)
	end
	 -- a warning floating over a player (VFXEngine P5Strikes.Warn): Kind "Lethal" - red, this takes lives (`lives`
	 -- of them) - or "Jump" - gold, jump now
	function ctx.Cue(char, kind, seconds, lives)
		ctx.Send("Warn", { Victim = char, Kind = kind, Time = seconds, Lives = lives })
	end
	function ctx.Wait(seconds)
		return core.WaitFor(seconds) and ctx.Valid()
	end
	 -- a per-frame loop for `seconds`; fn(alpha, dt) returns false to stop early
	function ctx.Over(seconds, fn)
		local elapsed = 0
		while elapsed < seconds do
			local dt = Run.Heartbeat:Wait()
			if not ctx.Valid() then
				return false
			end
			elapsed += dt
			if fn(math.min(elapsed / seconds, 1), dt) == false then
				return true
			end
		end
		return true
	end
	function ctx.Targets()
		local out = {}
		for _, char in ipairs(core.Characters()) do
			local player = Players:GetPlayerFromCharacter(char)
			if core.Alive(char) and player and player.Character == char and not Encounter.IsDefeated(player)
				and not player:GetAttribute("ViewAsServer") then
				out[#out + 1] = char
			end
		end
		return out
	end
	 -- a random player; `avoid` is skipped when someone else is around
	function ctx.RandomTarget(avoid)
		local list = ctx.Targets()
		if #list > 1 and avoid then
			local index = table.find(list, avoid)
			if index then
				table.remove(list, index)
			end
		end
		return #list > 0 and list[math.random(1, #list)] or nil
	end
	function ctx.Send(stage, data)
		data = data or {}
		data.Boss = actor
		Net.Send("P5Strikes", stage, data)
	end
	function ctx.Ground(position)
		return Placement.GroundPoint(position, { Clamp = true }) or position - Vector3.new(0, 3, 0)
	end
	 -- teleport to `frame` the way P1.5 Teleportation does (its flash and sounds), kept on the arena floor;
	 -- false when there is no room there
	function ctx.Blink(frame)
		local valid = Placement.Validate(actor, frame, { Margin = 6 })
			or Placement.ResolveRecorded(actor, frame, { Margin = 6, SearchRadius = 10 })
		if not valid then
			return false
		end
		local old = ctx.Root.CFrame
		local cast = Effects.NewCast(actor, "TeleportationFlash", 0.5)
		Audio.Emit(actor, "TeleportOut", ctx.Root)
		teleportFlash(old, "TeleportDeparture", cast)
		Audio.Emit(actor, "TeleportWarp", old.Position)
		ctx.Root.AssemblyLinearVelocity = Vector3.zero
		ctx.Root.AssemblyAngularVelocity = Vector3.zero
		ctx.Root.CFrame = valid
		teleportFlash(valid, "TeleportArrival", cast)
		Audio.Emit(actor, "TeleportIn", valid.Position)
		return true
	end
	 -- behind a player (the way they face), facing them
	function ctx.Behind(char, distance)
		return ctx.Beside(char, distance, 0)
	end
	 -- a deflectable hit: true when the player turned it away (no damage then)
	function ctx.Deflected(char, kind)
		return kind ~= nil and Deflect.TryDeflect(char, kind)
	end
	function ctx.Warn(char, kind, seconds)
		Deflect.Warn(char, kind, seconds)
	end
	 -- a flying claw (three or more blades, VFXEngine P5Strikes.Claw) along `frame`; o: Speed, Range, Width,
	 -- Spread, Roll, Count, Damage, HitHalfWidth, HitHeight, Deflect ("Tap"/"Hold"/nil), Final
	function ctx.FireClaw(frame, o)
		ctx.Send("Claw", { Frame = frame, Roll = o.Roll, Speed = o.Speed, Range = o.Range, Width = o.Width,
			Spread = o.Spread, Count = o.Count, Final = o.Final })
		local cast = Effects.NewCast(actor, "P5ClawWave", o.Range / o.Speed + 0.5)
		cast.PersistsThroughEmitterStun = true  -- a thrown claw keeps flying if the boss is stunned
		local traveled, hit = 0, {}
		local params = core.Params()
		if o.Deflect then  -- the shield cue for whoever is in its lane, just before it reaches them
			local lead = o.Deflect == "Hold" and (Config.DeflectHoldTime or 0.5) + 0.3 or (Config.DeflectWarnLead or 0.5)  -- a hold needs time to fill
			for _, char in ipairs(ctx.Targets()) do
				local p = frame:PointToObjectSpace(char.HumanoidRootPart.Position)
				if math.abs(p.X) <= o.HitHalfWidth + 6 and math.abs(p.Y) <= o.HitHeight + 6 and -p.Z > 0 and -p.Z <= o.Range then
					local eta = -p.Z / o.Speed
					task.delay(math.max(0, eta - lead), function()
						if not hit[char] then Deflect.Warn(char, o.Deflect, math.min(eta, lead) + 0.15) end
					end)
				end
			end
		end
		cast:Step(function(dt)
			if actor:GetAttribute("Phase") ~= 5 or actor:GetAttribute("PhaseTransitionInProgress") then
				cast:Dispose()
				return false
			end
			local step = math.min(o.Speed * dt, o.Range - traveled)
			local wall = workspace:Raycast(frame.Position, frame.LookVector * step, params)
			if wall then
				step = wall.Distance
			end
			for _, char in ipairs(ctx.Targets()) do
				if not hit[char] then
					local p = frame:PointToObjectSpace(char.HumanoidRootPart.Position)
					if math.abs(p.X) <= o.HitHalfWidth and math.abs(p.Y) <= o.HitHeight and p.Z <= 2 and p.Z >= -step - 2 then
						hit[char] = true
						if not ctx.Deflected(char, o.Deflect) and ctx.Hit(char, o.Damage, frame.Position) > 0 then
							ctx.Send("ClawHit", { Pos = char.HumanoidRootPart.Position })
						end
					end
				end
			end
			frame += frame.LookVector * step
			traveled += step
			if wall or traveled >= o.Range then
				cast:Dispose()
				return false
			end
			return true
		end)
	end
	 -- a frame `distance` studs from a player (at `angle` around them, 0 = behind), facing them
	function ctx.Beside(char, distance, angle)
		local r = char.HumanoidRootPart
		local look = r.CFrame.LookVector * Vector3.new(1, 0, 1)
		look = look.Magnitude > 0.1 and look.Unit or Vector3.zAxis
		local offset = CFrame.Angles(0, angle or 0, 0):VectorToWorldSpace(-look) * distance
		local spot = Vector3.new(r.Position.X + offset.X, ctx.Root.Position.Y, r.Position.Z + offset.Z)
		local face = Vector3.new(r.Position.X, spot.Y, r.Position.Z)
		return (face - spot).Magnitude > 0.1 and CFrame.lookAt(spot, face) or CFrame.new(spot)
	end
	function ctx.Hit(char, amount, origin, options)
		options = options or {}
		if not core.CanHit(char, origin or ctx.Root.Position) then
			return 0
		end
		local dealt = Encounter.Damage(char, amount, actor, nil, { Skill = name, BreaksBlock = options.BreaksBlock }) or 0
		if dealt > 0 and options.Knock then
			Runtime.Knockback(actor, char, options.Knock.Direction or Vector3.zAxis, options.Knock)
		end
		return dealt
	end
	 -- a hit that takes whole lives (the target dies and pays `lives`), like the Hyper-lastic Beam
	function ctx.Execute(char, lives, origin)
		if not core.CanHit(char, origin or ctx.Root.Position) then
			return false
		end
		return Encounter.ExecuteHit(char, lives, name)
	end
	 -- a straight shot (VFXEngine P5Strikes.Bolt draws it, Look = its style); o: Speed, Range, Radius, Damage,
	 -- Pierce (keeps going through players), Deflect ("Tap"/"Hold"/nil), Look, Knock (Runtime.Knockback options)
	function ctx.Bolt(origin, dir, o)
		dir = dir.Magnitude > 0.01 and dir.Unit or ctx.Root.CFrame.LookVector
		ctx.Send("Bolt", { Origin = origin, Dir = dir, Speed = o.Speed, Range = o.Range, Look = o.Look or "Pierce", Width = o.Radius })
		local cast = Effects.NewCast(actor, "P5Bolt", o.Range / o.Speed + 0.5)
		cast.PersistsThroughEmitterStun = true
		local pos, traveled, hit = origin, 0, {}
		local params = core.Params()
		if o.Deflect then
			local lead = o.Deflect == "Hold" and (Config.DeflectHoldTime or 0.5) + 0.3 or (Config.DeflectWarnLead or 0.5)  -- a hold needs time to fill
			for _, char in ipairs(ctx.Targets()) do
				local rel = char.HumanoidRootPart.Position - origin
				local along = rel:Dot(dir)
				if along > 0 and along <= o.Range and (rel - dir * along).Magnitude <= o.Radius + 5 then
					local eta = along / o.Speed
					task.delay(math.max(0, eta - lead), function()
						if not hit[char] then Deflect.Warn(char, o.Deflect, math.min(eta, lead) + 0.15) end
					end)
				end
			end
		end
		cast:Step(function(dt)
			if actor:GetAttribute("Phase") ~= 5 or actor:GetAttribute("PhaseTransitionInProgress") then
				cast:Dispose()
				return false
			end
			local step = math.min(o.Speed * dt, o.Range - traveled)
			local wall = workspace:Raycast(pos, dir * step, params)
			if wall then
				step = wall.Distance
			end
			local nextPos = pos + dir * step
			for _, char in ipairs(ctx.Targets()) do
				local p = char.HumanoidRootPart.Position
				local d = nextPos - pos
				local t = d:Dot(d) > 1e-4 and math.clamp((p - pos):Dot(d) / d:Dot(d), 0, 1) or 0
				if not hit[char] and (p - (pos + d * t)).Magnitude <= o.Radius then
					hit[char] = true
					if not ctx.Deflected(char, o.Deflect) then
						local knock = o.Knock and table.clone(o.Knock)
						if knock then knock.Direction = dir end
						ctx.Hit(char, o.Damage, pos, { Knock = knock })
					end
					if not o.Pierce then
						cast:Dispose()
						return false
					end
				end
			end
			pos = nextPos
			traveled += step
			if wall or traveled >= o.Range then
				cast:Dispose()
				return false
			end
			return true
		end)
	end
	 -- a ground shockwave ring from `center` (VFXEngine P5Strikes.Shockwave draws it): its front runs out at o.Speed
	 -- to o.Range and hits everyone it crosses once, unless they are more than o.Height over the floor (jump it).
	 -- o: Speed, Range, Width (how far behind the front still hits), Height, Damage, Knock, Look ("Gold"/"Dark"),
	 -- Inward (the ring starts at Range and closes on the centre)
	function ctx.Shockwave(center, o)
		ctx.Send("Shockwave", { Pos = center, Speed = o.Speed, Range = o.Range, Look = o.Look, Inward = o.Inward })
		local cast = Effects.NewCast(actor, "P5Shockwave", o.Range / o.Speed + 0.5)
		cast.PersistsThroughEmitterStun = true
		local hit, radius = {}, o.Inward and o.Range or 0
		cast:Step(function(dt)
			if actor:GetAttribute("Phase") ~= 5 or actor:GetAttribute("PhaseTransitionInProgress") then
				cast:Dispose()
				return false
			end
			local last = radius
			radius = o.Inward and math.max(radius - o.Speed * dt, 0) or math.min(radius + o.Speed * dt, o.Range)
			local lo, hi = math.min(last, radius), math.max(last, radius)
			for _, char in ipairs(ctx.Targets()) do
				if not hit[char] then
					local rel = char.HumanoidRootPart.Position - center
					local flat = Vector3.new(rel.X, 0, rel.Z)
					if flat.Magnitude >= lo - o.Width and flat.Magnitude <= hi + o.Width and rel.Y <= (o.Height or 4) + 3.5 then
						hit[char] = true
						local knock = o.Knock and table.clone(o.Knock)
						if knock then knock.Direction = flat.Magnitude > 0.1 and flat or Vector3.zAxis end
						ctx.Hit(char, o.Damage, center + Vector3.new(0, 2, 0), { Knock = knock })
					end
				end
			end
			if radius >= o.Range or o.Inward and radius <= 0 then
				cast:Dispose()
				return false
			end
			return true
		end)
	end
	 -- the orange-red warning circles crystal spikes come out of (VFXEngine GroundShatter.Warn)
	function ctx.SpikeWarn(points, radius, seconds)
		Net.Send("GroundShatter", "Warn", { Points = points, Radius = radius, Time = seconds })
	end
	 -- gold crystal spikes burst out of the ground at each point (VFXEngine GroundShatter.Erupt; Tall and Count make
	 -- them taller and more of them); after o.Warn seconds of warning circles when it is set. Everyone within
	 -- o.Radius of a point and under o.Height is hit once. o: Radius, Warn, Damage, Tall, Count, Hold, Height, Knock.
	 -- False when the cast ended during the warning.
	function ctx.Spikes(points, o)
		if (o.Warn or 0) > 0 then
			ctx.SpikeWarn(points, o.Radius, o.Warn)
			if not ctx.Wait(o.Warn) then
				return false
			end
		end
		Net.Send("GroundShatter", "Erupt", { Points = points, Radius = o.Radius, Seed = math.random(1, 1e6), Tall = o.Tall,
			Count = o.Count, Hold = o.Hold })
		for _, char in ipairs(ctx.Targets()) do
			local p = char.HumanoidRootPart.Position
			for _, point in ipairs(points) do
				local rel = p - point
				local flat = Vector3.new(rel.X, 0, rel.Z)
				if flat.Magnitude <= o.Radius and rel.Y >= -4 and rel.Y <= (o.Height or 12) then
					local knock = o.Knock and table.clone(o.Knock)
					if knock then knock.Direction = flat.Magnitude > 0.1 and flat or Vector3.zAxis end
					ctx.Hit(char, o.Damage, point + Vector3.new(0, 1, 0), { Knock = knock, BreaksBlock = true })
					break
				end
			end
		end
		return true
	end
	 -- inside a forward arc of the boss (a horizontal slash)
	function ctx.InArc(frame, position, radius, halfAngle, height)
		local p = frame:PointToObjectSpace(position)
		local d = Vector3.new(p.X, 0, p.Z).Magnitude
		if math.abs(p.Y) > (height or 6) or d > radius then
			return false
		end
		return d < 0.5 or -p.Z / d >= math.cos(math.rad(halfAngle))
	end
	return ctx
end

return table.freeze(api)
