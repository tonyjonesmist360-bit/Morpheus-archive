<#  02-copy-resources.ps1
    INSTALL-WALKTHROUGH Part 7.1. Copies the three resource groups from the pack
    into the live tree. The pack folder stays the source of truth.
    Safe to re-run - this is also how you deploy a patch.
#>
param([string]$Base, [switch]$DryRun)

. "$PSScriptRoot\_common.ps1"
$pack = Get-PackRoot
$baseResolved = Resolve-Base -Base $Base
$srcRoot = Join-Path $pack 'resources'
$dstRoot = Join-Path $baseResolved 'resources'

Write-Host "OUTBREAK - copy resources into the live tree" -ForegroundColor White
Write-Host "from: $srcRoot"
Write-Host "to:   $dstRoot"
if ($DryRun) { Warn "DRY RUN - nothing will be changed" }

$groups = @('[outbreak]','[outbreak_extended]','[outbreak_progression]')

foreach ($g in $groups) {
    Step $g
    $src = Join-Path $srcRoot $g
    $dst = Join-Path $dstRoot $g

    if (-not (Test-DirExists $src)) { Bad "missing in the pack: $src"; continue }
    $n = @([System.IO.Directory]::GetDirectories($src)).Count

    if ($DryRun) { Note "would copy $n resources -> $dst"; continue }

    # -LiteralPath everywhere: [brackets] are wildcards to PowerShell otherwise.
    if (Test-DirExists $dst) { Note "replacing existing $g" ; Remove-Item -LiteralPath $dst -Recurse -Force }
    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
    $copied = @([System.IO.Directory]::GetDirectories($dst)).Count
    if ($copied -eq $n) { Ok "$copied resources copied" } else { Bad "copied $copied but source has $n" }
}

if (-not $DryRun) {
    Step "Verify the slice"
    $slice = Join-Path $dstRoot '[outbreak]'
    $count = @([System.IO.Directory]::GetDirectories($slice)).Count
    if ($count -eq $script:SliceResourceCount) { Ok "[outbreak] has $count resources (expected $script:SliceResourceCount)" }
    else { Bad "[outbreak] has $count resources, expected $script:SliceResourceCount" }

    # The two pre-boot fixes must be present, or first boot reproduces bugs we already fixed.
    Step "Pre-boot fixes present"
    $spawn = Join-Path $slice 'outbreak_spawn\server\spawn.lua'
    if ((Get-Content -LiteralPath $spawn -Raw) -match 'exports\.qbx_core:SetMoney') { Ok "PB-1 SetMoney fix present" }
    else { Bad "PB-1 MISSING - your pack predates the fix. New characters will get no kit and no story text." }

    $fac = Join-Path $slice 'outbreak_faction\fxmanifest.lua'
    if ((Get-Content -LiteralPath $fac -Raw) -match 'oxmysql') { Ok "PB-4 oxmysql include present" }
    else { Bad "PB-4 MISSING - your pack predates the fix. outbreak_faction will error on every join." }
}

Write-Host ""
Write-Host "Done." -ForegroundColor White
