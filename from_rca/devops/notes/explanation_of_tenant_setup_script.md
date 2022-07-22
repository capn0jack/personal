# Explanation of the tenant setup script.

## Explanations entered as comments at the end of the line #Like this.

## Many lines don't need explanation; they just exist as an example to follow.

## As of this writing, there is a bug that causes the organization URL to have duplicate and incorrect protocols, e.g. "https://api.tra.shoutout.com" gets stored as "http://http://api.tra.shoutout.com" in the DB.  After this script runs, you'll have to fix that manually with something like:

    use _so;
    update facilities set url='https://api.tra.shoutout.com';
    update facility_domains set domain='http://api.tra.shoutout.com';
    use caredfor;
    update organization_domains set domain='https://api.tra.shoutout.com' where id=1;
    update organization_domains set domain='http://api.tra.shoutout.com' where id=2;

And just for convenience, the selects to check what's in there:

    use _so;
    select * from facilities;
    select * from facility_domains;
    use caredfor;
    select * from organization_domains;
    select * from organization_domains;

## And here's what a script run looks like, with comments:

    herokuishuser@da367df88f8f:~$     php artisan caredfor:tenant:setup
    Hello! I'll guide you through setting up a new client.
    First, let's create an Organization...

    What is the name of the Organization?:
    > SO #As far as I can tell, this is arbitrary and I haven't seen it used anywhere.

    What is the client code for the Organization?:
    > so #This is the code that's used, for instance, to create the tenant DB by prexing with "_", resulting in "_so".

    What URL will the organization use to access the app?:
    > https://api.tra.shoutout.com

    Migration table created successfully.
    Migrating: 2016_06_01_000001_create_oauth_auth_codes_table
    Migrated:  2016_06_01_000001_create_oauth_auth_codes_table (0.06 seconds)
    .
    .
    .
    Migrating: 2021_06_10_133547_add__f_u_l_l_t_e_x_t_indexes
    Migrated:  2021_06_10_133547_add__f_u_l_l_t_e_x_t_indexes (0 seconds)
    Seeding: EntryTypesTableSeeder
    Seeded:  EntryTypesTableSeeder (0.06 seconds)
    .
    .
    .
    Seeding: App\Updates\Release6150\Seeder
    Seeded:  App\Updates\Release6150\Seeder (0.01 seconds)
    Database seeding completed successfully.
    Organization created!
    Now let's add a facility...

    What is the name of the Facility?:
    > Shoutout Tra

    Facility Logo:
    > https://cdn.tra.shoutout.com/assets/shoutout-logo.png

    From Email Address:
    > noreply@mail.tra.shoutout.com

    Street Address:
    > 2701 Renaissance Blvd

    City:
    > King of Prussia

    State:
    > PA

    Postal Code:
    > 19406

    One Signal App ID:
    > 68sdasdfasdfasdfasdfasdfasdfasdfasdfasdfd9

    One Signal API Key:
    > NDasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfadfGZk

    Facility created!
    Let's set up a Developer User...

    First Name::
    > Jonathan

    Last Name::
    > Judge

    Email::
    > jjudge@recoverycoa.com

    Password:
    > Wasdsdfasdfsadfsadfg

    What role should the user have?:
    [0] dev
    [1] super
    [2] member
    > 0

    Would you like to create another user? (yes/no) [no]:
    > yes

    First Name::
    > Charles

    Last Name::
    > McCabe

    Email::
    > cmccabe@recoverycoa.com

    Password:
    > EAD2asdfadfsdfasdfu1

    What role should the user have?:
    [0] dev
    [1] super
    [2] member
    > 0

    Would you like to create another user? (yes/no) [no]:
    > no

    Got it! Let's add a team while we're at it...

    Team Name::
    > First Team

    Should I seed this team with testing data? (yes/no) [no]:
    > yes

    Should I seed assessments for this client? (yes/no) [no]:
    > yes

    Creating oAuth clients...
    Personal access client created successfully.
    Client ID: 1
    Client secret: 0NasdfsadfasdfasdfasdgsdfgdasfgasfasdEwt

    Which user provider should this client use to retrieve users? [users]:
    [0] users
    > 0

    Password grant client created successfully.
    Client ID: 2
    Client secret: Lsasdfasdfasdfasdfasdfasdfasdfasdfaadsku
    Ding! Your new client is ready.