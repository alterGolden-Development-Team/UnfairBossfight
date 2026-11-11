# Side places and the Reality Orb quest

Two small places in the live universe (10768840017), next to the lobby and the Golden Encounter. Each has its own folder and Rojo
project; both mount `shared/UnfairShared` as `ReplicatedStorage.UnfairShared`.

| Place | Id | Folder | Server size | How you get there |
|---|---|---|---|---|
| Tutorial Place (Azusa's training grounds) | 105069596660916 | `tutorial/` | 1 | Lobby: hold E at Azusa (beside the spawn path) → "Please teach me how to fight" |
| !A GL!TC3D PL@CE! | 120825718922899 | `glitched/` | default | Lobby: walk into the black-and-white portal in the Divided Wood (by the way back, west of the path) |

Ids live in `UnfairConfig.SidePlaces`; the lobby's `SidePlaceService` does the teleports (never in Studio: it says what it would do).

## Azusa's training grounds (`tutorial/`)

- `map/init.luau` builds the floating island at dusk (Dojo kit from `lobby/blender/realm.py`: arena, torii, lanterns, posts, sakura).
- `TutorialService` builds Azusa from the mymeo125 avatar and runs seven lessons, each a small version of an alterGolden attack:
  circles (step out), the golden wave (dash through with Q), the heavy strike (guard with R), ground rings (jump), bullet fans (strafe),
  punish (click her while she is open), and an exam. Being hurt never kills you: the lesson repeats.
- `TutorialClient` has the lesson banner, her voice, and the three tutorial-only controls (Q dash, hold R guard, click).
- When the lessons are done she offers the way back; the lobby then shows "You're ready" (teleport data `{ from = "Tutorial", done = true }`).

## The Reality Orb quest

1. **Golden Encounter** (`Encounter/RealityOrb.luau`): every server hides the orb at a random spot in the dunes outside the castle,
   on the Blender `OrbShrine`, with a thin flickering pink thread of light rising from it. The gate court's invisible fence was archived
   (`ServerStorage.ArenaOldScenery.ExteriorBoundary`), so players can walk out of the west gate. Hold E to take it: one per player,
   saved as `Items.RealityOrb` in the player's record (`UnfairShared/RecordStore`, same DataStore and key as cash).
2. **Inventory**: the bag icon on the left edge of every place (`UnfairShared/InventoryUI`, key B) lists what you carry, from the
   `Inventory` player attribute that each place's server publishes.
3. **Glitched place** (`glitched/`): walk the broken road to the man on the bench. Without the orb he asks for it; with it, "Give him the
   Reality Orb" takes the orb and grants the class in one save (`RecordStore.TradeItemForClass`), plays the cutscene (he rises, tears the
   sky open, the tear pulls you in, "Thank you...") and returns you to the lobby, where a toast says the class is yours.
4. **Unlock rule**: `ClassUnlocks.Disorderer` is `Kind = "GamePass", Quest = true`: owned by game pass (25 Robux) **or** by the record
   listing it (`UnlockCheck` in the lobby, `ClassService.ownsEntry` in the boss place).

## Building and syncing

```
powershell -File tools\sync-place.ps1 -Place glitched     # or tutorial
```
then paste `tools/sync-place.luau` (set `PLACE`) in that place's Studio window, and run
`require(game.ServerStorage.MapBuilder).Build()` there to rebuild its world. `tools/check-all.ps1` builds and analyses both places.
Publishing each place is done from its own Studio window ("Publish to Roblox"); the glitched window was opened from the user's
"11102026_2" file and the tutorial was built in a blank "Place1" window, so save each to its place id when publishing.
Studio has no DataStore access unless "Enable Studio Access to API Services" is on: the orb pickup and the hand-over then say they could
not save (the glitched cutscene still plays in Studio so it can be seen).
