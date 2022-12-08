#This isn't safe to run as-is; it's just an example.
#exit

. ..\..\shared\functions.ps1
$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken

$parameter = Get-Content .\parameters_vpc_sta.json | ConvertFrom-Json
$templateBody = Get-Content .\vpc.yml -Raw
New-CFNChangeSet -StackName "so-sta" -ChangeSetName "so-sta-plus-cloudfront" -ChangeSetType UPDATE -TemplateBody $templateBody -Parameter $parameter -ClientToken "002"
Get-CFNChangeSet -StackName "so-sta" -ChangeSetName "so-sta-plus-cloudfront"
# Start-Sleep 45
# Start-CFNChangeSet -StackName "so-sta" -ChangeSetName "so-sta-plus-cloudfront"