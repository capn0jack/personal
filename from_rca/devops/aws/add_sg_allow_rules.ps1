#Pull in the shared functions.
. C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\shared\functions.ps1

Import-Module AWS.Tools.Common
Import-Module AWS.Tools.EC2

#$tokenCode = Read-Host -Prompt "Enter your MFA code:"

Initialize-AWSDefaults -ProfileName default -Region us-east-2

$token = getAwsSessionToken -region us-east-2
$key = $token.AccessKeyId
$secret = $token.SecretAccessKey
$sessionToken = $token.SessionToken

#$token = Get-STSSessionToken -DurationInSeconds 900 -SerialNumber "arn`:aws`:iam`:`:729507891944:mfa`/cmccabe`@recoverycoa.com" -TokenCode $tokenCode
Set-AWSCredential -AccessKey $key -SecretKey $secret -SessionToken $sessionToken

$cidrs = '136.243.0.0/16',
'138.201.0.0/16',
'46.4.0.0/16',
'78.46.0.0/16',
'88.198.0.0/16',
'88.99.0.0/16',
'94.130.0.0/16',
'144.76.0.0/16',
'148.251.0.0/16',
'159.69.0.0/16',
'176.9.0.0/16',
'178.63.0.0/16',
'195.201.0.0/16',
'213.133.96.0/19',
'213.239.192.0/18',
'188.40.0.0/16',
'5.9.0.0/16',
'66.185.20.64/27',
'66.185.31.224/27',
'116.202.0.0/16',
'168.119.0.0/16'



$portpairs = "22-22"
#$groupid = "sg-0c63f77f37bbd6681"
$sgs = "builder"
$proto = "TCP"
$desc = "SSH from Semaphore"

foreach ($sg in $sgs) {
  write-host $sg
  if (-not (sgnameexists "$sg")) {
    $sgsuggestions = getsgnamesbeginningwith -instring "$sg" -numchars 2
    $sgreplacement = picksinglefromlist -listin $sgsuggestions -pretext "The security group name $sg wasn't found." -posttext "Did you mean one of these? If you don't select a value, the script will exit."
    if (-not $sgreplacement) {exit} else {$sg = $sgreplacement}
  }
  $groupid = getsgidfromname $sg

  foreach ($portpair in $portpairs) {
    foreach ($cidr in $cidrs) {
      $iPRange = New-Object -TypeName Amazon.EC2.Model.IpRange
      $iPRange.CidrIp = "$cidr"
      $iPRange.Description = "$desc"
      $portlow = $portpair.split("-")[0]
      $porthigh = $portpair.split("-")[1]
      $iPPermission = new-object Amazon.EC2.Model.IpPermission 
      $iPPermission.IpProtocol = "$proto"
      $iPPermission.FromPort = $portlow
      $iPPermission.ToPort = $porthigh
      $iPPermission.Ipv4Ranges = $iPRange
      try {
        Grant-EC2SecurityGroupIngress -GroupId $groupid -IpPermissions @($iPPermission)
        Write-Host "Allowed access to $groupid on $proto/$portlow-$porthigh from $cidr."
      } catch {
        Write-Host "SOMETHING WENT WRONG allowing access to $groupid on $proto/$portlow-$porthigh from $cidr."
      }
    }
  }

}