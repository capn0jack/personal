
. C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\shared\functions.ps1

$clt = "so"
$env = "dev"

#$apps = "api","global","int"
$bucketName = "so-dev-media"



#$sQSEncryptionKey = "alias/aws/sqs"

$newIamUserWait = 60

$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken

$accountId = (Get-STSCallerIdentity).Account

#$random = Get-Random

#POLICY: so-prod-s3-int
#USER: so-prod-s3-int
#GROUP: so-prod-s3-int

#foreach ($app in $apps) {
  #$qName = "$clt-$env-$app"
  #$qUrl = New-SQSQueue -QueueName "$qName"
  #$qArn = Get-SQSQueueAttribute -QueueUrl $qUrl -AttributeName QueueArn | Select-Object QueueARN -ExpandProperty QueueARN
#   $username = "$clt-$env-s3-$app"
#   $groupname = "$clt-$env-s3-$app"
#   $policyname = "$clt-$env-s3-$app"
#   $group = New-IAMGroup -GroupName $groupname
#   $user = New-IAMUser -UserName $username
#   $userArn = $user.Arn
#   $accessKey = New-IAMAccessKey -UserName $username
#   $accessKeyId = $($accessKey.AccessKeyId)
#   $secretAccessKey = $($accessKey.SecretAccessKey)
#   Write-Host "Username: $username"
#   Write-Host "Access Key ID:$accessKeyId"
#   Write-Host "Secret Access Key:$secretAccessKey"

  
#   $policyDocApi = @"
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "s3:GetBucketLocation",
#                 "s3:ListAllMyBuckets"
#             ],
#             "Resource": "*"
#         },
#         {
#             "Sid": "ListObjectsInBucket",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:ListBucket"
#             ],
#             "Resource": [
#                 "arn:aws:s3:::$clt-$env-media"
#             ]
#         },
#         {
#             "Sid": "AllObjectActions",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:*Object",
#                 "s3:PutObjectAcl"
#             ],
#             "Resource": [
#                 "arn:aws:s3:::$clt-$env-media/*"
#             ]
#         }
#     ]
# }
# "@
  
#   $policyDocGlobal = @"
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "ListObjectsInBucket",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:ListBucket"
#             ],
#             "Resource": [
#                 "arn:aws:s3:::$clt-$env-media"
#             ]
#         },
#         {
#             "Sid": "AllObjectActions",
#             "Effect": "Allow",
#             "Action": "s3:*Object",
#             "Resource": [
#                 "arn:aws:s3:::$clt-$env-media/uploads/*"
#             ]
#         }
#     ]
# }
# "@
  
#   $policyDocInt = @"
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "ListObjectsInBucket",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:ListBucket"
#             ],
#             "Resource": [
#                 "arn:aws:s3:::$clt-$env-$app"
#             ]
#         },
#         {
#             "Sid": "AllObjectActions",
#             "Effect": "Allow",
#             "Action": "s3:*Object",
#             "Resource": [
#                 "arn:aws:s3:::$clt-$env-$app/*"
#             ]
#         }
#     ]
#   }
# "@

# switch ($app) {
#     'api' { $policyDoc = $policyDocApi }
#     'global' { $policyDoc = $policyDocGlobal }
#     'int' { $policyDoc = $policyDocInt }
#     Default {
#         Write-host "We're not set up to handle app name $app. Exiting."
#         exit
#     }
# }

# $policy = New-IAMPolicy -PolicyName $policyname -PolicyDocument $policyDoc
# $policyArn = $policy.Arn

#   $attribs = @{}
#   $attribs.add('VisibilityTimeout','1800')
#   $attribs.add('KmsMasterKeyId',$sQSEncryptionKey)
#   $attribs.add('Policy',$policy)

#  Write-Host "Waiting up to $newIamUserWait seconds for user $username to be accessible..."
#  $timer =  [system.diagnostics.stopwatch]::StartNew()

  while (1 -eq 1) {
    Try {
        #If they've become available, we'll move on.
        # $ready = $true
        New-S3Bucket -Region us-east-2 -BucketName "$bucketName"
        $Encryptionconfig = @{ServerSideEncryptionByDefault = @{ServerSideEncryptionAlgorithm = "AES256"}}
        Set-S3BucketEncryption -BucketName "$bucketName" -Region us-east-2 -ServerSideEncryptionConfiguration_ServerSideEncryptionRule $Encryptionconfig
        # If (-Not $?) {$ready = $false}
        # Get-IAMGroup -GroupName $groupname | Out-Null
        # If (-Not $?) {$ready = $false}
        # Get-IAMPolicy -PolicyArn $policyArn | Out-Null
        # If (-Not $?) {$ready = $false}
        # #Get-IAMGroup -GroupName $groupname | Out-Null
        # If ($ready) {
        #     Add-IAMUserToGroup -UserName $username -GroupName $groupname
        #     Register-IAMGroupPolicy -GroupName $groupname -PolicyArn $policyArn
        # }
        #Set-SQSQueueAttribute -QueueUrl $qUrl -Attribute $attribs

# Set-SQSQueueAttribute -QueueUrl $qUrl -Attribute @{ Policy = $policy }
      break
    } catch {
      #If the they haven't become available, we'll let the loop continue.
      Start-Sleep 30
      continue
    }
  }
# }