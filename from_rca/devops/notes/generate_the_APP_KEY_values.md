# How to generate the APP_KEY values for Shoutout.

## Each of these apps needs an APP_KEY value generated and added to the env vars:
- admin
- assess
- global
- int
- api
- sms
- cm-service

## Enter the target application container (I guess this only works for Laravel apps?  Doens't work in cm-service.):

    dokku enter caredfor-laravel-rca-export web

## To get the APP_KEY values (you can generate them all at once in any of the containers):

    grep -v APP_KEY= .env > .envtemp && cat .envtemp > .env && echo APP_KEY= >> .env && export APP_KEY= && php artisan key:generate --ansi --force && grep APP_KEY .env