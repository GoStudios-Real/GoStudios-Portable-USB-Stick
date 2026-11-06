# One-time setup: installs platform-tools + Android 16 image into D:\SDK (the USB).
# Reuses the host Android SDK's cmdline-tools if present (no big downloads).
$ErrorActionPreference = "Stop"
$USBROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$SDK = "D:\SDK"
$HOST_SDK = "C:\Users\RhysC\Android\Sdk"
$env:TEMP = "D:\sdktmp"; $env:TMP = "D:\sdktmp"
New-Item -ItemType Directory -Force -Path $SDK, $env:TEMP | Out-Null

$sdkmanager = Get-ChildItem "$HOST_SDK\cmdline-tools\*\bin\sdkmanager.bat" -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (-not $sdkmanager) { throw "No host cmdline-tools found at $HOST_SDK - install Android Studio first" }

$env:ANDROID_SDK_ROOT = $SDK

# Re-run until success (long downloads can be interrupted)
$pkgs = @("platform-tools", "emulator", "system-images;android-36-ext19;google_apis_playstore;x86_64")
echo y | & $sdkmanager --sdk_root=$SDK $pkgs
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Interrupted - re-run setup.ps1 to resume (sdkmanager resumes automatically)."
    exit 1
}
echo y | & $sdkmanager --sdk_root=$SDK --licenses | Out-Null

Write-Host "Setup complete. Next: create-avd.ps1"
