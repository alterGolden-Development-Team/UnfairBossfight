# Circular requires in `BossSystem` (Task 8)

Method: `luau-lsp analyze` reports every `require` call site that closes a cycle. I resolved each of the **235** sites
to its target module, classified it as **load-time** (a statement at column 0, runs when the module is first required)
or **call-time** (inside a function, runs when that function is called), and computed strongly-connected groups.

## Headline
| | Result |
|---|---|
| Cyclic `require` sites the analyzer flags | 235 (one tangled group of 40 modules) |
| ...of which load-time | 100 |
| ...of which call-time (lazy, inside a function) | 135 |
| **Cycles made only of load-time requires** | **0** |

**Nothing can deadlock at load today.** The 100 load-time edges are acyclic (a clean layering), and every edge that
points "backwards" is a `require(...)` inside a function. The code already uses lazy requires as its cycle-breaker.
The analyzer's complaint ("cyclic dependencies are only supported if all modules use `export`") is a type-checking
limitation, not a run-time fault: Luau cannot infer types across the cycle, which is also why many `Key 'X' not found`
type errors appear.

## The call-time back-edges, by hub
Targets that other modules reach "backwards" into (call-time edges): `StatusEffectService` 17, `PassiveController` 17,
`PlayerEncounter` 13, `TimeEffectController` 8, `RealityController` 7, `ArenaPlacement` 7, `AttackRegistry` 7,
`CharacterEffects` 6, `ClassService` 6, `UltimateService` 5.
Sources with the most: `PhaseController` 31, `PlayerEncounter` 15, `Phase25Controller` 14, `ClassService` 12,
`StatusEffectService` 10, `CloneController` 9.

## Two-way pairs (A requires B and B requires A)
| Pair | Load-time side | Call-time side (the lazy back-edge) | What a real cut would be |
|---|---|---|---|
| `CombatRuntime` <-> `ArenaPlacement` | `ArenaPlacement` -> `Runtime.Effects/AllTargets` | `CombatRuntime:198` -> `Placement.GetBounds/Validate/GroundPoint` (knockback containment) | Move the knockback-containment block into `ArenaPlacement` (or a new `Knockback` module) and change its callers |
| `StatusEffectService` <-> `ShieldBreakControl` | `ShieldBreakControl` -> `Status` | `StatusEffectService:1214` `.Clear(character)` | Let `ShieldBreakControl` register a "clear on removal" hook with `StatusEffectService` |
| `StatusEffectService` <-> `CardDebuffService` | `CardDebuffService` -> `S` | `:1095, :1106, :1213` `.Apply / .ClearCharacter` | Same hook/registry idea |
| `StatusEffectService` <-> `RealityController` | `RealityController` -> `Status` | `:1215` `.ClearCharacter` | Same |
| `StatusEffectService` <-> `TimeEffectController` | `StatusEffectService:14` -> `Time` | `TimeEffectController:366, 369, 504, 576` -> `RefreshMovement / SetLocked` | Hook, or move `RefreshMovement/SetLocked` down into a lower layer |
| `StatusEffectService` <-> `PlayerEncounter` | (lazy both ways) | `:37, 798, 923, 1098` -> `DamageOwner / CanReceiveHit`; `PlayerEncounter:123, 284` -> `StatusEffectService` | Pass the two predicates in once at startup |
| `PlayerEncounter` <-> `ClassService` | (lazy both ways) | `PlayerEncounter:251-553` -> `Incoming / OnDamaged / Apply` | An event on `PlayerEncounter` that `ClassService` subscribes to |
| `PlayerEncounter` <-> `CharacterEffects` | | `PlayerEncounter:548` `.Death`; `CharacterEffects:463` `.Say` | Event, or pass `Say` in |
| `EffectService` <-> `TimeEffectController` | | `EffectService:15` and `TimeEffectController:440, 535` | Lower-layer shared helper |
| `ProjectileService` <-> `Phase25Controller` | | `ProjectileService:1246` `.OnTemporalEmission`; `Phase25Controller:2099` | Hook |
| `Phase25Controller` <-> `PhaseController` | `PhaseController:15` -> `Phase25` | `Phase25Controller:2220, 2449` -> `ShieldBroken / BeginPhase3` | Callback passed to `Phase25Controller` |

## Recommendation (why Tasks 9-10 were not carried out)
Every cut above is a **small dependency inversion** (a hook, an event, or a function moved down a layer), and each one
changes who calls whom and in what order. At run time the cycles are already safe, so the payoff is cleaner types and
easier reading, not a bug fix. I did not make them without being able to play the encounter, because a hook that is
registered one frame late, or a moved function with a missed caller, only shows up in a fight.

If you want to proceed, the order with the best value for the least risk is:
1. `StatusEffectService` hooks (`ShieldBreakControl`, `CardDebuffService`, `RealityController`): they all hang off the
   same three "clear this character" lines (`:1213-1215`), so one `OnCharacterCleared` registry removes three pairs.
2. `PlayerEncounter` <-> `ClassService` / `CharacterEffects` / `StatusEffectService`: one event/predicate set.
3. `CombatRuntime` <-> `ArenaPlacement` (moves real code).
Each should be its own commit, verified with `tools/check.ps1` and a fight that exercises the touched hook.
