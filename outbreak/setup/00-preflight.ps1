<#  00-preflight.ps1
    Read-only. Answers the five "where am I?" questions. Changes nothing.
    Usage: powershell -ExecutionPolicy Bypass -File .\setup\00-preflight.ps1
#>
param([string]$Base, [string]$DbName = 'outbreak', [string]$DbUser = 'root', [string]$DbPass, [switch]$SkipDb)

. "$PSScriptRoot\_common.ps1"
$pack = Get-PackRoot

Write-Host "OUTBREAK PREFLIGHT (read-only)" -ForegroundColor White
Write-Host "pack: $pack"

Step "1. FXServer"
if (Test-FileExists 'C:\FXServer\server\FXServer.exe') { Ok "C:\FXServer\server\FXServer.exe" }
else { Bad "FXServer.exe not found -> INSTALL-WALKTHROUGH Part 1" }

$baseResolved = $null
try { $baseResolved = Resolve-Base -Base $Base; Ok "base: $baseResolved" }
catch { Bad $_.Exception.Message }

Step "2. MariaDB"
$svc = Get-Service | Where-Object { $_.Name -like '*maria*' -or $_.Name -like '*mysql*' }
if ($svc) { $svc | ForEach-Object { if ($_.Status -eq 'Running') { Ok "$($_.Name): Running" } else { Warn "$($_.Name): $($_.Status)" } } }
else { Bad "No MariaDB/MySQL service -> INSTALL-WALKTHROUGH Part 3 (standalone, not XAMPP)" }

$mysql = Find-MysqlClient
if ($mysql) { Ok "client: $mysql" } else { Warn "no mariadb.exe/mysql.exe found; 03-apply-migrations needs -MysqlPath" }

if ($mysql -and -not $SkipDb) {
    if (-not $DbPass) {
        $sec = Read-Host "   MariaDB password for '$DbUser' (blank to skip the database check)" -AsSecureString
        $DbPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
    }
}
if ($mysql -and -not $SkipDb -and $DbPass) {
    $tables = & $mysql "-u$DbUser" "-p$DbPass" "-N" "-B" "-e" "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DbName' AND table_name LIKE 'outbreak\_%';" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $n = ($tables | Select-Object -Last 1).ToString().Trim()
        if ($n -eq '21') { Ok "database '$DbName': all 21 outbreak_ tables present" }
        elseif ($n -eq '0') { Warn "database '$DbName' reachable but 0 outbreak_ tables -> run 03-apply-migrations.ps1" }
        else { Warn "database '$DbName': $n of 21 outbreak_ tables -> re-run 03-apply-migrations.ps1 (idempotent)" }
    } else { Bad "could not query '$DbName': $tables" }
} elseif ($mysql) { Note "database check skipped" }

if ($baseResolved) {
    $res = Join-Path $baseResolved 'resources'

    Step "3. Pack resources in the live tree"
    foreach ($g in @('[outbreak]','[outbreak_extended]','[outbreak_progression]')) {
        $p = Join-Path $res $g
        if (Test-DirExists $p) {
            $n = @([System.IO.Directory]::GetDirectories($p)).Count
            if ($g -eq '[outbreak]' -and $n -ne $script:SliceResourceCount) { Warn "$g present but $n folders (expected $script:SliceResourceCount)" }
            else { Ok "$g present ($n resources)" }
        } else { Bad "$g NOT copied -> 02-copy-resources.ps1" }
    }

    Step "4. Paste-ins"
    $items = Join-Path $res '[ox]\ox_inventory\data\items.lua'
    if (Test-FileExists $items) {
        if ((Get-Content -LiteralPath $items -Raw) -match 'canned_beans') { Ok "ox_inventory items.lua: outbreak items present" }
        else { Bad "ox_inventory items.lua: outbreak items MISSING -> 04-paste-ins.ps1" }
    } else { Bad "ox_inventory items.lua not found at $items" }

    $jobs = Join-Path $res '[qbx]\qbx_core\shared\jobs.lua'
    if (Test-FileExists $jobs) {
        if ((Get-Content -LiteralPath $jobs -Raw) -match 'Military Remnant') { Ok "qbx_core jobs.lua: military/raider present" }
        else { Bad "qbx_core jobs.lua: still stock -> 04-paste-ins.ps1" }
    } else { Bad "qbx_core jobs.lua not found at $jobs" }

    $weapons = Join-Path $res '[ox]\ox_inventory\data\weapons.lua'
    if (Test-FileExists $weapons) { Note "weapons.lua present (weapons_snippet is optional for first boot - it ships commented out)" }

    Step "5. server.cfg and disabled resources"
    $cfg = Join-Path $baseResolved 'server.cfg'
    if (Test-FileExists $cfg) {
        $c = Get-Content -LiteralPath $cfg -Raw
        if ($c -match 'OUTBREAK PACK') { Ok "server.cfg: additions appended" } else { Bad "server.cfg: additions NOT appended -> 05-append-cfg.ps1" }
        if ($c -match '(?m)^\s*ensure\s+npwd\s*$') { Bad "server.cfg: 'ensure npwd' still active -> 01-disable-competing.ps1" } else { Ok "server.cfg: npwd lines commented" }
    } else { Bad "server.cfg not found at $cfg" }

    foreach ($r in $script:CompetingResources) {
        $live     = Join-Path $res "$($r.Group)\$($r.Name)"
        $disabled = Join-Path $res "[disabled]\$($r.Name)"
        if (Test-DirExists $live)          { Bad  "$($r.Name) still ACTIVE in $($r.Group) - $($r.Why)" }
        elseif (Test-DirExists $disabled)  { Ok   "$($r.Name) disabled" }
        else                               { Warn "$($r.Name) not found in either place (recipe variant?)" }
    }
}

Write-Host ""
Write-Host "Preflight done. Nothing was changed." -ForegroundColor White
