# Cut-over to the live universe (plan task 25)

**Nothing in here has been done.** This is the runbook. It starts only after you say go, and only after Checkpoint C and D
(real teleport, cash, Return to Lobby) passed in the test universe. Live universe 10768840017: the lobby is "Place1" /
Talueber's Place (92877530696258, empty today) and the boss is The Golden Encounter (123789153131367).

## The order matters

The boss place must not start bouncing players to the lobby before the lobby exists and is the way in. So:

| # | Step | Who | Effect on live players |
|---|---|---|---|
| 1 | Backups (below) | you | none |
| 2 | Publish the lobby build to the live lobby place (Env = Live) | you, after my 2-line change | none: nobody can reach it yet |
| 3 | Open the lobby place's link yourself and walk through it | you | none |
| 4 | Publish the boss build (Env = Live, `RequireLobby = true`) | you | direct joins of the boss place now bounce to the lobby |
| 5 | Creator Hub: set the lobby as the **start place** | you | new players now land in the lobby |
| 6 | Rename the experience to "Unfair Bossfight" | you | none |
| 7 | Run the 2-account check (below) | you + alt | none |
| 8 | Remove the old server lock setting on the boss place | you, last | boss place is now guarded only by the lobby |

## 1. Backups

- Creator Hub > each live place > Version History: write down the current published version number of **both** places here:
  lobby `____`, boss `____`.
- In Studio, open each live place and File > Save to File As: `lobby/place/Lobby.rbxl`, `boss/place/TheGoldenEncounter.rbxl`
  (the boss file already exists in the repo; replace it with the current live version).
- Note the current start place and the server lock setting.

## 2. The code change (mine, only on your go-ahead)

`shared/UnfairShared/UnfairConfig.luau`:

```lua
Config.Env = "Live"        -- was "Test"
Config.RequireLobby = true -- was false
```

Then run `tools/check-all.ps1` and commit. Publish **both** places from builds with these values (the boss place reads them to
decide where "back to the lobby" goes and whether to bounce direct joins). After this, builds meant for the test universe need
`Env = "Test"` again, so switch it back on a branch (or before the next test round) and never publish a Test build to a live place.

## 3. Lobby place settings to check before publishing

- `Workspace.StreamingEnabled` is off.
- Teleports between the two places need no setting (same universe). DataStores always work in published servers; the
  "Enable Studio Access to API Services" switch only matters for Studio sessions.
- `UnfairConfig.DryRun` is `false`.
- `UnfairConfig.DevPayload` is `nil`.

## 7. The 2-account check

1. Alt joins the experience link: lands in the lobby (not the boss place).
2. Both pick a class, form a party, Hardcore + Enraged, Start: both arrive in one private boss server with the right class.
3. Open `https://www.roblox.com/games/123789153131367` directly: bounces to the lobby.
4. Win (or die and use Return to Lobby): cash appears in the lobby HUD, once.

## Rollback

Any step: Creator Hub > start place > set it back to The Golden Encounter; publish the previous boss version from Version History
(step 1 numbers) or restore `boss/place/TheGoldenEncounter.rbxl`; set `RequireLobby = false` and republish if the boss place was
already updated. Cash already written stays in the data store and is harmless.
