. C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\shared\functions.ps1
$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken



$paramName = "/so/dev/envvars/api/DB_DATABASE"
(Get-SSMParameter -Name $paramName -WithDecryption $true).value