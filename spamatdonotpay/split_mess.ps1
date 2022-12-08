$inFile="C:\Users\charlesm\AppData\Roaming\Thunderbird\Profiles\oqyg0pi7.default\Mail\Local Folders\Junk.sbd\to_process"

If (-Not (Test-Path -PathType Container $workingDir)) {New-Item -ItemType Directory -Force -Path $workingDir}

$completedLine = 0
$lineCount = (Get-Content $inFile).Length
Get-Content $inFile | ForEach-Object {
    If ($_ -like "From - *") {
        $outputFile = [guid]::NewGuid()
        Write-Host "Writing $_ to $outputFile"
    }
    $_ | Out-File -Append -FilePath $(Join-Path $workingDir $outputFile)
    $completedLine++
    $progress = [math]::Round($($completedLine * 100 / $lineCount))
    Write-Progress -Activity "Progress:" -Status "$progress% Complete" -PercentComplete $progress
}
