function getArbitraryParentDir {
    #This is only designed to work if the given path actually exists.
    param( 
        [parameter(Mandatory=$true)]
        [string]$dir,
        [parameter(Mandatory=$true)]
        [int]$levelsUp
    )
    
    if (-Not (Test-Path -PathType Container $dir)) {
        If (Test-Path -PathType Leaf $dir) {
            $dir = Split-Path -Parent $dir
        } else {
            Write-Error "Supplied path $dir doesn't exist."
        }
    }

    $i=1
    for (;$i -le $levelsUp) {
        $dir = Split-Path -Parent $dir
        Write-Host
        $i++
    }

    return $dir
}

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$baseDir = getArbitraryParentDir -dir $ScriptDirectory -levelsUp 1
. (Join-Path (Join-Path $baseDir "shared") "functions.ps1")

Set-DefaultAWSRegion -region us-east-2
$ownerid = "729507891944"
$tagName = "env"

$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken

#Get all the volumes that don't have the $tagName at all.
$untaggedVols = Get-EC2Volume | Where-Object {-Not ($_.tag.key -ccontains "$tagName")}
#Get all the volumes that have the $tagName tag, but it's blank.
$blankTagVols = Get-EC2Volume -filter @{name="tag:$tagName";Values=""}

$vols = $untaggedVols + $blankTagVols
$vols.count
$i = 0
foreach ($vol in $vols) {
    write-host "================================="
    $i+=1
    $i
    $volumeid = ""
    $volumeid = $vol.VolumeId
    $instanceId = (Get-EC2Volume -VolumeId $volumeid).attachments[0].instanceId
    
    $tagval = get-ec2tag -filter @{name="resource-id";values="$instanceid"} | where-object {$_.key -eq "$tagName"} | select-object -expand value

    If ($tagval) {
        Write-Host "Setting tag $tagval on $volumeid..."
        New-EC2Tag -Resources $volumeid -Tags @( @{ Key = "$tagName"; Value = "$tagval"} )
    } else {

    }

}