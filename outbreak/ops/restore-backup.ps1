<#  ops/restore-backup.ps1  (v0.23 - infra 5: one-command rollback)
    Lists backups, or restores one date: database from db_<stamp>.sql, our resources + server.cfg from
    resources_<stamp>.zip. NOTHING is deleted: the current resources and server.cfg are MOVED ASIDE to
    <OUT>\aside_<now>\ first, so a restore can itself be undone by moving them back.
    The server must be STOPPED (txAdmin -> Stop) before -Apply.

      powershell -ExecutionPolicy Bypass -File .\ops\restore-backup.ps1                       # list
      powershell -ExecutionPolicy Bypass -File .\ops\restore-backup.ps1 -Date 20260916        # preview that day (latest stamp)
      powershell -ExecutionPolicy Bypass -File .\ops\restore-backup.ps1 -Date 20260916 -Apply # do it
      powershell -ExecutionPolicy Bypass -File .\ops\restore-backup.ps1 -Stamp 20260916_0400 -Apply -DbPass yourpass

    -SkipDb restores files only. -SkipFiles restores the database only. Weekly: run verify-backup.ps1 -RestoreTest.
#>
param([string]$Date, [string]$Stamp, [switch]$Apply, [switch]$SkipDb, [switch]$SkipFiles,
      [string]$Out = 'C:\Outbreak\backups', [string]$Server = 'C:\Outbreak\txData', [string]$Db = 'QboxProject_A70B55', [string]$DbPass)

function Ok($t){ Write-Host "   [ ok ] $t" -ForegroundColor Green }
function Note($t){ Write-Host "   [ .. ] $t" -ForegroundColor Gray }
function Warn($t){ Write-Host "   [ !! ] $t" -ForegroundColor Yellow }
function Bad($t){ Write-Host "   [FAIL] $t" -ForegroundColor Red }

if (-not (Test-Path -LiteralPath $Out)) { Bad "backup folder not found: $Out"; exit 1 }
$dumps = Get-ChildItem -LiteralPath $Out -Filter 'db_*.sql' | Sort-Object Name
$zips  = Get-ChildItem -LiteralPath $Out -Filter 'resources_*.zip' | Sort-Object Name
if (-not $Date -and -not $Stamp) {
    Write-Host "Backups in $Out" -ForegroundColor White
    $stamps = @($dumps | ForEach-Object { $_.Name -replace '^db_','' -replace '\.sql$','' }) + @($zips | ForEach-Object { $_.Name -replace '^resources_','' -replace '\.zip$','' }) | Sort-Object -Unique
    foreach ($s in $stamps) {
        $d = Test-Path -LiteralPath (Join-Path $Out "db_$s.sql"); $z = Test-Path -LiteralPath (Join-Path $Out "resources_$s.zip")
        Note ("{0}   db:{1}  files:{2}" -f $s, ($(if($d){'yes'}else{' no'})), ($(if($z){'yes'}else{' no'})))
    }
    Write-Host "  restore with: -Date YYYYMMDD [-Apply]  or  -Stamp YYYYMMDD_HHMM [-Apply]"
    exit 0
}
if (-not $Stamp) {
    $cand = @($dumps + $zips | ForEach-Object { $_.Name -replace '^(db_|resources_)','' -replace '\.(sql|zip)$','' } | Where-Object { $_ -like "$Date*" } | Sort-Object -Unique)
    if ($cand.Count -eq 0) { Bad "no backup for $Date"; exit 1 }
    $Stamp = $cand[-1]; Note "latest stamp for ${Date}: $Stamp"
}
$dump = Join-Path $Out "db_$Stamp.sql"; $zip = Join-Path $Out "resources_$Stamp.zip"
if (-not $SkipDb -and -not (Test-Path -LiteralPath $dump)) { Bad "missing $dump (use -SkipDb to restore files only)"; exit 1 }
if (-not $SkipFiles -and -not (Test-Path -LiteralPath $zip)) { Bad "missing $zip (use -SkipFiles to restore the database only)"; exit 1 }
if (-not $Apply) { Warn "PREVIEW. Would restore stamp $Stamp"; if (-not $SkipDb) { Note "database $Db <- $dump" }; if (-not $SkipFiles) { Note "files: move aside $Server\resources\[outbreak*] + server.cfg, then expand $zip" }; Write-Host "  add -Apply (server STOPPED first)"; exit 0 }

$aside = Join-Path $Out ("aside_" + (Get-Date -Format 'yyyyMMdd_HHmm'))
if (-not $SkipFiles) {
    New-Item -ItemType Directory -Path $aside -Force | Out-Null
    foreach ($n in '[outbreak]','[outbreak_extended]','[outbreak_progression]') {
        $p = Join-Path (Join-Path $Server 'resources') $n
        if (Test-Path -LiteralPath $p) { Move-Item -LiteralPath $p -Destination (Join-Path $aside $n) -Force; Note "moved aside $n" }
    }
    $cfg = Join-Path $Server 'server.cfg'
    if (Test-Path -LiteralPath $cfg) { Copy-Item -LiteralPath $cfg -Destination (Join-Path $aside 'server.cfg') -Force; Note "copied aside server.cfg" }
    $tmp = Join-Path $aside '_expand'
    Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
    foreach ($n in '[outbreak]','[outbreak_extended]','[outbreak_progression]') {
        $src = Get-ChildItem -LiteralPath $tmp -Recurse -Directory | Where-Object { $_.Name -eq $n } | Select-Object -First 1
        if ($src) { Copy-Item -LiteralPath $src.FullName -Destination (Join-Path (Join-Path $Server 'resources') $n) -Recurse -Force; Ok "restored $n" } else { Warn "$n not in the zip" }
    }
    $scfg = Get-ChildItem -LiteralPath $tmp -Recurse -File -Filter 'server.cfg' | Select-Object -First 1
    if ($scfg) { Copy-Item -LiteralPath $scfg.FullName -Destination $cfg -Force; Ok "restored server.cfg" }
    Ok "previous files are in $aside (move them back to undo)"
}
if (-not $SkipDb) {
    $cli = Get-ChildItem 'C:\Program Files\MariaDB *\bin\mariadb.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cli) { $cli = Get-ChildItem 'C:\Program Files\MariaDB *\bin\mysql.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if (-not $cli) { Bad "mariadb.exe not found under C:\Program Files\MariaDB *"; exit 1 }
    if (-not $DbPass) { $DbPass = Read-Host "MariaDB root password" }
    $pre = Join-Path $aside ("db_before_restore.sql"); New-Item -ItemType Directory -Path $aside -Force | Out-Null
    $dumpExe = $cli.FullName -replace 'mariadb\.exe$','mariadb-dump.exe' -replace 'mysql\.exe$','mysqldump.exe'
    if (Test-Path -LiteralPath $dumpExe) { & $dumpExe -u root "-p$DbPass" $Db | Out-File -LiteralPath $pre -Encoding utf8; Note "current database dumped to $pre first" }
    cmd /c "`"$($cli.FullName)`" -u root -p$DbPass $Db < `"$dump`""
    if ($LASTEXITCODE -eq 0) { Ok "database $Db restored from $dump" } else { Bad "database restore reported exit code $LASTEXITCODE" }
}
Ok "done. Start the server from the launcher."
