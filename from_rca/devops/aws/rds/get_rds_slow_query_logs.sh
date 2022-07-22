#!/bin/bash
#usage : ./get_rds_slow_query_logs.sh my-db-1 '2020-07-18' us-east-2 [IAM_USER MFA_TOKEN]

#Special note to the dunkoff who wrote the script from the dunkoff who wrote the script...here's how you'd run it:
#cmccabe@RCA4593:~/get_rds_slow_query_logs$ /mnt/c/Users/cmccabe/source/repos/github/rcatelehealth/devops/aws/rds/get_rds_slow_query_logs.sh rca-caredfor '2022-04-27' us-east-2 cmccabe@recoverycoa.com 457265
#It looks like IAM username and MFA code were supplied, so doing MFA authentication...
#Press ENTER to continue if you're sure you're properly authenticated to AWS.  Otherwise, CTRL-C.

instanceID=$1
date=$2
region=$3

if [[ $4 && $5 ]]; then
  echo "It looks like IAM username and MFA code were supplied, so doing MFA authentication..."
  source "${BASH_SOURCE%/*}/../aws_cli_mfa_auth.sh" $4 $5
else
  read -p "Press ENTER to continue if you're sure you're properly authenticated to AWS.  Otherwise, CTRL-C."
fi

function downloadLog () {
  local log=$1

  aws rds download-db-log-file-portion \
    --output text \
    --db-instance-identifier $instanceID \
    --log-file-name $log \
    --region $region
}


downloadLog slowquery/mysql-slowquery.log > slow-$date.log

for i in $(seq -w 0 23); do
  downloadLog slowquery/mysql-slowquery.log.$date.$i >> slow-$date.log
done
