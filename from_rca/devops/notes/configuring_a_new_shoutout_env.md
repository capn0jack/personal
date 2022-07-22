# How to setup a completely new Shoutout environment

## Open ticket for required changes to code and check out appropriate branch.

## Add new env name to allow values for AWS tag policy.

## Generate or request Google Analytics ID for the environment.

## Create nexmo information (have to request from support).

## Generate the CloudFront keys.
See [generate_keys_for_cloudfront_signed_urls.md](./generate_keys_for_cloudfront_signed_urls.md)

## Stand up the AWS services.
See [vpc.yml](../aws/cloudformation/vpc.yml)

## Add ec2-instance-dokku-builder-* policy and apply to EC2 instance.

## Do the things that CloudFormation can't:
- The VPC has to be authorized on the private hosted zone manually.  CF doesn't
have a way to do this at writing: https://github.com/aws-cloudformation/cloudformation-coverage-roadmap/issues/371
- DNS resolution has to be enabled across the peering connection manually.  CF doesn't have a way to do this at writing: https://github.com/aws-cloudformation/cloudformation-coverage-roadmap/issues/169

## Add new VPC route to OpenVPN

## Add config to CSV.
See [deployment_config.csv](../deployment/deployment_config.csv)

## Create S3 and SQS queues, buckets and users.  Perhaps this will get baked into the CF template(s).
[//]: # (Can we inject these right into the env var file?)

## Create airbrake projects for:
- frontend
- api
- sms

## Create Ionic App/ID.
We're actually using the same values everywhere right now, but eventually that will change.

## Create OneSignal App/ID
- iOS
  - Entry in KeePass with the key files is "Apple app store account for APN for OneSignal"
  - upload the aps.p12 to OneSignal
- Android, which includes creating the Firebase project.  (I don't know how to uniquely identify the Google account involved, but my cmccabe@recoverycoa.com Google account was invited and the PROD project URL is https://console.firebase.google.com/project/so-prod-2a47e/overview).  As of this writing, we don't know exactly how a non-PROD configuration would work, so we're not doing it.

## Add Frontend src/environments/environment.env.ts and configure*:
- Airbrake
- Google Analytics
- Ionic
- OneSignal

*One of the many sucky things about this is that all that stuff has to be done ahead of time in env.env.ts, but the authClientSecrets can't be done until the apps are up.

## Create the Help Scout stuff.
- mailbox
  - drop down Manage at the top, select Mailboxes, New Mailbox, change name to "Support Env", e-mail address should default to support-env@shoutouthelp.helpscoutapp.com
  - open mailbox settings, change Default Status to Pending, change Default Assignee to "Person Replying (if Unassigned)"
  - copy the mailbox ID number out of the URL (as far as we know, that's the only place to find it), e.g. https://secure.helpscout.net/settings/mailbox/*123456*/
- user
  - drop down Manage at the top, select Users, New User, name="so env", e-mail=support@env.shoutout.com (no point in sending an invite e-mail), allow access to just this env's mailbox on the next screen
  - create app, that's where the app id and secret come from
    - In the newly-create user, select My Apps, click Create My App, name=so-env, Redirection URL=https://app.env.shoutout.com
    - document generated App ID and App Secret

## Create pusher information
- https://dashboard.pusher.com/apps
- app name=so-env
- cluster=us2
- document the info

## Create sparkpost domain and api key.

- Add a Sending domain:
  - Configuration-->Domains-->Add a Domain
  - domain=mail.env.shoutout.com
  - Accept strict domain alignment on the next screen
  - Add the DKIM record to DNS.
  - The Bounce record should already have been added by the VPC CloudFormation template.
  - Check "The TXT and CNAME records have been added to the DNS provider." and click Verify Domain.
- Generate an API key:
  - Configuration-->API Keys--Create API Key
  - API Key Name=so-env

## Create WEBHOOK_CLIENT_SECRET for Laravel.
Just a 20-char alphanumber password generated out of KeePass.

## Create new set of env vars in Systems Manager Paramter Store, making sure to:
- invalidate all sensitive entries until they are updated with appropriate values
- update DB connection info
- replace "oldenv" references with "newenv"
- update WEBHOOK_CLIENT_SECRET
- update AWS connection info for:
  - S3
  - SQS
  - CloudFront
- update connection info for
  - OneSignal
  - Pusher
  - NexMo
  - Help Scout
  - Ionic
  - Airbrake

## Set up DBA SQL accounts.
See [User_maintenance.sql](../../databases/System_Maintenance/User_maintenance.sql)

## Create the DBs.
See [create_new_db_set.md](./create_new_db_set.md)

## Add builder internal IP to hosts file (on your local workstation, as a convenience).

## Add builder to SSH config (on your local workstation, as a convenience).

## Configure new SSH keys on Dokku hosts:
As dokku user:
- move existing dokku and semaphore user keys to old_deleteme directory
- create new dokku user keys (id_rsa)
- create new semaphore user keys (semaphore-env)
- sudo dokku ssh-keys:add semaphore_env /home/dokku/.ssh/id_rsa_semaphore.pub
- remove the rest of the entries from dokku's authorized_keys
- SSH to target with old dokku key
  - Add new dokku key to authorized_keys and comment out the old one

## Configure the deployment-keys and hostkeys Dokku plugins on Dokku hosts:
### deployment keys allows Dokku to inject SSH keys into the container so it can pull from private repos, in this case so we can pull yak and aws-elastic-client into caredfor-laravel-rca-export.
### hostkeys allows Dokku to inject known_hosts into the container for the same reason.

    sudo dokku plugin:install https://github.com/cedricziel/dokku-hostkeys-plugin.git --name hostkeys-keys
    dokku hostkeys:shared:autoadd github.com
    sudo dokku plugin:install https://github.com/cedricziel/dokku-deployment-keys.git --name deployment-keys
    cd ~/.deployment-keys/shared/.ssh
    echo ${the_github_machine_user_private_key} > id_rsa #Yes, we're replacing the keys that were auto-generated during the installation of the plugin.
    echo ${the_github_machine_user_public_key} > id_rsa.pub #No, it doesn't seem to work unless the keys are in the files with those names.

#### For the script to do this, see (replace_ssh_keys_on_dokku_hosts.sh)[./replace_ssh_keys_on_dokku_hosts.sh]
Run as the dokku user.

- upload semaphore private key to  semaphore as semaphore-ssh-env
- document semaphore keys

## Add/Update Semaphore configs for each app.

## Add env to Laravel app\Exceptions\Handler.php.

## Push changes to environment.env.ts, Semaphore configs, and handler.php.

## Run app config script to create the applications.
See [config_dokku_apps.ps1](../deployment/config_dokku_apps.ps1)

## Deploy the applications.

### Seed the DBs.
See [seeding.md](./seeding.md)

## Setup the branch.io stuff...need more info on this
- Create app "so-env"
- Do the "Configuration" stuff first.
  - Default URL=https://app.env.shoutout.com/
  - Android URL=https://play.google.com/store/apps/details?id=com.rcatelehealth.shoutout
  - Check "I have an iOS app"
  - iOS URL=shoutout-health://
  - Select Apple Store Search, type "shoutout health" and pick the Shoutout Health search result.
  - Click Add New Bundle ID
    - Bundle Identifier=com.rcatelehealth.shoutout
    - App App Prefix=ZK4S62TZMA
  - Save
- Create the "register" quicklink
  - At the top right, click Create-->Quick Link
    - On Name Your Link tab
      - Link Title=register
      - Link Alias=register
    - On Redirects tab
      - Under Desktop
        - Web URL
        - https://app.env.shoutout.com/#/register
    - On Link Data tab
      - Key=$canonical_url
      - Value=https://app.env.shoutout.com/#/register
  - Save and Continue
- link has to be put in the DB in the branch_link field:

      use _so;
      update facilities set branch_link='https://nmek4.app.link/register';
      select * from facilities;

## Create Elastic Search domain
- Add DNS CNAME es.env.shoutout.com

## Generate the APP_KEY values:
See [generate_the_APP_KEY_values.md](./generate_the_APP_KEY_values.md)

## Generate oAuth RSA keys for:
See [generate_passport_oauth_keys.ps1](../deployment/generate_passport_oauth_keys.ps1)
See [generate_passport_oauth_rsa_keys.md](./generate_passport_oauth_rsa_keys.md)
- assessments
- global-api
- integrations
- api
- sms
- cm-service

## Populate the env vars with the APP_KEY and PASSPORT_*_KEY values and force a rebuild/redeploy of the apps.

## Generate the AUTH_TOKEN values:
See [generate_AUTH_TOKENs.md](./generate_AUTH_TOKENs.md)

## Populate the env vars with the AUTH_TOKEN values and force a restart of the apps.

## Update these values via the Frontend (hamburger-->Dashboard-->App Settings):
- Branch Link=https://the_random_base_branch_domain
- iTunes App Store URL=(for non-PROD) https://apps.apple.com/us/app/shoutout-health-testing/id1573477937
- Google Play Store URL=(for non-PROD) https://play.google.com/store/apps/details?id=com.rcatelehealth.shoutout-testing
*The Apple and Google URLs are in the _so.facilities.app_urls table.

## Copy the contents of the mediaassets bucket

## Do the billingapi/Stripe webhook config (see https://rcatelehealth.atlassian.net/browse/MWA-861);
<!-- Create webhook in stripe.com with URL https://billingapi.${env}.shoutout.com/stripe/webhook. Enable the following events:

  customer.subscription.created
  customer.subscription.updated
  customer.subscription.deleted
  customer.updated
  customer.deleted
  invoice.payment_action_required

Copy secret from webhook and populate STRIPE_WEBHOOK_SECRET variable in billingapi. -->

Set up the Stripe key and secret variables.

In the billingapi container, do:

  php artisan cashier:webhook

That will generate the webhook in Stripe and add the appropriate stuff to Laravel.

Copy secret from webhook and populate STRIPE_WEBHOOK_SECRET variable in billingapi.



## Configure the api --> billingapi webhook:
### In the running billingapi container:

  php artisan passport:client --client

  PS [cmccabe@dokku-target-0] /home/cmccabe> dokku enter billingapi
  herokuishuser@cf4a40ccc377:~$ php artisan passport:client --client

  What should we name the client? [ShoutoutBilling ClientCredentials Grant Client]:
  >

  New client created successfully.
  Client ID: 1
  Client secret: lEMsVTqasdfasdfasdfasdfasdfasdfasdfasdfQ707p0f

### Populate the BILLING_API_* variables in api:

  BILLING_API_URL=https://billingapi.dev.shoutout.com
  BILLING_API_CLIENT_ID=1
  BILLING_API_CLIENT_SECRET=lEMsVTqasdfasdfasdfasdfasdfasdfasdfasdfQ707p0f
  BILLING_API_WEBHOOK_ENABLED=true
