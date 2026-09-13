<#  01-disable-competing.ps1
    INSTALL-WALKTHROUGH Part 6. Moves the nine competing resources into
    resources\[disabled]\ and comments out the three npwd ensure lines.
    Nothing is deleted. Reversible with -Revert.
    Run with the server STOPPED.
#>
param([string]$Base, [switch]$DryRun, [switch]$Revert)

. "$PSScriptRoot\_common.ps1"
$baseResolved = Resolve-Base -Base $Base
$res = Join-Path $baseResolved 'resources'
$disabled = Join-Path $res '[disabled]'

Write-Host "OUTBREAK - disable competing resources" -ForegroundColor White
Write-Host "base: $baseResolved"
if ($DryRun) { Warn "DRY RUN - nothing will be changed" }

Step "Graveyard folder"
if (Test-DirExists $disabled) { Ok "[disabled] already exists" }
elseif ($DryRun) { Note "would create $disabled" }
else { [System.IO.Directory]::CreateDirectory($disabled) | Out-Null; Ok "created [disabled]" }

Step $(if ($Revert) { "Restoring nine resources" } else { "Moving nine resources out of the ensured groups" })
foreach ($r in $script:CompetingResources) {
    $live     = Join-Path $res "$($r.Group)\$($r.Name)"
    $parked   = Join-Path $disabled $r.Name

    if ($Revert) {
        if (Test-DirExists $parked) {
            if ($DryRun) { Note "would restore $($r.Name) -> $($r.Group)" }
            else { Move-Dir -From $parked -To $live; Ok "restored $($r.Name) -> $($r.Group)" }
        } elseif (Test-DirExists $live) { Ok "$($r.Name) already active" }
        else { Warn "$($r.Name) not found in either place" }
        continue
    }

    if (Test-DirExists $parked) { Ok "$($r.Name) already disabled"; continue }
    if (-not (Test-DirExists $live)) { Warn "$($r.Name) not found in $($r.Group) - recipe variant? skipping"; continue }
    if ($DryRun) { Note "would move $($r.Group)\$($r.Name) -> [disabled]   ($($r.Why))"; continue }
    Move-Dir -From $live -To $parked
    Ok "$($r.Name) disabled   ($($r.Why))"
}

Step "npwd ensure lines in server.cfg"
$cfg = Join-Path $baseResolved 'server.cfg'
if (-not (Test-FileExists $cfg)) { throw "server.cfg not found at $cfg" }

$lines = Get-Content -LiteralPath $cfg
$targets = @('ensure [npwd-apps]','ensure qbx_npwd','ensure npwd')
$changed = $false
$out = foreach ($line in $lines) {
    $t = $line.Trim()
    if (-not $Revert -and ($targets -contains $t)) { $changed = $true; "# $line" }
    elseif ($Revert -and $t.StartsWith('# ') -and ($targets -contains $t.Substring(2).Trim())) { $changed = $true; $t.Substring(2) }
    else { $line }
}

if (-not $changed) { Ok "npwd lines already in the desired state" }
elseif ($DryRun) { Note "would rewrite 3 npwd lines in server.cfg" }
else {
    Backup-File -Path $cfg | Out-Null
    Write-TextNoBom -Path $cfg -Lines $out
    Ok $(if ($Revert) { "npwd lines re-enabled" } else { "npwd lines commented out" })
}

Write-Host ""
if ($DryRun) { Write-Host "Dry run complete. Re-run without -DryRun to apply." -ForegroundColor White }
else {
    Write-Host "Done. Next: start the server once and watch for 'dependency not found'." -ForegroundColor White
    Write-Host "Removing qbx_medical / qbx_police can upset other [qbx] job resources." -ForegroundColor Yellow
    Write-Host "Write down every resource name that errors. Do not fix by guessing." -ForegroundColor Yellow
}
