#I couldn't get it to create the repo on GitHub.  That's the line that's commented out below.  So you'll have to do that in the GUI.
$gitHubAccount = "rcatelehealth"
 git init -b main
 git add --all
 git commit -m "initial commit"
$repoName = Get-Location | Split-Path -Leaf
# $json = @"
# {'name':'$repoName'}
# "@
# write-host "curl -u `"$gitHubAccount`" -d `"$json`" https://api.github.com/user/repos"
git remote add origin https://github.com/$gitHubAccount/$repoName
git push origin main