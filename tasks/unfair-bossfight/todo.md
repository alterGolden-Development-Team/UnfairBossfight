# Task list: Unfair Bossfight (lobby + private boss place)
Details, acceptance criteria and risks: [plan.md](plan.md). Spec: [../../docs/spec/unfair-bossfight.md](../../docs/spec/unfair-bossfight.md).
Every task passes `tools/check.ps1` (build + analyzer diff). **(you)** = needs you in Studio, Creator Hub or an alt account.
Task numbers match plan.md; they are listed in build order, not numeric order.

## Phase 0: Safety and layout
- [x] 1. Commit docs (intent, spec, plan)
- [x] 2. Move repo to `D:/Project/UnfairBossfight` (`boss/`), fix paths, copy Claude memory (done as a clone + `git mv`, so the old folder is untouched and nothing had to be closed)
- [x] 3. Lobby skeleton, `shared/UnfairShared/UnfairConfig`, mounts, `check.ps1` for both projects
- [x] 4. Test universe with copies of both places **(you)** (universe 10775538032 "Unfair Bossfight TEST": lobby 83310105029258, boss 76581021814220)
- [x] 5. Place IDs and `Env` switch into `UnfairConfig` (live and test IDs in, `Env = "Test"`)

## Checkpoint A: Layout and test universe
- [x] Both projects build and pass `check.ps1`; Rojo serves 34872 (boss) and 34873 (lobby); test universe IDs recorded

## Phase 1: Contracts (pure logic)
- [x] 6. `TeleportPayload` build and validate, with tests (20 cases)
- [x] 7. `PartyState` state machine, with tests (28 cases)
- [x] 20. `CashRules` payout table, with tests (6 cases)

## Phase 2: Lobby slices
- [x] (user finished the section B Studio checks of user-tests.md: map, class picker, party UI, coming-soon panels, 3 clients)
- [x] 11. Lobby map shell: plaza, spawn, 3 portal arches, `MAP.md` **(you review)** (built in the test lobby window, contract in `lobby/MAP.md`; waits for your review and a save to `lobby/place/Lobby.rbxl`)
- [x] 12. Lobby map: class hall, 4 party rooms, shop shell **(you review)** (same)
- [x] 13. Class picker server: `UnlockCheck`, `ClassPickService` (13 tests; Play-tested: pick, bogus class ignored, TrueWarrior locked with hint, owned classes unlock)
- [x] 14. Class picker UI **(you)** (Play-tested and screenshotted; waits for your click-through)
- [x] 15. Party rooms server: `PartyService` (Play-tested with 1 client: join, leader settings, Easy clears Enraged, countdown, walk-away cancels; the 3-client test still to do)
- [x] 16. Party room UI: leader panel, roster, countdown **(you)** (Play-tested with 1 client; waits for your check)
- [x] 17. `LaunchService` with Studio dry-run (`LaunchPlan` 10 tests; dry-run payload checked in Play: right class, difficulty, Enraged)

## Checkpoint B: Lobby flow in Studio
- [x] 2+ test clients: classes picked, party formed, config set, dry-run payload correct **(you)**

## Phase 3: Boss intake
- [x] 8. `Intake` validate and apply (class, difficulty, enraged, lock, reject non-reserved) (`IntakeRules` pure + 18 tests, `Intake.luau` glue; wired in `FightBootstrap`)
- [x] 9. Hide statue, gate and class prompts in lobby mode; retry hint text **(you replay a fight)** (user replayed in Studio: Return button and the Studio message worked) (code in: prompts disabled and props hidden in lobby mode, remotes refuse; waits for your Studio replay)
- [x] 10. Dev-payload harness and intake test cases (`UnfairConfig.DevPayload` for Studio, 18 cases in `IntakeRulesTests`; the in-Studio play check still to do)

## Phase 4: First real teleport, run end, cash
What is left for a person to run is in [user-tests.md](user-tests.md) (sections A to D).
- [x] Boss map copied into the test boss place and synced with Rojo; intake run in Studio with a dev payload (Mage, Hardcore, Enraged): attributes right, statues, gate and prompts hidden; Return refused while alive and accepted when defeated; cash paid once per run, failed write retried not thrown
- [x] 18. Published test-universe teleport test with 2 accounts **(you)** (everything it needs is built; user-tests D1)
- [x] (also needed first) The boss map in the test boss place: Save to Roblox As from the live Golden Encounter window **(you)** (user-tests A2)

## Checkpoint C: Real teleport works
- [x] Party lands in a private boss server with the right class, difficulty and Enraged; direct boss join bounces to lobby

- [x] 19. Return to Lobby button and teleport **(you)** (`ReturnRules` 6 tests; `LobbyReturn` + `ReturnToLobbyClient` in; button and answer clicked in Studio with a stand-in server; the real teleport is user-tests D2)
- [x] 21. `CashService` in boss (DataStore write on win, once per run) (`CashLedger` 12 tests; `CashService` + the `VictoryRewards` hook in; the DataStore write itself has not run yet: needs Studio API access or the test universe, user-tests C and D3)
- [x] 22. Cash HUD in lobby **(you)** (`CashService` + `CashHudClient` Play-tested: `--` on a failed read, `Cash: 1,320` and the +gain after a good one; waits for a real balance, user-tests D3)
- [x] 23. End-to-end and regression: cash, solo badge, Retry in place **(you)** (user-tests D2 and D3)

## Checkpoint D: Run loop complete
- [x] Win pays cash once, lobby shows it, Retry and Return work, solo badge detection unchanged

## Phase 5: Cut-over
- [x] 24. Coming-soon panels and polish **(you)** (`PadInfoClient` + `PadInfo`: panel shows at both arches and the shop, no teleport path; audio not done, see user-tests)
- [ ] 25. Cut-over to the live universe (backups, start place, rename, `RequireLobby = true`) **(you, explicit go-ahead)** (runbook written in [../../docs/cutover.md](../../docs/cutover.md); nothing live touched, waits for Checkpoints C, D and your go-ahead)

## Checkpoint E: Live
- [ ] Joining lands in the lobby; boss-place link bounces back; a live party run works

- [x] 26. README, ports and "add the next pad" notes; update Claude memory (README rewritten and memory updated; revisit after the cut-over)

## Later (own spec)
- [ ] Shop: powerups and classes bought with cash
