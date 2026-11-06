Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 512,512
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255,8,12,40))
$rect = New-Object System.Drawing.Rectangle 32,32,448,448
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255,0,137,123)), ([System.Drawing.Color]::FromArgb(255,126,87,194)), 45
$g.FillEllipse($brush, $rect)
$font = New-Object System.Drawing.Font "Segoe UI",96,([System.Drawing.FontStyle]::Bold)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center
$g.DrawString("GoUI", $font, [System.Drawing.Brushes]::White, 256, 256, $sf)
$path = "C:\Users\RhysC\Downloads\Android USB\goui\goui-logo.png"
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Host "logo created"