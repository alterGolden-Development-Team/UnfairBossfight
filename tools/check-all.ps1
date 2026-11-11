<#
  check-all.ps1 - gate for the whole Unfair Bossfight repo.

    powershell -ExecutionPolicy Bypass -File tools\check-all.ps1            # everything
    powershell -ExecutionPolicy Bypass -File tools\check-all.ps1 -SkipBoss  # lobby + shared only

  1. alterGolden Bossfight/tools/check.ps1  (boss build + analyzer diff against its baseline + mirror pairs)
  2. lobby: `rojo build` must succeed.
  3. lobby + shared: `luau-lsp analyze` must report NO diagnostics at all. The lobby is new code, so unlike the boss
     project it has no baseline of known problems to hide behind.
  Exit code: 0 = pass, 1 = regression, 2 = tooling problem.
#>
param([switch]$SkipBoss)   # lobby/shared only (the boss gate takes a couple of minutes)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$tmp = Join-Path ([IO.Path]::GetTempPath()) 'unfairBossfightCheck'
New-Item -ItemType Directory -Force $tmp | Out-Null

function Stop-Tooling($msg) { Write-Host "TOOLING: $msg" -ForegroundColor Red; exit 2 }

# --- 1. boss ----------------------------------------------------------------------------------------------
if (-not $SkipBoss) {
    Write-Host '=== boss ===' -ForegroundColor Cyan
    & powershell -ExecutionPolicy Bypass -File (Join-Path $root 'alterGolden Bossfight\tools\check.ps1')
    if ($LASTEXITCODE -ne 0) { Write-Host 'FAIL: boss check failed' -ForegroundColor Red; exit $LASTEXITCODE }
}

# --- locate tools (same lookup as alterGolden Bossfight/tools/check.ps1) ------------------------------------------------------
if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) { Stop-Tooling 'rojo is not on PATH' }
$lsp = Get-ChildItem "$env:USERPROFILE\.vscode\extensions\johnnymorganz.luau-lsp-*\bin\server.exe" -ErrorAction SilentlyContinue |
    Sort-Object { $_.Directory.Parent.Name } | Select-Object -Last 1
if (-not $lsp) { Stop-Tooling 'luau-lsp not found: install the "Luau Language Server" VS Code extension' }
$defs = Get-ChildItem "$env:APPDATA\Code\User\globalStorage\johnnymorganz.luau-lsp\globalTypes*.d.luau" -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (-not $defs) { Stop-Tooling 'Roblox type definitions not found: open the project once in VS Code so luau-lsp downloads them' }

# --- 2. lobby build ---------------------------------------------------------------------------------------
Write-Host '=== lobby ===' -ForegroundColor Cyan
Write-Host '[1/2] rojo build ...'
$lobbyProject = Join-Path $root 'lobby\default.project.json'
& rojo build $lobbyProject -o (Join-Path $tmp 'lobby.rbxl') | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host 'FAIL: lobby rojo build failed' -ForegroundColor Red; exit 1 }

# --- 3. lobby + shared analyzer, zero tolerance -----------------------------------------------------------
Write-Host '[2/2] luau-lsp analyze (lobby + shared) ...'
$sourcemap = Join-Path $tmp 'lobby-sourcemap.json'
& rojo sourcemap $lobbyProject -o $sourcemap | Out-Null
Set-Location (Join-Path $root 'lobby')
$ErrorActionPreference = 'Continue'   # Windows PowerShell 5.1 turns a native command's stderr into errors
$raw = & $lsp.FullName analyze "--definitions=$($defs.FullName)" "--sourcemap=$sourcemap" --no-strict-dm-types src ..\shared 2>&1 |
    ForEach-Object { "$_" }
$ErrorActionPreference = 'Stop'
$problems = @($raw | Where-Object { $_ -match '(TypeError|[A-Za-z]+Unused|SyntaxError|[A-Za-z]+): ' -and $_ -match '[\\/](src|shared)[\\/]' -and
    # the boss code the lobby mounts (class kits for the showroom) is gated by the boss check and its baseline, not here
    $_ -notmatch '[\\/]alterGolden Bossfight[\\/]src[\\/]' })
if ($problems.Count) {
    Write-Host "FAIL: $($problems.Count) analyzer diagnostics in lobby/shared:" -ForegroundColor Red
    $problems | Select-Object -First 40 | ForEach-Object { Write-Host "  $_" }
    exit 1
}

# --- 4. the side places (glitched, tutorial): build + zero-tolerance analyze -----------------------------------
foreach ($place in @('glitched', 'tutorial')) {
    Write-Host "=== $place ===" -ForegroundColor Cyan
    $project = Join-Path $root "$place\default.project.json"
    $ErrorActionPreference = 'Continue'
    & rojo build $project -o (Join-Path $tmp "$place.rbxl") | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: $place rojo build failed" -ForegroundColor Red; exit 1 }
    $map = Join-Path $tmp "$place-sourcemap.json"
    & rojo sourcemap $project -o $map | Out-Null
    Set-Location (Join-Path $root $place)
    $raw = & $lsp.FullName analyze "--definitions=$($defs.FullName)" "--sourcemap=$map" --no-strict-dm-types src map 2>&1 | ForEach-Object { "$_" }
    $ErrorActionPreference = 'Stop'
    $found = @($raw | Where-Object { $_ -match '(TypeError|[A-Za-z]+Unused|SyntaxError|[A-Za-z]+): ' -and $_ -match '[\\/](src|map)[\\/]' })
    if ($found.Count) {
        Write-Host "FAIL: $($found.Count) analyzer diagnostics in ${place}:" -ForegroundColor Red
        $found | Select-Object -First 40 | ForEach-Object { Write-Host "  $_" }
        exit 1
    }
}
Write-Host 'PASS: lobby, glitched and tutorial build and analyze clean (alterGolden Bossfight gate included unless -SkipBoss).' -ForegroundColor Green
exit 0
