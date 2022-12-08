#Adding a new target node to a Dokku environment.
create ami from existing machine
create instance from ami, same everything, except patch group
add so.int dns entry

add to lb/tg

update deployment csv

adjust running counts of container types (e.g. scale cron back to 0)

update docs

set hostname on new host

Updating TARGET_NODES

ssh to new target the first time to accept the ssh key?

