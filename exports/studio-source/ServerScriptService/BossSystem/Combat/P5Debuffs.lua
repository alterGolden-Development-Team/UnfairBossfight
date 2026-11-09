local B = script:FindFirstAncestor("BossSystem")
local api = {}
local RETHROW = 0.6

api.Map = table.freeze({
	P5ClawForward = { "Bleed", 4 },
	P5Assassination = { "Hemorrhage", 5 },
	P5UpperCut = { "JumpLock", 2.5 },
	P5Butterfly = { "Blur", 4 },
	P5DistortedCounter = { "IllusionRot", 5 },
	P5GoldenPierce = { "Rupture", 4 },
	P5Slam = { "Vulnerability", 3 },
	P5Viper = { "Acid", 5 },
	P5HorrifyingGround = { "Fear", 2 },
	P5ScarletRiver = { "Hemorrhage", 4 },
	P5FireRing = { "Decay", 5 },
	P5ShotgunBlast = { "CooldownIncrease", 4 },
	P5PerfectVerticalSlash = { "ChainCurse", 4 },
	["P5Golden-matterBeam"] = { "Corruption", 5 },
	["P5DoubleGolden-matterBeam"] = { "Corruption", 6 },
	P5JudgementZone = { "DeathMark", 8 },
	P5NullifiedZone = { "CooldownFreeze", 1.5 },
	P5HellavanRampage = { "Hemorrhage", 5 },
	P5EnhancedBurst = { "Vulnerability", 3 },
	P5GoldenBullets = { "ChainCurse", 4 },
	P5NoonTearer = { "Decay", 5 },
	["P5Fang-Dive"] = { "Bleed", 4 },
	["P5Fang-Cross"] = { "Bleed", 4 },
	["P5Fang-Pierce"] = { "Rupture", 4 },
	P5IntrusiveLunge = { "Fear", 2 },
	P5SwordDancer = { "Hemorrhage", 4 },
	P5EnhancedGlidedThread = { "Rupture", 3 },
	["P5WildHunt(Ultimate)"] = { "Hemorrhage", 6 },
	["P5NightTearer(Ultimate)"] = { "Corruption", 6 },
	["P5SilentCut(Ultimate)"] = { "CooldownFreeze", 2 },
	["P5BlastBreath(Ultimate)"] = { "Decay", 6 },
	["P5Polaris(Ultimate)"] = { "Frostbite", 6 },
	["P5TheGreatStorm(Ultimate)"] = { "ChainCurse", 5 },
	["P5Finality(Ultimate)"] = { "CooldownFreeze", 2 },
	P5BlackHole = { "Corruption", 6 },
	P5IrisStar = { "Blur", 5 },
	P5DyingStar = { "Decay", 5 },
	P5GravityCrush = { "JumpLock", 2.5 },
	P5EnhancedStarSlash = { "Rupture", 3 },
	P5LightJab = { "Vulnerability", 2.5 },
	P5Disgeneration = { "Decay", 6 },
	P5PlasmaBall = { "Acid", 4 },
	P5JumpKick = { "CooldownIncrease", 4 },
	P5EnhancedJumpKick = { "Vulnerability", 4 },
	P5EnragedShockwave = { "JumpLock", 2 },
	P5UltraRed = { "Corruption", 5 },
	P5UltraBlue = { "Frostbite", 5 },
	P5StarShooter = { "CooldownIncrease", 3 },
	P5FallingStar = { "Vulnerability", 3 },
	P5GoldenEternity = { "TemporalWound", 6 },
	P5Overclock = { "CooldownIncrease", 5 },
	P5TimeBomb = { "TemporalWound", 6 },
	P5Chronobreak = { "CooldownFreeze", 1.5 },
	P5Borealis = { "Frostbite", 5 },
	P5Stranglethorns = { "Hemorrhage", 5 },
	P5AuroraCurtain = { "Frostbite", 4 },
	P5EnhancedFlowerField = { "Acid", 5 },
	P5LightningDash = { "Vulnerability", 3 },
	P5TheWind = { "Blur", 4 },
	P5GreatWind = { "JumpLock", 2 },
	P5EnhancedGildedCataclysm = { "Rupture", 3 },
})

local last = setmetatable({}, { __mode = "k" })

function api.For(skill)
	return api.Map[skill]
end

 -- called by PlayerEncounter.Damage after a hit that dealt damage; owner is the boss, skill the attack's name
function api.OnHit(owner, char, skill)
	local entry = api.Map[skill]
	if not entry or not owner or not char then
		return false
	end
	local now = os.clock()
	local mine = last[char]
	if not mine then
		mine = {}
		last[char] = mine
	end
	if (mine[entry[1]] or 0) + RETHROW > now then
		return false
	end
	mine[entry[1]] = now
	local ok, applied = pcall(require(B.Combat.AttackDebuffService).Apply, owner, char, entry[1], entry[2])
	if ok and applied then
		owner:SetAttribute("LastP5Debuff", skill .. " -> " .. entry[1])
	end
	return ok and applied == true
end

return api
