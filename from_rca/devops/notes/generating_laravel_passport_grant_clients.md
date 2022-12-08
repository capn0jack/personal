# How to generate the Laravel Passport grant clients

## When setting up a new environment, you probably do have to do this for (ClientCredentials Grant Client):
- cm-service
- assessments
- sms

## And you probably don't have to do it for Laravel (Password Grant Client).

## Enter the target application container, e.g.:
    dokku enter cm-service-rca-export web

## This generates the "clientcredentials grant client" (it's also possible that that's generated by the passport:install above and this is unnecessary):
    php artisan passport:client --client

## This will generate just a password grant client (which allows generating a code using just username/password for auth?; this is grant_type=password in the curl request):
    php artisan passport:client --password

## And for a personal access client (This is grant_type=client_credentials in the curl request):
    php artisan passport:client --personal