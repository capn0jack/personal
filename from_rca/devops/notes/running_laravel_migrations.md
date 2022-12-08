# How to run the Laravel migrations (the scripts that create/update DB schema):

## Enter the target application container, e.g.:
    dokku enter caredfor-laravel-rca-export web

## This would run a single migration:
    php artisan migrate --path=database/migrations/2021_04_22_192805_add_provider_to_oauth_clients.php

## But you probably want to just do this to run them all:
    php artisan migrate