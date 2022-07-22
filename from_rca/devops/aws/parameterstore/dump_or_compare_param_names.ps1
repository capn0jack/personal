
. C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\shared\functions.ps1
$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken

#Setting this to true will result in the first env in $envs being compared to each subsequent env and the differences will be output.
$compareEnvs = $false

#Setting this to true will result in the first env in $envs being compared to the env vars listed in $file.
$compareToFile = $true
$file = c:\temp\vars.txt

$clt = "so"
$app = "api"
$envs = "dev","qa","tra","sta","prod"

If ($compareEnvs -and ($envs.Count -lt 2)) {
    Write-Error "You set the option to compare sets of variables but gave less than two environment names.  Exiting."
}

If ($compareToFile -and ($envs.Count -gt 1)) {
    Write-Error "You set the option to compare an environment to a file but gave more than one environment name.  Exiting."
}

$fileContents = Get-Content $file
foreach ($line in $fileContents) {
    $name,$value = parseEnvVars -line "$line" -stripQuotes
    If ($name) {
        
    }
}


$paramNames = $null

foreach ($env in $envs) {
    $p = New-Object Amazon.SimpleSystemsManagement.Model.ParameterStringFilter
    $p.Key = "Name"
    $p.Option = "BeginsWith"
    if ($app) {
        $p.Values = "/$clt/$env/envvars/$app/"
    } else {
        $p.Values = "/$clt/$env/envvars/"
    }
 
    New-Variable -Name "paramNames$env" -Value ((Get-SSMParameterList -ParameterFilter $p).Name)
    $paramNames += (Get-Variable -Name "paramNames$env" -ValueOnly)
    Set-Variable -Name "paramNames$env" -Value (Split-Path (Get-Variable -Name "paramNames$env" -ValueOnly) -Leaf)
}

            # foreach ($paramName in $paramNames) {

            #     # $envvarName = Split-Path -Path $paramName -Leaf
            #     # $envvarValue = (Get-SSMParameter -Name $paramName -WithDecryption $true).value
            #     $envvarName,$envvarValue = GetParamStoreParamNameAndValue -paramFullName "$paramName"

            #     "$dokkuConfigSetCommand $app $envvarName=`'$envvarValue`'" | ssh dokku@$server

            # }
if ($compareEnvs) {
    $referenceEnv = $envs[0]
    $paramNamesRef = (Get-Variable -Name "paramNames$referenceEnv" -ValueOnly)
    Foreach ($env in $envs) {
        If ($env -eq $referenceEnv) {continue}
        Write-Host "-------------------------------------------------- Comparing $referenceEnv to $env`:"

        $paramNamesComp = (Get-Variable -Name "paramNames$env" -ValueOnly)

        $compareOutput = Compare-Object $paramNamesComp $paramNamesRef

        Write-Host "------------------------- Unique to $referenceEnv`:"
        ForEach($compareItem in $compareOutput) {
            if($compareItem.sideindicator -eq "=>") {     
                $missingVar = $compareItem.InputObject
                $missingVar
            }
        }

        Write-Host "------------------------- Unique to $env`:"
        ForEach($compareItem in $compareOutput) {
            if($compareItem.sideindicator -eq "<=") {     
                $missingVar = $compareItem.InputObject
                $missingVar
            }
        }

    }
    
} else {
    $paramNames
}