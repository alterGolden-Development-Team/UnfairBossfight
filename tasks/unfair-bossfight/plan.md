# Implementation Plan: Unfair Bossfight (lobby + private boss place)

Spec: [docs/spec/unfair-bossfight.md](../../docs/spec/unfair-bossfight.md) (approved). Intent: [docs/intent/unfair-bossfight.md](../../docs/intent/unfair-bossfight.md).
Task checklist: [todo.md](todo.md). Module ids below match the spec's capability map.

This lives in `tasks/unfair-bossfight/` because `tasks/plan.md` and `tasks/todo.md` are the refactor record and still have unchecked tasks (they were not touched). After task 2 the whole repo moves into `boss/`; this folder and `docs/` are lifted to the new root `D:/Project/UnfairBossfight/` in that task.

## Overview

Add a public lobby place in front of the existing boss place. Players pick a class, form a party (1-6, with a leader), the leader sets difficulty and Enraged, and a pad teleports the party to a reserved boss server. After a fight, players Retry or Return to Lobby. Wins pay cash saved in a shared DataStore. The shop is out of this plan (milestone 3, its own spec).

Corrections to the earlier research notes: `src/ServerStorage/BossEncounter/` is already tracked in git, so no "commit it first" task is needed. The only uncommitted work is `docs/`. Lobby class data is reused from `BossShared/Classes`, as already decided.

## Decisions (from the interview, spec and your answers)

- Lobby = "Talueber's Place: 11092026_1", the empty place. Boss = The Golden Encounter. Cut-over changes the start place to the lobby.
- A separate **test universe** is used for every teleport test. The live game is only touched in the final cut-over task.
- Return to Lobby is the only way to change difficulty. Retry stays in the same reserved server with the same settings.
- Cash table: Easy 5, NerfedHardcore 15, Hardcore 25, TrueHardcore 35, Hellaven 50; Enraged x2. 4 party rooms per lobby server.
- Git root moves to `D:/Project/UnfairBossfight`, current project goes into `boss/`, history kept (`git mv`).
- Boss place changes are kept minimal and additive (a new intake module plus small hooks), because the refactor just finished and there are no automated tests for the boss code.

## Dependency graph

```
T1 commit docs
  └─ T2 move repo (project-layout)
       └─ T3 lobby skeleton + shared config + check.ps1 for both projects
            ├─ T4 test universe (you) ── T5 place IDs into config
            ├─ T6 TeleportPayload (pure) ─┬─ T8 BossIntake validate ─ T9 hide statue/gate ─ T10 dev-payload harness
            ├─ T7 PartyState (pure) ──────┤
            └─ T11 lobby map shell ─ T12 map: class hall, party rooms, shop shell
                    ├─ T13 class picker server ─ T14 class picker UI
                    └─ T15 party rooms server (needs T7, T13) ─ T16 party UI ─ T17 LaunchService (needs T6, T5)
T8+T17 ── T18 first published teleport test (you)
T18 ── T19 Return to Lobby ──┐
T20 CashRules ─ T21 CashService (boss) ─ T22 cash HUD (lobby) ─ T23 end-to-end + solo regression (you)
T24 coming-soon panels ── T25 cut-over (you) ── T26 docs and memory
```

Parallelizable once T3 is done: T6, T7 and T11 touch different files. T20 can be done any time after T3.

## Phases

### Phase 0: Safety and layout (`project-layout`)
T1 commits the docs. T2 moves the repo (the riskiest mechanical task, so it comes first and alone). T3 gives the lobby a buildable skeleton, shared config, and extends `check.ps1` to gate both projects. T4-T5 give us somewhere safe to test teleports.

### Phase 1: Contracts as pure logic (`teleport-contract`, party state)
Roblox-free modules with assertions. These carry the security rules (validation, leader-only config, Enraged not on Easy), so they are proven before any UI exists.

### Phase 2: Lobby vertical slices (`lobby-world`, `class-picker`, `party-pads`)
Map shell first (so scripts have real named parts to attach to), then one slice at a time: pick a class, join a party room, see and set the config, launch. Launch runs in dry-run mode in Studio (logs the payload instead of calling `TeleportAsync`).

### Phase 3: Boss intake (`boss-intake`)
Validate and apply the payload on the boss side, hide the statue and gate in lobby mode, keep the Studio fallback. A dev-payload harness lets us test intake in Studio without a teleport.

### Phase 4: First real teleport, run end, cash (`run-end-flow`, `cash`)
The first published teleport test comes right after intake, so the riskiest unknown (reserved servers and teleport data in the real service) is found early. Then Return to Lobby, cash earn/save/show, and the solo-badge regression.

### Phase 5: Cut-over
Coming-soon panels and polish, then the one task that touches the live game.

## Checkpoints

- **A (after T5):** both projects build and pass `check.ps1`; both Rojo servers run on their own ports; test universe exists with its IDs in config.
- **B (after T17):** in Studio with 2+ test clients: pick classes, form a party, set config, see the dry-run payload with the right classes and settings.
- **C (after T18):** published test universe: a real party teleports from lobby to a private boss server and the boss place applies class, difficulty and Enraged with no statue interaction.
- **D (after T23):** win pays cash once per run, lobby HUD shows it, Retry and Return work, solo badge still detects a 1-player party.
- **E (after T25):** live cut-over verified; direct boss-place join is rejected.

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Teleports cannot run in Studio | High: can't test the core hop locally | Dry-run mode in Studio, test universe for real hops, find problems at Checkpoint C (early) |
| Moving the git root breaks paths, tools, Rojo, Claude memory | High | T2 is done alone, with a backup copy and `check.ps1` as the gate; paths fixed in the same task |
| Changing the start place or publishing breaks the live game | High | Only T25 touches live; it needs your explicit go-ahead; keep the old place versions for rollback |
| Boss code has no tests; intake hooks could change normal play | High | Additive hooks, fallback to current behaviour when no teleport data, you replay a fight in Studio after T9/T10 |
| `ClassService.CheckUnlock` isn't available in the lobby | Med | New `UnlockCheck` in `shared/` for the lobby; the boss re-check keeps using `ClassService` |
| Rojo wipes non-script instances in new folders | High | `init.meta.json` with `ignoreUnknownInstances` on every folder; lobby map backup `.rbxl` after each map task |
| Two Studio instances confuse the MCP connection | Med | Use `list_roblox_studios` first and name the lobby instance in each MCP session |
| Rojo serve silently stops | Med | Check ports 34872 (boss) and 34873 (lobby) before comparing Studio to files |
| DataStore throttling or failure on win | Med | `UpdateAsync` with retry and backoff, per-run guard, pending amount kept in session |
| Party member disconnects or fails to teleport mid-launch | Med | Launch only to players still in the room; failed teleports retry 3 times, then return the player to the lobby with a message |
| Reserved-server payload forged or replayed | Med | Reserved server access is the gate; payload also validated with a `runId` and 10-minute freshness |
| Lobby map taste is subjective | Low | Map is two small tasks with screenshots and your review, not one big "design" task |

## Open questions

None blocking. Two things to confirm when we get there:
- T4 needs you in Creator Hub / Studio to create the test universe (I can do the code and config around it).
- T25 needs your explicit go-ahead before anything live changes.

## Task Detail

Sizes: XS 1 file, S 1-2, M 3-5. No task is larger than M. (you) = needs you in Studio, Creator Hub or an alt account.

### Phase 0

**T1 - Commit the docs.** (XS) Commit `docs/intent`, `docs/spec` and this plan folder.
- Accept: `git status` clean.
- Verify: `git log -1` shows the commit.
- Files: `docs/**`, `tasks/unfair-bossfight/**`. Deps: none.

**T2 - Move the repo to `D:/Project/UnfairBossfight` (project-layout).** (M) Close VS Code, Studio and Rojo first (you). Backup copy of the whole folder. Create `D:/Project/UnfairBossfight`, move `.git` up, `git mv` the project files into `boss/`, lift `docs/` and `tasks/unfair-bossfight/` to the new root, fix hard-coded `D:\Project\alterGoldenBossfight` paths (README, `tools/*`, `.vscode`), regenerate `sourcemap.json`, copy Claude memory files to the new project memory directory, and record the new location in memory.
- Accept: `git log --follow boss/src/...` shows history; `boss/default.project.json` builds; `check.ps1` result equals the pre-move baseline; Rojo serves boss on 34872 and Studio syncs.
- Verify: `powershell -File boss/tools/check.ps1`; `rojo build boss/default.project.json -o build/boss.rbxl`; you open the new folder in VS Code and Studio connects. (you)
- Files: README, `tools/*.ps1`, `.vscode/*`, `sourcemap.json` (many renames, few edits). Deps: T1.

**T3 - Lobby skeleton and shared config.** (M) `lobby/default.project.json` (DataModel with ReplicatedStorage, ServerScriptService, StarterGui, StarterPlayer, Workspace left alone), each folder with `init.meta.json`; `shared/UnfairShared/UnfairConfig.luau` (placeholder place IDs, `RequireLobby`, cash table, difficulty ids, party max 6, rooms 4); mount `boss/.../BossShared/Classes` in the lobby project; mount `shared/UnfairShared` in both projects; extend `tools/check.ps1` to build and analyze both projects.
- Accept: `rojo build lobby/default.project.json` succeeds; `require(ReplicatedStorage.UnfairShared.UnfairConfig)` works in both builds (analyzer clean); `ClassConfig` resolves in the lobby build; boss analyzer diff unchanged.
- Verify: `tools/check.ps1`; `rojo serve lobby/default.project.json --port 34873`.
- Files: `lobby/default.project.json`, `lobby/**/init.meta.json`, `shared/UnfairShared/UnfairConfig.luau`, `boss/default.project.json`, `tools/check.ps1`. Deps: T2.

**T4 - Test universe (you, with my config help).** (S) Create a test universe with a copy of the boss place and a copy of the lobby place (Creator Hub "new experience" plus Studio publish-as). I read both place IDs through Studio MCP (`game.PlaceId`) and note the two live IDs. The lobby place used is Talueber's Place for the live universe.
- Accept: test universe exists; teleport between its two places is allowed (same universe); you can join the test lobby from Studio with "Play here" off.
- Verify: you confirm the two test place IDs. Files: none. Deps: T3.

**T5 - Place IDs into config.** (XS) `UnfairConfig` gets `Live` and `Test` ID sets and an `Env` switch (default Test until T25).
- Accept: `UnfairConfig.LobbyPlaceId()` and `BossPlaceId()` return the right IDs for the env; analyzer clean.
- Verify: `check.ps1`. Files: `shared/UnfairShared/UnfairConfig.luau`. Deps: T4.

**Checkpoint A** (see plan).

### Phase 1

**T6 - TeleportPayload (pure).** (S) `build(partyState, runId)` and `validate(payload, opts)` implementing spec 6.1/6.2 rules 2 (shape, version, difficulty set, Enraged vs Easy, members 1-6 unique, freshness). Tests as a ModuleScript run by `execute_luau`.
- Accept: assertions for valid payload; wrong version; unknown difficulty; Enraged on Easy; 0 and 7 members; duplicate members; stale `issuedAt`; non-table input.
- Verify: tests pass via Studio MCP; `check.ps1`. Files: `shared/UnfairShared/TeleportPayload.luau`, `.../Tests/TeleportPayloadTests.luau`. Deps: T3.

**T7 - PartyState (pure).** (M) State machine for a room: `join`, `leave`, `setClass`, `setConfig(actor, difficulty, enraged)` (leader only; Enraged rejected on Easy; switching to Easy clears Enraged), leader handoff to the longest-waiting member, `lock`, `startCountdown`/`cancel`, max 6.
- Accept: assertions for join up to 6 and reject the 7th; leader leaves, next member becomes leader; empty room resets; non-leader config change rejected; locked room rejects joins and leaves-cancel behaviour; difficulty to Easy clears Enraged.
- Verify: tests via MCP; `check.ps1`. Files: `shared/UnfairShared/PartyState.luau`, `.../Tests/PartyStateTests.luau`. Deps: T3.

### Phase 2

**T11 - Lobby map shell (lobby-world).** (M) Through Studio MCP: circular plaza "Unfair Plaza", spawn ring, lighting and sky, three radial portal arches (gold live arch, dimmed chained arch for Jeff n' Fred, harbour-dock arch for TheFallenNoob's Private Island) with sign parts. All gameplay parts get a stable name and attributes (contract documented in `lobby/MAP.md`), e.g. `Workspace.Pads.AlterGolden`, `.JeffAndFred`, `.FallenNoob`.
- Accept: `lobby/MAP.md` lists every named part scripts rely on; screenshot set (`screen_capture`) from spawn and each arch; place saved to `lobby/place/Lobby.rbxl`.
- Verify: you review screenshots and walk it in Studio. (you) Files: `lobby/MAP.md`, `lobby/place/Lobby.rbxl`. Deps: T3.

**T12 - Lobby map: class hall, party rooms, shop shell.** (M) Class hall with one pedestal per entry in `ClassConfig.Order` (9) each carrying a `ProximityPrompt`; 4 party rooms in the gold wing (`Workspace.PartyRooms.Room1..4` with `Pad`, `Console`, `RosterDisplay` parts); shop building shell with a "Coming soon" sign. Update `MAP.md`.
- Accept: names match `MAP.md`; each room has the same structure; place backup saved.
- Verify: screenshots and your review. (you) Files: `lobby/MAP.md`, `lobby/place/Lobby.rbxl`. Deps: T11.

**T13 - Class picker, server (class-picker).** (M) `UnlockCheck` (badge via `BadgeService`, game pass via `MarketplaceService`, cached, tri-state true/false/nil, same semantics as `ClassService.CheckUnlock`), `ClassPickService` with `ClassPick` remote (`Select`, with arg type checks and rate limit), stores `PlayerClass` attribute, refreshes `ClassUnlocked_<id>` attributes for the UI.
- Accept: picking a missing class does nothing; picking an unowned badge or pass class returns a locked message; unverifiable returns the retry message; a valid pick sets the attribute; pick is allowed whenever the player is not locked into a launching party.
- Verify: tests via MCP for the pure parts; Studio local test with a test account that lacks a badge. Files: `shared/UnfairShared/UnlockCheck.luau`, `lobby/src/ServerScriptService/Lobby/ClassPickService.server.luau`, `lobby/src/ReplicatedStorage/Lobby/ClassPickRemote.luau`, test file. Deps: T12.

**T14 - Class picker, UI.** (M) UI built from `ClassConfig` data (names, colours, taglines, stats) with padlocks and hints from `ClassConfig`/`ClassUnlocks`; opens from a pedestal prompt; Buy button for game pass classes (mirrors the boss picker); selected class shown on HUD and floating over the player.
- Accept: all 9 classes listed (TrueWarrior shows per existing rules), padlocks match unlocks, selection round-trips to the server attribute.
- Verify: Studio screenshots and a click-through. (you) Files: `lobby/src/StarterGui/LobbyUI/ClassPicker*.luau`, `lobby/src/StarterPlayer/.../LobbyClient/ClassPickerClient.client.luau`. Deps: T13.

**T15 - Party rooms, server.** (M) `PartyService` binds `PartyState` to `Workspace.PartyRooms.Room1..4`: pad prompt join/create, leave on pad exit or disconnect, leader handoff, countdown cancel, a `PartyControl` remote (`Join`, `Leave`, `SetConfig`, `Start`) with all server-side checks, replication of room state through attributes or a `PartyUpdate` event, roster pulling each member's current `PlayerClass`.
- Accept: matches `PartyState` tests; one player can be in only one room; leader-only config enforced on the server (a hacked client can't change it); disconnect handled.
- Verify: Studio with 3 clients: join, leave, handoff. Files: `lobby/src/ServerScriptService/Lobby/PartyService.server.luau`, `lobby/src/ReplicatedStorage/Lobby/PartyRemote.luau` + tests. Deps: T7, T13.

**T16 - Party room UI.** (M) Leader panel (five difficulty buttons, Enraged toggle disabled on Easy, Start), live roster with classes (panel plus billboard over each pad), countdown display, Leave button; non-leaders see the settings read-only.
- Accept: toggle disabled on Easy and cleared when switching to Easy; non-leader controls disabled; roster updates live when a member changes class.
- Verify: Studio 2-3 clients, screenshots. (you) Files: `lobby/src/StarterGui/LobbyUI/PartyPanel*.luau`, `LobbyClient/PartyClient.client.luau`, `Lobby/RosterBillboard.luau`. Deps: T15.

**T17 - LaunchService.** (M) On countdown end: build the payload (T6) from the server's party state (classes read from server attributes, never from the client), `TeleportService:ReserveServer`, one `TeleportAsync` for all members with `SetTeleportData`; handle `TeleportInitFailed` with 3 retries then return the player to the lobby; skip players who left. In Studio (or `UnfairConfig.DryRun`) log the payload and fire a `LaunchDryRun` event instead of teleporting.
- Accept: payload printed in Studio matches room settings and classes; Easy never carries Enraged; the room is locked during launch and resets after.
- Verify: Studio dry-run with 2+ clients (Checkpoint B). Files: `lobby/src/ServerScriptService/Lobby/LaunchService.server.luau` + tests. Deps: T6, T15, T5.

**Checkpoint B.**

### Phase 3

**T8 - BossIntake (validate and apply).** (M) New `boss/src/ServerScriptService/BossSystem/Encounter/Intake.luau` plus a small bootstrap `Intake.server.luau`: apply spec 6.2 rules 1-4 (reject non-reserved joins when `RequireLobby`; validate payload with `TeleportPayload`; class existence and unlock re-check through `ClassService`; set `PlayerClass`, `SelectedDifficulty`, `EncounterEnraged`, `DifficultyLocked`; later payloads must match `runId`). Studio or `RequireLobby = false` leaves current behaviour.
- Accept: valid payload gives correct attributes for each of the 5 difficulties; forged locked class falls back to the default class with a message; Enraged on Easy rejected; no payload in Studio leaves everything as today.
- Verify: `check.ps1`; tested through T10's harness. Files: `Intake.luau`, `Intake.server.luau`, one hook in `ClassService` or `DifficultyService` if needed (max 3 files). Deps: T6.

**T9 - Hide statue, gate and picker prompts in lobby mode.** (S) With a valid payload, disable `DifficultyStatue` and `ClassStatue` prompts and the Enraged Gate; the retry hint text changes to "Return to the lobby to change difficulty" (lobby mode only).
- Accept: in lobby mode none of the three prompts can be triggered; in fallback mode all three work as before; hint text swaps correctly.
- Verify: you play the boss place in Studio in both modes and replay a fight briefly. (you) Files: `DifficultyService.luau`, `EnragedGate.luau`, `ClassService.luau`, `EncounterRetryClient.client.luau` (hooks only). Deps: T8.

**T10 - Dev-payload harness.** (S) `UnfairConfig.DevPayload` (Studio only) feeds a fake teleport payload to intake so Studio can test lobby mode; a table of cases (valid x5 difficulties, forged class, Enraged on Easy, stale, wrong member) run via `execute_luau`.
- Accept: every case gives the expected accept or reject and the expected attributes.
- Verify: MCP assertions. Files: `Intake` dev hook, `tests/IntakeCases.luau`. Deps: T8.

### Phase 4

**T18 - First published teleport test (you).** (S) Publish both projects to the **test universe**, launch two accounts: pick classes, form a party, launch, arrive in the boss place; check the attributes and that no statue or gate prompt works; try a direct join of the boss place (must bounce to the lobby).
- Accept: Checkpoint C items hold; findings written into this plan.
- Verify: you with 2 accounts (alts). Files: none (fixes become new tasks). Deps: T9, T10, T17.

**Checkpoint C.**

**T19 - Return to Lobby.** (M) Button next to Retry in `EncounterRetryClient`, server action (`ReturnToLobby` on the existing retry remote) that teleports that single player to the lobby place with a short message; works after both a win and a loss; leaves Retry unchanged.
- Accept: after a win or loss the player can choose either; Return puts them in a public lobby server; Retry still restarts in place.
- Verify: test universe, 2 accounts, one retries while the other returns. (you) Files: `EncounterRetryClient.client.luau`, `EncounterLifecycle.luau`, `UnfairConfig.luau`. Deps: T18.

**T20 - CashRules (pure).** (XS) `payout(difficulty, enraged)` from the config table; Enraged on Easy returns the Easy value.
- Accept: all 5 difficulties with and without Enraged; unknown difficulty returns 0.
- Verify: MCP assertions. Files: `shared/UnfairShared/CashRules.luau` + test. Deps: T3.

**T21 - CashService (boss).** (M) On `BossEncounterWon`, pay each participant (same rule as victory badges) via `UpdateAsync` increment on `UnfairBossfight_PlayerData_v1/user_<id>`, once per `(runId, userId)`; retry with backoff; session pending amount if all retries fail; Studio writes go to a separate test store name so nothing real is touched.
- Accept: a win pays each participant exactly once per `runId` (Retry only happens after a loss, so a run has at most one win); amounts match T20; a DataStore error is logged and retried, not thrown.
- Verify: Studio with API access enabled and test store; then the test universe. Files: `CashService.luau`, `VictoryRewards.luau` (one call), `UnfairConfig.luau`. Deps: T20, T18.

**T22 - Cash HUD (lobby).** (S) Read the balance on join and on return, show top-right; no client write path.
- Accept: HUD shows the balance after a win and a return; failure shows "--" and retries.
- Verify: test universe. (you) Files: `lobby/.../CashService.server.luau`, `LobbyUI/CashHud.luau`. Deps: T21.

**T23 - End-to-end and regression (you).** (S) Test universe: solo and 6-player (alts plus any friends) win on a hard mode with Enraged: cash doubles, shown in lobby; solo True Hardcore win still awards the solo badge path (use the dev badge check or the logs); a 2-player win does not; Retry in place keeps settings.
- Accept: Checkpoint D items hold. Files: none. Deps: T19, T22.

**Checkpoint D.**

### Phase 5

**T24 - Coming-soon panels and polish.** (S) Info panel for Jeff n' Fred and TheFallenNoob's Private Island, shop shell panel ("Coming soon"), audio, signage; no teleport path exists for these pads.
- Accept: stepping on either coming-soon pad shows its panel and never calls `TeleportService`.
- Verify: Studio walkthrough. (you) Files: `LobbyUI/ComingSoon*.luau`, `LobbyClient/PadInfoClient.client.luau`. Deps: T12.

**T25 - Cut-over (you, explicit go-ahead required).** (M) Backups of both live places first. Publish the lobby build into Talueber's Place in the live universe and the boss build into The Golden Encounter, switch `UnfairConfig.Env` to Live and `RequireLobby = true`, set the lobby as the universe start place in Creator Hub, rename the experience to "Unfair Bossfight", remove the old server lock setting.
- Accept: joining the experience lands in the lobby; the boss place direct link bounces back to the lobby; a live party run works.
- Verify: you with 2 accounts. Rollback: restore the previous start place and published versions. Files: `UnfairConfig.luau`. Deps: T23, T24.

**Checkpoint E.**

**T26 - Docs and memory.** (XS) README layout, ports (34872 boss, 34873 lobby), "how to add the next pad" notes; update the Claude memory notes.
- Accept: README matches the folder layout. Files: README, memory files. Deps: T25.

## Not in this plan

- The shop and powerups (`shop`): its own spec and plan after cut-over.
- Jeff n' Fred and TheFallenNoob's Private Island bosses.
