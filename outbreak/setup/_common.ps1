# _common.ps1 - shared helpers. Dot-sourced by every setup script.
# ASCII only on purpose: avoids encoding damage under Windows PowerShell 5.1.

$ErrorActionPreference = 'Stop'

function Step($m) { Write-Host ""; Write-Host "== $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "   [ ok ] $m" -ForegroundColor Green }
function Note($m) { Write-Host "   [ .. ] $m" -ForegroundColor Gray }
function Warn($m) { Write-Host "   [ !! ] $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "   [ XX ] $m" -ForegroundColor Red }

# The pack root is the parent of the setup folder this script lives in.
function Get-PackRoot { return (Split-Path -Parent $PSScriptRoot) }

# Find C:\FXServer\txData\<name>.base, or validate one the user passed in.
function Resolve-Base {
    param([string]$Base)

    if ($Base) {
        if (-not (Test-Path -LiteralPath $Base)) { throw "Base path not found: $Base" }
        return (Resolve-Path -LiteralPath $Base).Path
    }

    $txData = 'C:\FXServer\txData'
    if (-not (Test-Path -LiteralPath $txData)) {
        throw "No $txData folder. Finish INSTALL-WALKTHROUGH Part 4 first, or pass -Base <path>."
    }

    $bases = @(Get-ChildItem -LiteralPath $txData -Directory | Where-Object { $_.Name.EndsWith('.base') })

    if ($bases.Count -eq 0) { throw "No *.base folder under $txData. Finish INSTALL-WALKTHROUGH Part 4 (the txAdmin recipe) first." }
    if ($bases.Count -gt 1) {
        Bad "More than one .base folder found. Pass the one you want with -Base:"
        $bases | ForEach-Object { Write-Host "        $($_.FullName)" }
        throw "Ambiguous base folder."
    }
    return $bases[0].FullName
}

# Timestamped backup beside the original. Returns the backup path.
function Backup-File {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Cannot back up, file missing: $Path" }
    $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$Path.$stamp.bak"
    Copy-Item -LiteralPath $Path -Destination $backup -Force
    Note "backup -> $(Split-Path -Leaf $backup)"
    return $backup
}

# Write text as UTF-8 WITHOUT a BOM. Windows PowerShell 5.1's -Encoding UTF8
# emits a BOM, and Lua chokes on it: "unexpected symbol near '<\239>'".
function Write-TextNoBom {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [AllowEmptyCollection()][AllowEmptyString()][AllowNull()][string[]]$Lines = @()
    )
    if ($null -eq $Lines) { $Lines = @() }
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($Path, [string[]]$Lines, $enc)
}

function Add-TextNoBom {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [AllowEmptyCollection()][AllowEmptyString()][AllowNull()][string[]]$Lines = @()
    )
    if ($null -eq $Lines) { $Lines = @() }
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::AppendAllLines($Path, [string[]]$Lines, $enc)
}

# Strip a UTF-8 BOM from a file if one is present. Returns $true if it removed one.
# Works on raw bytes: File.ReadAllText silently swallows the BOM, so a text-level
# check would never see it.
function Remove-Bom {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not [System.IO.File]::Exists($Path)) { return $false }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        [System.IO.File]::WriteAllBytes($Path, $bytes[3..($bytes.Length - 1)])
        return $true
    }
    return $false
}

# Move a directory using .NET so that [brackets] in the path are always literal.
function Move-Dir {
    param(
        [Parameter(Mandatory=$true)][string]$From,
        [Parameter(Mandatory=$true)][string]$To
    )
    [System.IO.Directory]::Move($From, $To)
}

function Test-DirExists {
    param([Parameter(Mandatory=$true)][string]$Path)
    return [System.IO.Directory]::Exists($Path)
}

function Test-FileExists {
    param([Parameter(Mandatory=$true)][string]$Path)
    return [System.IO.File]::Exists($Path)
}

# Locate the MariaDB / MySQL command line client.
function Find-MysqlClient {
    $names = @('mariadb.exe','mysql.exe')
    foreach ($n in $names) {
        $c = Get-Command $n -ErrorAction SilentlyContinue
        if ($c) { return $c.Source }
    }
    $roots = @(Get-ChildItem -LiteralPath 'C:\Program Files' -Directory -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -like 'MariaDB*' -or $_.Name -like 'MySQL*' })
    foreach ($r in $roots) {
        foreach ($n in $names) {
            $p = Join-Path $r.FullName "bin\$n"
            if (Test-FileExists $p) { return $p }
        }
    }
    return $null
}

# The nine resources that Outbreak replaces, and which recipe group each lives in.
$script:CompetingResources = @(
    @{ Name = 'qbx_spawn';           Group = '[qbx]';        Why = 'outbreak_spawn owns spawning' },
    @{ Name = 'qbx_properties';      Group = '[qbx]';        Why = 'outbreak_housing owns property' },
    @{ Name = 'qbx_hud';             Group = '[qbx]';        Why = 'outbreak_hud owns the HUD' },
    @{ Name = 'qbx_medical';         Group = '[qbx]';        Why = 'outbreak_needs owns needs/wounds' },
    @{ Name = 'qbx_ambulancejob';    Group = '[qbx]';        Why = 'outbreak_down owns death' },
    @{ Name = 'qbx_police';          Group = '[qbx]';        Why = 'outbreak_faction owns the military job' },
    @{ Name = 'qbx_density';         Group = '[qbx]';        Why = 'outbreak_core zeroes ambient population' },
    @{ Name = 'ox_fuel';             Group = '[ox]';         Why = 'outbreak_vehicles owns fuel' },
    @{ Name = 'Renewed-Weathersync'; Group = '[standalone]'; Why = 'outbreak_world owns time/weather (limitation #12)' }
)

$script:SliceResourceCount = 22   # 17 services + hud + status + wheel + dm + debug
$script:MigrationFiles = @(
    '001_slice.sql','002_extended.sql','003_progression.sql','004_vehicles.sql',
    '005_radio.sql','006_worlditems.sql','007_dm.sql'
)
