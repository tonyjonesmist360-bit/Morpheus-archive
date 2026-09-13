<#  06-fix-bom.ps1
    Repairs UTF-8 BOMs on the files the setup scripts write.

    Windows PowerShell 5.1's `-Encoding UTF8` emits a byte-order mark. Lua rejects it:
        unexpected symbol near '<\239>'
    which takes down ox_inventory/data/items.lua and qbx_core/shared/jobs.lua, and
    cascades into "No such export" errors all over the server.

    Fixed at source in 01/04/05 as of this version. This script repairs a tree that
    was already written by the buggy version. Safe to run any time - it only rewrites
    files that actually carry a BOM.
#>
param([string]$Base)

. "$PSScriptRoot\_common.ps1"
$baseResolved = Resolve-Base -Base $Base
$res = Join-Path $baseResolved 'resources'

Write-Host "OUTBREAK - strip UTF-8 BOMs" -ForegroundColor White
Write-Host "base: $baseResolved"

$targets = @(
    (Join-Path $baseResolved 'server.cfg'),
    (Join-Path $baseResolved 'permissions.cfg'),
    (Join-Path $res '[ox]\ox_inventory\data\items.lua'),
    (Join-Path $res '[qbx]\qbx_core\shared\jobs.lua')
)

Step "Checking"
$fixed = 0
foreach ($t in $targets) {
    if (-not (Test-FileExists $t)) { Warn "missing: $t"; continue }
    if (Remove-Bom -Path $t) { Ok "BOM stripped: $(Split-Path -Leaf $t)"; $fixed++ }
    else { Note "clean: $(Split-Path -Leaf $t)" }
}

Write-Host ""
if ($fixed -gt 0) { Write-Host "Repaired $fixed file(s). Restart the server." -ForegroundColor White }
else { Write-Host "Nothing to fix." -ForegroundColor White }
