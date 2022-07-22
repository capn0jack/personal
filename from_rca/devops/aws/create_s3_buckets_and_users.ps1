param( 
    [parameter(Mandatory=$true)]
    [string]$clt,
    [parameter(Mandatory=$true)]
    [string]$env
)

. C:\Users\cmccabe\source\repos\github\rcatelehealth\devops\shared\functions.ps1

$region = "us-east-2"

$apps = "api","global","int"
$buckets = "int","media","mediaassets"

$foldersToCreate = @(
    ("media","/uploads/so/media/"),
    ("media","/uploads/profiles/")
)

$newIamUserWait = 60

$token = getAwsSessionToken
Set-AWSCredential -AccessKey $token.AccessKeyId -SecretKey $token.SecretAccessKey -SessionToken $token.SessionToken

foreach ($bucket in $buckets) {
    New-S3Bucket -BucketName $clt-$env-$bucket -Region $region
    Add-S3PublicAccessBlock -BucketName $clt-$env-$bucket -PublicAccessBlockConfiguration_BlockPublicAcl $true -PublicAccessBlockConfiguration_BlockPublicPolicy $true -PublicAccessBlockConfiguration_IgnorePublicAcl $true -PublicAccessBlockConfiguration_RestrictPublicBucket $true
}

Foreach ($folderToCreate in $foldersToCreate) {
    Write-S3Object -BucketName $clt-$env-$($folderToCreate[0]) -Key "$($folderToCreate[1])" -Content "$($folderToCreate[1])"
}

foreach ($app in $apps) {
    $username = "$clt-$env-s3-$app"
    $groupname = "$clt-$env-s3-$app"
    $policyname = "$clt-$env-s3-$app"
    $group = New-IAMGroup -GroupName $groupname
    $user = New-IAMUser -UserName $username
    $userArn = $user.Arn
    $accessKey = New-IAMAccessKey -UserName $username
    $accessKeyId = $($accessKey.AccessKeyId)
    $secretAccessKey = $($accessKey.SecretAccessKey)
    Write-Host "Username: $username"
    Write-Host "Access Key ID: $accessKeyId"
    Write-Host "Secret Access Key: $secretAccessKey"

    $policyDocApi = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$clt-$env-media"
            ]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": [
                "s3:*Object",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::$clt-$env-media/*"
            ]
        }
    ]
}
"@
  
    $policyDocGlobal = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$clt-$env-media"
            ]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": [
                "arn:aws:s3:::$clt-$env-media/uploads/*"
            ]
        }
    ]
}
"@
  
    $policyDocInt = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$clt-$env-$app"
            ]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": [
                "arn:aws:s3:::$clt-$env-$app/*"
            ]
        }
    ]
  }
"@

switch ($app) {
    'api' { $policyDoc = $policyDocApi }
    'global' { $policyDoc = $policyDocGlobal }
    'int' { $policyDoc = $policyDocInt }
    Default {
        Write-host "We're not set up to handle app name $app. Exiting."
        exit
    }
}

$policy = New-IAMPolicy -PolicyName $policyname -PolicyDocument $policyDoc
$policyArn = $policy.Arn

    Write-Host "Waiting up to $newIamUserWait seconds for user $username to be accessible..."
    $timer =  [system.diagnostics.stopwatch]::StartNew()

    while ($timer.Elapsed.TotalSeconds -lt $newIamUserWait) {
        Try {
            #If they've become available, we'll move on.
            $ready = $true
            Get-IAMUser -UserName $username | Out-Null
            If (-Not $?) {$ready = $false}
            Get-IAMGroup -GroupName $groupname | Out-Null
            If (-Not $?) {$ready = $false}
            Get-IAMPolicy -PolicyArn $policyArn | Out-Null
            If (-Not $?) {$ready = $false}
            If ($ready) {
                Add-IAMUserToGroup -UserName $username -GroupName $groupname
                Register-IAMGroupPolicy -GroupName $groupname -PolicyArn $policyArn
            }
            break
        } catch {
            #If the they haven't become available, we'll let the loop continue.
            Start-Sleep 5
            continue
        }
    }
}