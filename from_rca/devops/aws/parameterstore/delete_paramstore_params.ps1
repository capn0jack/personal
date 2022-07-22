. C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\shared\functions.ps1
$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken

#Import-Module "AWSPowerShell"
$p = New-Object Amazon.SimpleSystemsManagement.Model.ParameterStringFilter
$p.Key = "Name"
$p.Option = "BeginsWith"
$p.Values = "/so/prod/envvars/"

$params = (Get-SSMParameterList -ParameterFilter $p).name
foreach ($param in $params) {
    $paramName = "$param"
    #Write-Host "Trying to retrieve $paramName"
    # (Get-SSMParameter -Name $paramName -WithDecryption $true).value
    Remove-SSMParameter -Name $paramName -Force
}