@echo off
setlocal
set USBROOT=%~dp0

echo [GoUI 1.0] Starting Android 16 portable session...
powershell -NoProfile -ExecutionPolicy Bypass -File "%USBROOT%launch.ps1"
endlocal
