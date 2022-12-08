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
function deleteLocalBranch {
    param (
        [Parameter()]
        [string]
        $branchToDelete,
        [Parameter()]
        [array]
        $protectedBranches
    )

    If ($branchToDelete -notin $protectedBranches) {
        git checkout dev
        git branch -d $branchToDelete
    } else {
        Write-Warning "The target branch was $branchToDelete and the following branches are protected against deletion:"
        Foreach ($protectedBranch in $protectedBranches) {
            Write-Warning "$protectedBranche"
        }
    }

}    

function deleteLocalAndRemoteBranch {
    param (
        [Parameter()]
        [string]
        $branchToDelete,
        [Parameter()]
        [array]
        $protectedBranches
    )

    If ($branchToDelete -notin $protectedBranches) {
        git checkout dev
        git branch -d $branchToDelete
        git push origin --delete $branchToDelete
        git fetch --prune
    } else {
        Write-Warning "The target branch was $branchToDelete and the following branches are protected against deletion:"
        Foreach ($protectedBranch in $protectedBranches) {
            Write-Warning "$protectedBranch"
        }
    }

}

function createPr {
    param (
        [Parameter()]
        [string]
        $fromBranch,
        [Parameter()]
        [string]
        $toBranch,
        [Parameter()]
        [switch]
        $mergePr
    )
        Write-Host "Waiting 5 seconds because GitHub gets all pissy if we submit PRs too fast."
        Start-Sleep 5
        $urlPr = (gh pr create --head "$fromBranch" --base "$toBranch" --body "Merge $fromBranch into $toBranch." --title "$fromBranch-->$toBranch" --reviewer "$reviewer" --assignee "$assignee")
        Write-Host "PR created: $urlPr"
            If ($mergePr) {
                gh pr merge "$urlPr" --merge --body "Merge $fromBranch into $toBranch." --admin
            }
}

function listPrs {

    gh pr list
}

function createRelease {

    gh release create $releaseVersion --generate-notes --target main --title $releaseVersion
}

function createNewbranch {
    param (
        [Parameter()]
        [string]
        $fromBranch,
        [Parameter()]
        [string]
        $newBranch
    )
    updateBranch $fromBranch
    git checkout -b $newBranch
    git push origin $newBranch
    git branch --set-upstream-to "origin/$newBranch"

    # return $newBranch
}
function getMyCommits {

    param (
        [Parameter()]
        [string]
        $commitAuthor,
        [Parameter()]
        [int]
        $numCommitsToList
    )
    $commitHashes = $(git log -$numCommitsToList --author="$commitAuthor"  --pretty=format:"%H")

    return $commitHashes
}

function updateBranch {
    param (
        [Parameter()]
        [string]
        $branch
    )

    git checkout $branch
    git pull
}

function getLocalBranches {
    $localBranches=git branch --format='%(refname:short)'
    return $localBranches
}

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$baseDir = getArbitraryParentDir -dir $ScriptDirectory -levelsUp 1
. (Join-Path (Join-Path $baseDir "shared") "functions.ps1")

$timestamp = GetTimeStamp -format 2

$githuborg = "RCATelehealth"

$compactOutput = $true

$numCommitsToList = 10

$sourceBranch = ""

$targetBranch = "MWA-1243"

$reviewer = "nucleusjvv"

$assignee = "@me"

$releaseVersion = "v20220318.1"

$repoRootDir = "/home/cmccabe/source/repos/github/rcatelehealth"

$commitMessage = $targetBranch

$commitAuthor = "cmccabe <cmccabe@recoverycoa.com>"

$protectedBranches = "main","sta","qa","dev"

$commitHashes = "1feaefb4042277be40645b821b2ea12670968175","92c45e873d7133cf476983bf50bc61f82ecdda30"

$fileToCopy = Join-Path $repoRootDir "caredfor-laravel-rca-export/.github/workflows/AlertAboutPRs.yml"
$fileRelativePath = ".github/workflows/" #No slash at the beginning but a slash at the end.  We're just going to use this as the destination parameter to the Copy-Item/Remove-Item cmdlet while in the rep dir.

$repos = `
"caredfor-laravel-rca-export"`
,"cm-service-rca-export"`
,"caredfor-admin-rca-export"`
,"caredfor-integrations-rca-export"`
,"caredfor-assessments-rca-export"`
,"caredfor-global-api-rca-export"`
,"caredfor-sms-rca-export"`
,"EmployeeSelfServe"`
,"caredfor-frontend-rca-export"`
,"billing"`
,"billingapi"`
,"sleep"`
,"00healthcheck"

# $forceBuild = $false #Use forceRebuild.
$setGitAttributesForLineEndings = $false
$addAllCommitPush = $false
$createNewBranch = $false
$deleteLocalBranch = $false
$deleteLocalAndRemoteBranch = $true
$createPr = $false
$mergePr = $false
$listPrs = $false
$cherryPick = $false
$listMyCommits = $false
$listAllCommits = $false
$getMyAuthorPerRepo = $false
$listBranchesContainingSourceBranchCommits = $false
$listBranchesMissingSourceBranchCommits = $false
$checkoutAndPullBranch = $false
$listCommitsInSourceNotTarget = $false
$updateAllBranches = $false
$listAllLocalBranches = $false
$copyFileIn = $false
$deleteFile = $false
$forceRebuild = $false
$createRelease = $false

foreach ($repo in $repos) {
    Write-Host
    Write-Host ================ $repo
    $currentRepoDir = Join-Path $repoRootDir $repo
    Set-Location $currentRepoDir

    If ($cherryPick) {
        write-host "+++++++++++++++++++++++++++++++++ updating source branch"
        updateBranch $sourceBranch
        write-host "+++++++++++++++++++++++++++++++++ updating target branch"
        updateBranch $targetBranch
        $newBranch = "cherrypick$timestamp"
        write-host "+++++++++++++++++++++++++++++++++ creating new branch"
        createNewbranch -fromBranch $sourceBranch -newBranch $newBranch
        write-host "+++++++++++++++++++++++++++++++++ updating new branch"
        updateBranch $newBranch
        foreach ($commitHash in $commitHashes) {
            write-host "+++++++++++++++++++++++++++++++++ cherrypicking a hash"
            Write-host "git cherry-pick $commitHash"
            # git cherry-pick --continue
        }
        write-host "+++++++++++++++++++++++++++++++++ git add"
        # git add --all
        write-host "+++++++++++++++++++++++++++++++++ git commit"
        # git commit -m "cherrypick $sourceBranch-->$targetBranch" --allow-empty
        write-host "+++++++++++++++++++++++++++++++++ git push"
        # git push origin
        write-host "+++++++++++++++++++++++++++++++++ creating pr"
        # createPr -fromBranch $newBranch -toBranch $targetBranch -merge
        write-host "+++++++++++++++++++++++++++++++++ deleting new branch"
        # deleteLocalAndRemoteBranch -branchToDelete $newBranch -protectedBranches $protectedBranches
    }
    If ($listAllLocalBranches) {
        getLocalBranches
    }

    If ($updateAllBranches) {
        $localBranches = getLocalBranches
        foreach ($branch in $localBranches) {updateBranch $branch}
    }

    If ($listCommitsInSourceNotTarget) {
        updateBranch $targetBranch
        updateBranch $sourceBranch
        git log $targetBranch..$sourceBranch
    }

    If ($checkoutAndPullBranch) {
        updateBranch $sourceBranch
    }

    If ($listBranchesContainingSourceBranchCommits) {
        updateBranch $sourceBranch
        git branch --contains $sourceBranch
    }

    If ($listBranchesMissingSourceBranchCommits) {
        updateBranch $sourceBranch
        git branch --no-contains $sourceBranch
    }

    If ($getMyAuthorPerRepo) {
        git config --get user.name
        git config --get user.email
    }

    If ($listMyCommits) {
        updateBranch $sourceBranch
        Write-Host
        Write-Host "These are your last $numCommitsToList commits on the $sourceBranch branch:"
        If ($compactOutput) {
            git log -$numCommitsToList --author="$commitAuthor"  --pretty=oneline
        } else {
            git log -$numCommitsToList --author="$commitAuthor"
        }
    }

    If ($listAllCommits) {
        updateBranch $sourceBranch
        Write-Host
        Write-Host "These are the last $numCommitsToList commits on the $sourceBranch branch:"
        If ($compactOutput) {
            git log -$numCommitsToList --pretty=oneline
        } else {
            git log -$numCommitsToList
        }
    }

    # If ($forceBuild) {
    #     updateBranch $commitBranch
    #     If (-Not (test-path touchfile)) {
    #         New-Item -Name touchfile -ItemType File
    #     }
    #     Get-Date | Out-File -FilePath touchfile
    #     git add touchfile
    #     git commit -m "forcing rebuild"
    #     git rm touchfile
    #     git commit -m "forcing rebuild"
    #     git push
    # }

    If ($setGitAttributesForLineEndings) {
        updateBranch $commitBranch
        "* text=auto" | Out-File -FilePath .gitattributes
        git add --renormalize .
        git status
        git commit -m "Introduce end-of-line normalization"
        git push
    }

    If ($addAllCommitPush) {
        git checkout $targetBranch
        git add --all
        git commit -m "$commitMessage"
        git push
    }

    If ($createNewBranch) {
        createNewbranch -fromBranch $sourceBranch -newBranch $targetBranch
    }

    If ($deleteLocalAndRemoteBranch) {
        deleteLocalAndRemoteBranch -branchToDelete $targetBranch -protectedBranches $protectedBranches
    }

    If ($deleteLocalBranch) {
        deleteLocalBranch -branchToDelete $targetBranch -protectedBranches $protectedBranches
    }

    If ($createPr) {
        updateBranch $sourceBranch
        updateBranch $targetBranch
        Start-Sleep 30
        If ($mergePr) {
            createPr -fromBranch $sourceBranch -toBranch $targetBranch -mergePr
        } else {
            createPr -fromBranch $sourceBranch -toBranch $targetBranch
        }
        Start-Sleep 30
    }

    If ($listPrs) {
        listPrs
    }

    If ($copyFileIn) {
        If (-Not (Test-Path $fileRelativePath)) {
            New-Item -Path $fileRelativePath -ItemType Directory
        }
        Copy-Item -Path $fileToCopy -Destination $fileRelativePath
    }

    If ($deleteFile) {
        Remove-Item -Path $fileRelativePath -WhatIf
    }

    If ($forceRebuild) {
        updateBranch $targetBranch
        git commit --allow-empty -m "Empty commit to force rebuild."
        git push
    }

    If ($createRelease) {
        createRelease
    }
}


    # git checkout $commitBranch
    # git log -2 --author="$commitAuthor"  --pretty=oneline
    # $commitHash = $(git log -1 --author="$commitAuthor"  --pretty=format:"%H")
    #git reset --hard
    # git status
    # git push --set-upstream origin $targetBranch
    # git restore .semaphore/deployment-qa.yml
    # git restore .semaphore/semaphore.yml
    # git status
    # git checkout $commitBranch
    # git pull
    # git status
    #  git cherry-pick --continue --allow-empty
    # git cherry-pick $commitHash
    #git cherry-pick --abort
    # git push
    # git branch
    # git branch -d $cherryPickBranch
    # git checkout -b $cherryPickBranch --track origin/$cherryPickBranch
    # git checkout DEVO-74
    # git status
    # git reset --hard
    # git pull
    # git checkout sta
    # git rm testfile
    # git commit -m "forcing pipeline"
    # git push
    # Get-ChildItem .semaphore/


            # getMyCommits -commitAuthor $commitAuthor -numCommitsToList $numCommitsToList
        # If (-Not (test-path touchfile)) {
        #     New-Item -Name touchfile -ItemType File
        # }
        # Get-Date | Out-File -FilePath touchfile
        # git add touchfile
        # git commit -m "forcing rebuild"
        # git rm touchfile
        # git commit -m "forcing rebuild"
        # # git push


                # getMyCommits -commitAuthor $commitAuthor -numCommitsToList $numCommitsToList
        # If (-Not (test-path touchfile)) {
        #     New-Item -Name touchfile -ItemType File
        # }
        # Get-Date | Out-File -FilePath touchfile
        # git add touchfile
        # git commit -m "forcing rebuild"
        # git rm touchfile
        # git commit -m "forcing rebuild"
        # # git push
