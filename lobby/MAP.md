# Lobby map contract

The lobby world is built by the modules in `lobby/map/` into `Workspace.World` and saved in the place file (Rojo does not sync Workspace).
Rebuild an area from Studio, **test place only**: `require(game.ServerStorage.MapBuilder).Build("Palace")`.
Design notes and sources: [docs/spec/lobby-redesign.md](../docs/spec/lobby-redesign.md). Scripts rely on the names below.

## Areas (all in one place, far apart)

| Area | Where | Notes |
|---|---|---|
| Hub | `World.Hub`, y = 400 | Floating island. `SpawnLocation` faces north at the portals. `Arrival` is where falls and returns land. |
| Portals | `World.Portals.{AlterGolden,FallenNoob,JeffAndFred}` | Each has a `Trigger` part |
| Shop | `World.Shop` | `Shopkeeper.Torso.ShopPrompt` opens the shop |
| Palace | `World.Palace`, y = -400 | `ArrivalPalace`. The four party portals are `Workspace.PartyRooms.Room1..4` |
| Island | `World.Island`, x = -12000 (attribute `Origin`) | Terrain sea and land. `ArrivalIsland`, `BoatLanding`, `BoardingSpot.BoardPrompt`, `Boats.Boat1..3` |
| Forest | `World.Forest`, y = -400 | `ArrivalForest`, `CutTrigger`, `TheFight.{Jeff,Fred}` |
| Stage | `World.Stage`, y = -400 | The showroom. `DummySpot` is where the client puts its dummy |

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

## Place settings

- `Workspace.StreamingEnabled` off. `Workspace.FallenPartsDestroyHeight` = -2000 (the Palace, Forest and Stage are at y = -400).
