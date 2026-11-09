# Task list: Unfair Bossfight (lobby + private boss place)
Details, acceptance criteria and risks: [plan.md](plan.md). Spec: [../../docs/spec/unfair-bossfight.md](../../docs/spec/unfair-bossfight.md).
Every task passes `tools/check.ps1` (build + analyzer diff). **(you)** = needs you in Studio, Creator Hub or an alt account.
Task numbers match plan.md; they are listed in build order, not numeric order.

## Phase 0: Safety and layout
- [ ] 1. Commit docs (intent, spec, plan)
- [ ] 2. Move repo to `D:/UnfairBossfight` (`boss/`), fix paths, copy Claude memory **(you: close VS Code, Studio, Rojo; reopen from the new folder)**
- [ ] 3. Lobby skeleton, `shared/UnfairShared/UnfairConfig`, mounts, `check.ps1` for both projects
- [ ] 4. Test universe with copies of both places **(you)**
- [ ] 5. Place IDs and `Env` switch into `UnfairConfig`

## Checkpoint A: Layout and test universe
- [ ] Both projects build and pass `check.ps1`; Rojo serves 34872 (boss) and 34873 (lobby); test universe IDs recorded

## Phase 1: Contracts (pure logic)
- [ ] 6. `TeleportPayload` build and validate, with tests
- [ ] 7. `PartyState` state machine, with tests
- [ ] 20. `CashRules` payout table, with tests

## Phase 2: Lobby slices
- [ ] 11. Lobby map shell: plaza, spawn, 3 portal arches, `MAP.md` **(you review)**
- [ ] 12. Lobby map: class hall, 4 party rooms, shop shell **(you review)**
- [ ] 13. Class picker server: `UnlockCheck`, `ClassPickService`
- [ ] 14. Class picker UI **(you)**
- [ ] 15. Party rooms server: `PartyService`
- [ ] 16. Party room UI: leader panel, roster, countdown **(you)**
- [ ] 17. `LaunchService` with Studio dry-run

## Checkpoint B: Lobby flow in Studio
- [ ] 2+ test clients: classes picked, party formed, config set, dry-run payload correct **(you)**

## Phase 3: Boss intake
- [ ] 8. `Intake` validate and apply (class, difficulty, enraged, lock, reject non-reserved)
- [ ] 9. Hide statue, gate and class prompts in lobby mode; retry hint text **(you replay a fight)**
- [ ] 10. Dev-payload harness and intake test cases

## Phase 4: First real teleport, run end, cash
- [ ] 18. Published test-universe teleport test with 2 accounts **(you)**

## Checkpoint C: Real teleport works
- [ ] Party lands in a private boss server with the right class, difficulty and Enraged; direct boss join bounces to lobby

- [ ] 19. Return to Lobby button and teleport **(you)**
- [ ] 21. `CashService` in boss (DataStore write on win, once per run)
- [ ] 22. Cash HUD in lobby **(you)**
- [ ] 23. End-to-end and regression: cash, solo badge, Retry in place **(you)**

## Checkpoint D: Run loop complete
- [ ] Win pays cash once, lobby shows it, Retry and Return work, solo badge detection unchanged

## Phase 5: Cut-over
- [ ] 24. Coming-soon panels and polish **(you)**
- [ ] 25. Cut-over to the live universe (backups, start place, rename, `RequireLobby = true`) **(you, explicit go-ahead)**

## Checkpoint E: Live
- [ ] Joining lands in the lobby; boss-place link bounces back; a live party run works

- [ ] 26. README, ports and "add the next pad" notes; update Claude memory

## Later (own spec)
- [ ] Shop: powerups and classes bought with cash
