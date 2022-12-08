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

$apps = `
"api"`
,"cm"`
,"int"`
,"assess"`
,"global"`
,"sms"`

#I'm not bothering with trying to escape spaces in the path, so you'll have to deal with that.
$openSslExe = "C:\Progra~1\Git\usr\bin\openssl.exe"

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$baseDir = getArbitraryParentDir -dir $ScriptDirectory -levelsUp 1
. (Join-Path (Join-Path $baseDir "shared") "functions.ps1")

$tempFileOutput = $null
$tempFileOutput = New-TemporaryFile

Foreach ($app in $apps) {
    $tempFilePair = $null
    $tempFilePair = New-TemporaryFile
    $tempFilePub = $null
    $tempFilePub = New-TemporaryFile
    $tempFilePriv = $null
    $tempFilePriv = New-TemporaryFile
    $tempFilePass = $null
    $tempFilePass = New-TemporaryFile

    $securePass = $null
    $securePass = Get-RandPass -length 20 -lowercase -uppercase -numbers
    $pass = ConvertFrom-SecureString -SecureString $securePass -AsPlainText

    Set-Content -Path "$tempFilePass" -Value $pass

    "$openSslExe genrsa -des3 -out $tempFilePair -passout file:$tempFilePass 4096" | Invoke-Expression

    "$openSslExe rsa -in $tempFilePair -outform PEM -pubout -out $tempFilePub -passin file:$tempFilePass" | Invoke-Expression

    "$openSslExe rsa -in $tempFilePair -out $tempFilePriv -outform PEM -passin file:$tempFilePass" | Invoke-Expression

    $keyPub = [string]::Join('\n', (Get-Content "$tempFilePub"))
    $keyPriv = [string]::Join('\n', (Get-Content "$tempFilePriv"))

    "" | Out-File -FilePath $tempFileOutput -Append
    $app | Out-File -FilePath $tempFileOutput -Append
    $keyPub | Out-File -FilePath $tempFileOutput -Append
    $keyPriv | Out-File -FilePath $tempFileOutput -Append

    overwriteFileContents -file $tempFilePair
    overwriteFileContents -file $tempFilePub
    overwriteFileContents -file $tempFilePriv
    overwriteFileContents -file $tempFilePass

    Remove-Item $tempFilePair -Force
    Remove-Item $tempFilePub -Force
    Remove-Item $tempFilePriv -Force
    Remove-Item $tempFilePass -Force

    $tempFilePair = $null
    $tempFilePub = $null
    $tempFilePriv = $null
    $tempFilePass = $null
    $securePass = $null
    $pass = $null
}

Write-Warning "NOW GET THE INFORMATION YOU NEED AND THEN DELETE $tempFileOutput!"