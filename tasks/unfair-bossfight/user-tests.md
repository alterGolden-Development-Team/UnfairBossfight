# What is left for you to test

Everything that code and Studio-by-script could check is done. What remains needs a person (clicks in menus, a second account,
or your eyes). Do the parts in order; each one says what to tell me so I can continue. Task numbers match [plan.md](plan.md).

## A. Setup (about 10 minutes)

**A1. Save the test lobby.** In the window titled *Unfair Bossfight TEST* press Ctrl+S. (It is the test place, 83310105029258.)

**A2. Copy the boss map into the test boss place.** I cannot click Studio's File menu, so this one is yours.
1. Go to the window titled *The Golden Encounter* (the live boss).
2. File > **Save to Roblox As...**
3. Pick the experience *Unfair Bossfight TEST* and the place named *Taiueber's Place: 11092026_3* (id 76581021814220, the empty
   baseplate). **Do not** pick *The Golden Encounter* and do not use Publish: that would overwrite the live game.
4. Wait for "saved". That window now belongs to the test place, so it is safe to leave open.
5. Tell me "boss copied". I check the window title and that the arena is there.

**A3. (Optional, for cash tests in Studio.)** In each test window: Home > Game Settings > Security > turn on **Enable Studio Access
to API Services**. Without it the Studio cash HUD shows `--` (that is the failure path working, not a bug).

**A4. Connect Rojo when I say.** I will remove the scripts I put into the test lobby window by hand, then you press Connect in the
Rojo plugin: lobby window to port **34873**, boss window to port **34872**. Never connect a live window.

## B. Studio checks, no teleport (lobby window, Test tab)

| Task | Do this | You should see |
|---|---|---|
| 11, 12 (map review) | Look around: plaza, 3 arches, class hall, 4 party rooms, shop. | Anything you want moved or restyled: tell me. |
| 14 (class picker) | Press Play. Click the **Class: Warrior** chip bottom-left, or press E at a pedestal. Pick Mage. | Chip says Mage, a "Mage" tag floats above your head, cards show Pick / Selected. |
| 14 (locks, optional) | Before Play, add attribute `ForceClassLocks` = true on Workspace (Properties > Attributes). Try TrueWarrior. | "Locked." with the hint; class unchanged. |
| 15, 16 (party, 3 clients) | Test tab > Clients and Servers, Players 3, Start. Client 1: walk to **Room 1** pad, press E. Clients 2 and 3: join Room 1. | Billboard over the pad lists 3 names with classes. Client 1 has the leader panel, the others only the roster. |
| | Leader picks Hardcore, ticks Enraged, then picks Easy. | Enraged turns off and cannot be ticked on Easy. |
| | Leader presses Start. During the 5 s countdown a member walks away from the pad. | Countdown cancels for everyone. |
| | Start again and let it finish. | Output prints a dry-run payload with 3 members, the difficulty, Enraged and each member's class. Room resets. |
| | Leader leaves the pad. | Leadership passes to the next member. |
| 24 (coming soon) | Walk up to the Jeff n' Fred arch, the TheFallenNoob arch and the shop. | A "Coming soon" panel for each; nothing teleports, no prompt. |

Tell me what looked wrong and I fix it. If all fine, I tick 11, 12, 14, 15, 16, 24 and Checkpoint B.

## C. Boss place in Studio (needs A2 and A4)

I run the intake checks myself (class, difficulty and Enraged from a fake payload, forged class falls back, direct join in lobby
mode). Your part is the replay (task 9):
1. I set `UnfairConfig.DevPayload = { difficulty = "Hardcore", enraged = true, class = "Mage" }`; press Play in the boss window.
2. You should be a Mage on Hardcore + Enraged with the difficulty statue, class statue and Enraged gate gone, and no prompt to
   change anything.
3. Fight a bit and die: the panel says *"Return to the lobby to change difficulty."* and a **RETURN TO LOBBY** button shows at the
   bottom. Click it: Studio only says it would send you back (it cannot teleport).
4. Remove the dev payload (I do): the place plays exactly as before, statues and gate work.
5. With A3 on: win once. Output has no `[Cash]` errors, and the Studio lobby HUD later shows the cash (Hardcore Enraged = 50).

## D. Published tests with two accounts (tasks 18, 19, 21, 22, 23)

**D0. Publish both test places.** With both windows connected to Rojo and no errors: in each, File > Publish to Roblox (the boss
window to 76581021814220, the lobby window to 83310105029258). In Creator Hub set the **start place** of *Unfair Bossfight TEST*
to the lobby and make the experience joinable for your alt (public or friends).

**D1. First teleport (task 18, Checkpoint C).**
1. You and the alt join the test experience: both land in the lobby.
2. Pick different classes. Form a party in one room. Leader: Hardcore + Enraged. Start.
3. Both arrive in the same boss server. Check: right class each, Hardcore + Enraged, statues and gate gone.
4. Direct join: open `https://www.roblox.com/games/start?placeId=76581021814220` as the alt. They should be bounced to the lobby.
5. Write anything odd into plan.md or tell me; fixes become new tasks.

**D2. Retry and Return (task 19).** Die with both players. One presses **Retry**, the other **Return to Lobby**. The returner lands
in a public lobby server; the other restarts in place with the same class, difficulty and Enraged. Then win once: Return appears
about 6 seconds after the victory screen.

**D3. Cash and badges (tasks 21, 22, 23, Checkpoint D).**
- Win a Hardcore + Enraged run with 2 players: each gets +50 (TrueHardcore 70, Hellaven 100). Return: the lobby HUD shows it with a
  green +50. Reload the lobby: still 50 (never twice).
- Win a solo True Hardcore run. Win again with 2 players. In the boss server Output (F9 > Server) expect `Victory badge for ...`
  warnings, because the badges belong to the live universe: the solo run should show **two** lines for that player (normal + solo
  badge), the 2-player run **one line per player**. That proves solo detection did not change.
- Unplug test: nothing to do; a failed cash write is retried and logged as `[Cash] ... will be retried`.

## E. Going live (tasks 25, 26)

Only after D passes and you say go. The steps and rollback are in [../../docs/cutover.md](../../docs/cutover.md). I do the 2-line
config change; you do the Creator Hub steps and the live 2-account check.

## What I did not build

- **Audio** for the lobby (task 24): there are no sound assets chosen yet. Tell me what you want or send asset ids.
- **Multi-boss launching:** every party room launches the one boss place. The README lists the small change for the next boss.
- **The shop:** its own spec (milestone 3); the lobby only shows a "Coming soon" panel.
