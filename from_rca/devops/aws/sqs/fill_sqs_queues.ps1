param( 
    [parameter(Mandatory=$true)]
    [string]$clt,
    [parameter(Mandatory=$true)]
    [string]$env
)

. C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\shared\functions.ps1

$apps = "api"

$message = $null
$messages = $null

$messages = @()

$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken
$i=1
foreach ($app in $apps) {
    $qName = "$clt-$env-$app"
    $qUrl = Get-SQSQueue -QueueNamePrefix $qName
    do {
        $body = Get-RandPass -length 128 -lowercase -uppercase -numbers | ConvertFrom-SecureString -AsPlainText
        $AttributeValue = New-Object Amazon.SQS.Model.MessageAttributeValue
        $AttributeValue.DataType = "String"
        $AttributeValue.StringValue = "wut"

        $messageAttributes = New-Object System.Collections.Hashtable
        $messageAttributes.Add("huh", $AttributeValue)
        $message = Send-SQSMessage -DelayInSeconds 10 -MessageAttributes $messageAttributes -MessageBody "stuff{$body}" -QueueUrl "$qUrl"
        $messages += $message
        $i += 1
    } while ($i -le 100)
}