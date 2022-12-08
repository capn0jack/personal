#!/snap/powershell/160/opt/powershell/pwsh
$servers = "main-worker-0","microsvc-worker-0"
While (1 -eq 1) {
    ForEach ($server in $servers) {
        $crontab = $(ssh $server crontab -l 2>/dev/null)
        If (-Not $crontab) {
            $servers = $servers | Where-Object { $_ -ne "$server" }
            write-host "THERE'S NOTHING IN $server's CRONTAB AS OF $(Get-Date)!"
        }
    }
    If ($servers.Count -lt 1) {
        Write-Host "No servers left in list.  Exiting."
        Exit
    }
    start-sleep 60
}