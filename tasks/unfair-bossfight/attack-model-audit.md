# Boss attack model audit (2026-11-10)

How it was checked: Blender MCP and Roblox Studio MCP both connected. A Play session in the live boss window spawned a fresh
boss per attack and ran `AttackRegistry.For(boss, name).Combo(target)` for every registered attack, logging every Part /
MeshPart / Model it created (shape, size, material) and sampling the boss's Motor6D joints for animation.

## What the numbers say

- 142 attacks registered. 86 produced server-side parts and were logged; 56 produced none (listed under "Not seen").
- **Animation: 0 AnimationTracks on any attack.** The boss is posed only by code tables (`PoseAngles`, `Pose("Idle")` writing
  Motor6D C0). Every attack moves the same 5-10 joints with stiff lerps. So "animation rework" = real keyframed motion.
- Roughly 90% of what attacks spawn is Neon energy (beams, rings, sparks, flashes, streaks). That is fine as procedural VFX
  and is NOT in the rework list.
- Already on Blender meshes: boss sword/crown/horns/pauldrons/cape/belt, death scythe, rain sword, class weapons, arena props.

## Needs a Blender model (solid props built from blocks / cylinders / balls)

| # | Attack(s) | What it builds today | Rework |
|---|-----------|----------------------|--------|
| 1 | P1.5GoldenHand | palm = one 8x8x2.4 block, fingers = ball + cylinder per joint, fingers frozen in one curl | Hand mesh (palm, cuff, gem, claw fingers) + curl animation (open reach, clench on grab) |
| 2 | P1.5GoldenChain, P1.5GroundChains, P1.5RoyalBow chains, P1GildedCataclysm QTE chain | `GoldenChainLink` 0.9x0.4x4.9 blocks (364 in the bow ultimate), ground "sockets" = flat cylinders | Chain link mesh (alternating), ground anchor ring |
| 3 | P1.5GoldenLance, FrozenGoldenLances | spearhead block + SpecialMesh, cylinder collars, neon wings | Lance mesh (head, collar, shaft, fletching) |
| 4 | P1.5RoyalBow (Ultimate) | bow + arrows from parts (`Bow.luau`) | Bow + arrow mesh |
| 5 | P1GildedCataclysm, P5EnhancedGildedCataclysm | `CataclysmDebris` 11x8x12 SmoothPlastic blocks (144-279 per cast) | 3-4 rock chunk meshes |
| 6 | P3Cards, P3.5IllusionGun/TrueIllusion, P3Illusion, P3EtherealAcumen | flat 2.5x3.5x0.1 Neon/plastic blocks as cards | Card mesh with face and back |
| 7 | P3PlayerClone, P5Finality, P5Hyper-lasticBeam | shield from ShieldFace / ShieldFillet / Rivet / ShieldRim blocks (839 parts in one cast) | Single shield mesh |
| 8 | P3Dash, P3Clone, P4Dash trails | boss blade from BladePoint / GripBand / GuardWing blocks | Reuse BossSword mesh |
| 9 | P4TargetingKnives, P1KnifeBarrage | knife = blade block + ball grip + guard block | Knife mesh |
| 10 | P3PickThePupils (Ultimate) | giant hand from Finger/Joint cylinders + balls, barn doors, marquee bulbs | Reuse hand mesh + stage mesh |
| 11 | P3.5MysteriousGuy (Ultimate) | Claw / Forearm SpecialMesh, cloak blocks, 9-stud ball | Creature model with arms and cloak |
| 12 | P2GoldenClock (Ultimate) | AncientClock pediment/gear/glyph blocks and cylinders | Clock tower + animated hands |
| 13 | P4.5FlowerField, P5EnhancedFlowerField, P4.5HeavenlyDisciple | petals and quills = SpecialMesh wedges (1170 petals in one cast) | Lotus petal + feather quill mesh |
| 14 | P5BlackHole, P5NullifiedZone, P5JudgementZone | plain ball / 4x56x2 blocks | Accretion disc + pillar meshes |
| 15 | P1ChainedCombo (hammers), P1ContinousStrike (greatsword) | not reachable in test (needs a shield-break clone); code uses blocks | Hammer + greatsword mesh |

## Animation rework (needs real motion, not just meshes)

1. Golden Hand fingers (reach open, clench).
2. Boss attack poses: windup / strike / recovery are code tables per attack. A shared pose library (sword overhead, thrust, point,
   two-hand slam, cast, throw) driven by an easing curve would replace the stiff lerps on ~60 melee attacks.
3. Card flip, chain swing, clock hands, pupil-hand fingers, creature arms.

## Not seen by the audit (reviewed from code only)

- P5 attacks (about 45) draw on the client in `VFXEngine/Effects/P5Strikes`, `P5Arsenal`, `P5Ascend`, `P5Finale`: almost entirely
  Neon beams, rings and slashes, with a few props (fang, claw, butterfly) that I did not see running.
- Shield-break roles (P1FireBullet, LightningBarrage, TornadoLeaf, Sniping, GroundShatter, KnifeBarrage, ContinousStrike,
  ChainedCombo) need clones in the shield gate; time-stop attacks (ClockBlades, FrozenGoldenBullets/Lances, TimeMines,
  TemporalSlashMarks) need a Golden Hour. P4DeathScythe, P3.5TrueIllusion, P2.5LastMinute, P5Polaris/SilentCut also gated.
- The audit logs what attacks create, not how it looks: no per-attack screenshot review was done.

## Done

- **#1 Golden Hand** (2026-11-10): kit `BossHand` (asset 116565052753361; `lobby/blender/boss_hand.py`) = palm + cuff + 3 finger-bone
  types with claws. `GoldenHand/Visuals.buildHand` builds from it (old primitives stay as the fallback) and returns `SetCurl(amount, flex)`;
  `Behavior` flexes the fingers while reaching and eases to a fist (`curl` 1) on a grab. Run in the live boss window: 45 mesh pieces
  per cast, no errors. NOT yet seen: the grab clench inside a real hit (preview showed all three poses), and the finger joints are a
  little chunky (shrink `GoldDeep_Joint` / tip ball if it bothers).

## Order of work

1. Golden Hand + curl animation  2. Chain link  3. Lance  4. Cards  5. Cataclysm rocks  6. Knife  7. Shield  8. the rest.
Meshes live in kit `BossProps` (`lobby/blender/boss_props.py`), code falls back to the old parts when the mesh is missing.
