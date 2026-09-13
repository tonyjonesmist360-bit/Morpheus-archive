<#  RUN-ALL.ps1
    The whole of INSTALL-WALKTHROUGH Part 6 and Part 7 file work, in order.
    Parts 1-5 (FXServer, licence key, MariaDB, the txAdmin recipe, the first stock
    boot and your admin principal) are yours - this script cannot do them.

    Run with the server STOPPED:
      powershell -ExecutionPolicy Bypass -File .\setup\RUN-ALL.ps1

    Preview everything without changing a thing:
      powershell -ExecutionPolicy Bypass -File .\setup\RUN-ALL.ps1 -DryRun
#>
param([string]$Base, [string]$DbName = 'outbreak', [string]$DbUser = 'root', [string]$DbPass, [string]$MysqlPath, [switch]$DryRun, [switch]$Force)

. "$PSScriptRoot\_common.ps1"

Write-Host ""
Write-Host "  OUTBREAK - full setup (Parts 6 and 7)" -ForegroundColor White
Write-Host "  ------------------------------------" -ForegroundColor White

$baseResolved = Resolve-Base -Base $Base
Write-Host "  base: $baseResolved"
Write-Host "  pack: $(Get-PackRoot)"
if ($DryRun) { Write-Host "  MODE: DRY RUN - nothing will be changed" -ForegroundColor Yellow }
Write-Host ""

if (-not $DryRun -and -not $Force) {
    Write-Host "  This will modify your live server tree:" -ForegroundColor Yellow
    Write-Host "    1. move 9 resources into resources\[disabled] and comment 3 npwd lines"
    Write-Host "    2. copy the 3 outbreak resource groups in"
    Write-Host "    3. apply migrations 001-007 to the '$DbName' database"
    Write-Host "    4. edit ox_inventory items.lua and qbx_core jobs.lua"
    Write-Host "    5. append the start order to server.cfg"
    Write-Host ""
    Write-Host "  Everything it touches is backed up first. The server must be STOPPED." -ForegroundColor Yellow
    $a = Read-Host "  Continue? (yes/no)"
    if ($a -ne 'yes') { Write-Host "  Aborted."; exit 1 }
}

$common = @{ Base = $baseResolved }
if ($DryRun) { $common['DryRun'] = $true }

& "$PSScriptRoot\01-disable-competing.ps1" @common
& "$PSScriptRoot\02-copy-resources.ps1"    @common

$dbArgs = @{ DbName = $DbName; DbUser = $DbUser }
if ($DbPass)    { $dbArgs['DbPass']    = $DbPass }
if ($MysqlPath) { $dbArgs['MysqlPath'] = $MysqlPath }
if ($DryRun)    { $dbArgs['DryRun']    = $true }
& "$PSScriptRoot\03-apply-migrations.ps1" @dbArgs

$pArgs = $common.Clone()
if ($Force) { $pArgs['Force'] = $true }
& "$PSScriptRoot\04-paste-ins.ps1"  @pArgs
& "$PSScriptRoot\05-append-cfg.ps1" @common

Write-Host ""
Write-Host "  ------------------------------------" -ForegroundColor White
Write-Host "  Setup finished. Verifying..." -ForegroundColor White
$vArgs = @{ Base = $baseResolved; DbName = $DbName; DbUser = $DbUser }
if ($DbPass) { $vArgs['DbPass'] = $DbPass } else { $vArgs['SkipDb'] = $true }
& "$PSScriptRoot\00-preflight.ps1" @vArgs

Write-Host ""
Write-Host "  Next:" -ForegroundColor White
Write-Host "    1. Start the server in txAdmin, watch the live console"
Write-Host "    2. connect localhost, F8 open"
Write-Host "    3. SMOKE-SCRIPT.md section 1 FIRST: /ob_animcheck, /ob_models, /ob_walk"
Write-Host ""
