return [====[
# alterGolden bossfight — project guide

## Where to edit

| Change | Studio location |
| --- | --- |
| Boss health, shields, attack timings, P3Clone trap settings | ReplicatedStorage → BossShared → Config → EncounterConfig |
| Class health, damage, stamina, speed, regeneration | ReplicatedStorage → BossShared → Classes → ClassConfig |
| Shared dash motion | ReplicatedStorage → BossShared → Config → PlayerMovementConfig |
| Final phase and difficulty tuning | ReplicatedStorage → BossShared → Config → DifficultyConfig |
| Victory badge IDs | ReplicatedStorage → BossShared → Config → VictoryRewardConfig |
| Victory badge awards | BossSystem → Encounter → VictoryRewards |
| Music and sound IDs | ReplicatedStorage → BossShared → Config → CombatAudioConfig |
| Register an attack and its allowed phases | ServerScriptService → BossSystem → Combat → AbilityMetadata |
| Resolve attack modules and create actor-specific attacks | BossSystem → Combat → AttackRegistry |
| Attack weights, cooldown gating, selection | BossSystem → Combat → AttackSelector |
| Boss attack loop | BossSystem → Combat → AttackController |
| Individual attacks | BossSystem → Attacks → phase folder |
| P3Clone decoy trap | BossSystem → Attacks → P3 → P3Clone |
| P3Dash rush and execution | BossSystem → Attacks → P3 → P3Dash |
| Passives | BossSystem → Passives |
| Phase transitions | BossSystem → Phases |
| Time, clone, illusion mechanics | BossSystem → Mechanics → Time / Clones / Reality |
| Boss movement, collision, weapons, guard | BossSystem → Boss |
| Arena geometry, safe placement, story | BossSystem → Encounter |
| Player combat, lives, skills, appearance | BossSystem → Players |
| Server audio, character effects, attack indicator | BossSystem → Presentation |
| Client effects, input, player presentation | StarterPlayer → StarterPlayerScripts → BossClient |
| Boss and player HUD layouts | StarterGui → AlterGoldenBossHUD / PlayerVitalsHUD |
| Boss model and sword assets | ServerStorage → BossEncounter → Templates / Assets |

## Attack child modules (P1 through P4)

Expand an attack ModuleScript in Explorer. Its small entry point preserves the registered attack name. This includes P1.5, P2.5, and Golden Clock's attacks.

- Behavior: server sequence, targeting, hit detection, cancellation and cleanup.
- Visuals: effect and model builders. Its functions take an explicit context and return the builder used by Behavior.
- Style, when present: named color and texture choices. Damage, timings and cooldowns still belong in EncounterConfig.
- Larger effects have additional named children. Royal Bow has Geometry, Particles, Chains, Stage, Bow and Impact. P3Dash has Box and Swords. Ethereal Acumen has Cube and Fireworks. P3Projectile has Mirrors, Beam and Impact. P4RiftColumn has Column.
- Small attacks that delegate to shared time/illusion mechanics keep a Behavior child; their shared system remains the source of those effects.
- Pick the Pupils keeps its existing Capture, Cups, Dialogue, Hands, Stage, Style and Visuals children.

Builder contexts carry the same actor, cast and dependencies as the attack. A get_* callback reads changing sequence state at call time. Keep new effects registered with the supplied cast so cancellation releases them. Behavior aliases script to the attack entry ModuleScript to preserve existing sibling/child paths. Do not move attack entry points or rename their API methods without updating AbilityMetadata and callers.

## P3PlayerClone

The main attack owns capture, spawning, cooldown and lifetime. Appearance copies the selected avatar and equips its sword. Animation animates joints in torso axes with a movement-driven gait and smoothed transitions. Locomotion handles turning, spacing, body-sized collision checks and a consistent route around obstacles. Tactics controls flanking, telegraph-aware dodges, guarded targets and delayed sword strikes. Behavior coordinates those modules, player proximity, swaps, rushes and explosions. Visuals owns the arrival, explosion and swap effects.

Copies last 50 seconds and swap with the original every six seconds. Multiplayer copies rush other players approaching a copy or the original; in solo they fight Golden and rush the original on approach. Swaps grant a short arming grace period.

## Entry points

BossController starts the encounter and owns its entrance/reset lifecycle. FightBootstrap starts player services and equipment handling. Both remain directly inside BossSystem.

## Adding an attack

1. Add its ModuleScript under Attacks in the correct phase folder.
2. Register the exact module name in Combat/AbilityMetadata. Set phase availability, copy restrictions, and ultimate flags there.
3. Return an actor factory with Combo(target), optional CanUse(target), Cooldown, and optional Dispose().
4. Put adjustable values in BossShared/Config/EncounterConfig.

AttackController builds its attack list from AbilityMetadata.ActiveNames. AttackRegistry resolves folders from the same metadata; a second manual attack list is unnecessary.

## P3Clone

P3Clone is an active phase-three attack. It plants one decoy trap, then lets the boss continue its normal attacks. Physical body contact consumes the exact-looking decoy immediately, with no warning disc, and pulls the player toward the boss before queuing an instant P3Dash. The pull works while the boss is busy; the dash waits up to eight seconds for the scheduler. The trap is single-use and is cancelled on expiry, phase change, or encounter end.

Its seven tuning values are grouped after P3DashCooldown in EncounterConfig. P3Dash.Combo(target, options) supports optional Instant and Pull settings; normal scheduler calls preserve the normal startup.

## P3PickThePupils(Ultimate)

A phase-three ultimate with a 60-second cooldown measured after its sequence finishes. Correct guesses and failed guesses both advance the round. Correct guesses launch fireworks and grant all living players two separate 45-second buffs: ATK Boost and HP Regen Boost. StatusEffectService tracks their independent timers; EncounterConfig exposes separate duration values. The encounter ends early if no contestants remain. Solo play uses a golden NPC for the visual puzzle, but penalties always affect the real player.

A failure applies stackable Halved for the rest of that life: the solo player or trapped pupil loses 50% of current maximum HP, and every outside player loses 15%. Current HP scales by the same percentage. The reductions compound, bypass damage shields and cleansing, and reset on death/respawn. Maximum HP below one ends the life. Combat/HealthPenaltyService owns these rules; Config/EncounterConfig contains the fractions. Client HUD text and icons are under BossShared/Presentation and BossClient/Players.

Difficulties: Easy, Medium, AfterImage, Illusion, Insane, DoubleCross (two simultaneous pairs), FalseMemory (gold real swaps mixed with violet illusions), and Carousel (every third shuffle rotates all five cups). Violet illusions move the shells but keep the hidden pupil in its occupied slot. Pad votes, ties and no-vote failures use the same server-side rules in every mode.

The main attack owns round flow and cleanup. Its child ModuleScripts split presentation responsibilities: Style (shared colors/tuning), Visuals (primitive builders, bursts and fireworks), Stage (arena decoration and ambience), Hands (golden hand models), Cups (cup models, spotlights and afterimages), Capture (hand pickup and release), and Dialogue (boss lines). Helpers receive the current cast, round folder or state explicitly so cleanup remains owned by the attack.

PickThePupilsClient owns cameras and round instructions. Completion, cancellation, death and respawn release its camera and bloom. Server cleanup restores pupil appearance, locks, lighting, effects and boss position. Studio-only Combo options support TimeScale and DifficultySequence for gameplay QA.

## P3Projectile presentation

Attacks/P3/P3Projectile/Impact owns the impact flash, segmented shock rings, mirror shards, embers and dust. The old Presentation/P3ProjectileVFX path forwards to that module. P3Projectile/Behavior owns travel, damage and the timed Darkness debuff; Visuals owns the basic rings and spheres. Darkness cleanup in BossCombatEffectsClient remembers engine-rounded property values so the original fog and atmosphere restore exactly.

Ethereal Acumen sends each card volley to every captured player and has a 75-second cooldown. P3Cards successful hits choose one random debuff (HP/stamina regen block, burn, bleed, slow or attack reduction), lasting 5–10 seconds. StatusEffectService owns their expiry and Will of Steel cleansing; EncounterConfig contains their tuning values.

## Ultimate lifecycle and observer mode

Combat/UltimateService owns one ultimate at a time and the shared cooldown. A phase change, encounter end or dead cast task releases stale ownership. Deferred Golden Clock and Last Minute casts retain ownership until their encounter-owned sequence ends.

Last Minute (reworked 2026-10-30 as "Borrowed Time"): during the countdown the boss's shield IS the clock. It starts at LastMinuteDuration x LastMinuteShieldPerSecond x the difficulty's Shield; every point the players break steals 1/LastMinuteShieldPerSecond seconds (LastMinuteEndsAt moves), BossDamageService keeps it at >= 1, and at 1 (or when real + stolen time reaches the duration) the clock shatters and Phase 3 begins. Clock sweeps fire as the clock crosses each revolution plus a final midnight sweep; random echo replays are off (EchoChance 0). Last Minute reaches Phase 3 only after its countdown completes. An interrupted opening or unexpectedly disposed countdown retries at ten shield through the shared cooldown. Player death and respawn do not own the cast. Diagnostic attributes include LastUltimateFailure, LastUltimateRecoveryReason and LastMinuteRecoveryReason.

View as Server excludes players from targeting, time freezes, slowdown, projectile darkness and scythe restraints. Observers do not reduce participating players' sword damage. Normal sword damage is 100 before the existing player-count scaling; normal dash cost is eight stamina. Testing balance overrides have been removed.

## Death Scythe v2

P4DeathScythe(Ultimate)/Behavior owns gameplay and /Visuals owns the world effects. BossShared/Presentation/DeathScythe contains the shared Style, ScytheGeometry and ScytheModel, plus the client-only Cinematic module. DeathScytheClient keeps the jump warning and headcount HUD and drives that cinematic. Death, observer mode, encounter end and camera replacement clean up the local effects.

The welded scythe moves through one root, and world pose updates are capped at 30 per second. Particle bursts use replicated emitter state. The supplied keyboard Preview demo is not installed.

Projectile darkness uses a translucent overlay and 45-stud visibility. EncounterConfig exposes visibility distance, overlay transparency and fog density; the client restores prior lighting when the effect ends.

## Development tools

BossSystem/Development contains Studio-only ForcePhase3Test and ForcePhase4Test helpers. Enable only one when intentionally skipping progression; disable it afterwards.

ServerStorage/BossEncounter/Archive/IntegrationTests holds the previous RevisionGameplayV4 server/client test drivers. Both are disabled and kept outside normal execution locations.

## Code conventions

Use explicit grouped module paths. Keep attack registration in AbilityMetadata. Keep comments that explain cancellation, ownership, replication, or unusual behavior; avoid decorative banners and comments that repeat the code. Sources use consistent Luau formatting.

The original scripts, paths, classes, and disabled states are saved in bossfight-scripts-before.json.


## P1 shield-break attacks

Attacks/P1(ShieldBreak) contains alterGolden/P1Sniping, Elementalist/P1FireBullet and Swordsmaster/P1KnifeBarrage. Each entry returns an actor-specific factory. All five shield-break attacks (including TornadoLeaf and LightningBarrage) now use Behavior, Visuals and Style children; their registered paths and factory APIs are unchanged. Combat/AbilityMetadata registers these as ShieldBreakOnly, excluding them from the normal attack and clone-copy lists.

Mechanics/Clones/ShieldGateAttacks dispatches only the matching role. The factories also reject the wrong actor, an inactive gate, and an early cooldown retry. CloneController schedules Elementalist every 2.5 seconds and Swordsmaster every 0.75 seconds from each attack's start; a running combo finishes before the next attack begins. Shared/ShieldBreakCombat uses the same role-specific cooldowns for all six summon skills. They materialize 12 studs to the left and right of the boss spawn circle, facing into the arena. PhaseController lets Golden fire from the wall perch every fifteen seconds while either clone remains alive.

EncounterConfig exposes the P1Sniping, P1FireBullet, P1FireBurn and P1Knife values. Defaults: sniper 80 damage with a 1.2-second aim warning; ten fire bullets, 5 explosion damage and golden ground flames lasting four seconds with 10 damage per second; twenty-five spreading knives dealing 18 damage each with a backflip. Overlapping flame pools share one burn timer per player and caster. Shared/ShieldBreakCombat owns role validation, player targeting, wall-aware hit sweeps and gate cancellation.

## Server View and phase lives

The owner-only View as Server toggle is an observer mode: normal client rendering remains active, while PlayerObserver excludes the owner from combat target lists and hit/control checks. It does not switch Roblox Studio to its server DataModel view. Enabling it clears existing status effects; the replicated character flag follows respawns. Observers do not prevent defeated combat participants from retrying.

PhaseLifeGrant grants one life on each new higher phase (including 1.5, 2.5 and 3.5), only during a running encounter. PlayerEncounter.GrantLife synchronizes Player and Character; eliminated or execution-pending players do not receive rewards. Repeated/regressed phases do not duplicate rewards. The HUD shows bonus lives beside the five base hearts. Respawn protection follows a consumed life rather than the remaining life count.

The previously missing Elementalist settings now live in EncounterConfig: TornadoLeaf has a 0.6-second windup, four-second lifetime, 60 studs/second speed, five-stud radius, 20 damage and 1.2-second trip. LightningBarrage has a 0.45-second windup, three-second duration, 22-stud radius, 20 initial damage and six five-damage ticks.

## P3.5TrueIllusion(Ultimate)

Behavior owns the sequence, targeting, damage and cleanup. Its children split presentation: Style (tuning, poses, palette), Visuals (rockets, bursts, rings, telegraphs, clones), Launcher (the "Royal Flush" card revolver welded into the boss's RightHand; its four-chamber drum turns to the active suit), Cards (playing-card models: the five-card fan in the LeftHand and the giant finale cards) and Finale (the giant cards' motions, beam and telegraph lines). Parts are registered with the attack's cast so cancellation releases them. The sword is hidden for the ultimate and restored on cleanup.

Sequence: the gun forms from cards and twirls, then fifty clones bloom outward in a wave. Fifty teleport volleys follow (predictive aim, homing hearts, burning clubs, clone crossfire, shuffled suits after volley eight). The 50th clone triggers ROYAL FLUSH: 10 and J dive into closing card prisons, Q and K slam edge-first twice each, and the A becomes a lens for the final beam, which locks 0.35 s before it fires.

BossShared/Presentation/TrueIllusion holds the client Style and Cinematic; BossClient/Presentation/TrueIllusionClient forwards "TrueIllusion" events to it (Intro, Finale, Card, Strike, End). The intro camera, grade, letterbox, title impact frames, volley HUD and card-hand UI are client-only. End is also sent on interruption; death, respawn, View as Server, phase change and encounter end release the camera and grade. Cinematic.Settings has IntroCamera, Shake and Flash switches; ReduceFlashing removes the strobing impact frames.




## P4DeathRoars(Ultimate)

A barrage of yellow-white slashes everywhere. Behavior owns the sequence, targeting, damage and cleanup; Style holds tuning, palette and poses; Visuals draws light streaks (long neon lines across the arena and sky), crescent slashes (two camera-facing Beams on an invisible holder part), swarms, glints, the Last Roar charge and the boss aura. All parts are registered with the attack's cast.

Sequence: the boss blinks to the arena centre. A 2.8 s cinematic follows: the sword is raised and the first streaks fire. Then an 8 s barrage: streaks cross the arena (16 to 38 per second); crescent swarms chase each player, landing where the player was 0.45 s earlier (keep running); random swarms land after a 0.45 s glint. LAST ROAR ends it: a closing shell of light on every player, then a 14-crescent swarm there after 0.85 s.

Damage uses balance {Skill = "P4DeathRoars(Ultimate)", IgnoreDefense = true, IgnoreIFrames = true}. PlayerEncounter whitelists that skill: Defensive is ignored and dash i-frames are pierced (CanReceiveHit's third argument). Respawn protection, ForceFields and time-stop protection still apply.

BossClient/Presentation/DeathRoarsClient handles "DeathRoars" events (Intro, Barrage, LastRoar, Burst, Hit, End): a three-shot intro camera, letterbox, the "DEATH ROARS!" title, grade, screen streaks and cues. Settings at the top: Cinematic, ReduceFlashing, Density. Its child module Spam draws the dense local barrage (faint crescents around you, cuts near you, crescents and cuts all over the arena, long streaks; roughly 1200 to 3000 per second, 500 to 1000 on screen) with pooled Beams on Terrain attachments, so none of it replicates; it caps at 1100 live effects.

## Classes, performance and multiplayer

Player class base stats and ability tuning: BossShared/Classes/ClassConfig.
ClassService owns hit tokens, boss defenses, cast interruption, class state and incoming class damage.
Kits under Players/Classes/Kits contain Warrior, Mage, Tank, Supporter, Gambler and Duelist behavior.
ClassModels builds their gear; the older unused kit Gear builders have been removed.

BossShared/Config/BattleScaling owns participating-player damage and the battle's peak roster scale.
Boss HP, shields and progression thresholds gain 60% for each additional player.
The highest roster size reached during a fight is retained until encounter reset.
Temporary deaths with remaining lives still participate; final elimination, leaving and observer mode do not reduce survivors' damage.
Damage uses the existing 0.5 multiplier per additional participant, returning to 1 for a survivor playing solo.

Combat/DamageTracker owns the leaderstats Damage column and resets it at the next battle start.
It credits accepted HP/shield damage to the attacking player; predicted, parried and immune hits add no damage.
DifficultyConfig.Victory provides each mode's victory title, subtitle and farewell dialogue.
Phase 1.5 judgment only applies after lives have dropped below the player's starting allotment.

Class target queries use CombatRuntime's actor list. Class upkeep and HUD refresh at 10 Hz.
Class animation updates are capped at 30 Hz, reuse pose transforms and skip distant or frozen actors.
Mage summons and Supporter links are cleaned up when their class owner changes or dies.

## Phase limits and victory rewards

Easy and Nerfed Hardcore finish after Phase 4. DifficultyConfig.FinalPhase gates the 4.5 and 5 transitions and filters later skills. Hardcore, True Hardcore and Hellaven continue through Phase 5. The normal defeat presentation runs in every mode.

VictoryRewards snapshots eligible combatants when Golden is defeated and awards the matching difficulty's Roblox badge asynchronously. Badge ownership and pending awards are tracked separately for each badge, so winning one mode never blocks another mode's reward. Observers, permanently defeated players and players who join after the defeat are excluded. API failures retry without blocking the victory presentation.

## Player services

ClassConfig is the source of player combat stats. PlayerEncounter initializes class health and speed before appearance loading. ClassService owns class buffs, skills and health regeneration; R6DashService owns stamina recovery and dash validation. The retired test-health configuration and non-class health-regeneration service have been removed.

## Global attack lifetime rule

AttackLifecycleRules in BossShared/Config applies to existing and future boss attacks. A player death or respawn never owns or ends a boss attack. EffectService casts belong to the caster and expire on their own timeline; boss defeat, phase replacement and encounter reset may still cancel them. Player-only restraints and pulls are released when their character is lost, while the attack and its world visuals continue.

Use core.RetainTarget(target) during an active cast: it returns the living character, a stable last-known-position aim proxy during death, and the new character after respawn. Do not dispose a cast merely because a player target has died. Damage and capture checks must still require a real living player.

For client effects, CinematicReset.Register(script, fullCleanup, resetPlayerView) separates world cleanup from camera/UI cleanup. A missing resetPlayerView callback is a no-op on player death, never a fallback to fullCleanup. World effect timelines continue while personal camera and UI effects are disabled; respawn may restore those views.

## P5Finality

All canonical attack files are under Attacks/P5/P5Finality(Ultimate): Behavior, Style, Geometry, Visuals, Pull, Waves and Presentation. Presentation replicates client-only Geometry/Visuals at runtime. FinalityVFX is only the client event adapter. Geometry drives the same outward-ring timeline for server damage and client drawing.

## VFX engine (ReplicatedStorage.VFXEngine)

All new effects render on each client. Server attack code sends small cues with VFXEngine.Net.Send(effect, stage, data) or tags an invisible carrier part with VFXDecorate plus a VFX attribute; StarterPlayerScripts.VFXEngineClient routes both to VFXEngine.Effects.<Name>.

- Library: role-tagged texture ids (Lib.Id "star.lens", Lib.Find{role="ring",edge="soft"}). Textures come from Alex's VFX Texture Pack (Creator Store 15527901599). Flipbooks need 1024px sheets; the pack's sheets are not, so effects use static textures.
- Core primitives: Sprite (one long-lived particle as an animated billboard or flat decal, curves run on the GPU), Emit, Stream, Beam, Light, Anchor, Group (one call cancels an effect), Step (RenderStepped, Heartbeat in Studio edit so effects can be previewed without playing).
- Sky: a lighting-profile stack (PolarisNight swaps to Assets.PolarisNightSky under a short dark dip and restores the arena afterwards).
- Gotchas: a single particle spawns anywhere inside its parent part, so sprites need a tiny anchor; a Beam's width follows its attachments' Y axis; change scripts with ScriptEditorService:UpdateSourceAsync, not .Source, when they may be open in the editor.

## P5 astral attacks (rebuilt on VFXEngine)

- P5Polaris(Ultimate): night sky + aurora curtains, the north star charges, releases, an 11-bolt constellation volley and finale, then the star itself explodes 1.6 s before the cast ends (constellation stars burst in turn). Only a faint compass ring under the boss and a gate star per bolt as tells.
- P5BlackHole: forms between the boss's raised hands (Style.HoldTime), drifts out and up to hang 40 studs over the landing point (Style.HoverHeight). Pull 11-22 studs/s (PullAccelerationLimit must beat the humanoid's grip); anyone dragged into its 8-stud ground shadow (Style.KillRadius) is executed; the collapse explodes for BurstDamage within BurstRadius. The original client (P5BlackHole.Client via BlackHoleRuntime) draws the hole; VFXEngine.Effects.BlackHoleDebris adds ground chunks spiralling up into it and the explosion visuals.
- P5DyingStar: summon, 7 beams, throw, goes critical for Style.Fuse while small stars strike around it (each with its own blast and an energy tether into the star), then the star detonates (shake, flash, fireball, fragments, rings, pillar).
- P5Borealis: per-target aurora beam (twin helix, hanging curtain crown, pouring light; no ground pattern) that chases for Style.Chase (4.5 s); every beam ends with a flash and withdraws upward into the sky.
- P5IrisStar: a radiant iris star. No minor attacks and no ground marks: its light blinds the closer you are (client overlay), then it collapses and explodes; only the spot directly under it is safe.

Replaced modules and the retired client runtimes are kept in ServerStorage.VFXBackups (Retired holds the old BlackHole/DyingStar/Borealis client pipelines).

## Boss rework roadmap

1. DONE (properties): VFXEngine.Lighting is the single writer of Lighting/Atmosphere properties. Effects push named layers (Arb.Push(id,{Lighting=..,Atmosphere=..},{Priority,Fade}) / Arb.Pop); writes it did not make (server PhaseController, EncounterTheme) become the live base, so restores never go stale. Using it: VFXEngine.Sky (50), HeavenlyDiscipleClient night (40), BossCombatEffectsClient GoldenFog (80). Still direct: per-attack ColorCorrection/Bloom/Blur instances (they stack, but should move to a shared grade).
2. Move remaining server-built visuals (P1-P4, P4.5, P5 HyperElastic/Finality) to VFXEngine effects.
3. DONE: story trimmed to original lines only (verbatim, so DialogueScripts' per-difficulty variants still match; full text in ServerStorage.VFXBackups.EncounterStory_full): opening ~21s->8s, phase 2 reveal ~36s->11s, phase 3 ~11s->4s, phase 4 ~9s->2s, phase 5 ~9s->3s. Scripted cameras off in DeathRoars and HeavenlyDisciple; TrueIllusion's intro camera is back on (2026-10-30: it is the 1 HP last stand); letterbox off in EtherealAcumen. PickThePupils keeps its camera (the cup puzzle needs it); Phase 3's gravity/wave transformation is gameplay and stays.
4. DONE: AttackSelector uses Phase45/Phase5 weight tables, a range factor (sword attacks favoured inside MeleeRange, ranged/area beyond FarRange), a recent-attack penalty (RecentPenalty), and takes a ready ultimate with UltimatePickChance instead of always. Heavy attacks (EncounterConfig.HeavyAttacks + ultimates) never start while another lingers (actor HeavyCasts from P5AstralCore, BlackHoleActive); when the last one ends the boss waits HeavyBreather seconds. Phase 5 runs only its own attacks (no P4 fillers in AllowedPhases). A non-ultimate P5 heavy may start beside lingering astral casts, up to EncounterConfig.Phase5HeavyOverlap at once, never while the black hole or Polaris is active. The filler-debt rule (Phase5FillerBetween, actor attribute FillerDebt) is still there, set to 0; listing a P4 attack's phase 5 in AllowedPhases makes it a filler again.
5. Fewer, sharper moves per phase with a clear visual identity.
6. Central boss state module instead of ad-hoc attributes; split Phase25Controller and PhaseController.
7. Single source for attack client code (no runtime copies in ReplicatedStorage).
8. Fix failing sound ids and placeholder sounds.
9. Studio attack tester panel (cast attack X with protection and cooldowns cleared).

PHASE 5 MODES (2026-10-31, updated in Round I)
Attacks/P5 is split into mode folders: Space (BlackHole, Hyper-lasticBeam, IrisStar, DyingStar), Natural (Borealis, Polaris), Time (Finality), NormalAttack (ClawForward, Assassination, UpperCut, Butterfly, DistortedCounter, GoldenPierce, WildHunt(Ultimate)) and Weapon (P5ModeWeapon). AbilityMetadata gives each entry ModuleFolder "P5/<folder>" and P5Mode. Combat/P5ModeService (ticked by AttackController) keeps a mode for Phase5ModeDuration (30s), then runs Phase5ModeGap (30s) with no mode, never picking the same mode twice in a row; Time is entered only when Finality can be cast. With no mode he uses only the Normal Attack folder (Phase5NormalCombo: 5-6 moves, Phase5NormalAttackGap 0.35s apart, 4s combo cooldown). In a mode he uses only that mode's skills plus his mode weapon (Phase5ModeCombo: 2-4 moves, Phase5ModeAttackGap 0.75s apart). Combat/P5ModeWeapon welds the weapon in his right hand while the mode lasts: Star Saber (Space), Aurora Glaive (Natural), Clock Hand (Time); Attacks/P5/Weapon/P5ModeWeapon swings it. The HUD title shows the mode. The normal attacks share Attacks/Shared/P5StrikeCore (blink, hit, FireClaw, Bolt, Execute, deflect helpers) and draw through VFXEngine.Effects.P5Strikes.
P3.5 BACKGROUND CASTS (2026-10-31): Illusion Bomb holds the boss only for its windup and Mysterious Guy only for its summon; the volleys and the shadow chase run on as casts (PersistsThroughEmitterStun) while he keeps attacking. When the shadow catches someone the boss drops his current attack (new MovementRevision, CancelEmitter) and blinks in for the punch; AttackController waits on MysteriousGuyPunching. The two never overlap each other.
P5 NORMAL ATTACK VFX (2026-10-31, second pass): VFXEngine.Effects.P5Strikes builds its slashes from mesh templates in ReplicatedStorage.VFXEngine.Assets (ArcSlash, StreakSlash, AnimeSlash, MonarchWings; free Creator Store meshes, DoubleSided set in Studio since it can't be set at runtime). A slash is a bright core copy, a coloured glow copy behind it and a StreakSlash swirl, swept and scaled per frame. Claw Forward throws three 30-stud crescents a swing; Upper Cut is a vertical arc in the swing plane sweeping up from the ground while the boss leaps with it; Assassination cuts are black cores with crimson rims that hang, then burst; Butterfly opens the monarch wings and sheds flapping butterfly sprites (the Squash curve fakes the flap). Library textures from the store must use the image id behind the decal (InsertService:LoadAsset(decalId) in Studio shows it); a decal id fails at runtime.
PASSIVES SELF-REPAIR (2026-10-31): the PassiveController record lives on one EffectService cast ("EncounterPassives"). Class stuns and the Mysterious Guy catch (CancelEmitter) and the phase transitions' CancelOwner used to dispose it and nothing restarted it, so every passive (P3.5 Debuffer, P4 Regeneration, True Spirit...) stayed off for the rest of the fight. The cast now has PersistsThroughEmitterStun, and AttackController restarts the record (PassiveController.Running) whenever the fight is running without one.
CLAW FORWARD (2026-10-31, third pass): the claws are drawn like the P4 ranged slash wave, as camera-facing beams along a curve that leads with its bulge, rolled 45 degrees, plus a tip-to-tip Trail and a groove carved in the floor under each claw. Flat meshes facing the camera read as a sliding image.
SHIELD GATE (2026-10-31): alterGolden's own gate skills (ShieldGateAttacks pool: P1Sniping, P1GroundShatter) take turns every P1ShieldGateBossInterval. Ground Shatter: a warning circle at every player's feet for 0.6s, then gold spikes (VFXEngine.Effects.GroundShatter).
DEFLECT (2026-10-31): Combat/DeflectService (server) and BossClient.Presentation.DeflectClient. A deflectable hit calls Deflect.Warn(char, "Tap" or "Hold", lead) just before it lands; only that player sees a shield cue over their own head ("E" or "HOLD E" with a fill bar), and it disappears afterwards. Tap = press E within DeflectTapWindow of the hit; Hold = E held for DeflectHoldTime. A deflected hit deals nothing (Deflect.TryDeflect). The P5 guide (P5TPClient) teaches it after the TP bar lines. The TP bar's godmode break moved from E to Z.
P5 NORMAL ATTACKS (Round I): Claw Forward's claws are Tap-deflectable, and the combo ends with a 5-claw finisher that can't be deflected. Assassination (2 lives on a hit) and Upper Cut blink behind the target with the P1.5 Teleportation flash. An Upper Cut hit arms P5GoldenPierce (Phase5Combos): a circle spell, then 9 rapid piercing shots. Distorted Counter: a small yellow circle stance (actor CounterStanceUntil); BossDamageService catches a player hit during it, and he answers with a piercing gold shot. Butterfly beats his own back wings (Phase5Transition.BeatWings) and has a wider thrust hitbox.
WILD HUNT (P5WildHunt(Ultimate)): two lunges, claw slices (Tap), a dragging bite and pierce shot (Hold), an explosion, then the P4 Death Scythe (the scythe's Behavior api.Forced lets it run inside another ultimate). The first Wild Hunt of a fight calls Encounter/ArenaRuin.Ruin(boss): every client (ArenaRuinClient) deletes the castle walls, the arena border wall and the scenery outside the floor, leaves charred rubble and golden fires, and lights a ring of big golden fires along the rim. BossShared.Config.ArenaRuinFires lays the ring out (seeded, shared by client and server), and the server burns anyone touching a rim fire for ArenaFireDamage (50) every ArenaFireTick (0.1s). The flames are layered stylized fire: soft glow, a recoloured flipbook body, toon flame tongues, a white-gold core, embers. Everything is restored when the encounter ends; later Wild Hunts only use the scythe.
ROUND J (2026-11-01):
MODES: the weapon swing (M1) is gone from the modes (P5ModeService.Allows "Weapon" is false). Only Natural carries a mode weapon (the Aurora Glaive). Phase 5 always opens in Natural. Space floats him (boss attribute P5Floating; Boss/BossLocomotion lifts the joint under the root, legs dangling). BossClient.Presentation.P5ModeAuraClient draws Time's gold clock behind his back (SurfaceGuis), Natural's ice-neon glowing hands, Space's falling star dust, and the Enraged aura.
TIME MODE: P5GoldenEternity (Phase 2's Golden Clock, far stronger): "Eternity." A sky clock appears, then TimeEffectController.StopTime for 3.4s. He blinks behind every frozen player and hangs a sphere of blades around them; when time resumes they all strike (Hold Deflect) and a shockwave rolls out. P5Overclock (Acceleration and Deceleration together): AccelerateBoss for 8s, every player decelerated to half time for 5s, then fans of clock-hand shots (Tap Deflect). Finality is still there.
NEW NORMAL ATTACKS: P5Slam (raised left arm, giant spikes and a fast shockwave). P5Viper (a yellow lane warning, a 110-stud snake lunge that drags whoever it catches; Hold Deflect). P5HorrifyingGround (10 warning circles in a ring around the target, then every circle erupts in its own GroundShatter Style with a shockwave as they rise: jump). P5NightTearer(Ultimate) (a 3s charge, a 52-stud beam that takes 777 lives, and a shockwave at the release).
CHANGES: Assassination makes 0-2 feints, violet for a feint and red for the real cut. Upper Cut and Assassination have shorter windups. Counter is a 4.5s background stance. Golden Pierce fires several lasers from small circles, then a wide one. Butterfly's leftovers clear within a second. Wild Hunt is heavier, and its Death Scythe uses the scythe's Quick mode (no forming, straight to GOODBYE).
DEFLECT: Tap on Upper Cut, Butterfly's thrust, Claw Forward, Wild Hunt's lunges and slices, and Overclock's shots. Hold on Viper's grab, Wild Hunt's bite, pierce and burst, and Golden Eternity's blades.
WARNINGS: the yellow ! over his head (Presentation/BossAttackIndicator) turns red while a skill in EncounterConfig.LethalSkills runs (one that takes lives), on every difficulty.
DIFFICULTY: P5StrikeCore.Tell scales windups by the profile's Telegraph and Count scales counts by its Density. Phase 5 attack gaps scale with its Recovery.
ENRAGED: Encounter/EnragedGate builds the Gate of Wrath behind the lobby statues. Holding E sets workspace EncounterEnraged and starts the battle (ArenaController.Activate) straight in Phase 5 (InstantPhaseOverride.Selected) with the boss marked Enraged. DifficultyConfig.Get then reads the picked profile through an enraged copy: damage 1.3, cooldown 0.75, recovery 0.8, telegraph 0.8, density 1.25, boss health 1.25, final phase 5. Phase 5 skills are also allowed on Easy. The flag clears when the encounter ends.
LIVES: leaderstats "Lives" shows a heart per life (Combat/DamageTracker).
]====]
