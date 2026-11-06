# GoStudios USB Maker - creates a "GoStudios Portable USB Stick" from a source folder.
# Run as Administrator. Requires Windows PowerShell 5.1+.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "GoStudios USB Maker"
$form.Size = New-Object System.Drawing.Size(520, 360)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "GoStudios Portable USB Stick Maker"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(20, 15)
$form.Controls.Add($lblTitle)

$lblDrive = New-Object System.Windows.Forms.Label
$lblDrive.Text = "Select USB drive:"
$lblDrive.Location = New-Object System.Drawing.Point(20, 60)
$lblDrive.AutoSize = $true
$form.Controls.Add($lblDrive)

$cmbDrives = New-Object System.Windows.Forms.ComboBox
$cmbDrives.Location = New-Object System.Drawing.Point(20, 85)
$cmbDrives.Size = New-Object System.Drawing.Size(460, 25)
$cmbDrives.DropDownStyle = "DropDownList"
$form.Controls.Add($cmbDrives)

function Refresh-Drives {
    $cmbDrives.Items.Clear()
    Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 } | ForEach-Object {
        $free = [math]::Round($_.FreeSpace / 1GB, 2)
        $size = [math]::Round($_.Size / 1GB, 2)
        $label = if ($_.VolumeName) { $_.VolumeName } else { "(no label)" }
        $cmbDrives.Items.Add("$($_.DeviceID)  $label  ($size GB, $free GB free)") | Out-Null
    }
    if ($cmbDrives.Items.Count -gt 0) { $cmbDrives.SelectedIndex = 0 }
}
Refresh-Drives

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Refresh"
$btnRefresh.Location = New-Object System.Drawing.Point(390, 55)
$btnRefresh.Size = New-Object System.Drawing.Size(90, 28)
$btnRefresh.Add_Click({ Refresh-Drives })
$form.Controls.Add($btnRefresh)

$lblSrc = New-Object System.Windows.Forms.Label
$lblSrc.Text = "Source folder (project):"
$lblSrc.Location = New-Object System.Drawing.Point(20, 125)
$lblSrc.AutoSize = $true
$form.Controls.Add($lblSrc)

$txtSrc = New-Object System.Windows.Forms.TextBox
$txtSrc.Location = New-Object System.Drawing.Point(20, 150)
$txtSrc.Size = New-Object System.Drawing.Size(360, 25)
$txtSrc.Text = Split-Path -Parent $MyInvocation.MyCommand.Path
$form.Controls.Add($txtSrc)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse"
$btnBrowse.Location = New-Object System.Drawing.Point(390, 148)
$btnBrowse.Size = New-Object System.Drawing.Size(90, 28)
$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq "OK") { $txtSrc.Text = $dlg.SelectedPath }
})
$form.Controls.Add($btnBrowse)

$chkFormat = New-Object System.Windows.Forms.CheckBox
$chkFormat.Text = "Format drive as NTFS (label: GoStudios Portable USB Stick)"
$chkFormat.Location = New-Object System.Drawing.Point(20, 190)
$chkFormat.AutoSize = $true
$chkFormat.Checked = $true
$form.Controls.Add($chkFormat)

$chkCopy = New-Object System.Windows.Forms.CheckBox
$chkCopy.Text = "Copy project files to USB"
$chkCopy.Location = New-Object System.Drawing.Point(20, 215)
$chkCopy.AutoSize = $true
$chkCopy.Checked = $true
$form.Controls.Add($chkCopy)

$chkSetup = New-Object System.Windows.Forms.CheckBox
$chkSetup.Text = "Run setup.ps1 after copy"
$chkSetup.Location = New-Object System.Drawing.Point(20, 240)
$chkSetup.AutoSize = $true
$chkSetup.Checked = $false
$form.Controls.Add($chkSetup)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20, 270)
$progress.Size = New-Object System.Drawing.Size(460, 20)
$progress.Style = "Continuous"
$form.Controls.Add($progress)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Ready."
$status.Location = New-Object System.Drawing.Point(20, 295)
$status.AutoSize = $true
$form.Controls.Add($status)

$btnMake = New-Object System.Windows.Forms.Button
$btnMake.Text = "Make USB"
$btnMake.Location = New-Object System.Drawing.Point(20, 320)
$btnMake.Size = New-Object System.Drawing.Size(120, 30)
$btnMake.BackColor = [System.Drawing.Color]::FromArgb(0, 137, 123)
$btnMake.ForeColor = [System.Drawing.Color]::White
$btnMake.Add_Click({
    if ($cmbDrives.SelectedIndex -lt 0) { [System.Windows.Forms.MessageBox]::Show("Select a USB drive."); return }
    $drive = ($cmbDrives.SelectedItem.ToString() -split "\s+")[0]
    $src = $txtSrc.Text
    if (-not (Test-Path $src)) { [System.Windows.Forms.MessageBox]::Show("Source folder not found."); return }

    $btnMake.Enabled = $false
    $progress.Value = 0
    $status.Text = "Working..."

    try {
        if ($chkFormat.Checked) {
            $status.Text = "Formatting $drive as NTFS..."
            $form.Refresh()
            $label = "GoStudios Portable USB Stick"
            Format-Volume -DriveLetter $drive.TrimEnd(":") -FileSystem NTFS -NewFileSystemLabel $label -Confirm:$false -ErrorAction Stop | Out-Null
            $progress.Value = 20
        }

        if ($chkCopy.Checked) {
            $status.Text = "Copying files..."
            $form.Refresh()
            $dest = $drive + "\"
            robocopy $src $dest /E /COPY:DAT /XD "src" /R:1 /W:1 /NFL /NDL /NJH | Out-Null
            $progress.Value = 70
        }

        if ($chkSetup.Checked) {
            $status.Text = "Running setup.ps1..."
            $form.Refresh()
            & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $drive "setup.ps1")
            $progress.Value = 90
        }

        $progress.Value = 100
        $status.Text = "Done! USB is ready."
        [System.Windows.Forms.MessageBox]::Show("USB created successfully.", "GoStudios USB Maker")
    } catch {
        $status.Text = "Error: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error")
    } finally {
        $btnMake.Enabled = $true
    }
})
$form.Controls.Add($btnMake)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "Close"
$btnClose.Location = New-Object System.Drawing.Point(360, 320)
$btnClose.Size = New-Object System.Drawing.Size(120, 30)
$btnClose.Add_Click({ $form.Close() })
$form.Controls.Add($btnClose)

[void]$form.ShowDialog()