# Boots Android 16, installs GoUI 1.0 as the HOME/system UI, opens GoStudios shell.
$ErrorActionPreference = "Stop"
$USBROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

# Prefer the USB (portable) SDK; fall back to host SDK for emulator/adb
$SDK = if (Test-Path "D:\SDK\emulator\emulator.exe") { "D:\SDK" }
       elseif (Test-Path "D:\SDK\platform-tools\adb.exe") { "D:\SDK" }
       else { "C:\Users\RhysC\Android\Sdk" }
$EMULATOR = Join-Path $SDK "emulator\emulator.exe"
if (-not (Test-Path $EMULATOR)) { $EMULATOR = Join-Path $SDK "emulator\emulator.exe" }
$ADB = Join-Path $SDK "platform-tools\adb.exe"
if (-not (Test-Path $ADB)) { $ADB = Join-Path $USBROOT "emulator\adb.exe" }
$AVD = "Android16_Portable"
$GOUI = Join-Path $USBROOT "goui\goui-4.9.apk"
if (-not (Test-Path $GOUI)) { $GOUI = Join-Path $USBROOT "goui\goui-1.0.apk" }

# Host architecture -> pick the right ABI image/emulator so the stick runs on any PC
if ($env:PROCESSOR_ARCHITECTURE -match "ARM") { $ABI = "arm64-v8a" } else { $ABI = "x86_64" }

if (-not (Test-Path $EMULATOR)) { throw "emulator.exe not found - run setup.ps1" }
if (-not (Test-Path $ADB)) { throw "adb.exe not found - run setup.ps1" }
if (-not (Test-Path $GOUI)) { throw "GoUI APK missing - run build-goui.ps1" }

$env:ANDROID_SDK_ROOT = $SDK
$env:ANDROID_HOME = $SDK
$env:ANDROID_AVD_HOME = Join-Path $USBROOT "avd"

# Guard: emulator may rewrite userdata to a huge default (Play Store images want 6G)
# which never fits on the USB - force it back to 1G before booting.
$avdCfg = Join-Path $env:ANDROID_AVD_HOME "Android16_Portable.avd\config.ini"
if (Test-Path $avdCfg) {
    $c = Get-Content $avdCfg -Raw
    $c2 = $c -replace "disk\.dataPartition\.size\s*=\s*\d+", "disk.dataPartition.size = 2147483648"
    $c2 = $c2 -replace "hw\.sdCard\s*=\s*\w+", "hw.sdCard = no"
    if ($c2 -ne $c) { Set-Content $avdCfg $c2 -Encoding ASCII }
}

Write-Host "[GoStudios] Booting Android 16 + GoUI 1.0..."
Start-Process -FilePath $EMULATOR -ArgumentList "-avd",$AVD,"-no-snapshot","-no-boot-anim","-gpu","host" -WindowStyle Hidden

# Wait for boot (max ~3 min)
$booted = $false
for ($i=0; $i -lt 90; $i++) {
    try { $state = & $ADB shell getprop sys.boot_completed 2>$null } catch { $state = $null }
    if ("$state" -match "1") { $booted = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $booted) { throw "Android 16 did not boot in time" }

Write-Host "[GoStudios] Installing GoUI 1.0 as system UI..."
& $ADB install -r $GOUI

# Make GoUI the default HOME (replaces stock System UI launcher)
& $ADB shell cmd package set-home-activity com.goui.launcher/.GoUIActivity 2>$null | Out-Null
# Disable stock launchers so GoUI is the only system UI
& $ADB shell pm disable-user --user 0 com.google.android.apps.nexuslauncher 2>$null | Out-Null
& $ADB shell pm disable-user --user 0 com.android.launcher3 2>$null | Out-Null
& $ADB shell "input keyevent KEYCODE_HOME" 2>$null | Out-Null

# Grant overlay permissions so GoUI draws over everything
& $ADB shell appops set com.goui.launcher SYSTEM_ALERT_WINDOW allow 2>$null

# Install preinstalled gaming apps (skip missing with warning)
Get-ChildItem (Join-Path $USBROOT "apps\*.apk") -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "Installing $($_.Name)..."
    & $ADB install -r $_.FullName 2>&1 | Out-Null
}

# Make sure Play Store is present (playstore system image)
$play = & $ADB shell pm path com.android.vending 2>$null
if ("$play" -match "package:") {
    Write-Host "[GoStudios] Google Play Store present on system image."
} else {
    Write-Warning "Play Store not on image - use google_apis_playstore variant (setup.ps1)"
}

# Push wallpaper
$wp = Get-ChildItem (Join-Path $USBROOT "goui\wallpaper.*") -ErrorAction SilentlyContinue | Select-Object -First 1
if ($wp) {
    & $ADB shell "mkdir -p /sdcard/GoStudios" 2>$null | Out-Null
    & $ADB push $wp.FullName "/sdcard/GoStudios/wallpaper$($wp.Extension)" 2>$null | Out-Null
}

# Launch GoUI home (shows GoStudios boot splash -> account gate -> shell)
& $ADB shell am start -n com.goui.launcher/.GoUIActivity
Write-Host "[GoStudios] GoUI 4.9 running on GoStudios Portable USB Stick. Unplug to close."

# Maximize emulator window to fullscreen (best-effort)
Start-Sleep -Seconds 2
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class WinMax {
  [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
}
"@ -ErrorAction SilentlyContinue
$proc = Get-Process emulator -ErrorAction SilentlyContinue | Select-Object -First 1
if ($proc) {
    $h = $proc.MainWindowHandle
    if ($h -ne 0) { [WinMax]::ShowWindowAsync($h, 3) | Out-Null }  # SW_MAXIMIZE
}

# Wait for emulator to exit, then return to desktop
while (Get-Process emulator -ErrorAction SilentlyContinue) { Start-Sleep -Seconds 3 }
Write-Host "[GoStudios] Android closed. Returning to desktop."


