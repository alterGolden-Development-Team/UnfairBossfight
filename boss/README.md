# alterGolden's Bossfight (boss place) — VS Code workspace

The place's scripts as files, laid out for [Rojo](https://rojo.space) 7 so you can edit them in VS Code
and sync them back into Studio.

```
src/
  ReplicatedFirst/ ReplicatedStorage/ ServerScriptService/ ServerStorage/ StarterGui/ StarterPlayer/
tools/
  export-receiver.ps1     local receiver that writes the exported files here
  ExportFromStudio.luau   run in Studio to export every script into src/
  check.ps1               build + static-analysis check; run it before committing a refactor
default.project.json      Rojo project
```

File naming follows Rojo: `Name.luau` is a ModuleScript, `Name.server.luau` a Script,
`Name.client.luau` a LocalScript. A folder with `init.*.luau` is a script that has scripts inside it.
`init.meta.json` keeps a container's class and sets `ignoreUnknownInstances`, so **syncing never deletes
the place's models, GUIs, sounds or values**. Rojo only manages the scripts. Backup folders
(`VFXBackups`, `MapBackups`, `VFXQuarantine`) are not exported.

## 1. Export the scripts from Studio (one time, or whenever Studio is ahead)

1. In Studio: **Game Settings → Security → Allow HTTP Requests: On** (turn it off again after step 4).
2. In PowerShell: `powershell -ExecutionPolicy Bypass -File D:\Project\alterGoldenBossfight\tools\export-receiver.ps1`
3. In Studio's command bar (View → Command Bar), paste the contents of `tools/ExportFromStudio.luau` and press Enter.
4. The receiver prints each batch and stops by itself. Check `export-report.txt` for naming notes.

## 2. Edit in VS Code

Open this folder in VS Code and install the two recommended extensions when it asks:

- **Rojo** (`evaera.vscode-rojo`): installs Rojo and starts/stops the sync server.
- **Luau Language Server** (`JohnnyMorganz.luau-lsp`): autocomplete, types and `require` navigation.

## 3. Sync back to Studio

1. Install the Rojo plugin in Studio (the Rojo extension offers to do it).
2. In VS Code: Rojo → **Start server** on `default.project.json`.
3. In Studio: Plugins → Rojo → **Connect**.

From then on, saving a file in VS Code updates the script in Studio. Rojo does not pull edits made in
Studio back into the files, so either keep VS Code as the place you edit scripts, or re-run the export
(step 1) before you start working in VS Code again.

## Project layout

- `src/` — Rojo-managed scripts used for editing and syncing.
- `place/TheGoldenEncounter.rbxl` — full Roblox place snapshot, including the map and saved instances. Open it in Roblox Studio.
- `src/ServerStorage/BossEncounter/` — besides scripts this holds the boss `Templates`, `Assets` and `NPCs` as `.rbxm` models (recovered from `place/TheGoldenEncounter.rbxl`). Rojo manages them, so edit them in Studio only if you then re-export them over the `.rbxm`.
- **Every folder under `src/` needs an `init.meta.json` with `{"ignoreUnknownInstances":true}`.** Without it Rojo deletes any non-script instance inside that folder on the next sync. (That is how `Templates` and the Gate of Wrath's boss model disappeared once.)
- `tools/` — Studio export receiver, `check.ps1` (build + analyzer + mirror-pair gate), `mirror-pairs.txt`, `analyzer-baseline.txt`.
- `tasks/` — the refactor plan (`plan.md`, `todo.md`), the require-cycle analysis (`cycles.md`) and the P5Strikes split note.
- Large modules are folder modules: `VFXEngine/Effects/P5Strikes/` and `BossSystem/Phases/Phase25Controller/` are an `init.luau`
  that requires a `Core.luau` plus themed group files and returns the same table as before, so callers did not change.
- `ReplicatedStorage/BossShared/Presentation/*Runtime` are client copies of server modules. Edit the **server** copy, then run
  `tools\check.ps1 -SyncMirrors`; clients only run the ReplicatedStorage copy.
- `_backup/` — existing project backups.

Roblox cloud assets in the place remain referenced by their asset IDs and may need Roblox access to load.


## Checking a change

`powershell -ExecutionPolicy Bypass -File tools\check.ps1` runs `rojo build` and the Luau analyzer over `src/` and
fails if it finds any diagnostic that is not in `tools/analyzer-baseline.txt`. After a cleanup that removes warnings,
run it with `-UpdateBaseline` to lock the improvement in. It cannot test gameplay: playtest the touched attacks in Studio.
