Set-DefaultAWSRegion -region us-east-2

$allVols = Get-EC2Volume
foreach ($vol in $allVols) {
    # remove-ec2tag -resource "$($vol.volumeid)" -tag @{ Key="BillToSubtype" } -Force
    # remove-ec2tag -resource "$($vol.volumeid)" -tag @{ Key="Bill_To" } -Force
    # remove-ec2tag -resource "$($vol.volumeid)" -tag @{ Key="Biil_To" } -Force
    # remove-ec2tag -resource "$($vol.volumeid)" -tag @{ Key="OID" } -Force
    If ($vol.attachments.count -gt 0) {
        $volumeid = $vol.volumeid
        $instanceid = $vol.attachments[0].instanceid
        # $passthrough = get-ec2tag -filter @{name="resource-id";value="$instanceid"} | where-object {$_.key -eq "Passthrough"} | select-object -expand value
        # write-host "Setting Passthrough=$passthrough for volume=$volumeid, attached to instance=$instanceid"
        # New-EC2Tag -Resources $volumeid -Tags @( @{ Key = "Passthrough"; Value = "$passthrough"} )
    } else {
        write-host "SKIPPED $($vol.volumeid)"
        Continue
    }
}

$snaps = Get-Ec2snapshot -Ownerid self
foreach ($snap in $snaps) {
    $snapshotid = ""
    $volumeid = ""
    $volume = ""
    $snapshotdesc = ""
    $amiid = ""
    $snapshotid = $snap.snapshotid
    $snapshotdesc = $snap.description
    $volumeid = $snap.volumeid

    Write-Host ""
    Write-host "$snapshotid ($snapshotdesc):"

    #Check if that volume exists.  Maybe there's a cleaner way, but this is doing the trick.
    Try {
        $volume = Get-EC2Volume -VolumeId $volumeid
    } catch {
    }

    
    If ($volume) {
        #If the volume exists, take the Passthrough from that.
        # $passthrough = get-ec2tag -filter @{name="resource-id";value="$volumeid"} | where-object {$_.key -eq "Passthrough"} | select-object -expand value
        # Write-Host "          Got Passthrough of volume $volumeid $(Get-EC2Tag -filter @{name="resource-id";value="$volumeid"} | Where-Object {$_.key -eq "Name"} | Select-Object -expand Value)`: $passthrough"
    } else {
        #Otherwise, run a regex against the snap description to try to pull out an AMI ID and get the Passthrough from that.
        # $snapshotdesc -match 'ami-([a-z]|[0-9]){8,17}' | Out-Null
        # $amiid = $matches[0]
        # If ($amiid) {
        #     $passthrough = get-ec2tag -filter @{name="resource-id";value="$amiid"} | where-object {$_.key -eq "Passthrough"} | select-object -expand value
        #     Write-Host "          Got Passthrough of AMI $amiid $((get-ec2image -ImageId $amiid).name)`: $passthrough"
        #     #Get-EC2SnapshotAttribute -SnapshotId $snapshotid -Attribute createVolumePermission
        # } else {
        #     Write-host "          Couldn't find a Passthrough."
        # }
    }

    # If (-Not $passthrough) {
    #     $passthrough = "No"
    # }

    # write-host "          Setting Passthrough=$passthrough for snapshot=$snapshotid"
    # New-EC2Tag -Resources $snapshotid -Tags @( @{ Key = "Passthrough"; Value = "$passthrough"} )
}

$amis = get-ec2image -owner self
foreach ($ami in $amis) {
    $amiid = $ami.imageid
    $snapshotid = $ami.blockdevicemappings[0].ebs.snapshotid
    $passthrough = get-ec2tag -filter @{name="resource-id";value="$snapshotid"} | where-object {$_.key -eq "Passthrough"} | select-object -expand value
    write-host "Setting Passthrough=$passthrough for AMI=$amiid, based on snapshot=$snapshotid"
    New-EC2Tag -Resources $amiid -Tags @( @{ Key = "Passthrough"; Value = "$passthrough"} )
}