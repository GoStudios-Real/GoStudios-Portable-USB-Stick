Add-Type -AssemblyName System.Drawing
$names = @("boot","account","home","gaming","play","settings")
$labels = @("Boot splash","Account gate","Home (Spots)","Gaming Hub","Play Store","Settings")
$dir = "C:\Users\RhysC\Downloads\Android USB\docs\screenshots"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
for ($i=0; $i -lt $names.Count; $i++) {
    $bmp = New-Object System.Drawing.Bitmap 360,640
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(255,8,12,40))
    $rect = New-Object System.Drawing.Rectangle 0,0,360,640
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255,0,137,123)), ([System.Drawing.Color]::FromArgb(255,126,87,194)), 90
    $g.FillRectangle($brush, $rect)
    $font = New-Object System.Drawing.Font "Segoe UI", 24, ([System.Drawing.FontStyle]::Bold)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString($labels[$i], $font, [System.Drawing.Brushes]::White, 180, 320, $sf)
    $sub = New-Object System.Drawing.Font "Segoe UI", 12
    $g.DrawString("GoUI 4.9", $sub, [System.Drawing.Brushes]::White, 180, 360, $sf)
    $bmp.Save("$dir\$($names[$i]).png", [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}
Write-Host "screenshots created"