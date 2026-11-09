local B = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local api = {}
local TAU = math.pi * 2
local MAX_AT_ONCE = 2
local MIN_GAP = 1.6
local state = setmetatable({}, { __mode = "k" })

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function chest(c)
	return c.Root.Position + Vector3.new(0, 0.6, 0)
end
local function alive(c, char)
	return char ~= nil and char.Parent ~= nil and c.Core.Alive(char)
end
 -- who to aim at: the attack's target, else anyone
local function pick(c, target)
	if alive(c, target) then
		return target
	end
	return c.RandomTarget()
end
 -- the flat direction from him to a player, a little ahead of where they are running
local function aim(c, char, lead)
	local root = char.HumanoidRootPart
	local v = root.AssemblyLinearVelocity
	local p = root.Position + Vector3.new(v.X, 0, v.Z) * (lead or 0.25)
	return flat(p - c.Root.Position)
end
local function dirOf(a)
	return Vector3.new(math.cos(a), 0, math.sin(a))
end

 -- N bolts spread over `Spread` degrees at the target (a fan); Gap seconds between bolts turns it into a rapid burst
local function fan(c, target, o)
	target = pick(c, target)
	if not target then
		return false
	end
	local n = o.N or 5
	for i = 1, n do
		if not c.Valid() then
			return false
		end
		local d = alive(c, target) and aim(c, target, o.Lead) or c.Root.CFrame.LookVector
		if d.Magnitude < 0.1 then
			d = c.Root.CFrame.LookVector
		end
		local base = math.atan2(d.Z, d.X)
		local t = n == 1 and 0 or ((i - 1) / (n - 1) - 0.5)
		if o.Flip then
			t = -t
		end
		local a = base + math.rad(o.Spread or 40) * t
		c.Bolt(chest(c), dirOf(a), { Speed = o.Speed or 90, Range = o.Range or 130, Radius = o.Radius or 2.4, Damage = o.Damage or 16,
			Look = o.Look, Pierce = o.Pierce, Deflect = "Tap" })
		if (o.Gap or 0) > 0 and i < n and not c.Wait(o.Gap) then
			return false
		end
	end
	return true
end

 -- N bolts out of him in a full circle
local function ring(c, o)
	if not c.Valid() then
		return false
	end
	local n = o.N or 12
	local base = o.Spin or math.random() * TAU
	for i = 1, n do
		c.Bolt(chest(c), dirOf(base + (i - 1) / n * TAU), { Speed = o.Speed or 70, Range = o.Range or 120, Radius = o.Radius or 2.4,
			Damage = o.Damage or 15, Look = o.Look, Deflect = "Tap" })
	end
	return true
end

 -- a ground shockwave out of (or, Inward, closing on) his feet
local function quake(c, o)
	if not c.Valid() then
		return false
	end
	c.Shockwave(c.Ground(c.Root.Position), { Speed = o.Speed or 55, Range = o.Range or 80, Width = o.Width or 3, Height = o.Height or 4,
		Damage = o.Damage or 26, Look = o.Look, Inward = o.Inward })
	return true
end

 -- crystal spikes under every player (and Around more points near each), after a warning circle
local function spikes(c, o)
	local points = {}
	for _, char in ipairs(c.Targets()) do
		local v = char.HumanoidRootPart.AssemblyLinearVelocity
		local p = c.Ground(char.HumanoidRootPart.Position + Vector3.new(v.X, 0, v.Z) * (o.Lead or 0.35))
		points[#points + 1] = p
		for _ = 1, (o.Around or 0) do
			local a = math.random() * TAU
			local r = (o.AroundRadius or 16) * (0.5 + math.random() * 0.5)
			points[#points + 1] = c.Ground(p + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
		end
	end
	if #points == 0 or not c.Valid() then
		return false
	end
	return c.Spikes(points, { Radius = o.Radius or 8, Warn = c.Tell(o.Warn or 1.4), Damage = o.Damage or 36, Tall = o.Tall,
		Count = o.Count, Hold = o.Hold, Height = 14 })
end

 -- a warning circle on every player's spot, then an explosion there (they can leave the circle in time)
local function blast(c, o)
	local points = {}
	for _, char in ipairs(c.Targets()) do
		points[#points + 1] = c.Ground(char.HumanoidRootPart.Position)
	end
	if #points == 0 or not c.Valid() then
		return false
	end
	local warn = c.Tell(o.Warn or 1.4)
	c.SpikeWarn(points, o.Radius or 14, warn)
	if not c.Wait(warn) then
		return false
	end
	for _, p in ipairs(points) do
		c.Explode(p, o.Radius or 14, o.Damage or 45, { Look = o.Look, Height = 16, Push = 30, Lift = 14, Shake = 0.9 })
	end
	return true
end

 -- a tall wall of force rolling out of him; it can't be jumped (hold deflect or dash through)
local function wall(c, o)
	if not c.Valid() then
		return false
	end
	c.WallWave(c.Ground(c.Root.Position), { Speed = o.Speed or 55, Range = o.Range or 100, Height = o.Height or 16, Width = o.Width or 6,
		Damage = o.Damage or 34 })
	return true
end

 -- flying claw blades from him at the target; Angles is a list of degrees off the direct line
local function claws(c, target, o)
	target = pick(c, target)
	if not target or not c.Valid() then
		return false
	end
	local d = aim(c, target, o.Lead)
	if d.Magnitude < 0.1 then
		d = c.Root.CFrame.LookVector
	end
	local base = math.atan2(d.Z, d.X)
	for i, deg in ipairs(o.Angles or { 0 }) do
		local dir = dirOf(base + math.rad(deg))
		c.FireClaw(CFrame.lookAt(chest(c), chest(c) + dir), { Speed = o.Speed or 160, Range = o.Range or 140, Width = o.Width or 20,
			Spread = o.Spread or 8, Roll = math.rad(o.Roll or 45) * (i % 2 == 1 and 1 or -1), Count = o.Count, Damage = o.Damage or 22,
			HitHalfWidth = o.Half or 8, HitHeight = 7, Deflect = "Tap" })
	end
	return true
end
local function wait(c, s)
	return c.Wait(s)
end

local EXTRA = {}
local function def(name, label, run)
	EXTRA[name] = { Label = label, Run = run }
end

def("P5ClawForward", "Echo Claws", function(c, t)
	if fan(c, t, { N = 7, Spread = 70, Speed = 100, Damage = 17, Look = "Gold" }) and wait(c, 0.45) then
		fan(c, t, { N = 7, Spread = 70, Speed = 100, Damage = 17, Look = "Gold", Flip = true })
	end
end)
def("P5Assassination", "Shadow Bloom", function(c, t)
	ring(c, { N = 10, Speed = 85, Damage = 16, Look = "Gold" })
	if wait(c, 0.5) then blast(c, { Radius = 13, Warn = 1.3, Damage = 42 }) end
end)
def("P5UpperCut", "Rising Edge", function(c, t)
	spikes(c, { Around = 3, AroundRadius = 16, Radius = 9, Warn = 1.3, Damage = 38, Tall = true })
end)
def("P5Butterfly", "Wing Storm", function(c, t)
	ring(c, { N = 12, Speed = 75, Damage = 14, Look = "Gold" })
	if wait(c, 0.4) then ring(c, { N = 12, Speed = 75, Damage = 14, Look = "Gold", Spin = math.pi / 12 + math.random() * TAU }) end
	if wait(c, 0.4) then ring(c, { N = 12, Speed = 75, Damage = 14, Look = "Gold" }) end
end)
def("P5DistortedCounter", "Warped Return", function(c, t)
	fan(c, t, { N = 9, Spread = 100, Speed = 105, Damage = 14 })
	if wait(c, 0.3) then quake(c, { Speed = 60, Range = 55, Damage = 24, Look = "Dark" }) end
end)
def("P5GoldenPierce", "Second Pierce", function(c, t)
	fan(c, t, { N = 3, Spread = 16, Speed = 190, Damage = 24, Pierce = true, Look = "Pierce", Gap = 0.18 })
end)
def("P5Slam", "Aftershock", function(c, t)
	quake(c, { Speed = 60, Range = 90, Damage = 28, Look = "Gold" })
	if wait(c, 0.55) then quake(c, { Speed = 75, Range = 90, Damage = 28, Look = "Dark" }) end
end)
def("P5Viper", "Venom Spit", function(c, t)
	fan(c, t, { N = 5, Spread = 34, Speed = 60, Damage = 16 })
	if wait(c, 0.4) then spikes(c, { Around = 2, AroundRadius = 14, Radius = 7, Warn = 1.2, Damage = 30 }) end
end)
def("P5HorrifyingGround", "Hands From Below", function(c, t)
	spikes(c, { Around = 5, AroundRadius = 20, Radius = 7, Warn = 1.5, Damage = 32, Count = 7 })
end)
def("P5ScarletRiver", "Crimson Tide", function(c, t)
	quake(c, { Speed = 50, Range = 110, Width = 5, Damage = 30, Look = "Dark" })
	if wait(c, 0.5) then fan(c, t, { N = 5, Spread = 50, Speed = 100, Damage = 16 }) end
end)
def("P5FireRing", "Closing Ring", function(c, t)
	quake(c, { Speed = 38, Range = 75, Inward = true, Damage = 26, Look = "Gold" })
	if wait(c, 0.6) then ring(c, { N = 8, Speed = 65, Damage = 15, Look = "Gold" }) end
end)
def("P5ShotgunBlast", "Buckshot", function(c, t)
	fan(c, t, { N = 13, Spread = 120, Speed = 115, Damage = 12 })
end)
def("P5PerfectVerticalSlash", "Crossing Slash", function(c, t)
	claws(c, t, { Angles = { -35, 35 }, Speed = 190, Damage = 24, Width = 24, Half = 9 })
	if wait(c, 0.5) then claws(c, t, { Angles = { 0 }, Speed = 220, Damage = 30, Width = 30, Half = 11 }) end
end)
def("P5Golden-matterBeam", "Matter Scatter", function(c, t)
	ring(c, { N = 14, Speed = 48, Damage = 16, Look = "Star" })
end)
def("P5DoubleGolden-matterBeam", "Matter Storm", function(c, t)
	ring(c, { N = 16, Speed = 50, Damage = 16, Look = "Star" })
	if wait(c, 0.6) then ring(c, { N = 16, Speed = 50, Damage = 16, Look = "Star", Spin = math.random() * TAU }) end
end)
def("P5JudgementZone", "Verdict", function(c, t)
	blast(c, { Radius = 18, Warn = 1.5, Damage = 55, Look = "Red" })
end)
def("P5NullifiedZone", "Null Spikes", function(c, t)
	spikes(c, { Around = 4, AroundRadius = 18, Radius = 7, Warn = 1.4, Damage = 34 })
end)
def("P5HellavanRampage", "Rampage Echo", function(c, t)
	wall(c, { Speed = 55, Range = 95, Height = 16, Damage = 36 })
end)
def("P5EnhancedBurst", "Burst Rebound", function(c, t)
	ring(c, { N = 12, Speed = 88, Damage = 15 })
	if wait(c, 0.4) then ring(c, { N = 12, Speed = 88, Damage = 15, Spin = math.random() * TAU }) end
end)
def("P5GoldenBullets", "Orb Cage", function(c, t)
	ring(c, { N = 9, Speed = 62, Damage = 17, Look = "Gold" })
	if wait(c, 0.35) then fan(c, t, { N = 5, Spread = 28, Speed = 120, Damage = 17, Look = "Gold", Lead = 0.5 }) end
end)
def("P5NoonTearer", "High Noon", function(c, t)
	blast(c, { Radius = 20, Warn = 1.5, Damage = 50, Look = "Gold" })
	quake(c, { Speed = 55, Range = 80, Damage = 24, Look = "Gold" })
end)
def("P5Fang-Dive", "Fang Rain", function(c, t)
	spikes(c, { Around = 3, AroundRadius = 15, Radius = 7, Warn = 1.1, Damage = 32 })
end)
def("P5Fang-Cross", "Crossfang", function(c, t)
	claws(c, t, { Angles = { -45, 45, 135, -135 }, Speed = 170, Damage = 20, Width = 20, Half = 8 })
end)
def("P5Fang-Pierce", "Fang Volley", function(c, t)
	fan(c, t, { N = 5, Spread = 14, Speed = 170, Damage = 20, Pierce = true, Gap = 0.1, Lead = 0.4 })
end)
def("P5IntrusiveLunge", "Intrusion", function(c, t)
	blast(c, { Radius = 10, Warn = 1.0, Damage = 36 })
	ring(c, { N = 6, Speed = 90, Damage = 15 })
end)
def("P5SwordDancer", "Dance Finale", function(c, t)
	local s = math.random() * TAU
	ring(c, { N = 14, Speed = 70, Damage = 15, Look = "Gold", Spin = s })
	if wait(c, 0.3) then ring(c, { N = 14, Speed = 70, Damage = 15, Look = "Gold", Spin = s + TAU / 28 }) end
	if wait(c, 0.3) then ring(c, { N = 14, Speed = 70, Damage = 15, Look = "Gold", Spin = s }) end
end)
def("P5EnhancedRipAndTear", "Rip Rebound", function(c, t)
	fan(c, t, { N = 9, Spread = 120, Speed = 105, Damage = 14, Look = "Gold" })
	if wait(c, 0.4) then spikes(c, { Around = 3, AroundRadius = 14, Radius = 7, Warn = 1.1, Damage = 30 }) end
end)
def("P5EnhancedGlidedThread", "Thread Snap", function(c, t)
	fan(c, t, { N = 11, Spread = 160, Speed = 100, Damage = 14, Look = "Gold" })
end)

def("P5WildHunt(Ultimate)", "Pack Call", function(c, t)
	spikes(c, { Around = 4, AroundRadius = 22, Radius = 8, Warn = 1.4, Damage = 40, Count = 7 })
	if wait(c, 0.4) then fan(c, t, { N = 9, Spread = 150, Speed = 110, Damage = 15 }) end
end)
def("P5NightTearer(Ultimate)", "Dusk Aftershock", function(c, t)
	quake(c, { Speed = 45, Range = 120, Width = 5, Damage = 36, Look = "Dark" })
	if wait(c, 0.5) then ring(c, { N = 20, Speed = 60, Damage = 15 }) end
end)
def("P5SilentCut(Ultimate)", "Silent Aftermath", function(c, t)
	blast(c, { Radius = 12, Warn = 1.3, Damage = 52 })
end)

def("P5BlackHole", "Horizon Flares", function(c, t)
	ring(c, { N = 12, Speed = 50, Damage = 16, Look = "Star" })
	if wait(c, 0.7) then ring(c, { N = 12, Speed = 50, Damage = 16, Look = "Star", Spin = math.random() * TAU }) end
end)
def("P5Hyper-lasticBeam(Ultimate)", "Elastic Rebound", function(c, t)
	quake(c, { Speed = 70, Range = 130, Damage = 32, Look = "Gold" })
	if wait(c, 0.4) then ring(c, { N = 16, Speed = 75, Damage = 15, Look = "Star" }) end
end)
def("P5IrisStar", "Iris Flash", function(c, t)
	ring(c, { N = 9, Speed = 80, Damage = 16, Look = "Star" })
end)
def("P5DyingStar", "Supernova Shards", function(c, t)
	ring(c, { N = 24, Speed = 60, Damage = 14, Look = "Star" })
end)
def("P5GravityCrush", "Crush Echo", function(c, t)
	blast(c, { Radius = 16, Warn = 1.3, Damage = 46 })
end)
def("P5EnhancedStarSlash", "Star Trail", function(c, t)
	fan(c, t, { N = 5, Spread = 50, Speed = 100, Damage = 17, Look = "Star" })
end)
def("P5LightJab", "Jab Flurry", function(c, t)
	fan(c, t, { N = 8, Spread = 22, Speed = 145, Damage = 13, Gap = 0.07, Lead = 0.35 })
end)
def("P5Disgeneration", "Disintegration Cloud", function(c, t)
	spikes(c, { Around = 6, AroundRadius = 20, Radius = 6, Warn = 1.2, Damage = 28, Count = 6 })
end)
def("P5PlasmaBall", "Plasma Split", function(c, t)
	ring(c, { N = 10, Speed = 40, Damage = 12, Look = "Star", Radius = 3.2 })
end)
def("P5JumpKick", "Landing Quake", function(c, t)
	quake(c, { Speed = 65, Range = 70, Damage = 26, Look = "Gold" })
end)
def("P5EnhancedJumpKick", "Double Kick", function(c, t)
	quake(c, { Speed = 70, Range = 75, Damage = 28, Look = "Gold" })
	if wait(c, 0.35) then quake(c, { Speed = 90, Range = 85, Damage = 28, Look = "Dark" }) end
end)
def("P5EnragedShockwave", "Shockwave Chain", function(c, t)
	for i = 1, 3 do
		if not quake(c, { Speed = 50 + i * 15, Range = 90, Damage = 24, Look = i % 2 == 1 and "Dark" or "Gold" }) or i == 3 or not wait(c, 0.45) then
			break
		end
	end
end)
def("P5UltraRed", "Red Aftershock", function(c, t)
	blast(c, { Radius = 20, Warn = 1.4, Damage = 48, Look = "Red" })
	ring(c, { N = 12, Speed = 70, Damage = 15, Look = "Gold" })
end)
def("P5UltraBlue", "Blue Aftershock", function(c, t)
	fan(c, t, { N = 11, Spread = 140, Speed = 80, Damage = 15, Look = "Star" })
end)
def("P5BlastBreath(Ultimate)", "Breath Cinders", function(c, t)
	spikes(c, { Around = 8, AroundRadius = 24, Radius = 7, Warn = 1.4, Damage = 34, Count = 6 })
end)
def("P5StarShooter", "Starburst", function(c, t)
	ring(c, { N = 14, Speed = 62, Damage = 14, Look = "Star" })
	if wait(c, 0.5) then ring(c, { N = 14, Speed = 62, Damage = 14, Look = "Star", Spin = math.random() * TAU }) end
end)

def("P5GoldenEternity", "Eternal Return", function(c, t)
	quake(c, { Speed = 50, Range = 95, Inward = true, Damage = 30, Look = "Gold" })
	if wait(c, 0.5) then ring(c, { N = 10, Speed = 70, Damage = 15, Look = "Gold" }) end
end)
def("P5Overclock", "Overheat", function(c, t)
	fan(c, t, { N = 15, Spread = 90, Speed = 150, Damage = 10, Gap = 0.05, Lead = 0.4 })
end)
def("P5TimeBomb", "Chain Reaction", function(c, t)
	blast(c, { Radius = 14, Warn = 1.2, Damage = 42 })
	if wait(c, 0.4) then spikes(c, { Around = 3, AroundRadius = 12, Radius = 7, Warn = 1.1, Damage = 30 }) end
end)
def("P5Chronobreak", "Time Shatter", function(c, t)
	ring(c, { N = 18, Speed = 40, Damage = 15, Look = "Gold" })
end)
def("P5Finality(Ultimate)", "Last Second", function(c, t)
	wall(c, { Speed = 60, Range = 100, Height = 16, Damage = 40 })
	if wait(c, 0.6) then ring(c, { N = 16, Speed = 55, Damage = 15, Look = "Gold" }) end
end)
def("P5EnhancedTimeBullets", "Bullet Time", function(c, t)
	fan(c, t, { N = 9, Spread = 80, Speed = 90, Damage = 14, Look = "Gold", Lead = 0.5 })
end)
def("P5EnhancedDirectShot", "Double Tap", function(c, t)
	fan(c, t, { N = 3, Spread = 10, Speed = 175, Damage = 20, Gap = 0.12, Lead = 0.4 })
	if wait(c, 0.3) then fan(c, t, { N = 3, Spread = 10, Speed = 175, Damage = 20, Gap = 0.12, Lead = 0.4 }) end
end)

def("P5Borealis", "Aurora Shards", function(c, t)
	fan(c, t, { N = 9, Spread = 110, Speed = 85, Damage = 15, Look = "Star" })
end)
def("P5Polaris(Ultimate)", "Polar Fall", function(c, t)
	spikes(c, { Around = 6, AroundRadius = 22, Radius = 8, Warn = 1.5, Damage = 38, Count = 6 })
	if wait(c, 0.4) then quake(c, { Speed = 55, Range = 100, Damage = 28, Look = "Gold" }) end
end)
def("P5Stranglethorns", "Thorn Bloom", function(c, t)
	spikes(c, { Around = 6, AroundRadius = 22, Radius = 6, Warn = 1.2, Damage = 30, Count = 6 })
end)
def("P5AuroraCurtain", "Curtain Call", function(c, t)
	ring(c, { N = 12, Speed = 66, Damage = 13, Look = "Star" })
end)
def("P5EnhancedFlowerField", "Pollen Burst", function(c, t)
	blast(c, { Radius = 16, Warn = 1.2, Damage = 40, Look = "Gold" })
	if wait(c, 0.3) then spikes(c, { Around = 2, AroundRadius = 14, Radius = 6, Warn = 1.0, Damage = 28 }) end
end)
def("P5LightningDash", "Static Trail", function(c, t)
	fan(c, t, { N = 5, Spread = 16, Speed = 200, Damage = 18, Look = "Gold", Pierce = true, Lead = 0.4 })
end)
def("P5TheWind", "Gale Cut", function(c, t)
	fan(c, t, { N = 7, Spread = 60, Speed = 125, Damage = 14 })
end)
def("P5GreatWind", "Tempest", function(c, t)
	quake(c, { Speed = 60, Range = 100, Damage = 28, Look = "Dark" })
	if wait(c, 0.5) then quake(c, { Speed = 80, Range = 100, Damage = 28, Look = "Gold" }) end
end)
def("P5EnhancedGildedCataclysm", "Gilded Rain", function(c, t)
	spikes(c, { Around = 5, AroundRadius = 20, Radius = 8, Warn = 1.3, Damage = 36, Tall = true })
end)
def("P5TheGreatStorm(Ultimate)", "Storm Eye", function(c, t)
	wall(c, { Speed = 58, Range = 100, Height = 16, Damage = 38 })
	if wait(c, 0.5) then blast(c, { Radius = 15, Warn = 1.2, Damage = 44 }) end
end)

api.Extras = EXTRA

function api.Has(name)
	return EXTRA[name] ~= nil
end

 -- runs one extra on a ready-made context (used by tests with a mock context)
function api.RunWith(c, name, target)
	local extra = EXTRA[name]
	if extra then
		extra.Run(c, target)
	end
end

local function run(actor, name, extra, target)
	local Strike = require(B.Attacks.Shared.P5StrikeCore)
	local c = Strike.Context(actor, name)
	if not c.Valid() then
		return
	end
	actor:SetAttribute("P5HellavenExtra", extra.Label)
	extra.Run(c, target)
end

 -- AttackRegistry calls this after a Phase 5 attack ran; nothing happens off Hellaven
function api.After(actor, name, target)
	local extra = EXTRA[name]
	if not extra or not actor or not actor.Parent then
		return false
	end
	if Difficulty.Id(actor) ~= "Hellaven" then
		return false
	end
	if actor:GetAttribute("IsGoldenClone") or actor:GetAttribute("IsClone") or actor:GetAttribute("IsIllusion")
		or actor:GetAttribute("EncounterEnded") or actor:GetAttribute("PhaseTransitionInProgress")
		or (tonumber(actor:GetAttribute("Phase")) or 1) ~= 5 or workspace:GetAttribute("SonicBlasterActive") then
		return false
	end
	local st = state[actor]
	if not st then
		st = { Busy = 0, Next = 0 }
		state[actor] = st
	end
	local now = os.clock()
	if st.Busy >= MAX_AT_ONCE or now < st.Next then
		return false
	end
	st.Busy += 1
	st.Next = now + MIN_GAP
	task.spawn(function()
		local ok, err = xpcall(run, debug.traceback, actor, name, extra, target)
		st.Busy -= 1
		if not ok then
			warn("[P5Hellaven] " .. name .. ": " .. tostring(err))
		end
	end)
	return true
end

return api
