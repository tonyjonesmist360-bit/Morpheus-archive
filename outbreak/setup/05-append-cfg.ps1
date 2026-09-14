<#  05-append-cfg.ps1
    INSTALL-WALKTHROUGH Part 7.5. Appends server.cfg.additions to the END of the
    live server.cfg, after every recipe exec and ensure. Marker-guarded.
#>
param([string]$Base, [switch]$DryRun)

. "$PSScriptRoot\_common.ps1"
$pack = Get-PackRoot
$baseResolved = Resolve-Base -Base $Base
$cfg = Join-Path $baseResolved 'server.cfg'
$add = Join-Path $pack 'server.cfg.additions'

Write-Host "OUTBREAK - append start order to server.cfg" -ForegroundColor White
if ($DryRun) { Warn "DRY RUN - nothing will be changed" }

if (-not (Test-FileExists $cfg)) { throw "server.cfg not found at $cfg" }
if (-not (Test-FileExists $add)) { throw "server.cfg.additions not found at $add" }

Step "Current state"
$current = Get-Content -LiteralPath $cfg -Raw
if ($current -match 'OUTBREAK PACK') {
    Ok "additions already present - nothing appended"
    Warn "this script only APPENDS. If the pack has been upgraded since that block"
    Warn "was written, its new ensure lines are NOT live. Run 07-update-cfg.ps1 to"
    Warn "replace the block, or diff it by hand."
} else {
    $addLines = @(Get-Content -LiteralPath $add)
    Note "appending $($addLines.Count) lines"
    if ($DryRun) { Note "would append to $cfg" }
    else {
        Backup-File -Path $cfg | Out-Null
        Add-TextNoBom -Path $cfg -Lines @('')
        Add-TextNoBom -Path $cfg -Lines $addLines
        Ok "appended"
    }
}

Step "Order check"
$lines = @(Get-Content -LiteralPath $cfg)
$qbx = -1; $ob = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($qbx -lt 0 -and $lines[$i] -match '^\s*ensure\s+\[qbx\]')      { $qbx = $i }
    if ($ob  -lt 0 -and $lines[$i] -match '^\s*ensure\s+outbreak_core') { $ob  = $i }
}
if ($qbx -lt 0) { Warn "no 'ensure [qbx]' line found - unusual recipe?" }
if ($ob  -lt 0) { Bad "no 'ensure outbreak_core' line found" }
if ($qbx -ge 0 -and $ob -ge 0) {
    if ($qbx -lt $ob) { Ok "ensure [qbx] (line $($qbx+1)) comes before ensure outbreak_core (line $($ob+1))" }
    else { Bad "ORDER WRONG: outbreak_core (line $($ob+1)) starts before [qbx] (line $($qbx+1)). The additions must be at the END of server.cfg." }
}

Step "Held groups still held"
$raw = Get-Content -LiteralPath $cfg -Raw
foreach ($held in @('outbreak_vehicles','outbreak_intel','outbreak_opportunities','outbreak_craft','outbreak_military','outbreak_stations','outbreak_raiders','outbreak_camps','outbreak_broadcast','outbreak_map')) {
    if ($raw -match "(?m)^\s*ensure\s+$held\s*$") { Warn "$held is ENSURED - it should stay commented until smoke 0-11 pass" }
}
Ok "checked"

Write-Host ""
Write-Host "Done. Next: start the server in txAdmin." -ForegroundColor White
