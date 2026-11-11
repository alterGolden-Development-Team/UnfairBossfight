# BossKit: the fight layer every bossfight map shares

Every boss in Unfair Bossfight fights on the same rules: R6 bodies, lives, HP and stamina, dash with i-frames (Q), deflect (E),
guard and perfect guard (R), the nine classes and all their skills, the boss's HP and shield, damage numbers. Those rules were built
for the Golden Encounter and live in `alterGolden Bossfight/src`. A new boss map does not copy them: it **mounts** them and talks to them
through one module, `shared/UnfairShared/BossKit`.

## What a boss place mounts

See `tutorial/default.project.json` (Azusa's place, the first map built this way). Everything comes from `alterGolden Bossfight/src`:

| Where in the place | From | What it is |
|---|---|---|
| `ReplicatedStorage.BossShared` (+ `ClassModels`) | `ReplicatedStorage/BossShared` | class config, dash motion, VFX helpers, the vitals panel builder |
| `ReplicatedStorage.VFXEngine` | `ReplicatedStorage/VFXEngine` | skill effects |
| `ServerScriptService.BossSystem.*` | `ServerScriptService/BossSystem/*` | `PlayerEncounter` (lives, damage), `R6DashService`, `DeflectService`, `ClassService` + kits, `BossDamageService` |
| `StarterGui.PlayerVitalsHUD` | `StarterGui/PlayerVitalsHUD` | hearts, HP, stamina, the dash key (builds its own panel when the place file has none) |
| `StarterPlayerScripts.BossClient.Players.*` | `ClassClient`, `ClassAnimator`, `R6ActionAnimations`, `PlayerEncounterClient` | class keys, animations, death/respawn |
| `StarterPlayerScripts.BossClient.Presentation.*` | `BossAudioClient`, `BossCombatEffectsClient` (+ `GoldenHourView`), `DeflectClient` | sounds, damage numbers, the deflect shield |
| `StarterPlayerScripts.VFXEngineClient` | `StarterPlayer/StarterPlayerScripts/VFXEngineClient` | plays the skill effects |

Change a class, the dash or the deflect in the boss project and every boss map gets it on its next build.

## The API (`UnfairShared/BossKit`)

```lua
-- server
BossKit.Start({ Lives = 3, Class = "Warrior" })       -- once, before anyone spawns: remotes, R6 rig, lives, the services
BossKit.Register(model, { Title, Subtitle, MaxHealth, Shield, Color })   -- the boss (Humanoid + HumanoidRootPart, in Workspace)
BossKit.Begin() / BossKit.End()                        -- deaths cost lives only between these
BossKit.Hit(char, damage, bossModel, { Skill, Deflect = "Tap"|"Hold", BreaksBlock })   -- returns damage dealt or "Deflected"
BossKit.Warn(char, "Tap", seconds)                     -- the white deflect shield before a deflectable hit
BossKit.SetShield(model, amount)                       -- a shield over the boss's HP
BossKit.Say(text, seconds?)                            -- the boss speaks: typed at the bottom of the screen, like alterGolden
BossKit.Dashing(char), BossKit.Fighters(), BossKit.Revive(player, lives)

-- client
require(ReplicatedStorage.UnfairShared.BossKit.BossBar).Mount()   -- the boss's HP / shield / phase bar at the top
```

- **Hitting the boss**: `Register` makes the model the class kits' target (workspace attribute `ClassBossName`, read by
  `ClassService.Boss`) and marks it `DamageableClone`, so `BossDamageService` takes its HP and then its `Shield` attribute. Attributes
  that change how it takes damage: `Invulnerable` (no damage), `Defense` (-1..1; negative = takes more, e.g. a stagger).
- **Hitting players**: `Hit` goes through `PlayerEncounter.Damage`, so dash i-frames, guard / perfect guard, class defence and passives,
  and the damage numbers all work as in the Golden Encounter. Give `Deflect` and call `Warn` first to make a hit deflectable.
- **The bar** reads `BossTitle`, `BossSubtitle`, `BossColor`, `Shield` / `MaxShield`, `BossPhase` / `BossPhases` and `BossHidden`.

## Not moved (yet)

The engine files still live under `alterGolden Bossfight/` because alterGolden's own attacks are woven through them (phase rules in
`BossDamageService`, Golden Hour in `R6DashService`). Moving them into `shared/` is a separate refactor: the mounts above would then
point at `shared/` and nothing else would change.
