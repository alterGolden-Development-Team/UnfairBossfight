 
 
local api = {}
api.Order = table.freeze({ "Warrior", "Mage", "Tank", "Supporter", "Gambler", "Duelist" })
api.Default = "Warrior"  
api.TestingHPEnabled = true
api.TestingHP = 999000
api.DamageMultiplier = 1.5
api.DefenseCap = 0.95
api.Block = table.freeze({ Defense = 0.75, SpeedMultiplier = 0.65, Cooldown = 2 })
api.DashImmunity = 0.35
api.StaminaRegen = 22  
api.StaminaRegenDelay = 0.6
api.HealthRegen = table.freeze({ Delay = 5, Interval = 1 })

api.Classes = table.freeze({
  Warrior = table.freeze({
    Name = "Warrior", Color = Color3.fromRGB(226, 92, 76),
    Tagline = "Sword and shield. Swap between Offensive and Defensive stances.",
    HealthRegenFraction = 0.01,
    HP = 150, Stamina = 100, Speed = 22, DashCost = 11,
    Passive = { Name = "Battle Hardened", Text = "Taking damage grants +25% attack and +20% defense for 3 seconds." },
    M1 = { Name = "Sword Attack", Text = "A sword swing for 140 damage.", Damage = 140, Cooldown = 0.55, Range = 10 },
    F = { Name = "Switch", Text = "Swap between Offensive and Defensive mode.", Cooldown = 1 },
    C = { Name = "X-Slash / Slam", Text = "Offensive: launch an X-shaped slash for 325 damage. Defensive: raise the shield (+35% defense, faster) and charge in a straight line along your aim, shield-slamming the boss for 80 damage.",
      Cooldown = 12, XDamage = 325, XSpeed = 95, XRange = 120, SlamDefense = 0.35, SlamSpeed = 1.2, SlamDamage = 80, SlamDuration = 1.4 },
    V = { Name = "Conclusion / Parry", Text = "Offensive: a quick dash that deals 100 damage. Defensive: parry the next hit for regeneration and an attack boost; a failed parry adds a 10s lockout.",
      Cooldown = 18, ConclusionDamage = 100, ConclusionDistance = 26, ParryWindow = 0.6, ParryFailLock = 10, ParryBuff = 6 },
    PassiveAttack = 1.25, PassiveDefense = 0.2, PassiveDuration = 3,
  }),
  Mage = table.freeze({
    Name = "Mage", Color = Color3.fromRGB(156, 106, 245),
    Tagline = "Every orb hit spawns more orbs. Spend them to dash, detonate, or summon a clone.",
    HealthRegenFraction = 0.0075,
    HP = 100, Stamina = 75, Speed = 20, DashCost = 9,
    Passive = { Name = "Orb Cascade", Text = "Each orb hit summons 2-4 extra orbs near the target (max 50)." },
    M1 = { Name = "Orb Shot", Text = "Fire an orb that explodes for 85 damage.", Damage = 85, Cooldown = 0.5, Speed = 120, Range = 140, Radius = 6 },
    F = { Name = "Orb Dash", Text = "Consume 8 nearby orbs (20 studs) to dash; stack +35% defense for 4s (99% cap). Dash again while 8 nearby orbs remain.",
      Cooldown = 17, OrbCost = 8, Distance = 22, DefensePerStack = 0.35, DefenseCap = 0.99, StackDuration = 4, PickupRadius = 20, MinDashInterval = 0.3 },
    C = { Name = "Bombardment / Clone", Text = "Tap: detonate every orb for 100 damage each (2000 total base damage cap). Hold: pull every orb into the wand and automatically summon a fighting copy. Aim at any player to copy them; otherwise copy yourself.",
      Cooldown = 35, OrbDamage = 100, TotalDamageCap = 2000, OrbRadius = 16, HoldTime = 0.5, CloneLifetime = 15, CloneHPPerOrb = 20, CloneShotDamage = 30, CloneShotDamagePerOrb = 2, CloneFireInterval = 1, ClonePullDuration = 0.8, CloneSpeed = 18, CloneCopyRange = 120, CloneAimRadius = 12 },
    V = { Name = "Hyper-Laser", Text = "Charge 3.5s, then aim a laser that deals 28 damage per tick for up to 80 ticks and spawns orbs.",
      Cooldown = 65, Charge = 3.5, TickDamage = 28, Ticks = 80, TickInterval = 0.05, Range = 160, OrbEvery = 5 },
    OrbMax = 50, OrbSpawnMin = 2, OrbSpawnMax = 4,
  }),
  Tank = table.freeze({
    Name = "Tank", Color = Color3.fromRGB(110, 150, 196),
    Tagline = "Armored wall. Gets tougher as HP drops, taunts the boss and shields the team.",
    HealthRegenFraction = 0.005,
    HP = 300, Stamina = 125, Speed = 16, DashCost = 25, BaseDefense = 0.15, DefenseCap = 0.95,
    Passive = { Name = "Bulwark", Text = "Base defense is 15%. Bulwark adds up to +65% as HP falls. Total defense caps at 95%." },
    M1 = { Name = "Shield Slam", Text = "Lunge and slam the shield for 175 damage.", Damage = 175, Cooldown = 1.4, Lunge = 10, Range = 9 },
    F = { Name = "Defender", Text = "Hold: a Taunt debuff slows you by 95% and draws every enemy with ring waves. Gain a stacking +70% Defense Boost (95% total cap) and interruption protection.", Cooldown = 20, Defense = 0.7, DefenseCap = 0.95, SpeedMultiplier = 0.05, HoldLease = 1.25 },
    C = { Name = "Rampage", Text = "Charge in the aimed direction with +50% defense until you hit the boss, dealing 150 damage and stunning it for 3s.", Cooldown = 45, Defense = 0.5, Speed = 70, MaxTime = 2.5, Stun = 3, Damage = 150 },
    V = { Name = "Almighty", Text = "Give nearby players 200 shield HP.", Cooldown = 100, Shield = 200, Radius = 34 },
    PassiveMin = 0, PassiveMax = 0.65,
  }),
  Supporter = table.freeze({
    Name = "Supporter", Color = Color3.fromRGB(104, 214, 150),
    Tagline = "Heals, saves allies from death, and turns a life into a second wind for everyone.",
    HealthRegenFraction = 0.02,
    HP = 90, Stamina = 95, Speed = 26, DashCost = 11,
    Passive = { Name = "Sanctuary", Text = "Gain 1 life every 120s alive (max 2 per battle). Allies in your aura get +15% HP and stamina regeneration." },
    M1 = { Name = "Sonar Wave", Text = "A wave that lightly damages the boss and heals allies it passes.", Damage = 55, Heal = 0.05, Cooldown = 0.8, Speed = 75, Range = 70, Radius = 6 },
    F = { Name = "Healing", Text = "Heal an aimed ally for 35% max HP, plus stamina regen and attack for 5s.", Cooldown = 10, StaminaCost = 15, Heal = 0.35, Buff = 5, BuffAttack = 1.2, BuffStamina = 1.5, Range = 80 },
    C = { Name = "Chain of Fate", Text = "Link to an ally. Fatal damage leaves them at 1 HP, swaps you, and grants 5s of Undying.", Cooldown = 150, Undying = 5, Range = 80 },
    V = { Name = "Second Wind", Text = "Sacrifice 1 life: everyone revives in place once at full HP with skills restored.", Cooldown = 300 },
    LifeEvery = 120, MaxBonusLives = 2, AuraRadius = 20, AuraRegen = 1.15,
  }),
  Gambler = table.freeze({
    Name = "Gambler", Color = Color3.fromRGB(232, 190, 64),
    Tagline = "A handgun and a D20. Natural 1 is a critical failure; natural 20 is a critical success.",
    HealthRegenFraction = 0.0125,
    HP = 110, Stamina = 90, Speed = 23, DashCost = 10,
    Passive = { Name = "High Roller", Text = "Every effect comes from the die and the gun." },
    M1 = { Name = "Gunshot", Text = "An aimed shot for 200 damage.", Damage = 200, Cooldown = 1, Range = 220 },
    F = { Name = "Roll the Dice", Text = "Throw a numbered D20 (+35% defense while rolling). Natural 1 leaves you at 1 HP; natural 20 grants the strongest boosts. The result lasts 8s and replaces the last roll.", Cooldown = 12, Roll = 1.5, RollDefense = 0.35, Duration = 8 },
    C = { Name = "Trusted Gun Companion", Text = "Load six trusted rounds for 12s: 320 damage each at a 0.6s interval, with a 500-damage final round. Accepted hits restore 5 stamina. No misfires.", Cooldown = 30, Duration = 12, Damage = 320, Ammo = 6, FinalDamage = 500, FireInterval = 0.6, StaminaOnHit = 5 },
    V = { Name = "JACKPOT?!?!", Text = "50%: full HP and stamina, +200% attack, +95% defense, +25% speed, +100% stamina regen for 15s. 50%: HP becomes 1; no life is removed.", Cooldown = 120, Duration = 15 },
  }),
  Duelist = table.freeze({
    Name = "Duelist", Exclusive = true, Color = Color3.fromRGB(120, 170, 255),
    Tagline = "EXCLUSIVE. A lightweight swordsman: tempo, blink-steps, phase dashes and a cinematic five-cut waltz.",
    HealthRegenFraction = 0,
    HP = 120, Stamina = 110, Speed = 30, DashCost = 8, BaseDefense = 0.1, NoRegen = true, Lifesteal = 0.1,
    Passive = { Name = "Relentless Tempo", Text = "Successful attacks heal 10% of actual damage dealt. Each sword hit: +5% attack speed (max +20%, 4s). Dodging an attack with your dash grants Duelist's Guard: the next hit deals 50% less. No HP regeneration (direct heals still work)." },
    M1 = { Name = "Swift Cuts", Text = "Quick sword strikes, 85 damage each. 0.35s interval.", Damage = 85, Cooldown = 0.35, Range = 9 },
    F = { Name = "Flashstep", Text = "Blink through enemies almost instantly for 150 (i-frames). A hit unlocks a second blink within 3s for 100. 8 stamina per blink.", Cooldown = 6, StaminaCost = 8, Damage = 150, SecondDamage = 100, Distance = 26, Window = 3, Windup = 0.03, BlinkTime = 0.05 },
    C = { Name = "Phasing", Text = "Tap: a short phase dash (i-frames), 150. Tap again within 2.5s for a second dash. Hold 1.5s: a charged phase slash for 450. Invincible from activation through the dash or charge. A hit taken during the first second of the charge is riposted: it blocks the hit, restores 25 stamina and slashes for 400 (cooldown drops to 6s).", Cooldown = 14, SuccessCooldown = 6, CancelCooldown = 4, StaminaCost = 15, SecondStaminaCost = 6, DashDamage = 150, DashDistance = 14, DashTime = 0.15, Window = 2.5, HoldThreshold = 0.2, ChargeTime = 1.5, SlashDamage = 450, SlashDistance = 16, Stance = 1, CounterDamage = 400, CounterStamina = 25 },
    V = { Name = "Final Waltz", Text = "Charge your blade, then blink straight to the boss (within 60 studs; farther away you rush it instead). Five cuts from every direction (100 each), then a 250 finishing slash that sends out a small shockwave. Invincible through the charge, approach, cinematic combo and retreat. Missing: 15s cooldown.", Cooldown = 40, MissCooldown = 15, StaminaCost = 30, CutDamage = 100, Cuts = 5, FinishDamage = 250, ChargeTime = 1.0, TeleportRadius = 60, ShockwaveRadius = 18, ShockwaveDamage = 125 },
    TempoPerHit = 0.05, TempoMax = 4, TempoDuration = 4, GuardDuration = 3, GuardReduction = 0.5,
  }),
})

 
api.Statuses = table.freeze({
  Blocking = { Name = "Block", Kind = "buff", Color = Color3.fromRGB(120, 180, 255), Text = "+75% defense, -35% speed." },
  DamageBoost = {Name="Attack Boost",Kind="buff",Color=Color3.fromRGB(255,120,90),Text="Increases outgoing damage. Sources keep their own duration."},
  DefenseBoost = {Name="Defense Boost",Kind="buff",Color=Color3.fromRGB(130,180,255),Text="Increases defense, subject to the class defense cap."},
  HPRegen = {Name="Regeneration",Kind="buff",Color=Color3.fromRGB(140,255,170),Text="Increases HP regeneration."},
  StaminaRegen = {Name="Stamina Regen Boost",Kind="buff",Color=Color3.fromRGB(255,230,100),Text="Increases stamina regeneration."},
  SpeedBoost = {Name="Speed Boost",Kind="buff",Color=Color3.fromRGB(140,220,255),Text="Increases movement speed."},
  Uninterrupted = {Name="Uninterrupted",Kind="buff",Color=Color3.fromRGB(140,190,255),Text="Defender resists combat stuns, restraints and knockback. Time stops and encounter sequences still apply."},
  ShieldRaised = { Name = "Shield Raised", Kind = "buff", Color = Color3.fromRGB(230, 200, 120), Text = "+35% defense, faster charge." },
  ParryStance = { Name = "Parry", Kind = "buff", Color = Color3.fromRGB(255, 236, 150), Text = "The next hit is parried." },
  ParryLocked = { Name = "Parry Locked", Kind = "debuff", Color = Color3.fromRGB(150, 150, 160), Text = "Failed parry: V is locked." },
  LaserCharge = { Name = "Charging", Kind = "buff", Color = Color3.fromRGB(200, 160, 255), Text = "Charging the Hyper-Laser." },
  Taunt = {Name="Taunt",Kind="debuff",Color=Color3.fromRGB(235,144,108),Text="Ring waves draw every enemy toward you. -95% movement speed while Defender is held."},
  Rampage = { Name = "Rampage", Kind = "buff", Color = Color3.fromRGB(150, 190, 240), Text = "+50% defense while charging." },
  Almighty = { Name = "Almighty Shield", Kind = "buff", Color = Color3.fromRGB(120, 210, 255), Text = "Shield HP absorbs damage first." },
  FateLinked = { Name = "Chain of Fate", Kind = "buff", Color = Color3.fromRGB(150, 255, 210), Text = "A fatal hit is prevented once." },
  Undying = { Name = "Undying", Kind = "buff", Color = Color3.fromRGB(255, 255, 255), Text = "Immune to attacks (except life removal)." },
  SecondWind = { Name = "Second Wind", Kind = "buff", Color = Color3.fromRGB(180, 255, 220), Text = "Revive in place once at full HP." },
  Rolling = {Name="Rolling",Kind="buff",Color=Color3.fromRGB(255,230,140),Text="The D20 is rolling."},
  AttackSpeedBoost={Name="Attack Speed Boost",Kind="buff",Color=Color3.fromRGB(255,225,115),Text="Increases basic attack speed."},
  AttackDebuff={Name="Attack Debuff",Kind="debuff",Color=Color3.fromRGB(220,130,105),Text="Reduces outgoing damage."},
  Slow={Name="Slow",Kind="debuff",Color=Color3.fromRGB(150,170,205),Text="Reduces movement speed."},
  StaminaRegenBlock={Name="Stamina Regen Block",Kind="debuff",Color=Color3.fromRGB(145,175,215),Text="Reduces stamina regeneration."},
  TrustedGun = { Name = "Trusted Gun", Kind = "buff", Color = Color3.fromRGB(255, 200, 80), Text = "Six trusted rounds: 320 damage, 500 on the final round, no misfires." },
  Orbs = { Name = "Orbs", Kind = "buff", Color = Color3.fromRGB(200, 170, 255), Text = "Active orbs. Spend them on Orb Dash, Bombardment or Clone." },
  NextLife = { Name = "Next Life", Kind = "buff", Color = Color3.fromRGB(120, 255, 170), Text = "Stay alive to earn another life." },
  SkillStolen = { Name = "Skill Stolen", Kind = "debuff", Color = Color3.fromRGB(190, 120, 255), Text = "The Thief took one of your skills." },
  Tempo = { Name = "Relentless Tempo", Kind = "buff", Color = Color3.fromRGB(150, 190, 255), Text = "+5% attack speed per stack." },
  DuelistGuard = { Name = "Duelist's Guard", Kind = "buff", Color = Color3.fromRGB(200, 220, 255), Text = "The next hit deals 50% less damage." },
  Riposte = { Name = "Riposte", Kind = "buff", Color = Color3.fromRGB(255, 255, 255), Text = "Counter stance." },
  Phasing = { Name = "Phasing", Kind = "buff", Color = Color3.fromRGB(170, 200, 255), Text = "Invincible while moving." },
  FlashstepReady = { Name = "Second Flashstep", Kind = "buff", Color = Color3.fromRGB(120, 170, 255), Text = "Press F again to blink once more." },
  PhasingReady = { Name = "Second Phase", Kind = "buff", Color = Color3.fromRGB(170, 200, 255), Text = "Press C again to phase-dash once more." },
  PhaseCharge = { Name = "Phase Charge", Kind = "buff", Color = Color3.fromRGB(190, 215, 255), Text = "Charging a phase slash. Hold C for 1.5s." },
  WaltzCharge = { Name = "Waltz Charge", Kind = "buff", Color = Color3.fromRGB(150, 195, 255), Text = "Gathering power for the Final Waltz." },
  GuardBroken = {Name="Guard Broken",Kind="debuff",Color=Color3.fromRGB(255,150,70),Text="Block broken; cannot block for 2s."},
  Stunned = { Name = "Stunned", Kind = "debuff", Color = Color3.fromRGB(255, 240, 120), Text = "The boss is stunned." },
})

function api.Get(id)
  return api.Classes[id] or api.Classes[api.Default]
end
function api.GetMaxHealth(id)
  return api.TestingHPEnabled and api.TestingHP or api.Get(id).HP
end
return table.freeze(api)
