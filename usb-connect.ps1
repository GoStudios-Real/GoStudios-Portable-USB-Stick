# GoStudios USB Connect - connects to a plugged-in GoStudios USB stick and manages the session.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "GoStudios USB Connect"
$form.Size = New-Object System.Drawing.Size(460, 320)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$title = New-Object System.Windows.Forms.Label
$title.Text = "GoStudios USB Connect"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 15)
$form.Controls.Add($title)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Scanning for GoStudios USB..."
$status.Location = New-Object System.Drawing.Point(20, 60)
$status.Size = New-Object System.Drawing.Size(420, 25)
$form.Controls.Add($status)

$info = New-Object System.Windows.Forms.TextBox
$info.Multiline = $true
$info.ReadOnly = $true
$info.Location = New-Object System.Drawing.Point(20, 90)
$info.Size = New-Object System.Drawing.Size(420, 120)
$info.BackColor = [System.Drawing.Color]::FromArgb(28,35,49)
$info.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($info)

$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Connect"
$btnConnect.Location = New-Object System.Drawing.Point(20, 220)
$btnConnect.Size = New-Object System.Drawing.Size(130, 32)
$btnConnect.BackColor = [System.Drawing.Color]::FromArgb(0,137,123)
$btnConnect.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($btnConnect)

$btnDisconnect = New-Object System.Windows.Forms.Button
$btnDisconnect.Text = "Disconnect"
$btnDisconnect.Location = New-Object System.Drawing.Point(160, 220)
$btnDisconnect.Size = New-Object System.Drawing.Size(130, 32)
$form.Controls.Add($btnDisconnect)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "Close"
$btnClose.Location = New-Object System.Drawing.Point(300, 220)
$btnClose.Size = New-Object System.Drawing.Size(130, 32)
$btnClose.Add_Click({ $form.Close() })
$form.Controls.Add($btnClose)

$script:root = $null

function Find-USB {
    $vol = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.VolumeName -eq "GoStudios Portable USB Stick" } | Select-Object -First 1
    if ($vol) {
        $script:root = $vol.DeviceID + "\"
        $status.Text = "Connected: $($vol.DeviceID) ($([math]::Round($vol.FreeSpace/1GB,2)) GB free)"
        $info.Text = "Drive: $($vol.DeviceID)`nLabel: $($vol.VolumeName)`nFree: $([math]::Round($vol.FreeSpace/1GB,2)) GB`nTotal: $([math]::Round($vol.Size/1GB,2)) GB`n`nReady to launch Android 16 + GoUI 4.9."
        $btnConnect.Enabled = $true
    } else {
        $script:root = $null
        $status.Text = "No GoStudios USB detected. Plug in the stick."
        $info.Text = "Insert the USB stick labelled 'GoStudios Portable USB Stick' and click Refresh."
        $btnConnect.Enabled = $false
    }
}

$btnConnect.Add_Click({
    if (-not $script:root) { Find-USB; if (-not $script:root) { return } }
    $status.Text = "Launching Android 16..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($script:root)launch.ps1`""
})

$btnDisconnect.Add_Click({
    Get-Process -Name "emulator","qemu-system*","adb" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    $status.Text = "Disconnected."
    $info.Text = "Session closed. Returning to desktop."
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000
$timer.Add_Tick({ Find-USB })
$timer.Start()

Find-USB
[void]$form.ShowDialog()
$timer.Stop()