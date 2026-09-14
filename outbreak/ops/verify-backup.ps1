<#  ops/verify-backup.ps1
    Proves the newest backup is restorable-shaped without touching the live database:
      - newest db_*.sql exists, is not tiny, contains CREATE TABLE for outbreak_ tables and INSERTs
      - newest resources_*.zip opens, contains server.cfg and the [outbreak] folders with real files
    -RestoreTest additionally restores the dump into a scratch database (outbreak_restore_test),
    counts the outbreak_ tables, then drops the scratch database. Never touches the live DB.
#>
param([string]$Out = 'C:\Outbreak\backups', [switch]$RestoreTest, [string]$DbUser = 'root', [string]$DbPass)

function Ok($m)  { Write-Host "   [ ok ] $m" -ForegroundColor Green }
function Bad($m) { Write-Host "   [ XX ] $m" -ForegroundColor Red; $script:fail = $true }
function Note($m){ Write-Host "   [ .. ] $m" -ForegroundColor Gray }
$script:fail = $false

Write-Host "OUTBREAK - verify backup in $Out" -ForegroundColor White
if (-not (Test-Path -LiteralPath $Out)) { Bad "backup folder missing: $Out"; exit 1 }

$sql = Get-ChildItem -LiteralPath $Out -Filter 'db_*.sql' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$zip = Get-ChildItem -LiteralPath $Out -Filter 'resources_*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $sql) { Bad "no db_*.sql dump found" } else {
    Note "dump: $($sql.Name) ($([math]::Round($sql.Length/1KB)) KB, $($sql.LastWriteTime))"
    if ($sql.Length -lt 2KB) { Bad "dump is tiny - the mariadb-dump call probably failed (wrong password or DB name?)" }
    $head = Get-Content -LiteralPath $sql.FullName -TotalCount 4000 -ErrorAction SilentlyContinue | Out-String
    $all  = Get-Content -LiteralPath $sql.FullName -Raw
    $tables = ([regex]::Matches($all, 'CREATE TABLE `?(outbreak_[a-z_]+)`?')).Count
    if ($tables -ge 20) { Ok "$tables outbreak_ tables in the dump" } else { Bad "only $tables outbreak_ tables in the dump (expected 23)" }
    if ($all -match 'INSERT INTO') { Ok "dump has data rows" } else { Note "dump has no INSERT rows (empty tables are fine on a fresh server)" }
    if ($head -match 'Access denied|Unknown database') { Bad "dump contains a MariaDB error banner" }
}

if (-not $zip) { Bad "no resources_*.zip found" } else {
    Note "zip: $($zip.Name) ($([math]::Round($zip.Length/1KB)) KB)"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
        $z = [System.IO.Compression.ZipFile]::OpenRead($zip.FullName)
        $names = $z.Entries | ForEach-Object { $_.FullName }
        $z.Dispose()
        if ($names -contains 'server.cfg') { Ok "server.cfg in zip" } else { Bad "server.cfg missing from zip" }
        $ob = @($names | Where-Object { $_ -like '[[]outbreak]/*' -or $_ -like '[[]outbreak]\*' })
        if ($ob.Count -ge 20) { Ok "$($ob.Count) files under [outbreak] in zip" } else { Bad "only $($ob.Count) files under [outbreak] - the bracket-wildcard bug (use -LiteralPath in backup.bat)" }
        $lua = @($names | Where-Object { $_ -like '*.lua' }).Count
        Note "$lua .lua files total"
    } catch { Bad "zip would not open: $($_.Exception.Message)" }
}

if ($RestoreTest -and $sql) {
    . "$PSScriptRoot\..\setup\_common.ps1"
    $mysql = Find-MysqlClient
    if (-not $mysql) { Bad "no mariadb.exe found for the restore test" } else {
        if (-not $DbPass) { $sec = Read-Host "MariaDB password for '$DbUser'" -AsSecureString; $DbPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)) }
        $scratch = 'outbreak_restore_test'
        & $mysql "-u$DbUser" "-p$DbPass" -e "DROP DATABASE IF EXISTS ``$scratch``; CREATE DATABASE ``$scratch``;" 2>&1 | Out-Null
        Get-Content -LiteralPath $sql.FullName -Raw | & $mysql "-u$DbUser" "-p$DbPass" $scratch 2>&1 | Out-Null
        $n = (& $mysql "-u$DbUser" "-p$DbPass" -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$scratch' AND table_name LIKE 'outbreak\_%';" 2>&1 | Select-Object -Last 1).ToString().Trim()
        & $mysql "-u$DbUser" "-p$DbPass" -e "DROP DATABASE ``$scratch``;" 2>&1 | Out-Null
        if ($n -eq '23') { Ok "restore test: 23 outbreak_ tables came back in a scratch database (dropped again)" } else { Bad "restore test: $n tables came back, expected 23" }
    }
}

Write-Host ""
if ($script:fail) { Write-Host "RESULT: FAIL - see [ XX ] lines" -ForegroundColor Red; exit 1 } else { Write-Host "RESULT: PASS - this backup is restorable-shaped" -ForegroundColor Green }
