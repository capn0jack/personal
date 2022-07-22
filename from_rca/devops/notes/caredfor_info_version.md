#To check and change the version of the application according to the DB (e.g. if you need migrations to run again):

    SELECT * FROM caredfor.caredfor_info;
    
    UPDATE caredfor.caredfor_info set app_version = "7.2.0.0" where app_version = "7.3.0.0";