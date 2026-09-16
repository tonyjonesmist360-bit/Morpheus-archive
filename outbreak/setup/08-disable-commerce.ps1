<#  08-disable-commerce.ps1  (v0.23 - bugfix 2: banks and every other shop-front the recipe ships)
    Finds `ensure <resource>` lines for known commerce resources in every .cfg under the live tree
    and comments them out with an `# OUTBREAK: disabled` prefix. PREVIEW by default; -Apply writes
    (backs up each cfg first). Nothing is deleted, nothing is reordered; un-comment to restore.

      powershell -ExecutionPolicy Bypass -File .\setup\08-disable-commerce.ps1 -Base "C:\Outbreak\txData"
      powershell -ExecutionPolicy Bypass -File .\setup\08-disable-commerce.ps1 -Base "C:\Outbreak\txData" -Apply

    Add names with -Extra 'name1','name2' (e.g. whatever the recipe's bank resource is actually called;
    `Get-ChildItem C:\Outbreak\txData\resources -Recurse -Directory -Filter "*bank*"` tells you).
#>
param([string]$Base, [switch]$Apply, [string[]]$Extra = @())
. "$PSScriptRoot\_common.ps1"
$baseResolved = Resolve-Base -Base $Base
$names = @('qbx_bank','qb-banking','Renewed-Banking','okokBanking','ps-banking','qbx_pawnshop','qbx_vehicleshop','qb-vehicleshop','qbx_clothing','qb-clothing','qbx_shops','qb-shops','qbx_barbershop','qbx_tattooshop','qbx_ammunation','qb-weapons-shop','qbx_vehiclekeys') + $Extra
Write-Host "OUTBREAK - disable commerce resources" -ForegroundColor White
if (-not $Apply) { Warn "PREVIEW - nothing will be changed. Add -Apply to write." }
$cfgs = Get-ChildItem -LiteralPath $baseResolved -Recurse -Filter *.cfg -File -ErrorAction SilentlyContinue
$hits = 0
foreach ($cfg in $cfgs) {
    $lines = @(Get-Content -LiteralPath $cfg.FullName)
    $changed = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if ($l -match '^\s*(ensure|start)\s+(\S+)\s*$') {
            $r = $Matches[2]
            if ($names -contains $r) {
                $hits++
                Note "$($cfg.Name):$($i+1)  $l"
                $lines[$i] = "# OUTBREAK: disabled (no commerce) " + $l
                $changed = $true
            }
        }
    }
    if ($changed -and $Apply) { Backup-File -Path $cfg.FullName | Out-Null; Write-TextNoBom -Path $cfg.FullName -Lines $lines; Ok "written: $($cfg.FullName)" }
}
if ($hits -eq 0) { Ok "no commerce ensure lines found (nothing to do). Banks may be called something else: see the header." }
elseif (-not $Apply) { Warn "$hits line(s) would be commented out. Re-run with -Apply." }
else { Ok "$hits line(s) disabled. Restart the server." }
