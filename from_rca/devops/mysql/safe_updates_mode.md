#When you get this stupid message in SQL Workbench:
    You are using safe update mode and you tried to update a table without a WHERE that uses a KEY column.  To disable safe mode, toggle the option in Preferences -> SQL Editor and reconnect.

##OFF:

    set sql_safe_updates=0

##ON:

    set sql_safe_updates=1
