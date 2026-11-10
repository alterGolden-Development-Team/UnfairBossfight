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

## Areas (all in one place, far apart)

| Area | Where | Notes |
|---|---|---|
| Hub | `World.Hub`, y = 400 | Floating island. `SpawnLocation` faces north at the portals. `Arrival` is where falls and returns land. |
| Portals | `World.Portals.{AlterGolden,FallenNoob,JeffAndFred}` | Each has a `Trigger` part |
| Shop | `World.Shop` | `Shopkeeper.Torso.ShopPrompt` opens the shop |
| Palace | `World.Palace`, y = -400 | `ArrivalPalace`. The four party portals are `Workspace.PartyRooms.Room1..4` |
| Island | `World.Island`, x = -12000 (attribute `Origin`) | Terrain sea and land. `ArrivalIsland`, `BoatLanding`, `BoardingSpot.BoardPrompt`, `Boats.Boat1..3` |
| Forest | `World.Forest`, y = -400 | `ArrivalForest`, `CutTrigger`, `TheFight.{Jeff,Fred}` |
| Stage | `World.Stage`, y = -400 | The class showroom. `DummySpot` is where the target dummy stands (`TryoutService` puts up `workspace.ClassTrainingDummy`); performers stand in a ring 7 studs round it. `OrbSpot` is the orb dais. `ArrivalStage` |

## Rules the scripts use

- A part tagged `UnfairPortal` with attribute `Target` (Hub, Palace, Island, Forest) moves whoever walks in. Used by `PortalService`.
- `Workspace.PartyRooms.RoomN.Pad` is where a party gathers; `JoinPrompt` is added by `PartyService`.
- Parts tagged `UnfairComingSoon` with attribute `ComingSoon` show the panel from `Lobby/PadInfo` (bosses not built yet). No teleport path exists for them.
- Each client draws only its current area (`AreaClient` sets `LocalTransparencyModifier`; nothing is reparented). A new top-level folder under `World` must be added to `AREA_PARTS` there, or it shows in every area.
- Models tagged `UnfairSpin` (with `SpinSpeed`) and GUI frames tagged `UnfairSpinGui` are rotated on the client.

## Attributes the scripts publish

- Room model: `Phase`, `LeaderUserId`, `Difficulty`, `Enraged`, `CountdownEndsAt`, `MemberCount`, `Roster`.
- Player: `Area`, `PlayerClass`, `ClassUnlocked_<id>`, `PartyRoom`, `PartyLocked`, `Cash`, `CashState`, `OrbOwned_<id>`, `PlayerOrb`, plus `leaderstats.Cash`.
- Workspace: `LastLaunchPayload` (Studio dry runs).
- Workspace: `ClassShowroom` = true (set by `TryoutService`): the boss place's `ClassService`, mounted here for the showroom, then
  leaves unlocks and class choice to the lobby and the fight HUD stays hidden.
- Player: `TryoutClass` is the class a showroom performer is wearing (server only; nil outside the showroom).

## Place settings

- `Workspace.StreamingEnabled` off. `Workspace.FallenPartsDestroyHeight` = -2000 (the Palace, Forest and Stage are at y = -400).
