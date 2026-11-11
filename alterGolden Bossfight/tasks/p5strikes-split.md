# P5Strikes split (Tasks 11 and 12): design and outcome

`ReplicatedStorage/VFXEngine/Effects/P5Strikes.luau` was 3,773 lines: 88 independent client cues
(`P.<Name>(E, d)`) plus 66 top-level colours/helpers, all in one file.

## How effects are found (why a folder module is safe)
- The server only ever sends the string `"P5Strikes"` and a stage name: `Net.Send("P5Strikes", stage, data)`.
- `StarterPlayerScripts/VFXEngineClient` does `require(VFX.Effects:FindFirstChild(name))[stage](E, data)` and only
  walks the *direct children* of `Effects`.
- So `P5Strikes` can become a `ModuleScript` that has child modules, as long as `require(P5Strikes)` still returns the same
  table of cues. No server script and no dispatcher code changes.

## Layout
```
Effects/P5Strikes/
  init.luau        the doc comment of every cue; requires Core and each group; returns Core.P
  Core.luau        colours, materials and drawing helpers used by more than one group; returns them + the shared P table
  Slashes.luau     818  Mode, Blink, claws, black/upper slashes, wings, bolts, counter stance, Wild Hunt, Golden Pierce
  ViperTearer.luau 671  Slam, Viper, Horrifying Ground (stab + cage), Night Tearer, Warn
  FireKnives.luau  648  Fire Ring, Shotgun Blast, Perfect Vertical Slash, knife sets/fields
  RootsStars.luau  557  thorn roots / thickets, star curtain and falling stars, gravity well
  SilentRiver.luau 547  Golden Eternity blades, Overclock, big warnings, Silent Cut, Scarlet River
  ChronoBomb.luau  243  Time Bomb, Chronobreak
```
Each group starts with `local Core = require(script.Parent.Core)` and a `local P, a, b = Core.P, Core.a, Core.b` line,
registers its `function P.<Name>(E, d)` bodies unchanged, and ends with `return P` (Roblox requires exactly one return).
A helper used by only one group stays inside that group (this keeps the two mutable locals, `frozen` and `knifeSets`,
private to the file that owns them); helpers used by several groups live in Core.

## Rules this was done under
- Function bodies are moved byte-for-byte. The only edits: the doc title, and Core's `Assets` path (one level deeper).
- Only `thorn`, `VINE`, `VINE_TIP` were dropped (nothing called them).
- Verified by script: every original block appears verbatim in exactly one new file, all 88 cues exist once, and the analyzer
  reports no new diagnostics (existing ones relocate).

## Found on the way
- The analyzer flagged **"Module does not return exactly 1 value"** on the first draft (groups had no `return P`). That would have
  stopped `P5Strikes` from loading at all. Fixed before commit; it is the reason `check.ps1` stays the gate for this kind of change.
- `SilentHit` passed an undefined `g` into `E.Ground(..., {g, h.Folder})`; `E.Ground` uses `ipairs`, which stops at the nil, so the
  effect's own parts were never excluded from the floor raycast. Fixed (`{h.Folder}`), separate commit.

## Adding or changing a cue
Put it in the group whose attack it belongs to (or a new group file: add it to `init.luau`). If it needs a helper another
group also uses, add the helper to Core and export it in Core's return table.
