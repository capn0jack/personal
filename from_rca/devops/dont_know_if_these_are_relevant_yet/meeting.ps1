. /mnt/c/Users/cmccabe/source/repos/github/rcatelehealth/devops/shared/functions.ps1

$numParticipants = 9
$numTeams = 99
Foreach ($participantNum in 1..$numParticipants) {
    Write-Host "LEADER:  OK, Person$participantNum, what do you have for us?"
    Write-Host "Person$($participantNum):  Well, I've been working on The Thing, The Other Thing, and A Couple of Other Things."
    Write-host "Person$($participantNum + (getRandomButNot -not 0 -max 3)):  Did you involve Team$(getRandomButNot -not 0 -max $numTeams), who will make you explain it all again and then take 2 steps backward if you haven't, but not really improve anything?"
    Write-Host "Person$($participantNum):  Not yet, or maybe I'll make sure I do."
    Write-Host "LEADER: Great work Person$($participantNum)."
    Write-host
}