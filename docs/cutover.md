# Cut-over to the live universe (plan task 25)

Live universe 10768840017. Checkpoints C and D passed in the test universe and the live lobby to boss run was tested.

## The swap

Creator Hub gave no way to move the start place, so the places swap roles instead. The start place (123789153131367, the old
Golden Encounter link) becomes the **lobby**, and the boss moves to 92877530696258:

| Place | Was | Is now | Server size |
|---|---|---|---|
| 123789153131367 (start place) | boss | **lobby** | 50 |
| 92877530696258 | lobby | **boss** | 6 |

`UnfairConfig.Places.Live` already has the swapped ids, `Env = "Live"`, `RequireLobby = true`. Both windows must run a build with
that config. (Found on the way: the boss place had server size 4, too small for a party of 6.)

## Steps (do them back to back, with nobody playing)

Windows: **A** = the boss window (bound to 123789153131367), **B** = the lobby window (bound to 92877530696258).

1. **Backups.** In Creator Hub > each place > Version History note the current version numbers: 123789153131367 `____`, 92877530696258 `____`.
2. **Save local copies.** In A: File > Download a Copy > `boss-live.rbxl`. In B: File > Download a Copy > `lobby-live.rbxl`.
   These are the backups and the starting points for the swap.
3. **Close A and B.** An open window counts as a Team Create session and blocks publishing to that place.
4. **Lobby into the start place.** File > Open from File > `lobby-live.rbxl`. Connect Rojo to **34873**. File > **Publish to Roblox As**,
   choose the existing place **123789153131367** (overwrite). Close the window.
5. **Boss into the other place.** File > Open from File > `boss-live.rbxl`. Connect Rojo to **34872**. File > **Publish to Roblox As**,
   choose the existing place **92877530696258** (overwrite). Close the window.
6. **Place settings** (done by the assistant through the API after step 5): lobby place name "Unfair Bossfight", server size 50;
   boss place name "The Golden Encounter", server size 6.
7. **Rename the experience** in Creator Hub > Game details > Name: "Unfair Bossfight".
8. **Two-account check** (below).
9. **Last:** remove the old server lock setting on the boss place.

## Two-account check

1. The alt joins the experience link: lands in the lobby (no boss-place hop).
2. Both pick a class, form a party, Hardcore + Enraged, Start: both arrive in one private boss server with the right class.
3. Open `https://www.roblox.com/games/92877530696258` directly: bounces to the lobby.
4. Win (or die and use Return to Lobby): cash appears in the lobby HUD, once.
5. A party of 5 or 6 can launch (server size 6).

## Rollback

Version History in Creator Hub for each place: restore the version noted in step 1 (or publish the `.rbxl` copies from step 2
back to their own places). Then restore the old ids in `UnfairConfig.Places.Live`, set `RequireLobby = false` and republish. Cash
already written stays in the data store and is harmless.

## After this

Builds for the test universe need `Env = "Test"` again (switch it on a branch or before the next test round). Never publish a Test
build to a live place.
