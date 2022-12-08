param( 
    [parameter(Mandatory=$false)]
    [string]$aWSAccountNumber='729507891944',
    [parameter(Mandatory=$false)]
    [string]$aWSRegion='us-east-2',
    [parameter(Mandatory=$true)]
    [string]$imageNameeCR,
    [parameter(Mandatory=$true)]
    [string]$imageTageCR,
    [parameter(Mandatory=$false)]
    [string]$imageNameOther,
    [parameter(Mandatory=$false)]
    [string]$imageTagOther,
    [parameter(Mandatory=$false)]
    [switch]$tagAndPush
)

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$baseDir = getArbitraryParentDir -dir $ScriptDirectory -levelsUp 1
. (Join-Path (Join-Path $baseDir "shared") "functions.ps1")

$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken
(Get-ECRLoginCommand).Password | docker login --username AWS --password-stdin $aWSAccountNumber.dkr.ecr.$aWSRegion.amazonaws.com
 docker pull 729507891944.dkr.ecr.us-east-2.amazonaws.com/testadmin:latest
exit
If ($tagAndPush) {
    docker tag $imageNameOther`:$imageTagOther $aWSAccountNumber.dkr.ecr.$aWSRegion.amazonaws.com/$imageName`:$imageTag
    docker push $aWSAccountNumber.dkr.ecr.$aWSRegion.amazonaws.com/$imageName`:$imageTag
} else {
    docker pull $aWSAccountNumber.dkr.ecr.$aWSRegion.amazonaws.com/$imageName`:$imageTag
}