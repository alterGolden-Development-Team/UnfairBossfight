local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local B = script:FindFirstAncestor("BossSystem")
local SB = require(RS.BossShared.SonicBlaster)
local Net = require(RS.VFXEngine.Net)
local Difficulty = require(RS.BossShared.Config.DifficultyConfig)
local FX = "P5SonicBlaster"
local TAU = math.pi * 2
local UP = Vector3.yAxis
local PLAYER_R = 0.85  -- the player's own hit radius: small, as in a shmup (the dot over their head shows it)
local DAMAGE = 0.07  -- each bullet takes this much of a player's max health (times the kind's Damage, the difficulty's Damage)
local LASER_DAMAGE = 0.17
local COLUMN_DAMAGE = 0.2
local api = {}
local running = {}

local remote = RS.BossShared:FindFirstChild("SonicBlasterHit")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "SonicBlasterHit"
	remote.Parent = RS.BossShared
end

local BEFORE = { "FA1", "FA2", "FA3", "FA4", "FA5", "FA6", "FA7" }
 -- his goodbye at the black hole: { line, song time, how long it stays up }
local FAREWELL = { { "FB1", 149.9, 4 }, { "FB2", 154.1, 4 }, { "FB3", 158.3, 4 }, { "FB4", 162.5, 4.4 }, { "FB5", 167.1, 3.8 }, { "FB6", 171.1, 2.8 } }
local function line(id)
	local scripts = require(B.Encounter.DialogueScripts)
	return scripts.Original[id] or id  -- (PlayerEncounter.Say translates it for the difficulty)
end

function api.Active(actor)
	return running[actor] ~= nil
end

 -- the solid part of the other dimension: a glass disc (the clients add the stars, planets and the stage's markings)
local function buildFloor()
	local old = workspace:FindFirstChild("NothingDimension")
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = "NothingDimension"
	local floor = Instance.new("Part")
	floor.Name = "Stage"
	floor.Shape = Enum.PartType.Cylinder
	floor.Size = Vector3.new(6, (SB.Radius + 10) * 2, (SB.Radius + 10) * 2)
	floor.CFrame = CFrame.new(SB.Space - UP * 3) * CFrame.Angles(0, 0, math.pi / 2)
	floor.Anchored = true
	floor.CanCollide = true
	floor.CanTouch = false
	floor.CastShadow = false
	floor.Material = Enum.Material.Glass
	floor.Color = Color3.fromRGB(18, 15, 34)
	floor.Reflectance = 0.15
	floor.Parent = f
	-- the Blender stage (MeshKit "NothingStage", lobby/blender/boss_arena.py): an obsidian platform with a gold star chart, a
	-- rocky underside with glowing cracks, crystal shards round the rim and a gold orbit; the glass disc stays as the floor you stand on
	local stage = require(game:GetService("ReplicatedStorage").BossShared.Presentation.MeshKit).Get("NothingStage")
	if stage then
		stage:ScaleTo((SB.Radius + 10) / 100)
		stage:PivotTo(CFrame.new(SB.Space))
		for _, p in ipairs(stage:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
			end
		end
		stage.Name = "StageMesh"
		stage.Parent = f
		floor.Transparency = 1
	end
	f.Parent = workspace
	return f
end

local function lockPlayers(on)
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then char:SetAttribute("FinalAttackLocked", on or nil) end
	end
end

 -- everyone back in the arena (after the win, or if the fight was reset half way)
function api.ReturnHome(actor)
	local Strike = require(B.Attacks.Shared.P5StrikeCore)
	local arena = Strike.Context(actor, "P5SonicBlasterReturn").Center()
	Net.Send(FX, "Return", { Boss = actor })
	task.wait(0.35)
	local list = Players:GetPlayers()
	for i, p in ipairs(list) do
		local char = p.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local a = (i - 1) / math.max(#list, 1) * TAU
			local to = arena + Vector3.new(math.cos(a) * 24, 4, math.sin(a) * 24)
			hrp.Anchored = false
			hrp.CFrame = CFrame.lookAt(to, Vector3.new(arena.X, to.Y, arena.Z))
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		if char then char:SetAttribute("FinalAttackLocked", nil) end
	end
	local f = workspace:FindFirstChild("NothingDimension")
	if f then f:Destroy() end
	workspace:SetAttribute("NothingDimension", nil)
end

function api.Run(actor)
	if running[actor] then return false end
	local Strike = require(B.Attacks.Shared.P5StrikeCore)
	local Encounter = require(B.Players.PlayerEncounter)
	local c = Strike.Context(actor, "P5SonicBlaster")
	local root = c.Root
	local arena = c.Center()
	local space = SB.Space
	local cx, cz, floorY = space.X, space.Z, space.Y
	local R = SB.Radius
	local state = { Done = false, Phase = "Arena" }
	running[actor] = state
	local function valid()
		return actor.Parent ~= nil and not actor:GetAttribute("EncounterEnded") and running[actor] == state
	end

	 -- stop everything else of his: clones, background casts, every attack's leftovers, the passives
	pcall(function() require(B.Mechanics.Clones.CloneController).CancelAll(actor, "Final attack") end)
	pcall(function() require(B.Combat.EffectService).CancelOwner(actor, "Final attack") end)
	pcall(function() require(B.Combat.AttackRegistry).Release(actor) end)
	pcall(function() require(B.Combat.PassiveController).Stop(actor) end)
	pcall(function() require(B.Combat.P5ModeService).Clear(actor) end)
	actor:SetAttribute("AttackInProgress", false)
	actor:SetAttribute("AttackState", "Last Imagination")
	actor:SetAttribute("SonicBlasterActive", true)
	actor:SetAttribute("SonicBlasterHush", true)  -- the music stops for his last words
	actor:SetAttribute("SonicBlasterLength", SB.Length)
	actor:SetAttribute("SonicBlasterMusicStartedAt", nil)
	actor:SetAttribute("FinalVanished", nil)
	workspace:SetAttribute("SonicBlasterActive", true)
	lockPlayers(true)

	 -- he floats wherever state.Goal says (state.Snap: jump straight there), facing the nearest player or state.Look;
	 -- state.Fly takes him along a path on the server clock (into the black hole)
	c.Plant()
	state.Goal = arena + UP * 9
	local float = Run.Heartbeat:Connect(function(dt)
		if not root.Parent then return end
		local f = state.Fly
		if f then
			local u = math.clamp((workspace:GetServerTimeNow() - f.T0) / (f.T1 - f.T0), 0, 1)
			local p = f.From:Lerp(f.To, u * u * u)
			local dir = f.To - f.From
			dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.zAxis
			root.CFrame = CFrame.lookAt(p, p + dir) * CFrame.Angles(0, 0, u * u * 6)
			root.AssemblyLinearVelocity = Vector3.zero
			return
		end
		local t = os.clock()
		local target = state.Goal + Vector3.new(0, math.sin(t * 1.7) * 0.6, 0)
		local here = root.Position
		local p = (state.Snap or (target - here).Magnitude > 300) and target or here:Lerp(target, math.min(1, dt * 2.6))
		state.Snap = nil
		local look = state.Look
		if not look then
			local best, bestD = nil, math.huge
			for _, char in ipairs(c.Targets()) do
				local d = (char.HumanoidRootPart.Position - p).Magnitude
				if d < bestD then best, bestD = char, d end
			end
			look = best and best.HumanoidRootPart.Position or p + Vector3.zAxis
		end
		look = Vector3.new(look.X, p.Y, look.Z)
		if (look - p).Magnitude < 0.1 then look = p + Vector3.zAxis end
		root.CFrame = CFrame.lookAt(p, look)
		root.AssemblyLinearVelocity = Vector3.zero
	end)

	local report, beat
	local function cleanup(survived)
		if float then float:Disconnect() float = nil end
		if beat then beat:Disconnect() beat = nil end
		if report then report:Disconnect() report = nil end
		running[actor] = nil
		workspace:SetAttribute("SonicBlasterActive", nil)
		for _, p in ipairs(Players:GetPlayers()) do
			local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp.Anchored and state.Anchored and state.Anchored[p.Character] then hrp.Anchored = false end
		end
		if actor.Parent then
			actor:SetAttribute("SonicBlasterHush", nil)
			if not survived then
				actor:SetAttribute("SonicBlasterActive", nil)
				actor:SetAttribute("SonicBlasterMusicStartedAt", nil)
			end
		end
		if not survived then
			Net.Send(FX, "End", { Boss = actor })
			lockPlayers(false)
			if workspace:FindFirstChild("NothingDimension") then task.spawn(api.ReturnHome, actor) end
		end
	end

	 -- 1. the cut, and where he comes from
	Net.Send(FX, "Intro", { Boss = actor, Center = arena })
	task.wait(0.9)
	for i, id in ipairs(BEFORE) do
		if not valid() then break end
		Net.Send(FX, "Shot", { Boss = actor, Index = i })
		local raw = line(id)
		local count = 0
		local okT, shown = pcall(function() return require(B.Encounter.DialogueScripts).Translate(raw, actor) end)
		for _ in utf8.graphemes(okT and type(shown) == "string" and shown or raw) do count += 1 end
		local dur = count * 0.017 + 0.35
		pcall(Encounter.Say, raw, nil, { Duration = dur + 0.3, LyricSoundtrack = true })
		local untilAt = os.clock() + dur
		repeat task.wait(0.05) until os.clock() >= untilAt or not valid()
		if not valid() then break end
		task.wait(id == "FA4" and 0.4 or id == "FA6" and 0.35 or 0.12)
	end
	if not valid() then cleanup(false) return false end

	 -- 2. the portal: it opens over the arena and swallows everyone
	local portal = arena + UP * 34
	local mid = Vector3.zero
	local list = c.Targets()
	for _, char in ipairs(list) do mid += char.HumanoidRootPart.Position end
	mid = #list > 0 and mid / #list or arena + Vector3.new(0, 0, 40)
	local facing = (mid - portal) * Vector3.new(1, 0, 1)
	facing = facing.Magnitude > 1 and facing.Unit or Vector3.zAxis
	local OPEN, SUCK = 1.2, 2.4
	Net.Send(FX, "Portal", { Boss = actor, Pos = portal, Facing = facing, Open = OPEN, Suck = SUCK, At = workspace:GetServerTimeNow() })
	pcall(Encounter.Say, line("FA8"), nil, { Duration = 3 })
	state.Goal = portal + facing * 14 - UP * 10
	state.Look = portal + facing * 40
	task.wait(OPEN)
	if not valid() then cleanup(false) return false end
	local caught = {}
	state.Anchored = {}
	for _, char in ipairs(c.Targets()) do
		local hrp = char.HumanoidRootPart
		caught[#caught + 1] = { Char = char, From = hrp.Position, Delay = math.random() * 0.6, Spin = math.random() * TAU }
		hrp.Anchored = true
		state.Anchored[char] = true
	end
	local t0 = os.clock()
	state.Goal = portal
	while os.clock() - t0 < SUCK and valid() do
		local el = os.clock() - t0
		for _, k in ipairs(caught) do
			local hrp = k.Char.Parent and k.Char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local u = math.clamp((el - k.Delay) / (SUCK - k.Delay - 0.15), 0, 1)
				local e = u ^ 2.4
				local off = Vector3.new(math.cos(k.Spin + el * 5), 0, math.sin(k.Spin + el * 5)) * 7 * math.sin(u * math.pi)
				hrp.CFrame = CFrame.new(k.From:Lerp(portal, e) + off + UP * 4 * math.sin(u * math.pi)) * CFrame.Angles(el * 3, el * 7, 0)
			end
		end
		task.wait()
	end
	if not valid() then cleanup(false) return false end
	Net.Send(FX, "Warp", { Time = 2 })
	task.wait(0.45)

	buildFloor()
	workspace:SetAttribute("NothingDimension", true)
	state.Phase = "Space"
	state.Look = nil
	state.Goal = Vector3.new(cx, floorY + 9, cz)
	state.Snap = true
	list = c.Targets()
	for i, char in ipairs(list) do
		local a = (i - 1) / math.max(#list, 1) * TAU + math.pi / 2
		local p = Vector3.new(cx + math.cos(a) * R * 0.5, floorY + 3.2, cz + math.sin(a) * R * 0.5)
		local hrp = char.HumanoidRootPart
		hrp.CFrame = CFrame.lookAt(p, Vector3.new(cx, p.Y, cz))
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
	Net.Send(FX, "Space", { Boss = actor, Center = space, Radius = R, Core = SB.Core })
	task.wait(0.9)
	for _, k in ipairs(caught) do
		local hrp = k.Char.Parent and k.Char:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.Anchored = false end
	end
	state.Anchored = {}
	task.wait(0.8)
	if not valid() then cleanup(false) return false end

	Net.Send(FX, "Declare", { Boss = actor, Title = "Last Imagination", Name = "「Universe of the Nothing」" })
	pcall(Encounter.Say, line("FA9"), nil, { Duration = 2.6, LyricSoundtrack = true })
	task.wait(0.9)
	local startAt = workspace:GetServerTimeNow() + SB.Lead
	actor:SetAttribute("SonicBlasterMusicStartedAt", startAt)
	actor:SetAttribute("SonicBlasterHush", nil)
	Net.Send(FX, "Start", { Boss = actor, Center = space, Radius = R, Core = SB.Core, StartAt = startAt, Length = SB.Length, End = SB.End })

	local profile = Difficulty.Get(actor) or {}
	local DENS = math.clamp((profile.Density or 1) * 0.82 * (Difficulty.Enraged() and 1.15 or 1), 0.5, 1.4)
	local DMG = math.clamp(profile.Damage or 1, 0.3, 3)
	local SPD = math.clamp(profile.ProjectileSpeed or 1, 0.8, 1.25)
	local TELL = math.clamp(profile.Telegraph or 1, 0.7, 1.4)
	local function n(x) return math.max(1, math.floor(x * DENS + 0.5)) end
	local function v(x) return x * SPD end

	 -- the bullets, lasers and columns the server keeps (the same ones every client draws)
	local bullets, byId, lasers, columns = {}, {}, {}, {}
	local nextId = 0
	local outgoing, outLasers, outColumns = {}, {}, {}
	local function emit(d, songT)
		nextId += 1
		d.Id = nextId
		d.T = startAt + songT + (d.Late or 0)
		d.Late = nil
		d.X = d.X or cx
		d.Z = d.Z or cz
		for _, b in ipairs(SB.Expand(d)) do
			bullets[#bullets + 1] = b
			byId[b.id] = b
		end
		outgoing[#outgoing + 1] = d
	end
	local function laser(l, songT)
		nextId += 1
		l.Id = nextId
		l.X = l.X or cx
		l.Z = l.Z or cz
		l.T = startAt + songT
		l.On = l.T + (l.Warn or 1.2) * (l.Exact and 1 or TELL)
		l.Off = startAt + l.Until
		l.Len = l.Len or R + 16
		l.Wid = l.Wid or 3.2
		l.Warn, l.Until = nil, nil
		lasers[l.Id] = l
		outLasers[#outLasers + 1] = l
	end
	 -- a column: a warning circle on the floor, then a pillar of light (Phase 1's Falling Blade, Phase 5's falling stars)
	local function column(col, songT)
		nextId += 1
		col.Id = nextId
		col.T = startAt + songT
		col.On = col.T + (col.Warn or 1) * TELL
		col.Off = col.On + (col.Last or 0.5)
		col.Warn, col.Last = nil, nil
		columns[col.Id] = col
		outColumns[#outColumns + 1] = col
	end
	local function targets() return c.Targets() end
	local function aimFrom(char, x, z)
		local p = char.HumanoidRootPart.Position
		return math.atan2(p.Z - z, p.X - x)
	end
	local function aim(char) return aimFrom(char, cx, cz) end
	local function randomTarget()
		local all = targets()
		return all[math.random(1, math.max(#all, 1))]
	end
	local function rim(a, r)
		r = r or R - 2
		return cx + math.cos(a) * r, cz + math.sin(a) * r
	end

	 -- the schedule: song time -> what fires
	local events = {}
	local function at(t, fn) events[#events + 1] = { t = t, fn = fn } end
	local beats = SB.Beats
	local function half(i) return ((beats[i + 1] or beats[i] + SB.Beat) - beats[i]) / 2 end
	local spiral, counter, golden, liAng = 0, 0, 0, 0
	local clockBase, clockDir = math.random() * TAU, 1
	local first = {}
	local mirrors
	local PATTERN = {}

	 -- heading A), so crescents, lines and rings of points are the cheapest way to make a pattern LOOK like something.
	 -- a crescent moon, its convex side leading along heading `a`, born at (x, z)
	local function crescent(x, z, a, r, span, nOut, nIn)
		local pts = {}
		local ca, sa = math.cos(a), math.sin(a)
		local function put(lx, lz)
			pts[#pts + 1] = x + lx * ca - lz * sa
			pts[#pts + 1] = z + lx * sa + lz * ca
		end
		local c0 = -r * 0.28
		local ex, ez = r * math.cos(span), r * math.sin(span)
		local r2 = math.sqrt((ex - c0) ^ 2 + ez ^ 2)
		local phi = math.atan2(ez, ex - c0)
		for q = 0, nOut do
			local th = -span + 2 * span * q / nOut
			put(r * math.cos(th), r * math.sin(th))
		end
		for q = 1, nIn - 1 do
			local ph = -phi + 2 * phi * q / nIn
			put(c0 + r2 * math.cos(ph), r2 * math.sin(ph))
		end
		return pts
	end
	 -- the angle from the middle to the nearest player (a ring's gap points near it, so there is always one way through)
	local function nearestAng()
		local best, bd
		for _, ch in ipairs(targets()) do
			local p = ch.HumanoidRootPart.Position
			local d = (p.X - cx) ^ 2 + (p.Z - cz) ^ 2
			if not bd or d < bd then best, bd = math.atan2(p.Z - cz, p.X - cx), d end
		end
		return best or math.random() * TAU
	end
	 -- a spot on the stage at least `minD` from every player
	local function spotAway(minD)
		local all = targets()
		for _ = 1, 14 do
			local a, rr = math.random() * TAU, SB.Core + 14 + math.sqrt(math.random()) * (R * 0.8 - SB.Core - 14)
			local x, z = cx + math.cos(a) * rr, cz + math.sin(a) * rr
			local ok = true
			for _, ch in ipairs(all) do
				local p = ch.HumanoidRootPart.Position
				if (p.X - x) ^ 2 + (p.Z - z) ^ 2 < minD * minD then ok = false break end
			end
			if ok then return x, z end
		end
		local a = math.random() * TAU
		return cx + math.cos(a) * R * 0.6, cz + math.sin(a) * R * 0.6
	end
	 -- a star shell: a heavy orb and a ring of bullets hang frozen at (x, z), then burst `wait` seconds later - the ring
	 -- outwards, the orb at the nearest player
	local function shell(x, z, tb, wait, count, color)
		local go = startAt + tb + wait
		local who
		local bd = math.huge
		for _, ch in ipairs(targets()) do
			local p = ch.HumanoidRootPart.Position
			local d = (p.X - x) ^ 2 + (p.Z - z) ^ 2
			if d < bd then who, bd = p, d end
		end
		emit({ X = x, Z = z, N = 1, A = 0, V = 0, K = 3, C = 2, Fz = startAt + tb, Go = go, Gm = who and 2 or 1, Gx = who and who.X, Gz = who and who.Z, Gs = v(13) }, tb)
		emit({ X = x, Z = z, Rr = 2.6, N = count, A = math.random() * TAU, V = 0, K = 1, C = color, Fz = startAt + tb, Go = go, Gm = 3, Cx = x, Cz = z, Gs = v(16) }, tb)
	end

	local function beam(x, z, a, tb, o)
		local warn = (o.Beats or 3) * SB.Beat
		laser({ X = x, Z = z, A = a, W = o.W or 0, Len = o.Len or (2 * R + 8), Wid = o.Wid or 3.4, C = o.C or 1, Exact = true,
			Warn = warn, Until = tb + warn + (o.Burn or 0.55) }, tb)
	end
	 -- Prologue: starlight drifting in from the rim, his slow rings
	function PATTERN.Prologue(i, tb)
		at(tb, function()
			local a0 = i * 0.9
			for k = 0, 2 do
				local a = a0 + k * TAU / 3
				local x, z = rim(a)
				emit({ X = x, Z = z, N = n(5), S = 0.55, A = a + math.pi, V = v(17), K = 1, C = 1 }, tb)
			end
			if i % 2 == 0 then emit({ N = n(16), A = i * 0.13, V = v(14), K = 2, C = 2 }, tb) end
		end)
	end
	 -- Gilded Sign 「Crescent Requiem」 (Phase 1): crescent moons slide at you - walk round their horns - between thin fans of
	 -- rice; every eighth beat a great orange moon and, one bar on, three at once; golden blades fall on you
	function PATTERN.Gilded(i, tb)
		first.Gilded = first.Gilded or i
		local k = i - first.Gilded
		at(tb, function()
			local all = targets()
			local who = all[(k % math.max(#all, 1)) + 1]
			if who then
				local a = aim(who)
				if k % 2 == 0 then
					local big = k % 8 == 0
					emit({ P = crescent(cx, cz, a, big and 11 or 8, 2.3, math.max(12, n(big and 26 or 18)), math.max(7, n(big and 14 or 10))),
						A = a, V = v(big and 19 or 24), K = 1, C = big and 9 or 1 }, tb)
				else
					emit({ N = n(9), S = 0.9, A = a, V = v(27), K = 4, C = 9 }, tb)
				end
				if k % 8 == 4 then
					for q = -1, 1, 2 do
						emit({ P = crescent(cx, cz, a + q * 0.62, 7, 2.3, math.max(10, n(16)), math.max(6, n(9))), A = a + q * 0.62, V = v(22), K = 1, C = 1, Late = 0.04 }, tb)
					end
				end
			end
			if SB.Kick[i] >= 8 then emit({ N = n(18), A = i * 0.21, V = v(14), K = 2, C = 2 }, tb) end
		end)
		if k % 8 == 6 then  -- three golden lances from the rim, fanned across where you stand
			at(tb, function()
				local who = randomTarget()
				if not who then return end
				local rx, rz = rim(aim(who) + (math.random() < 0.5 and 1 or -1) * (0.9 + math.random() * 0.5))
				local base = aimFrom(who, rx, rz)
				for q = -1, 1 do beam(rx, rz, base + q * 0.3, tb, { C = 1, Wid = 2.6, Beats = 3, Burn = 0.5 }) end
			end)
		end
		local t = tb + half(i)
		local a = spiral
		spiral += 0.37
		at(t, function() emit({ N = 3, A = a, V = v(20), K = 4, C = 1 }, t) end)
		if k % 4 == 2 then
			at(tb, function()
				for _, char in ipairs(targets()) do
					local p = char.HumanoidRootPart.Position
					column({ X = p.X, Z = p.Z, R = 10, C = 1, Warn = 1.05 }, tb)
				end
			end)
		end
	end
	 -- Clock Sign 「Hour Hands of the Golden Clock」 (Phase 2): the minute hand TICKS - every second beat it drops on the next
	 -- of the twelve marks (the warning line shows where) - the hour hand creeps round, and rings of twelve snap their
	function PATTERN.Clock(i, tb)
		if not first.Clock then
			first.Clock = i
			local s0 = SB.Sections[3].At
			at(s0, function()
				Net.Send(FX, "ClockFace", { Until = startAt + 65.3 })
				laser({ A = math.random() * TAU, W = 0.16, Until = 65.0, C = 6, Wid = 4.6, Len = R * 0.62, Warn = 2.2 }, s0)
			end)
		end
		local k = i - first.Clock
		if k % 2 == 0 then
			at(tb, function()
				local step = k // 2
				local ang = clockBase + step * (TAU / 12) * clockDir
				laser({ A = ang, W = 0, Len = R + 6, Wid = 3.8, Warn = 0.75, Until = tb + 0.75 * TELL + 0.42, C = 1 }, tb)
				if step % 12 == 11 then clockDir = -clockDir end
				Net.Send(FX, "Tick", { Ang = ang, At = startAt + tb + 0.75 * TELL })
			end)
		end
		at(tb, function()
			if k % 2 == 1 then
				local g = math.floor(nearestAng() / (TAU / 12) + 0.5) * (TAU / 12) + (math.random() < 0.5 and 1 or -1) * (TAU / 12)
				emit({ N = n(24), S = TAU * 0.87, A = g + math.pi, V = v(12), K = 2, C = 6 }, tb)
			else
				emit({ N = n(12), A = (k % 12) * TAU / 12 + k * 0.05, V = v(6), Acc = v(15), Vmax = v(32), K = 5, C = 1 }, tb)
			end
			if SB.Kick[i] >= 8 then emit({ N = n(16), A = i * 0.3, V = v(13), K = 3, C = 1 }, tb) end
		end)
		if k % 4 == 3 then
			at(tb, function()
				local who = randomTarget()
				if not who then return end
				for _ = 1, 2 do
					local x, z = rim(math.random() * TAU)
					emit({ X = x, Z = z, N = 6, A = aimFrom(who, x, z), V = v(50), Dl = 0.05, K = 4, C = 2 }, tb)
				end
			end)
		end
	end
	 -- Time Sign 「The World Stands Still」 (Phase 2): rings of knives hang round you; at the stop they freeze, at the drop
	function PATTERN.World(i, tb)
		local per = tb < 72 and 1 or tb < 76 and 2 or 3
		local step = ((beats[i + 1] or tb + SB.Beat) - tb) / per
		local freeze, drop = startAt + 79.482, startAt + 79.9
		for k = 0, per - 1 do
			local t = tb + k * step
			if t < 79.3 then
				local a = golden
				golden += 2.39996
				at(t, function()
					emit({ N = n(7), A = a, V = v(18), K = 1, C = 6, Fz = freeze, Go = drop, Gm = 1, Gs = v(10), Gacc = v(10), Seed = i * 7 + k }, t)
					if k == 0 then
						local who = randomTarget()
						if who then
							local p = who.HumanoidRootPart.Position
							emit({ X = p.X, Z = p.Z, Rr = 15, In = true, N = n(10), A = math.random() * TAU, V = v(3), K = 6, C = 1,
								Fz = startAt + t + 0.3, Go = drop, Gm = 4, Gx = p.X, Gz = p.Z, Gs = v(38) }, t)
						end
					end
				end)
			end
		end
	end
	 -- Illusion Sign 「One Hundred Faces」 (Phase 3): three mirrors circle the stage; every card they fire BOUNCES off the rim
	 -- and comes back, so each shot is two - and a ring of reflections from him on every fourth beat
	function PATTERN.Illusion(i, tb)
		if not first.Illusion then
			first.Illusion = i
			local s0 = SB.Sections[5].At
			mirrors = { X = cx, Z = cz, R = R * 0.6, W = 0.26, A0 = math.random() * TAU, T0 = startAt + s0, Count = 3 }
			at(s0 - 0.6, function() Net.Send(FX, "Mirrors", { M = mirrors, Until = startAt + 94.3 }) end)
		end
		local k = i - first.Illusion
		at(tb, function()
			local now = startAt + tb
			for q = 1, mirrors.Count do
				local x, z = SB.Mirror(mirrors, q, now)
				emit({ X = x, Z = z, N = n(5), A = i * 0.31 + q, V = v(19), K = 7, C = (q + i) % 2 == 0 and 5 or 3, Bn = 1 }, tb)
			end
			if i % 2 == 0 then emit({ N = n(20), A = (i % 4) * math.pi / 20 + i * 0.02, V = v(21), K = 1, C = i % 4 == 0 and 1 or 7 }, tb) end
			if SB.Kick[i] >= 8 then emit({ N = n(9), A = i * 0.37, V = v(12), K = 3, C = 5 }, tb) end
			if k % 4 == 0 then
				emit({ N = n(14), A = i * 0.2, V = v(16), K = 7, C = 2, Bn = 1 }, tb)
				for q = 1, mirrors.Count do
					local x, z = SB.Mirror(mirrors, q, now)
					local who = randomTarget()
					if who then emit({ X = x, Z = z, N = n(5), S = 0.45, A = aimFrom(who, x, z), V = v(34), K = 7, C = 2 }, tb) end
				end
			end
		end)
		if k % 8 == 4 then  -- each mirror opens a beam on you from where it will be when it fires (crossfire)
			at(tb, function()
				local fireAt = startAt + tb + 3 * SB.Beat
				for q = 1, mirrors.Count do
					local x, z = SB.Mirror(mirrors, q, fireAt)
					local who = randomTarget()
					if who then beam(x, z, aimFrom(who, x, z), tb, { C = q % 2 == 0 and 3 or 5, Wid = 2.8, Beats = 3, Burn = 0.55 }) end
				end
			end)
		end
	end
	 -- Thread Sign 「Gilded Loom」 (Phase 1.5): WEAVING - gilded warp threads sweep across the stage, then the weft crosses
	 -- them at a right angle (each with one gap); serpents of knives snake at you; taut thread lasers
	function PATTERN.Thread(i, tb)
		first.Thread = first.Thread or i
		local k = i - first.Thread
		if k % 4 == 0 then
			local wall = k // 4
			at(tb, function()
				local ang = (wall % 2 == 0 and 0.4 or 0.4 + math.pi / 2) + (wall // 2) * 0.55
				local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
				local perp = Vector3.new(-dir.Z, 0, dir.X)
				local gap = math.sin(wall * 1.9 + 0.6) * R * 0.5
				local pts = {}
				for s = -R, R, 3.4 do
					if math.abs(s - gap) > 9 then
						local p = Vector3.new(cx, 0, cz) + dir * (-R - 4 + math.sin(s * 0.08 + wall) * 7) + perp * s
						pts[#pts + 1] = p.X
						pts[#pts + 1] = p.Z
					end
				end
				emit({ P = pts, A = ang, V = v(25), K = 5, C = wall % 2 == 0 and 1 or 9 }, tb)
			end)
		end
		if k % 4 == 2 then
			at(tb, function()
				local who = randomTarget()
				if not who then return end
				for q = -1, 1, 2 do
					local x, z = rim(aim(who) + q * 1.2 + (math.random() - 0.5) * 0.4)
					emit({ X = x, Z = z, N = 9, A = aimFrom(who, x, z), V = v(24), Dl = 0.07, K = 6, C = 1, Sa = 2.6, Sf = 5.2 }, tb)
				end
			end)
		end
		if k % 8 == 6 then
			at(tb, function()
				local a = math.random() * TAU
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				local perp = Vector3.new(-dir.Z, 0, dir.X)
				for q = -1, 1 do
					local start = Vector3.new(cx, 0, cz) - dir * (R + 4) + perp * (q * R * 0.3 + (math.random() - 0.5) * 8)
					laser({ X = start.X, Z = start.Z, A = a, W = 0, Len = 2 * R + 8, Wid = 2.6, Warn = 1.3, Until = tb + 1.3 * TELL + 1.1, C = 1 }, tb)
				end
			end)
		end
		if k % 8 == 2 then  -- the loom: five warp beams, and two beats later five weft beams across them
			local a = math.random() * TAU
			for set = 0, 1 do
				local t0 = tb + set * 2 * SB.Beat
				at(t0, function()
					local ang = a + set * math.pi / 2
					local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
					local perp = Vector3.new(-dir.Z, 0, dir.X)
					for q = -2, 2 do
						local start = Vector3.new(cx, 0, cz) - dir * (R + 4) + perp * (q * R * 0.36)
						beam(start.X, start.Z, ang, t0, { C = set == 0 and 1 or 9, Wid = 2.8, Len = 2 * R + 8, Beats = 3, Burn = 0.5 })
					end
				end)
			end
		end
		at(tb, function()
			for _, char in ipairs(targets()) do emit({ N = 1, A = aim(char), V = v(32), K = 2, C = 1 }, tb) end
			if SB.Kick[i] >= 8 then emit({ N = n(14), A = i * 0.3, V = v(16), K = 1, C = 4 }, tb) end
		end)
	end
	 -- Space Sign 「Supernova Constellation」 (Phase 4/5), 34 seconds in four motions that repeat: a GALAXY of curving arms
	 -- - STAR SHELLS that hang frozen and burst - five-pointed constellations that swell - a LATTICE of rings that freeze and
	 -- each turn a quarter-turn; two long beams turn over it all and falling stars come down on you
	function PATTERN.Cosmos(i, tb)
		if not first.Cosmos then
			first.Cosmos = i
			local s0 = SB.Sections[7].At
			at(s0, function()
				local a0 = math.random() * TAU
				for q = 0, 1 do laser({ A = a0 + q * math.pi, W = 0.3, Until = 123.9, C = 5, Wid = 3.6, Len = R + 6 }, s0) end
			end)
			at(123.92, function()
				local a0 = math.random() * TAU
				for q = 0, 1 do laser({ A = a0 + q * math.pi, W = -0.36, Until = 140.6, C = 3, Wid = 3.6, Len = R + 6 }, 123.92) end
			end)
		end
		local k = i - first.Cosmos
		local motion = (k // 8) % 4
		at(tb, function()
			if motion == 0 then  -- the galaxy: every ring turns as it flies, so the arms curl
				local dir = (k // 4) % 2 == 0 and 1 or -1
				emit({ N = n(5), A = i * 0.3, V = v(19), W = 0.55 * dir, K = 1, C = 5 }, tb)
				emit({ N = n(5), A = i * 0.3 + 0.6, V = v(14), W = -0.45 * dir, K = 1, C = 7, Late = 0.05 }, tb)
			elseif motion == 1 then
				if k % 2 == 0 then emit({ Shape = "Star", N = n(4), Rr = 4, A = i * 0.4, V = v(24), K = 2, C = k % 4 == 0 and 1 or 5 }, tb) end
			elseif motion == 2 then
				if k % 2 == 0 then
					local x, z = spotAway(46)
					shell(x, z, tb, 1.15, n(22), k % 4 == 0 and 7 or 5)
				end
			else
				if k % 2 == 0 then
					emit({ N = n(20), A = i * 0.17, V = v(16), Fz = startAt + tb + 0.75, Go = startAt + tb + 1.25, Gm = 5, Gs = v(17), K = 1, C = k % 4 == 0 and 6 or 7, Seed = i }, tb)
				end
			end
			if SB.Kick[i] >= 8 then emit({ N = n(10), A = i * 0.5, V = v(13), K = 3, C = 3 }, tb) end
			if k % 16 == 8 then  -- a pentagram of beams drawn between five stars (it warns four beats)
				local r0, a0 = R * 0.72, k * 0.21
				for q = 0, 4 do
					local pa, qa = a0 + q * TAU / 5, a0 + ((q + 2) % 5) * TAU / 5
					local px, pz = cx + math.cos(pa) * r0, cz + math.sin(pa) * r0
					local qx, qz = cx + math.cos(qa) * r0, cz + math.sin(qa) * r0
					beam(px, pz, math.atan2(qz - pz, qx - px), tb, { C = 5, Wid = 3, Len = math.sqrt((qx - px) ^ 2 + (qz - pz) ^ 2), Beats = 4, Burn = 0.6 })
				end
			end
			if k % 4 == 1 then
				for _, char in ipairs(targets()) do
					local p = char.HumanoidRootPart.Position
					column({ X = p.X, Z = p.Z, R = 11, C = 5, Warn = 1.0 }, tb)
				end
			end
		end)
		if SB.Hat[i] >= 7 and motion ~= 2 then
			local t = tb + half(i)
			local a = spiral
			spiral += 0.5
			at(t, function() emit({ N = 3, A = a, V = v(26), K = 1, C = 1 }, t) end)
		end
	end
	 -- 「Galaxy in a Breath」: he INHALES - a ring closes in from the rim with one way through - and EXHALES - a ring leaves him
	function PATTERN.Breath(i, tb)
		first.Breath = first.Breath or i
		local k = i - first.Breath
		if k % 4 == 0 then
			at(tb, function()
				local g = nearestAng() + (math.random() - 0.5) * 0.7
				if (k // 4) % 2 == 0 then
					emit({ X = cx, Z = cz, Rr = R - 6, In = true, N = n(46), S = TAU * 0.9, A = g + math.pi, V = v(9), K = 1, C = 4 }, tb)
				else
					emit({ N = n(34), S = TAU * 0.88, A = g + math.pi, V = v(11), K = 2, C = 2 }, tb)
				end
			end)
		end
		if tb >= 146.5 then
			at(tb, function() emit({ N = n(12), A = i * 0.5, V = v(16), K = 3, C = 1 }, tb) end)
		else
			at(tb, function()
				emit({ N = 4, A = i * 0.31, V = v(8), Acc = v(4), Vmax = v(22), K = 1, C = 5 }, tb)
				emit({ N = 4, A = -i * 0.31, V = v(8), Acc = v(4), Vmax = v(22), K = 1, C = 4 }, tb)
			end)
		end
	end
	 -- Last Imagination 「Return to Nothing」 (2:28 - 2:50): the black hole hangs behind the stage and the real last attack
	 -- begins, in four movements on the beat:
	 --   1 Accretion    - seven arms of light wind off him, turning the other way every bar
	 --   2 Gravity Lens - light streams across the stage into the hole in snaking lanes; two jets sweep like scissors
	 --   3 Event Horizon- rings close in from the rim with two ways through, kunai on every hard kick
	 --   4 Singularity  - the last five beats: a ring on every one, each faster and wider, its gap near you
	local HOLE_DIR = -math.pi / 2
	function PATTERN.BlackHole(i, tb)
		first.BlackHole = first.BlackHole or i
		local k = i - first.BlackHole
		local part = tb < 155.1 and 1 or tb < 162.6 and 2 or tb < 168.6 and 3 or 4
		if part == 1 then
			if not first.Spokes then
				first.Spokes = true
				at(tb, function()  -- three slow spokes of light turn round him
					local a0 = math.random() * TAU
					for q = 0, 2 do laser({ A = a0 + q * TAU / 3, W = 0.2, Until = 154.9, C = 7, Wid = 3.4, Len = R + 6, Warn = 1.7 }, tb) end
				end)
			end
			at(tb, function()
				local dir = (k // 4) % 2 == 0 and 1 or -1
				liAng += 0.45
				emit({ N = n(7), A = liAng, V = v(14), W = 0.5 * dir, K = 4, C = k % 2 == 0 and 7 or 5 }, tb)
				if SB.Kick[i] >= 7 then emit({ N = n(6), A = liAng + 0.2, V = v(9), K = 3, C = 1 }, tb) end
				if k % 4 == 2 then emit({ N = n(24), A = liAng, V = v(18), K = 2, C = 2 }, tb) end
			end)
		elseif part == 2 then
			if tb < 155.1 + 0.5 and not first.Jets then
				first.Jets = true
				at(155.1, function()
					laser({ X = cx - 46, Z = cz + R - 2, A = HOLE_DIR, W = 0.07, Len = 2 * R, Wid = 3.6, Until = 162.5, C = 3, Warn = 1.8 }, 155.1)
					laser({ X = cx + 46, Z = cz + R - 2, A = HOLE_DIR, W = -0.07, Len = 2 * R, Wid = 3.6, Until = 162.5, C = 6, Warn = 1.8 }, 155.1)
					laser({ X = cx - 100, Z = cz + R - 2, A = HOLE_DIR, W = -0.045, Len = 2 * R, Wid = 2.8, Until = 162.5, C = 5, Warn = 2.2 }, 155.1)
					laser({ X = cx + 100, Z = cz + R - 2, A = HOLE_DIR, W = 0.045, Len = 2 * R, Wid = 2.8, Until = 162.5, C = 1, Warn = 2.2 }, 155.1)
				end)
			end
			at(tb, function()
				local sh = math.sin(k * 0.7) * R * 0.14
				for q = -3, 3 do
					local x = cx + q * R * 0.25 + sh
					emit({ X = x, Z = cz + R - 4, N = 3, A = HOLE_DIR, V = v(18), Dl = 0.12, K = 4, C = 6, Sa = 1.7, Sf = 3, Sp = q * 0.8 }, tb)
				end
				if SB.Hat[i] >= 7 then
					local who = randomTarget()
					if who then emit({ N = 3, S = 0.3, A = aim(who), V = v(30), K = 6, C = 2 }, tb) end
				end
			end)
		elseif part == 3 then
			if k % 4 == 0 then  -- four spokes, then the four between them on the next bar
				at(tb, function()
					local off = (k // 4) % 2 == 0 and 0 or TAU / 8
					for q = 0, 3 do beam(cx, cz, 0.3 + off + q * TAU / 4, tb, { C = (k // 4) % 2 == 0 and 3 or 6, Wid = 3.2, Len = R + 6, Beats = 3, Burn = 0.5 }) end
				end)
			end
			if k % 4 == 0 then
				at(tb, function()
					local g = nearestAng() + (math.random() - 0.5) * 1.2
					emit({ X = cx, Z = cz, Rr = R - 5, In = true, N = n(26), S = TAU * 0.42, A = g, V = v(10), K = 2, C = 7 }, tb)
					emit({ X = cx, Z = cz, Rr = R - 5, In = true, N = n(26), S = TAU * 0.42, A = g + math.pi, V = v(10), K = 2, C = 7 }, tb)
				end)
			end
			at(tb, function()
				emit({ N = n(5), A = i * 0.41, V = v(12), W = -0.4, K = 1, C = 5 }, tb)
				if SB.Kick[i] >= 7 then
					local who = randomTarget()
					if who then emit({ N = n(5), S = 0.5, A = aim(who), V = v(34), K = 6, C = 2 }, tb) end
				end
			end)
		else
			local last = tb >= SB.Last - 0.6
			if not first.Burst then
				first.Burst = true
				at(tb, function()  -- twelve spokes at once, warned four beats, burning just before the hole takes everything
					local g0 = nearestAng() + TAU / 24
					for q = 0, 11 do beam(cx, cz, g0 + q * TAU / 12, tb, { C = q % 2 == 0 and 1 or 7, Wid = 3, Len = R + 6, Beats = 4, Burn = 0.5 }) end
				end)
			end
			at(tb, function()
				local step = math.min(1, (tb - 168.6) / 2.3)
				local g = nearestAng() + (math.random() - 0.5) * 0.6
				emit({ N = n(30), S = TAU * 0.9, A = g + math.pi, V = v(14 + 14 * step), K = last and 3 or 2, C = last and 1 or 7 }, tb)
				emit({ N = n(18), S = TAU * 0.9, A = g + math.pi + 0.18, V = v(10 + 10 * step), K = 1, C = 2, Late = 0.06 }, tb)
			end)
		end
	end
	for i, tb in ipairs(beats) do
		if tb >= SB.Last - 0.05 then break end
		local sec = SB.Section(tb).Id
		if PATTERN[sec] then PATTERN[sec](i, tb) end
	end
	for _, s in ipairs(SB.Sections) do
		if s.At > 0 and s.Title ~= "" then
			at(math.max(0, s.At - 0.05), function() Net.Send(FX, "Section", { Title = s.Title, Id = s.Id }) end)
		end
	end
	at(79.482, function() Net.Send(FX, "Accent", { Kind = "Freeze" }) end)
	at(79.90, function() Net.Send(FX, "Accent", { Kind = "Drop" }) end)
	at(106.81, function() Net.Send(FX, "Accent", { Kind = "Drop" }) end)
	at(155.1, function() Net.Send(FX, "Accent", { Kind = "Drop" }) end)
	at(162.6, function() Net.Send(FX, "Accent", { Kind = "Drop" }) end)

	 -- 4. 2:28: the black hole opens behind the stage and Last Imagination begins; at SB.Last every bullet is drawn into it,
	 -- he says his last words (FAREWELL, spoken over the attack), and at SB.FlyAt he flies in
	local bh = Vector3.new(cx, floorY + 30, cz - 262)
	at(SB.End, function()
		state.Look = bh
		Net.Send(FX, "BlackHole", { Boss = actor, Pos = bh, At = startAt + SB.End, Fly = startAt + SB.FlyAt, Gone = startAt + SB.GoneAt })
	end)
	at(SB.Last, function()
		state.Phase = "BlackHole"
		table.clear(bullets)
		table.clear(byId)
		table.clear(columns)
		local now = workspace:GetServerTimeNow()
		for _, l in pairs(lasers) do l.Off = math.min(l.Off, now) end
		Net.Send(FX, "Cancel", { Into = bh })
		state.Goal = Vector3.new(cx, floorY + 22, cz) + (bh - Vector3.new(cx, bh.Y, cz)).Unit * 20
	end)
	for _, f in ipairs(FAREWELL) do
		at(f[2], function() pcall(Encounter.Say, line(f[1]), nil, { Duration = f[3] }) end)
	end
	at(SB.FlyAt, function()
		state.Fly = { From = root.Position, To = bh, T0 = startAt + SB.FlyAt, T1 = startAt + SB.GoneAt }
		Net.Send(FX, "Fly", { Boss = actor, From = root.Position, To = bh, T0 = startAt + SB.FlyAt, T1 = startAt + SB.GoneAt })
	end)
	at(SB.GoneAt, function()
		actor:SetAttribute("FinalVanished", true)
		Net.Send(FX, "Vanish", { Boss = actor, Pos = bh })
	end)
	table.sort(events, function(a, b) return a.t < b.t end)

	local immune = {}
	 -- a MISS: the hit would have killed, so consume one star. If this is the last star, defeat the player
	 -- through the encounter's normal life system; otherwise restore health and grant a brief grace period.
	local function miss(char, player, hum)
		local key = player or char
		immune[key] = os.clock() + SB.MissGrace
		local lives = player and player:GetAttribute("LivesRemaining")
		local last = type(lives) ~= "number" or lives <= 1
		if last and player then
			require(B.Players.PlayerEncounter).ExhaustLives(player, "Last star lost in Phase 5 final attack")
			local p = char:FindFirstChild("HumanoidRootPart")
			Net.Send(FX, "Miss", { Char = char, X = p and p.Position.X or cx, Z = p and p.Position.Z or cz,
				R = SB.MissClear, Lives = 0, Last = true, At = workspace:GetServerTimeNow(), Grace = SB.MissGrace })
			return
		end
		if player then
			lives = math.floor(lives) - 1
			player:SetAttribute("LivesRemaining", lives)
			char:SetAttribute("LivesRemaining", lives)
		end
		hum.Health = hum.MaxHealth
		local now = workspace:GetServerTimeNow()
		char:SetAttribute("RespawnInvulnerableUntil", now + SB.MissGrace)
		local p = char.HumanoidRootPart.Position
		local r2 = SB.MissClear * SB.MissClear
		local i = 1
		while i <= #bullets do
			local b = bullets[i]
			if now >= b.t0 and (b.x - p.X) ^ 2 + (b.z - p.Z) ^ 2 < r2 then
				byId[b.id] = nil
				bullets[i] = bullets[#bullets]
				bullets[#bullets] = nil
			else
				i += 1
			end
		end
		Net.Send(FX, "Miss", { Char = char, X = p.X, Z = p.Z, R = SB.MissClear, Lives = lives, Last = last, At = now, Grace = SB.MissGrace })
	end
	local function hurt(char, frac, origin)
		local player = Players:GetPlayerFromCharacter(char)
		local key = player or char
		local t = os.clock()
		if (immune[key] or 0) > t then return false end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 or not Encounter.CanReceiveHit(char) then return false end
		immune[key] = t + SB.HitGrace
		 -- (an upper guess at what the hit deals: if it could kill, it is a miss instead)
		if hum.Health - hum.MaxHealth * frac * DMG * 1.25 <= 1 then
			miss(char, player, hum)
			return true
		end
		c.Hit(char, hum.MaxHealth * frac, origin)
		return true
	end
	local function bulletFrac(b)
		local kind = SB.Kinds[b.k] or SB.Kinds[1]
		return DAMAGE * (kind.Damage or 1)
	end
	local floorBullet = floorY + SB.Height
	report = remote.OnServerEvent:Connect(function(player, kind, id)
		if not valid() or type(id) ~= "number" then return end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local p = hrp.Position
		local now = workspace:GetServerTimeNow()
		if kind == "B" then
			local b = byId[id]
			if not b or now < b.t0 then return end
			local x, z = SB.Where(b, now)
			local slack = (SB.Kinds[b.k] or SB.Kinds[1]).Hit + PLAYER_R + 9
			if (x - p.X) ^ 2 + (z - p.Z) ^ 2 <= slack * slack then
				hurt(char, bulletFrac(b), Vector3.new(x, floorBullet, z))
			end
		elseif kind == "L" then
			local l = lasers[id]
			if not l or now < l.On - 0.15 or now > l.Off + 0.3 then return end
			hurt(char, LASER_DAMAGE, Vector3.new(l.X, floorBullet, l.Z))
		end
	end)

	 -- the stage keeps everyone on it; a fall or a respawn back in the arena puts them back on it
	local function contain(char)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp or hrp.Anchored then return end
		local p = hrp.Position
		local rel = Vector3.new(p.X - cx, 0, p.Z - cz)
		local d = rel.Magnitude
		if d > R + 60 or p.Y < floorY - 25 or p.Y > floorY + 250 then
			local a = math.random() * TAU
			local to = Vector3.new(cx + math.cos(a) * R * 0.45, floorY + 3.2, cz + math.sin(a) * R * 0.45)
			hrp.CFrame = CFrame.lookAt(to, Vector3.new(cx, to.Y, cz))
			hrp.AssemblyLinearVelocity = Vector3.zero
			char:SetAttribute("FinalAttackLocked", true)
			return
		end
		local dir = d > 0.01 and rel / d or Vector3.zAxis
		if d > R - 0.4 then
			hrp.CFrame = CFrame.lookAt(Vector3.new(cx, p.Y, cz) + dir * (R - 1.5), Vector3.new(cx, p.Y, cz))
			local vel = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = vel - dir * math.max(0, vel:Dot(dir))
		elseif d < SB.Core - 0.5 then
			hrp.CFrame = hrp.CFrame + dir * (SB.Core + 0.5 - d)
		end
	end

	local cursor = 1
	local frame = 0
	local finished = Instance.new("BindableEvent")
	beat = Run.Heartbeat:Connect(function()
		if state.Done then return end
		if not valid() then
			state.Done = true
			finished:Fire(false)
			return
		end
		local now = workspace:GetServerTimeNow()
		local songT = now - startAt
		while events[cursor] and events[cursor].t <= songT do
			local e = events[cursor]
			cursor += 1
			local ok, err = pcall(e.fn)
			if not ok then warn("[P5SonicBlaster] " .. tostring(err)) end
		end
		if #outgoing > 0 then
			Net.Send(FX, "Volley", { List = outgoing })
			outgoing = {}
		end
		if #outLasers > 0 then
			Net.Send(FX, "Laser", { List = outLasers })
			outLasers = {}
		end
		if #outColumns > 0 then
			Net.Send(FX, "Column", { List = outColumns })
			outColumns = {}
		end
		 -- move every bullet; drop the ones that are gone
		local i = 1
		while i <= #bullets do
			local b = bullets[i]
			local live = SB.Advance(b, now)
			if live and SB.Gone(b, now, cx, cz) then
				byId[b.id] = nil
				bullets[i] = bullets[#bullets]
				bullets[#bullets] = nil
			else
				i += 1
			end
		end
		for id, l in pairs(lasers) do
			if now > l.Off + 1 then lasers[id] = nil end
		end
		frame += 1
		local all = targets()
		for _, char in ipairs(all) do
			contain(char)
			if not char:GetAttribute("FinalAttackLocked") then char:SetAttribute("FinalAttackLocked", true) end
		end
		 -- the server's own (tighter) hit check, every other frame
		if frame % 2 == 0 and state.Phase == "Space" then
			for _, char in ipairs(all) do
				local p = char.HumanoidRootPart.Position
				local px, pz = p.X, p.Z
				for _, b in ipairs(bullets) do
					if now >= b.t0 then
						local dx, dz = b.x - px, b.z - pz
						if dx < 4 and dx > -4 and dz < 4 and dz > -4 then
							local r = (SB.Kinds[b.k] or SB.Kinds[1]).Hit * 0.55 + 0.3
							if dx * dx + dz * dz < r * r then
								hurt(char, bulletFrac(b), Vector3.new(b.x, floorBullet, b.z))
								break
							end
						end
					end
				end
				for _, l in pairs(lasers) do
					if now >= l.On + 0.1 and SB.LaserLive(l, now) then
						local a = SB.LaserAngle(l, now)
						local dx, dz = px - l.X, pz - l.Z
						local along = dx * math.cos(a) + dz * math.sin(a)
						local across = math.abs(-dx * math.sin(a) + dz * math.cos(a))
						if along > 0 and along < l.Len and across < l.Wid * 0.3 then
							hurt(char, LASER_DAMAGE, Vector3.new(l.X, floorBullet, l.Z))
						end
					end
				end
				for id, col in pairs(columns) do
					if now > col.Off then
						columns[id] = nil
					elseif now >= col.On + 0.05 and (px - col.X) ^ 2 + (pz - col.Z) ^ 2 < (col.R * 0.9) ^ 2 then
						hurt(char, COLUMN_DAMAGE, Vector3.new(col.X, floorBullet, col.Z))
					end
				end
			end
		end
		if songT >= SB.GoneAt then
			state.Done = true
			finished:Fire(true)
		end
	end)
	local survived = finished.Event:Wait()
	finished:Destroy()
	table.clear(bullets)
	table.clear(byId)
	cleanup(survived == true)
	if survived == true and actor.Parent then
		 -- the song plays on to its very end; then the music flags go
		task.delay(math.max(0, startAt + SB.Length - workspace:GetServerTimeNow()) + 0.5, function()
			if actor.Parent and not running[actor] then
				actor:SetAttribute("SonicBlasterActive", nil)
				actor:SetAttribute("SonicBlasterMusicStartedAt", nil)
			end
		end)
	end
	return survived == true and actor.Parent ~= nil and not actor:GetAttribute("EncounterEnded")
end

 -- ends it early (the encounter was reset)
function api.Cancel(actor)
	running[actor] = nil
end

return api
