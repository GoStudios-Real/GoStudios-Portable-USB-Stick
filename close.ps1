$ErrorActionPreference = "Stop"
$USBROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$ADB = Join-Path $USBROOT "emulator\adb.exe"

Write-Host "[GoUI 1.0] Closing Android 16 portable session..."
if (Test-Path $ADB) {
    & $ADB shell am force-stop com.goui.launcher 2>$null
    & $ADB emu kill 2>$null
}
Get-Process -Name "emulator","qemu-system*","adb" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "[GoUI 1.0] Session closed. Safe to remove USB."
