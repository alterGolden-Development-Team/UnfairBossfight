# Lobby map contract

The lobby world is built by the modules in `lobby/map/` into `Workspace.World` and saved in the place file (Rojo does not sync Workspace).
Rebuild an area from Studio, **test place only**: `require(game.ServerStorage.MapBuilder).Build("Palace")`.
Design notes and sources: [docs/spec/lobby-redesign.md](../docs/spec/lobby-redesign.md). Scripts rely on the names below.

## Store assets

Some props are Creator Store models: the plaza fountain, the gothic greatswords (Jeff n' Fred's portal, gilded on the shop roof),
the hub island's earth and grass meshes, its trees and rocks, the small islands around the hub, and the palms. Builders clone them from
`ServerStorage.MapAssets` (saved in the place), never from the web. `lobby/map/Assets.luau` lists every id with its creator and
rebuilds that folder: `require(game.ServerStorage.MapBuilder.Assets).Fetch()` (test place only). Fetch strips every script, spawn,
prompt and tool from what it downloads: free models are props, never code. Check a new model for scripts before adding it; several
"portal" uploads on the store hide malware-style scripts.

## Blender meshes

The portals, the palace, the island's lighthouse/ferries/pier/huts/arches/cliffs and the forest's trees/gates/lanterns/pillars are our
own meshes, modelled in Blender by the scripts in `lobby/blender/` (`kit.py` holds the helpers; one script per kit). Running a script
in Blender (through the Blender MCP: `exec(open(path).read())`) rebuilds its collections; `export_kit(...)` writes
`lobby/blender/export/<Kit>.glb`, which is uploaded as a Model asset and listed in `Assets.Kits`. `Assets.Fetch("<Kit>")` splits the
kit into its pieces in `ServerStorage.MapAssets`:

- MeshParts are named `<Piece>__<Role>_<S?><n>`. The role picks the Roblox material and colour (`Assets.Skin`); `S` means players
  stand on it (collision on, precise convex decomposition), otherwise collision and queries are off.
- `<Piece>__Pivot` marks the piece's Blender origin and becomes its pivot. 1 Blender unit = 1 stud; Blender -Y (the front) is the
  piece's -Z, so `CFrame.lookAt(pos, target)` turns a piece's front toward `target`.
- To change a mesh: edit the script, rebuild and export in Blender, upload the GLB (a new asset id), update `Assets.Kits`, then
  `Fetch("<Kit>")` and rebuild the area.

Gates (`map/Gates.luau`): every portal is a Blender gate whose glowing face is the MeshPart named `Glow` (tinted by
`Gates.glow`); `Gates.returnGate` is the winged "Back to the Sanctum" arch used in every area. The golden gate's leaves are Models
tagged `UnfairDoor` (attributes `Swing`, `OpenAngle`, `Range`) that `AreaClient` swings open as you come near.

The brothers in the Forest (`TheFight.Jeff/Fred`) are jointed: segment models Pelvis, Torso, UpperArmL/R, ForearmL/R, ThighL/R,
ShinL/R, Sword, posed by `ReplicatedStorage.Lobby.BrotherRig` (the builder poses them at guard; `AreaClient` plays the duel).

## Areas (all in one place, far apart)

| Area | Where | Notes |
|---|---|---|
| Hub | `World.Hub`, y = 400 | Floating island. `SpawnLocation` faces north at the portals. `Arrival` is where falls and returns land. |
| Portals | `World.Portals.{AlterGolden,FallenNoob,JeffAndFred}` | Each has a `Trigger` part |
| Shop | `World.Shop` | `Shopkeeper.Torso.ShopPrompt` opens the shop |
| Palace | `World.Palace`, y = -400 | `ArrivalPalace`. The four party portals are `Workspace.PartyRooms.Room1..4` |
| Island | `World.Island`, x = -12000 (attribute `Origin`) | Terrain sea and land; the arrival isle is 1300 out to sea and the ferries cross through mist. `ArrivalIsland`, `BoatLanding`, `BoardingSpot.BoardPrompt`, `Boats.Boat1..3` (each has a `Shore` CFrame attribute: its own landing lane) |
| Forest | `World.Forest`, y = -400 | `ArrivalForest`, `CutTrigger`, `TheFight.{Jeff,Fred}` |
| Stage | `World.Stage`, y = -400 | The class showroom, a sand arena. `Board.Ink.Score` is the score board (`AmbientService`); sandbags hang on ropes. `DummySpot` is where the target dummy stands (`TryoutService` puts up `workspace.ClassTrainingDummy`); performers stand in a ring 7 studs round it. `OrbSpot` is the orb dais. `ArrivalStage` |

## Rules the scripts use

- A part tagged `UnfairPortal` with attribute `Target` (Hub, Palace, Island, Forest) moves whoever walks in. Used by `PortalService`.
- `Workspace.PartyRooms.RoomN.Pad` is where a party gathers; `JoinPrompt` is added by `PartyService`.
- Parts tagged `UnfairComingSoon` with attribute `ComingSoon` show the panel from `Lobby/PadInfo` (bosses not built yet). No teleport path exists for them.
- Each client draws only its current area (`AreaClient` sets `LocalTransparencyModifier`; nothing is reparented). A new top-level folder under `World` must be added to `AREA_PARTS` there, or it shows in every area.
- Models tagged `UnfairSpin` (with `SpinSpeed`) and GUI frames tagged `UnfairSpinGui` are rotated on the client.
- Models tagged `UnfairSway` (unanchored, hinged) get a gust of wind now and then from `AmbientService`.
- Hiding another area also switches off its lights, particles, fire, beams and Billboard/Surface GUIs on that client.

## Attributes the scripts publish

- Room model: `Phase`, `LeaderUserId`, `Difficulty`, `Enraged`, `CountdownEndsAt`, `MemberCount`, `Roster`.
- Player: `Area`, `PlayerClass`, `ClassUnlocked_<id>`, `PartyRoom`, `PartyLocked`, `Cash`, `CashState`, `OrbOwned_<id>`, `PlayerOrb`, plus `leaderstats.Cash`.
- Workspace: `LastLaunchPayload` (Studio dry runs).
- Workspace: `ClassShowroom` = true (set by `TryoutService`): the boss place's `ClassService`, mounted here for the showroom, then
  leaves unlocks and class choice to the lobby and the fight HUD stays hidden.
- Player: `TryoutClass` is the class a showroom performer is wearing (server only; nil outside the showroom).

## Place settings

- `Workspace.StreamingEnabled` off. `Workspace.FallenPartsDestroyHeight` = -2000 (the Palace, Forest and Stage are at y = -400).

## 2026-11-11 additions

- **Azusa**: `World.Hub.AzusaSpot` (built by `Hub.luau`) is where `SidePlaceService` stands Azusa (the mymeo125 avatar, R15, idle
  animation, `HumanoidRootPart.TalkPrompt` hold E). `AzusaClient` runs her conversation; "teach me" teleports to the Tutorial place.
- **Back walls**: every portal trigger has a `BackWall` model behind it (`Gates.backWall`), so gates can only be entered from the front.
  Themed per boss from the `PortalWalls` kit (`lobby/blender/portal_walls.py`): `WallGolden` (alterGolden's door, the palace way back),
  `WallWreck` (TheFallenNoob's wreck, the island way back), `WallDivided` (Jeff n' Fred's swords, the forest way back).
- **Divided Wood**: the ground now runs to x = ±500 and z = -700..190, under the mountain wall and past the way back (the old edge left
  gaps). Trees are sunk by 0.8 + 2.5% of their height and also fill the outer bands. `Forest.Props` (cabins, ruined cabins, wells,
  shrines, log piles, boulders, stumps; `Realm` kit, `lobby/blender/realm.py`), `Forest.Mist` (64 fog banks), and
  `Forest.GlitchPortal.Face` (tag `UnfairPlacePortal`, `Place = "Glitched"`, tag `UnfairGlitchPortal` for `GlitchPortalClient`).
- **Showroom**: performers live in `Workspace.Performers` (hidden outside the Stage area). The target is `Workspace.ClassTrainingDummy`
  (Blender `TrainingDummy`, MeshKit kit `Props`), with a text-only DPS readout.
- Tags: `UnfairPlacePortal` (attribute `Place`: a part that teleports to a side place, `SidePlaceService`), `UnfairGlitchPortal`.
- Player attribute: `Inventory` (JSON of carried items).
