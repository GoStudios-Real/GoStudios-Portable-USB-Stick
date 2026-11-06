# Generates wallpaper + app icons locally using System.Drawing (no network needed).
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$USBROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$gouiDir = Join-Path $USBROOT "goui"
$appsDir = Join-Path $USBROOT "apps"
New-Item -ItemType Directory -Force -Path $gouiDir, $appsDir | Out-Null

function New-GradientBitmap([int]$w, [int]$h, [System.Drawing.Color]$c1, [System.Drawing.Color]$c2) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    for ($y = 0; $y -lt $h; $y++) {
        $t = $y / [math]::Max(1, $h - 1)
        $r = [int]($c1.R + ($c2.R - $c1.R) * $t)
        $g = [int]($c1.G + ($c2.G - $c1.G) * $t)
        $b = [int]($c1.B + ($c2.B - $c1.B) * $t)
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, $r, $g, $b))
        $gfx = [System.Drawing.Graphics]::FromImage($bmp)
        $gfx.DrawLine($pen, 0, $y, $w, $y)
        $gfx.Dispose(); $pen.Dispose()
    }
    return $bmp
}

function Add-Glyph($bmp, [string]$text, [System.Drawing.Color]$color, [string]$fontFamily = "Segoe UI", [float]$emSize = 200, [string]$style = "Bold") {
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.SmoothingMode = "AntiAlias"
    $gfx.TextRenderingHint = "AntiAliasGridFit"
    $font = New-Object System.Drawing.Font($fontFamily, $emSize, [System.Drawing.FontStyle]::$style, [System.Drawing.GraphicsUnit]::Pixel)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = "Center"; $fmt.LineAlignment = "Center"
    $brush = New-Object System.Drawing.SolidBrush($color)
    $rect = New-Object System.Drawing.RectangleF(0, 0, $bmp.Width, $bmp.Height)
    $gfx.DrawString($text, $font, $brush, $rect, $fmt)
    $gfx.Dispose()
}

# --- Wallpaper (dark blue -> violet, 1920x1080) ---
$wp = New-GradientBitmap 1920 1080 ([System.Drawing.Color]::FromArgb(255, 8, 12, 40)) ([System.Drawing.Color]::FromArgb(255, 60, 20, 90))
$wp.Save((Join-Path $gouiDir "wallpaper.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$wp.Dispose()
Write-Host "Created goui\wallpaper.png"

# --- Icon helper (rounded-ish square, 512x512) ---
function New-AppIcon([string]$path, [System.Drawing.Color]$c1, [System.Drawing.Color]$c2, [string]$glyph) {
    $bmp = New-GradientBitmap 512 512 $c1 $c2
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.SmoothingMode = "AntiAlias"
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 10)
    $gfx.DrawRectangle($pen, 24, 24, 464, 464)
    $gfx.Dispose(); $pen.Dispose()
    Add-Glyph $bmp $glyph ([System.Drawing.Color]::White) "Segoe UI" 220 Bold
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

New-AppIcon (Join-Path $gouiDir "goui-icon.png") ([System.Drawing.Color]::FromArgb(255, 0, 150, 170)) ([System.Drawing.Color]::FromArgb(255, 50, 30, 140)) "G"
New-AppIcon (Join-Path $appsDir "GoDevice-icon.png") ([System.Drawing.Color]::FromArgb(255, 20, 40, 30)) ([System.Drawing.Color]::FromArgb(255, 0, 160, 90)) "GD"
New-AppIcon (Join-Path $appsDir "PlayTree-icon.png") ([System.Drawing.Color]::FromArgb(255, 40, 140, 60)) ([System.Drawing.Color]::FromArgb(255, 150, 220, 90)) "PT"
New-AppIcon (Join-Path $appsDir "XboxCloudGaming-icon.png") ([System.Drawing.Color]::FromArgb(255, 15, 60, 20)) ([System.Drawing.Color]::FromArgb(255, 16, 124, 16)) "X"
Write-Host "Created app icons in goui\ and apps\"
Write-Host "Done."
