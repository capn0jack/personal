#!/snap/bin/pwsh

function Get-Config {
    param (
        [Parameter(Mandatory=$true)]
        [string]$configFile
    )
    $config = Get-Content "$configFile"
    ForEach ($line in $config) {
        $name = $line.Split("=")[0]
        $value = $line.Split("=")[1]
        If ("$name" -like "env:*") {
            $name = $name.Split(":")[1]
            [Environment]::SetEnvironmentVariable("$name","$value")
        } Else {
            Set-Variable -name "$name" -Value "$value" -Scope global
        }
    }
    $configTime = Get-Date
    return $configTime
}

$configFile = "/home/ubuntu/move_mess.config"

While ($true) {
    $configTime = Get-Config -configFile "$configFile"
    $archiveDir = Join-Path $workingDir "archive"
    $sleepSecs = $throttleSecs/100
    $workingOnMessage = 0
    $inFiles = (Get-ChildItem $workingDir -Depth 0 -File).FullName
    $messageCount = $inFiles.Count
    If ($inFiles.count -eq 0) {
        Write-Host "The spam@donotpay.com queue is empty."
        Start-Sleep $emptyQueueSecs
    }
    Foreach ($inFile in $inFiles) {
        If (((Get-Date)-$configTime).Seconds -gt $configTimer) {
            $configTime = Get-Config -configFile "$configFile"
            $archiveDir = Join-Path $workingDir "archive"
        }
        $workingOnMessage++
        $message = Get-Content $inFile
        $firstLine = $message | Select-Object -Index (0)
        $message | reformail -s mailbot -T forward -t $emptyFile -f$fromAddress -A "From: $fromAddress" nullmailer-inject -a -f $fromAddress $toAddress
        Move-Item -Path $inFile -Destination $archiveDir
        $messagesRemaining = $messageCount - $workingOnMessage
        Write-Host "Wrote message: $firstLine, Messages remaining: $messagesRemaining"
        $progress = [math]::Round($($workingOnMessage * 100 / $messageCount))
        Write-Progress -Activity "Progress:" -Status "$progress% Complete" -PercentComplete $progress -Id 1
        $sleepCount = 0
        while ($sleepCount -le 99) {
            Start-Sleep $sleepSecs
            $sleepCount = $sleepCount + 1
            Write-Progress -Activity "Progress:" -Status "$sleepCount% Complete" -PercentComplete $sleepCount -ParentId 1
        }
    }
}
Write-Output "That's all, folks!." | mail -s "The spam@donotpay.com queue is empty." -r $fromAddress $fromAddress