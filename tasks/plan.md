# Implementation Plan: Untangle the Boss System Code

## Overview
The Rojo/Studio sync is fixed and the first dead-code pass is done (see "Done so far"). What remains is
the structural debt a review of the 155k-line, 774-script codebase found: dead code, byte-identical
copied files, circular `require`s between core services, and a handful of 1,500-3,800 line files.
The goal is a codebase that is smaller and easier to change **without changing how any attack plays**.
There are no automated tests, so every task is made safe by the same three checks (below) instead.

## Done so far
- Rojo sync fixed: restored `init.meta.json` for `ServerStorage/BossEncounter` (+`Archive`, `IntegrationTests`),
  recovered `Templates` / `Assets` / `NPCs` from `place/TheGoldenEncounter.rbxl` as `.rbxm`.
- Removed dead code: first `FX.Text` (ClassFX), old `P.TearerCharge` (P5Strikes), dead chain/session code
  (P5EnhancedGildedCataclysm), fixed mixed indentation (AttackController). About 100 lines.
- All of the above is **uncommitted**.

## How every task is verified (the "three checks")
There is no test suite, so a task is only done when all three pass:
1. **Build:** `rojo build default.project.json -o <temp>.rbxl` succeeds.
2. **Analyzer diff:** run `luau-lsp analyze` (the binary in the VS Code extension) with
   `--sourcemap` from `rojo sourcemap` and `--definitions` (`globalTypes.PluginSecurity.d.luau`), normalise
   line numbers, and diff against the baseline. **No diagnostic may be added**; the expected ones disappear.
   (Task 2 turns this into one command.)
3. **Studio playtest of the touched attacks/systems:** for any task that edits runtime code, start the
   encounter and trigger the affected attacks, with the Output window open for errors. Only the user can
   judge "feels the same", so these steps are marked **(you)**.

## Architecture Decisions
- **Refactor and cleanup only, never mixed with behavior changes.** The pending `TickEvery = 0.2` edit in
  `P5DeathRoar/Style.luau` is a gameplay change and is committed separately (or reverted) in Task 1.
- **Smallest blast radius first.** Dead code -> duplicate files -> require cycles -> big-file splits.
  Each phase ends with a playtest checkpoint.
- **One logical change per commit**, so any single step can be reverted if the playtest finds a problem.
- **Shared code for server + client lives in `ReplicatedStorage`.** Where the same file exists in
  `ServerScriptService` and `ReplicatedStorage`, the `ReplicatedStorage` copy is canonical and the server
  copy becomes a one-line `return require(...)`.
- **Cycles are broken with lazy `require`s (inside the function that needs them), not by redesigning the
  services**, unless Task 8's map shows a cleaner cut.
- **Every folder under `src/` keeps an `init.meta.json`** with `ignoreUnknownInstances` (the cause of the
  original data loss). Any new folder a task creates must get one.

## Task List

### Phase 0: Safety net
- [ ] Task 1: Commit the current work in clean pieces
- [ ] Task 2: One-command check script (build + analyzer diff)

### Checkpoint: Safety net
- [ ] Clean `git status`, check script reproduces the baseline

### Phase 1: Dead code (lowest risk)
- [ ] Task 3: Remove unused imports (75), by subsystem
- [ ] Task 4: Remove unused locals and functions (322 / 80), by subsystem
- [ ] Task 5: Decide on and remove `DisordererBackup_2026-11-09`

### Checkpoint: Dead code
- [ ] Check script clean, playtest one attack per phase (you)

### Phase 2: Duplicated files
- [ ] Task 6: Server/client mirror pairs become stubs (5 files)
- [ ] Task 7: Sibling-attack duplicate `Visuals` pairs get one shared home (4 pairs)

### Checkpoint: Duplicates
- [ ] Check script clean, playtest each attack that owns a touched file (you)

### Phase 3: Circular requires
- [ ] Task 8: Map the cycles (investigation, no code changes)
- [ ] Task 9: Break the smallest cycle
- [ ] Task 10: Break the remaining cycles, one per commit

### Checkpoint: Cycles
- [ ] "Cyclic dependencies" analyzer errors gone or reduced to a documented, intentional few
- [ ] Full encounter runs start to Phase 5 without errors (you)

### Phase 4: Oversized files
- [ ] Task 11: Decide the split design for `P5Strikes.luau` (3,829 lines)
- [ ] Task 12: Split `P5Strikes.luau`
- [ ] Task 13: Plan the `Phase25Controller.luau` (2,690) split

### Checkpoint: Complete
- [ ] All three checks pass, README layout section updated

## Tasks

### Task 1: Commit the current work in clean pieces
**Description:** Land the sync fix, the recovered assets and the cleanup as separate commits so each can be
reverted alone, and settle the stray gameplay edit.
**Acceptance criteria:**
- [ ] Commit A: `init.meta.json` files + recovered `.rbxm` templates + README note
- [ ] Commit B: the dead-code cleanup (ClassFX, P5Strikes, Cataclysm, AttackController indentation)
- [ ] `P5DeathRoar/Style.luau` `TickEvery = 0.2` is either committed on its own with a proper comment, or reverted (**ask the user**; the comment still says "5 ticks")
**Verification:** `git status` clean; `git log` shows three focused commits; `rojo build` succeeds.
**Dependencies:** None
**Files likely touched:** `src/ServerStorage/BossEncounter/**`, `README.md`, the 4 cleaned files, `P5DeathRoar/Style.luau`
**Scope:** Small

### Task 2: One-command check script
**Description:** Wrap the three mechanical checks in `tools/check.ps1` so later tasks are cheap to verify.
It builds, runs the analyzer, normalises line numbers and diffs against a stored baseline.
**Acceptance criteria:**
- [ ] `powershell tools/check.ps1` exits non-zero if the build fails or any diagnostic is added
- [ ] Baseline stored in `tools/analyzer-baseline.txt`; a `-UpdateBaseline` switch rewrites it
- [ ] Locates `luau-lsp` and the type definitions without hard-coded user paths (VS Code extensions folder glob)
**Verification:** Run it twice on a clean tree (passes); add a deliberate `local x = undefined_var` to a file (fails); revert.
**Dependencies:** Task 1
**Files likely touched:** `tools/check.ps1`, `tools/analyzer-baseline.txt`, `README.md`
**Scope:** Small

### Task 3: Remove unused imports (75), by subsystem
**Description:** Delete `local X = require(...)` lines the analyzer reports as `ImportUnused`. Do **not**
delete a `require` whose module does work at load (registers a handler, starts a loop); for those, keep the
call without the unused local.
**Acceptance criteria:**
- [ ] Every `ImportUnused` removed, or kept with a one-line reason if the module has load-time effects
- [ ] One commit per subsystem folder (`Attacks/P1`, `Attacks/P5`, `Combat`, `Players`, `VFXEngine`, ...)
**Verification:** check script (the `ImportUnused` count drops, nothing added); playtest one attack from each touched folder (you).
**Dependencies:** Task 2
**Files likely touched:** Up to ~75 files, in batches of <= 5 files per commit
**Scope:** Medium (many tiny edits; split by folder)

### Task 4: Remove unused locals and functions (322 / 80)
**Description:** Same as Task 3 for `LocalUnused` and `FunctionUnused`. Skip anything that is part of a
module's returned API or that is reachable via a string lookup (attack names, `Net.Send` handlers).
**Acceptance criteria:**
- [ ] `grep` for the symbol across `src/` shows no other reference before removal
- [ ] Anything intentionally kept is renamed `_name` or left with a reason
**Verification:** check script; playtest per touched folder (you).
**Dependencies:** Task 3
**Files likely touched:** Batches of <= 5 files per commit
**Scope:** Medium

### Task 5: Decide on and remove `DisordererBackup_2026-11-09`
**Description:** `src/ServerStorage/DisordererBackup_2026-11-09` (9 modules, about 10k lines) is referenced
nowhere and every file already differs from its live version. **Ask the user** whether it is still wanted.
If not, delete it (git history keeps it).
**Acceptance criteria:**
- [ ] User confirms deletion (or keeps it, and the task is closed as "kept")
- [ ] Folder removed from `src/`; Rojo removes it from Studio on the next sync
**Verification:** `grep -r DisordererBackup src` empty; check script; Studio ServerStorage no longer lists it.
**Dependencies:** Task 2
**Files likely touched:** `src/ServerStorage/DisordererBackup_2026-11-09/**`
**Scope:** Small

### Task 6: Server/client mirror pairs become stubs
**Description:** Five files exist byte-identical in `ReplicatedStorage` and `ServerScriptService`:
`FinalityRuntime/Visuals`, `FinalityRuntime/Geometry`, `PolarisRuntime/Camera`,
`HyperElasticRuntime/Geometry`, `MysteriousGuyRuntime/Client`. Keep the `ReplicatedStorage` copy and make
the server copy `return require(game:GetService("ReplicatedStorage")...)`.
**Acceptance criteria:**
- [ ] Per pair: confirm the module holds no mutable module-level state that two server-side requirers would now share
- [ ] Server copy is a one-line re-export; nothing else references the old path differently
**Verification:** check script; trigger Finality, Polaris, Hyper-elastic Beam and Mysterious Guy on the server and watch the client visuals (you).
**Dependencies:** Task 2
**Files likely touched:** 5 server files
**Scope:** Small-Medium (one commit per attack)

### Task 7: Sibling-attack duplicate `Visuals` pairs get one shared home
**Description:** Four pairs are identical across attack folders: `P1GildedCataclysm`/`P5EnhancedGildedCataclysm`,
`P2DirectShot`/`P5EnhancedDirectShot`, `P1.5Raining`/`P4EnhancedRaining`, `P4StarSlash`/`P5EnhancedStarSlash`.
Move each pair's code into one module (the base attack's folder, or `Attacks/Shared`) and make the "Enhanced"
copy a re-export.
**Acceptance criteria:**
- [ ] One real copy per pair; the other is a one-line `require`
- [ ] No new folder without an `init.meta.json`
**Verification:** check script; fight each of the 8 attacks once (you).
**Dependencies:** Task 2
**Files likely touched:** 4 files + 4 stubs
**Scope:** Medium (one commit per pair)

### Task 8: Map the cycles (investigation only)
**Description:** The analyzer reports about 20k cyclic-dependency errors. Extract the distinct cycles
(from `StatusEffectService`, `PlayerEncounter`, `R6DashService`, `TimeEffectController`, `CharacterEffects`,
`EffectService`, ...) into `tasks/cycles.md`: members, the specific `require` edges, and the smallest edge
to cut for each.
**Acceptance criteria:**
- [ ] `tasks/cycles.md` lists every distinct cycle with its edges, ranked by size
- [ ] For each, a proposed cut and whether the `require` is needed at load or only at call time
**Verification:** Review with the user; no source files changed.
**Dependencies:** Task 2
**Files likely touched:** `tasks/cycles.md` only
**Scope:** Small

### Task 9: Break the smallest cycle
**Description:** Apply the proposed cut from Task 8 for the smallest cycle (move the `require` inside the
function that uses it, or pass the dependency in) as the proof of the approach.
**Acceptance criteria:**
- [ ] That cycle no longer appears in the analyzer output
- [ ] No behavior change at load: the module's top-level code does not use the lazily required module
**Verification:** check script; start an encounter and confirm no "attempt to index nil" / require errors in Output (you).
**Dependencies:** Task 8
**Files likely touched:** 2-3 files
**Scope:** Small

### Task 10: Break the remaining cycles, one per commit
**Description:** Repeat Task 9 for each remaining cycle in Task 8's ranking. Stop and ask if a cut would
need a redesign instead of a lazy require.
**Acceptance criteria:**
- [ ] Each cycle removed or explicitly documented as intentional in `tasks/cycles.md`
**Verification:** check script after each; a full run through every phase after the last (you).
**Dependencies:** Task 9
**Files likely touched:** Per cycle, 2-5 files
**Scope:** Medium-Large (split per cycle)

### Task 11: Decide the split design for `P5Strikes.luau`
**Description:** `ReplicatedStorage/VFXEngine/Effects/P5Strikes.luau` is 3,829 lines of `P.<Name>(E, d)`
effect functions in one table. Find out how `VFXEngine` loads effect modules (one file = one effect name? a
registry?) and propose a split, for example one module per attack family. No code changes.
**Acceptance criteria:**
- [ ] Short design note in `tasks/plan.md` or `tasks/p5strikes-split.md`: grouping, new file names, how the loader finds them
- [ ] Confirms shared helpers (`newPart`, colors) can move to one `Shared` module
**Verification:** User approves the design.
**Dependencies:** Task 6 (so the VFX layout is settled)
**Files likely touched:** one design note
**Scope:** Small

### Task 12: Split `P5Strikes.luau`
**Description:** Implement the approved design, moving functions without editing their bodies.
**Acceptance criteria:**
- [ ] No resulting file over about 1,000 lines
- [ ] Every `P.<Name>` is still reachable under the same effect name
- [ ] Function bodies are byte-identical to before (verified by diffing the moved text)
**Verification:** check script; trigger every P5 strike effect at least once (you).
**Dependencies:** Task 11
**Files likely touched:** `P5Strikes.luau` + 3-5 new modules (+ meta files)
**Scope:** Large (do it in commits of 1-2 functions-groups each)

### Task 13: Plan the `Phase25Controller.luau` split
**Description:** Same investigation as Task 11 for the 2,690-line `Phases/Phase25Controller.luau` (and later
`PhaseController` at 1,570, `Phase3Intro` at 1,467). Output a design, no code changes.
**Acceptance criteria:**
- [ ] Design note listing responsibilities (intro cinematic, attack scheduling, transitions, cleanup) and the proposed module for each
**Verification:** User approves, then a follow-up plan is written for the implementation.
**Dependencies:** Task 10
**Files likely touched:** one design note
**Scope:** Small

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| No automated tests, so a refactor can silently change an attack | High | Three checks per task, small commits, playtest checkpoints, bodies moved byte-identical |
| Lazy `require` changes load order and a module that relied on the cycle breaks | High | Task 8 classifies each edge as load-time vs call-time first; start with the smallest cycle |
| A "stub" re-export shares state between two callers that used to have separate copies | Med | Task 6 checks module-level mutable state per pair |
| Removing an "unused" function that is called by name from a string (attack/effect registries) | Med | `grep` the symbol and the string form before removal; skip API surfaces |
| Rojo overwrites Studio-side edits to `.rbxm` assets | Med | README note; re-export from Studio before editing; commit often |
| Studio edits made while Rojo is connected are not synced back to files | Med | Keep VS Code as the editing side; re-export (`tools/ExportFromStudio.luau`) if Studio is ahead |

## Open Questions
- `TickEvery = 0.2` in `P5DeathRoar/Style.luau`: intended gameplay change or a test value? (Task 1)
- Is `DisordererBackup_2026-11-09` still wanted? (Task 5)
- Was the boss template edited in Studio after the 16:27 snapshot? If so, those edits are lost and need redoing. (Recovered `.rbxm`)
- How much playtesting time can you give each checkpoint? The **(you)** steps can't be automated.

## Findings from Phases 2-3 (read this before Tasks 9-13)
- **Mirror drift is already live, and goes both ways.** `Presentation.Publish()` only clones the server copy into
  `ReplicatedStorage/BossShared/Presentation/*Runtime` when that folder does not exist, so **clients run the committed
  ReplicatedStorage copy**. Four of the nine pairs differ:
  - `HyperElasticRuntime/Style`: static has `BeamRange=360`, `RingMaxRadius=220`; server has `620` / `380`. The server
    hits out to 620 while clients draw a 360 beam.
  - `PolarisRuntime/Style`: static lacks the whole `Aurora` table and has `ScreenRange=260` (server: 420).
  - `HyperElasticRuntime/Visuals`: static has the newer ground-matching colours (`GroundLook`); server has the newer
    `shockDisc` effects. Neither is a superset.
  - `BlackHoleRuntime/Client`: server removed the local explosion (now in `VFXEngine.BlackHoleDebris`); static still draws it.
  **Needs your decision** which side is intended for each, then copy that side over (and flip the pair to `identical` in
  `tools/mirror-pairs.txt`). Not merged automatically because it changes what players see.
- **Task 6 as written was unsafe**: `Camera`, `Client` and `Visuals` hold per-instance state, and a re-export stub would
  make every cast share it. Replaced by the drift guard.
- **Task 7**: three of four pairs consolidated. `P4StarSlash`/`P5EnhancedStarSlash` stay separate (sibling `Style` differs).
- **Tasks 9-10**: see `tasks/cycles.md`. No run-time cycle exists; each cut is a redesign, deferred pending your call.

## Phase 4 outcome (P5Strikes and Phase25Controller)
- Decisions taken on the drift pairs: the **server copy wins** for `HyperElasticRuntime/Style`, `PolarisRuntime/Style` and
  `BlackHoleRuntime/Client` (newer, and the server is what decides hits); `HyperElasticRuntime/Visuals` is a **merge** of both
  sides (ground-matched colours + the extra `shockDisc` effects). All 9 mirror pairs are identical again, and
  `tools/check.ps1 -SyncMirrors` re-copies server -> ReplicatedStorage so they stay that way.
- `check.ps1` no longer gates on the ~20-26k cross-module type-inference messages (symptoms of the cycles in
  `tasks/cycles.md`); it still gates on everything that indicates a real problem. Baseline: 340 distinct diagnostics.
- Two latent bugs surfaced by the splits and fixed: a missing `return` that would have stopped `P5Strikes` from loading (caught
  by the analyzer before commit), and an undefined `g` in `SilentHit`'s floor raycast.
- Still large (next targets, "bigger fish"): `VFXEngine/Effects/P5SonicBlaster` 1,874, `Disorderer` 1,847, `P5Ascend` 1,725,
  the HyperElastic `Visuals` mirror pair (about 1,700 each), `Combat/ProjectileService` 1,624, `Phases/PhaseController` 1,570,
  `Phases/Phase3Intro` 1,467, `Combat/StatusEffectService` 1,442; and single huge functions inside the new files:
  `startLastMinuteCollapse` (532 lines, in `Phase25Controller/LastMinute`) and `BeginFalseTelegraph` (276).
- Rojo was not running during this work, so Studio still holds the pre-split scripts. Start Rojo and click Connect in Studio;
  it will add the new folder modules and remove the old single files.
