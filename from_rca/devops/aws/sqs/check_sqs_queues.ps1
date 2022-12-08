#To Do:
#Have to tag the queues.

param( 
    [parameter(Mandatory=$true)]
    [string]$clt,
    [parameter(Mandatory=$true)]
    [string]$env
)

. C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\shared\functions.ps1

# 12:13
# 3:15

$getCount = 1000

$apps = "api"
#,"global","cm","sms"

$bodies = @()
$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken
$i=1
foreach ($app in $apps) {
do {
  
  $qName = "$clt-$env-$app"
  $qUrl = Get-SQSQueue -QueueNamePrefix $qName
 #Get-SQSQueue -QueueNamePrefix $qName
#  Get-SQSQueueAttribute -QueueUrl $qUrl -AttributeName All | Select-Object ApproximateNumberOfMessages,ApproximateNumberOfMessagesDelayed,ApproximateNumberOfMessagesNotVisible,QueueARN
  $message = Receive-SQSMessage -AttributeName SenderId, SentTimestamp -MessageCount 1 -QueueUrl $qUrl -VisibilityTimeout 30
  $bodies += $message.Body
  # $message.MessageAttributes."huh"
#  $message.Body
#  $message.ReceiptHandle
#  $messages.Body
 # Edit-SQSMessageVisibility -QueueUrl "$qUrl" -ReceiptHandle "$($message.ReceiptHandle)" -VisibilityTimeout 0
$i += 1
} while ($i -le $getCount)

}
$timestamp = gettimestamp -format 2
$bodies | Out-File c:\temp\bodies$timestamp.txt -Force