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

#Get all the snaps that don't have the $tagName tag at all.
$untaggedSnaps = Get-Ec2snapshot -Ownerid $ownerid | Where-Object {-Not ($_.tag.key -ccontains "$tagName")}
#Get all the snaps that have the $tagName tag, but it's blank.
$blankTagSnaps = get-ec2snapshot -ownerid $ownerid -filter @{name="tag:$tagName";Values=""}

$snaps = $untaggedSnaps + $blankTagSnaps
# $untaggedSnaps
# exit
# $snaps
$snaps.count
# exit
$i = 0
foreach ($snap in $snaps) {
    write-host "================================="
    $i+=1
    $i
    $snapshotid = ""
    $volumeid = ""
    $volume = ""
    $snapshotdesc = ""
    $amiid = ""
    $snapshotid = $snap.snapshotid
    $snapshotdesc = $snap.description
    $volumeid = $snap.volumeid
    $snap.snapshotid
    $snap.description
    $snap.volumeid

    #Check if that volume exists.  Maybe there's a cleaner way, but this is doing the trick.
    Try {
        $volume = Get-EC2Volume -VolumeId $volumeid
        $volume.VolumeId
    } catch {
        Write-Host "THIS IS A PROBLEM: The volume didn't exist."
    }

    If ($volume) {
        #If the volume exists, take the $tagName from that.
        $tagval = get-ec2tag -filter @{name="resource-id";values="$volumeid"} | where-object {$_.key -eq "$tagName"} | select-object -expand value
        Write-Host "          Got $tagName of volume $volumeid`: $tagval"
    } else {
        #Otherwise, run a regex against the snap description to try to pull out an AMI ID and get the $tagName from that.
        $snapshotdesc -match 'ami-([a-z]|[0-9]){8,17}' | Out-Null
        $amiid = $matches[0]
        If ($amiid) {
            $tagval = get-ec2tag -filter @{name="resource-id";values="$amiid"} | where-object {$_.key -eq "$tagName"} | select-object -expand value
            Write-Host "          Got $tagName of AMI $amiid $((get-ec2image -ImageId $amiid).name)`: $tagval"
            #Get-EC2SnapshotAttribute -SnapshotId $snapshotid -Attribute createVolumePermission
        } else {
            Write-host "          Couldn't find a $tagName."
        }
    }

    If ($tagval) {
        Write-Host "Setting tag $tagval on $snapshotid..."
        New-EC2Tag -Resources $snapshotid -Tags @( @{ Key = "$tagName"; Value = "$tagval"} )
    } else {

    }

}

exit

# $allsnaps = Get-EC2Tag -Filter @{Name="resource-type";Value="snapshot"}

# $snapswith = Get-EC2Tag -Filter @{Name="resource-type";Value="snapshot"},@{Name="key";Value="$tagName"}

# $snapwithout = $allsnaps | Where-Object {$_ -notin $snapswith}

# $snapwithout

# $string = "this is some ami-a0e84ec0 that I want to match"
# $string -match 'ami-([a-z]|[0-9]){8,17}'
# $matches