. ..\..\shared\functions.ps1
$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken

$stackName = "so-sta"
$templateBody = Get-Content .\vpc.yml -Raw
$parameters = Get-Content .\parameters_vpc_sta.json | ConvertFrom-Json
New-CFNStack -Parameter $parameters -StackName $stackName -TemplateBody $templateBody