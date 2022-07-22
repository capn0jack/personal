. C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\shared\functions.ps1
$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken

$paramBase = "/so/dev/envvars/api/VAR"

$keyArn = "arn:aws:kms:us-east-2:729507891944:key/mrk-8e981cbb23a241da8bd0c10ce8c9d938"

$tag1 = New-Object Amazon.SimpleSystemsManagement.Model.Tag
$tag1.Key = "env"
$tag1.Value = "dev"

$tag2 = New-Object Amazon.SimpleSystemsManagement.Model.Tag
$tag2.Key = "appdelivery"
$tag2.Value = "false"

foreach ($i in 1..50) {
    Write-SSMParameter `
    -Name "$paramBase$i" `
    -Value "VAL$i" `
    -Type "SecureString" `
    -KeyId "$keyArn" `
    -Tags $tag1,$tag2
}