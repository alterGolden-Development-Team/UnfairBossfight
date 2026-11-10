# Lobby redesign

What was asked: replace the plain lobby with a floating island, a walk-in shop (Classes / Orbs / Lore) with a showroom, cash on the leaderboard, three portals that each look like their boss's world, a destination world behind each portal, and a new difficulty screen.

## What the research said, and what was done with it

| Finding | Source | How it is used here |
|---|---|---|
| A "weenie" is a big, unique landmark that pulls people toward it and tells them where they are | Unity, Game Developer | Each portal has a column of light visible across the island. The shop has a giant sword through its roof. The palace has one great door at the end of one straight hall. The island has a lighthouse. |
| Start players with a clear view of the path ahead and their options | Unity level design basics | Spawn faces north with all three portals on the skyline, and trees and lanterns frame the view. Nothing is planted in that sightline. |
| Hub-and-spoke: spokes get identity from the hub, return trips should feel like a break | The Level Design Book | One hub, three spokes, one way back from each. The spokes are moods first, floor plans second. |
| Hubs should feel like a home base, not a menu; keep the fiction even at a little cost to speed | Hub-world analyses (Hades, Hollow Knight, Destiny) | The shop is a place with a keeper. The menu only opens once you have walked up and spoken to him. |
| Give every biome its own colour identity with a colour script; check the silhouette in greyscale | Beast Breaker color script, Sky: Children of the Light | Colour script: gold-hour sky, dark gilded hall, bright noon sea, a world drained to black and white. Lighting changes per area on the client. |
| Tell story through arranged objects | The Level Design Book, Game Maker's Toolkit | Kneeling gold statues and spilled coin at Midas's gate, an anchor and driftwood at the sand portal, two swords planted in opposite ground at the yin-yang gate. |
| Use light and contrast to mark what can be used; keep interactive things visually consistent | Unity level design basics | Every portal is a glowing disc in a frame. |
| Show the whole roster at once, and show what the moves do, not only portraits | Character-select write-ups, fighting-game UX case studies | The list is always visible on the left. Clicking any skill plays it on the dummy. |
| Free players must be able to reach everything paying players can; valuable items may be slow but never impossible | Game Developer "free to play ethics", Machinations, Unity economy guide | Three free classes. Every cash item is earned only from wins. Orbs are small (+8% to +20%) so they are a choice, not a requirement. |
| Early earnings should be quick | Roblox onboarding guide, F2P economy guides | Supporter costs 100 (four Hardcore wins, or two Enraged). Orbs start at 40. |
| Low part count matters on mobile; reuse pieces; large rocks under floating islands sell them | Roblox optimisation guide, DevForum feedback | About 5,000 parts for the whole place. Details have collision and shadows off. Rock hangs under every island. |
| Animate previews with a local model; animation assets are unreliable in viewports | DevForum WorldModel threads | The showroom dummy is a client-side R6 rig on a real stage, posed by code, so it works for every player. |

Most of the game-design sources are practitioner writing, not research. Treat them as good habits, and test them with real players.

## Was each idea suitable? Questions I asked

- **Should the worlds be separate places?** No. One place means no teleport wait and no extra failure points. A short fade and a server-side move is instant. Only the actual boss fight teleports.
- **A black-and-white forest in a colourful game?** Yes, but it needs real black and white, so the client also drops saturation to zero there. Your UI and class tags keep their colour.
- **"Blue stripe house" from the reference photos?** Not used. The photos are of Little St. James and its building. I replaced it with an original island and a blue-and-white striped lighthouse, because Roblox has a young audience and a recognisable copy could get the game moderated.
- **Orbs that change combat?** Kept to simple stat and cash effects applied in one place, so the boss fight's balance and code stay as they were. They can be retuned in `OrbConfig`.
- **Can a client cheat a purchase?** The client only names an item. Prices are on the server, spending goes through `UpdateAsync` with pure rules, and the boss place re-reads what you own from the save instead of trusting the teleport.
- **Do the skill previews match the real thing?** They are stylised previews, not the fight's effects, because those are bound to a boss. Each one shows the shape of the skill.

## What exists now

**World** (builders in `lobby/map/`, saved in the place file): Hub (floating island, satellites, cloud sea), Shop, three portals, Palace, Island (sea, 3 ferries, lighthouse), Forest (The Cut), Stage (showroom).

**Code**
- Server: `PlayerData` (save, leaderboard), `ShopService`, `PortalService` (portals, falling rescue, boats).
- Client: `AreaClient` (moods, fades, cutscene), `ShopClient`, `PartyClient` (expedition board), `PadInfoClient`, `ClassTagsClient`.
- Shared: `OrbConfig`, `CashLedger` (purchases), `UnlockCheck` (cash classes).
- Boss: `Encounter/Orbs`, `Encounter/PlayerRecord`, hooks in `ClassService`, `PlayerEncounter`, `Intake`, `CashService`.

**Prices**: Warrior, Mage, Tank free. Supporter 100, Gambler 175 cash. Duelist, Twinblade, True Warrior by badge. Reality Disorderer by game pass. Orbs 40 to 250.

## Sources

- [Level design basics, Unity](https://unity.com/blog/level-design-basics)
- [What Mario learned from Mickey Mouse (weenies)](https://gamedeveloper.com/design/what-mario-learned-from-mickey-mouse---part-3-decision-making-and-weenies)
- [The Level Design Book: layout typology](https://book.leveldesignbook.com/process/layout/typology)
- [How to design a hub world that works](https://bugnet.io/blog/how-to-design-a-hub-world-that-works)
- [Safe havens in video games](https://galaron.substack.com/p/safe-havens-in-video-games)
- [How color scripting conveyed the emotional arcs of Beast Breaker](https://gamedeveloper.com/art/how-color-scripting-conveyed-the-emotional-arcs-of-beast-breaker)
- [Designing emotional environments for Sky: Children of the Light](https://80.lv/articles/how-to-design-emotional-game-environments-for-sky-children-of-the-light)
- [Environmental storytelling, The Level Design Book](https://book.leveldesignbook.com/process/env-art/storytelling)
- [Armchair VGUX: Smash Ultimate](https://medium.com/super-jump/armchair-vgux-super-smash-bros-ultimate-e16bfeeea0c9)
- [Fighting game UX case study: Guilty Gear Strive](https://medium.com/patternfly/fighting-games-ux-holds-the-genre-back-a-case-study-into-guilty-gear-strive-s-ux-e0c5e24eae0f)
- [Defining free-to-play ethics](https://www.gamedeveloper.com/game-platforms/defining-free-to-play-ethics)
- [Game economy design in free-to-play games, Machinations](https://machinations.io/articles/game-economy-design-free-to-play-games)
- [Game economy design guide, Unity](https://unity.com/resources/game-economy-design-guide)
- [Onboarding, Roblox docs](https://create.roblox.com/docs/production/game-design/onboarding)
- [Optimize your game, Roblox docs](https://create.roblox.com/docs/tutorials/curriculums/environmental-art/optimize-your-experience)
- [Low-poly floating island feedback, DevForum](https://devforum.roblox.com/t/feedback-low-poly-enviromental-builds/502492)
- [WorldModel character animation, DevForum](https://devforum.roblox.com/t/worldmodel-and-character-animation-in-viewport-frame/1148913)
