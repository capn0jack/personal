#!/bin/bash

numCommits=10
commitAuthor="Charles McCabe <cmccabe@recoverycoa.com>"
lookFor="semaphore"

repoRootDir="/home/cmccabe/source/repos/github/rcatelehealth"

repos=$(cat <<SETVAR
caredfor-laravel-rca-export 
SETVAR
)

# cm-service-rca-export 
# caredfor-admin-rca-export 
# caredfor-frontend-rca-export 
# caredfor-integrations-rca-export 
# caredfor-assessments-rca-export 
# caredfor-global-api-rca-export 
# caredfor-sms-rca-export 
# EmployeeSelfServe

echo "$variable"
for repo in $repos
do
    echo ==================================================
    echo ========== $repo
    cd $repoRootDir
    cd $repo

    #Filtering for the author works just fine, but I found that there was a typo in my global setting that meant some of my own commit author info was wrong, so I was missing results.
    #commitHashes=$(git log -$numCommits --author="$commitAuthor"  --pretty=format:"%H")
    commitHashes=$(git log -$numCommits --pretty=format:"%H")

    for commitHash in $commitHashes
    do
        diffTreeOutput=$(git diff-tree --no-commit-id --name-only -r $commitHash)
        if [[ $diffTreeOutput =~ $lookFor ]]
        then
            echo --------------------------------------------------
            echo $commitHash
            echo "$diffTreeOutput"
        fi
    done
done