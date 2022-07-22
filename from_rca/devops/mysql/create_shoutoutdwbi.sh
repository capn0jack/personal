#!/bin/bash


#Runs on mgt-0 as cron job under cron-so-prod-dba to create the BI copy of the DW DB.

dumpFile="/scratchdata/shoutoutdwbi/shoutoutdw.sql"
#sourceHost="rds.shoutout.com"
#targetHost="rdsprodbi.shoutout.com"
sourceDB="shoutoutdw"
targetDB="shoutoutdwbi"
#sourceUser="dp-so-prod-bi"
#targetUser="dp-so-prod-bi"

echo "Starting the backup..."
mysqldump --login-path=create_shoutoutdwbi_source --set-gtid-purged=OFF --column-statistics=0 --lock-tables=false --no-tablespaces --ignore-table=shoutoutdw.v_users $sourceDB > $dumpFile

if [ $? -eq 0 ] 
then
    echo "Editing the backup file..."
    sed -i 's/\DEFINER\=`[^`]*`@`[^`]*`//g' $dumpFile
    echo "Starting the restore..."
    mysql --login-path=create_shoutoutdwbi_target --force $targetDB < $dumpFile
else
    echo "The backup returned an error, so not trying to do the restore:"
    echo "$?"
fi