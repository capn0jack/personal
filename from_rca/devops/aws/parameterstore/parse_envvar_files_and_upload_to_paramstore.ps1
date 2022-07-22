param( 
    [parameter(Mandatory=$false)]
    [switch]$update=$false #specify that you know some of these parameters already exist and you want to update the values
)

#This is just copied from shared\functions.ps1.  If you find something has to be changed, change it there and copy it here.
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
$baseDir = getArbitraryParentDir -dir $ScriptDirectory -levelsUp 2
. (Join-Path (Join-Path $baseDir "shared") "functions.ps1")

Write-Host ""
Write-Host "================================================================================"
Write-Host "Making sure we have the right PowerShell modules installed..."
Write-Host "================================================================================"

installAndImportRequiredModules -requiredModules "AWS.Tools.Installer" -requiredAWSModules "AWS.Tools.SimpleSystemsManagement"

$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken

$clt = "so"
$env = "prod"

switch ($env) {
    "dev" { 
        $keyArn = "arn:aws:kms:us-east-2:729507891944:key/mrk-8e981cbb23a241da8bd0c10ce8c9d938"
    }
    "qa" { 
        $keyArn = "arn:aws:kms:us-east-2:729507891944:key/mrk-e16cb37163ea4bb3b5a770218dce8acd"
    }
    "sta" { 
        $keyArn = "arn:aws:kms:us-east-2:729507891944:key/mrk-5d216680c4a644728365ec79f707a717"
    }
    "tra" { 
        $keyArn = "arn:aws:kms:us-east-2:729507891944:key/mrk-a38fd7dca36942b3b5e32a69ba1e25e1"
    }
    "prod" { 
        $keyArn = "arn:aws:kms:us-east-2:729507891944:key/mrk-de7d556385e047579262d6e623bec5f1"
    }
    Default {
        Write-Error "This doesn't work if you don't specify an env."
        exit
    }
}

$devOpsRepoDir = "c:\temp\api"
$dokkuConfigSetSubdir = "prod"
# $dokkuConfigSetDir = Join-Path (Join-Path (Join-Path $devOpsRepoDir $dokkuConfigSetSubdir) $env) $clt
$dokkuConfigSetDir = "c:\temp\api\prod"
$files = (Get-ChildItem -Recurse -Path $dokkuConfigSetDir).FullName
# $files = "c:\temp\api.txt"

Foreach ($file in $files) {
    $fileName = (Split-Path -Path "$file" -Leaf)
    $configFileBaseName = [io.path]::GetFileNameWithoutExtension("$fileName")
    $fileContents = Get-Content $file
    foreach ($line in $fileContents) {
        $name,$value = parseEnvVars -line "$line" -stripQuotes
        # If (($line.startswith("#")) -or ([string]::IsNullOrWhiteSpace($line))) {
        #     Continue
        # } elseif (-not $line.Contains("=")) {
        #     Write-Warning "Skipped a line that isn't empty and isn't a comment because it doesn't contain '='.  The line was:`
        #     $line"
        #     Continue
        # } Else {
        #     $envVarArray = $line -Split "=",2
        #     $name = $envVarArray[0]
        #     $value = $envVarArray[1]
        #     If ($value.substring(0,1) -eq "'") {
        #         $value = $value.substring(1)
        #     }
        #     If ($value.Substring($value.Length - 1) -eq "'") {
        #         $value = $value.Substring(0,$value.Length - 1)
        #     }
        If ($name) {
            $tag1 = New-Object Amazon.SimpleSystemsManagement.Model.Tag
            $tag1.Key = "env"
            $tag1.Value = "$env"
            
            $tag2 = New-Object Amazon.SimpleSystemsManagement.Model.Tag
            $tag2.Key = "appdelivery"
            $tag2.Value = "false"

            $paramName = "/$clt/$env/envvars/$configFileBaseName/$name"

            if ($update) {
                $testName = $null
                $testValue = $null
                $testName,$testValue = GetParamStoreParamNameAndValue -paramFullName "$paramName"

                if ($testName){
                    Write-SSMParameter `
                    -Name "$paramName" `
                    -Value "$value" `
                    -Type "SecureString" `
                    -KeyId "$keyArn" `
                    -Overwrite $true

                    #THIS HASN'T BEEN TESTED.  SPECIFICALLY:  NOT 100% SURE THAT THE -FORCE WILL MAKE IT UPDATE EXISTING TAGS AND DON'T KNOW IF -TAG CAN HANDLE MULTIPLE TAGS AT ONCE.
                    Add-SSMResourceTag `
                    -ResourceType "Parameter" `
                    -ResourceId "$paramName" `
                    -Tag $tag1,$tag2 `
                    -Force
                    
                } else {
                    Write-SSMParameter `
                    -Name "$paramName" `
                    -Value "$value" `
                    -Type "SecureString" `
                    -KeyId "$keyArn" `
                    -Tags $tag1,$tag2
                }
            } else {
                try {
                    Write-SSMParameter `
                    -Name "$paramName" `
                    -Value "$value" `
                    -Type "SecureString" `
                    -KeyId "$keyArn" `
                    -Tags $tag1,$tag2
                }
                catch {
                    Write-Warning "Failed to create $paramName.  Does it already exist?"                    
                }
            }
        }
    }
}
