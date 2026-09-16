<#  03-apply-migrations.ps1
    INSTALL-WALKTHROUGH Part 7.3. Applies sql\migrations\001..008 in order.
    Every statement is CREATE TABLE IF NOT EXISTS - safe to re-run.
#>
param(
    [string]$DbName = 'outbreak',
    [string]$DbUser = 'root',
    [string]$DbPass,
    [string]$MysqlPath,
    [switch]$DryRun
)

. "$PSScriptRoot\_common.ps1"
$pack = Get-PackRoot
$migrations = Join-Path $pack 'sql\migrations'

Write-Host "OUTBREAK - apply migrations" -ForegroundColor White

$mysql = if ($MysqlPath) { $MysqlPath } else { Find-MysqlClient }
if (-not $mysql) { throw "No mariadb.exe/mysql.exe found. Pass -MysqlPath 'C:\Program Files\MariaDB 11.8\bin\mariadb.exe'." }
Ok "client: $mysql"

if (-not $DbPass) {
    $sec = Read-Host "MariaDB password for '$DbUser'" -AsSecureString
    $DbPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
              [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}

function Invoke-Sql {
    param([string]$Sql)
    $out = & $mysql "-u$DbUser" "-p$DbPass" "-N" "-B" "-e" $Sql 2>&1
    if ($LASTEXITCODE -ne 0) { throw "mysql failed: $out" }
    return $out
}

Step "Connection"
Invoke-Sql "SELECT 1;" | Out-Null
Ok "connected"

Step "Database '$DbName'"
$exists = Invoke-Sql "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='$DbName';"
if (($exists | Select-Object -Last 1).ToString().Trim() -eq '0') {
    if ($DryRun) { Note "would create database $DbName" }
    else { Invoke-Sql "CREATE DATABASE ``$DbName`` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" | Out-Null; Ok "created $DbName" }
} else { Ok "$DbName exists" }

Step "Migrations"
foreach ($f in $script:MigrationFiles) {
    $path = Join-Path $migrations $f
    if (-not (Test-FileExists $path)) { Bad "missing: $path"; continue }
    if ($DryRun) { Note "would apply $f"; continue }
    $sql = Get-Content -LiteralPath $path -Raw
    $out = & $mysql "-u$DbUser" "-p$DbPass" $DbName "-e" $sql 2>&1
    if ($LASTEXITCODE -ne 0) { Bad "$f FAILED: $out" } else { Ok "$f applied" }
}

if (-not $DryRun) {
    Step "Verify"
    $n = (Invoke-Sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DbName' AND table_name LIKE 'outbreak\_%';" |
          Select-Object -Last 1).ToString().Trim()
    if ($n -eq '24') { Ok "24 outbreak_ tables present" } else { Bad "$n outbreak_ tables, expected 24" }
}

Write-Host ""
Write-Host "Done." -ForegroundColor White
