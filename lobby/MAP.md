# Lobby map contract

The lobby map lives in the place file (Rojo does not sync Workspace; backup in `lobby/place/Lobby.rbxl`).
Scripts rely on the **names** below. Everything else (looks, extra decoration) is free.
Anything marked *(script adds)* is created at runtime if the map does not have it, so it does not need building.

## Plaza (plan task 11)

| Path | Type | Notes |
|---|---|---|
| `Workspace.SpawnLocation` | SpawnLocation | centre of "Unfair Plaza" |
| `Workspace.Pads` | Folder | the three portal arches |
| `Workspace.Pads.AlterGolden` | Model | gold arch, live. Needs a `Sign` part (SurfaceGui title). Attribute `Status = "Live"` |
| `Workspace.Pads.JeffAndFred` | Model | dimmed, chained arch. `Sign` part. Attribute `Status = "ComingSoon"` |
| `Workspace.Pads.FallenNoob` | Model | harbour-dock arch (TheFallenNoob's Private Island). `Sign` part. Attribute `Status = "ComingSoon"` |

The two `ComingSoon` arches never call `TeleportService` (plan task 24 adds an info panel).

## Class hall and party rooms (plan task 12)

| Path | Type | Notes |
|---|---|---|
| `Workspace.ClassHall` | Folder | one child per class id |
| `Workspace.ClassHall.<ClassId>` | Model or BasePart | name = an entry of `ClassConfig.Order` (Warrior, Mage, Tank, Supporter, Gambler, Duelist, Twinblade, Disorderer, TrueWarrior). A BasePart named `Pedestal` inside (or the part itself) carries the prompt. `PickPrompt` *(script adds, client side)* |
| `Workspace.PartyRooms` | Folder | in the gold wing |
| `Workspace.PartyRooms.Room1` .. `Room4` | Model | same structure each (4 = `UnfairConfig.PartyRooms`) |
| `Workspace.PartyRooms.RoomN.Pad` | BasePart | players stand here; `JoinPrompt` *(script adds)*; leaving the pad by more than `UnfairConfig.RoomLeaveDistance` studs drops you from the room |
| `Workspace.PartyRooms.RoomN.Console` | BasePart | decoration the leader looks at |
| `Workspace.PartyRooms.RoomN.RosterDisplay` | BasePart | screen for the roster; the roster billboard is drawn over `Pad` *(script adds)* |
| `Workspace.Shop` | Model | shop shell with a `Sign` part reading "Coming soon" |

## Coming-soon places (plan task 24)

`PadInfoClient` shows a panel when a player is within 9 studs of a watched model. Watched: every child of `Workspace.Pads` with
attribute `Status = "ComingSoon"`, and `Workspace.Shop`. The model's **name** must be a key in
`lobby/src/ReplicatedStorage/Lobby/PadInfo.luau` (`JeffAndFred`, `FallenNoob`, `Shop`), which holds the panel text. These models have
no ProximityPrompt and nothing touches `TeleportService` for them. To open a pad later: set its `Status` to `Live` and remove its
`PadInfo` entry.

## Cash HUD (plan task 22)

Top-right "Cash: N", drawn by `CashHudClient` from the player attributes below. `--` means the balance is still loading or could not
be read (it retries).

## Attributes the scripts publish (read-only for the map)

- Room model (`RoomN`): `Phase` (Open / Countdown / Locked), `LeaderUserId`, `Difficulty`, `Enraged`, `CountdownEndsAt` (server time), `MemberCount`, `Roster` (JSON list of `{userId, name, class}`).
- Player: `PlayerClass`, `ClassUnlocked_<id>`, `PartyRoom`, `PartyLocked`, `Cash` (whole number, only after a good read), `CashState` (`Loading` / `Ready` / `Error`).
- Workspace: `LastLaunchPayload` (dry runs in Studio: the JSON that would have been sent).

## Place settings

- `Workspace.StreamingEnabled` is **off** in the lobby (the map is small). With streaming on, pads and rooms far from the player are not on the client yet and the party UI cannot find them.

## Rules

- Never rename a path above without changing the scripts: `PartyService`, `PartyClient`, `ClassPickerClient`.
- Parts scripts touch must be anchored and have a stable name; keep decoration in separate models.
- Re-save `lobby/place/Lobby.rbxl` after every map task.
