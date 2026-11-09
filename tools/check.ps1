<#
  check.ps1 - one-command safety check for the Rojo project.

    powershell -ExecutionPolicy Bypass -File tools\check.ps1                 # build + analyzer diff vs baseline
    powershell -ExecutionPolicy Bypass -File tools\check.ps1 -UpdateBaseline # accept the current analyzer output

  1. `rojo build` must succeed.
  2. `luau-lsp analyze` (the binary shipped with the VS Code Luau extension) runs over src/. Every diagnostic is
     reduced to "file: Kind: message" (line numbers stripped, so edits above a warning do not matter) and counted.
     The run FAILS if any diagnostic is new or occurs more often than in tools\analyzer-baseline.txt.
     Diagnostics that went away are reported as an improvement; run -UpdateBaseline to lock them in.
  Exit code: 0 = pass, 1 = regression, 2 = tooling problem.
#>
param([switch]$UpdateBaseline)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$baselinePath = Join-Path $PSScriptRoot 'analyzer-baseline.txt'
$tmp = Join-Path ([IO.Path]::GetTempPath()) 'alterGoldenCheck'
New-Item -ItemType Directory -Force $tmp | Out-Null

function Stop-Tooling($msg) { Write-Host "TOOLING: $msg" -ForegroundColor Red; exit 2 }

# --- locate tools -----------------------------------------------------------------------------------------
if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) { Stop-Tooling 'rojo is not on PATH' }
$lsp = Get-ChildItem "$env:USERPROFILE\.vscode\extensions\johnnymorganz.luau-lsp-*\bin\server.exe" -ErrorAction SilentlyContinue |
    Sort-Object { $_.Directory.Parent.Name } | Select-Object -Last 1
if (-not $lsp) { Stop-Tooling 'luau-lsp not found: install the "Luau Language Server" VS Code extension' }
$defs = Get-ChildItem "$env:APPDATA\Code\User\globalStorage\johnnymorganz.luau-lsp\globalTypes*.d.luau" -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (-not $defs) { Stop-Tooling 'Roblox type definitions not found: open the project once in VS Code so luau-lsp downloads them' }

# --- 1. build ---------------------------------------------------------------------------------------------
Write-Host '[1/2] rojo build ...'
& rojo build default.project.json -o (Join-Path $tmp 'check.rbxl') | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host 'FAIL: rojo build failed' -ForegroundColor Red; exit 1 }

# --- 2. analyzer ------------------------------------------------------------------------------------------
Write-Host '[2/2] luau-lsp analyze (about a minute) ...'
$sourcemap = Join-Path $tmp 'sourcemap.json'
& rojo sourcemap default.project.json -o $sourcemap | Out-Null
$ErrorActionPreference = 'Continue'   # Windows PowerShell 5.1 turns a native command's stderr into errors
$raw = & $lsp.FullName analyze "--definitions=$($defs.FullName)" "--sourcemap=$sourcemap" --no-strict-dm-types src 2>&1 |
    ForEach-Object { "$_" }
$ErrorActionPreference = 'Stop'

$rootPattern = [regex]::Escape($root) + '[\\/]?'
$counts = @{}
foreach ($line in $raw) {
    if ($line -notmatch '(TypeError|[A-Za-z]+Unused|[A-Za-z]+): ') { continue }
    $l = $line -replace '\\', '/'
    $l = $l -replace ([regex]::Escape(($root -replace '\\', '/')) + '/?'), ''
    if ($l -notmatch '^src/') { continue }
    $l = $l -replace '\[game/[^\]]*\]', ''
    $l = $l -replace '\(\d+,\d+\)', ''
    $l = $l -replace 'line \d+', 'line N' -replace 'column \d+', 'column N'
    $l = $l -replace '(Cyclic dependencies).*', '$1'
    $l = $l.Trim()
    $counts[$l] = 1 + [int]$counts[$l]
}
if ($counts.Count -eq 0) { Stop-Tooling 'the analyzer produced no diagnostics at all (it normally reports hundreds); something is wrong' }

if ($UpdateBaseline) {
    $counts.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Value)`t$($_.Name)" } | Set-Content $baselinePath -Encoding UTF8
    Write-Host "Baseline written: $($counts.Count) distinct diagnostics -> $baselinePath" -ForegroundColor Green
    exit 0
}
if (-not (Test-Path $baselinePath)) { Stop-Tooling 'no baseline yet: run with -UpdateBaseline on a known-good tree' }

$base = @{}
foreach ($b in Get-Content $baselinePath -Encoding UTF8) {
    $i = $b.IndexOf("`t"); if ($i -lt 1) { continue }
    $base[$b.Substring($i + 1)] = [int]$b.Substring(0, $i)
}
$added = @(); $gone = @()
foreach ($k in $counts.Keys) { if ($counts[$k] -gt [int]$base[$k]) { $added += "  +$($counts[$k] - [int]$base[$k])  $k" } }
foreach ($k in $base.Keys)   { if ($base[$k] -gt [int]$counts[$k]) { $gone  += "  -$($base[$k] - [int]$counts[$k])  $k" } }

if ($gone.Count)  { Write-Host "Improved ($($gone.Count) diagnostics gone or reduced; -UpdateBaseline to lock in):" -ForegroundColor Green; $gone | Select-Object -First 15 | ForEach-Object { Write-Host $_ } }
if ($added.Count) {
    Write-Host "FAIL: $($added.Count) new/increased diagnostics:" -ForegroundColor Red
    $added | Select-Object -First 40 | ForEach-Object { Write-Host $_ }
    exit 1
}
Write-Host 'PASS: build ok, no new analyzer diagnostics.' -ForegroundColor Green
exit 0
