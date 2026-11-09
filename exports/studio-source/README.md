# Studio source snapshot

This folder contains the direct Luau source snapshot exported from the connected Studio edit session.

- `place/TheGoldenEncounter.rbxl` (at the project root) is the complete place file, including the map.
- `ReplicatedFirst/`, `ReplicatedStorage/`, `ServerScriptService/`, `ServerStorage/`, `StarterGui/`, and `StarterPlayer/` contain 771 Script, LocalScript, and ModuleScript files.
- `manifest.json` maps each exported file to its Roblox instance path and class.

The project's root `src/` remains the Rojo-managed source tree. These exports are kept separately because the direct snapshot uses plain `.lua` filenames. Roblox cloud assets remain referenced by asset IDs and may need Roblox access to load.
