# How to seed the various databases required for Shoutout:

## Create a DB set:
See [create_new_db_set.md](./create_new_db_set.md)

## It seems you have to start with Laravel, otherwise cm-service and SMS don't work.

## From the Passport documentation:
#Passport's service provider registers its own database migration directory, so you should migrate your database after installing the package. The Passport migrations will create the tables your application needs to store OAuth2 clients and access tokens:
#php artisan migrate #DON'T RUN THIS AGAINST LARAVEL

## Laravel:

### Make sure that the following things are completely configured or the caredfor:tenant:setup script will fail (this is a problem because if the tenant:setup fails it leaves stuff in the caredfor DB that the script won't handle gracefully*):
- SQS driver and queues
- search (at least if that search is Algolia)
- S3 buckets

### Enter the target application container, e.g.:

    dokku enter caredfor-laravel-rca-export web
  
### Run the migrate and update scripts:
    #DON'T RUN THIS AGAINST LARAVEL: php artisan migrate
    php artisan caredfor:update #This is probably unnecessary because it was already done when the app was deployed.

*When doing this in DEV, we dropped and recreated the whole caredfor and _so DBs.  CF does this with a CSV import, instead.

### You will need to provide the OneSignal AppID and API key, so get OneSignal setup, if not done already.

### Run the tenant setup script:
See [explanation_of_tenant_setup_script.md](./explanation_of_tenant_setup_script.md)

    dokku enter caredfor-laravel-rca-export web
    php artisan caredfor:tenant:setup

### After a bunch of questions, it generates the grants:

    Creating oAuth clients...
    Personal access client created successfully.
    Client ID: 1
    Client secret: YZ8asdfasdfasdfasdfasdfasdfasdfasdfasxAW

    Which user provider should this client use to retrieve users? [users]:
      [0] users

    Password grant client created successfully.
    Client ID: 2
    Client secret: qsKcfasdfasdfasdfasdfasdfasdfasdfasdflld
    Ding! Your new client is ready.

### As of this writing, you need to populate src\app\environments\environment.env.ts in the Frontend with those "Password grant client" values.

## Assessments:
### Enter the target application container, e.g.:

    dokku enter caredfor-assessments-rca-export web

### Run the migrations:

    php artisan migrate #In STA, got "Nothing to migrate."  Same in QA.  Can probably eliminate this step.

### Seed the DB:

    php artisan db:seed

### Verify seeding:

    select * from survey_question_types;

## SMS:
### Enter the target application container, e.g.:

    dokku enter caredfor-sms-rca-export web

### Run the migrations:

    php artisan migrate #In STA, got "Nothing to migrate."

### Seed the DB:

    php artisan db:seed

### Verify seeding:

    select * from users;

## cm-service:
### Enter the target application container, e.g.:

    dokku enter cm-service-rca-export web

### Run the migrations:

    php artisan migrate #In STA, got "Nothing to migrate." Same in QA.  Can probably eliminate this step.

### Seed the DB:

    php artisan db:seed

### Verify seeding:

    select * from actions;

## admin:
### Enter the target application container, e.g.:

    dokku enter caredfor-admin-rca-export web

### Run the migrations:

    php artisan migrate #In STA, got "Nothing to migrate." Same in QA.  Can probably eliminate this step.

### Seed the DB:

    php artisan db:seed

### Verify seeding:

    #Don't know.

## integrations:
### Enter the target application container, e.g.:

    dokku enter caredfor-integrations-rca-export web

### Run the migrations:

    php artisan migrate #In STA, got "Nothing to migrate." Same in QA.  Can probably eliminate this step.

### Seed the DB:

    php artisan db:seed

### Verify seeding:

    #Don't know.