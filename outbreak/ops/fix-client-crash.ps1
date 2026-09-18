<#  ops/fix-client-crash.ps1 - INIT_SESSION / CExtraContentWrapper crash on connect (c0000005)
    Does the three things that can be scripted, MOVING things aside (never deleting):
      1. FiveM cache -> moved to %LOCALAPPDATA%\FiveM\aside_<stamp>\   (FiveM rebuilds it)
      2. server.cfg: sv_enforceGameBuild <n> -> -Build (default 2944), backed up as server.cfg.bak.<stamp>
      3. GTA V "mods" folder -> moved to mods_aside_<stamp> (only if one exists)
    Verifying game files must be done in the Rockstar Launcher / Steam by hand.
      powershell -ExecutionPolicy Bypass -File .\ops\fix-client-crash.ps1            # preview
      powershell -ExecutionPolicy Bypass -File .\ops\fix-client-crash.ps1 -Apply     # do it
      -Build 3258 puts the build back once the game files are verified.
#>
param([switch]$Apply, [int]$Build = 2944, [string]$Cfg = 'C:\Outbreak\txData\server.cfg')
function Ok($t){ Write-Host "   [ ok ] $t" -ForegroundColor Green }
function Note($t){ Write-Host "   [ .. ] $t" -ForegroundColor Gray }
function Warn($t){ Write-Host "   [ !! ] $t" -ForegroundColor Yellow }
$stamp = Get-Date -Format 'yyyyMMdd_HHmm'
if (-not $Apply) { Warn "PREVIEW - add -Apply to do it" }
if (Get-Process FiveM* -ErrorAction SilentlyContinue) { Warn "FiveM is running. Close it first, then run this again."; if ($Apply) { exit 1 } }

# 1. cache
$data = Join-Path $env:LOCALAPPDATA 'FiveM\FiveM.app\data'
$aside = Join-Path $env:LOCALAPPDATA "FiveM\aside_$stamp"
$targets = @()
if (Test-Path -LiteralPath (Join-Path $data 'cache')) { $targets += (Join-Path $data 'cache') }
$targets += Get-ChildItem -LiteralPath $data -Directory -Filter 'server-cache*' -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
if ($targets.Count -eq 0) { Note "no FiveM cache folders found under $data" }
foreach ($t in $targets) {
    if ($Apply) { New-Item -ItemType Directory -Path $aside -Force | Out-Null; Move-Item -LiteralPath $t -Destination (Join-Path $aside (Split-Path $t -Leaf)) -Force; Ok "moved aside: $t" }
    else { Note "would move aside: $t" }
}

# 2. game build
if (Test-Path -LiteralPath $Cfg) {
    $lines = @(Get-Content -LiteralPath $Cfg)
    $hit = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*(set\s+|setr\s+)?sv_enforceGameBuild\s+(\S+)') { $hit = $i } }
    if ($hit -lt 0) { Note "no sv_enforceGameBuild line in $Cfg (the server uses the client's build); nothing to change" }
    else {
        Note "$($Cfg):$($hit+1)  $($lines[$hit])  ->  sv_enforceGameBuild $Build"
        if ($Apply) {
            Copy-Item -LiteralPath $Cfg -Destination "$Cfg.bak.$stamp" -Force
            $lines[$hit] = ($lines[$hit] -replace 'sv_enforceGameBuild\s+\S+', "sv_enforceGameBuild $Build")
            [IO.File]::WriteAllLines($Cfg, $lines, (New-Object Text.UTF8Encoding($false)))
            Ok "server.cfg updated (backup: $Cfg.bak.$stamp). Restart the server."
        }
    }
} else { Warn "server.cfg not found at $Cfg (pass -Cfg)" }

# 3. mods folder
$gta = $null
foreach ($k in 'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto V','HKLM:\SOFTWARE\Rockstar Games\Grand Theft Auto V') {
    try { $p = (Get-ItemProperty -Path $k -ErrorAction Stop).InstallFolder; if ($p -and (Test-Path -LiteralPath $p)) { $gta = $p; break } } catch {}
}
if (-not $gta) { foreach ($c in 'C:\Program Files\Rockstar Games\Grand Theft Auto V','C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto V','C:\Program Files\Epic Games\GTAV') { if (Test-Path -LiteralPath $c) { $gta = $c; break } } }
if ($gta) {
    $mods = Join-Path $gta 'mods'
    if (Test-Path -LiteralPath $mods) { if ($Apply) { Move-Item -LiteralPath $mods -Destination (Join-Path $gta "mods_aside_$stamp") -Force; Ok "mods folder moved aside" } else { Note "would move aside: $mods" } }
    else { Note "no mods folder in $gta" }
} else { Note "GTA V install folder not found; skip the mods step (or check by hand)" }
Write-Host ""
Ok "Now: verify game files in the Rockstar Launcher (Settings -> GTA V -> Verify integrity) or Steam, start the server from the launcher, reconnect."
