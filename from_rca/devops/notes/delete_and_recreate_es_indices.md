
#To delete all the existing indices:
##In the Kibana Dev Tools Console:

    DELETE /dev*

#To create all the indices:
##From the running caredfor-laravel-rca-export container:

    php artisan shoutout:elastic:createindex App\\Appointment so
    php artisan shoutout:elastic:createindex App\\Conversation so
    php artisan shoutout:elastic:createindex App\\Invitation so
    php artisan shoutout:elastic:createindex App\\Team so
    php artisan shoutout:elastic:createindex App\\User so
    php artisan shoutout:elastic:createindex App\\AccessRequest so

<!-- #This section isn't officially what's happening yet, but it's what Jonathan and I had to do to make this work in DEV/QA, so I don't want to lose it.

    php artisan scout:flush App\\Appointment
    php artisan scout:flush App\\Conversation
    php artisan scout:flush App\\Invitation
    php artisan scout:flush App\\Team #This generates an error because of the incorrect env_teams index.  Probably not the case anymore.
    php artisan scout:flush App\\User
    php artisan scout:flush App\\AccessRequest
     -->
    php artisan caredfor:scout:import App\\Appointment so
    php artisan caredfor:scout:import App\\Conversation so
    php artisan caredfor:scout:import App\\Invitation so
    php artisan caredfor:scout:import App\\Team so
    php artisan caredfor:scout:import App\\User so
    php artisan caredfor:scout:import App\\AccessRequest so
    