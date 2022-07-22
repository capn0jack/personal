
mysql --login-path=rds.dev.shoutout.com < Update_Fact_User_Action.sql > test_action.txt

mysql_config_editor set --login-path=create_shoutoutdwbi_source --host=rds.shoutout.com --user=dp-so-prod-bi --password
mysql_config_editor set --login-path=create_shoutoutdwbi_target --host=rdsprodbi.shoutout.com --user=dp-so-prod-bi --password