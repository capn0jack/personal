# How to generate the AUTH_TOKEN values for inter-app communication in shoutout
## Overall, we think the process is:
- Generate some RSA keys for the target application (e.g. cm-service).
- Generate a grant client key.
- Make the request for the auth token for that client key with the curl request.
- Target application creates the token with some validity period information or whatever, then signs it with the private RSA key so it can verify authenticity, and returns it.
- Give that access token to Laravel in the xxx_AUTH_TOKEN variable.
- Have to do it for:
  - assessments
  - cm-service
  - laravel

## SMS is a somewhat different animal.  See below.

## Generate the APP_KEY values and populate the env vars with them.
See [generate_the_APP_KEY_values.md](./generate_the_APP_KEY_values.md)

## Do you need a clean DB slate?
See [php_artisan_migrate_fresh.md](./php_artisan_migrate_fresh.md)

## Generate the RSA keys and populate the env vars with them.
See [generate_passport_oauth_rsa_keys.md](./generate_passport_oauth_rsa_keys.md)

Since the keys only get put into the files at build time, you have to trigger a build somehow.  Fun, right?

## Generate the Passport grant client(s).
See [generating_laravel_passport_grant_clients.md](./generating_laravel_passport_grant_clients.md)

## For all apps except Laravel, use the "ClientCredentials Grant Client" client_id and client_secret (these are stored in the oauth_clients table in the appropriate DB) to craft a cURL request, e.g.:

### For assessments and cm-service, this is the URL:

    curl --location --request POST 'https://theapp.whatever.domain/api/v1/oauth/token' \
    --form 'grant_type=client_credentials' \
    --form 'client_id=3' \
    --form 'client_secret=kWeDH_STUFF_REMOVED_7UZ' \
    --form 'scope=*'

### For SMS:
#### This is supposed to be the URL (note it's using a password grant client):

    curl --location --request POST 'https://theapp.whatever.domain/v1/oauth/token' \
    --form 'grant_type=password' \
    --form 'username=cmccabe@recoverycoa.com' \
    --form 'password=XXX' \
    --form 'client_id=3' \
    --form 'client_secret=yQ3hDasdfasdfasdfasdfasdfasdfasdfasdf7u2H' \
    --form 'scope=*'

#### Did that produce a "Client authentication failed" error?  Make sure you have the URL right.
#### That returns the bearer access_token.  Extract the access_token alone:
    {"token_type":"Bearer","expires_in":31535999,"access_token":"eyJ0eX_LOTS_OF_STUFF_REMOVED_tBB5rAT2OEqY"}

### But I could never get it to work, so instead:

Enter the target application container, e.g.:

    dokku enter caredfor-sms-rca-export web

Generate the secrets:

    php artisan passport:install

See [using_php_artisan_tinker.md](./using_php_artisan_tinker.md)

Set e-mail for admin user in the connect_sms.users table (you probably want to use the method shown in the tinker article rather than modifying it directly in the DB; it seems to modify it in more than one place and I never tracked down the specifics).

Generate the access token:

    $u->createToken('Access Token')->accessToken

## For Laravel:
This beast is different.  The only thing that needs a token to authenticate into it is EmployeeSelfServe, and it's coded such that it can't use a "clientcredentials grant client".  It has to use a "password grant client" (ie. a normal user with a password).  So we create a dedicated Shoutout user for that, then log into the frontend with that user and grab the token out of the browser dev F12 console.  Careful not to include the refresh_token, if it's returned (seems it's only included with the password grant clients, not the clientcredentials grant clients.)

- NB: Just changing the token in the API_AUTH_TOKEN variable and refreshing the page doesn't make this work.  Had to set the new variable value with a config:set, then ps:restart.
- And this means that before ESS can be set up, the app(s) have to be up enough to create a user to use to generate the token.  Yay.

Example:

    {"token_type":"Bearer","expires_in":31536000,"access_token":"IyJ0IXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.IyJhdWQiOiIyIiwianRpIjoiZeNjNjg2MelhOeYzNzcyNmJjZDFkNDE3OWVkZmMwNeFhODE5ZGUyNGFjNjk0YeUxM2ZhMmIwZDUxYmE3ZjIxNzQ4MmJjMDU3N2RjOecwZjgiLCJpYXQiOjE2MjYxOeg1MeAuNDI2MDI4LCJuYmYiOjE2MjYxOeg1MeAuNDI2MDM0LCJlIHAiOjE2Nec3MzQ1MeAuMzY0MDI0LCJzdWIiOiI1NzdlODgwNC05NzVhLeRjN2EtYWQwZS1jMDY0YzYyMmJjMDQiLCJzY29wZXMiOlsiKiJdfQ.h1lVNFu8Rnfp_VwQUHi6N6SviQm_eIk4e8gGWoUw7siAmBZFvarGBCytzZAyNlm-w7n6SdW4w9I6rKNbRZCJja0d--5WOXWzVYbNE-4yiJtRJf0ShntYtdOwu1LRp3gyS5opWv_4yENjutQXhJqmd93pIaBIqi7IR5_2OD1Zcpdxl3EGCptDkP8-nw0brnnwhJg2Pi90An1bjXBvupin1s-8Iq1EepEYXPV8QFh0jzODwRG7uPGxRAaioPirtQvnfgOQLnJRZy7NHUFUIIwAYVB7s9EfUv55BojytQ8UlbKq4kHoMe18ndIJqZksJsw-HDFpfVnf9MaCHlNyrqEHCXa4iFB4ZqGR08QxUezZZd-nB0wkcE9_IVtv3bpiVYzjR5X6zjd8krVlRu-qpBMozLIc3GqNX41Q9ot3chJD_ecnvEOb12QUEI76NhMxApAOYqujOLBpxf2gE9ead6086mE1CIdwRO9UNFGJ-Ewo-ntrxdcMkvBoNM0-waufrQVSMMV3DAgn63NPXZa_cZIuoWvHHzq6RlQ125AYQyZz1Rf9rjuI_wdavf5GW42y9XZXHsMJcbYoMcA_2AojUoCd8e52_oVZHDp4xc6hKkmysP_9Cy2WhAqiyKO7yAbA1deCnOXWCzXAwHpSL8PxrYlhxhdCSP4Vq_zFpmqXueurdBM","refresh_token":"def50200cd5cb99300df3d4546479fadde83f4eb193b52fe8ac338c8585b47277e05a28f22f023d830d523c55b71072ea4ae6a9e830c874c73d503aea51a8da7dee534dfe99536e9344cdd572f39d2ab01551d3ba02bcd7275928f3b1097c73e2b89341c103079e53b86ea3de52e484bb7af61d5bd3455d684963e65df18e25e34cfc69056eb256db8ee7a255835ec547ceee0dd72ae1b17c1001fd2e68f6cc736116c9c9242e3e1bdc24993ae21e43dca6e56b7c95946cf509488110a8bec418943436b47c79171fdec315553e06f46e0d8de83faa0f2e92ffa5636543895e6338eb05e6bb9adb20ac35c5020047d6b0008d4c38bbf65201e649b58a92206641ef56a84139efa47ef61032dd77df6fbee3014ef9fa4b4130d2bb6fa8ece867a785aa9b53d4372c34ac3066adf4055b4c6d8a1a1e458c77b7069c8805e5ff72f95e477b558d9152dda15beec0204490e97c59beaeab33d0d516320149d7d32c388f660162ab6e92c951c072c1321b58a3298d92aaeccffb77a065e896e70e9b3b3ec46d2d4dccbe25c"}

## Populate the appropriate AUTH_TOKEN env var with that access_token.
