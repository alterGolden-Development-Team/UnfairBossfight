# Task list: Untangle the Boss System Code
Full details, acceptance criteria and risks: [plan.md](plan.md).
Every task passes the "three checks" (build, analyzer diff, Studio playtest). **(you)** = needs you in Studio.

## Phase 0: Safety net
- [ ] 1. Commit current work in clean pieces; decide on the `TickEvery = 0.2` edit (you decide)
- [ ] 2. `tools/check.ps1`: build + analyzer diff against a stored baseline

## Checkpoint: Safety net
- [ ] Clean `git status`; check script passes on a clean tree and fails on a deliberate error

## Phase 1: Dead code
- [ ] 3. Remove unused imports (75), one commit per subsystem folder
- [ ] 4. Remove unused locals / functions (322 / 80), same batching
- [ ] 5. Decide on and remove `DisordererBackup_2026-11-09` (you decide)

## Checkpoint: Dead code
- [ ] Check script clean; one attack per phase played through (you)

## Phase 2: Duplicated files
- [ ] 6. Server/client mirror pairs become stubs (Finality x2, Polaris Camera, HyperElastic Geometry, MysteriousGuy Client)
- [ ] 7. Sibling-attack duplicate `Visuals` pairs get one shared home (Gilded Cataclysm, Direct Shot, Raining, Star Slash)

## Checkpoint: Duplicates
- [ ] Check script clean; each attack with a touched file fought once (you)

## Phase 3: Circular requires
- [ ] 8. Map the cycles into `tasks/cycles.md` (no code changes)
- [ ] 9. Break the smallest cycle (proves the approach)
- [ ] 10. Break the remaining cycles, one per commit

## Checkpoint: Cycles
- [ ] Cyclic-dependency analyzer errors gone, or the remaining few documented as intentional
- [ ] Full encounter run to Phase 5 with a clean Output window (you)

## Phase 4: Oversized files
- [ ] 11. Design the `P5Strikes.luau` split (3,829 lines); no code changes
- [ ] 12. Split `P5Strikes.luau`; function bodies moved byte-identical
- [ ] 13. Design the `Phase25Controller.luau` split (2,690 lines); no code changes

## Checkpoint: Complete
- [ ] All three checks pass; README layout section updated; no file over about 1,000 lines in the touched areas
