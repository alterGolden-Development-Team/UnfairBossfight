# Builds one of the side places (glitched, tutorial) into a model Studio can load, for tools/sync-place.luau.
#   powershell -File tools\sync-place.ps1 -Place glitched
param([Parameter(Mandatory = $true)][ValidateSet("glitched", "tutorial")][string]$Place)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $env:TEMP ("claude\" + $Place + "sync.rbxm")
New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
Push-Location (Join-Path $root $Place)
try { rojo build sync.project.json -o $out | Out-Null } finally { Pop-Location }
$versions = Join-Path $env:LOCALAPPDATA "Roblox\Versions"
foreach ($studio in (Get-ChildItem $versions -Directory | Where-Object { Test-Path (Join-Path $_.FullName "RobloxStudioBeta.exe") })) {
	Copy-Item $out (Join-Path $studio.FullName ("content\unfair_" + $Place + "sync.rbxm")) -Force
}
Write-Output ("synced " + $Place + " " + (Get-Item $out).Length + " bytes")
