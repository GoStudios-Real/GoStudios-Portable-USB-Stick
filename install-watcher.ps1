# Run once as Administrator. Registers a scheduled task that watches for USB arrival/removal.
$USBROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$USBROOT\watcher.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogon
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "AndroidPortableUSBWatcher" -Action $action -Trigger $trigger -Principal $principal -Force
Write-Host "Watcher registered. It will start on next logon."
