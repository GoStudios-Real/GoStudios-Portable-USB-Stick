@echo off
setlocal
set USBROOT=%~dp0

echo [GoUI 1.0] Closing Android 16 portable session...
powershell -NoProfile -ExecutionPolicy Bypass -File "%USBROOT%close.ps1"
endlocal
