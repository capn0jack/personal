param( 
    [parameter(Mandatory=$false)] 
    [string]$env="dev"
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
$baseDir = getArbitraryParentDir -dir $ScriptDirectory -levelsUp 1
. (Join-Path (Join-Path $baseDir "shared") "functions.ps1")

#!/snap/bin/pwsh
# HOW TO:
# Edit the script.
# Push to GitHub.
# Log onto the Dokku builder as yourself.
# Pull from GitHub.
# sudo su - dokku.
# pwsh
# Run script.

#This is now modified to pull the env vars from AWS Systems Manager Parameter Store.  That means that the builder has to have an IAM profile associated which has permission to read/decrypt the appropriate parameters.  Currently that's ec2-instance-dokku-builder-${env}.

#If this value is present, we will filter the CSV for only records related to the app named here and therefore only make changes for that app.  In theory, you can also use wildcards in here, like "billing*" to get billing and billingapi.
$appFilter = "caredfor-laravel-rca-export"

$appsToRestart = "caredfor-laravel-rca-export"
#""
# "billingapi",`
# "cm-service-rca-export",`
# "billing",`
# "caredfor-assessments-rca-export",`
# "caredfor-laravel-rca-export",`
# "employeeselfserve",`
# "caredfor-frontend-rca-export",`
# "sleep",`
# "00healthcheck"

# "caredfor-integrations-rca-export",`
# "caredfor-admin-rca-export",`
# "caredfor-global-api-rca-export",`

$recreateApps = $false
$scaleApps = $false
$dokkuConfigSets = $true
$dokkuRestartApps = $true
$createCronJobs = $false
$updateTargetNodes = $false
$updatePostDeployScript = $false

$clt = "so"
$domain = "shoutout.com"
$domain2 = ""
$devOpsRepoDir = "/home/cmccabe/source/repos/github/rcatelehealth/devops"
$configSubdir = "deployment"
#$dokkuConfigSetSubdir = "dokku/cf_config_sets/files"
$configFilename = "deployment_config.csv"
$dokkuConfigSetCommand = "dokku config:set --no-restart"

Write-Host ""
Write-Host "================================================================================"
Write-Host "Making sure we have the right PowerShell modules installed..."
Write-Host "================================================================================"

installAndImportRequiredModules -requiredModules "AWS.Tools.Installer" -requiredAWSModules "AWS.Tools.SimpleSystemsManagement"

$configFileDir = Join-Path $devOpsRepoDir $configSubdir
$configFile = Join-Path $configFileDir $configFilename
#$dokkuConfigSetDir = Join-Path (Join-Path (Join-Path $devOpsRepoDir $dokkuConfigSetSubdir) $env) $clt

If ($env -ne "prod") {
    $domain = "$env.$domain"
}

$appsRecreated = @()
$appsConfigured = @()
$cronJobsCreated = @()
$appsScaled = @()
$domainsReset = @()
$serversAll = @()
$appsConfiguredOnBuilder = @()
$appsTargetNodesConfigured = @()
$serverAppsTargetNodesConfigured = @()
$config = ""

If ($recreateApps -and (-Not $resetDomains)) {
    Write-Warning "Setting resetDomains=true because recreateApps=true.  Make sure that's what you want."
    $resetDomains = $true
}

If ($resetDomains -and (-Not $dokkuConfigSets)) {
    Write-Warning "Setting dokkuConfigSets=true because resetDomains=true.  Make sure that's what you want."
    $resetDomains = $true
}

If ($recreateApps -or $resetDomains -or $dokkuRestartApps) {
    $cofirmation = Read-Host -Prompt "You chose the recreateApps, resetDomains and/or dokkuRestartApps options.  These are disruptive, potentially destructive, operations.  To confirm, type 'That's what I want.' (anything else will exit)"
    If (-Not $cofirmation -eq "That's what I want.") {
        Write-Host "Exiting."
        return
    }
}

If ($resetDomains) {
    $cofirmation = Read-Host -Prompt "You chose the resetDomains option.  This will be done for all applications.  To confirm, type 'Got it.' (anything else will exit)"
    If (-Not $cofirmation -eq "Got it.") {
        Write-Host "Exiting."
        return
    }
}

If ($appFilter) {
    $config = Import-Csv "$configFile" | Where-Object { $_.env -like $env -and $_.clt -like $clt -and ($_.appName -like "$appFilter")}
} else {
    $config = Import-Csv "$configFile" | Where-Object { $_.env -like $env -and $_.clt -like $clt}
}

foreach ($line in $config) {
        $serversAll += ,$line.server
}

$serversAll = $serversAll | Sort-Object -Unique

$serversAllFile = (New-TemporaryFile).FullName
Set-Content -Path $serversAllFile $serversAll

If ($resetDomains) {
    # Write-Error "SHOULDN'T HAVE GOTTEN HERE!"
    Write-Host ""
    Write-Host "================================================================================"
    Write-Host "Resetting global domains on all servers..."
    Write-Host "==========================================================s======================"
    parallel-ssh -i -h $serversAllFile -l dokku dokku domains:report
    parallel-ssh -i -h $serversAllFile -l dokku dokku domains:clear-global
    parallel-ssh -i -h $serversAllFile -l dokku dokku domains:add-global $domain
    If ($domain2) {parallel-ssh -i -h $serversAllFile -l dokku dokku domains:add-global $domain2}
    parallel-ssh -i -h $serversAllFile -l dokku dokku domains:report
}

Remove-Item $serversAllFile

foreach ($line in $config) {
    $server = "$($line.server)"
    $vHostNames = $($line.vHostNames).Split(',')
    # $fqdn2 = "$($line.vHostNames).$domain2"
    $app = "$($line.appName)"
    $appShort = "$($line.appNameShort)"
    # write-host "=======> $appShort"
    $certDir = "~/$app/tls"
    # $fileCert2 = "$fqdn2.crt"
    # $fileKey2 = "$fqdn2.key"
    # $fullnameCert2 = "$(Join-Path $certDir $fileCert2)"
    # $fullnameKey2 = "$(Join-Path $certDir $fileKey2)"
    $serverApp = "$server-$app"

    If ($recreateApps) {
        # $serverApp = "$server-$app"
        If ($serverApp -notin $appsRecreated) {
            # Write-Error "SHOULDN'T HAVE GOTTEN HERE!"
            Write-Host ""
            Write-Host "================================================================================"
            Write-Host "Recreating $app on $server..."
            Write-Host "================================================================================"
            ssh dokku@$server dokku ps:scale $app web=0 worker=0 cron=0
            ssh dokku@$server dokku apps:destroy $app --force
            ssh dokku@$server dokku apps:create $app
            If ("localhost-$app" -notin $appsRecreated){
                Write-Host ""
                Write-Host "================================================================================"
                Write-Host "Recreating $app on local host..."
                Write-Host "================================================================================"
                dokku ps:scale $app web=0 worker=0 cron=0
                dokku apps:destroy $app --force
                dokku apps:create $app
                $appsRecreated += ,"localhost-$app"
            }
            $appsRecreated += ,$serverApp
        }
    }

    If ($scaleApps){
        If ($serverApp -notin $appsScaled) {
            # Write-Error "SHOULDN'T HAVE GOTTEN HERE!"
            Write-Host ""
            Write-Host "================================================================================"
            Write-Host "Scaling $app on $server..."
            Write-Host "================================================================================"
            ssh dokku@$server dokku ps:scale --skip-deploy $app web=$($line.scaleWeb) worker=$($line.scaleWorker) cron=$($line.scaleCron)
            $appsScaled += ,$serverApp
        }
    }

    If ($resetDomains) {
        If ($serverApp -notin $domainsReset) {
            # Write-Error "SHOULDN'T HAVE GOTTEN HERE!"
            Write-Host ""
            Write-Host "================================================================================"
            Write-Host "Resetting per-app domains for $app on $server..."
            Write-Host "================================================================================"
            ssh dokku@$server dokku domains:report $app
            ssh dokku@$server dokku domains:clear $app
            ssh dokku@$server dokku letsencrypt:disable $app
            ssh dokku@$server dokku certs:remove $app
            ssh dokku@$server mkdir $certDir

            foreach ($vHostName in $vHostNames) {
                If ($vHostName -eq "@") {
                    $fqdn = $domain
                } else {
                    $fqdn = "$vHostName.$domain"
                }
                $fileCert = "$fqdn.crt"
                $fileKey = "$fqdn.key"
                $fullnameCert = "$(Join-Path $certDir $fileCert)"
                $fullnameKey = "$(Join-Path $certDir $fileKey)"
                ssh dokku@$server dokku domains:add $app $fqdn
                ssh dokku@$server "openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out $($fullnameCert) -keyout $($fullnameKey) -subj '/C=US/ST=Pennsylvania/L=King of Prussia/O=RCA Telehealth/OU=DH/CN=$fqdn'"
                ssh dokku@$server dokku certs:add $app $fullnameCert $fullnameKey
            }
            # If ($domain2) {ssh dokku@$server dokku domains:add $app $fqdn2}
            # if($domain2) {
            #     ssh dokku@$server "openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out $($fullnameCert2) -keyout $($fullnameKey2) -subj '/C=US/ST=Pennsylvania/L=King of Prussia/O=RCA Telehealth/OU=DH/CN=$fqdn2'"
            #     ssh dokku@$server dokku certs:add $app $fullnameCert2 $fullnameKey2
            # }
            ssh dokku@$server dokku domains:report $app
            ssh dokku@$server dokku certs:report $app
            $domainsReset += ,$serverApp
        }
    }

    If ($dokkuConfigSets) {
        # Write-Error "SHOULDN'T HAVE GOTTEN HERE!"
        # $serverApp = "$server-$app"
        $p = New-Object Amazon.SimpleSystemsManagement.Model.ParameterStringFilter
        $p.Key = "Name"
        $p.Option = "BeginsWith"
        $p.Values = "/$clt/$env/envvars/$appShort/"

        $paramNames = (Get-SSMParameterList -ParameterFilter $p).Name

        If ($serverApp -notin $appsConfigured) {

            Write-Host ""
            Write-Host "================================================================================"
            Write-Host "Setting Dokku environment variables for $app on $server..."
            Write-Host "================================================================================"

            foreach ($paramName in $paramNames) {

                # $envvarName = Split-Path -Path $paramName -Leaf
                # $envvarValue = (Get-SSMParameter -Name $paramName -WithDecryption $true).value
                $envvarName,$envvarValue = GetParamStoreParamNameAndValue -paramFullName "$paramName"

                "$dokkuConfigSetCommand $app $envvarName=`'$envvarValue`'" | ssh dokku@$server

            }

            $appsConfigured += ,$serverApp

        }    

        If ($app -notin $appsConfiguredOnBuilder) {
            Write-Host ""
            Write-Host "================================================================================"
            Write-Host "Setting Dokku environment variables for $app on local host..."
            Write-Host "================================================================================"

            foreach ($paramName in $paramNames) {

                # $envvarName = Split-Path -Path $paramName -Leaf
                # $envvarValue = (Get-SSMParameter -Name $paramName -WithDecryption $true).value
                $envvarName,$envvarValue = GetParamStoreParamNameAndValue -paramFullName "$paramName"

                "$dokkuConfigSetCommand $app $envvarName=`'$envvarValue`'" | Invoke-Expression

            }

            $appsConfiguredOnBuilder += ,$app

        }

    }

    If ($createCronJobs) {
        $cronTest = @"
dokku ps:report $app | grep "Status cron 1" | grep running
"@
        $runningCronContainer = $cronTest | ssh dokku@$server 
        # If ($serverApp -notin $cronJobsCreated) {
        $cronText = @"
* * * * * su - dokku -c \"dokku enter $app cron php artisan schedule:run &>> /var/log/dokku/cron.log\"
"@
# Write-Host "This is the cronText:"
# Write-Host $cronText
        If ($runningCronContainer) {
            $commands = @"
(sudo crontab -l | grep -v $app; echo "$cronText") | sudo crontab -
"@
        } else {
            $commands = @"
(sudo crontab -l | grep -v $app) | sudo crontab -
"@
        }
# Write-Host "This is the command:"
# Write-Host $commands
        Write-Host ""
        Write-Host "================================================================================"
        Write-Host "Modifying cron jobs for $app on $server..."
        Write-Host "================================================================================"
#         $commands = @"
# (sudo crontab -l | grep -v nonsense; echo "* * * * * hostname") | sudo crontab -
# "@
        $commands | ssh dokku@$server
        If ($line.scaleCron -gt 0) {
            $cronJobsCreated += ,$serverApp
        }
        $commands = ""
        # }    
    }

    If ($dokkuRestartApps) {
        # Write-Error "SHOULDN'T HAVE GOTTEN HERE!"
        If ($app -in $appsToRestart) {
                Write-Host ""
                Write-Host "================================================================================"
                Write-Host "Restarting $app on $server..."
                Write-Host "================================================================================"
                If ($($line.scaleWeb) -gt 0) {ssh dokku@$server dokku ps:restart $app web}
                If ($($line.scaleWorker) -gt 0) {ssh dokku@$server dokku ps:restart $app worker}
                If ($($line.scaleCron) -gt 0) {ssh dokku@$server dokku ps:restart $app cron}
        }
    }
}

If ($updateTargetNodes) {
    foreach ($line in $config) {
        $server = "$($line.server)"
        $app = "$($line.appName)"
        $serverApp = "$server-$app"
        Write-Host ""
        Write-Host "================================================================================"
        Write-Host "Updating TARGET_NODES for $app on $server..."
        Write-Host "================================================================================"

        If ($serverApp -notin $serverAppsTargetNodesConfigured) {
            $appDir = Join-Path "/" (dokku apps:report $app | grep 'App dir:' | cut `--fields=2- `--delimiter=/)
            $targetNodeFile = Join-Path $appDir "TARGET_NODES"
            If ($app -notin $appsTargetNodesConfigured) {
                $server | Out-File $targetNodeFile
                $appsTargetNodesConfigured += ,$app
            } else {
                $server | Out-File $targetNodeFile -Append
            }
            $serverAppsTargetNodesConfigured += ,$serverApp
        }
    }    
}

If ($updatePostDeployScript) {
    foreach ($line in $config) {
#        $server = "$($line.server)"
        $app = "$($line.appName)"
#        $serverApp = "$server-$app"
        Write-Host ""
        Write-Host "================================================================================"
        Write-Host "Updating POST_DEPLOY_SCRIPT for $app on $server..."
        Write-Host "================================================================================"

#        If ($serverApp -notin $serverAppsTargetNodesConfigured) {
#            $targetNodeFile = Join-Path (Join-Path "/" (dokku apps:report $app | grep 'App dir:' | cut `--fields=2- `--delimiter=/)) "TARGET_NODES"
            If ($app -notin $appPostDeployScriptUpdated) {
                $appDir = Join-Path "/" (dokku apps:report $app | grep 'App dir:' | cut `--fields=2- `--delimiter=/)
                Copy-Item $(Join-Path $configFileDir "POST_DEPLOY_SCRIPT") $appDir -Force
                $scriptFile = $(Join-Path $appDir "POST_DEPLOY_SCRIPT")
                $content = Get-Content $scriptFile
                $appNameLine = @"
appName='$app'
"@
                $content[2] = $appNameLine
                $content | Set-Content $scriptFile
                chmod +x $scriptFile
                $appPostDeployScriptUpdated += ,$app
            }
            #$serverAppsTargetNodesConfigured += ,$serverApp
#        }
    }    
}