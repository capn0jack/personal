$inFile="C:\Users\charlesm\AppData\Roaming\Thunderbird\Profiles\oqyg0pi7.default\Mail\Local Folders\Junk.sbd\forwardtodonotpay"
$workingDir = "C:\temp\workingspam"
$remoteDir = "~/working/"
$username="ubuntu"
$hostname="3.89.155.14"
$privateKey="c:\users\charlesm\Downloads\donotpay.pem"

If (-Not (Test-Path -PathType Container $workingDir)) {New-Item -ItemType Directory -Force -Path $workingDir}

$completedLine = 0
$lineCount = (Get-Content $inFile).Length
If ($lineCount -lt 1) {
    Write-Warning "There don't appear to be any messages in $inFile. Exiting"
    Exit
}
Get-Content $inFile | ForEach-Object {
    If ($_ -like "From - *") {
        $outputFile = [guid]::NewGuid()
        Write-Host "Writing $_ to $outputFile"
    }
    $_ | Out-File -Append -FilePath $(Join-Path $workingDir $outputFile)
    $completedLine++
    $progress = [math]::Round($($completedLine * 100 / $lineCount))
    Write-Progress -Activity "Creating files from mailbox folder:" -Status "$progress% Complete" -PercentComplete $progress
}

Write-Host "Copying files to server:"
scp -i $privateKey $workingDir\* $username`@$hostname`:$remoteDir
If (-Not $?) {
    Write-Host "It looks like there was a problem uploading the files to the server.  The exit code was $?.  Exiting."
    Exit
}

Write-Host "Deleting local copy of files:"
Remove-Item -Force $workingDir\*