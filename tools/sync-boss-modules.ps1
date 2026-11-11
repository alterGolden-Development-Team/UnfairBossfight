# Builds the boss project into an rbxm in Studio's content folder so a snippet in the boss Studio window can copy chosen scripts' Source
# from it (see tools/sync-boss-modules.luau). Only the named scripts change in the place; nothing else is touched.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $env:TEMP "claude\bosssync.rbxm"
Push-Location (Join-Path $root "alterGolden Bossfight")
try { rojo build sync.project.json -o $out | Out-Null } finally { Pop-Location }
$versions = Join-Path $env:LOCALAPPDATA "Roblox\Versions"
# every installed Studio version: the running one may not be the newest folder
foreach ($studio in (Get-ChildItem $versions -Directory | Where-Object { Test-Path (Join-Path $_.FullName "RobloxStudioBeta.exe") })) {
	Copy-Item $out (Join-Path $studio.FullName "content\unfair_bosssync.rbxm") -Force
}
Write-Output ("synced " + (Get-Item $out).Length + " bytes")
