# Unfair Bossfight

One Roblox experience made of several places, grouped in this repo.

```
boss/     The Golden Encounter (alterGolden's Bossfight). Rojo project: boss/default.project.json
lobby/    Unfair Bossfight lobby: class picker, party pads, cash HUD, coming-soon panels. Rojo project: lobby/default.project.json
shared/   Code mounted into both places as ReplicatedStorage.UnfairShared (config, teleport payload, party rules, cash rules)
docs/     intent/ (what we want), spec/ (how it should work), cutover.md (going live)
tasks/    unfair-bossfight/ plan.md, todo.md and user-tests.md (boss/tasks holds the earlier code-cleanup record)
tools/    check-all.ps1, the gate for both projects
```

Open `UnfairBossfight.code-workspace` in VS Code to get all four folders with the right Luau settings.

## How a run works

1. A player joins the **lobby** (public servers), picks a class in the class hall and steps on a party-room pad.
2. The first player on a pad is the leader: they pick the difficulty and Enraged. Up to 6 players join the room. **Start** runs a
   5 second countdown, then the lobby reserves a private boss server and teleports the whole party with one `TeleportAsync`.
   The teleport carries a versioned payload (`shared/UnfairShared/TeleportPayload.luau`).
3. The **boss place** (`boss/.../Encounter/Intake.luau`) validates the payload, sets class, difficulty and Enraged, and hides the
   difficulty statue, class statue and Enraged gate. Anyone who did not come through the lobby is sent back to it.
4. When the boss falls, `CashService` pays each winner once (`CashRules` x `CashLedger`, DataStore
   `UnfairBossfight_PlayerData_v1`, key `user_<id>`). After a win or a loss the player can **Retry** (same server, same settings) or
   **Return to Lobby** (that one player, to a public lobby server). The lobby shows the cash top-right.

## Rojo ports

| Project | Command | Port |
|---|---|---|
| boss | `rojo serve boss/default.project.json --port 34872` | 34872 |
| lobby | `rojo serve lobby/default.project.json --port 34873` | 34873 |

Connect each Studio window to **its own** port only. If Studio stops receiving changes, check that the matching `rojo` process is
still running. Never connect a Studio window that holds the live game to a Rojo server while a test is going on.

## Places

| | Live universe | Test universe ("Unfair Bossfight TEST") |
|---|---|---|
| Lobby | 92877530696258 | 83310105029258 |
| Boss | 123789153131367 | 76581021814220 |

`shared/UnfairShared/UnfairConfig.luau` holds both sets. `Env = "Test"` while building; `Env = "Live"` and `RequireLobby = true`
come with the cut-over (see [docs/cutover.md](docs/cutover.md)). The test universe already enforces the lobby
(`RequireLobbyTest = true`), so "direct join bounces back" can be tried there.

## Checks

`powershell -ExecutionPolicy Bypass -File tools/check-all.ps1` builds both Rojo projects and runs the Luau analyzer: the boss
against its baseline (no new diagnostics), the lobby and `shared/` with zero tolerated. `-SkipBoss` checks only lobby and shared.
`boss/tools/check.ps1` is the boss-only gate; see [boss/README.md](boss/README.md) for how the boss place's files are laid out.

The pure rule modules in `shared/UnfairShared/` have test files in `shared/UnfairShared/Tests/` (run with the `Harness`; there is
no local Luau runner, so they are run in Studio through `execute_luau`).

## Studio testing tips

- Lobby in Studio never teleports: **Start** prints the payload and sets `workspace.LastLaunchPayload` (dry run).
- Boss in Studio can pretend to arrive from the lobby: set `UnfairConfig.DevPayload = { difficulty = "Hardcore", enraged = true, class = "Mage" }`
  (Studio only). Leave it `nil` for normal play.
- Class locks are bypassed for the creator in Studio; set `workspace` attribute `ForceClassLocks` to `true` to test the lock.
- Cash in Studio uses the data store `UnfairBossfight_PlayerData_v1_Studio` and needs **Game Settings > Security > Enable Studio
  Access to API Services** on. Without it the lobby HUD shows `--` and the boss place logs the failed write and retries.
- The lobby needs `Workspace.StreamingEnabled = false` (set in the place, not in Rojo): see [lobby/MAP.md](lobby/MAP.md).

## Adding the next pad (a new boss)

The lobby already has arches for Jeff n' Fred and TheFallenNoob's Private Island: both are `Status = "ComingSoon"` and only show a
panel (`lobby/.../PadInfoClient.client.luau`, text in `lobby/.../PadInfo.luau`). To open one:

1. Create the boss place in the same universe and put its id into `UnfairConfig.Places` (Live and Test).
2. Build its party rooms like `Workspace.PartyRooms` (see `lobby/MAP.md`) and flip the arch's `Status` attribute to `Live`.
3. `LaunchService` currently launches `Config.BossPlaceId()` for every room. Give each room a `Boss` attribute, map it to a place id
   in the config, and have `LaunchService` read it. This part is not built yet because only one boss exists.
4. In the new boss place mount `shared/UnfairShared` and call something like `Intake` on arrival so only lobby parties get in.
5. Remove the arch from `PadInfo` (it no longer needs a panel) and add its cash row to `CashByDifficulty` if it pays differently.

Plan: [tasks/unfair-bossfight/plan.md](tasks/unfair-bossfight/plan.md). Spec: [docs/spec/unfair-bossfight.md](docs/spec/unfair-bossfight.md).
What is left for a person to test: [tasks/unfair-bossfight/user-tests.md](tasks/unfair-bossfight/user-tests.md).
