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