sudo snap install powershell --classic
sudo sh -c 'echo /snap/powershell/160/opt/powershell/pwsh >> /etc/shells'
sudo sh -c "chsh $USER -s /snap/powershell/160/opt/powershell/pwsh"

pwsh

New-Item -ItemType Directory -Force ~\.config\powershell

$profileText = @'
function prompt {
    #Make sure everything here works on both Windows and Linux.
    $username = $env:USER
    If (-Not $username) {
        $username = $env:username
    }
    $hostname = hostname

    "PS [$username@$hostname] $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    # .Link
    # https://go.microsoft.com/fwlink/?LinkID=225750
    # .ExternalHelp System.Management.Automation.dll-help.xml
}
'@

$profileText | Out-File ~\.config\powershell\Microsoft.PowerShell_profile.ps1


$name = "mysql-0"
$dom = "so.int"

$ipstring = hostname -I

$ips = $ipstring.Split()

foreach ($ip in $ips) {
    if ($ip -like "10.*") {
            $ip
            break
        }
    }

$ip

sudo powershell -c "echo $name > /etc/hostname"
sudo powershell -c "hostname $name"
$hostsEntry = "$ip $name.$dom $name"
sudo powershell -c "sh -c 'echo $hostsEntry >> /etc/hosts'"
sudo powershell -c "sh -c 'echo Domains=$dom >> /etc/systemd/resolved.conf'"
sudo powershell -c "systemctl restart systemd-resolved.service"