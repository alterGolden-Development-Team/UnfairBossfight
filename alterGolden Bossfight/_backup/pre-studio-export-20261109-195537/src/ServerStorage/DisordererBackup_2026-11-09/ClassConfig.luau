--[==[ BACKUP of ReplicatedStorage.BossShared.Classes.ClassConfig (ModuleScript) ]==]
return nil
--[==[
 
 
local api = {}
api.Order = table.freeze({ "Warrior", "Mage", "Tank", "Supporter", "Gambler", "Duelist", "Twinblade", "Disorderer", "TrueWarrior" })
api.Default = "Warrior"  
api.TestingHPEnabled = false
api.TestingHP = 999000
api.DamageMultiplier = 1.5
api.DefenseCap = 0.95
api.Block = table.freeze({ Defense = 0.75, SpeedMultiplier = 0.65, Cooldown = 2 })
api.DashImmunity = 0.35
api.StaminaRegen = 22  
api.StaminaRegenDelay = 0.6
api.HealthRegen = table.freeze({ Delay = 4, Interval = 1 })  -- (Round Z) heals a % of MAX HP per second (class HealthRegenFraction), continuously, once Delay seconds have passed with no damage taken

api.Classes = table.freeze({
  Warrior = table.freeze({
    Name = "Warrior", Color = Color3.fromRGB(226, 92, 76),
    Tagline = "Sword and shield. Guard to build Aegis charges, then spend them on a Shield Charge or an Aegis Burst.",
    HealthRegenFraction = 0.01,
    HP = 150, Stamina = 100, Speed = 22, DashCost = 11,
    Passive = { Name = "Aegis", Text = "Taking damage grants +25% attack and +20% defense for 3 seconds. Guarding (R) turns every blocked hit into an Aegis charge (max 5). Press R just before a hit for a perfect guard: the hit is negated and gives 2 charges. Offensive mode loses the charges after 12s without a hit." },
    M1 = { Name = "Sword Attack", Text = "A sword swing for 140 damage.", Damage = 140, Cooldown = 0.55, Range = 10 },
    F = { Name = "Switch", Text = "Swap between Offensive and Defensive mode. Offensive mode deals +10% damage while the boss has a shield.", Cooldown = 1 },
    C = { Name = "X-Slash / Shield Charge", Text = "Offensive: launch an X-shaped slash for 325 damage. Defensive: raise the shield (+35% defense, faster) and charge along your aim, shield-slamming the boss for 80 damage plus 60 per Aegis charge (spends them all).",
      Cooldown = 12, XDamage = 325, XSpeed = 95, XRange = 120, SlamDefense = 0.35, SlamSpeed = 1.2, SlamDamage = 80, SlamPerCharge = 60, SlamDuration = 1.4 },
    V = { Name = "Conclusion / Aegis Burst", Text = "Offensive: a quick dash that deals 100 damage. Defensive: spend every Aegis charge. You heal 3% max HP per charge, allies within 20 studs heal 1.5%, and everyone in range gets +10% attack per charge for 6s. No lockout.",
      Cooldown = 18, ConclusionDamage = 100, ConclusionDistance = 26, BurstCooldown = 14, BurstSelfHeal = 0.03, BurstAllyHeal = 0.015, BurstAttack = 0.10, BurstDuration = 6, BurstRadius = 20 },
    PassiveAttack = 1.25, PassiveDefense = 0.2, PassiveDuration = 3, ShieldBonus = 1.1,
    GuardSpeed = 0.75, AegisMax = 5, AegisFade = 12, PerfectWindow = 0.3, PerfectGain = 2, BreakDrainCooldown = 8,
  }),
  Mage = table.freeze({
    Name = "Mage", Color = Color3.fromRGB(156, 106, 245),
    Tagline = "Every orb hit spawns more orbs. Spend them to dash, detonate, or summon a clone.",
    HealthRegenFraction = 0.01,
    HP = 110, Stamina = 85, Speed = 20, DashCost = 9,
    Passive = { Name = "Orb Cascade", Text = "Each orb hit summons 2-4 extra orbs near the target. At 50 orbs new orbs overwrite the oldest ones, so the swarm always follows the fight. Taking a hit summons 3 orbs around you (Arcane Recoil)." },
    M1 = { Name = "Orb Shot", Text = "Fire an orb that explodes for 85 damage.", Damage = 85, Cooldown = 0.5, Speed = 120, Range = 140, Radius = 6 },
    F = { Name = "Orb Dash", Text = "Consume 8 nearby orbs (20 studs) to dash; stack +35% defense for 4s (85% cap). Dash again while 8 nearby orbs remain.",
      Cooldown = 14, OrbCost = 8, Distance = 22, DefensePerStack = 0.35, DefenseCap = 0.85, StackDuration = 4, PickupRadius = 20, MinDashInterval = 0.3 },
    C = { Name = "Bombardment / Clone", Text = "Tap: detonate up to 35 orbs, nearest the boss first, for 100 damage each (3500 total base damage cap); leftover orbs stay. Hold: pull every orb into the wand and automatically summon a fighting copy. Aim at any player to copy them; otherwise copy yourself.",
      Cooldown = 35, OrbDamage = 100, TotalDamageCap = 3500, OrbRadius = 16, HoldTime = 0.5, CloneLifetime = 15, CloneHPPerOrb = 20, CloneShotDamage = 30, CloneShotDamagePerOrb = 2, CloneFireInterval = 1, ClonePullDuration = 0.8, CloneSpeed = 18, CloneCopyRange = 120, CloneAimRadius = 12 },
    V = { Name = "Hyper-Laser", Text = "Charge 2.5s, then aim a laser that deals 28 damage per tick for up to 80 ticks and spawns orbs.",
      Cooldown = 65, Charge = 2.5, TickDamage = 28, Ticks = 80, TickInterval = 0.05, Range = 160, OrbEvery = 5 },
    OrbMax = 50, OrbSpawnMin = 2, OrbSpawnMax = 4, RecoilOrbs = 3, RecoilInterval = 0.4,
  }),
  Tank = table.freeze({
    Name = "Tank", Color = Color3.fromRGB(110, 150, 196),
    Tagline = "Armored wall. Gets tougher as HP drops, taunts the boss and shields the team.",
    HealthRegenFraction = 0.0075,
    HP = 300, Stamina = 125, Speed = 18, DashCost = 20, BaseDefense = 0.15, DefenseCap = 0.95,
    Passive = { Name = "Bulwark", Text = "Base defense is 15%. Bulwark adds up to +65% as HP falls, and natural regeneration rises as HP falls (up to +1.25% per second). Total defense caps at 95%." },
    M1 = { Name = "Shield Slam", Text = "Lunge and slam the shield for 175 damage.", Damage = 175, Cooldown = 1.1, Lunge = 10, Range = 9 },
    F = { Name = "Defender", Text = "Hold: a Taunt debuff slows you by 95% and draws every enemy with ring waves. Gain a stacking +70% Defense Boost (95% total cap) and interruption protection. Allies within 25 studs take 25% less damage. 40% of the damage you absorb is stored (max 50% of your HP); release F to blast it back at the boss in a 14-stud shockwave.", Cooldown = 20, Defense = 0.7, DefenseCap = 0.95, SpeedMultiplier = 0.05, HoldLease = 1.25, AllyReduction = 0.25, AllyRadius = 25, StoreFraction = 0.4, StoreCap = 0.5, ShockwaveRadius = 14 },
    C = { Name = "Rampage", Text = "Charge in the aimed direction with +50% defense until you hit the boss, dealing 150 damage and stunning it for 3s.", Cooldown = 45, Defense = 0.5, Speed = 70, MaxTime = 2.5, Stun = 3, Damage = 150 },
    V = { Name = "Almighty", Text = "Give nearby players a shield of 200 HP or half their max HP, whichever is higher.", Cooldown = 80, Shield = 200, Radius = 34 },
    PassiveMin = 0, PassiveMax = 0.65, RegenPerMissing = 0.0125,
  }),
  Supporter = table.freeze({
    Name = "Supporter", Color = Color3.fromRGB(104, 214, 150),
    Tagline = "Heals, saves allies from death, and turns a life into a second wind for everyone.",
    HealthRegenFraction = 0.02,
    HP = 100, Stamina = 100, Speed = 26, DashCost = 11,
    Passive = { Name = "Sanctuary", Text = "Gain 1 life every 120s alive (max 2 per battle). Allies in your aura get +15% HP and stamina regeneration, and the aura removes one debuff from each ally every 10s." },
    M1 = { Name = "Sonar Wave", Text = "A wave that lightly damages the boss and heals allies it passes.", Damage = 90, Heal = 0.05, Cooldown = 0.8, Speed = 75, Range = 70, Radius = 6 },
    F = { Name = "Healing", Text = "Heal an aimed ally for 35% max HP, remove one debuff from them, plus stamina regen and attack for 5s.", Cooldown = 10, StaminaCost = 15, Heal = 0.35, Buff = 5, BuffAttack = 1.2, BuffStamina = 1.5, Range = 80 },
    C = { Name = "Chain of Fate", Text = "Link to the ally under your aim, or the nearest ally in range. Fatal damage leaves them at 1 HP, swaps you, and grants 5s of Undying.", Cooldown = 80, Undying = 5, Range = 80 },
    V = { Name = "Second Wind", Text = "Sacrifice 1 life: everyone revives in place once at full HP with skills restored.", Cooldown = 240 },
    LifeEvery = 120, MaxBonusLives = 2, AuraRadius = 20, AuraRegen = 1.15, AuraCleanseEvery = 10,
  }),
  Gambler = table.freeze({
    Name = "Gambler", Color = Color3.fromRGB(232, 190, 64),
    Tagline = "A handgun and a D20. Natural 1 is a critical failure; natural 20 is a critical success.",
    HealthRegenFraction = 0.0125,
    HP = 110, Stamina = 90, Speed = 23, DashCost = 10,
    Passive = { Name = "Loaded Luck", Text = "A roll of 10 or lower (after Luck) gives +1 Luck, up to 5. Luck is added to your next D20 roll (a natural 1 stays a 1, a natural 20 stays a 20) and adds +5% to Jackpot's win chance per stack. A roll above 10, or a Jackpot win, spends it." },
    M1 = { Name = "Gunshot", Text = "An aimed shot for 200 damage.", Damage = 200, Cooldown = 1, Range = 220 },
    F = { Name = "Roll the Dice", Text = "Throw a numbered D20 (+35% defense while rolling). Natural 1 leaves you at 1 HP (in Phase 5 you take 50% more damage for 8s instead); natural 20 grants the strongest boosts. The result lasts 8s and replaces the last roll.", Cooldown = 12, Roll = 1.5, RollDefense = 0.35, Duration = 8, Phase5Exposed = 0.5, MaxLuck = 5, JackpotLuck = 0.05 },
    C = { Name = "Trusted Gun Companion", Text = "Load six trusted rounds for 12s: 280 damage each at a 0.6s interval, with a 450-damage final round. Accepted hits restore 5 stamina. No misfires.", Cooldown = 30, Duration = 12, Damage = 280, Ammo = 6, FinalDamage = 450, FireInterval = 0.6, StaminaOnHit = 5 },
    V = { Name = "JACKPOT?!?!", Text = "50%: full HP and stamina, +200% attack, +95% defense, +25% speed, +100% stamina regen for 15s. 50%: HP becomes 1 (15% of max HP in Phase 5) and this cooldown is halved; no life is removed.", Cooldown = 120, Duration = 15 },
  }),
  Duelist = table.freeze({
    Name = "Duelist", Exclusive = true, Color = Color3.fromRGB(120, 170, 255),
    Tagline = "EXCLUSIVE. A lightweight swordsman: tempo, blink-steps, phase dashes and a cinematic five-cut waltz.",
    HealthRegenFraction = 0,
    HP = 120, Stamina = 110, Speed = 30, DashCost = 8, BaseDefense = 0.1, NoRegen = true, Lifesteal = 0.08,
    Passive = { Name = "Relentless Tempo", Text = "A successful riposte heals 8% max HP. Successful attacks heal 8% of actual damage dealt (scaled up with your bigger Phase 5 health). Each sword hit: +5% attack speed (max +20%, 4s). Dodging an attack with your dash grants Duelist's Guard: the next hit deals 50% less. No HP regeneration (direct heals still work)." },
    M1 = { Name = "Swift Cuts", Text = "Quick sword strikes, 75 damage each. 0.35s interval.", Damage = 75, Cooldown = 0.35, Range = 9 },
    F = { Name = "Flashstep", Text = "Blink through enemies almost instantly for 150 (i-frames). A hit unlocks a second blink within 3s for 100. 10 stamina per blink.", Cooldown = 7, StaminaCost = 10, Damage = 150, SecondDamage = 100, Distance = 26, Window = 3, Windup = 0.03, BlinkTime = 0.05 },
    C = { Name = "Phasing", Text = "Tap: a short phase dash (i-frames), 150. Tap again within 2.5s for a second dash. Hold 1.5s: a charged phase slash for 450. Invincible from activation through the dash or charge. A hit taken during the first second of the charge is riposted: it blocks the hit, restores 25 stamina and slashes for 400 (cooldown drops to 8s).", Cooldown = 14, SuccessCooldown = 8, CancelCooldown = 4, StaminaCost = 15, SecondStaminaCost = 6, DashDamage = 150, DashDistance = 14, DashTime = 0.15, Window = 2.5, HoldThreshold = 0.2, ChargeTime = 1.5, SlashDamage = 450, SlashDistance = 16, Stance = 1, CounterDamage = 400, CounterStamina = 25 },
    V = { Name = "Final Waltz", Text = "Charge your blade, then blink straight to the boss (within 60 studs; farther away you rush it instead). Five cuts from every direction (100 each), then a 250 finishing slash that sends out a small shockwave. Invincible through the charge, approach, cinematic combo and retreat. Missing: 15s cooldown.", Cooldown = 40, MissCooldown = 15, StaminaCost = 30, CutDamage = 100, Cuts = 5, FinishDamage = 250, ChargeTime = 1.0, TeleportRadius = 60, ShockwaveRadius = 18, ShockwaveDamage = 125 },
    TempoPerHit = 0.05, TempoMax = 4, TempoDuration = 4, GuardDuration = 3, GuardReduction = 0.5, RiposteHeal = 0.08,
  }),
  Twinblade = table.freeze({
    Name = "Twinblade", Exclusive = true, Color = Color3.fromRGB(255, 150, 70), Color2 = Color3.fromRGB(110, 190, 255),
    Tagline = "REWARD. Two blades, no pause. Chain cuts to build Flow, then spend the momentum on a single crushing blow.",
    HealthRegenFraction = 0.015,
    HP = 200, Stamina = 140, Speed = 28, DashCost = 7, BaseDefense = 0.05,
    Passive = { Name = "Twin Flow", Text = "Every landed hit builds Flow (max 10, lasts 8s). Each stack gives +5% attack speed, +4% damage and +3% defense. A hit you take costs 1 stack. At 5+ stacks you cannot be flinched or interrupted. At 10 stacks (Overflow) your reach grows and each hit heals 1% max HP. Your blades glow brighter with every stack." },
    M1 = { Name = "Crossing Cuts", Text = "A five-cut chain, one blade at a time: right diagonal, left diagonal, right sweep, left rising cut, then a crossing finisher that lunges into the target. 110 per cut and 260 on the finisher, 0.22s per cut.", Damage = 110, FinisherDamage = 260, Cooldown = 0.22, Range = 10, Combo = 5, Lunge = 24 },
    F = { Name = "Blade Whirl", Text = "Spin yourself and both swords into a whirlwind for 1.4s: six hits of 90. You take 50% less damage and move at 75% speed. Dashing cancels it. HIDDEN: press F within 3s of landing Sky Cross to unleash Final Destination: you vanish and become a 150x150-stud storm of slashes that cuts the boss and every clone with health inside it, invincible throughout (18 hits of 120, then a 600 finisher).", Cooldown = 7, Damage = 90, Ticks = 6, Duration = 1.4, Defense = 0.5, Speed = 0.75, Radius = 11,
      FinalCooldown = 20, FinalWindow = 3, FinalDuration = 2.4, FinalTicks = 18, FinalDamage = 120, FinalBurst = 600, FinalSize = 150, FinalHeight = 40, FinalSlashes = 48 },
    C = { Name = "Sky Cross", Text = "Leap high into the air, invincible, chain the boss, reel yourself in along the chain and crash down in an X slash, leaving a burning X on the ground: 350 damage in 14 studs. Flow multiplies the damage up to 3x (1050 at 10 stacks).", Cooldown = 10, Damage = 350, Radius = 14, FlowScale = 0.2, Height = 70, RiseTime = 0.42, HangTime = 0.24, FlyTime = 0.34, DiveTime = 0.14, ChainRange = 180, MarkSize = 30, MarkLife = 4 },
    V = { Name = "Twin Spirits", Text = "For 12s two spirit swords fly to the boss and keep cutting it, 80 damage every 0.3s each, wherever it goes. Casting bursts a 360-degree sphere slash for 800, Flow is held at 10 and your normal attack becomes a 360-degree sphere slash for 220.", Cooldown = 45, Duration = 12, Damage = 80, Interval = 0.3, SpinDamage = 220, SpinRadius = 18, SpinInterval = 0.25, BurstDamage = 800, Speed = 200, Reach = 9 },
    FlowMax = 10, FlowDuration = 8, AttackSpeedPerStack = 0.05, DamagePerStack = 0.04, DefensePerStack = 0.03, UninterruptedAt = 5, OverflowRange = 12, OverflowHeal = 0.01,
  }),
  TrueWarrior = table.freeze({
    Name = "True Warrior", Short = "True Warrior", ChampionName = "Champion", Exclusive = true,
    Color = Color3.fromRGB(255, 214, 120), Color2 = Color3.fromRGB(255, 255, 255),
    Tagline = "REWARD. The warrior who beat the hardest fight alone. Terrifying solo, still good in a team. Beat Hellaven solo to become the Champion.",
    HealthRegenFraction = 0.02,
    HP = 260, Stamina = 130, Speed = 26, DashCost = 9, BaseDefense = 0.1,
    Passive = { Name = "Unbroken", Text = "With no allies alive near you: +30% damage and +20% defense. With allies: +10% damage. Champion: +15% HP and one extra life per fight." },
    M1 = { Name = "Judgement Cuts", Text = "A three-hit chain of 150, 150 and a 320 finisher.", Damage = 150, FinisherDamage = 320, Cooldown = 0.4, Range = 11, Combo = 3 },
    F = { Name = "Victorious Throw", Text = "Hurl your shield along your aim. On a hit it deals 200 damage, stuns the boss for 1.5s (3s as Champion; ultimates cannot be stunned) and flies back to you. On a miss it returns from max range.", Cooldown = 14, Damage = 200, Stun = 1.5, ChampionStun = 3, Range = 110, Speed = 170, ReturnSpeed = 210, Radius = 8 },
    C = { Name = "Vow Slash", Text = "Charge for 1.1s with i-frames, then release a supersonic golden slash with unlimited range for 600 damage that leaves a burning line. As Champion it deals double after a successful Counter in the last 6s. Press it within 4s of landing Last Stand to unleash Supreme King Slash.", Cooldown = 16, Damage = 600, Charge = 1.1, Speed = 900, Range = 2000, HitRadius = 13, ChampionMultiplier = 2, PerfectMemory = 6, LineLife = 4,
      SupremeDamage = 3000, SupremeWindow = 4, SupremeCharge = 2, SupremeSwing = 0.38, SupremeLength = 170, SupremeRadius = 28 },
    V = { Name = "Last Stand", Text = "Enter a charging cutscene (invincible), then unleash a 360-degree slash, 75 studs wide, for 400 damage. If it hits the boss: for 15s you cannot be killed and deal +50% damage, and when it ends a finishing slash deals 40% of the damage you dealt meanwhile (max 3000). If it misses, this cooldown is reduced by 35%. Champion cooldown is 75s.", Cooldown = 90, ChampionCooldown = 75, MissCooldownFraction = 0.65, Charge = 1.7, SlashDamage = 400, SlashSize = 75, Duration = 15, Attack = 1.5, FinisherFraction = 0.4, FinisherCap = 3000 },
    R = { Name = "Counter", Text = "Take a counter stance for 0.7s. If you are hit during it, the hit is negated and you answer with a ranged slash for 350 damage.", Cooldown = 5, SuccessCooldown = 2, Window = 0.7, Damage = 350, Speed = 260, Range = 120, HitRadius = 9 },
    SoloDamage = 0.3, SoloDefense = 0.2, TeamDamage = 0.1, ChampionHP = 1.15,
  }),
  Disorderer = table.freeze({
    Name = "Reality Disorderer", Short = "Disorderer", Color = Color3.fromRGB(255, 80, 225), Color2 = Color3.fromRGB(70, 235, 255),
    Tagline = "GAME PASS. Bends the arena's rules: the best ranged damage in the roster, with the whole team stronger beside you.",
    HealthRegenFraction = 0.0125,
    HP = 140, Stamina = 120, Speed = 25, DashCost = 10,
    Passive = { Name = "Glitch", Text = "Static Bolts stack Glitch on the boss (max 8, 8s). Each stack gives you +4% damage and your whole team +3% damage. Every bolt also heals the lowest-HP ally within 30 studs for 0.5% of their max HP." },
    M1 = { Name = "Static Bolt", Text = "A glitching bolt for 130 damage, 0.4s apart. Applies Glitch.", Damage = 130, Cooldown = 0.4, Speed = 150, Range = 140, Radius = 6, GlitchMax = 8, GlitchDuration = 8, AllyHeal = 0.005, HealRange = 30, GlitchSelf = 0.04, GlitchTeam = 0.03 },
    F = { Name = "Misplace", Text = "Swap places with the ally under your aim (both of you are invincible for 0.5s), or jump to the aimed point within 40 studs. Your old spot becomes a static patch that deals 60 every 0.5s for 3s.", Cooldown = 8, StaminaCost = 15, Range = 40, IFrames = 0.5, PatchDamage = 60, PatchTime = 3, PatchInterval = 0.5, PatchRadius = 8 },
    C = { Name = "Redact", Text = "Redact a 14-stud zone at your aim for 5s (+0.5s per Glitch stack). Allies inside take 60% less damage, lose a debuff every second and deal +20% damage. The boss takes 40 every 0.5s while inside.", Cooldown = 28, Radius = 14, Duration = 5, DurationPerGlitch = 0.5, Reduction = 0.6, AllyBoost = 1.2, Damage = 40, Interval = 0.5, Range = 60 },
    V = { Name = "Overwrite", Text = "For 12s every bolt echoes for 60% damage, Glitch is held at 8 stacks and allies within 40 studs deal +25% damage and regain stamina 25% faster. The cast saves a checkpoint of your allies; press V again to reload their position and stamina (their HP is never reduced, and it never revives anyone). Reloading ends Overwrite.", Cooldown = 110, Duration = 12, EchoFraction = 0.6, TeamBoost = 1.25, Radius = 40 },
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
  TrustedGun = { Name = "Trusted Gun", Kind = "buff", Color = Color3.fromRGB(255, 200, 80), Text = "Six trusted rounds: 280 damage, 450 on the final round, no misfires." },
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
  DefenderGuard = { Name = "Defender's Guard", Kind = "buff", Color = Color3.fromRGB(130, 180, 255), Text = "A Tank holding Defender nearby: take 25% less damage." },
  Exposed = { Name = "Exposed", Kind = "debuff", Color = Color3.fromRGB(220, 90, 75), Text = "Natural 1 in Phase 5: take 50% more damage." },
  Stunned = { Name = "Stunned", Kind = "debuff", Color = Color3.fromRGB(255, 240, 120), Text = "The boss is stunned." },
  Unbroken = { Name = "Unbroken", Kind = "buff", Color = Color3.fromRGB(255, 214, 120), Text = "Fighting alone: +30% damage, +20% defense. With allies: +10% damage." },
  LastStand = { Name = "Last Stand", Kind = "buff", Color = Color3.fromRGB(255, 240, 180), Text = "You cannot be killed and deal +50% damage. A finisher follows." },
  CounterStance = { Name = "Counter", Kind = "buff", Color = Color3.fromRGB(255, 236, 170), Text = "The next hit is negated and answered with a ranged slash." },
  SupremeReady = { Name = "King's Vow", Kind = "buff", Color = Color3.fromRGB(255, 170, 70), Text = "Press C now to unleash Supreme King Slash." },
  Aegis = { Name = "Aegis", Kind = "buff", Color = Color3.fromRGB(240, 205, 120), Text = "Aegis charges from guarding. Spend them on Shield Charge or Aegis Burst." },
  Luck = { Name = "Luck", Kind = "buff", Color = Color3.fromRGB(120, 255, 160), Text = "Added to your next D20 roll and to the Jackpot win chance." },
  Stored = { Name = "Stored Damage", Kind = "buff", Color = Color3.fromRGB(140, 200, 255), Text = "Damage absorbed by Defender. Release F to blast it back." },
  TwinFlow = { Name = "Twin Flow", Kind = "buff", Color = Color3.fromRGB(255, 170, 90), Text = "Flow stacks: attack speed, damage and defense." },
  Whirling = { Name = "Blade Whirl", Kind = "buff", Color = Color3.fromRGB(255, 190, 120), Text = "Spinning: 50% less damage taken." },
  TwinSpirits = { Name = "Twin Spirits", Kind = "buff", Color = Color3.fromRGB(150, 210, 255), Text = "Two spirit blades are hunting the boss." },
  FinalReady = { Name = "Final Destination", Kind = "buff", Color = Color3.fromRGB(255, 225, 150), Text = "Press F now to unleash Final Destination." },
  Glitch = { Name = "Glitch", Kind = "buff", Color = Color3.fromRGB(255, 90, 230), Text = "Glitch stacks on the boss: more damage for you and your team." },
  Redacted = { Name = "Redacted", Kind = "buff", Color = Color3.fromRGB(90, 235, 255), Text = "Inside a Redact zone: 60% less damage taken, +20% damage." },
  Overwrite = { Name = "Overwrite", Kind = "buff", Color = Color3.fromRGB(255, 120, 235), Text = "Echoing bolts. Press V to reload the checkpoint." },
  Checkpoint = { Name = "Checkpoint", Kind = "buff", Color = Color3.fromRGB(110, 235, 255), Text = "A checkpoint of your position and stamina is saved." },
})

function api.Get(id)
  return api.Classes[id] or api.Classes[api.Default]
end
function api.GetMaxHealth(id)
  local base = api.TestingHPEnabled and api.TestingHP or api.Get(id).HP
   -- Phase 5's reinforcement: PlayerEncounter.ApplyPhase5Buff sets workspace Phase5HealthMultiplier for the rest of
   -- the encounter, so a respawn or a class swap keeps the bigger health too
  return base * (workspace:GetAttribute("Phase5HealthMultiplier") or 1)
end
return table.freeze(api)

]==]