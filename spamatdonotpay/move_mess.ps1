$fromAddress="mccachar@consultingprof.com"
#$toAddress="spam@donotpay.com"
$toAddress="mccachar@consultingprof.com"
#$emptyFile="/home/ubuntu/emptyfile"
$emptyFile="c:\temp\emptyfile"
$throttleSecs=30
#$workingDir="/home/ubuntu/working"
$workingDir="c:\temp\working"
$archiveDir=Join-Path $workingDir "archive"

$env:NULLMAILER_FLAGS="t"
$env:NULLMAILER_USER="mccachar"
$env:NULLMAILER_HOST="consultingprof.com"
$env:NULLMAILER_NAME="Charles McCabe"

$workingOnMessage = 0
$inFiles = (Get-ChildItem $workingDir -Depth 0 -File).FullName
$messageCount = $inFiles.Count
Foreach ($inFile in $inFiles) {
    $workingOnMessage++
    $message = Get-Content $inFile
    $firstLine = $message | Select-Object -Index (0)
    $message | reformail -s mailbot -T forward -t $emptyFile -f$fromAddress -A "From: $fromAddress" nullmailer-inject -a -f $fromAddress $toAddress
    Move-Item -Path $inFile -Destination $archiveDir
    $messagesRemaining = $messageCount - $workingOnMessage
    Write-Host "Wrote message: $firstLine, Messages remaining: $messagesRemaining"
    $progress = [math]::Round($($workingOnMessage * 100 / $messageCount))
    Write-Progress -Activity "Progress:" -Status "$progress% Complete" -PercentComplete $progress
    Start-Sleep $throttleSecs
}
Write-Output "That's all, folks!." | mail -s "The spam@donotpay.com queue is empty." -r $fromAddress $fromAddress