# Using php artisan tinker

### I don't know how universal this is, but it worked for modifying properties of the connect_sms.users table from the SMS app container.

## Enter the container

    dokku enter caredfor-sms-rca-export web

## Run tinker

    php artisan tinker

## Tinker with the properties of a user

    $u = User::find(1)
    $u->email='cmccabe@recoverycoa.com'
    $u->save()