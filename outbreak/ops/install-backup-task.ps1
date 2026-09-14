<#  ops/install-backup-task.ps1
    Registers the nightly backup as a Windows scheduled task (daily 04:00, highest privileges,
    runs whether or not you are logged in) and, with -RunNow, runs it immediately and verifies
    the result. Run from an elevated PowerShell (Run as administrator).

      powershell -ExecutionPolicy Bypass -File .\ops\install-backup-task.ps1 -RunNow

    Edit ops\backup.bat first: DB, DBPASS, SERVER, OUT at the top. DBPASS must not be CHANGE_ME.
#>
param([string]$Time = '04:00', [switch]$RunNow, [switch]$Remove)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$bat  = Join-Path $here 'backup.bat'
$name = 'Outbreak Backup'

if ($Remove) {
    Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "   [ ok ] task '$name' removed"; return
}
if (-not (Test-Path -LiteralPath $bat)) { throw "backup.bat not found beside this script: $bat" }
if ((Get-Content -LiteralPath $bat -Raw) -match 'DBPASS=CHANGE_ME') { throw "Edit ops\backup.bat first: DBPASS is still CHANGE_ME." }

$action  = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument ('/c "' + $bat + '"') -WorkingDirectory $here
$trigger = New-ScheduledTaskTrigger -Daily -At $Time
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 30) -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Highest
Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
Write-Host "   [ ok ] task '$name' registered: daily at $Time -> $bat"

if ($RunNow) {
    Write-Host "   [ .. ] running the backup now"
    Start-ScheduledTask -TaskName $name
    $t = 0
    do { Start-Sleep -Seconds 2; $t += 2; $st = (Get-ScheduledTask -TaskName $name).State } while ($st -eq 'Running' -and $t -lt 300)
    $info = Get-ScheduledTaskInfo -TaskName $name
    Write-Host "   [ .. ] last result code: $($info.LastTaskResult)  (0 = ran)"
    & powershell -ExecutionPolicy Bypass -File (Join-Path $here 'verify-backup.ps1')
}
