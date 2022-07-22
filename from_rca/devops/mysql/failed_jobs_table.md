# Get recent entries in the failed_jobs table (it's big and low-performance, so doing natural things like filtering on the date times out):

    SELECT * FROM caredfor.failed_jobs order by id desc limit 100;

## Finding an id that corresponds to the date you're interested in, then filtering from there works without timing out:
    SELECT exception FROM caredfor.failed_jobs where id >= 678438 and exception NOT LIKE "%slack%" and exception NOT LIKE "%onesignal%" limit 100;