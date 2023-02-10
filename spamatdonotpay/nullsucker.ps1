#!/snap/bin/pwsh

$files = (Get-ChildItem -Path "/var/spool/nullmailer/what").FullName
Foreach ($file in $files) {
    Write-Host "Moving $file..."
    Move-Item "$file" "/var/spool/nullmailer/queue"
    "echo x /var/spool/nullmailer/trigger" | Invoke-Expression
    Start-Sleep 600
}
