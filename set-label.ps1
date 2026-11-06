Set-Volume -DriveLetter D -NewFileSystemLabel "GoStudios Portable USB Stick"
Get-Volume -DriveLetter D | Select-Object FileSystemLabel | Out-File "$env:TEMP\label_result.txt"
