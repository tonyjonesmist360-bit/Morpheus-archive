<#  04-paste-ins.ps1
    INSTALL-WALKTHROUGH Part 7.4. The two paste-ins first boot needs:
      items - inserts (or refreshes) the outbreak items block in ox_inventory\data\items.lua
      jobs  - replaces the 'police' entry in qbx_core\shared\jobs.lua with military + raider
    weapons_snippet is NOT applied: it ships fully commented out and nothing in the
    slice requires it. Do that one by hand later.

    Both edits are backed up, marker-guarded (safe to re-run) and brace-checked.
    Use -Only items | jobs to do one. -Force skips the confirmation prompt.
#>
param([string]$Base, [ValidateSet('both','items','jobs','shops','all')][string]$Only = 'both', [switch]$DryRun, [switch]$Force)

. "$PSScriptRoot\_common.ps1"
$pack = Get-PackRoot
$baseResolved = Resolve-Base -Base $Base
$res = Join-Path $baseResolved 'resources'

Write-Host "OUTBREAK - paste-ins" -ForegroundColor White
if ($DryRun) { Warn "DRY RUN - nothing will be changed" }

function Confirm-Or-Exit($what) {
    if ($Force -or $DryRun) { return $true }
    $a = Read-Host "   Apply the $what edit? (yes/no)"
    if ($a -ne 'yes') { Warn "skipped $what"; return $false }
    return $true
}

# ---------------------------------------------------------------- items
if ($Only -eq 'both' -or $Only -eq 'all' -or $Only -eq 'items') {
    Step "ox_inventory items.lua"
    $target  = Join-Path $res '[ox]\ox_inventory\data\items.lua'
    $snippet = Join-Path $pack 'resources\[outbreak]\outbreak_items\data\ox_items_snippet.lua'

    if (-not (Test-FileExists $target))  { Bad "not found: $target" }
    elseif (-not (Test-FileExists $snippet)) { Bad "not found: $snippet" }
    else {
        $lines = @(Get-Content -LiteralPath $target)
        $snip  = @(Get-Content -LiteralPath $snippet)
        $mStart = -1; $mEnd = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($mStart -lt 0 -and $lines[$i] -match '>>> OUTBREAK ITEMS') { $mStart = $i }
            elseif ($mStart -ge 0 -and $lines[$i] -match '<<< OUTBREAK ITEMS') { $mEnd = $i; break }
        }
        if ($mStart -ge 0 -and $mEnd -gt $mStart) {
            # Managed block exists. Re-apply only if the snippet changed, so an upgraded pack
            # actually lands its new items (the old no-op here left v0.16 items undefined).
            $current = @($lines[($mStart+1)..($mEnd-1)] | ForEach-Object { $_ -replace '^  ', '' })
            $same = ($current.Count -eq $snip.Count)
            if ($same) { for ($k = 0; $k -lt $snip.Count; $k++) { if ($current[$k] -ne $snip[$k]) { $same = $false; break } } }
            if ($same) { Ok "already applied and current ($($snip.Count) lines)" }
            else {
                $body = ($snip | ForEach-Object { '  ' + $_ })
                $new  = @($lines[0..$mStart]) + $body + @($lines[$mEnd..($lines.Count-1)])
                $opens  = ([regex]::Matches(($new -join "`n"), '\{')).Count
                $closes = ([regex]::Matches(($new -join "`n"), '\}')).Count
                Note "managed block found at lines $($mStart+1)-$($mEnd+1); snippet differs ($($current.Count) -> $($snip.Count) lines); braces after edit: $opens open / $closes close"
                if ($opens -ne $closes) { Bad "brace count would not balance - refusing to write. Do this one by hand." }
                elseif ($DryRun) { Note "would rewrite the managed block in $target" }
                elseif (Confirm-Or-Exit 'items.lua') {
                    Backup-File -Path $target | Out-Null
                    Write-TextNoBom -Path $target -Lines $new
                    Ok "managed block replaced: $($snip.Count) snippet lines"
                }
            }
        }
        elseif ($mStart -ge 0) { Bad "found the >>> OUTBREAK ITEMS marker but no <<< end marker - items.lua was hand-edited. Fix by hand." }
        else {
            # The insert point is the final closing brace of the returned table.
            $idx = -1
            for ($i = $lines.Count - 1; $i -ge 0; $i--) {
                if ($lines[$i].Trim() -eq '}') { $idx = $i; break }
                if ($lines[$i].Trim() -ne '')  { break }   # last non-empty line is not '}' -> bail
            }
            if ($idx -lt 1) {
                Bad "could not find the closing '}' of items.lua - do this paste-in by hand (Part 7.4)"
            } else {
                $body = @('', '  -- >>> OUTBREAK ITEMS (managed by setup/04-paste-ins.ps1)') +
                        ($snip | ForEach-Object { '  ' + $_ }) +
                        @('  -- <<< OUTBREAK ITEMS', '')
                $new = @($lines[0..($idx-1)]) + $body + @($lines[$idx..($lines.Count-1)])

                $opens  = ([regex]::Matches(($new -join "`n"), '\{')).Count
                $closes = ([regex]::Matches(($new -join "`n"), '\}')).Count
                Note "inserting $($snip.Count) lines before line $($idx+1); braces after edit: $opens open / $closes close"

                if ($opens -ne $closes) { Bad "brace count would not balance - refusing to write. Do this one by hand." }
                elseif ($DryRun) { Note "would write $target" }
                elseif (Confirm-Or-Exit 'items.lua') {
                    Backup-File -Path $target | Out-Null
                    Write-TextNoBom -Path $target -Lines $new
                    Ok "$($snip.Count) snippet lines inserted"
                }
            }
        }
    }
}

# ---------------------------------------------------------------- jobs
if ($Only -eq 'both' -or $Only -eq 'all' -or $Only -eq 'jobs') {
    Step "qbx_core jobs.lua"
    $target  = Join-Path $res '[qbx]\qbx_core\shared\jobs.lua'
    $snippet = Join-Path $pack 'resources\[outbreak]\outbreak_faction\data\jobs_snippet.lua'

    if (-not (Test-FileExists $target))  { Bad "not found: $target" }
    elseif (-not (Test-FileExists $snippet)) { Bad "not found: $snippet" }
    else {
        $lines = @(Get-Content -LiteralPath $target)
        if ($lines -match 'Military Remnant') { Ok "already applied" }
        else {
            $start = -1
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "^\s*\[?'?police'?\]?\s*=\s*\{") { $start = $i; break }
            }
            if ($start -lt 0) {
                Bad "no 'police' entry found in jobs.lua - it may already be gone. Check by hand (Part 7.4)."
            } else {
                # Walk braces from the police line until the entry closes.
                $depth = 0; $end = -1
                for ($i = $start; $i -lt $lines.Count; $i++) {
                    $depth += ([regex]::Matches($lines[$i], '\{')).Count
                    $depth -= ([regex]::Matches($lines[$i], '\}')).Count
                    if ($depth -le 0) { $end = $i; break }
                }
                if ($end -lt 0) {
                    Bad "could not find the end of the police entry - do this paste-in by hand"
                } else {
                    # Drop the snippet's leading instruction comments and blank lines.
                    $snip = @(Get-Content -LiteralPath $snippet)
                    $first = 0
                    while ($first -lt $snip.Count -and ($snip[$first].Trim() -eq '' -or $snip[$first].Trim().StartsWith('--'))) { $first++ }
                    $body = @('  -- >>> OUTBREAK FACTIONS (replaced the stock police job)') +
                            ($snip[$first..($snip.Count-1)] | ForEach-Object { '  ' + $_ }) +
                            @('  -- <<< OUTBREAK FACTIONS')

                    Write-Host ""
                    Write-Host "   Replacing lines $($start+1)-$($end+1) of jobs.lua:" -ForegroundColor Yellow
                    $lines[$start..$end] | Select-Object -First 4 | ForEach-Object { Write-Host "     - $_" -ForegroundColor DarkGray }
                    if (($end - $start) -gt 4) { Write-Host "     - ... $($end - $start - 3) more lines" -ForegroundColor DarkGray }
                    Write-Host "   with the military + raider entries." -ForegroundColor Yellow
                    Write-Host ""

                    $pre  = if ($start -gt 0) { @($lines[0..($start-1)]) } else { @() }
                    $post = if ($end -lt $lines.Count-1) { @($lines[($end+1)..($lines.Count-1)]) } else { @() }
                    $new  = $pre + $body + $post

                    $opens  = ([regex]::Matches(($new -join "`n"), '\{')).Count
                    $closes = ([regex]::Matches(($new -join "`n"), '\}')).Count
                    if ($opens -ne $closes) { Bad "brace count would not balance ($opens/$closes) - refusing to write. Do this one by hand." }
                    elseif ($DryRun) { Note "would write $target" }
                    elseif (Confirm-Or-Exit 'jobs.lua') {
                        Backup-File -Path $target | Out-Null
                        Write-TextNoBom -Path $target -Lines $new
                        Ok "police replaced with military + raider"
                    }
                }
            }
        }
    }
}

# ---------------------------------------------------------------- shops (v0.23: no commerce)
if ($Only -eq 'all' -or $Only -eq 'shops') {
    Step "ox_inventory shops.lua -> no shops (gun stores and stores become loot)"
    $target  = Join-Path $res '[ox]\ox_inventory\data\shops.lua'
    $snippet = Join-Path $pack 'resources\[outbreak]\outbreak_items\data\ox_shops_snippet.lua'
    if (-not (Test-FileExists $target))  { Bad "not found: $target" }
    elseif (-not (Test-FileExists $snippet)) { Bad "not found: $snippet" }
    else {
        $cur = Get-Content -LiteralPath $target -Raw
        if ($cur -match 'OUTBREAK: NO COMMERCE') { Ok "already applied" }
        elseif ($DryRun) { Note "would back up and replace $target with the empty shop table" }
        elseif (Confirm-Or-Exit 'shops.lua') {
            Backup-File -Path $target | Out-Null
            Write-TextNoBom -Path $target -Lines @(Get-Content -LiteralPath $snippet)
            Ok "shops.lua replaced: no Ammunation, no 24/7 cashier, no licence, no prices. restart ox_inventory (or the server)"
        }
    }
}

Write-Host ""
Warn "A malformed items.lua takes ox_inventory down with it. If the server will not boot"
Warn "after this step, restore the .bak beside the file and do the paste-in by hand."
