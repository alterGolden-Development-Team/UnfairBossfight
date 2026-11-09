local BattleScaling=require(script.Parent.BattleScaling)
local api = {}
api.Default = "TrueHardcore"
api.Order = table.freeze({ "Hellaven", "TrueHardcore", "Hardcore", "NerfedHardcore", "Easy" })

 
local function profile(t)
  t.Cooldown = t.Cooldown or 1
  t.Recovery = t.Recovery or t.Cooldown
  t.ShowAttackIndicators = t.ShowAttackIndicators ~= false
  t.FinalPhase = t.FinalPhase or 5
  t.Mercy = table.freeze(t.Mercy or {})
  t.PickLines = table.freeze(t.PickLines or {})
  return table.freeze(t)
end

api.Profiles = table.freeze({
  Hellaven = profile({
    Name = "Hellaven",
    ShowAttackIndicators = false,
    Color = Color3.fromRGB(236, 91, 105),
    Description = "Everything is crueler. 1.3x damage, faster and denser attacks, one life. No overhead attack signals.",
    Damage = 1.3,  
    Cooldown = 0.85,  
    Recovery = 0.8,  
    Telegraph = 0.85,  
    ProjectileSpeed = 1.12,
    Density = 1.25,  
    Shield = 1.15,  
    BossHealth = 1.15,
    DebuffDuration = 1.3,  
    PassivePotency = 1.35,  
    PassiveChance = 1.3,  
    BossSustain = 1.5,  
    Penalty = 1.3,  
    Ultimates = true,
    StartingLives = 10000,
    PhaseLives = 0,  
    PlayerReward = 0.75,  
    Mercy = {  
       
      Tell = 0, PostHitGrace = 0, UltimateDamage = 1.25, UltimateDefensePierce = 0.5, AllowPierce = true,
      Control = 1.3, Knockback = 1.2, DashIFrames = 0.28,
       
      ChainAllPhases = true, ChainChance = 0.45, ChainMin = 2, ChainMax = 3, EchoAllPhases = true, Opening = 0, OpeningBonus = 1,
      CataclysmBlocks = { 6, 10 }, CataclysmLaunchGap = 0.08, QTEKeys = 6, QTETime = 3,
       
      Grace = 0.4,  
      HitCap = nil,  
       
      HeavenlyStunGrace = 0,  
      Execution = 1.5,  
      FlowerCenterBomb = true, FlowerDuration = 1.2,  
      BurstSecondWave = true, BurstGaps = 2, BurstGapScale = 0.8,
      OrderBreakTrack = true, OrderBreakLockBefore = 0.12,  
      StarFallWaves = 2, StarFallOnTarget = true,
      Rift = true, RiftDelay = 0.32,
      CrossSplit = true,
    },
    PickLines = {
      "...Hellaven.",
      "You actually chose it. No one chooses it.",
      "Then I won't hold a single thing back. One life. Make it count.",
    },
    DefeatLine = "Hellaven... conquered. You are something else entirely.",
  }),
  TrueHardcore = profile({
    Name = "True Hardcore",
    Color = Color3.fromRGB(232, 185, 92),
    Description = "The fight as it was meant to be. No restraints in either direction.",
    Damage = 1, Cooldown = 1, Recovery = 1, Telegraph = 1, ProjectileSpeed = 1, Density = 1,
    Shield = 1, BossHealth = 1, DebuffDuration = 1, PassivePotency = 1, PassiveChance = 1,
    BossSustain = 1, Penalty = 1, Ultimates = true, StartingLives = 5, PhaseLives = 1,
    PlayerReward = 1,
    Mercy = {
      Tell = 0, PostHitGrace = 0, UltimateDamage = 1, UltimateDefensePierce = 0, AllowPierce = true,
      Control = 1, Knockback = 1, DashIFrames = 0.35,
      ChainAllPhases = false, EchoAllPhases = false, Opening = 0, OpeningBonus = 1,
      CataclysmBlocks = { 3, 8 }, CataclysmLaunchGap = 0.16, QTEKeys = 4, QTETime = 3.5,
      Grace = 1, HitCap = nil, HeavenlyStunGrace = 1, Execution = 1,
      FlowerCenterBomb = false, FlowerDuration = 1, BurstSecondWave = true, BurstGaps = 3, BurstGapScale = 1,
      OrderBreakTrack = false, OrderBreakLockBefore = 0.18, StarFallWaves = 1, StarFallOnTarget = true,
      Rift = true, RiftDelay = 0.45, CrossSplit = true,
    },
    PickLines = {
      "No restraints. No excuses.",
      "This is how I was meant to be fought.",
    },
  }),
  Hardcore = profile({
    Name = "Hardcore",
    Color = Color3.fromRGB(239, 151, 84),
    Description = "A dulled edge. Still dangerous, with a little more room to breathe.",
    Damage = 0.75, Cooldown = 1.25, Recovery = 1.25, Telegraph = 1.15, ProjectileSpeed = 0.95, Density = 0.75,
    Shield = 0.75, BossHealth = 0.9, DebuffDuration = 0.8, PassivePotency = 0.8, PassiveChance = 0.8,
    BossSustain = 0.7, Penalty = 0.75, Ultimates = true, StartingLives = 5, PhaseLives = 1,
    PlayerReward = 1.1,
    Mercy = {
      Tell = 0.12, PostHitGrace = 0.1, UltimateDamage = 0.9, UltimateDefensePierce = 0, AllowPierce = true,
      Control = 0.9, Knockback = 0.9, DashIFrames = 0.38,
      ChainAllPhases = false, ChainMax = 4, EchoAllPhases = false, Opening = 0.5, OpeningBonus = 1.15,
      CataclysmBlocks = { 3, 6 }, CataclysmLaunchGap = 0.22, QTEKeys = 4, QTETime = 4.2,
      Grace = 1.25, HitCap = 0.8, HeavenlyStunGrace = 1.25, Execution = 0.85,
      FlowerCenterBomb = false, FlowerDuration = 0.9, BurstSecondWave = true, BurstGaps = 3, BurstGapScale = 1.2,
      OrderBreakTrack = false, OrderBreakLockBefore = 0.25, StarFallWaves = 1, StarFallOnTarget = true,
      Rift = true, RiftDelay = 0.55, CrossSplit = true,
    },
    PickLines = {
      "A respectable choice.",
      "I'll dull my edge a little. Only a little.",
    },
    DefeatLine = "A hard-fought victory. You've earned my respect.",
  }),
  NerfedHardcore = profile({
    Name = "Nerfed Hardcore",
    FinalPhase = 4,
    Color = Color3.fromRGB(110, 179, 227),
    Description = "Long recovery windows, lighter barrages and weaker passives. Ends after Phase 4.",
    Damage = 0.5, Cooldown = 1.6, Recovery = 1.6, Telegraph = 1.3, ProjectileSpeed = 0.88, Density = 0.5,
    Shield = 0.5, BossHealth = 0.75, DebuffDuration = 0.6, PassivePotency = 0.6, PassiveChance = 0.55,
    BossSustain = 0.45, Penalty = 0.5, Ultimates = true, StartingLives = 5, PhaseLives = 1,
    PlayerReward = 1.25,
    Mercy = {
      Tell = 0.25, PostHitGrace = 0.25, UltimateDamage = 0.8, UltimateDefensePierce = 0, AllowPierce = false,
      Control = 0.75, Knockback = 0.8, DashIFrames = 0.42,
      ChainAllPhases = false, ChainMax = 2, EchoAllPhases = false, Opening = 0.8, OpeningBonus = 1.25,
      CataclysmBlocks = { 3, 5 }, CataclysmLaunchGap = 0.3, QTEKeys = 3, QTETime = 5,
      Grace = 1.5, HitCap = 0.6, HeavenlyStunGrace = 1.6, Execution = 0.7,
      FlowerCenterBomb = false, FlowerDuration = 0.75, BurstSecondWave = true, BurstGaps = 4, BurstGapScale = 1.4,
      OrderBreakTrack = false, OrderBreakLockBefore = 0.35, StarFallWaves = 1, StarFallOnTarget = false,
      Rift = false, RiftDelay = 0.55, CrossSplit = false,
    },
    PickLines = {
      "A gentler trial. Wise, perhaps.",
      "Don't mistake my mercy for weakness.",
    },
    DefeatLine = "Well fought. Next time, perhaps, without my mercy?",
  }),
  Easy = profile({
    Name = "Easy",
    FinalPhase = 4,
    Color = Color3.fromRGB(118, 214, 161),
    Description = "A guided trial through Phase 4: selected skills only, no ultimates and generous recovery.",
    Damage = 0.35, Cooldown = 2, Recovery = 2, Telegraph = 1.5, ProjectileSpeed = 0.8, Density = 0.4,
    Shield = 0.4, BossHealth = 0.6, DebuffDuration = 0.5, PassivePotency = 0.35, PassiveChance = 0.35,
    BossSustain = 0.25, Penalty = 0.3, Ultimates = false, StartingLives = 5, PhaseLives = 2,
    PlayerReward = 1.4,
    Mercy = {
      Tell = 0.45, PostHitGrace = 0.45, UltimateDamage = 0.7, UltimateDefensePierce = 0, AllowPierce = false,
      Control = 0.5, Knockback = 0.65, DashIFrames = 0.5,
      ChainAllPhases = false, ChainMax = 1, EchoAllPhases = false, Opening = 1.2, OpeningBonus = 1.35,
      CataclysmBlocks = { 3, 4 }, CataclysmLaunchGap = 0.35, QTEKeys = 3, QTETime = 5.5,
      Grace = 2.2, HitCap = 0.4, HeavenlyStunGrace = 2, Execution = 0.5,
      FlowerCenterBomb = false, FlowerDuration = 0.6, BurstSecondWave = false, BurstGaps = 5, BurstGapScale = 1.6,
      OrderBreakTrack = false, OrderBreakLockBefore = 0.5, StarFallWaves = 0, StarFallOnTarget = false,
      Rift = false, RiftDelay = 0.6, CrossSplit = false,
    },
    PickLines = {
      "Easy? ...Hah.",
      "Very well. I'll go gentle on you. This once.",
    },
    DefeatLine = "A gentle victory is still a victory. Come back when you're ready for more.",
  }),
})

 
api.EasySkills = table.freeze({
  P1NormalSlash = true, P1RangedSlashes = true, P1FallingBlade = true, P1GoldenThrust = true,
  ["P1.5Teleportation"] = true, ["P1.5GoldenLance"] = true, ["P1.5GoldenHand"] = true,
  P2GoldenBullets = true, P2DirectShot = true, P2Save = true, P2Load = true,
  ["P2.5CircularBarrage"] = true,
  P3Projectile = true, P3Cards = true, P3Illusion = true, ["P3.5IllusionBomb"] = true,
  P4EnhancedNormalSlashes = true, P4EnhancedRangedSlashes = true, P4EnhancedThrust = true,
  P4Burst = true, ["P4.5FlowerField"] = true,
  P1Sniping = true, P1GroundShatter = true, P1FireBullet = true, P1TornadoLeaf = true,
  P1KnifeBarrage = true, P1ContinousStrike = true,
  ["P1Unstoppable(Passive)"] = true, ["P4Regeneration(Passive)"] = true,
})

function api.Id(actor)
  local id = actor and actor:GetAttribute("EncounterDifficulty")
  if not api.Profiles[id] then
    id = workspace:GetAttribute("EncounterStarted") and workspace:GetAttribute("ActiveDifficulty")
      or workspace:GetAttribute("SelectedDifficulty")
  end
  return api.Profiles[id] and id or api.Default
end
 -- The Enraged Gate (Encounter/EnragedGate, workspace EncounterEnraged) starts the fight straight in Phase 5 with the
 -- boss enraged. Every profile is then read through an enraged copy - more damage, shorter cooldowns, recoveries and
 -- telegraphs, denser attacks, a sturdier boss - on top of whichever difficulty was picked; its final phase is 5.
local ENRAGE = { Damage = 1.3, Cooldown = 0.75, Recovery = 0.8, Telegraph = 0.8, ProjectileSpeed = 1.1, Density = 1.25,
  BossHealth = 1.25, BossSustain = 1.3, PassivePotency = 1.2, PassiveChance = 1.2, Shield = 1.2 }
local enragedProfiles = {}
function api.Enraged()
  return workspace:GetAttribute("EncounterEnraged") == true
end
function api.Get(actor)
  local id = api.Id(actor)
  if not api.Enraged() then
    return api.Profiles[id]
  end
  local p = enragedProfiles[id]
  if not p then
    p = table.clone(api.Profiles[id])
    for key, scale in pairs(ENRAGE) do
      if type(p[key]) == "number" then p[key] *= scale end
    end
    p.FinalPhase = 5
    p.Name = p.Name .. " · Enraged"
    p.Enraged = true
    p = table.freeze(p)
    enragedProfiles[id] = p
  end
  return p
end
local VICTORIES=table.freeze({
 Easy=table.freeze({Title="Golden Defeated — A Gentle Victory",Subtitle="Easy trial cleared.",Farewell="A gentle victory is still a victory. Return when you are ready for more."}),
 NerfedHardcore=table.freeze({Title="Golden Defeated — Trial Passed",Subtitle="Nerfed Hardcore trial cleared.",Farewell="You have passed my lesson. Next time, face me without my mercy."}),
 Hardcore=table.freeze({Title="Golden Defeated — Rival Bested",Subtitle="Hardcore trial cleared.",Farewell="A hard-fought victory. You have earned my respect."}),
 TrueHardcore=table.freeze({Title="Golden Defeated — No Restraints",Subtitle="True Hardcore conquered.",Farewell="No restraints. No excuses. You faced everything I am—and prevailed."}),
 Hellaven=table.freeze({Title="Golden Defeated — Hellaven Conquered",Subtitle="One life. No mercy. Victory.",Farewell="Hellaven... conquered. You are something else entirely."}),
})
function api.Victory(actor)
 return VICTORIES[api.Id(actor)]
end
function api.GetStartingLives(actor)
  return api.Get(actor).StartingLives
end
function api.FinalPhase(actor)
  return api.Get(actor).FinalPhase
end
 
function api.Scale(knob, value, actor)
  return value * (api.Get(actor)[knob] or 1)
end
 
function api.Mercy(key, actor)
  return api.Get(actor).Mercy[key]
end
 
 
 
 
local function isArray(t)
  return type(t) == "table" and (#t > 0 or next(t) == nil)
end
local function variantProxy(base, override, overridden)
   
   
  return setmetatable({}, {
    __index = function(_, key)
      local o = override()
      local ov = nil
      if type(o) == "table" then
        ov = o[key]
      end
      local bv = base[key]
      if type(bv) == "table" and not isArray(bv) and (ov == nil or (type(ov) == "table" and not isArray(ov))) then
        local deeper = overridden(key)
        if not deeper then
          return bv
        end
        return variantProxy(bv, function()
          local parent = override()
          if type(parent) == "table" then
            return parent[key]
          end
          return nil
        end, deeper)
      end
      if ov ~= nil then
        return ov
      end
      return bv
    end,
    __iter = function(t)
      local key
      return function()
        key = next(base, key)
        if key ~= nil then
          return key, t[key]
        end
      end
    end,
    __len = function()
      return #base
    end,
  })
end
 
local function overriddenAt(levels)
  return function(key)
    local next_ = {}
    for _, level in ipairs(levels) do
      if type(level) == "table" and type(level[key]) == "table" then
        table.insert(next_, level[key])
      end
    end
    return #next_ > 0 and overriddenAt(next_) or nil
  end
end
function api.Variant(base, variants)
  local levels = {}
  for _, v in pairs(variants) do
    table.insert(levels, v)
  end
  return variantProxy(base, function()
    return variants[api.Id()]
  end, overriddenAt(levels))
end
api.ConfigOverrides = table.freeze({
  Hellaven = table.freeze({
     
    P1SnipingAimDuration = 0.9, P1FireBulletCount = 14, P1FireBulletSpacing = 0.045, P1TornadoLeafSpeed = 75, P1LightningTicks = 8, P1LightningRadius = 26,
    P1KnifeCount = 32, P1KnifeSpreadDegrees = 24, ShieldGateElementalistAttackInterval = 2, ShieldGateSwordsmasterAttackInterval = 0.6, ShieldGateDodgeCooldown = 1.4,
     
    UnstoppableInterval = 7, ClonePassiveCooldown = 9, P3MisdirectionCooldown = 4, FutureSightDodgeMaxDistance = 22, FutureSightCooldown = 35, GoldenMarkMaxStacks = 140,
     
    Phase1Title = "???", Phase2Title = "alterGolden, Warden of the Last Hour", Phase3Title = "alterGolden, Liar of a Hundred Faces",
    Phase35Title = "alterGolden, Mask Without End", Phase4Title = "alterGolden, the Unforgiving", Phase45Title = "alterGolden, Crimson Executioner", Phase5Title = "alterGolden, the Unmaker",
    BossVictoryTitle = "alterGolden, the Unforgiving - Felled",
     
     
    SplitWidth = 15, BlockGrabAimTime = 0.3, BlockGrabWaveRadius = 36, ThrustChargeInterval = 0.15,
    TornadoTickInterval = 0.08, IntimidatingTickInterval = 0.08, GoldenGuardReduction = 0.85,
     
    GoldenChainSpinTurns = 4, GoldenChainRange = 76, GoldenChainSpinDuration = 3.8, GroundChainsTrackingTime = 4.5,
    GoldenHandCarryDuration = 0.8, GoldenHandCarrySpeed = 110, RainingSwordCount = 84, RainingSwordInterval = 0.07, GoldenSandPullSpeed = 18,
     
    GoldenBulletCount = 44, GoldenBulletBurstCount = 4, GoldenBulletBurstInterval = 0.22,
    TimeBulletCount = 26, TimeBulletMinDelay = 4, TimeBulletMaxDelay = 24, P2DirectShotInterval = 0.35,
     
    CircularBarrageShotCount = 36, CircularBarrageShotInterval = 0.06, MissingFrameSkipSeconds = 4,
    FalseFutureFakeDuration = 0.35, StolenSecondReplayDuration = 0.5,
     
    P3CardsMinCount = 14, P3CardsMaxCount = 28, P3CardsThrowInterval = 0.07, P3CardsZigzagAmplitude = 7,
    P3ProjectilePredictionMaxLead = 2, P3ProjectileMirrorCount = 6, P3DashSwordCount = 7, P3DashSwordInterval = 0.2,
    ControlDistortionMaxRotationDegrees = 80, IllusionCount = 3, IllusionCardCount = 18, P3CloneTrapPullSpeed = 140, P3PlayerCloneSwapInterval = 4,
     
    P4EnhancedNormalDashSpeed = 160, P4EnhancedNormalXWidth = 40, P4EnhancedRangedWaveCount = 11, P4EnhancedRangedInterval = 0.12,
    P4KnifePerPlayerCount = 8, P4RiftColumnCount = 16, P4RiftColumnInterval = 0.05, RiftColumnsMainCount = 12,
    SplittingSlashSpinDegreesPerSecond = 650, SplittingSlashStageInterval = 0.26,
     
    RoyalBowNormalChainCount = 3, RoyalBowChainPredictionTime = 0.75, RoyalBowFinalWarningTime = 1.2, RoyalBowFinalImpactRadius = 78,
     
    GoldenHourMaxPreparedCasts = 34, GoldenHourSetupInterval = 0.32, GoldenHourHomingTurnRate = 2.5, GoldenHourHomingDuration = 6.5,
     
    EtherealAcumenDuration = 20, EtherealAcumenCardInterval = 0.65, EtherealAcumenOrbitSpeed = 2.4, EtherealAcumenPullMaxSpeed = 130, EtherealAcumenCardCount = 24,
     
    PickThePupilsRounds = 7,
     
    LastMinuteDuration = 75,
    LastMinuteStages = {
      { At = 0, IntervalMultiplier = 0.62, TemporalAdvance = 1.2, Phase25Weight = 2.6, EchoChance = 0.2, PressureInterval = 6.5, PressureCount = 8 },
      { At = 12, IntervalMultiplier = 0.54, TemporalAdvance = 1.8, Phase25Weight = 3.2, EchoChance = 0.45, PressureInterval = 5, PressureCount = 10 },
      { At = 24, IntervalMultiplier = 0.48, TemporalAdvance = 2.3, Phase25Weight = 3.8, EchoChance = 0.55, PressureInterval = 4, PressureCount = 12 },
      { At = 36, IntervalMultiplier = 0.42, TemporalAdvance = 2.8, Phase25Weight = 4.5, EchoChance = 0.55, PressureInterval = 3.4, PressureCount = 14 },
      { At = 48, IntervalMultiplier = 0.37, TemporalAdvance = 3.3, Phase25Weight = 5.5, EchoChance = 0.65, PressureInterval = 2.8, PressureCount = 16 },
      { At = 60, IntervalMultiplier = 0.32, TemporalAdvance = 3.8, Phase25Weight = 6.5, EchoChance = 0.75, PressureInterval = 2.2, PressureCount = 18 },
    },
  }),
  Hardcore = table.freeze({
    P1SnipingAimDuration = 1.35, P1FireBulletCount = 9, P1KnifeCount = 22, P1LightningTicks = 6, ShieldGateElementalistAttackInterval = 2.8,
    UnstoppableInterval = 12, ClonePassiveCooldown = 14, P3MisdirectionCooldown = 7, FutureSightCooldown = 50,
    Phase1Title = "???", Phase2Title = "alterGolden, Duelist of Time", Phase3Title = "alterGolden, Duelist of Masks",
    Phase35Title = "alterGolden, Master Duelist", Phase4Title = "alterGolden, the Gilded Rival", Phase45Title = "alterGolden, Rival Unbound", Phase5Title = "alterGolden, Rival Ascendant",
    BossVictoryTitle = "alterGolden, the Gilded Rival - Bested",
     
    SplitWidth = 10, BlockGrabAimTime = 0.55, BlockGrabWaveRadius = 25, ThrustChargeInterval = 0.22,
    GoldenChainSpinTurns = 3, GoldenChainRange = 60, GroundChainsTrackingTime = 3, GoldenHandCarryDuration = 0.6,
    RainingSwordCount = 54, RainingSwordInterval = 0.095, GoldenSandPullSpeed = 12,
    GoldenBulletCount = 26, GoldenBulletBurstCount = 3, GoldenBulletBurstInterval = 0.32, TimeBulletCount = 15, P2DirectShotInterval = 0.6,
    CircularBarrageShotCount = 20, CircularBarrageShotInterval = 0.1, MissingFrameSkipSeconds = 3, FalseFutureFakeDuration = 0.55,
    P3CardsMinCount = 7, P3CardsMaxCount = 16, P3CardsThrowInterval = 0.11, P3CardsZigzagAmplitude = 4.5,
    P3ProjectilePredictionMaxLead = 0.8, P3ProjectileMirrorCount = 3, P3DashSwordCount = 4, P3DashSwordInterval = 0.3,
    ControlDistortionMaxRotationDegrees = 45, IllusionCardCount = 10, P3CloneTrapPullSpeed = 95, P3PlayerCloneSwapInterval = 7,
    P4EnhancedNormalDashSpeed = 120, P4EnhancedNormalXWidth = 30, P4EnhancedRangedWaveCount = 7, P4EnhancedRangedInterval = 0.18,
    P4KnifePerPlayerCount = 5, P4RiftColumnCount = 10, P4RiftColumnInterval = 0.08, RiftColumnsMainCount = 8,
    SplittingSlashSpinDegreesPerSecond = 500, SplittingSlashStageInterval = 0.36,
    RoyalBowNormalChainCount = 2, RoyalBowChainPredictionTime = 0.3, RoyalBowFinalWarningTime = 1.9,
    GoldenHourMaxPreparedCasts = 18, GoldenHourSetupInterval = 0.55, GoldenHourHomingTurnRate = 1.5, GoldenHourHomingDuration = 5,
    EtherealAcumenDuration = 13, EtherealAcumenCardInterval = 1.15, EtherealAcumenOrbitSpeed = 1.6, EtherealAcumenPullMaxSpeed = 85, EtherealAcumenCardCount = 14,
    PickThePupilsRounds = 4,
    LastMinuteDuration = 50,
    LastMinuteStages = {
      { At = 0, IntervalMultiplier = 0.8, TemporalAdvance = 1, Phase25Weight = 2, EchoChance = 0.05, PressureInterval = 9, PressureCount = 5 },
      { At = 12, IntervalMultiplier = 0.7, TemporalAdvance = 1.4, Phase25Weight = 2.5, EchoChance = 0.25, PressureInterval = 7, PressureCount = 6 },
      { At = 24, IntervalMultiplier = 0.62, TemporalAdvance = 1.8, Phase25Weight = 3, EchoChance = 0.32, PressureInterval = 6, PressureCount = 8 },
      { At = 36, IntervalMultiplier = 0.56, TemporalAdvance = 2.2, Phase25Weight = 3.5, EchoChance = 0.35, PressureInterval = 5, PressureCount = 9 },
    },
  }),
  NerfedHardcore = table.freeze({
    P1SnipingAimDuration = 1.6, P1FireBulletCount = 7, P1FireBulletSpacing = 0.07, P1TornadoLeafSpeed = 50, P1LightningTicks = 4, P1LightningRadius = 18,
    P1KnifeCount = 16, P1KnifeSpreadDegrees = 14, ShieldGateElementalistAttackInterval = 3.4, ShieldGateSwordsmasterAttackInterval = 1, ShieldGateDodgeCooldown = 3,
    UnstoppableInterval = 15, ClonePassiveCooldown = 18, P3MisdirectionCooldown = 10, FutureSightCooldown = 60, GoldenMarkMaxStacks = 60,
    Phase1Title = "???", Phase2Title = "alterGolden, Keeper of Hours", Phase3Title = "alterGolden, Weaver of Masks",
    Phase35Title = "alterGolden, Grand Weaver", Phase4Title = "alterGolden, the Gilded Mentor", Phase45Title = "alterGolden, the Last Lesson", Phase5Title = "alterGolden, Master Unbound",
    BossVictoryTitle = "alterGolden, the Gilded Mentor - Trial Passed",
     
    SplitWidth = 8, BlockGrabAimTime = 0.7, BlockGrabWaveRadius = 22, ThrustChargeInterval = 0.26,
    GoldenChainSpinTurns = 2, GoldenChainRange = 54, GroundChainsTrackingTime = 2.5, GoldenHandCarryDuration = 0.5,
    RainingSwordCount = 40, RainingSwordInterval = 0.11, GoldenSandPullSpeed = 10,
    GoldenBulletCount = 22, GoldenBulletBurstCount = 2, GoldenBulletBurstInterval = 0.36, TimeBulletCount = 12, P2DirectShotInterval = 0.7,
    CircularBarrageShotCount = 16, CircularBarrageShotInterval = 0.12, MissingFrameSkipSeconds = 2, FalseFutureFakeDuration = 0.65,
    P3CardsMinCount = 6, P3CardsMaxCount = 12, P3CardsThrowInterval = 0.13, P3CardsZigzagAmplitude = 3.5,
    P3ProjectilePredictionMaxLead = 0.3, P3ProjectileMirrorCount = 3, P3DashSwordCount = 3, P3DashSwordInterval = 0.36,
    ControlDistortionMaxRotationDegrees = 35, IllusionCount = 1, IllusionCardCount = 8, P3CloneTrapPullSpeed = 80, P3PlayerCloneSwapInterval = 8,
    P4EnhancedNormalDashSpeed = 110, P4EnhancedNormalXWidth = 26, P4EnhancedRangedWaveCount = 5, P4EnhancedRangedInterval = 0.22,
    P4KnifePerPlayerCount = 4, P4RiftColumnCount = 8, P4RiftColumnInterval = 0.1, RiftColumnsMainCount = 6,
    SplittingSlashSpinDegreesPerSecond = 430, SplittingSlashStageInterval = 0.42,
    RoyalBowNormalChainCount = 1, RoyalBowChainPredictionTime = 0, RoyalBowFinalWarningTime = 2.3, RoyalBowFinalImpactRadius = 45,
    GoldenHourMaxPreparedCasts = 12, GoldenHourSetupInterval = 0.7, GoldenHourHomingTurnRate = 1.1, GoldenHourHomingDuration = 4,
    EtherealAcumenDuration = 10, EtherealAcumenCardInterval = 1.4, EtherealAcumenOrbitSpeed = 1.4, EtherealAcumenPullMaxSpeed = 70, EtherealAcumenCardCount = 12,
    PickThePupilsRounds = 3,
    LastMinuteDuration = 40,
    LastMinuteStages = {
      { At = 0, IntervalMultiplier = 0.9, TemporalAdvance = 0.8, Phase25Weight = 1.8, EchoChance = 0, PressureInterval = 11, PressureCount = 4 },
      { At = 14, IntervalMultiplier = 0.8, TemporalAdvance = 1.1, Phase25Weight = 2.2, EchoChance = 0.15, PressureInterval = 9, PressureCount = 5 },
      { At = 28, IntervalMultiplier = 0.72, TemporalAdvance = 1.4, Phase25Weight = 2.6, EchoChance = 0.2, PressureInterval = 8, PressureCount = 6 },
    },
  }),
  Easy = table.freeze({
    P1SnipingAimDuration = 1.8, P1FireBulletCount = 6, P1KnifeCount = 12, P1TornadoLeafSpeed = 45,
    ShieldGateElementalistAttackInterval = 3.8, ShieldGateSwordsmasterAttackInterval = 1.2, ShieldGateDodgeCooldown = 3.5, UnstoppableInterval = 18,
    Phase1Title = "???", Phase2Title = "alterGolden, Clockwork Friend", Phase3Title = "alterGolden, Trickster of Cups",
    Phase35Title = "alterGolden, Merry Illusionist", Phase4Title = "alterGolden, the Gentle Gilded", Phase45Title = "alterGolden, Bloom of Kindness", Phase5Title = "alterGolden, Starlit Friend",
    BossVictoryTitle = "alterGolden, the Gentle Gilded - Befriended",
     
    SplitWidth = 7, ThrustChargeInterval = 0.3, GoldenHandCarryDuration = 0.45,
    GoldenBulletCount = 16, GoldenBulletBurstCount = 2, GoldenBulletBurstInterval = 0.42, P2DirectShotInterval = 0.85,
    CircularBarrageShotCount = 12, CircularBarrageShotInterval = 0.14,
    P3CardsMinCount = 5, P3CardsMaxCount = 10, P3CardsThrowInterval = 0.16, P3CardsZigzagAmplitude = 3,
    P3ProjectilePredictionMaxLead = 0, P3ProjectileMirrorCount = 2, IllusionCount = 1, IllusionCardCount = 6,
    P4EnhancedNormalDashSpeed = 100, P4EnhancedNormalXWidth = 24, P4EnhancedRangedWaveCount = 4, P4EnhancedRangedInterval = 0.26,
  }),
})
api.SignatureNotes = table.freeze({
  Hellaven = { "Every phase: denser volleys, faster throws, wider lanes", "Mirrors, chains and lances lead your movement", "Falling Blade leaps twice, Golden Lance fires twice, Teleport ambushes behind you", "Normal Slash: 7 swings that aim ahead of you" },
  TrueHardcore = { "Signature skills as designed" },
  Hardcore = { "Every phase: slightly lighter volleys and more space" },
  NerfedHardcore = { "Every phase: sparse volleys, slow throws, narrow lanes", "Mirrors and lances aim where you are", "Normal Slash: 4 swings, Ranged Slashes: 4 waves" },
  Easy = { "Selected skills only, in their gentlest shapes", "Nothing leads your movement", "Normal Slash: 3 swings, Ranged Slashes: 3 waves, long Lance warning" },
})
 
 
api.SkillDesign = table.freeze({
  Hellaven = {
    GoldenParry = { CounterHits = 4 },
    GildedThread = { Speed = 150, ChargeTime = 0.3, ThreadLifetime = 10 },
    Acceleration = { Duration = 14, Windup = 0.18 },
    Deceleration = { Duration = 14 },
    Thief = { AllTargets = true, Windup = 0.12 },
    TargetingKnives = { Extra = 2, HunterEvery = 1, HunterTurn = 3.2, CueScale = 0.65 },
    NormalSlash = { Swings = { 1, 2, 1, 2, 1, 2, 3 }, SwingWindup = 0.05, Lead = 0.25 },
    FallingBlade = { Windup = 0.22, Slams = 2 },
    RangedSlashes = { Waves = 8, Gap = 0.14, Windup = 0.09, XWindup = 0.25 },
    GoldenLance = { Warning = 0.5, Lead = 0.35, LeadCap = 12, Lances = 2 },
    Teleportation = { Windup = 0.1, Ambush = true },
    Save = { Channel = 0.1 },
    Load = { Channel = 0.12 },
  },
  TrueHardcore = {},
  Hardcore = {
    GoldenParry = { CounterHits = 3 },
    GildedThread = { Speed = 115, ChargeTime = 0.45, ThreadLifetime = 7 },
    Acceleration = { Duration = 9 },
    Deceleration = { Duration = 9 },
    Thief = { Windup = 0.3 },
    TargetingKnives = { Extra = 1, HunterEvery = 3, HunterTurn = 1.9, CueScale = 0.9 },
    NormalSlash = { SwingWindup = 0.08 },
    FallingBlade = { Windup = 0.38 },
    RangedSlashes = { Waves = 5, Gap = 0.24, Windup = 0.14, XWindup = 0.42 },
    GoldenLance = { Warning = 0.8, Lead = 0.06, LeadCap = 2 },
    Teleportation = { Windup = 0.25 },
    Save = { Channel = 0.3 },
    Load = { Channel = 0.4 },
  },
  NerfedHardcore = {
    GoldenParry = { CounterHits = 2 },
    GildedThread = { Speed = 100, ChargeTime = 0.55, ThreadLifetime = 6 },
    Acceleration = { Duration = 7, Windup = 0.4 },
    Deceleration = { Duration = 7 },
    Thief = { AllTargets = false, Windup = 0.4 },
    TargetingKnives = { Extra = 0, HunterEvery = 99, HunterTurn = 1.4, CueScale = 1.15 },
    NormalSlash = { Swings = { 1, 2, 1, 3 }, SwingWindup = 0.1 },
    FallingBlade = { Windup = 0.45 },
    RangedSlashes = { Waves = 4, Gap = 0.3, Windup = 0.16, XWindup = 0.5 },
    GoldenLance = { Warning = 0.95, Lead = 0, LeadCap = 0 },
    Teleportation = { Windup = 0.35, MinDistance = 28 },
    Save = { Channel = 0.45 },
    Load = { Channel = 0.6 },
  },
  Easy = {
    GoldenParry = { CounterHits = 2 },
    Acceleration = { Duration = 6, Windup = 0.45 },
    Deceleration = { Duration = 6 },
    Thief = { AllTargets = false, Windup = 0.45 },
    NormalSlash = { Swings = { 1, 2, 3 }, SwingWindup = 0.12 },
    FallingBlade = { Windup = 0.55 },
    RangedSlashes = { Waves = 3, Gap = 0.36, Windup = 0.18, XWindup = 0.6 },
    GoldenLance = { Warning = 1.1, Lead = 0, LeadCap = 0 },
    Teleportation = { Windup = 0.4, MinDistance = 30 },
    Save = { Channel = 0.5 },
    Load = { Channel = 0.7 },
  },
})
function api.Design(skill, key, default, actor)
  local d = api.SkillDesign[api.Id(actor)]
  local entry = d and d[skill]
  local value = entry and entry[key]
  if value == nil then
    return default
  end
  return value
end
function api.ConfigOverride(key)
  local o = api.ConfigOverrides[api.Id()]
  return o and o[key]
end
api.UltimateNotes = table.freeze({
  Hellaven = { "Gilded Cataclysm: 6-10 blocks back-to-back, 6-key break in 3s", "Royal Bow: 3 leading chains, short final warning",
    "Golden Clock: more prepared attacks, sharper homing", "Last Minute: 75s with a brutal 6th stage", "Ethereal Acumen: 20s storm, stronger pull",
    "Pick the Pupils: 7 rounds", "True Illusion: 130 clones that fully lead your movement", "Death Scythe: shorter warning, faster sweep, costs 3 lives",
    "Death Roars: 18s, swarms hunt you closely", "Heavenly Disciple: 180-arrow storm, 40% aimed volleys, wider impacts" },
  TrueHardcore = { "All ultimates as designed", "Heavenly Disciple: 110-arrow storm, 30% aimed volleys" },
  Hardcore = { "Gilded Cataclysm: 3-6 blocks, roomier break", "Royal Bow: 2 chains, light prediction, longer warning", "Last Minute: 50s",
    "Pick the Pupils: 4 rounds", "True Illusion: 80 clones, less lead", "Death Scythe / Death Roars: more warning and space", "Heavenly Disciple: 85-arrow storm, 25% aimed volleys" },
  NerfedHardcore = { "Gilded Cataclysm: 3-5 blocks, 3-key break in 5s", "Royal Bow: 1 chain, no prediction", "Last Minute: 40s, gentle stages",
    "Pick the Pupils: 3 rounds", "True Illusion: 60 clones, no lead, little crossfire", "Death Scythe: long warning, costs 1 life",
    "Death Roars: 10s, swarms lag behind" },
  Easy = { "No ultimates" },
})
function api.Allowed(name, metadata, actor)
  local p = api.Get(actor)
  if metadata and (metadata.NativePhase or 1) > p.FinalPhase then return false end
  if (metadata and metadata.Ultimate or string.find(name, "(Ultimate)", 1, true)) and not p.Ultimates then
    return false
  end
  return api.Id(actor) ~= "Easy" or api.EasySkills[name] == true
    or api.Enraged() and metadata ~= nil and metadata.NativePhase == 5  -- the Enraged Gate opens Phase 5 on Easy too
end
function api.Count(value, actor)
  return math.max(1, math.floor(value * api.Get(actor).Density + 0.5))
end
function api.Damage(amount, actor)
  return amount * api.Get(actor).Damage
end
 
 
function api.Penalty(fraction, actor)
  return math.clamp(fraction * api.Get(actor).Penalty, 0, 0.9)
end

 
 
 
local function set(list)
  local t = {}
  for _, k in ipairs(list) do
    t[k] = true
  end
  return table.freeze(t)
end
local COUNT_EXCLUSIONS = set({
  "GoldenChainSegmentCount", "RoyalBowChainMarkerCount", "GoldenHourMaxPreparedCasts", "P3ProjectileMirrorCount",
  "P3ProjectileMinMirrors", "P3ProjectileMaxMirrors", "EtherealAcumenCardCount", "P3DashSwordCount",
  "LastMinuteMissingFrameMaxCasts", "MissingFrameLastMinuteMaxCasts", "FutureSightCharges", "FalseFutureCharges",
  "P3CloneTrapMaxTriggers", "PickThePupilsRounds", "P3WaveSidesMin", "P3WaveSidesMax",
})
local SHIELD = set({
  "ShieldMaxHealth", "Phase2ShieldMaxHealth", "Phase3ShieldMaxHealth", "Phase4ShieldMaxHealth",
  "Phase15ShieldThreshold", "Phase25ShieldThreshold", "Phase35ShieldThreshold",
})
local CLONE_HEALTH = set({ "TrueCloneMaxHealth", "NormalCloneMaxHealth", "ShieldGateCloneMaxHealth" })
local BOSS_HEALTH = set({ "BossMaxHealth", "Phase3MaxHealth", "Phase2HealthThreshold", "Phase45HealthThreshold", "Phase5HealthThreshold" })
local PROJECTILE_SPEED = set({
  "GoldenBulletSpeed", "TimeBulletSpeed", "TimeBulletApproachSpeed", "CircularBarrageSpeed", "P3CardsSpeed",
  "P4EnhancedRangedSpeed", "P1FireBulletSpeed", "P1KnifeSpeed", "P1TornadoLeafSpeed", "LastMinutePressureSpeed",
  "Phase3WaveSpeed", "P4EnhancedNormalXSpeed", "TargetedKnifeSpeed", "BlockGrabSpeed",
})
 
 
local DEBUFF_DURATION = set({ "GoldenMarkDuration", "ControlDistortionDuration", "ThiefDuration", "GoldenFlameLifetime" })
local PASSIVE_POTENCY = set({
  "Phase4EnragedCritChancePerHit", "Phase4EnragedCritDamagePerHit", "Phase4EnragedDuration",
  "GoldenMarkDamagePerStack",
})
local PASSIVE_CHARGES = set({ "FutureSightCharges", "FalseFutureCharges" })
local SLOWS = set({ "P3CardsSlowAmount" })  
local PASSIVE_CHANCE = set({ "HourDebtProcChance", "ClonePassiveChance", "P3MisdirectionChance", "LinkedSwapChance", "P35DebufferChance" })
local SUSTAIN_UP = set({ "Phase4RegenerationFraction", "UnstoppableShieldRestore" })
local SUSTAIN_DOWN = set({ "TrueCloneReviveDelay", "Phase4RegenerationLockout" })  
local GRACE = set({ "MissingFrameDamageGrace", "TimeResumeGrace" })  
local PLAYER_REWARD = set({ "PickThePupilsRewardHealFraction", "PickThePupilsAttackBoostDuration", "PickThePupilsRegenBoostDuration" })

local function isTelegraph(key)
  if string.find(key, "Sound", 1, true) then
    return false
  end
  return string.match(key, "Warning$") or string.match(key, "WarningTime$") or string.match(key, "Windup$")
    or string.match(key, "AimDuration$") or string.match(key, "AimTime$") or string.match(key, "ReactionCue$")
    or key == "P3MisdirectionClueLead"
end

function api.ConfigValue(key, value)
  local p = api.Get()
  local override = api.ConfigOverride(key)
 if override~=nil then value=override end
 if key=="BossVictoryTitle" then return api.Victory().Title end
  if key == "BossDefeatDialogue" and type(value) == "string" then
    return api.Victory().Farewell or p.DefeatLine or value
  end
  if type(value) ~= "number" then
    return value
  end
  if SHIELD[key] then
    return math.max(1, math.floor(value * p.Shield * BattleScaling.ShieldMultiplier() + 0.5))
  elseif CLONE_HEALTH[key] then
    return math.max(1, math.floor(value * p.Shield + 0.5))
  elseif BOSS_HEALTH[key] then
    return math.max(1, math.floor(value * p.BossHealth * BattleScaling.HealthMultiplier() + 0.5))
  elseif PROJECTILE_SPEED[key] then
    return value * p.ProjectileSpeed
  elseif DEBUFF_DURATION[key] then
    return value * p.DebuffDuration
  elseif PASSIVE_POTENCY[key] then
    return value * p.PassivePotency
  elseif PASSIVE_CHARGES[key] then
    return math.max(1, math.floor(value * p.PassivePotency + 0.5))
  elseif SLOWS[key] then
    return math.clamp(value * p.PassivePotency, 0, 0.9)
  elseif PASSIVE_CHANCE[key] then
    return math.clamp(value * p.PassiveChance, 0, 1)
  elseif SUSTAIN_UP[key] then
    return value * p.BossSustain
  elseif SUSTAIN_DOWN[key] then
    return value / math.max(p.BossSustain, 0.2)
  elseif GRACE[key] then
    return value * (p.Mercy.Grace or 1)
  elseif key == "RoyalBowExecutionRadius" then
    return value * (p.Mercy.Execution or 1)
  elseif PLAYER_REWARD[key] then
    return value * p.PlayerReward
  elseif key == "PickThePupilsRewardAttackMultiplier" then
    return 1 + (value - 1) * p.PlayerReward
  elseif key == "Phase4EnragedMaxCritDamage" then
    return 1 + (value - 1) * p.PassivePotency
  elseif isTelegraph(key) then
    return value * p.Telegraph
  end
  if not COUNT_EXCLUSIONS[key] and (string.match(key, "Count$") or string.match(key, "MaxActive")
    or string.match(key, "MaxQueued") or string.match(key, "MinCount$") or string.match(key, "MaxCount$")
    or string.match(key, "PerVolley$")) then
    return api.Count(value)
  end
  return value
end

local function proxy(baseline, resolve)
  return table.freeze(setmetatable({}, {
    __index = function(_, key)
      return resolve(key, baseline[key])
    end,
    __iter = function()
      local key
      return function()
        key = next(baseline, key)
        if key ~= nil then
          return key, resolve(key, baseline[key])
        end
      end
    end,
    __len = function()
      return #baseline
    end,
  }))
end

function api.WrapConfig(baseline)
   
  return proxy(baseline, api.ConfigValue)
end

 
 
local function pct(multiplier)
  return math.floor(math.abs(multiplier - 1) * 100 + 0.5)
end
local function more(multiplier, up, down, same)
  if math.abs(multiplier - 1) < 0.005 then
    return same
  end
  return string.format(multiplier > 1 and up or down, pct(multiplier))
end
function api.Changes(id)
  local p = api.Profiles[id] or api.Get()
  local boss, passives, you = {}, {}, {}
  local titles = api.ConfigOverrides[id or api.Id()]
  table.insert(boss, "The boss: " .. (titles and titles.Phase4Title or "alterGolden, True Imaginator - Hero"))
  local passiveText = ({
    Hellaven = "Passive - No Mercy: each hit he lands stacks +4% damage (max +40%)",
    TrueHardcore = "Passive - Golden Resolve: below 25% HP he takes 15% less damage",
    Hardcore = "Passive - Duelist's Honor: 4 hits in a row without being hit staggers him",
    NerfedHardcore = "Passive - Mentor's Patience: after he hits you, his next attacks warn twice as long",
    Easy = "Passive - Gentle Heart: every 15s he heals everyone for 6% max HP",
  })[id or api.Id()]
  if passiveText then
    table.insert(boss, passiveText)
  end
  table.insert(boss, string.format("Boss damage x%.3g", p.Damage))
  table.insert(boss, more(1 / p.Recovery, "Attacks come %d%% faster", "Attacks come %d%% slower", "Normal attack pace"))
  table.insert(boss, more(p.Telegraph, "Warnings last %d%% longer", "Warnings are %d%% shorter", "Normal warning time"))
  table.insert(boss, more(p.ProjectileSpeed, "Projectiles %d%% faster", "Projectiles %d%% slower", "Normal projectile speed"))
  table.insert(boss, more(p.Density, "Barrages %d%% denser", "Barrages %d%% lighter", "Full barrages"))
  table.insert(boss, string.format("Final phase: %d", p.FinalPhase))
  table.insert(boss, string.format("Shields x%.3g  ·  Boss HP x%.3g", p.Shield, p.BossHealth))
  table.insert(boss, p.Ultimates and "All ultimates" or "No ultimates · selected skills only · skips Last Minute and True Illusion")
  table.insert(passives, more(p.DebuffDuration, "Debuffs last %d%% longer", "Debuffs last %d%% shorter", "Normal debuff duration"))
  table.insert(passives, more(p.PassivePotency, "Passives %d%% stronger", "Passives %d%% weaker", "Normal passive strength"))
  table.insert(passives, more(p.PassiveChance, "Passives trigger %d%% more often", "Passives trigger %d%% less often", "Normal passive procs"))
  table.insert(passives, more(p.BossSustain, "Boss heals %d%% more", "Boss heals %d%% less", "Normal boss healing"))
  local startingLives = p.StartingLives
  table.insert(you, string.format("%d starting %s  ·  %s", startingLives, startingLives == 1 and "life" or "lives",
    p.PhaseLives == 0 and "no phase bonus lives" or string.format("+%d per new phase", p.PhaseLives)))
  table.insert(you, "Class stats, regeneration and dash costs are independent of difficulty.")
  local m = p.Mercy
  local mercy = {}
  if m.Grace and m.Grace < 1 then
    table.insert(mercy, "NO MERCY: every attack and ultimate, in every phase, loses its safety nets")
  end
  table.insert(mercy, (m.Tell or 0) > 0 and string.format("Every attack gives a %.2gs tell before it starts", m.Tell) or "No tell: attacks start instantly")
  table.insert(mercy, (m.PostHitGrace or 0) > 0 and string.format("%.2gs of protection after every hit you take", m.PostHitGrace) or "No protection after being hit")
  table.insert(mercy, more(m.UltimateDamage or 1, "Ultimates hit %d%% harder", "Ultimates hit %d%% softer", "Normal ultimate damage")
    .. ((m.UltimateDefensePierce or 0) > 0 and string.format(" and pierce %d%% of defense", math.floor(m.UltimateDefensePierce * 100 + 0.5)) or ""))
  table.insert(mercy, m.AllowPierce == false and "Defense and dash i-frames always protect you" or "Piercing attacks ignore Defense and dash i-frames")
  table.insert(mercy, more(m.Control or 1, "Stuns and roots last %d%% longer", "Stuns and roots last %d%% shorter", "Normal stun length")
    .. "  ·  " .. more(m.Knockback or 1, "knockback %d%% stronger", "knockback %d%% weaker", "normal knockback"))
  table.insert(mercy, string.format("Dash invulnerability %.2gs", m.DashIFrames or 0.35))
  table.insert(mercy, m.ChainAllPhases and string.format("Attacks chain into %d-%d move combos in EVERY phase", m.ChainMin or 2, m.ChainMax or 3)
    or ((m.ChainMax or 9) <= 1 and "No combos: one attack at a time" or (m.ChainMax and string.format("Phase 4 combos capped at %d moves", m.ChainMax) or "Phase 4 combos")))
  table.insert(mercy, m.EchoAllPhases and "Hour Debt echoes repeat attacks in every phase" or "Echoes only in the time phases")
  table.insert(mercy, (m.Opening or 0) > 0 and string.format("After every attack he is exposed for %.2gs (+%d%% damage taken)", m.Opening, math.floor(((m.OpeningBonus or 1) - 1) * 100 + 0.5)) or "No openings after attacks")
  table.insert(mercy, more(m.Grace or 1, "Stun / damage grace windows %d%% longer", "Stun / damage grace windows %d%% shorter", "Normal grace windows"))
  table.insert(mercy, m.HitCap and string.format("No single hit can take more than %d%% of your max HP", math.floor(m.HitCap * 100 + 0.5)) or "No one-hit protection")
  table.insert(mercy, "Death Roar drains to 1 HP and blocks healing until the attack ends.")
  table.insert(mercy, (m.HeavenlyStunGrace or 1) <= 0 and "Heavenly Disciple's stuns can chain" or "Heavenly Disciple's stuns can't chain")
  table.insert(mercy, m.FlowerCenterBomb and "Flower Field: a bomb lands on you too (no safe middle)" or string.format("Flower Field: safe middle, fields last x%.3g", m.FlowerDuration or 1))
  table.insert(mercy, m.BurstSecondWave and string.format("Burst: tall second wall with %d gaps", m.BurstGaps) or "Burst: no tall second wall")
  table.insert(mercy, m.OrderBreakTrack and "Order Break: the laser keeps turning toward you" or string.format("Order Break: aim locks %.2gs before firing", m.OrderBreakLockBefore))
  table.insert(mercy, (m.StarFallWaves or 0) == 0 and "Star Slash: no Star Fall" or string.format("Star Slash: %d Star Fall wave%s%s", m.StarFallWaves, m.StarFallWaves > 1 and "s" or "", m.StarFallOnTarget and "" or ", star points only"))
  table.insert(mercy, (m.Rift and "Rip and Tear: Rend Rift erupts" or "Rip and Tear: no Rend Rift") .. "  ·  " .. (m.CrossSplit and "Enhanced Split: Cross Split" or "Enhanced Split: single lane"))
  return { Boss = boss, Passives = passives, You = you, Mercy = mercy, Ultimates = api.UltimateNotes[id] or {}, Signature = api.SignatureNotes[id] or {} }
end

return table.freeze(api)
