# Side places and the Reality Orb quest

Two small places in the live universe (10768840017), next to the lobby and the Golden Encounter. Each has its own folder and Rojo
project; both mount `shared/UnfairShared` as `ReplicatedStorage.UnfairShared`.

| Place | Id | Folder | Server size | How you get there |
|---|---|---|---|---|
| Tutorial Place (Azusa's training grounds) | 105069596660916 | `tutorial/` | 1 | Lobby: hold E at Azusa (beside the spawn path) → "Please teach me how to fight" |
| !A GL!TC3D PL@CE! | 120825718922899 | `glitched/` | default | Lobby: walk into the black-and-white portal in the Divided Wood (by the way back, west of the path) |

Ids live in `UnfairConfig.SidePlaces`; the lobby's `SidePlaceService` does the teleports (never in Studio: it says what it would do).

## Azusa's training grounds (`tutorial/`)

- `map/init.luau` builds floating islands at dusk from the Blender kit **Blossom** (`tutorial/blender/blossom.py`, asset 80713024384595):
  the `ShrineArena` (radius 74, the fight; `World.ArenaCenter`), the `SpawnIsle` and red `ArchBridge` to the south, the `GreatSakura`
  on its own rock behind the arena, a `Pagoda`, drifting `SkyRock`s, plus torii and lanterns from the older Dojo kit. `World.Fence`
  is a ring of invisible walls; its `Gate` piece (over the bridge) closes while the fight is on. Her sword and attack shapes come from
  the kit **AzusaFX** (asset 121606459275439) and are stored in `ReplicatedStorage.AzusaFX`.
- Azusa is a real boss built on **BossKit** (`docs/boss-kit.md`): you are a Warrior with the Golden Encounter's kit, 3 lives, HP and
  stamina; she has 9000 HP, an HP bar, and a 1600 shield in phase 2. `Tutorial/Azusa.luau` is her body (mymeo125's avatar, the katana
  with a blade trail, afterimages, and ten generated animations: combat idle, quick-draw, overhead slash, plunge, dancer's throw,
  dash-cut, summon, stagger, point, kneel), `Tutorial/AzusaAttacks.luau` her skills, `TutorialService` the fight.
- Her skills: Blossom Mines (step out), Moonlit Crescent (dash through), Flash Draw (deflect: she staggers, "OPEN", takes 50% more),
  Thorn Waltz (jump), Petal Storm (strafe or guard); below 50%: Hundred Steps (deflect each cut) and Petal Requiem (a giant spirit
  blade, chasing pillars, then a ring wave to dash). Each is layered: Neon core + ForceField aura shapes, petals, smoke, lights, camera
  shake, and an inverted impact frame on the big cuts. She explains each one the first time, out loud, through the boss dialogue
  (`BossKit.Say`), then just calls its name.
- Every telegraph flashes: shapes are tagged `AzusaFlash` with `FlashFrom` / `FlashTo` (server time) and `TutorialClient` blinks them
  from 3 to 16 times a second until they land; sigils are tagged `AzusaSpin` and turn.
- No "E: Talk" prompt during the fight (E is deflect); a life lost mid-fight puts you back in the arena.
- Lose your lives and she starts over; beat her and you are "TutorialDone" (the lobby then shows "You're ready").

## The Reality Orb quest

1. **Golden Encounter** (`Encounter/RealityOrb.luau`): every server hides the orb at a random spot in the dunes outside the castle,
   on the Blender `OrbShrine`, with a thin flickering pink thread of light rising from it. The gate court's invisible fence was archived
   (`ServerStorage.ArenaOldScenery.ExteriorBoundary`), so players can walk out of the west gate. Hold E to take it: one per player,
   saved as `Items.RealityOrb` in the player's record (`UnfairShared/RecordStore`, same DataStore and key as cash).
2. **Inventory**: the bag icon on the left edge of every place (`UnfairShared/InventoryUI`, key B) lists what you carry, from the
   `Inventory` player attribute that each place's server publishes.
3. **Glitched place** (`glitched/`; the world is the Blender kit **Void**, `glitched/blender/void.py`, asset 110711929130764: a road of
   broken slabs, a sliced city, a shattered clock, upside-down trees, stairs and doors to nowhere, the cracked dais and its turning
   halo): walk the broken road to the man on the bench. Without the orb he asks for it; with it, "Give him the
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
