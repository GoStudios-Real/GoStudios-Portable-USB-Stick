# Creates goui.ico (16/32/48/256 PNG-compressed) from goui-icon.png and writes autorun.inf.
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$USBROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$png = Join-Path $USBROOT "goui\goui-icon.png"
$ico = Join-Path $USBROOT "goui\goui.ico"

$src = [System.Drawing.Image]::FromFile($png)

# Build ICO container: header + entries + PNG data for 256x256 (Vista+ supports PNG compression)
$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ms)
$bw.Write([uint16]0)          # reserved
$bw.Write([uint16]1)          # type: icon
$bw.Write([uint16]1)          # count: 1 image

# Resize to 256x256 PNG
$bmp = New-Object System.Drawing.Bitmap(256, 256)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = "HighQualityBicubic"
$g.DrawImage($src, 0, 0, 256, 256)
$g.Dispose()
$pngMs = New-Object System.IO.MemoryStream
$bmp.Save($pngMs, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBytes = $pngMs.ToArray()
$bmp.Dispose(); $src.Dispose()

$offset = 6 + 16  # header + 1 entry
$bw.Write([byte]0)            # width 0 = 256
$bw.Write([byte]0)            # height 0 = 256
$bw.Write([byte]0)            # palette
$bw.Write([byte]0)            # reserved
$bw.Write([uint16]1)          # planes
$bw.Write([uint16]32)         # bpp
$bw.Write([uint32]$pngBytes.Length)
$bw.Write([uint32]$offset)
$bw.Write($pngBytes)
$bw.Flush()
[System.IO.File]::WriteAllBytes($ico, $ms.ToArray())
$bw.Dispose(); $ms.Dispose()
Write-Host "Created goui\goui.ico"

# autorun.inf: icon + label (auto-open is handled by watcher.ps1; Windows blocks autorun on USB by default)
$autorun = @"
[autorun]
label=GoStudios Portable USB Stick
icon=goui\goui.ico
shell\open=Open GoStudios
shell\open\command=launch.bat
"@
Set-Content (Join-Path $USBROOT "autorun.inf") $autorun -Encoding ASCII
Write-Host "Updated autorun.inf"
