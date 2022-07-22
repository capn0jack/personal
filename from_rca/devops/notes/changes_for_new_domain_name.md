# These are things we had to change when switching from shoutouttest.com to shoutout.com.
## References to the builder:
- .semaphore configs
## References to the CDN:
- laravel media.php
- frontend configuration.service.ts
## References to the API:
- frontend client-config.model.ts
## SparkPost
- spf record
## E-mail addresses
- laravel mail.php
## config:sets
## Databases:

    update facilities set support_email_address='support@shoutout.com';
    update facilities set from_email_address='noreply@mail.shoutout.com';
    update facilities set url='https://api.shoutout.com';

    update organization_domains set domain='https://api.shoutout.com' where id=1;
    update organization_domains set domain='http://api.shoutout.com' where id=2;

    update facility_domains set domain='http://api.shoutout.com';