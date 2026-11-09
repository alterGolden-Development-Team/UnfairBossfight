 
local definitions, active, passive, stopped, clone = {}, {}, {}, {}, {}
local phaseFolders = table.freeze({ [1] = "P1", [1.5] = "P1.5", [2] = "P2", [2.5] = "P2.5", [3] = "P3", [3.5] = "P3.5", [4] = "P4", [4.5] = "P4.5", [5] = "P5" })
local sharedModules = table.freeze({ P1CombatCore = true, BossDamageService = true, P15Transition = true })
local function add(name, phase, options)
	options = options or {}
	local phases = options.AllowedPhases
		or (
			phase == 1 and { 1, 1.5, 2, 2.5 }
			or phase == 1.5 and { 1.5, 2, 2.5 }
			or phase == 2 and { 2, 2.5 }
			or phase == 3 and { 3, 3.5 }
			or phase == 4 and { 4, 4.5 }  
			or phase == 4.5 and { 4.5 }
			or { phase }
		)
	local allowed, maximum = {}, phase
	for _, value in ipairs(phases) do
		allowed[value] = true
		maximum = math.max(maximum, value)
	end
	local entry = {
		Name = name,
		NativePhase = phase,
		Passive = options.Passive == true,
		ShieldBreakOnly = options.ShieldBreakOnly == true,
		ModuleFolder = options.Passive == true and "Passives"
			or options.TimeStopOnly == true and "P2/GoldenClock"
			or options.ModuleFolder
			or phaseFolders[phase],
		Ultimate = options.Ultimate == true,
		UnscaledDifficulty = options.UnscaledDifficulty == true,
		TimeStopOnly = options.TimeStopOnly == true,
		TimeStopCompatible = options.TimeStopOnly == true,
		CanClone = options.CanClone == true,
		CanLinked = options.CanLinked == true or options.CanClone == true,
		CanMimic = options.CanClone == true or options.CanLinked == true,
		CanFalseFuture = options.CanFalseFuture == true,
		CanLastMinuteEcho = options.CanLastMinuteEcho == true,
		CanMissingFrame = options.CanMissingFrame == true,
		SwordBased = options.SwordBased == true,
		CanHourDebt = options.CanHourDebt ~= false
			and not options.Passive
			and not options.Ultimate
			and not options.TimeStopOnly,
		CooldownUsesRealTime = options.Ultimate == true or options.Passive == true,
		AllowedPhases = table.freeze(allowed),
		MaximumPhase = maximum,
		TriggerOnly = options.TriggerOnly == true,
		Linked = options.Linked == true,
		P5Mode = options.P5Mode,  -- Phase 5 mode folder: Space / Natural / Time / Normal (P5ModeService)
		AnyRange = options.AnyRange == true,  -- closes the distance itself: no melee/far range weighting
	}
	 
	if phase == 2.5 then
		entry.CanClone = false
		entry.CanHourDebt = false
		entry.CanLinked = false
		entry.CanMimic = false
	end
	if entry.Passive or entry.Ultimate or entry.TimeStopOnly or entry.Linked then
		entry.CanFalseFuture = false
		entry.CanLastMinuteEcho = false
		entry.CanMissingFrame = false
	end
	definitions[name] = table.freeze(entry)
	if not entry.Linked and not entry.ShieldBreakOnly then
		table.insert(entry.Passive and passive or entry.TimeStopOnly and stopped or active, name)
	end
	if entry.CanClone then
		table.insert(clone, name)
	end
end
for _, name in ipairs({
	"P1NormalSlash",
	"P1RangedSlashes",
	"P1FallingBlade",
	"P1GoldenThrust",
	"P1GoldenSplit",
	"P1TornadoSlash",
	"P1IntimidatingSlash",
	"P1BlockGrab",
}) do
	add(name, 1, {
		CanClone = true,
		SwordBased = name ~= "P1BlockGrab",
		CanFalseFuture = name == "P1RangedSlashes",
		CanLastMinuteEcho = name == "P1RangedSlashes",
		CanMissingFrame = name == "P1RangedSlashes"
			or name == "P1GoldenThrust"
			or name == "P1TornadoSlash"
			or name == "P1IntimidatingSlash",
	})
end
add("P4EnhancedSplit", 4, { SwordBased = true, CanHourDebt = false })
add("P1GoldenParry", 1, { SwordBased = true })
add("P1GildedCataclysm(Ultimate)", 1, { Ultimate = true, SwordBased = true, AllowedPhases = { 1, 1.5 } })
add("P1.5Teleportation", 1.5)
for _, name in ipairs({ "P1.5GildedThread", "P1.5Raining", "P1.5GoldenHand", "P1.5GoldenLance" }) do
	add(name, 1.5, {
		CanClone = true,
		CanFalseFuture = name == "P1.5GoldenLance",
		CanLastMinuteEcho = name == "P1.5GoldenLance",
		CanMissingFrame = name == "P1.5GoldenLance" or name == "P1.5GildedThread",
	})
end
add("P1.5GoldenChain", 1.5)
add("P1.5GroundChains", 1.5, { CanFalseFuture = true })
add("P1.5RoyalBow(Ultimate)", 1.5, { Ultimate = true, AllowedPhases = { 1.5 } })
for _, name in ipairs({ "P2Save", "P2Load", "P2GoldenBullets", "P2TimeBullets" }) do
	add(name, 2, {
		CanFalseFuture = name == "P2GoldenBullets",
		CanLastMinuteEcho = name == "P2GoldenBullets" or name == "P2TimeBullets",
		CanMissingFrame = name == "P2GoldenBullets" or name == "P2TimeBullets",
		CanHourDebt = name ~= "P2Save" and name ~= "P2Load",
	})
end
add("P2DirectShot", 2, { CanHourDebt = false })
add("P2Acceleration", 2, { CanHourDebt = false })
add("P2Deceleration", 2, { CanHourDebt = false })
add("P2GoldenClock(Ultimate)", 2, { Ultimate = true, ModuleFolder = "P2/GoldenClock" })
for _, name in ipairs({ "P2.5StolenSecond", "P2.5FalseFuture", "P2.5MissingFrame", "P2.5CircularBarrage" }) do
	add(name, 2.5, { CanClone = false, CanHourDebt = false })
end
add("P2.5LastMinute(Ultimate)", 2.5, { Ultimate = true, TriggerOnly = true, CanClone = false, CanHourDebt = false })
add("P3Dash", 3, { CanHourDebt = false })
add("P3Thief", 3, { CanClone = false, CanHourDebt = false })
add("P3Illusion", 3, { CanClone = false, CanHourDebt = false })
add("P3ControlDistortion", 3, { CanClone = false, CanHourDebt = false })
add("P3Projectile", 3, { CanClone = false, CanHourDebt = false })
add("P3Cards", 3, { CanClone = false, CanHourDebt = false })
add("P3Clone", 3, { CanClone = false, CanHourDebt = false })
add("P3PlayerClone", 3, { CanClone = false, CanHourDebt = false })
add("P3EtherealAcumen(Ultimate)", 3, { Ultimate = true, CanClone = false, CanHourDebt = false })
add("P3PickThePupils(Ultimate)", 3, { Ultimate = true, CanClone = false, CanHourDebt = false })
add("P3.5TrueIllusion(Ultimate)",3.5,{Ultimate=true,CanClone=false,CanHourDebt=false,AllowedPhases={3.5}})
add("P3.5IllusionBomb",3.5,{UnscaledDifficulty=true,CanClone=false,CanHourDebt=false,AllowedPhases={3.5}})
add("P3.5IllusionGun",3.5,{CanClone=false,CanHourDebt=false,AllowedPhases={3.5}})
add("P3.5MysteriousGuy(Ultimate)",3.5,{Ultimate=true,UnscaledDifficulty=true,CanClone=false,CanHourDebt=false,AllowedPhases={3.5}})
add("P4SplittingSlash", 4, { SwordBased = true, CanHourDebt = false })
add("P4EnhancedRaining", 4, { CanHourDebt = false })
add("P4StarSlash", 4, { SwordBased = true, CanHourDebt = false, AllowedPhases = { 4, 4.5 } })
add("P4RipAndTear",4,{SwordBased=true,CanHourDebt=false})
add("P4Karmanation(Passive)",4,{Passive=true})
add("P4EnhancedThrust", 4, { SwordBased = true, CanHourDebt = false })
add("P4Burst", 4, { CanHourDebt = false })
add("P4Dash", 4, { SwordBased = true, CanHourDebt = false, AllowedPhases = { 4, 4.5 } })
add("P4.5FlowerField", 4.5, { CanHourDebt = false })
add("P4.5HeavenlyDisciple(Ultimate)", 4.5, { Ultimate = true, CanClone = false, CanHourDebt = false })
add("P4.5OrderBreak", 4.5, { CanHourDebt = false })
 -- Phase 5 attacks live in mode folders (P5/Space, P5/Natural, P5/Time) plus P5/NormalAttack;
 -- P5ModeService lets the boss use one mode's skills at a time, normal attacks always
for name, mode in pairs({
	["P5Hyper-lasticBeam(Ultimate)"] = "Space", P5BlackHole = "Space", P5DyingStar = "Space", P5IrisStar = "Space",
	["P5Polaris(Ultimate)"] = "Natural", P5Borealis = "Natural",
	["P5Finality(Ultimate)"] = "Time", P5GoldenEternity = "Time", P5Overclock = "Time",  -- Time's P2 powers, enhanced
	P5TimeBomb = "Time", P5Chronobreak = "Time", P5Stranglethorns = "Natural", P5AuroraCurtain = "Natural",
	P5GravityCrush = "Space", P5StarShooter = "Space", P5EnhancedJumpKick = "Space",
	P5EnhancedStarSlash = "Space", P5LightJab = "Space", P5Disgeneration = "Space", P5PlasmaBall = "Space", P5JumpKick = "Space",
	P5EnragedShockwave = "Space", P5UltraRed = "Space", P5UltraBlue = "Space",
	P5EnhancedFlowerField = "Natural", P5LightningDash = "Natural", P5TheWind = "Natural", P5GreatWind = "Natural",
	P5EnhancedGildedCataclysm = "Natural",
	P5EnhancedTimeBullets = "Time", P5EnhancedDirectShot = "Time",
}) do
	add(name, 5, { Ultimate = name:find("(Ultimate)", 1, true) ~= nil, CanClone = false, CanHourDebt = false,
		ModuleFolder = "P5/" .. mode, P5Mode = mode })
end
local unarmed = { P5DistortedCounter = true, P5GoldenPierce = true, P5Slam = true, P5ScarletRiver = true, P5ShotgunBlast = true,
	["P5Golden-matterBeam"] = true, ["P5DoubleGolden-matterBeam"] = true, P5JudgementZone = true, P5NullifiedZone = true,
	P5IntrusiveLunge = true, P5SwordDancer = true, P5GoldenBullets = true, P5EnhancedBurst = true, P5EnhancedGlidedThread = true }
for _, name in ipairs({ "P5ClawForward", "P5Assassination", "P5UpperCut", "P5Butterfly", "P5DistortedCounter", "P5GoldenPierce",
	"P5Slam", "P5Viper", "P5HorrifyingGround", "P5DeathRoar", "P5ScarletRiver", "P5FireRing", "P5ShotgunBlast", "P5PerfectVerticalSlash",
	"P5Golden-matterBeam", "P5DoubleGolden-matterBeam", "P5JudgementZone", "P5NullifiedZone", "P5HellavanRampage",
	"P5Fang-Dive", "P5Fang-Cross", "P5Fang-Pierce", "P5IntrusiveLunge", "P5NoonTearer", "P5EnhancedRipAndTear", "P5EnhancedBurst",
	"P5GoldenBullets", "P5SwordDancer", "P5EnhancedGlidedThread" }) do
	add(name, 5, { SwordBased = not unarmed[name], AnyRange = name ~= "P5ClawForward",
		CanClone = false, CanHourDebt = false, ModuleFolder = "P5/NormalAttack", P5Mode = "Normal" })
end
for _, name in ipairs({ "P5WildHunt(Ultimate)", "P5NightTearer(Ultimate)", "P5SilentCut(Ultimate)" }) do
	add(name, 5, { Ultimate = true, SwordBased = true, AnyRange = true, CanClone = false, CanHourDebt = false,
		ModuleFolder = "P5/NormalAttack", P5Mode = "Normal" })
end
 -- each mode's last stand: owed once when that mode's shield breaks (P5ModeService.LastStand), never picked otherwise
for name, mode in pairs({ ["P5BlastBreath(Ultimate)"] = "Space", ["P5TheGreatStorm(Ultimate)"] = "Natural" }) do
	add(name, 5, { Ultimate = true, CanClone = false, CanHourDebt = false, ModuleFolder = "P5/" .. mode, P5Mode = "LastStand" })
end
 -- the mode weapon's swing: only inside a mode, in place of the Normal Attack folder (P5ModeService)
add("P5ModeWeapon", 5, { AnyRange = true, CanClone = false, CanHourDebt = false, ModuleFolder = "P5/Weapon", P5Mode = "Weapon" })
add("P5God(Passive)", 5, { Passive = true, AllowedPhases = {5} })
add("P5FallingStar", 5, { CanClone = false, CanHourDebt = false, ModuleFolder = "P5/Summoned", P5Mode = "Summoned" })
for _, name in ipairs({ "P5Spacetrum(Passive)", "P5Verdant(Passive)", "P5Pastborn(Passive)", "P5Enraged(Passive)", "P5SuperEnraged(Passive)" }) do
	add(name, 5, { Passive = true, AllowedPhases = { 5 } })
end
add("P4TargetingKnives", 4, { CanHourDebt = false, AllowedPhases = { 4, 4.5 } })
add("P4RiftColumn", 4, { SwordBased = true, CanHourDebt = false })
add("P4EnhancedRangedSlashes", 4, { SwordBased = true, CanHourDebt = false, AllowedPhases = { 4, 4.5 } })
add("P4EnhancedNormalSlashes", 4, { SwordBased = true, CanHourDebt = false, AllowedPhases = { 4, 4.5 } })
add("P4DeathScythe(Ultimate)", 4, { Ultimate = true, CanClone = false, CanHourDebt = false })
add("P4DeathRoars(Ultimate)", 4, { Ultimate = true, SwordBased = true, CanClone = false, CanHourDebt = false })
add("P1Unstoppable(Passive)", 1, { Passive = true })
add("P1.5Clone(Passive)", 1.5, { Passive = true })
add("P2HourDebt(Passive)", 2, { Passive = true })
add("P2.5FutureSight(Passive)", 2.5, { Passive = true, CanClone = false, CanHourDebt = false })
add("P4Regeneration(Passive)", 4, { Passive = true })
add("P4Enraged(Passive)", 4, { Passive = true })
add("P4TrueSpirit(Passive)",4,{Passive=true})
add("P3Misdirection(Passive)",3,{Passive=true,AllowedPhases={3,3.5}})
add("P3.5Debuffer(Passive)",3.5,{Passive=true,AllowedPhases={3.5}})
add("P3GoldenMark(Passive)", 3, { Passive = true })
for _, name in ipairs({ "FrozenGoldenBullets", "ClockBlades", "TemporalSlashMarks", "FrozenGoldenLances", "TimeMines" }) do
	add(name, 2, { TimeStopOnly = true })
end
for role, name in pairs({ alterGolden = "P1Sniping", Elementalist = "P1FireBullet", Swordsmaster = "P1KnifeBarrage" }) do
 add(name, 1, {ModuleFolder = "P1(ShieldBreak)/" .. role, ShieldBreakOnly = true,
  CanClone = false, CanHourDebt = false, AllowedPhases = {1, 1.5}})
end
add("P1GroundShatter", 1, {ModuleFolder = "P1(ShieldBreak)/alterGolden", ShieldBreakOnly = true,
 CanClone = false, CanHourDebt = false, AllowedPhases = {1, 1.5}})
for _, name in ipairs({"P1TornadoLeaf", "P1LightningBarrage"}) do
 add(name, 1, {ModuleFolder = "P1(ShieldBreak)/Elementalist", ShieldBreakOnly = true,
  CanClone = false, CanHourDebt = false, AllowedPhases = {1, 1.5}})
end
for _,name in ipairs({"P1ContinousStrike","P1ChainedCombo"}) do
 add(name,1,{ModuleFolder="P1(ShieldBreak)/Swordsmaster",ShieldBreakOnly=true,
 SwordBased=true,CanClone=false,CanHourDebt=false,AllowedPhases={1,1.5}})
end
local api = {
	ActiveNames = table.freeze(active),
	PassiveNames = table.freeze(passive),
	TimeStopNames = table.freeze(stopped),
	CloneNames = table.freeze(clone),
}
function api.Get(name)
	return definitions[name]
end
function api.ModuleFolder(name)
	if sharedModules[name] then
		return "Shared"
	end
	local entry = definitions[name]
	return entry and entry.ModuleFolder or nil
end
function api.PassiveAvailable(name, phase)
	local entry = definitions[name]
	return entry ~= nil and entry.Passive and entry.AllowedPhases[tonumber(phase) or 1] == true
end
function api.Available(name, phase)
	local entry = definitions[name]
	phase = tonumber(phase) or 1
	return entry ~= nil and entry.AllowedPhases[phase] == true
end
function api.CanCopy(name, mode)
	local entry = definitions[name]
	if not entry or entry.Passive or entry.Ultimate or entry.TimeStopOnly or entry.Linked or entry.ShieldBreakOnly then
		return false
	end
	if mode == "Linked" then
		return entry.CanLinked and entry.NativePhase ~= 2 and entry.NativePhase ~= 2.5
	end
	 
	if mode == "Illusion" then
		return false
	end
	return mode == "HourDebt" and entry.CanHourDebt or mode ~= "HourDebt" and entry.CanClone
end
return table.freeze(api)