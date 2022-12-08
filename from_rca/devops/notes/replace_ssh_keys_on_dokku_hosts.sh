#!/bin/bash
export env='qa'
export targetname='dokku-target-4'
cd ~/.ssh
mkdir old_deleteme
mv id_rsa* old_deleteme/
mv semaphore-* old_deleteme/
ssh-keygen -t rsa -b 4096
ssh-keygen -t rsa -b 4096 -f semaphore-$env
sudo dokku ssh-keys:add semaphore-$env ~/.ssh/semaphore-$env.pub
export oldpubkey=`cat ~/.ssh/old_deleteme/id_rsa.pub`
#The next 3 lines (well, probably only the lines beginning with "sed" and "EOF") have to be outdented all the way to the left, but doing that break Markdown formatting.  The HereDoc doesn't work without it.
export sedcommand=$(cat <<EOF
sed -i.bak 's#$oldpubkey##' ~/.ssh/authorized_keys
EOF
)
eval "$sedcommand"
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile ~/.ssh/old_deleteme/id_rsa" dokku@$targetname
ssh dokku@$targetname "$sedcommand"