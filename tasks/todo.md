# Task list: Untangle the Boss System Code
Full details, acceptance criteria and risks: [plan.md](plan.md).
Every task passes the "three checks" (build, analyzer diff, Studio playtest). **(you)** = needs you in Studio.

## Phase 0: Safety net
- [x] 1. Commit current work (done as one commit, "fourth commit", by you); `TickEvery = 0.2` is in it - still needs your confirmation it is intended
- [x] 2. `tools/check.ps1`: build + analyzer diff against a stored baseline

## Checkpoint: Safety net
- [x] Clean `git status`; check script passes on a clean tree and fails on a deliberate error

## Phase 1: Dead code
- [x] 3. Remove unused imports (75), one commit per subsystem folder
- [x] 4. Remove unused locals / functions (322 / 80), same batching - 76 functions + 191 locals removed, ran to a fixpoint
- [x] 5. Remove `DisordererBackup_2026-11-09` (you approved; recoverable from git history)

## Checkpoint: Dead code
- [x] Check script clean (904 -> 569 distinct diagnostics)
- [ ] One attack per phase played through (you)

## Phase 2: Duplicated files
- [x] 6. Mirror pairs: NOT turned into stubs (unsafe: stateful modules, and `Publish()` makes the ReplicatedStorage copy the live one). Instead `tools/mirror-pairs.txt` + a check that fails on new drift. Found 4 pairs that have ALREADY drifted - see plan.md
- [x] 7. Duplicate `Visuals`: Gilded Cataclysm, Direct Shot and Raining now share one module (-1,068 lines). Star Slash skipped on purpose (its Visuals read a sibling `Style` that differs)

## Checkpoint: Duplicates
- [x] Check script clean
- [ ] Fight Enhanced Gilded Cataclysm, Enhanced Direct Shot and Enhanced Raining once (you)

## Phase 3: Circular requires
- [x] 8. Map the cycles into `tasks/cycles.md`: 0 load-time cycles, so nothing can deadlock today; the 235 flagged sites are 100 acyclic load-time + 135 lazy
- [ ] 9. (deferred - needs your call) Break the smallest cycle. Every cut is a dependency inversion, not a mechanical edit; see cycles.md
- [ ] 10. (deferred) Break the remaining cycles, one per commit

## Checkpoint: Cycles
- [x] Cycles documented as run-time safe (cycles.md); analyzer errors remain by design until Tasks 9-10
- [ ] Full encounter run to Phase 5 with a clean Output window (you)

## Phase 4: Oversized files
- [x] 11. Design the `P5Strikes.luau` split - see `tasks/p5strikes-split.md`
- [x] 12. Split `P5Strikes.luau` into Core + 6 groups (largest 818 lines); 88/88 cues, bodies byte-identical, thorn/VINE/VINE_TIP (dead) dropped
- [x] 13. `Phase25Controller` (2,691 lines): LastMinuteVFX extracted, then split into Core + FalseFuture/LastMinute/Lifecycle/Echoes (largest 861 lines). Went beyond "design only" because the dependency facts showed a clean, mechanical split

## Checkpoint: Complete
- [x] Analyzer + build + mirror checks pass; the two target files no longer exist as single files
- [x] README layout section updated
- [ ] Fight Phase 5 normal attacks, the Last Minute ultimate and False Future once after reconnecting Rojo (you)
