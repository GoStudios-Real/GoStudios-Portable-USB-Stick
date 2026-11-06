# Creates the GoStudios AVD manually (no avdmanager dependency).
$ErrorActionPreference = "Stop"
$USBROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$SDK = if (Test-Path "D:\SDK\system-images") { "D:\SDK" } else { "C:\Users\RhysC\Android\Sdk" }
$AVD_HOME = Join-Path $USBROOT "avd"
$AVD_DIR = Join-Path $AVD_HOME "Android16_Portable.avd"
New-Item -ItemType Directory -Force -Path $AVD_DIR | Out-Null

$imgDir = Get-ChildItem "$SDK\system-images\android-36*" -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName "google_apis_playstore\x86_64") } | Select-Object -First 1
$tag = "google_apis_playstore"
if (-not $imgDir) {
    $imgDir = Get-ChildItem "$SDK\system-images\android-36*" -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "google_apis\x86_64") } | Select-Object -First 1
    $tag = "google_apis"
}
if (-not $imgDir) { throw "Android 16 system image not found under $SDK\system-images - run setup.ps1" }
$relSysDir = "system-images\$($imgDir.Name)\$tag\x86_64\"

# AVD registry entry (next to avd folder)
$ini = @"
avd.ini.encoding=UTF-8
path=$AVD_DIR
path.rel=avd\Android16_Portable.avd
target=android-36
image.sysdir.1=$relSysDir
"@
Set-Content (Join-Path $AVD_HOME "Android16_Portable.ini") $ini -Encoding ASCII

# config.ini - Android 16 + GPU/RAM fixes for System UI stability
$cfg = @"
PlayStore.enabled=yes
abi.type=x86_64
avd.ini.displayname=Android16 Portable (GoStudios)
avd.ini.encoding=UTF-8
disk.cachePartition=yes
disk.cachePartition.size=32M
disk.dataPartition.size=1G
fastboot.forceChosenSnapshotBoot=no
fastboot.forceColdBoot=yes
fastboot.forceFastBoot=no
firstboot.bootFromDownloadableSnapshot=no
firstboot.bootFromLocalSnapshot=no
firstboot.saveToLocalSnapshot=no
hw.accelerometer=yes
hw.audioInput=yes
hw.audioOutput=yes
hw.battery=yes
hw.camera.back=emulated
hw.camera.front=emulated
hw.cpu.arch=x86_64
hw.cpu.ncore=4
hw.dPad=no
hw.device.hash2=MD5:12ab7fcb681cafc1697d019f385bf3b9
hw.device.manufacturer=Google
hw.device.name=pixel_5
hw.gps=yes
hw.gpu.enabled=yes
hw.gpu.mode=host
hw.initialOrientation=portrait
hw.keyboard=yes
hw.lcd.density=440
hw.lcd.height=2340
hw.lcd.width=1080
hw.mainKeys=no
hw.ramSize=4096
hw.screen=multi-touch
hw.sdCard=yes
hw.trackBall=no
hw.useext4=yes
image.sysdir.1=$relSysDir
runtime.network.latency=none
runtime.network.speed=full
sdcard.size=128M
showDeviceFrame=yes
tag.id=$tag
tag.display=Google Play
target=android-36
vm.heapSize=512M
"@
Set-Content (Join-Path $AVD_DIR "config.ini") $cfg -Encoding ASCII

Write-Host "AVD Android16_Portable created at $AVD_DIR"
Write-Host "Image: $relSysDir (RAM 4GB, host GPU, cold boot, snapshots off)"
