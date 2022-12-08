# To force Laravel scheduled jobs to run:

    php artisan caredfor:import:sftp:invitations
    php artisan caredfor:import:sftp:appointments

# To send appointment reminders:

    php artisan notifications:appointment_reminders

# Maybe ths sends event reminders:
    php artisan notifications:event_summary

# Need to figure out a new one?  Perhaps look in app/Console/Commands, find the corresponding PHP file, and pick out the "protected $signature" line for it.