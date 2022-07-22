$configDir = "C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\dokku\cf_config_sets\files\tra"

$rename = @{api = 'caredfor-laravel-rca-export';
cm = 'cm-service-rca-export';
admin = 'caredfor-admin-rca-export';
frontend = 'caredfor-frontend-rca-export';
int = 'caredfor-integrations-rca-export';
assess = 'caredfor-assessments-rca-export';
global = 'caredfor-global-api-rca-export';
sms = 'caredfor-sms-rca-export';
ess = 'employeeselfserve'
}

$files = (Get-ChildItem -Recurse -Path $configDir).FullName

Foreach ($file in $files) {
    $fileName = (Split-Path -Path "$file" -Leaf)
    $configFileBaseName = [io.path]::GetFileNameWithoutExtension("$fileName")
    $newBaseName = ($rename.GetEnumerator() | Where-Object Value -match "$configFileBaseName").Name
    Get-ChildItem -Path $file | Rename-Item -NewName {$_.name -replace "$configFileBaseName","$newBaseName"}
}