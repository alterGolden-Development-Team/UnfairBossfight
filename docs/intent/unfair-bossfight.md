# Unfair Bossfight: Statement of Intent

Confirmed by the user through an interview. Source of truth for the spec and the task plan.

## Outcome

A public game called **Unfair Bossfight**. Players join a lobby, choose a class, form a party and use a teleporter.

| Pad | Status |
|---|---|
| alterGolden (The Golden Encounter) | Live |
| Jeff n' Fred Bizzare Brother | "Coming soon" placeholder |
| TheFallenNoob's Private Island | "Coming soon" placeholder |

The boss place becomes private and is reachable only through the lobby, so the Roblox server lock is no longer needed.

## Users

Roblox players, solo or in a party of up to 6 with a leader.

## Why now

The boss place is a single place guarded by a server lock. A lobby lets anyone join safely and leaves room for more bosses and a shop.

## Success

- The lobby has a class picker (class is chosen in the lobby).
- The party leader sets difficulty (Hellaven, TrueHardcore, Hardcore, NerfedHardcore, Easy) and the Enraged toggle. Enraged is disabled on Easy.
- The pad teleports the party to a private boss server carrying class, difficulty and enraged state.
- The in-arena difficulty statue and Enraged Gate are replaced by this flow. A solo and Studio-testing fallback keeps them.
- After a win or a loss, players choose Retry or Return to Lobby.
- A win pays cash, scaled by difficulty, about 5 (Easy) to about 50 (Hellaven), doubled when Enraged.

## Constraints

- The boss place re-checks unlocks (badges and game passes) on arrival. The lobby result is never trusted alone.
- Solo-only badges such as TrueWarrior must still work. A 1-player pad counts as solo.
- Cash is persistent and shared across both places (DataStore).

## Phases

1. Lobby map, three pads, class picker, party and leader flow, difficulty and Enraged config, boss-place intake.
2. Retry and Return to Lobby, cash earning and saving.
3. Lobby shop for powerups and classes (designed separately). Milestone 1 only reserves a placeholder building.

## Project layout (assumption, not yet confirmed in detail)

`D:/UnfairBossfight` holds the lobby project and the boss project side by side. Each has its own Rojo project file, with a shared folder for config. The untracked BossEncounter folder is committed first.

## Out of scope

- The Jeff n' Fred and Fallen Noob bosses (placeholder pads only).
- The shop and powerups in milestone 1.
- Cross-server matchmaking.
- Joining a party from outside the lobby.
