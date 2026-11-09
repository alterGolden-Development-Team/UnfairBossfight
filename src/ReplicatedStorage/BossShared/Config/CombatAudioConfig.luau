 
local Assets = table.freeze({
	DialogueVoice = "rbxassetid://5342465893",
	DeathScytheGoodbye = "rbxassetid://135672235301139",
	Hero = "rbxassetid://96167216374376",
	Phase2 = "rbxassetid://138324961225014",
	Phase3 = "rbxassetid://81711339945780",
	Phase4 = "rbxassetid://101522080894404",
 Phase5 = "rbxassetid://129319297679953",
	TrueIllusion = "rbxassetid://81669251781743",
	ShieldBreak = "rbxassetid://100436540003611",
	PickThePupils = "rbxassetid://131181279208849",
	PupilSuspense = "rbxassetid://87045916711647",
	PupilCorrect = "rbxassetid://130206997868957",
	PupilIncorrect = "rbxassetid://135730774477674",
	PupilFirework = "rbxassetid://108875729772405",
	SwordSlash = "rbxassetid://12222216",
	SwordLunge = "rbxassetid://12222208",
	SwordDraw = "rbxassetid://12222225",
	Air = "rbxasset://sounds/action_falling.ogg",
	Crack = "rbxasset://sounds/action_jump_land.mp3",
	Rise = "rbxasset://sounds/action_get_up.mp3",
	Chime = "rbxasset://sounds/volume_slider.ogg",
	Impact = "rbxasset://sounds/impact_explosion_03.mp3",
	Rattle = "rbxasset://sounds/action_footsteps_plastic.mp3",
	Roar = "rbxasset://sounds/ouch.ogg",
	Water = "rbxasset://sounds/impact_water.mp3",
	P1Split = "rbxassetid://138687206526097",
	Ranged = "rbxassetid://130036764141803",
	Intimidating = "rbxassetid://138556725992332",
	Tornado = "rbxassetid://139345755518677",
	CatQTESuccess = "rbxassetid://124444290902740",
	CatFailurePull = "rbxassetid://86561148418857",
	CatRock = "rbxassetid://120212342534790",
	GoldenChain = "rbxassetid://94262331099819",
	GoldenHand = "rbxassetid://137231920197356",
	GoldenLance = "rbxassetid://106040916467911",
	GroundChains = "rbxassetid://72443891537288",
	RainSword = "rbxassetid://106836237516030",
	Teleport = "rbxassetid://120804026547578",
	Acceleration = "rbxassetid://83613815751583",
	Deceleration = "rbxassetid://9120061271",
	GoldenBullet = "rbxassetid://123444285617739",
	TimeBullet = "rbxassetid://126809328894734",
	TimeConstruct = "rbxassetid://139571940014575",
	MissingFrame = "rbxassetid://125628438711815",
	P3Snap = "rbxassetid://131727399246401",
	SplittingSlash = "rbxassetid://117016486915242",
	ShieldBreakScream = "rbxassetid://111870313797501",
	DeathRoarsSlash = "rbxassetid://129949908820890",
})
local cues = {}
local function layer(asset, volume, pitch, low, mid, high, tool)
	return table.freeze({
		Asset = Assets[asset],
		Volume = volume,
		Pitch = pitch,
		Low = low or 0,
		Mid = mid or 0,
		High = high or 0,
		ToolSound = tool,
	})
end
local function cue(name, layers, options)
	options = options or {}
	cues[name] = table.freeze({
		Layers = table.freeze(layers),
		Interval = options.Interval or 0.09,
		MaxVoices = options.MaxVoices or 3,
		Priority = options.Priority or 1,
		Range = options.Range or 180,
		Loop = options.Loop == true,
		Duration = options.Duration or 3,
		Duck = options.Duck,
		Vacuum = options.Vacuum,
		FixedPitch = options.FixedPitch == true,
		FullLength = options.FullLength == true,
		PreserveStart = options.PreserveStart == true,
		VolumeCap = options.VolumeCap,
	})
end
local function sweep(name, pitch, volume, tool)
	cue(
		name,
		{
			layer("Air", volume or 0.22, pitch or 1.2, -8, 0, 5, tool),
			layer("Chime", 0.10, (pitch or 1.2) * 1.2, -10, -4, 3),
		}
	)
end
local function magic(name, pitch, volume)
	cue(
		name,
		{ layer("Rise", volume or 0.24, pitch or 0.9, -4, 4, 2), layer("Chime", 0.16, (pitch or 0.9) * 0.85, -8, 1, 3) }
	)
end
local function impact(name, pitch, volume, priority)
	cue(
		name,
		{ layer("Impact", volume or 0.3, pitch or 0.8, 3, -4, -7), layer("Crack", 0.18, (pitch or 0.8) * 1.3, 0, 2, 1) },
		{ Priority = priority or 2, Interval = 0.12, MaxVoices = 3, Range = 230 }
	)
end
local function loop(name, asset, pitch, volume)
	cue(
		name,
		{ layer(asset, volume, pitch, -6, -2, -3) },
		{ Loop = true, MaxVoices = 2, Range = 100, Duration = 65, Interval = 0.3 }
	)
end
for name, data in pairs({
	NormalDraw = { 1.2, 0.12, "Unsheath" },
	NormalSwing = { 1.4, 0.22, "Slash" },
	RangedLaunch = { 1.6, 0.24 },
	RangedWhoosh = { 1.9, 0.11 },
	ThrustCharge = { 1.1, 0.12 },
	ThrustBurst = { 1.85, 0.2 },
	ThrustStab = { 1.7, 0.15, "Lunge" },
	TornadoCut = { 1.6, 0.14 },
	BlockLaunch = { 0.66, 0.27 },
	ThreadLaunch = { 1.85, 0.23 },
	RainFall = { 1.6, 0.09 },
	LanceLaunch = { 0.78, 0.32 },
	RoyalRelease = { 0.58, 0.44 },
	RoyalFinalRelease = { 0.38, 0.55 },
	TeleportOut = { 1.7, 0.18 },
	TeleportIn = { 1.2, 0.23 },
}) do
	sweep(name, table.unpack(data))
end
for name, data in pairs({
	RangedSummon = { 1.2, 0.2 },
	FallingCharge = { 0.65, 0.35 },
	GuardActivate = { 0.8, 0.3 },
	ParryStance = { 0.95, 0.23 },
	SplitCharge = { 0.64, 0.3 },
	TornadoBuild = { 0.8, 0.25 },
	CrescentCharge = { 0.45, 0.3 },
	CloneMaterialize = { 1.25, 0.27 },
	CloneFade = { 1.7, 0.18 },
	ThreadSummon = { 1.4, 0.18 },
	HandSummon = { 0.6, 0.32 },
	RainSummon = { 0.85, 0.24 },
	RainWarn = { 1.4, 0.09 },
	LanceSummon = { 0.85, 0.23 },
	LanceWarning = { 1.1, 0.2 },
	ChainSummon = { 0.75, 0.26 },
	GroundWarning = { 0.5, 0.16 },
	GroundLock = { 1.5, 0.21 },
	RoyalSummon = { 0.5, 0.4 },
	EntranceReveal = { 0.55, 0.35 },
	RoyalDraw = { 0.68, 0.3 },
	RoyalFinalCharge = { 0.43, 0.48 },
	TeleportWarp = { 0.55, 0.24 },
	QTESuccess = { 1.55, 0.24 },
}) do
	magic(name, table.unpack(data))
end
for name, data in pairs({
	NormalImpact = { 1.25, 0.15 },
	RangedImpact = { 1.1, 0.2 },
	RangedX = { 0.58, 0.32 },
	FallingImpact = { 0.38, 0.6, 4 },
	FallingWave = { 0.5, 0.3 },
	ParryContact = { 1.7, 0.23 },
	CounterImpact = { 0.55, 0.42, 3 },
	SplitActivate = { 0.45, 0.45 },
	CrescentRelease = { 0.55, 0.38 },
	BlockCrack = { 0.8, 0.22 },
	BlockImpact = { 0.5, 0.35 },
	BlockWave = { 0.7, 0.2 },
	CataclysmStomp = { 0.45, 0.5 },
	EarthRise = { 0.66, 0.25 },
	CataclysmSlam = { 0.38, 0.5, 4 },
	ThreadBounce = { 1.8, 0.16 },
	ThreadSphereHit = { 1.3, 0.2 },
	ThreadContact = { 1.55, 0.1 },
	HandGrab = { 0.55, 0.27 },
	HandExplosion = { 0.55, 0.4 },
	RainImpact = { 1.25, 0.13 },
	LanceImpact = { 0.6, 0.34 },
	ChainContact = { 1.35, 0.2 },
	ChainBreak = { 1.55, 0.25 },
	GroundErupt = { 0.65, 0.3 },
	GroundBreak = { 1.3, 0.2 },
	RoyalImpact = { 0.48, 0.47, 3 },
	RoyalFinalImpact = { 0.3, 0.75, 5 },
	QTEFailure = { 0.7, 0.3 },
	Knockback = { 0.45, 0.42, 4 },
	LifeCheckExecution = { 0.3, 0.65, 5 },
	JudgmentImpact = { 0.3, 0.65, 5 },
}) do
	impact(name, table.unpack(data))
end
sweep("JudgmentFall", 0.5, 0.42)
sweep("FallingDescend", 0.58, 0.35)
cue(
	"ShieldCrack",
	{ layer("Crack", 0.45, 0.65, 0, 3, 5), layer("Chime", 0.24, 0.55, -5, 0, 6) },
	{ Priority = 4, Range = 320 }
)
cue(
	"ShieldShatter",
	{ layer("Impact", 0.5, 0.7, 2, 0, 4), layer("Water", 0.28, 1.7, -8, 0, 5) },
	{ Priority = 4, Range = 350 }
)
cue(
	"Roar",
	{ layer("Roar", 0.7, 0.35, 5, 3, -7), layer("Air", 0.3, 0.4, 2, -2, -8), layer("Impact", 0.4, 0.3, 6, -7, -12) },
	{ Priority = 5, Range = 450, Duration = 4 }
)
 
cue("RoyalFinalVacuum", { layer("Air", 0.11, 0.55, -6, -2, 1) }, { Priority = 3, Duration = 0.12, Interval = 0.3 })
cue("ChainRattle", { layer("Rattle", 0.18, 1.8, -8, 2, 5) }, { Interval = 0.18, MaxVoices = 2 })
for name, data in pairs({
	FallingHum = { "Air", 0.6, 0.16 },
	SplitHum = { "Rise", 0.42, 0.08 },
	TornadoWind = { "Air", 0.7, 0.22 },
	CrescentFlame = { "Air", 0.45, 0.10 },
	CloneAura = { "Rise", 1.3, 0.08 },
	ThreadHum = { "Rise", 1.9, 0.07 },
	HandCarry = { "Air", 0.8, 0.15 },
	Sandstorm = { "Air", 0.48, 0.16 },
	LanceFlight = { "Air", 0.8, 0.15 },
	ChainSpin = { "Rattle", 1.5, 0.14 },
	ChainDrag = { "Rattle", 0.7, 0.16 },
	GroundTension = { "Rattle", 0.6, 0.11 },
}) do
	loop(name, table.unpack(data))
end
cue("QTEChain", { layer("Rattle", 0.28, 1.1, -4, 4, 2), layer("Crack", 0.22, 0.7, 0, 3, 2) }, { Priority = 3 })
 
 
for _, name in ipairs({
	"NormalSwing",
	"RangedLaunch",
	"RangedWhoosh",
	"RangedX",
	"TornadoCut",
	"SplitActivate",
	"CrescentRelease",
	"FallingDescend",
}) do
	local previous = cues[name]
	local layers = table.clone(previous.Layers)
	local blade = layer(
		"SwordSlash",
		name == "RangedWhoosh" and 0.11 or 0.32,
		name == "FallingDescend" and 0.8 or 1,
		0,
		1,
		2,
		"Slash"
	)
	if layers[1].ToolSound == "Slash" then
		layers[1] = blade
	else
		table.insert(layers, 1, blade)
	end
	local replacement = table.clone(previous)
	replacement.Layers = table.freeze(layers)
	replacement.MaxVoices = name == "NormalSwing" and 8 or 6
	cues[name] = table.freeze(replacement)
end
for name, asset in pairs({ NormalDraw = "SwordDraw", ThrustStab = "SwordLunge" }) do
	local previous = cues[name]
	local layers = table.clone(previous.Layers)
	layers[1] = layer(asset, 0.28, 1, 0, 1, 2, name == "NormalDraw" and "Unsheath" or "Lunge")
	local replacement = table.clone(previous)
	replacement.Layers = table.freeze(layers)
	cues[name] = table.freeze(replacement)
end
cue(
	"SwordSlash",
	{ layer("SwordSlash", 0.36, 1, 0, 1, 2, "Slash"), layer("Air", 0.1, 1.45, -8, 0, 4) },
	{ MaxVoices = 4, Duration = 1.6 }
)
 
 
magic("TimeConstructCast", 0.76, 0.24)
impact("TimeConstructImpact", 0.64, 0.25)
sweep("GoldenBulletsCast", 1.65, 0.19)
impact("GoldenBulletsImpact", 1.42, 0.17)
magic("TimeBulletsCast", 1.8, 0.2)
impact("TimeBulletsImpact", 1.62, 0.15)
magic("AccelerationCast", 2, 0.23)
magic("DecelerationCast", 0.43, 0.3)
magic("GoldenClockCast", 0.38, 0.4)
impact("GoldenClockImpact", 0.44, 0.42, 4)
magic("StolenSecondCast", 1.24, 0.24)
magic("FalseFutureCast", 1.85, 0.19)
cue(
	"MissingFrameCast",
	{ layer("Crack", 0.19, 2.1, -9, 2, 4), layer("Chime", 0.14, 0.38, -7, 1, 5) },
	{ Duration = 1.1 }
)
magic("LastMinuteCast", 0.34, 0.35)
impact("LastMinuteImpact", 0.36, 0.4, 4)
sweep("KnifeCast", 1.8, 0.24)
impact("KnifeImpact", 1.75, 0.16)
magic("ThiefCast", 0.62, 0.27)
magic("IllusionCast", 1.5, 0.26)
cue(
	"CardBurst",
	{ layer("Crack", 0.18, 1.9, -6, 2, 4), layer("Rise", 0.13, 1.75, -7, 1, 3) },
	{ Duration = 1.4, Interval = 0.14, MaxVoices = 6, VolumeCap = 0.22 }
)
magic("ControlDistortionCast", 0.83, 0.24)
cue(
	"RiftCast",
	{ layer("SwordSlash", 0.33, 0.86, 0, 2, 2, "Slash"), layer("Crack", 0.15, 0.56, 2, -2, -4) },
	{ Duration = 1.8, MaxVoices = 5 }
)
impact("RiftImpact", 0.49, 0.37, 3)
magic("FrozenBulletsCast", 0.92, 0.2)
magic("ClockBladesCast", 0.7, 0.25)
magic("TemporalMarksCast", 0.55, 0.23)
magic("FrozenLancesCast", 0.67, 0.28)
magic("TimeMinesCast", 0.47, 0.23)
magic("Phase2Start", 0.54, 0.35)
magic("Phase25Start", 0.91, 0.29)
cue(
	"Phase3Start",
	{ layer("Rise", 0.28, 0.42, 0, 3, 1), layer("Impact", 0.32, 0.54, 2, -3, -4) },
	{ Priority = 4, Range = 450, Duration = 3 }
)
cue(
	"Phase2WaveWarning",
	{ layer("Chime", 0.2, 0.64, -7, 1, 4), layer("Rise", 0.14, 0.7, -3, 2, 2) },
	{ Priority = 2, Range = 400, Duration = 1.6, Interval = 0.28 }
)
cue(
	"Phase2WaveRelease",
	{ layer("Air", 0.3, 0.64, 0, 2, 1), layer("Crack", 0.21, 0.78, 2, -1, -3) },
	{ Priority = 3, Range = 400, Duration = 2, Interval = 0.25 }
)
cue(
	"Phase3Transform",
	{ layer("Rise", 0.34, 0.4, 1, 3, 0), layer("Chime", 0.19, 0.54, -5, 1, 4) },
	{ Priority = 4, Range = 450, Duration = 3 }
)
 
 
local uploaded = {}
local function exact(name, asset, volume, options)
	options = options or {}
	options.FixedPitch = true
	options.FullLength = true
	options.VolumeCap = 0.22
	options.MaxVoices = options.MaxVoices or 2
	cue(name, { layer(asset, volume, 1) }, options)
	uploaded[name] = Assets[asset]
end
exact("DeathScytheGoodbye", "DeathScytheGoodbye", 0.22, { PreserveStart = true, Priority = 5, Range = 450, Interval = 0.5, MaxVoices = 1 })
exact("SplitActivate", "P1Split", 0.16, { Interval = 0.22, MaxVoices = 2 })
exact("RangedLaunch", "Ranged", 0.13, { Interval = 0.1, MaxVoices = 3 })
exact("CrescentRelease", "Intimidating", 0.16, { Interval = 0.22, MaxVoices = 2 })
exact("TornadoBuild", "Tornado", 0.15, { Interval = 0.45, MaxVoices = 1 })
exact("CataclysmChainSuccess", "CatQTESuccess", 0.16, { Interval = 0.15, MaxVoices = 2 })
exact("CataclysmChainFailure", "CatFailurePull", 0.17, { Interval = 0.15, MaxVoices = 2 })
exact("CataclysmRockThrow", "CatRock", 0.13, { Interval = 0.06, MaxVoices = 3 })
exact("ChainSummon", "GoldenChain", 0.13, { Interval = 0.3, MaxVoices = 1 })
exact("ChainSpin", "GoldenChain", 0.10, { Loop = true, Interval = 0.3, MaxVoices = 1, Range = 120 })
exact("ChainDrag", "GoldenChain", 0.10, { Loop = true, Interval = 0.3, MaxVoices = 1, Range = 120 })
exact("HandSummon", "GoldenHand", 0.15, { Interval = 0.25 })
exact("LanceSummon", "GoldenLance", 0.15, { Interval = 0.25 })
exact("GroundWarning", "GroundChains", 0.13, { Interval = 0.25 })
exact("RainFall", "RainSword", 0.06, { Interval = 0.01, MaxVoices = 3 })
exact("TeleportOut", "Teleport", 0.13, { Interval = 0.25 })
exact("TeleportWarp", "Teleport", 0.13, { Interval = 0.25 })
exact("AccelerationCast", "Acceleration", 0.15, { Interval = 0.3 })
exact("DecelerationCast", "Deceleration", 0.15, { Interval = 0.3 })
exact("GoldenBulletWave", "GoldenBullet", 0.10, { Interval = 0.025, MaxVoices = 2 })
exact("TimeBulletShot", "TimeBullet", 0.055, { Interval = 0, MaxVoices = 4 })
exact("TimeConstructCast", "TimeConstruct", 0.15, { Interval = 0.3 })
exact("MissingFrameCast", "MissingFrame", 0.14, { Interval = 0.3 })
exact("P3Snap", "P3Snap", 0.15, { Interval = 0.08, MaxVoices = 3 })
exact("SplittingSlashRelease", "SplittingSlash", 0.16, { Interval = 0.1, MaxVoices = 3 })
exact("DeathRoarsRoar", "ShieldBreakScream", 0.20, { Loop = true, Interval = 0.5, MaxVoices = 1, Priority = 5, Range = 450 })
exact("DeathRoarsSlash", "DeathRoarsSlash", 0.13, { Loop = true, Interval = 0.1, MaxVoices = 1, Priority = 3, Range = 450 })
exact("P1ShieldBreakScream", "ShieldBreakScream", 0.20, { Interval = 0.5, MaxVoices = 1, Priority = 5, Range = 450 })
exact("PupilSuspense", "PupilSuspense", 0.20, { Interval = 0.2, Priority = 4, Range = 450 })
exact("PupilCorrect", "PupilCorrect", 0.20, { Interval = 0.2, Priority = 4, Range = 450 })
exact("PupilIncorrect", "PupilIncorrect", 0.20, { Interval = 0.2, Priority = 4, Range = 450 })
exact("PupilFirework", "PupilFirework", 0.20, { Interval = 0.2, Priority = 4, Range = 450 })
exact("TimeSave", "TimeConstruct", 0.13, { Interval = 0.3 })
exact("TimeLoad", "TimeConstruct", 0.13, { Interval = 0.3 })
 
exact("EnhancedRangedLaunch", "Ranged", 0.12, { Interval = 0.10, MaxVoices = 3 })
exact("MirrorCast", "P3Snap", 0.12, { Interval = 0.3, MaxVoices = 2 })
exact("ProjectileCast", "TimeConstruct", 0.11, { Interval = 0.3, MaxVoices = 2 })
cue(
	"MirrorBeam",
	{ layer("Chime", 0.06, 0.75, -6, -1, 2), layer("Air", 0.025, 1.1, -8, -3, 0) },
	{ Interval = 0.12, MaxVoices = 2, Duration = 1.6, VolumeCap = 0.12 }
)
cue(
	"MirrorImpact",
	{ layer("Impact", 0.14, 0.65, 1, -3, -5), layer("Crack", 0.06, 1.1, -2, 1, 0) },
	{ Priority = 3, Range = 230, Interval = 0.14, Duration = 1.6, VolumeCap = 0.18 }
)
cue(
	"RoyalImpact",
	{ layer("Impact", 0.18, 0.48, 3, -4, -7), layer("Crack", 0.08, 0.62, 0, 2, 1) },
	{ Priority = 3, Range = 230, Interval = 0.12, MaxVoices = 3, VolumeCap = 0.22 }
)
cue(
	"RoyalFinalImpact",
	{ layer("Impact", 0.20, 0.3, 3, -4, -7), layer("Crack", 0.10, 0.39, 0, 2, 1) },
	{ Priority = 5, Range = 350, Interval = 0.12, MaxVoices = 2, VolumeCap = 0.22 }
)
magic("CataclysmDeclare", 0.7, 0.12)
magic("EtherealChannel", 0.52, 0.18)
cue(
	"CircularBarrageAim",
	{ layer("Chime", 0.04, 1.4, -8, -4, 0) },
	{ Interval = 0.04, MaxVoices = 2, Duration = 0.2, VolumeCap = 0.08 }
)
cue(
	"CardSummon",
	{ layer("Rise", 0.10, 1.25, -6, 1, 2), layer("Crack", 0.055, 1.5, -5, 1, 2) },
	{ Interval = 0.2, MaxVoices = 2, Duration = 1.4, VolumeCap = 0.18 }
)
cue(
	"CardThrow",
	{ layer("Air", 0.065, 1.55, -8, 0, 3), layer("Crack", 0.04, 1.8, -6, 1, 2) },
	{ Interval = 0.03, MaxVoices = 3, Duration = 0.8, VolumeCap = 0.12 }
)
cue(
	"EnhancedNormalDraw",
	{ layer("SwordDraw", 0.12, 1, 0, 1, 1, "Unsheath") },
	{ Interval = 0.1, MaxVoices = 3, Duration = 1, VolumeCap = 0.18 }
)
cue(
	"EnhancedNormalSwing",
	{ layer("SwordSlash", 0.18, 1, 0, 1, 2, "Slash"), layer("Air", 0.04, 1.4, -8, 0, 3) },
	{ Interval = 0.06, MaxVoices = 4, Duration = 1.2, VolumeCap = 0.22 }
)
cue(
	"EnhancedNormalImpact",
	{ layer("Crack", 0.10, 1.2, -2, 1, 2), layer("Impact", 0.065, 1.1, 0, -3, -4) },
	{ Interval = 0.1, MaxVoices = 3, Duration = 1, VolumeCap = 0.18 }
)
local attacks = {}
local function attack(name, cast, hit)
	attacks[name] = table.freeze({ Cast = cast, Impact = hit or "NormalImpact" })
end
attack("P1NormalSlash", "NormalDraw", "NormalImpact")
attack("P1RangedSlashes", "RangedSummon", "RangedImpact")
attack("P1FallingBlade", "FallingCharge", "FallingImpact")
attack("P1GoldenThrust", "ThrustCharge", "ThrustStab")
attack("P1GoldenSplit", "SplitCharge", "RangedImpact")
attack("P1TornadoSlash", "TornadoBuild", "TornadoCut")
attack("P1IntimidatingSlash", "CrescentCharge", "RangedImpact")
attack("P1BlockGrab", "BlockCrack", "BlockImpact")
attack("P1GoldenParry", "ParryStance", "CounterImpact")
attack("P1GildedCataclysm(Ultimate)", "CataclysmDeclare", "CataclysmSlam")
attack("P1.5Teleportation", "TeleportOut", "TeleportIn")
attack("P1.5GildedThread", "ThreadSummon", "ThreadSphereHit")
attack("P1.5Raining", "RainSummon", "RainImpact")
attack("P1.5GoldenHand", "HandSummon", "HandExplosion")
attack("P1.5GoldenLance", "LanceSummon", "LanceImpact")
attack("P1.5GoldenChain", "ChainSummon", "ChainContact")
attack("P1.5GroundChains", "GroundWarning", "GroundErupt")
attack("P1.5RoyalBow(Ultimate)", "RoyalSummon", "RoyalImpact")
attack("P2GoldenBullets", "GoldenBulletsCast", "GoldenBulletsImpact")
attack("P2Save", "TimeSave", "TimeConstructImpact")
attack("P2Load", "TimeLoad", "TimeConstructImpact")
attack("P2TimeBullets", "TimeBulletsCast", "TimeBulletsImpact")
attack("P2Acceleration", "AccelerationCast", "QTESuccess")
attack("P2Deceleration", "DecelerationCast", "GroundLock")
attack("P2GoldenClock(Ultimate)", "GoldenClockCast", "GoldenClockImpact")
attack("P2.5StolenSecond", "StolenSecondCast", "ThreadContact")
attack("P2.5FalseFuture", "FalseFutureCast", "RangedImpact")
attack("P2.5MissingFrame", "MissingFrameCast", "CounterImpact")
attack("P2.5LastMinute(Ultimate)", "LastMinuteCast", "LastMinuteImpact")
attack("P2.5CircularBarrage", "GoldenBulletsCast", "GoldenBulletsImpact")
attack("P3Dash", "ThrustBurst", "Knockback")
attack("P3SplittingSlash", "SwordSlash", "RangedImpact")
attack("P3TargetedKnife", "P3Snap", "KnifeImpact")
attack("P3RiftColumns", "RiftCast", "RiftImpact")
attack("P3Thief", "P3Snap", "ChainContact")
attack("P3Illusion", "P3Snap", "CardBurst")
attack("P3ControlDistortion", "P3Snap", "GroundLock")
attack("P3Projectile", "ProjectileCast", "MirrorImpact")
attack("P3Cards", "CardSummon", "CardBurst")
attack("P3.5TrueIllusion(Ultimate)", "CardSummon", "CardBurst")
attack("P3EtherealAcumen(Ultimate)", "EtherealChannel", "CardBurst")
attack("P4RiftColumn", "RiftCast", "RiftImpact")
attack("P4TargetingKnives", "P3Snap", "KnifeImpact")
attack("P4SplittingSlash", "SwordSlash", "RangedImpact")
attack("P4EnhancedRangedSlashes", "RangedSummon", "RangedImpact")
attack("P4EnhancedNormalSlashes", "EnhancedNormalDraw", "EnhancedNormalImpact")
attack("FrozenGoldenBullets", "FrozenBulletsCast", "GoldenBulletsImpact")
attack("ClockBlades", "ClockBladesCast", "SwordSlash")
attack("TemporalSlashMarks", "TemporalMarksCast", "SwordSlash")
attack("FrozenGoldenLances", "FrozenLancesCast", "LanceImpact")
attack("TimeMines", "TimeMinesCast", "GroundErupt")
local aliases = table.freeze({
	["Golden Thrust"] = "P1GoldenThrust",
	["Tornado Slash"] = "P1TornadoSlash",
	["Ranged slash"] = "P1RangedSlashes",
	["Golden Split"] = "P1GoldenSplit",
	["Intimidating Slash"] = "P1IntimidatingSlash",
	["Falling Blade"] = "P1FallingBlade",
	["Golden Parry"] = "P1GoldenParry",
	["P1.5GildedCataclysm"] = "P1GildedCataclysm(Ultimate)",
	["P1.5GildedCataclysm(Ultimate)"] = "P1GildedCataclysm(Ultimate)",
	 
	["P3RiftColumns"] = "P4RiftColumn",
	["P3TargetedKnife"] = "P4TargetingKnives",
	["P3SplittingSlash"] = "P4SplittingSlash",
})
local hellavenMusic=table.freeze({
 Hero="rbxassetid://130604287239693",ShieldBreak="rbxassetid://70762771235020",
 Phase2="rbxassetid://107416487460868",Phase3="rbxassetid://77498350812884",
 Phase4="rbxassetid://132058286351091",Phase5="rbxassetid://81728038354273",
})
local function musicAsset(key,mode)
 if key=="Phase15" then key="Hero" end
 if key=="SonicBlaster" then return "rbxassetid://108440513814741" end  -- Phase 5's final attack (Combat/P5SonicBlaster)
 return mode=="Hellaven" and hellavenMusic[key] or Assets[key]
end
 -- names shown in the HUD for tracks whose uploaded title is hidden (Roblox shows it as ####)
local trackNames=table.freeze({
 ["rbxassetid://70762771235020"]="Illusionary's Perfect Puppet",
 ["rbxassetid://108440513814741"]="Sonic Blaster",
})
return table.freeze({
 HellavenMusic=hellavenMusic,
 TrackNames=trackNames,
 MusicAsset=musicAsset,
	Assets = Assets,
	Cues = table.freeze(cues),
	MusicVolume = 0.22,
	DialogueMusicScale = 0.45,
	DialogueVoiceVolume = 0.22,
	DialogueVoiceReplayInterval = 0.07,
	MaxVoices = 32,
	MaxLoopVoices = 8,
	MinDistance = 16,
	MaxDistance = 450,
	MusicFadeTime = 1.2,
	UploadedCues = table.freeze(uploaded),
	UploadedVolumeCap = 0.22,
	AssetLoadTimeout = 8,
	Attacks = table.freeze(attacks),
	AttackAliases = aliases,
	AttackCastInterval = 0.25,
	AttackImpactInterval = 0.14,
	PhaseCues = table.freeze({
		[1] = "EntranceReveal",
		[1.5] = "CloneMaterialize",
		[2] = "Phase2Start",
		[2.5] = "Phase25Start",
		[3] = "Phase3Start",
		[4] = "Phase3Start",
	}),
	MusicNames = table.freeze({
		Hero = "Gugustinette - Hero",
		Phase2 = "Phase 2 Soundtrack",
		Phase3 = "Phase 3 Soundtrack",
		Phase4 = "Phase 4 Soundtrack",
  Phase15="Phase 1.5 Soundtrack", Phase5="Phase 5 Soundtrack",
		TrueIllusion = "Big Bang WITH LYRICS",
		ShieldBreak = "Phase 1 Shield Break",
		PickThePupils = "Pick The Pupils Gameshow",
		SonicBlaster = "Sonic Blaster",
	}),
})
