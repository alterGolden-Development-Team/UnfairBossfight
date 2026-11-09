# Spec: Unfair Bossfight (lobby + private boss place)

Source: [docs/intent/unfair-bossfight.md](../intent/unfair-bossfight.md) (confirmed by the user).
Status: APPROVED by the user on 2026-11-09. Nothing here has been built. Plan: [tasks/unfair-bossfight/plan.md](../../tasks/unfair-bossfight/plan.md).

## 0. Capability map

This request bundles several independently testable capabilities, so they are listed as modules with stable ids. This one spec covers modules 1-8 (milestones 1 and 2) in detail and gives module 9 (shop) only a stub, because the intent says the shop is designed separately.

| Module id | Responsibility | Depends on | Milestone |
|---|---|---|---|
| `project-layout` | `D:/UnfairBossfight` folder, two Rojo projects, shared mounts, tooling | none | 1 |
| `teleport-contract` | The payload the lobby sends and the boss place validates | project-layout | 1 |
| `lobby-world` | Lobby map, spawn, 3 pads, shop placeholder | project-layout | 1 |
| `class-picker` | Class choice in the lobby (UI plus server check) | lobby-world | 1 |
| `party-pads` | Pad rooms, party of up to 6, leader, difficulty and Enraged config, launch | class-picker, teleport-contract | 1 |
| `boss-intake` | Boss place validates teleport data, sets class, difficulty, enraged; hides statue and gate | teleport-contract | 1 |
| `run-end-flow` | Retry or Return to Lobby after a win or a loss | boss-intake, lobby-world | 2 |
| `cash` | Cash earned on a win, saved in a shared DataStore, shown in the lobby HUD | boss-intake | 2 |
| `shop` | Lobby shop for powerups and classes (stub only here) | cash, class-picker | 3 |

Build order: `project-layout` -> `teleport-contract` -> `lobby-world` -> `class-picker` -> `party-pads` and `boss-intake` (parallel once the contract exists) -> `run-end-flow` -> `cash` -> `shop`.

## 1. Objective

Players join **Unfair Bossfight** (a lobby place). From there they use one of three pads:

| Pad | State |
|---|---|
| alterGolden (The Golden Encounter) | Live |
| Jeff n' Fred Bizzare Brother | "Coming soon", no teleport |
| TheFallenNoob's Private Island | "Coming soon", no teleport |

The boss place is only reachable through a reserved (private) server created by the lobby, so the Roblox server lock is no longer needed. Parties are 1-6 players with a leader. Class is chosen in the lobby. The leader chooses difficulty and Enraged.

Users: Roblox players (solo or party). Author: the sole developer, who play-tests in Studio.

## 2. Assumptions (correct me now or I proceed with these)

1. **Places.** The screenshot shows two places in the universe: "The Golden Encounter" (start place, star) and "Talueber's Place: 11092026_1" (looks like an empty place made for this). I assume Talueber's Place becomes the lobby (renamed "Unfair Bossfight Lobby") and The Golden Encounter becomes the boss place. The lobby must become the universe **start place**, otherwise players can still join the boss place directly. That is a Creator Hub setting I cannot change from code.
2. **Same universe.** Both places share one universe, so one DataStore is readable from both and `TeleportService` works between them.
3. **One lobby party room = one reserved server.** Each launched party gets its own `ReserveServer` code. Retry happens inside that same reserved server (current behaviour).
4. **Difficulty is fixed per run.** Retry keeps the same difficulty and Enraged setting. Changing them means Return to Lobby. The "Change difficulty at the statue" hint is replaced in lobby mode.
5. **Teleports do not work in Studio.** `TeleportAsync` only works in a published game. End-to-end teleport testing therefore needs published places. I propose a **separate test universe** (copies of both places) before the live game is touched. Local Studio tests cover everything except the actual teleport hop.
6. **Rojo manages scripts only.** As today, `ignoreUnknownInstances` is set everywhere. The lobby map is built in Studio through the Roblox Studio MCP and lives in the place file, backed up to `lobby/place/`.
7. **Cash values.** The intent gives Easy about 5 and Hellaven about 50. Proposed table (see Open Questions): Easy 5, NerfedHardcore 15, Hardcore 25, TrueHardcore 35, Hellaven 50. Enraged doubles it. Easy cannot be Enraged.
8. **Existing in-boss picker, statue and Enraged Gate stay for fallback.** They are hidden when valid teleport data was received, and active in Studio or `RequireLobby = false` mode.

## 3. Tech stack

- Roblox Luau (strict where the repo already is), Rojo 7 (`~/.local/bin/rojo`), `luau-lsp` (via `tools/check.ps1`), VS Code.
- Roblox services: `TeleportService` (`ReserveServer`, `TeleportAsync`, `TeleportOptions:SetTeleportData`, `GetJoinData`), `DataStoreService`, `BadgeService`, `MarketplaceService`, `MessagingService` not needed.
- Roblox Studio MCP: `execute_luau`, `generate_scene`, `insert_asset`, `screen_capture`, `get_console_output`, `start_stop_play` for building and smoke-testing the lobby.

## 4. Commands

```
Check (boss, existing gate):   powershell -ExecutionPolicy Bypass -File tools/check.ps1
Check (both projects):         powershell -ExecutionPolicy Bypass -File tools/check.ps1     # extended to build lobby too (task in plan)
Build boss place:              rojo build boss/default.project.json -o build/boss.rbxl
Build lobby place:             rojo build lobby/default.project.json -o build/lobby.rbxl
Serve boss to Studio:          rojo serve boss/default.project.json --port 34872
Serve lobby to Studio:         rojo serve lobby/default.project.json --port 34873
Sync mirror copies (boss):     powershell -File tools/check.ps1 -SyncMirrors
```

Paths assume the new layout in section 5. Until the move, boss commands run from the current repo root.

## 5. Project structure

Target: one git repo rooted at `D:/UnfairBossfight`, with the current repo's history preserved (`.git` moved up one level, existing files `git mv`-ed into `boss/`).

```
D:/UnfairBossfight/
  boss/                    the current alterGoldenBossfight project, moved as-is
    default.project.json   unchanged tree, paths still relative to boss/
    src/ place/ tools/ tasks/ _backup/
  lobby/
    default.project.json   DataModel for the lobby place
    src/
      ReplicatedStorage/Lobby/        client+server shared lobby modules
      ServerScriptService/Lobby/      PartyService, PadService, ClassPickService, LaunchService
      StarterGui/LobbyUI/             class picker, party panel, cash HUD
      StarterPlayer/StarterPlayerScripts/LobbyClient/
    place/                 backup .rbxl of the lobby map
  shared/
    UnfairShared/          UnfairConfig (place ids, RequireLobby, cash table), TeleportPayload, DifficultyIds
  docs/ intent/ spec/
  tasks/                   unfair-bossfight plan and todo (the boss refactor records stay in boss/tasks)
  README.md                updated layout and the "which port is which" notes
```

Sharing rules:
- `shared/UnfairShared` is mounted into `ReplicatedStorage.UnfairShared` by **both** projects.
- `ClassConfig` and `ClassUnlocks` stay where they are (`boss/src/ReplicatedStorage/BossShared/Classes`) and the lobby project **mounts that folder** at `ReplicatedStorage.BossShared.Classes`. One source of truth, no copies, so the lobby picker and the boss place can never disagree. If a require inside those files needs siblings that do not exist in the lobby, the plan task moves just that dependency into `shared/`.
- Every new folder under `src/` gets an `init.meta.json` with `{"ignoreUnknownInstances": true}` (this once wiped `Templates`; see `project-refactor-tooling` memory).
- Moving the repo changes Claude's per-project memory path (`d--Project-alterGoldenBossfight`). The memory files are copied across as part of `project-layout`.

## 6. Contracts

### 6.1 Teleport payload (`TeleportPayload`, version 1)

Sent by the lobby server in `TeleportOptions:SetTeleportData`, per teleport call (one party, up to 6 players, one `TeleportAsync` with a list of players so they land in the same reserved server).

```lua
type Payload = {
  v: number,                    -- 1
  runId: string,                -- GUID, one per launch (idempotency for cash)
  partyId: string,
  leaderUserId: number,
  difficulty: "Hellaven" | "TrueHardcore" | "Hardcore" | "NerfedHardcore" | "Easy",
  enraged: boolean,             -- never true when difficulty == "Easy"
  members: { { userId: number, class: string } },   -- 1..6 entries
  issuedAt: number,             -- os.time()
}
```

Reserved-server access, not the payload, is the real gate: only players holding the access code can enter. The payload is still **validated on arrival** (6.2) because the lobby result can't be trusted alone.

### 6.2 Boss-place intake rules (server)

On `PlayerAdded`, read `player:GetJoinData().TeleportData`:

1. Not in a reserved server (`game.PrivateServerId == ""`) and not Studio, and `RequireLobby` is on -> send the player back to the lobby with a message. This replaces the old server lock.
2. Payload must pass shape and version checks; `difficulty` must be a key of `DifficultyConfig.Profiles`; `enraged` only if difficulty is not Easy; `members` size 1-6 and unique; the arriving player must be in `members`; `issuedAt` not older than 10 minutes.
3. The class must exist in `ClassConfig.Classes`, and if it has an unlock entry, `ClassService.CheckUnlock` must return true. If the check returns `nil` (cannot verify), the player gets the default class and a message. If `false`, the same, never the locked class.
4. First valid payload sets `workspace:SetAttribute("SelectedDifficulty", ...)` and `EncounterEnraged`, and locks difficulty (existing `DifficultyLocked`). Later payloads in the same server must match the first (same `runId`), otherwise rejected.
5. Valid arrival hides `DifficultyStatue`, `ClassStatue` prompt and the Enraged Gate prompt. Missing or invalid data in Studio falls back to today's behaviour.

### 6.3 Cash

- DataStore `UnfairBossfight_PlayerData_v1`, key `user_<userId>`, field `Cash` (integer).
- Written only by the **boss place server** on a win (`BossEncounterWon`), via `UpdateAsync` increment, once per `(runId, userId)` (a `lastRunId` field guards double-award on retry wins).
- Lobby reads it for the HUD. The shop (milestone 3) spends with `UpdateAsync` and a balance check, never `SetAsync`.
- Payout = `CashTable[difficulty] * (enraged and 2 or 1)`. Participants who were alive or spectating when the win happened are paid, matching the existing victory-badge participant rule. DataStore failure: retry with backoff, then log and keep the pending amount for the session so the player is not silently robbed.

### 6.4 Run end

After a win or loss the existing panel offers **Retry** (same reserved server, same settings) and a new **Return to Lobby** button. Return teleports that player alone to the lobby place (public). Leader privileges end with the run.

### 6.5 Solo badges

`VictoryRewards.participantCount() == 1` already defines "solo" from who was in the server. A 1-player party therefore keeps TrueWarrior and Champion detectable unchanged. Tested explicitly (see 8).

## 7. Lobby design (summary; detailed in a design task)

- **Layout (proposal, I design it):** a circular hub, "Unfair Plaza". Central spawn ring. Three radial wings, each with a large portal arch: gold wing (alterGolden, live), a dimmed chained arch for Jeff n' Fred ("Coming soon"), a harbour-dock arch for TheFallenNoob's Private Island ("Coming soon"). A **class hall** with one pedestal per class (stats from `ClassConfig`, padlocks from `ClassUnlocks`). A **shop building** shell with a "Coming soon" sign. Cash HUD top-right.
- **alterGolden party rooms:** 4 pad rooms per lobby server (up to 24 queued players). A room holds one party of up to 6.
- **Party flow:** step on the pad or use its prompt -> become leader of an empty room, or join an open room. The leader's panel: difficulty selector (5 modes), Enraged toggle (disabled on Easy), Start. Members see the live roster with each person's class (billboard over the pad plus the panel). Start runs a 5 s countdown, then reserve and teleport. Leader leaves -> leadership passes to the longest-waiting member. Leaving the pad cancels a countdown. Room locks while teleporting.
- **Coming-soon pads:** do nothing except show an info panel. No teleport code path exists for them.
- **Class picker:** server validates class exists and unlock status on every pick; the pick is stored as a player attribute in the lobby and copied into the payload by the server, never taken from the client at launch time.

## 8. Testing strategy

There are no automated tests in the repo today; verification is `check.ps1` plus the user playing in Studio. This spec keeps that gate and adds:

| Level | What | How |
|---|---|---|
| Static | Both projects build; analyzer diff clean | `tools/check.ps1` (extended) |
| Pure logic | `TeleportPayload.validate`, party state machine (join, leave, leader handoff, lock), cash payout table | Roblox-free modules, run through `mcp__Roblox_Studio__execute_luau` assertions or a `luau` CLI script if one is installed |
| Studio local | Lobby: 2-4 clients (Test > Start with multiple players) for party flow, class pick, config panel | Studio, driven or watched through the MCP (`screen_capture`, `get_console_output`) |
| Boss fallback | Boss place with no teleport data in Studio still plays as today | Studio |
| Published | Real teleport, reserved server, payload arrival, Return to Lobby, cash write | **Test universe**, then 2+ accounts (user's alt accounts) |
| Regression | Solo badge detection with a 1-player party; retry in place; classes locked once `EncounterStarted` | Published test universe plus code inspection |

Each plan task states its own verify step; no task is "done" on a green build alone when it changes gameplay (the user confirms in Studio, as in the refactor).

## 9. Code style

Match the repo: tabs or two-space as the surrounding file, `local x = require(...)` at the top, `table.freeze` for config, `type(a) ~= "string"` guards on every remote argument, one `RemoteEvent` per feature with an `action` string. Example of the intake gate style:

```lua
local function validate(payload, player)
	if type(payload) ~= "table" or payload.v ~= 1 then return nil, "bad payload" end
	if not DifficultyConfig.Profiles[payload.difficulty] then return nil, "bad difficulty" end
	if payload.enraged == true and payload.difficulty == "Easy" then return nil, "enraged not allowed on Easy" end
	-- ...membership, class existence, unlock re-check
	return payload
end
```

## 10. Boundaries

**Always**
- Validate every remote argument and every teleport payload on the server; re-check unlocks in the boss place.
- Run `tools/check.ps1` before each commit; one task per commit.
- Add `init.meta.json` with `ignoreUnknownInstances` to every new `src/` folder.
- Keep a backup `.rbxl` of each place before a risky Studio change.
- Check the Rojo server is running (and which port) before comparing Studio to the files.

**Ask first**
- Changing the universe's start place, renaming the game, or publishing any place (live game impact).
- Making a test universe, adding DataStores, adding any dependency or plugin.
- Moving the git root (the `project-layout` move), because it changes every path and Claude's memory directory.
- Deleting the in-boss statue, gate or picker instead of hiding them.

**Never**
- Trust `TeleportData` or any client value without validation.
- Teleport from the client, or give clients a cash write.
- Publish over the live place without the user's explicit go-ahead.
- Remove or weaken existing victory or badge logic to make the lobby fit.
- Commit tokens, API keys or cookies.

## 11. Success criteria

1. Joining the game opens the lobby; the boss place cannot be entered from the website or by link (start place changed, plus intake rule 1).
2. A solo player picks a class, steps onto an alterGolden room, chooses a difficulty, and lands in a private boss server with that class and difficulty, with no statue or gate interaction.
3. A party of 6 with a leader does the same; non-leaders cannot change settings; leader handoff works when the leader leaves.
4. Enraged is toggleable on all modes except Easy and arrives as `EncounterEnraged = true`.
5. A forged or locked class in the payload is rejected in the boss place (player gets the default class, never the locked one).
6. The two "coming soon" pads show their panel and never teleport.
7. After a win or loss, Retry restarts in place and Return to Lobby puts the player in a public lobby server.
8. A solo win on True Hardcore or Hellaven still awards the solo badge; a 2-player win does not.
9. A win credits cash once per run per player (Easy 5 ... Hellaven 50, doubled when Enraged), visible in the lobby HUD after return.
10. `tools/check.ps1` passes for both projects; in Studio with no teleport data the boss place still plays exactly as today.

## 12. Open questions (all answered by the user on 2026-11-09)

Answers: 1 yes, Talueber's Place is the empty lobby place. 2 yes, create a test universe. 3 yes, cash table is fine. 4 yes, Return to Lobby is the only way to change difficulty. 5 yes, move the git root and `git mv` into `boss/`. 6 fine, 4 rooms.

1. Which place becomes the lobby: is "Talueber's Place: 11092026_1" the empty place you made for it? And what are the two place IDs (I can read them from Studio)?
2. OK to create a **separate test universe** for teleport testing before the live game changes? Without it, any teleport test touches the live game.
3. Cash values for the middle modes (proposed NerfedHardcore 15, Hardcore 25, TrueHardcore 35) fine?
4. After a loss, should the party be able to change difficulty without leaving the server, or is Return to Lobby the only way (my assumption)?
5. Git move: OK to make `D:/UnfairBossfight` the git root and `git mv` the current project into `boss/` (history kept)? The alternative is leaving the repo where it is and adding `lobby/` as a sibling folder in a new, second repo.
6. Is the 4-rooms-per-lobby-server count fine, or do you want a different number?
