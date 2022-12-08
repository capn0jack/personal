param(
[switch]$version
)

#This is the actual version of the script, which will get returned if the script is called with the -version switch, and which is used by SCCM to determine which version is installed.
$scriptversion = "3.00"

#2.07 changes:
#CPM 23Jan2019:  Added functions: getDC,  New-MaintContact, New-Contact, New-DL, New-MaintDL

if ($version) {
    "$scriptversion"
    exit
}

function setuplogging {
param(
    [string]$logdir,
    [string]$logbasename
)
#$logdir = "c:\_admin\scripts\scom\"
#$logbasename = "maint_sched"
$logextension = ".log"
$longTime =  Get-Date -Format "yyyyMMddHHmmss" # Get current time into a string
$logDate =  Get-Date -Format "yyyyMMdd" # Get current month into a string
$logfile = Join-Path $logdir "$logbasename$logDate$logextension"

"==============================================================================================================="  | Out-File -FilePath $logFile -Append
"Logging execution started at $longTime"  | Out-File $logFile -Append

return $logFile
}

function startinstancebyname { 
 #Returns True if we were able to get an instance ID from the instance name and try to start it.  Returns False if we couldn't get an instance ID.
    param( 
        [parameter(Mandatory=$true)] 
        [string]$machine 
    ) 

    $instanceid = getinstanceidfromname $machine
    if ($instanceid) {
        Start-EC2Instance $instanceid
        return $true
        } else {
        return $false
    }
 
}

function stopinstancebyname { 
 
    param( 
        [parameter(Mandatory=$true)] 
        [string]$machine 
    ) 

    $instanceid = getinstanceidfromname $machine
    Stop-EC2Instance $instanceid
 
}

function settimezone { 
 
    param( 
        [parameter(Mandatory=$true)] 
        [string]$TimeZone 
    ) 
     
    $proc = New-Object System.Diagnostics.Process 
    $proc.StartInfo.WindowStyle = "Hidden" 
 
        $proc.StartInfo.FileName = "tzutil.exe" 
        $proc.StartInfo.Arguments = "/s `"$TimeZone`"" 
   
 
    $proc.Start() | Out-Null 
 
}

function testtimezone { 
    param( 
        [parameter(Mandatory=$true)] 
        [string]$TimeZone 
    ) 
 $tz = Invoke-Expression -Command:'cmd.exe /C "tzutil /g"'
 if ("$tz" -eq "$TimeZone") {$true} else {$false}
}

function testnla {
    param( 
        [parameter(Mandatory=$true)] 
        [string]$DesiredState 
    ) 
if ("$DesiredState" -eq "Disabled") {$DesiredState = 0}
elseif ("$DesiredState" -eq "Enabled") {$DesiredState = 1}
$computerName = $env:COMPUTERNAME
$currstate = (Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -ComputerName $ComputerName -Filter "TerminalName='RDP-tcp'").UserAuthenticationRequired
if ("$currstate" -eq "$desiredstate") {$true} else {$false}
}

function setnla {
#CPM 08Nov2017 Read the comments in function "Set-NetworkLevelAuthentication".
    param( 
        [parameter(Mandatory=$true)] 
        [string]$DesiredState 
    ) 
$computerName = $env:COMPUTERNAME
if ("$desiredstate" -eq "Enabled") {
Set-NetworkLevelAuthentication -EnableNLA $true -ComputerName "$computername"
#(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -ComputerName $ComputerName -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(1)
}
elseif ("$desiredstate" -eq "Disabled")
{
Set-NetworkLevelAuthentication -EnableNLA $false -ComputerName "$computername"
#(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -ComputerName $ComputerName -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0)
}
}

function Set-NetworkLevelAuthentication {
<#
#CPM 08Nov2017 Note that rather than trying to strip this guys script down so it works the way I want it to (only for the local computer, only passing in the desired state), I'm going to keep my own "setnla" function and use it to call this function the way I want it to work.
.SYNOPSIS
	This function will set the NLA setting on a local machine or remote machine
.DESCRIPTION
	This function will set the NLA setting on a local machine or remote machine
.PARAMETER  ComputerName
	Specify one or more computers
.PARAMETER EnableNLA
	Specify if the NetworkLevelAuthentication need to be set to $true or $false
.PARAMETER  Credential
	Specify the alternative credential to use. By default it will use the current one.
.EXAMPLE
	Set-NetworkLevelAuthentication -EnableNLA $true
.EXAMPLE
	Set-NetworkLevelAuthentication -EnableNLA $true -computername "SERVER01","SERVER02"
.EXAMPLE
	Set-NetworkLevelAuthentication -EnableNLA $true -computername (Get-Content ServersList.txt)
.NOTES
	DATE	: 2014/04/01
	AUTHOR	: Francois-Xavier Cat
	WWW		: http://lazywinadmin.com
	Twitter	: @lazywinadm
	Article : http://lazywinadmin.com/2014/04/powershell-getset-network-level.html
	GitHub	: https://github.com/lazywinadmin/PowerShell
#>
	#Requires -Version 3.0
	[CmdletBinding()]
	PARAM (
		[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[System.String[]]$ComputerName = $env:ComputerName,
		
		[Parameter(Mandatory)]
		[System.Boolean]$EnableNLA,
		
		[Alias("RunAs")]
		[System.Management.Automation.Credential()]
		$Credential = [System.Management.Automation.PSCredential]::Empty
	)#Param
	BEGIN
	{
		TRY
		{
			IF (-not (Get-Module -Name CimCmdlets))
			{
				Write-Verbose -Message '[BEGIN] Import Module CimCmdlets'
				Import-Module CimCmdlets -ErrorAction 'Stop' -ErrorVariable ErrorBeginCimCmdlets
			}
		}
		CATCH
		{
			IF ($ErrorBeginCimCmdlets)
			{
				Write-Error -Message "[BEGIN] Can't find CimCmdlets Module"
			}
		}
	}#BEGIN
	
	PROCESS
	{
		FOREACH ($Computer in $ComputerName)
		{
			Write-Verbose -message $Computer
			TRY
			{
				# Building Splatting for CIM Sessions
				Write-Verbose -message "$Computer - CIM/WIM - Building Splatting"
				$CIMSessionParams = @{
					ComputerName = $Computer
					ErrorAction = 'Stop'
					ErrorVariable = 'ProcessError'
				}
				
				# Add Credential if specified when calling the function
				IF ($PSBoundParameters['Credential'])
				{
					Write-Verbose -message "[PROCESS] $Computer - CIM/WMI - Add Credential Specified"
					$CIMSessionParams.credential = $Credential
				}
				
				# Connectivity Test
				Write-Verbose -Message "[PROCESS] $Computer - Testing Connection..."
				Test-Connection -ComputerName $Computer -Count 1 -ErrorAction Stop -ErrorVariable ErrorTestConnection | Out-Null
				
				# CIM/WMI Connection
				#  WsMAN
				IF ((Test-WSMan -ComputerName $Computer -ErrorAction SilentlyContinue).productversion -match 'Stack: 3.0')
				{
					Write-Verbose -Message "[PROCESS] $Computer - WSMAN is responsive"
					$CimSession = New-CimSession @CIMSessionParams
					$CimProtocol = $CimSession.protocol
					Write-Verbose -message "[PROCESS] $Computer - [$CimProtocol] CIM SESSION - Opened"
				}
				
				# DCOM
				ELSE
				{
					# Trying with DCOM protocol
					Write-Verbose -Message "[PROCESS] $Computer - Trying to connect via DCOM protocol"
					$CIMSessionParams.SessionOption = New-CimSessionOption -Protocol Dcom
					$CimSession = New-CimSession @CIMSessionParams
					$CimProtocol = $CimSession.protocol
					Write-Verbose -message "[PROCESS] $Computer - [$CimProtocol] CIM SESSION - Opened"
				}
				
				# Getting the Information on Terminal Settings
				Write-Verbose -message "[PROCESS] $Computer - [$CimProtocol] CIM SESSION - Get the Terminal Services Information"
				$NLAinfo = Get-CimInstance -CimSession $CimSession -ClassName Win32_TSGeneralSetting -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'"
				$NLAinfo | Invoke-CimMethod -MethodName SetUserAuthenticationRequired -Arguments @{ UserAuthenticationRequired = $EnableNLA } -ErrorAction 'Continue' -ErrorVariable ErrorProcessInvokeWmiMethod
			}
			
			CATCH
			{
				Write-Warning -Message "Error on $Computer"
				Write-Error -Message $_.Exception.Message
				if ($ErrorTestConnection) { Write-Warning -Message "[PROCESS] Error - $ErrorTestConnection" }
				if ($ProcessError) { Write-Warning -Message "[PROCESS] Error - $ProcessError" }
				if ($ErrorProcessInvokeWmiMethod) { Write-Warning -Message "[PROCESS] Error - $ErrorProcessInvokeWmiMethod" }
			}#CATCH
			FINALLY
			{
				if ($CimSession)
				{
					# CLeanup/Close the remaining session
					Write-Verbose -Message "[PROCESS] Finally Close any CIM Session(s)"
					Remove-CimSession -CimSession $CimSession
				}
			}
		} # FOREACH
	}#PROCESS
	END
	{
		Write-Verbose -Message "[END] Script is completed"
	}
}

function addntfsperm {
     #Example call:
     #addntfsperm -username "AppVUsers" -perm "Modify" -path "d:\environments\workbench"
     #Possible perms: FullControl, ReadAndExecute
    param( 
        [parameter(Mandatory=$true)] 
        [string]$username, 
        [parameter(Mandatory=$true)] 
        [string]$perm, 
        [parameter(Mandatory=$true)] 
        [string]$path
    ) 

    Set-Owner -path $path

    $Acl = (Get-Item $Path).GetAccessControl('Access')
    if ((Get-Item $Path).psiscontainer) {
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("$Username","$perm",'ContainerInherit,ObjectInherit','None','Allow')
    } else {
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("$Username","$perm",'None','None','Allow')
    }

    $Acl.SetAccessRule($Ar)
    Set-Acl -path $Path -AclObject $Acl
    }

Function Set-Owner {
    <#
        .SYNOPSIS
            Changes owner of a file or folder to another user or group.

        .DESCRIPTION
            Changes owner of a file or folder to another user or group.

        .PARAMETER Path
            The folder or file that will have the owner changed.

        .PARAMETER Account
            Optional parameter to change owner of a file or folder to specified account.

            Default value is 'Builtin\Administrators'

        .PARAMETER Recurse
            Recursively set ownership on subfolders and files beneath given folder.

        .NOTES
            Name: Set-Owner
            Author: Boe Prox
            Version History:
                 1.0 - Boe Prox
                    - Initial Version

        .EXAMPLE
            Set-Owner -Path C:\temp\test.txt

            Description
            -----------
            Changes the owner of test.txt to Builtin\Administrators

        .EXAMPLE
            Set-Owner -Path C:\temp\test.txt -Account 'Domain\bprox

            Description
            -----------
            Changes the owner of test.txt to Domain\bprox

        .EXAMPLE
            Set-Owner -Path C:\temp -Recurse 

            Description
            -----------
            Changes the owner of all files and folders under C:\Temp to Builtin\Administrators

        .EXAMPLE
            Get-ChildItem C:\Temp | Set-Owner -Recurse -Account 'Domain\bprox'

            Description
            -----------
            Changes the owner of all files and folders under C:\Temp to Domain\bprox
    #>
    [cmdletbinding(
        SupportsShouldProcess = $True
    )]
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [string[]]$Path,
        [parameter()]
        [string]$Account = 'Builtin\Administrators',
        [parameter()]
        [switch]$Recurse
    )
    Begin {
        #Prevent Confirmation on each Write-Debug command when using -Debug
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Try {
            [void][TokenAdjuster]
        } Catch {
            $AdjustTokenPrivileges = @"
            using System;
            using System.Runtime.InteropServices;

             public class TokenAdjuster
             {
              [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
              internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
              ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
              [DllImport("kernel32.dll", ExactSpelling = true)]
              internal static extern IntPtr GetCurrentProcess();
              [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
              internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr
              phtok);
              [DllImport("advapi32.dll", SetLastError = true)]
              internal static extern bool LookupPrivilegeValue(string host, string name,
              ref long pluid);
              [StructLayout(LayoutKind.Sequential, Pack = 1)]
              internal struct TokPriv1Luid
              {
               public int Count;
               public long Luid;
               public int Attr;
              }
              internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
              internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
              internal const int TOKEN_QUERY = 0x00000008;
              internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
              public static bool AddPrivilege(string privilege)
              {
               try
               {
                bool retVal;
                TokPriv1Luid tp;
                IntPtr hproc = GetCurrentProcess();
                IntPtr htok = IntPtr.Zero;
                retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                tp.Count = 1;
                tp.Luid = 0;
                tp.Attr = SE_PRIVILEGE_ENABLED;
                retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                return retVal;
               }
               catch (Exception ex)
               {
                throw ex;
               }
              }
              public static bool RemovePrivilege(string privilege)
              {
               try
               {
                bool retVal;
                TokPriv1Luid tp;
                IntPtr hproc = GetCurrentProcess();
                IntPtr htok = IntPtr.Zero;
                retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                tp.Count = 1;
                tp.Luid = 0;
                tp.Attr = SE_PRIVILEGE_DISABLED;
                retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                return retVal;
               }
               catch (Exception ex)
               {
                throw ex;
               }
              }
             }
"@
            Add-Type $AdjustTokenPrivileges
        }

        #Activate necessary admin privileges to make changes without NTFS perms
        [void][TokenAdjuster]::AddPrivilege("SeRestorePrivilege") #Necessary to set Owner Permissions
        [void][TokenAdjuster]::AddPrivilege("SeBackupPrivilege") #Necessary to bypass Traverse Checking
        [void][TokenAdjuster]::AddPrivilege("SeTakeOwnershipPrivilege") #Necessary to override FilePermissions
    }
    Process {
        ForEach ($Item in $Path) {
            Write-Verbose "FullName: $Item"
            #The ACL objects do not like being used more than once, so re-create them on the Process block
            $DirOwner = New-Object System.Security.AccessControl.DirectorySecurity
            $DirOwner.SetOwner([System.Security.Principal.NTAccount]$Account)
            $FileOwner = New-Object System.Security.AccessControl.FileSecurity
            $FileOwner.SetOwner([System.Security.Principal.NTAccount]$Account)
            $DirAdminAcl = New-Object System.Security.AccessControl.DirectorySecurity
            $FileAdminAcl = New-Object System.Security.AccessControl.DirectorySecurity
            $AdminACL = New-Object System.Security.AccessControl.FileSystemAccessRule('Builtin\Administrators','FullControl','ContainerInherit,ObjectInherit','InheritOnly','Allow')
            $FileAdminAcl.AddAccessRule($AdminACL)
            $DirAdminAcl.AddAccessRule($AdminACL)
            Try {
                $Item = Get-Item -LiteralPath $Item -Force -ErrorAction Stop
                If (-NOT $Item.PSIsContainer) {
                    If ($PSCmdlet.ShouldProcess($Item, 'Set File Owner')) {
                        Try {
                            $Item.SetAccessControl($FileOwner)
                        } Catch {
                            Write-Warning "Couldn't take ownership of $($Item.FullName)! Taking FullControl of $($Item.Directory.FullName)"
                            $Item.Directory.SetAccessControl($FileAdminAcl)
                            $Item.SetAccessControl($FileOwner)
                        }
                    }
                } Else {
                    If ($PSCmdlet.ShouldProcess($Item, 'Set Directory Owner')) {                        
                        Try {
                            $Item.SetAccessControl($DirOwner)
                        } Catch {
                            Write-Warning "Couldn't take ownership of $($Item.FullName)! Taking FullControl of $($Item.Parent.FullName)"
                            $Item.Parent.SetAccessControl($DirAdminAcl) 
                            $Item.SetAccessControl($DirOwner)
                        }
                    }
                    If ($Recurse) {
                        [void]$PSBoundParameters.Remove('Path')
                        Get-ChildItem $Item -Force | Set-Owner @PSBoundParameters
                    }
                }
            } Catch {
                Write-Warning "$($Item): $($_.Exception.Message)"
            }
        }
    }
    End {  
        #Remove priviledges that had been granted
        [void][TokenAdjuster]::RemovePrivilege("SeRestorePrivilege") 
        [void][TokenAdjuster]::RemovePrivilege("SeBackupPrivilege") 
        [void][TokenAdjuster]::RemovePrivilege("SeTakeOwnershipPrivilege")     
    }
}

function createremoteapp {
#Example call:
#createremoteapp -path "d:\environments\desktop\exe\cc3.exe" -basename "cc3" -env "PROD"

    param( 
        [parameter(Mandatory=$true)] 
        [string]$path, 
        [parameter(Mandatory=$true)] 
        [string]$basename, 
        [parameter(Mandatory=$true)] 
        [string]$env
    ) 
import-module remotedesktopservices
$filename = split-path $path -leaf
new-item -path RDS:\RemoteApp\RemoteAppPrograms -name "$basename $env" -applicationname "$filename $env" -ApplicationPath "$path" -CommandLineSetting 0
}

function sendemail {
param (
    [parameter(Mandatory=$false)]
    [string]$SmtpServer,
    [parameter(Mandatory=$true)]
    [string]$from,
    [parameter(Mandatory=$true)]
    [string]$to,
    [parameter(Mandatory=$true)]
    [string]$subject,
    [parameter(Mandatory=$false)]
    [string]$body,
    [parameter(Mandatory=$false)]
    [string]$attachments
)

$cmdletexists = checkcmdletexists "Resolve-DNSName"

$smtpservers = @()

if (-not $SmtpServer) {
    if ($cmdletexists) { 
        $todomain = $($to -split "@")[1]
        $fromdomain = $($from -split "@")[1]

        $result = (Resolve-DnsName -name smtpprod).name
        if ($result) {$smtpservers += $result[0]} #Look up the name "smtpprod" in the local domain and add that.

        $result = (Resolve-DnsName -name "$todomain" -type MX).nameexchange
        if ($result) {$smtpservers += $result[0]} #add the MX server for the target domain.

        if ($todomain -ne $fromdomain) { 
            $result = (Resolve-DnsName -name "$fromdomain" -type MX).nameexchange
            if ($result) {$smtpservers += $result[0]} #Add the MX server for the target domain.
        }
    }
    $smtpservers += "some_host_that_we_will_always_try"
}
else {
    $smtpservers += $smtpserver   
}

foreach ($smtpserver in $smtpservers) {
    $messageParameters = @{
    Subject = "$subject"
    Body = "$body"
    From = "$from"
    To = "$to"
    SmtpServer = "$smtpserver"
    }

    if ($attachments) {
        Send-MailMessage @messageParameters -Attachments "$attachments"
    }
    else {
        Send-MailMessage @messageParameters

    }

    if ($?) {break}
}
return $?
}

function checkcmdletexists {
param (
    [parameter(Mandatory=$true)]
    [string]$cmdlet
    )
if (Get-Command $cmdlet -CommandType Cmdlet -errorAction SilentlyContinue) {return $true} else {return $false}
}

function instancenameexists {
#Returns $true if an instance with that name already exists, $false if it doesn't.
param( 
        [parameter(Mandatory=$true)] 
        [string]$instancename

    )
$available = $null
#$available = ((Get-EC2Instance -filter @{name="tag:Name"; values="$instancename"}).instances).instanceid
    $available = ((get-ec2instance).instances).tags | ? {$_.key -eq "Name"} | select -ExpandProperty Value | where {$_ -like "$instancename"}

if (-not $available) {return $false} else {return $true}
}

function sgnameexists {
#Returns $true if a security group with that name already exists, $false if it doesn't.
param( 
        [parameter(Mandatory=$true)] 
        [string]$sgname

    )
$sgid = $null
try {
$sgid = (Get-EC2SecurityGroup | where {$_.GroupName -eq "$sgname"}).groupid
}
catch {
$sgid = $false
}

if (-not $sgid) {return $false} else {return $true}
}

function getsgidfromname {
#Returns the security group ID corresponding to the given security group name.
param( 
        [parameter(Mandatory=$true)] 
        [string]$instancename
    )

#This is gruesome, but because people are terrible and didn't name SGs according to any standard, we're going to fake some stuff out here. I'll try to be smart about it by checking if the non-standard name exists, then doing the kludge assignment, so when/if the naming is corrected, this will become automatic again.
switch ($instancename) 
    { 
        FTP {if (sgnameexists "FTP_sec_grp") {$instancename = "FTP_sec_grp"}} 
        IMPDAWSSQL01 {if (sgnameexists "IMPDAWSSQL2016-01") {$instancename = "IMPDAWSSQL2016-01"}} 
    }
if (sgnameexists "$instancename") {
    $sgid = (Get-EC2SecurityGroup | where {$_.groupname -eq "$instancename"}).groupid
}

if (-not $sgid) {
write-host "Failed to get the security group ID for $instancename.  Exiting script."
exit
}
else
{return $sgid}
}

function taginstance {
 #Adds arbitrary tags to an instance.
 #Example call:
 #taginstance -instanceid "i-05c42a23e0afedc99" -tagname "Name" -tagvalue "TheInstanceName"
 param( 
        [parameter(Mandatory=$true)] 
        [string]$instanceid, 
        [parameter(Mandatory=$true)] 
        [string]$tagname,
        [parameter(Mandatory=$true)] 
        [string]$tagvalue
    )
$tag = New-Object Amazon.EC2.Model.Tag
$tag.Key = "$tagname"
$tag.Value = "$tagvalue"

New-EC2Tag -Resource $instanceid -Tags $tag
}

function assignneweip {
#Allocates a new elastic IP, assigns it to an instance, and returns the EIP.
param( 
        [parameter(Mandatory=$true)] 
        [string]$instanceid
)
$allocationid = (New-EC2Address -domain vpc).AllocationId
Register-EC2Address -InstanceId $instanceid -AllocationId $allocationid
$publicip = (get-ec2address -allocationid $allocationid).publicip
return $publicip
}

function getinstanceidfromname {
#Returns the instance ID of an instance matching a given name.
param( 
        [parameter(Mandatory=$true)] 
        [string]$instancename

    )
$instanceid = $null
$propername = ((get-ec2instance).instances).tags | ? {$_.key -eq "Name"} | select -ExpandProperty Value | where {$_ -like "$instancename"}
$instanceid = ((Get-EC2Instance -filter @{name="tag:Name"; values="$propername"}).instances).instanceid
if (-not $instanceid) {
    write-host "Failed to get the instance ID for $instancename.  Exiting script."
    #exit
} else {return $instanceid}
}

function GetInstanceNamesBeginningWith {
   param(
        [parameter(Mandatory=$true)] 
        [string]$instring, 
        [parameter(Mandatory=$true)] 
        [int]$numchars
    )
    $teststring = $instring.Substring(0,$numchars)
    $instancenames = ((get-ec2instance).instances).tags | ? {$_.key -eq "Name"} | select -ExpandProperty Value | where {$_ -like "$teststring*"}
    $instancenames
}

function pickmultiplefromlist {
    #Takes an array and some text (pre-list and post-list prompts) and then has the user select an arbitrary number of items from that array.
    param( 
            [parameter(Mandatory=$true)] 
            [array]$listin,
            [parameter(Mandatory=$true)] 
            [string]$pretext,
            [parameter(Mandatory=$true)] 
            [string]$posttext
            )
    printaline
    write-host "$pretext"
    $listout=@()
    [int] $i = 0
    [int] $selection = $null
    foreach ($item in $listin) {
        write-host $($i+1) `t $item
        $i++
    }
    do {
        write-host "$posttext"
        $selection = Read-Host "Select one at a time. To quit, press ENTER without making a selection. (1-$i)"
        if (-not $selection -eq 0) {
            if (($selection -lt 1) -or ($selection -gt $i)) {
                write-host "Invalid selection. Try again."
            }
            else
            {$listout+=$listin[$($selection-1)]}
        }
    }
    while
    ($selection)
    return $listout
}

function picksinglefromlist {
#Takes an array and some text (pre-list and post-list prompts) and then has the user select a single item from that array.
param( 
        [parameter(Mandatory=$true)] 
        [array]$listin,
        [parameter(Mandatory=$true)] 
        [string]$pretext,
        [parameter(Mandatory=$true)] 
        [string]$posttext
        )
printaline
write-host "$pretext"
$itemout = $null
$i=0
$selection = "UNSET"
foreach ($item in $listin) {
write-host $i `t $item
$i++
}
do {
write-host "$posttext"
$selection = Read-Host "Make a selection. (0-$($i-1))"
if ($selection) {
if (($selection -lt 0) -or ($selection -gt $($i-1))) {
write-host "Invalid selection. Try again."
}
else
{$itemout = $listin[$selection]
return $itemout
break
}
}
}
while
($selection)
}

function getlist {
#Prompts the user to provide a list of values and optionally returns a default value if they don't.
param( 
        [parameter(Mandatory=$false)] 
        [string]$pretext,
        [parameter(Mandatory=$true)] 
        [string]$posttext,
        [parameter(Mandatory=$false)] 
        [string]$default
        )
    $outlist = @()
    $entry = "UNSET"
    do {
        printaline
        write-host "$pretext"
        write-host "$posttext"
        $entry = read-host "Enter text"
        if ($entry) {
            $outlist += $entry
        } else {
            if (($default) -and ($outlist.Length -eq 0)) {
                $outlist += $default
            }
        }
    } until (-not $entry)
        return $outlist
}

function printaline {
#Just prints a line for visual effect.
write-host "================================================================================"
}

function getyesno {
#Prompts the user to provide a Yes/No answer and optionally sets a default.
param( 
        [parameter(Mandatory=$false)] 
        [string]$pretext,
        [parameter(Mandatory=$true)] 
        [string]$posttext,
        [parameter(Mandatory=$false)] 
        [string]$default
        )
$selection = "UNSET"

if ($default) {$prompt = "Enter Yes or No.  If left blank, will default to $default. (Yes/No)"} else {$prompt = "Enter Yes or No. (Yes/No)"}

printaline
write-host "$pretext"

while (1 -eq 1) {
    write-host "$posttext"
    $selection = read-host "$prompt"
    if ((-not $selection) -and ($default)) {
        $selection = $default
        break
    }
    elseif (($selection -eq "Yes") -or ($selection -eq "No")) {
        break
    }
    else {write-host "Invalid selection.  Try again."}
}

return $selection
}

function getsinglevalue {
#Prompts the user to provide one arbitrary value and optionally set a default if they don't.
param( 
        [parameter(Mandatory=$false)] 
        [string]$pretext,
        [parameter(Mandatory=$true)] 
        [string]$posttext,
        [parameter(Mandatory=$false)] 
        [string]$default
        )
$selection = "UNSET"

if ($default) {$prompt = "If left blank, will default to $default. Enter a value"} else {$prompt = "Enter a value"}

printaline
write-host "$pretext"

while (1 -eq 1) {
    write-host "$posttext"
    $selection = read-host "$prompt"
    if ($selection) {
        break
    } else {
        if ($default) {
            $selection = $default
            break
        } else {
            break
        }
    }
}

return $selection
}

function creatededicatedsg {
#Creates a security group named the same as an instance and returns the security group ID.
param( 
        [parameter(Mandatory=$true)] 
        [string]$instancename,
        [parameter(Mandatory=$true)] 
        [string]$vpcid
      )
$sgid = new-ec2securitygroup -vpcid $vpcid -groupname $instancename -groupdescription "Dedicated SG for $instancename"
return $sgid
}

function applysgsbyinstancename() {
#Applies all the appropriate security groups to a given instance name.  Takes in an array of security group IDs and then adds the SG named the same as the instance.  This can be made more portable in a couple of ways.  The first would be to make the $instanceinfo table optional and look up the instance ID in AWS if (-not $instanceinfo).
param( 
        [parameter(Mandatory=$true)] 
        [array]$instanceinfo,
        [parameter(Mandatory=$true)] 
        [array]$instancenames,
        [parameter(Mandatory=$true)] 
        [array]$sgs
        )
foreach ($instancename in $instancenames) {
    $instanceid = $instanceinfo.where({$_.instancename -eq "$instancename"}).instanceid
    $sgid = $instanceinfo.where({$_.instancename -eq "$instancename"}).sgid
    $sgs += $sgid
    edit-EC2InstanceAttribute -InstanceId $instanceid -Group @($sgs)
    }
}

function launchinstance {
#Launches an new AWS instance and returns the new instance ID.
    param( 
        [parameter(Mandatory=$true)] 
        [string]$imageid, 
        [parameter(Mandatory=$true)] 
        [string]$keyname, 
        [parameter(Mandatory=$true)] 
        [string]$securitygroupid,
        [parameter(Mandatory=$true)] 
        [string]$instancetype,
        [parameter(Mandatory=$true)] 
        [string]$subnetid,
        [parameter(Mandatory=$true)] 
        [string]$computername,
        [parameter(Mandatory=$true)] 
        [string]$billto
    ) 
$reservationid = (New-EC2Instance -imageid $imageid -keyname $keyname -securitygroupid $securitygroupid -instancetype $instancetype -subnetid $subnetid).reservationid
$filter_reservation = New-Object Amazon.EC2.Model.Filter -Property @{Name = "reservation-id"; Values = $reservationid}
$instanceid = ((Get-EC2Instance -Filter $filter_reservation).Instances).instanceid
$instanceid
    }
    
function nameinstance {
#Generates a name for an instance according to a standard format and assigns that name, if it doesn't exist already.
param( 
        [parameter(Mandatory=$true)] 
        [string]$client, 
        [parameter(Mandatory=$true)] 
        [string]$imagetype,
        [parameter(Mandatory=$true)] 
        [string]$env,
        [parameter(Mandatory=$true)] 
        [int]$number

    )
    if ($number -lt 10) {$pad = "0"}
$instancename = $client+$imagetype+$env+$pad+$number
if (instancenameexists $instancename) {
write-host "The instance name we're trying to create, $instancename, already exists.  Exiting script.  Maybe someday we'll account for this better."
exit
}
return $instancename
}

Function Set-ExSessionName {
$sessionName = (get-date -Format o).ToString()
$sessionName
}

Function Connect-Ex  {
    param(
    [string] $sessionName
    )
    $UserCredential = Get-Credential
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection -Name $sessionName -WarningAction SilentlyContinue
    # -AllowRedirection​
    $output = Import-PSSession $Session -AllowClobber -DisableNameChecking
    $output
}

Function Disconnect-Ex  {
    param(
    [String]$sessionName
    ) 
     Remove-PSSession -Name $sessionName
     Write-Color -Text "[*] Disconnected from $sessionName" -Color Yellow
}

Function Remove-StringLatinCharacters {
    PARAM (
    [string]$String
    )
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}

Function Write-Color {
    param(
    [String[]]$Text,
    [ConsoleColor[]]$Color = "White",
    [int]$StartTab = 0,
    [int] $LinesBefore = 0,
    [int] $LinesAfter = 0
    ) 
    $DefaultColor = $Color[0]
    if ($LinesBefore -ne 0) {  for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } } # Add empty line before
    if ($StartTab -ne 0) {  for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }  # Add TABS before text
    if ($Color.Count -ge $Text.Count) {
        for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine } 
    } else {
        for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
        for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine }
    }
    Write-Host
    if ($LinesAfter -ne 0) {  for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }  # Add empty line after
}

function GetADOUGUIDByName {
    param(
        [string]$ouname
    )
    
    $ouguid = $null

    try {
        $ouguid = @(Get-ADorganizationalunit -Identity $ouname).objectguid
    }
    catch {
    }
    if ($ouguid) {
        $ouguid
    }
}

function GetADGroupGUIDByName {
    param(
        [string]$groupname
    )
    
    $groupguid = $null

    try {
        $groupguid = @(Get-ADGroup -Identity $groupname).objectguid
        #$groupsid = @(Get-ADGroup -Identity $groupname).sid
    }
    catch {
    }
    if ($groupguid) {
        $groupguid
    }
}

function GetADComputerGUIDByName {
    param(
        [string]$computername
    )
    
    $computerguid = $null

    try {
        $computerguid = @(Get-ADcomputer -Identity $computername).objectguid
    }
    catch {
    }
    if ($computerguid) {
        $computerguid
    }
}

function GetADAccountPasswordLastSet {
    param(
        [string]$accountname
    )
    
    $passwordLastSet = $null

    try {
        $passwordLastSet = (Get-ADUser -Identity "$accountname" -Properties PasswordLastSet).PasswordLastSet
    }
    catch {
    }
    if ($passwordLastSet) {
        return $passwordLastSet
    }
}

function GetADAccountEnabled {
    param(
        [string]$accountname
    )
    
    $enabled = $null

    #try {
        $enabled = (Get-ADUser -Identity "$accountname" -Properties enabled).enabled
    #}
    #catch {
    #}
    #if ($enabled) {
        return $enabled
    #}
}

function GetADPasswordExpired {
    param(
        [string]$accountname
    )
    
    $expired = $null

    try {
        $expired = (Get-ADUser -Identity "$accountname" -Properties PasswordExpired).PasswordExpired
    }
    catch {
    }
    if ($expired) {
        return $expired
    }
}

function GetADAccountLockedOut {
    param(
        [string]$accountname
    )
    
    $locked = $null

    try {
        $locked = (Get-ADUser -Identity "$accountname" -Properties LockedOut).LockedOut
    }
    catch {
    }
    if ($locked) {
        return $locked
    }
}

function ResetADPassword {
    param(
        [string]$accountname
    )
    
    $pass = $null
    $pass = Get-RandPass -length 8
    try {
        Set-ADAccountPassword -Reset -Identity "$accountname" -NewPassword (ConvertTo-SecureString -AsPlainText "$pass" -Force)
        ForceADPasswordChange -accountname "$accountname"
    }
    catch {
    }
    if ($pass) {
        return $pass
    }
}

function UnlockADAccount {
    param(
        [string]$accountname
    )
    
    try {
        Unlock-ADAccount -Identity "$accountname"
    }
    catch {
    }
}

function ForceADPasswordChange {
    param(
        [string]$accountname
    )
    
    try {
        Set-ADUser -Identity "$accountname" -ChangePasswordAtLogon $true
    }
    catch {
    }
}

function GetADAccountDN {
    param(
        [string]$accountname
    )
    
    $dn = $null

    try {
        $dn = (Get-ADUser -Identity "$accountname" -Properties distinguishedname).distinguishedname
    }
    catch {
    }
    if ($dn) {
        return $dn
    }
}

function GetADAccountOU {
    param(
        [string]$accountname
    )
    
    $ou = $null

     try {
        $user = get-aduser -Identity "$accountname" -Properties *
        $dn = $user.distinguishedname
        $cn = $user.cn
        $ou = $dn -replace "cn=$cn,"
     }
     catch {
     }
     if ($ou) {
        return $ou
     }
}

function GetADAccountOULeafName {
    param(
        [string]$accountname
    )
    
    $ou = $null

     try {
        $user = get-aduser -Identity "$accountname" -Properties *
        $dn = $user.distinguishedname
        $cn = $user.cn
        $ou = $dn -replace "cn=$cn,"
        $LeafName = ($ou.Split(',')[0]).Split('=')[1]
     }
     catch {
     }
     if ($LeafName) {
        return $LeafName
     }
}

function TestADAccountsInSameOU {
    param(
        [array]$accountnames
    )
    
    $result = ""

    try {
        If ("$(GetADAccountOU -accountname $accountnames[0])" -eq "$(GetADAccountOU -accountname $accountnames[1])") {
            $result = $True
        } else {
            $result = $False
        }
    }
    catch {
    }
    # if ($result -ne "FUNCTION_FAILED") {
        return $result
    # }

}

function GetCurrentUsername {
   
    $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split("\")[1]

    return $username
}

function TestADAccountExists {
    param(
        [string]$accountname
    )

    if (-not [bool] (Get-ADUser -Filter { SamAccountName -eq $accountname })) {
        return $False
    } else {
        return $True
    }
}

function GetSGNamesBeginningWith {
    param(
        [parameter(Mandatory=$true)] 
        [string]$instring, 
        [parameter(Mandatory=$true)] 
        [int]$numchars
    )
    $teststring = $instring.Substring(0,$numchars)
    $sgnames = (Get-EC2SecurityGroup | where {$_.groupname -like "$teststring*"}).GroupName
    $sgnames
}

function GetInstanceNamesBeginningWith {
   param(
        [parameter(Mandatory=$true)] 
        [string]$instring, 
        [parameter(Mandatory=$true)] 
        [int]$numchars
    )
    $teststring = $instring.Substring(0,$numchars)
    $instancenames = ((get-ec2instance).instances).tags | ? {$_.key -eq "Name"} | select -ExpandProperty Value | where {$_ -like "$teststring*"}
#    $instancenames = ((get-ec2instance -filter @{Name="tag:Name";Value="$teststring*"}).instances).tags | ? {$_.key -eq "Name"} | select -ExpandProperty Value
    $instancenames
}

function GetInstanceNameFromID ($instanceId) {
 
$tags = (Get-EC2Instance).RunningInstance | Where-Object {$_.instanceId -eq $instanceId} |select Tag
$tagName = $tags.Tag | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value
 
return $tagName
 
}

function GetInstanceSGIDs ($instanceId) {
    $groups = (Get-EC2InstanceAttribute -InstanceId $instanceid -Attribute groupSet).Groups.GroupId
    return $groups
}

function GetSGNameFromID ($sgid) {
    $groupname = (Get-EC2SecurityGroup -GroupId $sgid).GroupName
    return $groupname
}

function CheckSuggestObject {
   param(
        [parameter(Mandatory=$true)] 
        [string]$objecttype, 
        [parameter(Mandatory=$true)] 
        [string]$object, 
        [parameter(Mandatory=$true)] 
        [int]$numchars
    )
    switch ($objecttype) 
    { 
        instance {
            if (-not (instancenameexists "$object")) {
                $names = GetInstanceNamesBeginningWith -instring $object -numchars $numchars
                $replacement = picksinglefromlist -listin $names -pretext "The name $object wasn't found." -posttext "Did you mean one of these? If you don't select a value, the script will exit."
                if (-not $replacement) {exit} else {$object = $replacement}
            }
        }
        securitygroup {
            if (-not (sgnameexists "$object")) {
                $names = GetSGNamesBeginningWith -instring $object -numchars $numchars
                $replacement = picksinglefromlist -listin $names -pretext "The name $object wasn't found." -posttext "Did you mean one of these? If you don't select a value, the script will exit."
                if (-not $replacement) {exit} else {$object = $replacement}
            }
        }
    }
return $object
}

function createPath {
    param( 
    [parameter(Mandatory=$true)] 
    [string]$newdir
    )

    $drive = split-path "$newdir" -Qualifier

    $driveexists = test-path $drive
    if ($driveexists) {
        $directoryexists = test-path "$newdir"
        if (-not $directoryexists) {
            md "$newdir"
        }
        else
        {
            $result = "DirExists"
        }
    }
    else
    {
    $result = "DriveNoExist"
    }
}

#function createPath {
#    $assettag = Get-WmiObject -Class Win32_SystemEnclosure | ForEach-Object {$_.SMBIOSAssetTag}
#    return $assettag
#}

function checkWindowsService {
    param( 
    [parameter(Mandatory=$true)] 
    [string]$serviceName
    )

    If (Get-Service $serviceName -ErrorAction SilentlyContinue) {
        If ((Get-Service $serviceName).Status -eq 'Running') {
            return "Running"
            } Else {
            return "NotRunning"
        }
    } Else {
    return "NotFound"
    }
}

function TestRegistryValue {
 
    param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Path,
 
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Value
    )
 
    try {
        Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
        return $true
        }
        catch {
        return $false
        }
}

function CompareFileSize {
#CPM 25Oct2018 Given two string file paths, returns:
#0 if there's a problem accessing the files
#1 if File1 is bigger
#2 if File2 is bigger
#3 if the files are the same size

    param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$file1,
 
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$file2
    )

    if ((Test-Path "$file1" -PathType Leaf) -and (Test-Path "$file2" -PathType Leaf)) {} else {return 0}

    $file1length = $file1.length
    $file2length = $file2.length

    if ($file1length -gt $file2length) {return 1}
        else
        {
        if ($file1length -lt $file2length) {return 2}
            else
            {
            return 3
        }
    }

}

function DeleteOldFiles {
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TargetDir,
 
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int]
        $MaxAgeDays,
    
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Extension,

        [parameter()]
        [switch]
        $Recurse,

        [parameter()]
        [switch]
        $OnlyCount
    )
    #CPM 25Oct2018 Deletes files from a specified directory older than a specified number of days.
    $Now = Get-Date
    $LastWrite = $Now.AddDays(-$MaxAgeDays)
    if ($recurse) {
        $Files = Get-Childitem $TargetDir -Filter $Extension -Recurse | Where {$_.LastWriteTime -le "$LastWrite"}
        } else {
        $Files = Get-Childitem $TargetDir -Filter $Extension | Where {$_.LastWriteTime -le "$LastWrite"}
    }

    if ($OnlyCount) {
        return $files.count
    }
    else {
        foreach ($File in $Files) {
            if ($File -ne $NULL) {
                Remove-Item $File.FullName | out-null
            }
        }
    }
}

function ModuleExists { 
 
    param( 
        [parameter(Mandatory=$true)] 
        [string]$modulename 
    ) 
    
    if (Get-Module -ListAvailable -Name "$modulename") {return $true} else {return $false}
}

function installAndImportRequiredModules { 
 
    param( 
        [parameter(Mandatory=$true)] 
        [string]$requiredModules,
        [parameter(Mandatory=$true)] 
        [string]$requiredAWSModules
    )

    foreach ($requiredModule in $requiredModules) {
        If ( -Not (ModuleExists $requiredModule)) {
            Install-Module -Name $requiredModule -Force
        }
        Import-Module $requiredModule
    }

    foreach ($requiredAWSModule in $requiredAWSModules) {
        If ( -Not (ModuleExists $requiredAWSModule)) {
            Install-AWSToolsModule $requiredAWSModule -Force -CleanUp
        }
        Import-Module $requiredAWSModule
    }

    #We should do error handling here and return any failures, but that's for another day.
}

function GetSecurityGroupNameByID { 
 
    param( 
        [parameter(Mandatory=$true)]
        [string]$GroupID 
    ) 
    
    $(Get-EC2SecurityGroup -GroupId $GroupID).groupname
}

function GetFileVersion {
    param( 
        [parameter(Mandatory=$true)]
        [string]$file
    )

    $major = (get-item "$file").versioninfo.filemajorpart
    $minor = (get-item "$file").versioninfo.fileminorpart
    $build = (get-item "$file").versioninfo.filebuildpart
    $private = (get-item "$file").versioninfo.fileprivatepart

    return $major,$minor,$build,$private
}

function getDC {
    $logonserver = $env:LOGONSERVER
    $userdnsdomain = $env:USERDNSDOMAIN
    $dc = ($logonserver.split('\')[2])+"."+$userdnsdomain
    return $dc
}

function New-MaintContact {
#This is essentially just a wrapper for the New-Contact function which feeds the right default OU for a maintenance notification contact.
    param( 
        [parameter(Mandatory=$false)] 
        [string]$ou="ou_here", 
        [parameter(Mandatory=$true)] 
        [string]$FirstName, 
        [parameter(Mandatory=$true)] 
        [string]$LastName, 
        [parameter(Mandatory=$true)] 
        [string]$EmailAddress, 
        [parameter(Mandatory=$true)] 
        [string]$Description, 
        [parameter(Mandatory=$true)] 
        [string]$ClientShortName,
        [parameter(Mandatory=$false)]
        [ValidateSet("hosted","onprem")] 
        [string]$hosting, 
        [parameter(Mandatory=$true)] 
        [switch]$batch 
    ) 

    $dc = getDC

    $contact = New-Contact -ou "$ou" -FirstName "$FirstName" -LastName "$LastName" -EmailAddress "$EmailAddress" -Description "$Description"
    $groupidentity = "MaintenanceNotification$ClientShortName"
    try {
        get-adgroup -Identity "$groupidentity" -Server $dc
    } catch {
        if ($batch) {
            $create = "Yes"
        } else {
            $create = getyesno -posttext "The `"$groupidentity`" group doesn't seem to exist yet.  Do you want to try to create it? Don't do this if you're fairly sure it was already created."
        }
        if ($create -eq "Yes") {
            if (-not $hosting) {
                $hosting = picksinglefromlist -listin "hosted","onprem" -pretext "Is this a hosted or onprem client?" -posttext "`"hosted`' means it runs on the company's servers.  `"onprem`" means it runs on the client's servers."
            }
            try {
                New-MaintDL -hosting $hosting -ClientShortName $ClientShortName
            } catch {
                Write-Error "Looks like that failed.  Maybe it already existed? Exiting."
                return
            }
        }
        try {
            get-adgroup -Identity "$groupidentity" -Server $dc
        } catch {
            $tryagain = getyesno -posttext "The `"$groupidentity`" group doesn't seem to exist yet.  Do you want to wait 30 seconds and try again to add $FirstName $LastName to it?"
            if ($tryagain -eq "Yes") {
                try {
                    Start-Sleep -s 30
                    get-adgroup -Identity "$groupidentity" -Server $dc
                } catch {
                    Write-Error "The `"$groupidentity`" group still doesn't seem to exist. Exiting."
                return
                }
            } else {
                Write-Error "Exiting."
            }
        }
    }

    try {
        $contactdn = (get-adobject -Identity $contact -Server $dc).distinguishedname
    } catch {
        $tryagain = getyesno -posttext "The contact `"$contactdn`" doesn't seem to exist yet.  Do you want to wait 30 seconds and try again?"
        if ($tryagain -eq "Yes") {
            try {
                Start-Sleep -s 30
                get-adobject -Identity "$contactdn" -Server $dc
            } catch {
                Write-Error "The contact `"$contactdn`" still doesn't seem to exist. Exiting."
            return
            }
        } else {
            Write-Error "Exiting."
        }
    }
        Write-Host "Trying to add $FirstName $Lastname to $groupidentity..."
        while (-not $success) {
            write-host "."
            try {
                $success = $true
                Set-ADGroup -Identity "$groupidentity" -Add @{'member'="$($contact.distinguishedname)"}
            } catch {
                $success = $false
            }
            Start-Sleep -s 2
        }

    return $contact
}

function New-Contact {
#Creates a new Contact in AD.
    param( 
        [parameter(Mandatory=$true)] 
        [string]$ou, 
        [parameter(Mandatory=$true)] 
        [string]$FirstName, 
        [parameter(Mandatory=$true)] 
        [string]$LastName, 
        [parameter(Mandatory=$true)] 
        [string]$EmailAddress, 
        [parameter(Mandatory=$true)] 
        [string]$Description 
    ) 

    $dc = getDC
    
    try {
    $contact = New-ADObject `
    -passthru `
    -server $dc `
    -type "contact" `
    -path "$ou" `
    -Name "$FirstName $LastName (CONTACT)" `
    -Description "$description"`
    -otherAttributes @{`
        'givenName'="$FirstName";`
        'sn'="$LastName";`
        'ProxyAddresses'="SMTP:$EmailAddress";`
        'mail'="$EmailAddress";`
        #'msexchhidefromaddressbook'='TRUE'
    }
    } catch {
        Write-Error "Couldn't create the contact `"$FirstName $LastName (CONTACT)`".  Maybe it already exists?  Exiting."
        return
    }

    return $contact
}

function New-DL {
#Creates a new Disitribution List in AD.
    param( 
        [parameter(Mandatory=$true)] 
        [string]$ou, 
        [parameter(Mandatory=$true)] 
        [string]$Name, 
        [parameter(Mandatory=$true)] 
        [string]$EmailAddress, 
        [parameter(Mandatory=$false)] 
        [string]$PermittedSenders, 
        [parameter(Mandatory=$true)] 
        [string]$Description 
    ) 

    $dc = getDC

If ($PermittedSenders) {
    try {
        $group = New-ADGroup -Name "$Name" `
        -passthru `
        -server $dc `
        -SamAccountName ($Name -replace '[\W]','') `
        -GroupCategory Distribution `
        -GroupScope Global `
        -DisplayName "$Name" `
        -Path "$ou" `
        -Description "$description" `
        -otherAttributes @{`
            'ProxyAddresses'="SMTP:$EmailAddress";`
            'mail'="$EmailAddress";`
            'msexchrequireauthtosendto'='TRUE';`
            'authOrig'="$permittedsenders"
        }
    } catch {
        Write-Error "Couldn't create the DL `"$DisplayName`".  Maybe it already exists? Exiting."
        return
    }
} else {
    
    try {
        $group = New-ADGroup -Name "$Name" `
        -passthru `
        -server $dc `
        -SamAccountName ($Name -replace '[\W]','') `
        -GroupCategory Distribution `
        -GroupScope Global `
        -DisplayName "$Name" `
        -Path "$ou" `
        -Description "$description" `
        -otherAttributes @{`
            'ProxyAddresses'="SMTP:$EmailAddress";`
            'mail'="$EmailAddress";`
            'msexchrequireauthtosendto'='TRUE'`
        }
    } catch {
        Write-Error "Couldn't create the DL `"$DisplayName`".  Maybe it already exists? Exiting."
        return
    }
}

    $groupdn = $group.distinguishedname
    return $groupdn
}

function New-MaintDL {
#This is essentially just a wrapper around the New-DL function to feed the appropriate default OU and name formatting for maintenance notification DLs.
    param( 
        [parameter(Mandatory=$false)] 
        [string]$ou="ou_here", 
        [parameter(Mandatory=$true)]
        [ValidateSet("hosted","onprem")] 
        [string]$hosting, 
        [parameter(Mandatory=$false)] 
        [string]$PermittedSenders="cn_of_group_here", 
        [parameter(Mandatory=$true)] 
        [string]$ClientShortName 
    ) 

    if ($ClientShortName.Length -ne 3) {
        Write-Error "ClientShortName must be exactly 3 characters.  Consult the documentation."
        return
    }

    $groupdn = New-DL -ou $ou -Name "Maintenance Notification $ClientShortName" -EmailAddress "email_address_here" -Description "This is the DL for system maintenance notifications to client $ClientShortName." -PermittedSenders "$permittedsenders"
    
    switch ($hosting)
    {
        "hosted" {$parentgroup = "MaintenanceNotificationHosted"}
        "onprem" {$parentgroup = "MaintenanceNotificationOnPrem"}
    }
    
    Write-Host "Trying to add $groupdn to $parentgroup..."
        while (-not $success) {
            write-host "."
            try {
                $success = $true
                Set-ADGroup -Identity "$parentgroup" -Add @{'member'="$groupdn"}
            } catch {
                $success = $false
            }
            Start-Sleep -s 2
        }

    return $groupdn
    
}
   
function GetWildCardThumbprint {
    param( 
        [parameter(Mandatory=$false)] 
        [string]$domain
    )

If (-Not $domain) {
    $domain = (Get-ADDomain).dnsroot
}

$cert = Get-ChildItem -path cert:\LocalMachine\My | where { $_.FriendlyName -eq "*.$domain" }
$thumb = $cert.thumbprint

Return $thumb

}

function Get-RandPass() {
    Param(
    [int]$length=10,
    [switch]$lowercase,
    [switch]$uppercase,
    [switch]$numbers
    )
    
    $sourcedata=$NULL
    
    #If we specified character sets, use them.
    If ($lowercase) {
        For ($a=97;$a -le 122;$a++) {$sourcedata+=,[char][byte]$a }
    }
    If ($uppercase) {
        For ($a=65;$a -le 90;$a++) {$sourcedata+=,[char][byte]$a }
    }
    If ($numbers) {
        For ($a=48;$a -le 57;$a++) {$sourcedata+=,[char][byte]$a }
    }
    
    #If the password source data was empty by the time we got here
    #maybe because we didn't specify any character sets, use them all.
    if (-Not $sourcedata) {
        For ($a=33;$a -le 126;$a++) {$sourcedata+=,[char][byte]$a }
    }
    
    For ($loop=1; $loop -le $length; $loop++) {
                $RandPass+=($sourcedata | GET-RANDOM)
                }
    [securestring]$SecurePass = $RandPass | ConvertTo-SecureString -AsPlainText -Force
    return $SecurePass
    }

function getdfsnroots() {
    #Returns an array of the DFS root namespaces in the current domain or the domain you specify with "-domain".
    Param(
        [parameter(Mandatory=$false)] 
        [string]$domain
        )

        If ($domain) {
        $dfsnroots = (Get-DfsnRoot -domain "$domain").Where( {$_.State -eq 'Online'} ) | Select-Object -ExpandProperty Path
    } else {
        $dfsnroots = (Get-DfsnRoot).Where( {$_.State -eq 'Online'} ) | Select-Object -ExpandProperty Path
    }

    return $dfsnroots
}

function getdfsfolders() {
    #Returns an array of the DFS folders in the specified DFS namespace.
    Param(
        [parameter(Mandatory=$true)] 
        [string]$namespace
        )

    $dfsfolders = Get-DfsnFolder -Path "$namespace\*" | Select-Object -ExpandProperty Path

    return $dfsfolders
}

function Get-ClientsOU($client) {
    $ou = "ou=$client,the_rest_of_the_ou_here"
    return $ou
}

function CreateAdAccount {
    Param(
        [parameter(Mandatory=$true)] 
        [string]$Client,
        [parameter(Mandatory=$true)] 
        [string]$Firstname,
        [parameter(Mandatory=$true)] 
        [string]$Lastname,
        [parameter(Mandatory=$true)] 
        [string]$Email,
        [parameter(Mandatory=$true)] 
        [string]$SAM,
        [parameter(Mandatory=$true)] 
        [string]$DNSDomain,
        [parameter(Mandatory=$true)] 
        [string]$Ticket,
        [parameter(Mandatory=$true)] 
        [string]$OU,
        [parameter(Mandatory=$true)] 
        [securestring]$Password,
        [parameter(Mandatory=$false)] 
        [array]$Groups
    )

    $Displayname = "$Firstname $Lastname"
    $UPN = "$SAM@$DNSDomain"
    $descstamp = "$client $(GetCurrentUsername) $(GetTimeStamp -Format 1) $ticket"

    $UserError = $false
    $GroupError = $false

    try {
        New-ADUser `
        -Name "$Displayname" `
        -DisplayName "$Displayname" `
        -SamAccountName "$SAM" `
        -UserPrincipalName "$UPN" `
        -GivenName "$UserFirstname" `
        -Surname "$UserLastname" `
        -Description "$descstamp" `
        -EmailAddress "$email" `
        -AccountPassword $Password `
        -Path "$OU" `
        -Enabled $true `
        -ChangePasswordAtLogon $true `
        -PasswordNeverExpires $false `
        -CannotChangePassword $False `
    } catch {
        $UserError = "Failed to create user $SAM with error: $_."
    }
    foreach ($Group in $Groups) {
        try {
            Add-ADGroupMember -Identity "$Group" -Members "$SAM"
        } catch {
            $GroupError = "Failed to add user $SAM to group $group with error: $_."
        }
    }
    return $UserError,$GroupError
}

function GetTimeStamp {
    Param(
        [parameter(Mandatory=$true)] 
        [string]$Format
        )

        #The formats:
        #1 2020-08-12T11:59:05
        #2 20200812_120546

    Switch ($format) {
        1 {
            $timestamp = get-date -format s
        }
        2 {
            $timestamp = get-date -f yyyyMMdd_HHmmss
        }
        3 {
            $timestamp = get-date -f yyyyMMdd
        }

    }
    return $timestamp
}

function Replicate-AllDomainControllers {
    (Get-ADDomainController -Filter *).Name | Foreach-Object {repadmin /syncall $_ (Get-ADDomain).DistinguishedName /e /A | Out-Null}; Start-Sleep 10; Get-ADReplicationPartnerMetadata -Target "$env:userdnsdomain" -Scope Domain | Select-Object Server, LastReplicationSuccess
}

function GetIncedoUserIDFromLoginName {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SQLInstance,
        [Parameter(Mandatory=$true)]
        [string]$DBName,
        [Parameter(Mandatory=$true)]
        [string]$Username
    )

    $query = @"
    select user_id from [$DBName].dbo.usr where login_name = '$username'
"@

    $userid = (Invoke-Sqlcmd -ServerInstance $SQLInstance -Database $DBName -Query $query).user_id

    return $userid
}

function GetDesktopLogContent {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogDir,
        [Parameter(Mandatory=$true)]
        [int]$userid,
        [Parameter(Mandatory=$true)]
        [int]$hoursback
    )

    If (Test-Path $LogDir) {

        If ((Get-ChildItem -Path "$LogDir" | Where-Object {$_.Name -match "`_$userid`_"} | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-$hoursback) }).count -gt 0) {
    
            $logfiles = (Get-ChildItem -Path "$LogDir" | Where-Object {$_.Name -match "`_$userid`_"} | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-$hoursback) | sort-object LastWriteTime -Descending}).fullname

                foreach ($logfile in $logfiles) {
                    [array]$desktopLogContent += "$logfile ====================================================================================================================================================="
                    [array]$desktopLogContent += Get-Content -tail 100 $logfile
                }
        } else {
            [array]$desktopLogContent = "No current Desktop log files to collect."
        }
    } else {
        [array]$desktopLogContent = "Desktop log directory, $logdir, doesn't exist."
    }
    return $desktopLogContent
}

# function UnsecureString {
#     param (
#         [Parameter(Mandatory=$true)]
#         [string]$StringIn
#     )

#     $StringOut = ([System.Net.NetworkCredential]::new(`"`", $StringIn).Password)
#     return $StringOut
# }

# function SecureString {
#     param (
#         [Parameter(Mandatory=$true)]
#         [string]$StringIn
#     )

#     [securestring]$StringOut = ConvertTo-SecureString -String "$StringIn" -AsPlainText -Force
#     return $StringOut
# }

function getOrphanSnapshots {
    $registeredsnaps = (Get-EC2Image -Owner self).BlockDeviceMapping.ebs.snapshotid
    $allsnaps = (Get-Ec2snapshot -OwnerId self).snapshotid
    $orphans = $allsnaps | Where-Object {$registeredsnaps -notcontains $_}
    return $orphans
}

function DetermineNewerFile {
    #Given two files, returns the following values:
    #0 = The files have the same last write time.
    #1 = File1 is newer than File2.
    #2 = File2 is newer than File1.
    #3 = Neither file exists.
    #4 = File1 doesn't exist.
    #5 = File2 doesn't exist.
    param(
    [string]$file1,
    [string]$file2
    )

    [array]$FileNotExist = ""
    
    If (-Not (Test-Path -Path "$file1")) {
        $FileNotExist += '1'
    }

    If (-Not (Test-Path -Path "$file2")) {
        $FileNotExist += '2'
    }
    

 If ($FileNotExist.count -gt 0) {
    $sum = 0
    $FileNotExist | ForEach-Object {$sum += $_}
    switch ($sum) {
        3 { return 3 }
        1 { return 4 }
        2 { return 5 }
    }     
 }

    $file1lastwritetime = [datetime](Get-ItemProperty -Path "$file1" -Name LastWriteTime).lastwritetime
    $file2lastwritetime = [datetime](Get-ItemProperty -Path "$file2" -Name LastWriteTime).lastwritetime
    
    If ($file1lastwritetime -gt $file2lastwritetime) {
        return 1
    } elseif ($file2lastwritetime -gt $file1lastwritetime) {
        return 2
    } else {
        return 0
    }
}

function ListNewerFiles {
    #Lists files in SrcDir that are newer than files in DstDir (or that don't exist in DstDir).
    param(
        [string]$SrcDir,
        [string]$DstDir,
        [int]$MaxFileAge
    )

    $Now = Get-Date
    $OldestDate = $Now.AddDays(-$MaxFileAge)


    [array]$NewerFiles = @()
    $SrcFiles = ((Get-ChildItem "$SrcDir" -file).fullname)

    #write-host $SrcFiles
    ForEach ($SrcFile in $SrcFiles) {
        $DstFile = Join-Path -Path $DstDir -ChildPath (Split-Path -Path $SrcFile -Leaf)
        $newer = DetermineNewerFile -file1 $SrcFile -file2 $DstFile
        If ($newer -in "1","5") {
            If ($MaxFileAge) {
                If (([datetime](Get-ItemProperty -Path "$SrcFile" -Name LastWriteTime).lastwritetime) -gt $OldestDate) {
                $NewerFiles += $SrcFile
                }
            } else {
                $NewerFiles += $SrcFile
            }
        }
    }
    return $NewerFiles
}

function iscurrentusermemberofadgroup {
    #NB:  This appears to retrieve the group memberships from the current token. So:
    #1. You'll get group memberships on the local machine.
    #2. Some things may be missing, like Domain Admins (which you might get if run as admin).
    
    param( 
        [parameter(Mandatory=$true)]
        [string]$groupname
    )
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $groups = $id.Groups | foreach-object {
        $_.Translate([Security.Principal.NTAccount])
        }
        if ($groups -contains "$groupname") {
            return $true
        } else {
            return $false
        }
    }

function getAwsSessionToken {
    # param( 
    #     # [parameter(Mandatory=$true)]
    #     # [string]$region,
    #     [parameter(Mandatory=$false)]
    #     [string]$profileName='default'
    # )

    $username = (Get-IAMUser).UserName
    $mFASerialNumber = (Get-IAMMFADevice -username $username).SerialNumber
    $tokenCode = Read-Host -Prompt "Enter your MFA code"
    #Initialize-AWSDefaults -ProfileName default -Region us-east-2
    $token = Get-STSSessionToken -DurationInSeconds 43200 -SerialNumber $mFASerialNumber -TokenCode $tokenCode
    $key = $token.AccessKeyId
    $secret = $token.SecretAccessKey
    $sessionToken = $token.SessionToken
    Set-AWSCredential -AccessKey $key -SecretKey $secret -SessionToken $sessionToken
    return $token
}

function replaceCurlyQuotes{
    param( 
        [parameter(Mandatory=$true)]
        [string]$stringIn
    )

# “ u201C  left double quotation mark
# ” u201D  right double quotation mark
# ‘ u2018  left single quotation mark
# ’ u2019  right single quotation mark

$SingleQuotes = '[\u2019\u2018]'
$DoubleQuotes = '[\u201C\u201D]'
    If ($stringIn -match $SingleQuotes -or $stringIn -match $DoubleQuotes) {
        # Write-Host "$FilePath"
        $stringIn = $stringIn -replace $SingleQuotes,"'"
        $stringIn = $stringIn -replace $DoubleQuotes,'"' 
    }
return $stringIn
}

function getRandomButNot {
    param( 
        [parameter(Mandatory=$true)]
        [int]$max,
        [parameter(Mandatory=$true)]
        [int]$not
    )
    $max = $max - 1
    $random = $not
    while ($random -eq $not) {
        $random = (1..$max) | Get-Random
    }
    return $random
}

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

function overwriteFileContents {
    #This will take an abitrary file path, get its length, then write that number of random characters back to the file, so the original content is gone.
    param( 
        [parameter(Mandatory=$true)]
        [string]$file
    )
    $length = (Get-Item $file).Length

    $randomString = Get-RandPass -length $length

    Set-Content -Path $file -Value $randomString
}

function GetParamStoreParamNameAndValue {

    param( 
        [parameter(Mandatory=$true)] 
        [string]$paramFullName 
    ) 

    $Name = $null
    $Value = $null

    $Name = Split-Path -Path $paramName -Leaf

    try {
        $Value = (Get-SSMParameter -Name $paramName -WithDecryption $true).value
    }
    catch {
        Write-Warning "$paramName doesn't have a value and may not exist at all, so returning NULL values."        
    }

    return $Name,$Value
}

function parseEnvVars {
    param( 
        [parameter(Mandatory=$true)]
        [string]$line, #specify that you know some of these parameters already exist and you want to update the values
        [parameter(Mandatory=$false)]
        [swtich]$stripQuotes #specify that you know some of these parameters already exist and you want to update the values

    )

    $name = $Null
    $value = $Null

    If (($line.startswith("#")) -or ([string]::IsNullOrWhiteSpace($line))) {
        Continue
    } Elseif (-not $line.Contains("=")) {
        Write-Warning "Skipped a line that isn't empty and isn't a comment because it doesn't contain '='.  The line was:`
        $line"
        Continue
    } Else {
        $envVarArray = $line -Split "=",2
        $name = $envVarArray[0]
        $value = $envVarArray[1]

        If ($stripQuotes) {
            If ($value.substring(0,1) -eq "'") {
                $value = $value.substring(1)
            }
            If ($value.Substring($value.Length - 1) -eq "'") {
                $value = $value.Substring(0,$value.Length - 1)
            }
            If ($value.substring(0,1) -eq '"') {
                $value = $value.substring(1)
            }
            If ($value.Substring($value.Length - 1) -eq '"') {
                $value = $value.Substring(0,$value.Length - 1)
            }
        }
    }

    return $name,$value
}