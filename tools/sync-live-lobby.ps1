# Builds the lobby code into a model and puts it where the LIVE lobby Studio window (Unfair Bossfight, place 123789153131367) can load it (see lobby/sync.project.json).
# Then run the snippet in tools/sync-live-lobby.luau in the live lobby window. Publishing stays the user's step.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $env:TEMP "claude\livelobbysync.rbxm"
Push-Location $root
try { rojo build lobby/sync.project.json -o $out | Out-Null } finally { Pop-Location }
$versions = Join-Path $env:LOCALAPPDATA "Roblox\Versions"
# every installed Studio version: the running one may not be the newest folder
foreach ($studio in (Get-ChildItem $versions -Directory | Where-Object { Test-Path (Join-Path $_.FullName "RobloxStudioBeta.exe") })) {
	Copy-Item $out (Join-Path $studio.FullName "content\unfair_livelobbysync.rbxm") -Force
}
Write-Output ("synced " + (Get-Item $out).Length + " bytes")
