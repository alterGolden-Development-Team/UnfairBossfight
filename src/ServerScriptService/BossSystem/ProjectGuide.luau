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
ROUND K (2026-11-01, not play-tested or exported yet):
DEFLECT: the cue is a white shield with E on the player's chest (DeflectClient); HOLD shows under it and the shield fills while E is down. DeflectHoldTime is 0.2s.
NIGHT TEARER: no lane warning; the beam is 154 studs wide (BeamRadius 77), charged for 3s. The client caps its sphere and flares (V) so only the beam's own layers grow that wide.
HORRIFYING GROUND: 10 big circles (10-13 studs) ringing the target 40 studs out, marked like the Flower Field (gold field, crimson ring closing in, P5Strikes.BigWarn).
ASSASSINATION: the red (real) draw is never shorter than 0.5s on any difficulty.
NEW NORMAL ATTACKS: P5SilentCut(Ultimate) (the victims' screens turn gold and drained with black bars and a thin line, then HOLD E; a hit halves health, which seeps back over 10s; then 3 quick TAP E cuts for 35 each). P5ScarletRiver (charged arm, screeching lunge that drags, then a 120 pierce). P5FireRing (wound-up full-circle cut, then a ring of golden fire for 6s). P5ShotgunBlast (a line, a white star in his eye, a 15-stud cone; closer hurts more). P5PerfectVerticalSlash (a still stance, then a 150 vertical slash wave down the ground, Hold Deflect, leaving golden flames along its path for 6s). Fire uses P5Strikes' goldFire (the ruined arena's flame recipe).
ROUND K FIXES (2026-11-01, play-tested, not exported):
DEFLECT (Combat/DeflectService) was rewritten:
- Tap = a press within DeflectTapWindow (0.45s) of the hit. A re-press within DeflectTapCooldown opens no new window.
- Hold = E held DeflectHoldTime (0.2s); it counts while still down, or within DeflectReleaseGrace (0.25s) after a full hold.
- A hold only counts if it began within DeflectHoldWindow (1.6s) of the hit. Before this, holding E all fight deflected everything.
- A successful deflect keeps that kind open for DeflectChain (0.35s), so flurries can be chained.
OTHER FIXES:
- goldFire used E outside its scope, so Fire Ring's and Vertical Slash's flames never drew.
- Silent Cut's flash had an invalid rotation range.
- StatusEffectService.ClearGoldenBurnFor indexed records with no P3 effects; it crashed passive cleanup on phase changes.
CHANGES:
- Fire Ring: radius 56, no floor circles, taller flames.
- Scarlet River: 120 studs; the burning arm turns to light; a crimson screech and a red river on the floor; thorns bind whoever is caught; a spear pierce.
- Night Tearer beam layers recoloured to gold.
Studio's screen_capture doesn't draw 3D BillboardGuis, so the deflect shield can't be checked by screenshot.

ROUND M (2026-11-01): deflect, attack fixes, the Phase 5 finale
DEFLECT (Combat/DeflectService + BossClient.Presentation.DeflectClient):
- Tap: any press while the shield is up counts (DeflectEarlyGrace before it appears to DeflectLateGrace after it should
  have landed). The old 0.45s-before-impact window only remains for hits with no shield.
- Hold: a hold has to begin with the shield (or 0.3s before it); holding E from earlier does nothing.
- Mash: DeflectMashPresses presses with no shield up within 1s lock deflect for DeflectMashLock (grey LOCKED / TOO EARLY).
- Reward: deflects do not add TP; DeflectCounterDamage damages the boss after godmode is stripped. The server emits the
  ParryContact cue.
- Client: the shield reads DEFLECT, with TAP E / HOLD E under it, and a ring closes on it as the hit comes. Every E press
  flicks the shield faintly. A deflect gives a gold shield (DEFLECTED!), a ring, sparks, a screen flash and an FOV kick.
- Verified in play with scripted presses: tap during (pass), tap 0.6s early (blocked), hold during (pass), hold begun
  before the shield (blocked), press while mash-locked (blocked).
ATTACKS:
- Perfect Vertical Slash: Height 110, HalfWidth 10, Speed 600, Range 220; the crescent uses 32 segments.
  - A Hold deflect throws the player sideways at DeflectPush 75 with AllowPlayerControl=false. With player control the
    client keeps ownership and the throw moved 0 studs in testing.
  - The columns are gone. P5Strikes.VerticalBurst draws a burst instead: a dome, a floor pulse, upward plus six
    outward fireBlasts, and a burning circle (BurstRadius 11, every BurstGap 20 at BurstSpeed 150).
- Fire Ring: CanUse needs the target within UseRange 32.
  - P5Strikes.FireRingCut was rebuilt as a spin slash around him plus a flat beam blade that races out to the ring
    radius. Beam width lies along each attachment's Y, which here is radial.
- Shotgun Blast: CanUse needs the target within UseRange 34. Range 24, HalfAngle 42.
- Horrifying Ground: 12 inner circles with 10-15 spikes each, plus an outer ring of 8 at radius 64 with 8-12 spikes.
- AttackSelector: during the final minute, Combo picks may be ultimates.
LIVES: leaderstats.Lives is an IntValue with the number of lives; the hearts StringValue is replaced on Register.
PHASE 5 FINALE (Combat/P5Finale server, VFXEngine.Effects.P5Finale client; boss attribute P5Stage):
- Frenzy: starts when GodStripped is set. Attack gaps x FinaleFrenzyGapScale (0.45). Crimson outline and body flames.
  The P5 shield (2500) still has to go before his HP.
- Final: BossDamageService holds HP at 1 through HoldHealth; reaching 1 runs BeginFinal.
  - He is then untouchable for FinaleSurviveTime (60s). P5ModeService.Allows lets every group but Weapon through.
  - Cooldowns, NextUltimateAt and Phase4ComboReadyAt are cleared every 0.1s; gaps x FinaleFinalGapScale (0.08).
  - The SURVIVE m:ss timer reads workspace P5FinaleUntil.
- Ending: the module runs on its own 0.1s Heartbeat clock, because a final-minute combo can run 30s and the attack
  loop only calls Update between combos.
  - It bumps PhaseGeneration to drop the combo and sets workspace P5FinaleSafe (PlayerEncounter.CanReceiveHit refuses
    all damage).
  - He blinks to the arena centre and says one line per mode (Time, Natural, Space), with P5Mode set so his mode aura
    shows, then a farewell. All lines are in EncounterConfig.FinaleLines.
  - A portal opens 18 studs behind him and he walks into it (anchored root and stride poses). He is parked at y-220.
  - His Basic Sword, scaled x5, falls from the sky and plants point-down at the centre (workspace P5FinaleSword) with
    a beacon.
- Cinematic (client): letterbox bars, a scripted camera ("P5FinaleCam") and cue order Begin/Line/Portal/Enter/
  PortalClose/Sword/End. It releases on End, on Claim or when EncounterStarted turns false.
- Claim: hold E (DeflectInput Down/Up, which DeflectClient keeps bound) within FinaleClaimRange 14 of the sword for
  FinaleClaimHold 1.5s.
  - workspace P5FinaleClaimBy/ClaimAt fill the HOLD E billboard.
  - PhaseController.Defeat(actor, true) skips the death scene; VictoryRewards.AwardEncounter(actor, claimed) awards
    the difficulty's badge, then the usual victory screen.
  - No ProximityPrompt: prompts never showed in the MCP play session, even the lobby ones.
- PhaseController.Defeat(actor, skipDeath) now holds the old inline defeat code; healthChanged calls it.
- Verified in play: frenzy, the 1 HP hold, final-minute attacks from all three modes plus an ultimate, the ending
  firing 0.6s after the timer, the portal and sword shots, and a claim giving BossEncounterWon and the TrueHardcore
  victory title.
Backups: ServerStorage.VFXBackups *_preRoundM.

ROUND N (2026-11-01): Time and Natural mode skills re-drawn (VFXEngine.Effects.P5Strikes; backup P5Strikes_preRoundN)
- Time Bomb: over each victim, a gold core in a ForceField shell with two beam-drawn clock rings turning round it like a
  gyroscope, the old ticking hand and a countdown number (BillboardGui). No ground disc any more: every tick sends a pulse
  ring across the floor out to the blast radius. The blast: domes, gear wheels and hands flung out, shards, smoke and a
  desaturating flash.
- Chronobreak: the afterimage is a ForceField copy of him with a flickering bright copy inside and a frozen clock face
  behind it. The rewind drains the screen to grey and trails up to 2 afterimages (each is ~135 parts). The burst is
  domes, an upright clock face blowing apart and shards.
- New helpers bramble/poseBramble (after placeThorn) and colour VINE_DARK: six curling cylinder segments, wedge thorns
  and an aurora bud, grown segment by segment.
- Stranglethorns: the root line raises brambles every 4.5 studs. The thicket is 18 tall edge brambles arching in over
  the middle plus 9 inside, on a soft glow only (no crisp ring). On the snap they whip up to 2.3x their height and pull
  back down, with a mint dome and shards.
- Aurora Curtain: drawn 1.5x as tall as it hits, with rippling folds (CurveSize), flickering rays every 14 studs, a soft
  floor band and a faint mint grade. The warning line has motes rising off it.
- Verified in play by run results and part counts only (no script errors). Studio was in the background, so captures
  came out black.
- Captured after (Studio brought to the front). Fixes from the captures:
  - the bomb is bigger and gold;
  - its radius ring and tick pulses are dark red-orange and unlit, because glowing ones vanish on the gold floor;
  - the blast gets an upright clock face;
  - Chronobreak's afterimage is moved back to d.Frame, because the server blinks him in the same frame as the cue;
  - brambles are thicker, teal at the tips, with pale-gold spike thorns;
  - ThicketSnap snaps the nearest live thicket; a cut-short one used to sit first in line and swallow the next snap;
  - the curtain has stronger aurora colour and a slight darkening grade.
ROUND O (2026-11-01): five new Phase 5 normal attacks, golden recolours, Aurora Curtain as a wall
Research applied (League of Legends VFX style guide via VFX Apprentice; Roblox Creator Hub VFX curriculum):
- one hue (gold) leads and other colours stay accents; the brightest white only at the hit and the leading edge;
- a short wind-up, the peak in the first quarter, a quick fade;
- ground telegraphs dark and unlit, so they read on the gold floor.
NEW ATTACKS (Attacks/P5/NormalAttack, registered in AbilityMetadata; client VFXEngine.Effects.P5Arsenal):
- P5Golden-matterBeam / P5DoubleGolden-matterBeam (shared Attacks/Shared/P5MatterBeam):
  - Charge 1.6s pulls everyone in PullRange toward him (a LinearVelocity in the ground plane with a capped force).
  - A gold circle on the floor shows the beam's reach.
  - Each pass is a full circle (Sweep 360): clockwise, Pause, then back. A TAP cue goes up just before the beam
    passes over someone (angle prediction); damage is once per pass.
  - The double fires two opposite beams (Spread 180), thinner, shorter, slower.
- P5JudgementZone: a zone under every player. It is a replicated marker part (VFX=P5Arsenal, Kind=Judgement,
  tagged VFXDecorate, attributes Radius/EndsAt/State) that hunts its player at Speed 12 for Timer 5, then goes
  red for Flash 0.6 and explodes (JudgementBoom, Damage 95). It runs as a background cast.
- P5NullifiedZone: a barrier ring (Radius 26) round the target for 15s.
  - The server clamps root CFrames: whoever is inside stays inside, whoever is outside stays out.
  - Marker Kind=Nullified. It runs as a background cast.
- P5HellavanRampage:
  - roar (RoarPush), then a 2.2s sprint toward the target with a slash every 0.22s (TAP);
  - a locked path (Lock 0.8), then the cut down it (HOLD);
  - a fuse, the blast (BlastRadius 22), a tall wall of force (HOLD, can't be jumped), then 3 ordinary
    shockwaves (c.Shockwave).
CHANGES:
- Aurora Curtain: no gap. It runs as a background cast (the boss keeps attacking); HOLD cue as the wall reaches
  someone; golden colours.
- Slam: UseRange 36 (melee only).
- Time Bomb: no countdown number.
- Horrifying Ground: 10 circles of 18-26 spikes; SpikeScale 1.5 (new GroundShatter d.Scale); Tall 2-3.2.
- Stranglethorns: golden roots.
  - Bramble shades run bronze to gold, with neon thorns and buds.
  - Roots are 2 brambles every 5 studs, with a hot spark riding the front, dust, sparks and cracks.
  - The snap has a light pillar, domes, shards, debris and cracks.
  - The snap knock now uses AllowPlayerControl=false; with true it moved players 0 studs in testing.
- Gold recolours: StarFall, StarImpact, GravityWell and GravitySlam (VIOLET->AMBER, PINK->BUTTERFLY_GOLD,
  BLUE->SHINE).
KNOWN: many older P5 knockbacks still use AllowPlayerControl=true and barely move players.
Backups: ServerStorage.VFXBackups *_preRoundO.

ROUND P (2026-11-02) - Phase 5 modes reworked, 27 new or enhanced skills
MODES (Combat/P5ModeService):
- No random modes and no per-mode cooldowns: one attack every Phase5AttackGap (0.15s) everywhere.
- Phase 5 opens in normal mode (the Normal Attack folder only) for Phase5NormalSpan (30s), then takes one of the
  modes it still has. Entering a mode swaps his shield for Phase5ModeShield (2000); no TP orbs while it is up.
- Breaking that shield ends the mode for good (P5ModesDone), says its Phase5ModeBreakLines line and owes its
  last stand (P5LastStand): Space -> P5BlastBreath(Ultimate), Natural -> P5TheGreatStorm(Ultimate); Time has none.
  AttackController casts the owed stand before anything else. P5ModeService.LastStand leaves it owed; the stand
  clears P5LastStand itself once its cast really starts (a cast refused while the target respawns stays owed).
- With all three broken he says Phase5AllModesLine and stays in normal mode.
NEW SKILLS (all on P5StrikeCore; visuals in VFXEngine.Effects.P5Ascend unless noted):
- Normal: P5Fang-Dive, P5Fang-Cross, P5Fang-Pierce (close only), P5IntrusiveLunge, P5SwordDancer.
- Space: P5LightJab, P5Disgeneration, P5PlasmaBall (balls are a background cast), P5JumpKick, P5EnragedShockwave,
  P5UltraRed (tiles turn on the server clock: client and server agree via d.At), P5UltraBlue, P5BlastBreath(Ultimate).
- Natural: P5LightningDash (beaten by MASHING E - DeflectService.LastTap; one shield for the whole flurry so the
  mash lock never trips), P5TheWind, P5GreatWind, P5EnhancedGildedCataclysm, P5TheGreatStorm(Ultimate) (the
  star's wall is lethal: WallWave Lethal=1).
CLONES (enhanced copies with their own Style): P5EnhancedStarSlash (Space), P5EnhancedFlowerField (Natural, ten
  overlapping fields - no corridor), P5EnhancedTimeBullets and P5EnhancedDirectShot (Time, double volley),
  P5EnhancedRipAndTear (close only), P5EnhancedBurst, P5GoldenBullets, P5NoonTearer (Night Tearer without the
  ultimate gate: 2 lives, beam radius 51). The DOUBLE wrapper at the end of a Behavior runs Combo twice.
P5StrikeCore kit: ctx.Center, ctx.Fx(effect, stage, data), ctx.WallWave (HOLD cue, can be Lethal),
  ctx.Explode (Look Red = JudgementBoom), ctx.PullField (LinearVelocity, no class can out-run it).
TWEAKS: Golden-matter Beam and Double are close range with a strong pull; Judgement Zone hunts with Lead/Orbit;
  Nullified Zone is a real wall (Workspace.P5NullifiedWall, 64 CanCollide panels, radius 40); Hellavan Rampage
  wall and waves are map-wide; Perfect Vertical Slash runs Range 720; Finality's pull is stronger; Silent Cut
  has its line; BlackHole -> DyingStar combo removed.
VERIFIED IN PLAY (2026-11-02, TrueHardcore): every new and cloned skill ran and hit; Lightning Dash took 0 damage
  while E was mashed (18 clangs); the Nullified wall stopped a walking player at 38.5 of 40; Natural, Space and
  Time breaks gave the right lines, stands and the all-modes line; Horrifying Ground and other spike attacks made
  no collidable part on server or client (only the Nullified wall panels collide, on purpose).
FIXED THIS ROUND: the Golden-matter Beam Styles had '-- close range' mid-line, commenting out Width/Sweep/
  SweepTime/Pause/Damage (math.rad(nil) crash).
TEST NOTE: hold the AI (NextAttackAt kept in the future every Heartbeat) BEFORE InstantPhaseOverride.Apply(boss, 5),
  or he opens Phase 5 with Night Tearer and the execution can end the encounter.

ROUND R (2026-11-07) - Phase 5 balance and fixes
- Light Jab: every stab draws Style.Rapiers (3; FinalRapiers 5) needles fanned across the hit lane (P5Ascend.Jab Rapiers/Width) and each hangs ~0.25s, so several are on screen together. Count scales with Density.
- Ultra Blue: the star hangs fixed over the middle of the map at Style.SkyHeight (130) and no longer follows him; beams have no range limit (BeamRange 2000 is just the longest drawable part); the throw's blast is a true sphere/circle (no pillar, no cylinder wall) and its edge grows across the whole map (ShellRange 450, ShellSpeed 85).
- Ultra Red: the centre blasts are drawn as half circles (domes) exactly as wide as the blast that hurts; each line is one unbroken strip instead of a pile of tiles.
- Polaris: he blinks to the centre of the map before the cast (Behavior); the north star's final explosion is FinalRadius 400 (whole map) and the client draws a ring racing to the corners.
- Time bullets (P2 and P5) are yellow: ProjectileService TIME/CORE/DEEP/FROZEN, TimeBulletClient, both TimeBullets Styles.
- Golden Eternity: the Cage (ring of knives round a player) is gone. The map ring's knives now leave ONE BY ONE in a shuffled order (Style.KnifeGap), each with its own flight time (FastChance of them FlightFast..FlightMid, the rest FlightMid..FlightSlow); client P5Strikes.KnifeThrow. Density scales how many, ProjectileSpeed the flight time, Recovery the spacing.
- Overclock: ShotRange 140 -> 700, ShotSpeed x the difficulty's ProjectileSpeed.
- Sword Dancer and Falling Star root him (P5StrikeCore ctx.Plant / ctx.Unplant) for the whole cast: no walking or sliding.
- Close range: AttackSelector weights EncounterConfig.Phase5CloseAttacks x Phase5CloseWeight when they can run, and Combat/P5CloseIn (called by AttackController before each pick) blinks him next to a target farther than Phase5CloseInRange so those skills are actually usable.
- NEW P5EnhancedGlidedThread (Attacks/P5/NormalAttack, registered in AbilityMetadata): Style.Threads (7) Gilded Threads are summoned in a ring round him (P5Ascend.ThreadRing) and shoot one after another at the players. It reuses P1.5GildedThread's Release(direction, {Origin, Damage}); lifetimes and speed are set per cast through the GildedThreadSpeed/Lifetime/SegmentLifetime actor attributes. Threads x Density, Tell x Telegraph, Stagger x Recovery, damage x DamageScale on top of the difficulty's Damage (the Enraged Gate included).

ROUND S (2026-11-07) - Phase 5 shields, passives, new skills and fixes
- ROOT CAUSE of "The Great Storm never activates": its Style had a `--` comment in the middle of a line that swallowed Bolts/Tell/Radius/Damage/Near/Predict/Spread, so the cast errored on nil. Keep comments on their own line in Style tables. (A scan of every P5 Behavior's S.<key> against its Style is a cheap check.)
- SHIELDS (Combat/P5ModeService): Phase 5 opens with Config.Phase5BaseShield (5000) + godmode. A mode swaps it for Config.Phase5ModeShields (Space 3500, Natural 2000, Time 5000). BossDamageService holds a mode's shield at Phase5ShieldHold (1): the moment it is down (boss attr P5ShieldDown) the mode's break line plays, the mode's last stand is owed (P5LastStand: Space - Blast Breath, Natural - The Great Storm, Time - Finality) and AttackController casts it first; the mode ends after that cast (or Phase5LastStandWait = 25s), the base shield comes back. TPService gives him Phase5BaseShield again when his godmode is stripped.
- FINAL MINUTE REMOVED: Combat/P5Finale no longer has the 60s "uses everything / portal / sword" ending. Stages are nil, Frenzy, Claim. Reaching 1 health calls P5Finale.BeginFinal - THE HOOK for the new ending. Placeholder: after 1.5s it ends the fight with PhaseController.Defeat(actor, true). VFXEngine.Effects.P5Finale (the cinematic) is unused.
- ENRAGED: godmode stripped -> P5Stage "Frenzy": gaps x FinaleFrenzyGapScale (0.45) = passive P5Enraged; on the Enraged Gate (DifficultyConfig.Enraged()) gaps x FinaleSuperFrenzyGapScale (0.3) = passive P5SuperEnraged (HUD icons).
- PASSIVES (BossSystem.Passives, run by Combat/PassiveController, HUD ids in UpdateBossHUD / EffectDescriptions / StatusIcons): P5Spacetrum (Space: every Space attack drops a P5FallingStar via Summon, P5SpacetrumCooldown = 2s x the difficulty's Cooldown), P5Verdant (Natural: shield +P5VerdantRegen/s, every Natural attack hit poisons - StatusEffectService.ApplyPoison from PassiveController.OnDamageDealt), P5Pastborn (Time: a CloneController "Past" clone, below), P5Enraged, P5SuperEnraged.
- "PAST" CLONE (Mechanics/Clones/CloneController, mode "Past"): casts any attack from P1 to P4.5, ultimates included, as the era it comes from (the clone's Phase attribute is set to the attack's NativePhase while it casts). CloneController.PastPool builds the list; PAST_BANNED lists what is left out (time stops, saves, illusions, the Phase 2.5 and 3.5 set pieces, Golden Parry, Block Grab). It lives while Time mode lasts, one at a time, P5PastInterval between attacks, P5PastRespawn before the next.
- P5FallingStar moved to Attacks/P5/Summoned (P5Mode "Summoned": never picked). NEW Space skills: P5StarShooter (4 five-pointed stars circle him and turn; every 2s each shoots a small star out of each point; after 9 volleys the 10th is a spam of volleys; background cast, client P5Ascend.StarRing / StarShots) and P5EnhancedJumpKick (Jump Kick with a red mark, an 8-stud blast instead of 16, and a kick that ignores dash i-frames and defense: P5StrikeCore ctx.PierceHit, PlayerEncounter.Damage knows the skill name).
- WIND: P5StrikeCore ctx.Pull places every player PullDistance from him within PullTime (The Wind 9 / 0.2s before the cut; Great Wind 13 / 0.25s, held there for the whole charge).
- DEFLECT: EncounterConfig.P5NoDeflect lists attacks with no deflect (P5StrikeCore ctx.Warn / ctx.Deflected obey it): LightningDash, SwordDancer, UltraBlue, UltraRed, GoldenEternity, Overclock, ClawForward, Butterfly.
- LightJab is a spray of rapier dashes (lanes x gaps), UltraRed's orb is a half sphere on the floor and its explosions give no warning, UltraBlue's star is bigger and its throw is one explosion, the Glided Thread orbs appear as a ring round him, Lightning Dash reaches 30 studs, the Golden-matter beams only run within P5BeamUseRange (38).
- SWORD DANCER is exclusive: CanUse needs no background cast (attrs P5BG_<attack>, set by UltraRed / UltraBlue / StarShooter) and no lingering heavy (AttackSelector.HeavyActive).
- Studio quirk met while testing: one ModuleScript (P5GreatWind.Style) kept an old Source in Play mode until it was destroyed and recreated.


--[[ ROUND T (2026-11-07)
- P5LightningDash: deflect is back (removed from EncounterConfig.P5NoDeflect); the TAP window is checked at the moment each
  dash reaches you (it used the dash's start time).
- P5SwordDancer: a BACKGROUND cast like Aurora Curtain - he calls the first ring (0.35s) and is free to walk and start other
  attacks while the rings form and cut (flag P5BG_P5SwordDancer). The Round S "clear stage only" rule is gone.
  Backup: VFXBackups.P5SwordDancer_Behavior_preRoundT.
- P5EnhancedGlidedThread: the threads no longer aim at players: the ring of seven blooms outward, every thread leaving straight
  away from him through its own point, all at once (they bounce off the walls).
- P5UltraRed: the orb is big from the start (Style OrbSize 34) and never swells; first blast 0.3s after the cast (Tell), the
  second 0.4s after the tiles stop (StopTell).
- P5FallingStar.Summon (the Space passive P5Spacetrum): 3-5 stars (SummonMin/Max) on random spots within SummonSpread of the
  player, SummonGap apart.
- P5PlasmaBall: tick damage (TickDamage 8 every Tick 0.15s while inside a ball, no knockback) and much faster throws
  (Balls 8, Tell 0.12, Every 0.08, Speed 95). Backup: VFXBackups.P5PlasmaBall_Behavior_preRoundT.
- FINAL ATTACK "Sonic Blaster" (replaces the Round S placeholder victory): P5Finale.BeginFinal -> Combat/P5SonicBlaster.Run.
  * Shared: ReplicatedStorage.BossShared.SonicBlaster - the song (asset 108440513814741, 182.09s file, music to 175.5s),
    its beat grid measured offline (librosa: 415 beats ~143.5 BPM, Kick/Hat strength 0-9 per beat), the nine sections,
    bullet kinds/colours and the deterministic bullet maths (Expand/Advance/Where/Gone, fixed 1/60 step). Offset shifts the grid.
  * Server: cancels clones/casts/attacks/passives, he floats to the arena middle, players are pulled onto the stage
    (radius 74, core 9 round him), 7 lines (DialogueScripts SB1-SB7; Easy/Hellaven variants), the declaration, then the
    music starts (boss SonicBlasterMusicStartedAt = now + 0.9) and a schedule fires every pattern on its beat. Hits: the
    client reports (RemoteEvent BossShared.SonicBlasterHit) and the server validates against its own bullet copy; the
    server also checks with a tighter radius. Damage = 8.5% of max health per bullet (x kind Damage), lasers 17%, 0.5s
    between hits; scaled by Difficulty Density/ProjectileSpeed/Telegraph/Damage, +15% bullets on the Enraged Gate.
    At song time 174.35 every bullet is cancelled; at 175.5 it ends, he says SB8/SB9 and PhaseController.Defeat wins it.
  * Sections: Overture (rings) / Sound Barrier (double spirals + aimed fans) / Crossfade Prism (3 then 4 rotating lasers,
    accelerating orb rings) / Crescendo Standstill (golden-angle spiral that speeds up, every bullet FREEZES on beat 79.48
    and scatters at the drop 79.90) / Sonic Blaster (dense alternating rings, big orbs on kicks, curving flower rings) /
    Oscilloscope Wall (sine-shaped walls of notes with one gap, crossing the stage) / Symphony of the Nothing (2 lasers,
    curving rice lattice, layered booms) / Galaxy in a Breath (slow spirals) / Imaginary Encore (aimed 7-way fans, spirals,
    rings, everything on the last note).
  * Client: VFXEngine.Effects.P5SonicBlaster - letterbox bars, cinematic shots per line, the spell card banners, then a
    top-down shmup camera (mouse wheel zooms), stage rings, a sound wave on every beat, the player's hit dot, graze counter,
    time left and song progress in the top bar, a live sound wave (music PlaybackLoudness) in the bottom bar.
  * Music: BossAudioClient key "SonicBlaster" (silence while boss SonicBlasterHush, then the song once, kept within 0.3s of
    the server clock); CombatAudioConfig.MusicAsset/MusicNames. Backups: VFXBackups.*_preRoundT.
  * Verified in Play: whole song end to end, music in sync (0.06s), no script errors, victory after the song, client cleanup.
]]
ROUND U (2026-11-07)
- UPDATE 2026-11-08: Hellaven Phase 4 music swapped to rbxassetid://132058286351091 (BATTLE AGAINST THE WORLD, owned by the place owner) because the Warak track below is refused for this experience.
- Music: Hellaven Phase 4 (was rbxassetid://115642344211448) is refused by Roblox ("Asset is not approved for the requester":
  the audio's permissions do not include this experience). BossAudioClient now marks any soundtrack that has not loaded
  after 6s as failed and plays the normal-mode track for that phase instead. CombatAudioConfig.TrackNames overrides HUD names
  for uploads whose title Roblox hides as ####: 70762771235020 (Hellaven P1.5 / shield break) = "Illusionary's Perfect
  Puppet", 108440513814741 = "Sonic Blaster". A #### title from MarketplaceService is never shown.
- UltraBlue: no debris, cracks or scorch on the floor. UltraRed: BlastRadius 58, FinalRadius 72, OrbSize 44.
  DeflectClient: no closing timing ring; with two deflects overlapping the shield shows the one that lands first.
  DeflectService: a hold counts from the EARLIEST hold shield up; E held for an up HOLD also turns a TAP hit inside it.
- Great Wind / The Wind: ctx.Pull(..., {Once = true}) snaps everyone in once and lets go (no dragging onto him).
  The Wind: Pull 0.25s, then a fixed 0.5s charge (Tell) before the cut.
- Time-mode clone (CloneController "Past"): after Combo returns it waits for every cast that move started
  (EffectService.CastsOf, max 15s) - the next move (AttackInterval 4.5s) used to start on top of a running charge.
- Golden Eternity: thrown knives fly on past their mark until a raycast meets something solid (server: knifeAt mirrors the
  client's KnifeField layout from the seed and keeps hurting along the line; client P5Strikes KnifeThrow continues).
- Silent Cut: no slash lines (world or screen). Night Tearer: Charge 5s (not scaled by difficulty).
- Star Shooter: Radius 28, Reach 6.5 (everything drawn scales), Orbit 1.9, Spin -3.4; each shot flies until it hits a wall.
- P5ModeService.Borrowed: Enraged (2) / Super Enraged (3) random non-ultimate moves from EACH defeated mode are allowed in
  normal mode (boss attributes P5Borrowed, P5BorrowedKey). EffectDescriptions: P5 passive texts rewritten.
- Final attack rebuilt as "Last Imagination 「Universe of the Nothing」" (Combat/P5SonicBlaster, Effects/P5SonicBlaster,
  BossShared.SonicBlaster): lore lines FA1-FA9 / FB1-FB6 (DialogueScripts; the old SB1-SB9 keys clashed with the shield
  break's SB1/SB2 and are gone), warp portal, outer space stage at SB.Space (workspace.NothingDimension), 7 spell cards from
  his eras, black hole at SB.End 147.888, flight at SB.FlyAt 171.4, gone at SB.GoneAt 174.0 -> Defeat; ReturnHome 3.5s
  later. Character attribute FinalAttackLocked blocks dash and skills. HUD: HP bar in the top letterbox, black equalizer
  bars standing on the bottom bar; graze and timer removed; the usual fight HUD is hidden until the win screen.
- Performance: Phase5Transition form animator 20 Hz; BossLocomotion skips unchanged joint writes; VisualQuality Auto drops
  a tier below ~40 fps; TimeBulletClient <=30 Hz and skips far clocks; new BossClient.Presentation.EffectLoadClient
  (no shadows from effect parts, effect lights off on Low/Medium).
- Backups: ServerStorage.VFXBackups.*_preRoundU.


ROUND V (2026-11-07) - final attack HUD, survival, look; UltraBlue deflect
- HUD (VFXEngine.Effects.P5SonicBlaster, from the user's sketch): the letterbox bars turn pale with heavy black rules
  when the song starts. Spell card = white card, thick black frame, under the top bar on the left (setSpell; it flashes
  on every new card). Over the bottom bar: the song's name on a black plate, health as a long green bar, lives as
  yellow star.anime stars over it (10 drawn, "x N" past that; a lost life breaks a star off the row). In the bottom bar:
  40 black music bars; the green bar on the far right fills as the song goes (song time / SB.End).
- Stage: SB.Radius 175 (was 120). Patterns that used fixed distances now scale with R. Black hole moved to
  (0, +120, -330) and drawn bigger.
- Survival: bullets 18% fewer (DENS x0.82), each bullet 7% max health (was 8.5%), 1s grace after a hit (SB.HitGrace,
  the character flickers). A hit that would kill is a MISS (server miss()): one life goes - never the last one - health
  is refilled, bullets within SB.MissClear (34) are wiped on server and clients, 3s grace (SB.MissGrace,
  RespawnInvulnerableUntil). Losing the last star now defeats the player. Cue "Miss".
- Look: every bullet has a white core; each spell card has its own colours (PALETTE) for the stage rings, sigils,
  crystals and his circles; a spell circle turns under him and one stands behind him; a ring rolls over the stage on a
  new card; lasers have a source orb; columns drop a golden blade / a star before they strike; shooting stars; floor
  art kept faint so it is never mistaken for bullets; camera keeps the player near the middle, zoomed out a bit (1.18).
- DEFLECT: UltraBlue removed from EncounterConfig.P5NoDeflect (its beams are Tap-deflectable again). Still on the list
  from Round S ("remove deflect on some attacks"): SwordDancer, UltraRed, GoldenEternity, Overclock, ClawForward,
  Butterfly - those show no shield on purpose.
- Backups: ServerStorage.VFXBackups *_preRoundV.

ROUND W (2026-11-07): final attack HUD, patterns and deflect
HUD (VFXEngine.Effects.P5SonicBlaster): the cinematic bars stay BLACK; no spell card box (the card name is only the centre banner). Health is built like the game's own Health bar (PlayerVitalsHUD: Guru font, dark track with green stroke, green gradient, yellow while untouchable), centred above the bottom bar, with the lives as yellow stars centred over it. The music's bars in the bottom bar are WHITE; the green progress bar is gone. While the HUD is up his lines (PlayerEncounterHUD.BossDialogue) are moved to the top of the screen so they never cover the stars.
FINAL ATTACK: Last Imagination is a real attack from SB.End (2:28) to SB.Last (2:50): the black hole opens low behind the far edge (server bh), the camera tilts up to it (S.tilt in topDown), four movements on the beat; at SB.Last the bullets are drawn into the hole; he flies in at SB.FlyAt. New bullet fields (BossShared.SonicBlaster): Bn (bounces off the rim), Sa/Sf/Sp (snaking), Gm 5 (quarter turn) and 6 (turn back). New cue: Tick (the clock's minute hand). Cards: Gilded crescents, Clock ticking hand, World knives, Illusion bouncing cards, Thread weave + snakes, Cosmos galaxy/shells/constellations/lattice, Breath inhale/exhale. New models: mirrors (gilded frame, pane, sigil), clock hub and numerals, landing rings for columns, halos on Orb/Big bullets; beat rings are thin.
DEFLECT: after godmode is stripped, deflects damage the boss through BossDamageService.ApplyDamage (DeflectCounterDamage 150); deflects no longer add TP.
SPEED: EncounterConfig.Phase5NormalCombo is 6-8 moves with a 1.2s pause (was 5-6, 4s); Phase5ModeCombo pause 2s; P5NormalTellScale 0.6 (P5StrikeCore ctx.Tell) and Phase5TellScale 0.5 (AttackController) shorten every windup.
Backups: ServerStorage.VFXBackups.*_preRoundW.

ROUND X (2026-11-07): small changes
DEFLECT: E does nothing by itself. DeflectService.Active returns false unless a shield for that kind is up (Warn) or a chain is open; the "recent tap" fallback and the mash lock are gone, and DeflectClient no longer flicks a shield on an idle press (the press is still sent, so P5LightningDash's LastTap works).
FINAL ATTACK: at SB.Last every bullet is removed at once (client P.Cancel: a few sparks, no flight into the hole). Lasers added on every card (server beam(): fires exactly on a beat, Exact=true skips the Telegraph scale): Gilded lance fans, Illusion crossfire from the mirrors, Thread loom (warp then weft), Cosmos pentagram, Last Imagination spokes / four jets / alternating spokes / a 12-spoke starburst. Every laser now has a soft glow sheath (l.Glow). The lead-in is about 20s instead of ~35-45s: his lines type at half the interval (LyricSoundtrack option), the portal opens in 1.2s and sucks in 2.4s, and the waits after it are shorter. Halos are only on Big bullets.
Backups: *_preRoundX.

ROUND Y (2026-11-08): defeat cutscene, transitions, UI, Phase 5 debuffs and Hellaven extras
- FINAL-ATTACK DEFEAT: losing the LAST star in Last Imagination plays a cutscene (VFXEngine.Effects.P5SonicBlaster: finalDefeat / endFinalDefeat) instead of the toast and the DEFEATED panel. Its ScreenGui sits at DisplayOrder 88, UNDER the win screen (PlayerEncounterClient, 90), and it fades out the moment BossEncounterWon turns true, so a dead player sees the victory screen alone. EncounterRetryClient hides its panel while the local player attribute FinalDefeatShow is set, and afterwards unless the whole group is down (EncounterRetryAvailable). The text "Your last star is gone. You have been defeated." is gone.
- PHASE 2 -> 3 (Phase3Intro.gravityField): the whole wave barrage goes OUT first and the waves wait at the arena edge (wave.Mode "Hold", harmless); when the last one is out (RECALL_LEAD 0.5s) the pull-back starts and the waves come back one after another at the throwing spacing (RETURN_GAP), so each keeps its own safe opening. The field ends as soon as every wave is back (about 28s).
- PHASE 4 -> 4.5 (Phases/Phase45Transition): the bloom is yellow now (the constants keep their old names CRIMSON / ROSE / BLUSH / GOLD but hold yellows).
- UI: class picker has vector logos instead of letters (StatusIcons kinds LogoWarrior / LogoMage / LogoTank / LogoSupporter / LogoGambler / LogoDuelist, placed by ClassClient) and no "Q Dash with i-frames" line; trial picker has no "Read the full terms" button; difficulty id NerfedHardcore is now shown as "Normal Mode" (DifficultyConfig Name, victory subtitle, EffectDescriptions). The id stays so badges and dialogue keys still match.
- PHASE 5 DEBUFFS (Combat/P5Debuffs): a table of attack -> existing debuff (advanced list, Bleed, Fear). PlayerEncounter.Damage calls P5Debuffs.OnHit after any damaging, non-status hit whose balance.Skill is listed, while the boss is in Phase 5 (boss attribute LastP5Debuff shows the last one). 61 attacks are mapped.
- PHASE 5 HELLAVEN EXTRAS (Combat/P5Hellaven): one extra pattern per Phase 5 attack, run after the attack on Hellaven only. AttackRegistry wraps every NativePhase 5 Combo and calls P5Hellaven.After(actor, name, target). Built from P5StrikeCore's own primitives (Bolt, Shockwave, Spikes, Explode, WallWave, FireClaw). At most 2 at once, never within 1.6s of the last; clones and illusions never run them. P5Hellaven.RunWith(ctx, name, target) exists for tests with a mock context.
- THUMBNAIL SCENE: ServerStorage.ThumbnailScene (boss clone with yellow eyes, scaled sword). Not used by the game.
]====]


-- ROUND Z (2026-11-08) - class balance, HP/stamina and difficulty pass
--  ClassConfig: Warrior parry-fail lock 6s on Hellaven (ParryFailLockHellaven, Kits/Warrior). Mage HP 100->110, stamina 75->85,
--  regen 0.75%->1%, Orb Dash cooldown 17->14, Hyper-Laser charge 3.5->2.5. Tank speed 16->18, dash cost 25->20, regen 0.5%->0.75%,
--  Almighty cooldown 100->80. Supporter HP 90->100, stamina 95->100, Sonar Wave 75->90, Chain of Fate 100->80, Second Wind 300->240.
--  Gambler: a failed Jackpot in Phase 5 leaves 15% HP (not 1) and halves the Jackpot cooldown (Kits/Gambler). Duelist lifesteal
--  10%->8%, Flashstep cooldown 6->7.
--  DifficultyConfig (Hellaven): StartingLives 100000->1, Damage 1.5->1.4, Cataclysm QTE 6 keys/3s -> 5 keys/3.2s, description text fixed.
--  Difficulty ladder check (Round Z): all 83 ConfigOverrides keys run in order Easy < Normal < Hardcore < True Hardcore (base) < Hellaven;
--  none out of order. Only change: Hardcore attack pace Cooldown/Recovery 1 -> 1.1 (it was identical to True Hardcore; ladder is now
--  1.5 / 1.25 / 1.1 / 1.0 / 0.75). NOTE: Mercy HitCap and PostHitGrace are skipped for class characters (PlayerEncounter.Damage:
--  "not char:GetAttribute('ClassId')"), so the "no single hit over X% of max HP" lines in the difficulty panel do nothing for players.
--  UPDATE (Round Z): HitCap and PostHitGrace now DO apply to class characters (PlayerEncounter.Damage, the two "Round Z" lines).
--  The cap is a share of max HP applied before class defense; the earlier note above that said they were skipped is obsolete.
--  Tested in Play on a Warrior (150 HP): Easy caps a hit at 60, Normal Mode 90, Hardcore 120, True Hardcore uncapped; the hit
--  right after is ignored for 0.45 / 0.25 / 0.1 s and lands again afterwards.
--  Natural HP recovery (Round Z): ClassConfig.HealthRegen.Delay 5 -> 4. ClassService.step now heals every tick (not once a second):
--  MaxHealth x class HealthRegenFraction x dt, once 4s have passed since the last damage taken (ClassService.OnDamaged sets LastDamaged).
--  Fractions per second of MAX HP: Warrior 1%, Mage 1%, Tank 0.75%, Supporter 2%, Gambler 1.25%, Duelist none (lifesteal instead).
--  Input buffer (Round Z): in the ClassControl "Action" handler a Begin press of M1/F/C/V that lands up to 0.25s (INPUT_BUFFER)
--  before that skill's cooldown ends now waits for it instead of being dropped. Hold-type skills are excluded (Tank F, Mage C,
--  Duelist C), and one waiting press per key at a time. Tested: Warrior F pressed 0.17s early fires, 0.59s early is dropped.
--
-- ROUND AA - class rework, locked classes, new classes
--  Unlocks: ReplicatedStorage.BossShared.Classes.ClassUnlocks is the single table (Kind = Badge / GamePass, Id, Hint). A class missing
--  from it is open to everyone. The REAL gate is ClassService (S.CheckUnlock, called from the "Select" handler, 2 attempts, fail closed);
--  the picker only shows padlocks (player attributes ClassUnlocked_<id>, refreshed on join, when the armory opens and on a game pass
--  purchase). The place owner and Studio bypass the lock; set workspace attribute ForceClassLocks = true to test the real check in Studio.
--    Duelist = badge 2347131894818918 (True Hardcore) | Twinblade = badge 1170331551749924 (Hellaven)
--    Reality Disorderer ("Disorderer") = game pass, ClassUnlocks.Disorderer.Id is 0 until the pass exists: put the real id there.
--    TrueWarrior (entry only, NOT in ClassConfig.Order yet - concept) = badge 126477610981225, upgrade to Champion = badge 2914248639183662.
--  Solo badges: VictoryRewardConfig.SoloBadgeIds {TrueHardcore = 126477610981225, Hellaven = 2914248639183662} are awarded IN ADDITION to the
--  normal badge by VictoryRewards when nobody else took part (participants = players present at EncounterStarted that were not spectating
--  + anyone who joined during the fight; leaving mid-fight still counts). The solo award does not touch the VictoryBadge* attributes.
--  Warrior: Battle Hardened stays. R is "Aegis Guard" (GuardSpeed 0.75): each absorbed hit = 1 Aegis charge (max 5), a press within 0.3s
--  before the hit negates it for 2 charges, a guard-breaking hit shatters the charges (once per 8s), Offensive mode loses them after 12s.
--  Defensive C = Shield Charge (80 + 60 per charge, spends them), Defensive V = Aegis Burst (heal 3% / ally 1.5% per charge, +10% attack
--  per charge for 6s, cd 14s, no charges = no cooldown). The Parry (ParryStance / ParryLocked) is no longer used by any kit.
--  Block lease: ClassService sets st.BlockLease on R Begin and the client sends R "Hold" every 0.1s; the server ends Blocking 1.5s after
--  the last one, so a lost key release can no longer leave the block stuck (which silently ignored every other skill).
--  Mage: at OrbMax (50) a new orb overwrites the OLDEST (orb records have Born). Being hit spawns 3 orbs (Arcane Recoil, 0.4s apart).
--  Bombardment detonates up to 35 orbs nearest the boss (cap 3500), leftovers stay.
--  Tank: Defender stores 40% of absorbed damage (cap 50% max HP); releasing F (or losing the hold) blasts it in a 14-stud shockwave
--  (ClassService.StopDefender -> Kits.Tank.OnDefenderEnd). Regen = 0.75% + 1.25% x missing HP fraction per second.
--  Supporter: Healing and a 10s aura pulse each remove one debuff (StatusEffectService.RemoveOneDebuff: the advanced debuff with the
--  longest remaining time). Chain of Fate already links the ally nearest your aim within 80 studs (AimedAlly), no change needed.
--  Gambler: Loaded Luck. K.LuckyRoll: effective roll = min(19, raw + luck) (raw 1 / 20 stay), <= 10 -> luck +1 (max 5), above 10 -> luck 0.
--  Jackpot win chance 50% + 5% per Luck; win clears Luck, loss adds 1.
--  Duelist: a successful riposte heals 8% max HP.
--  Twinblade (Kits/Twinblade): Flow (0-10, 8s) from landed hits; 5-hit chain. Blade Whirl (6 ticks) really spins the swords: each sword hangs off a
--  BladeRoot R/L hub on a BladeSpin Motor6D, ClassAnimator rotates it while TwinbladeSpinEnd is live. Sky Cross runs on the client "TwinPath" event
--  (rise, chain the boss, reel, X-slash dive; Phasing throughout; damage x(1 + 0.2 x Flow), leaves a burned X). F within FinalWindow of landing Sky
--  Cross triggers the hidden Final Destination (150x150 storm drawn client-side by the TwinStorm event, hits the boss and every damageable clone, body hidden via TwinbladeVanished, Phasing). Twin Spirits (12s, Flow held at 10) bursts a
--  360 slash on cast and turns your cuts into 360 slashes for 220.
--  Reality Disorderer (Kits/Disorderer): Glitch stacks (self +4%, team +3% per stack), Static Orbs / Convergence, Misplace + hunting decoys, Diamond Protocol (Combat/DisorderWall) / thrown cube, Checkpoint / Arena Glitch, hidden Falter combo (hold C, release, F at the cube). All visuals: VFXEngine.Effects.Disorderer.
--  Redact does NOT delete projectiles: most boss attacks are computed hits, not objects, so allies inside take 60% less damage instead.
--  Weapons (ClassModels): V2.Twinblade (two blades), V2.Disorderer (no body gear; client-drawn hands); detail passes on the Duelist, Mage, Supporter, Gambler and
--  Tank weapons. New weapon parts must set the ClassWeapon attribute (helper W) or ClassModels.Build removes them (avatar clothing is used).
--  Testing note: a command-bar require() of a game module gives a SEPARATE instance from the one the game runs. To test server kits in
--  Play, create a Script instance at runtime (its require shares the game's modules) and stub S.HitBoss / S.Targets / S.Boss there.
-- ROUND AB (2026-11-08) - True Warrior / Champion rework
--  Kits/TrueWarrior (server) sends cues to VFXEngine.Effects.TrueWarrior (client): camera cutscenes, letterbox, titles and impact frames are caster-only, world VFX render on every client.
--  R is Counter: ClassService calls an optional kit.GuardAction instead of the generic Blocking guard. F = Victorious Throw. C = charged Vow Slash, or Supreme King Slash within SupremeWindow after Last Stand lands.
--  V: cutscene, 360 slash (SlashSize 75 wide); Last Stand is granted only on a hit, a miss sets the cooldown to MissCooldownFraction.
--  True Warrior hidden skills: landing Last Stand grants one HiddenReady charge. C = Supreme King Slash, F = The Truth, R = Holy Counter.
--  Diamond Protocol (Combat/DisorderWall) is full immunity and no longer deletes bullets. Boss DoTs go through ClassService.S.DotBoss.
--  Phase 5: Unlimited HP is a Phase5UnlimitedShield shield; the TP break resets it to Phase5BaseShield. ClassModels is split into one module per class.
--  Past clones (P5 Time) carry the PastClone attribute, which lets them pass the ultimates' clone checks.
--  Last Stand protection lives in ClassService.S.Incoming (after all modifiers, covers status damage), PlayerEncounter.ExecuteHit (all but P5Finality / P5BlackHole) and HealthPenaltyService.Apply.
--  Attack tokens may set IgnoreSight = true to skip ClearSight. SFX (Pro Sound Effects, Creator Store): 9120769331 sonic boom, 9114362135 explosion.
