param( 
    [parameter(Mandatory=$true)]
    [string]$clt,
    [parameter(Mandatory=$true)]
    [string]$env
)

. C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\shared\functions.ps1

$apps = "api","global","cm","sms"

$sQSEncryptionKey = "alias/aws/sqs"

$newIamUserWait = 60

$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken

$accountId = (Get-STSCallerIdentity).Account

#$random = Get-Random

foreach ($app in $apps) {
  $qName = "$clt-$env-$app"
  $qUrl = New-SQSQueue -QueueName "$qName"
  $qArn = Get-SQSQueueAttribute -QueueUrl $qUrl -AttributeName QueueArn | Select-Object QueueARN -ExpandProperty QueueARN
  $username = "$clt-$env-sqs-$app"
  $user = New-IAMUser -UserName $username
  $userArn = $user.Arn
  $accessKey = New-IAMAccessKey -UserName $username
  $accessKeyId = $($accessKey.AccessKeyId)
  $secretAccessKey = $($accessKey.SecretAccessKey)
  Write-Host "Username: $username"
  Write-Host "Access Key ID: $accessKeyId"
  Write-Host "Secret Access Key: $secretAccessKey"

  $policyDoc = @"
{
    "Version": "2008-10-17",
    "Id": "$($qArn)_policy_ID",
    "Statement": [
      {
        "Sid": "1",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::$($accountId):root"
        },
        "Action": "SQS:*",
        "Resource": "$qArn"
      },
      {
        "Sid": "2",
        "Effect": "Allow",
        "Principal": {
          "AWS": "$userArn"
        },
        "Action": "SQS:SendMessage",
        "Resource": "$qArn"
      },
      {
        "Sid": "3",
        "Effect": "Allow",
        "Principal": {
          "AWS": "$userArn"
        },
        "Action": [
          "SQS:ChangeMessageVisibility",
          "SQS:DeleteMessage",
          "SQS:ReceiveMessage"
        ],
        "Resource": "$qArn"
      }
    ]
  }
"@

  $attribs = @{}
  $attribs.add('VisibilityTimeout','1800')
  $attribs.add('KmsMasterKeyId',$sQSEncryptionKey)
  $attribs.add('Policy',$policyDoc)

  Write-Host "Waiting up to $newIamUserWait seconds for user $username to be accessible..."
  $timer =  [system.diagnostics.stopwatch]::StartNew()

  while ($timer.Elapsed.TotalSeconds -lt $newIamUserWait) {
    Try {
      #If the user has become available, we'll move on.
      Get-IAMUser -UserName $username | Out-Null
      If ($?) {
        Set-SQSQueueAttribute -QueueUrl $qUrl -Attribute $attribs
      }
      # Set-SQSQueueAttribute -QueueUrl $qUrl -Attribute @{ Policy = $policy }
      break
    } catch {
      #If the user hasn't become available, we'll let the loop continue.
      Start-Sleep 5
      continue
    }
  }
}