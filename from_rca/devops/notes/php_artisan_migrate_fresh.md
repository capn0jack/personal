# This will roll back all the migrations in the target application (e.g. cm-service, and presumably any other) DB away (which isn't necessarily part of this process, but you might, for instance, want to start with a clean slate of client keys):
    php artisan migrate:fresh

    We think this only does the tenant DBs.  In reality, when this happened in QA, I dropped and recreated the DBs, then forced a rebuild of the apps and did the seeding again.