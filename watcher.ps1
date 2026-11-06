# Watches for the GoStudios USB and launches/closes the Android session automatically.
$VOLUME_NAME = "GoStudios Portable USB Stick"
$root = $null

while ($true) {
    $vol = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.VolumeName -eq $VOLUME_NAME } | Select-Object -First 1

    if ($vol -and -not $root) {
        $root = $vol.DeviceID + "\"
        Write-Host "[Watcher] USB $VOLUME_NAME detected at $root - launching..."
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$root`launch.ps1`""
    }
    elseif (-not $vol -and $root) {
        Write-Host "[Watcher] USB $VOLUME_NAME removed - closing session..."
        Get-Process -Name "emulator","qemu-system*","adb" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        $root = $null
    }

    Start-Sleep -Seconds 3
}
