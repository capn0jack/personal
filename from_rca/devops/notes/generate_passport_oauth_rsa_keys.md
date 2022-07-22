# How to generate the RSA keys used by Laravel Passport for oAuth.

For the script to do this for all the apps at once, see [generate_passport_and_cloudfront_keys.ps1](../deployment/generate_passport_and_cloudfront_keys.ps1)

## Enter the target application container, e.g.:
    dokku enter cm-service-rca-export web

## This will move the existing keys to a temp directory and then create and display new ones:
    mkdir storage/temp
    mv storage/oauth-p*.key storage/temp
    php artisan passport:keys
    cat storage/oauth-public.key
    cat storage/oauth-private.key
### In some cases, you might want to generate new keys, but put the old ones back in place, so you'd run these two lines as well:
    rm storage/oauth-p*.key
    mv storage/temp/oauth-p*.key storage/

### But maybe you want to just overwrite the existing keys:
    php artisan passport:keys --force

## This creates the oAuth RSA keys *and* generates a "personal access client" and a "password grant client" in the database (but you probably don't want to do that):

    php artisan passport:install

### And you can add --force to overwrite the oAuth RSA keys:

    php artisan passport:install --force

### If you can't do the passport:install because it complains that caredfor.oauth_clients doesn't exist, you need to run the migrations.
See [running_laravel_migrations.md](./running_laravel_migrations.md)

## The way it works as of this writing is that those RSA keys have to be the values of the PASSPORT_PUBLIC_KEY and PASSPORT_PRIVATE_KEY env vars (header, footer, and all) and the line breaks have to be replaced with "\n".  You can do that in VS Code by typing CTRL-Enter in the Search For field and "\n" in the Replace With field. So:
This key file content:

    -----BEGIN PUBLIC KEY-----
    MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1Mdoyj/MfyzFCtO18INb
    dwG6+s3Lhec02FzapA8QoGTAjHOMaiL49WS9Nu45qlBqTCKZoVigVMLG3Gnf5YIw
    6yFcBIiSHT+hUbRWQQcvSGhX4h0yX/slsSpco8aWnLVePhktsDK6svXQpuZzvVTz
    eoI8/wVWHuoCtFBqMqjUCDyOg0XsLWCDGsC9KWBR8UzMRSgAKGOacT/O/55RWOl8
    DUqbEON1C4+XQ7zmQtMzxJcVwF+N7WuxUpJ6AVU8I8RESIS7cp38Zha7KYlp4vAS
    CI9u3B7SHBHf7N3fk3VwWibFRpl70Ymcfr4xlJ7vvDM92PTnH7fQ49SeDUBLQqQY
    zgQWcfNChhdXB/LKIgia7nYWCKWXE7Wwev4xtQ+BD3IGvaWHQ2vZ60sKybEOjbPm
    WixWSmSdJdgA9v7uEqyti96mMRI1Df2z6VkSBqWgm2v8X1675XInGNRU8d6GnaPv
    Sy/As9ba8sPboZ80sUBEJUFFPR5mBE5piln7yybDSfYSSu8I/UbrqUiAIoDWD2Lr
    yAXUqCAaqUNn/61c5h3QhUeaHcvNhVpRd6iYxGRnW2k5tv9IB9SYR8U5LO97jlSX
    CkHXlxmV5FTrvDIiPb8UUTVCORRPDIGhuiB0MMq60IH8T3ftO681QIkE9YBKmQ9w
    kmoU3Ld9qcu8mYUvdzyCVC0CAwEAAQ==
    -----END PUBLIC KEY-----

Would become this env var string (it looks like Markdown is screwing this up...there shouldn't be any line breaks in it):

    -----BEGIN PUBLIC KEY-----\nMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1Mdoyj/MfyzFCtO18INb\ndwG6+s3Lhec02FzapA8QoGTAjHOMaiL49WS9Nu45qlBqTCKZoVigVMLG3Gnf5YIw\n6yFcBIiSHT+hUbRWQQcvSGhX4h0yX/slsSpco8aWnLVePhktsDK6svXQpuZzvVTz\neoI8/wVWHuoCtFBqMqjUCDyOg0XsLWCDGsC9KWBR8UzMRSgAKGOacT/O/55RWOl8\nDUqbEON1C4+XQ7zmQtMzxJcVwF+N7WuxUpJ6AVU8I8RESIS7cp38Zha7KYlp4vAS\nCI9u3B7SHBHf7N3fk3VwWibFRpl70Ymcfr4xlJ7vvDM92PTnH7fQ49SeDUBLQqQY\nzgQWcfNChhdXB/LKIgia7nYWCKWXE7Wwev4xtQ+BD3IGvaWHQ2vZ60sKybEOjbPm\nWixWSmSdJdgA9v7uEqyti96mMRI1Df2z6VkSBqWgm2v8X1675XInGNRU8d6GnaPv\nSy/As9ba8sPboZ80sUBEJUFFPR5mBE5piln7yybDSfYSSu8I/UbrqUiAIoDWD2Lr\nyAXUqCAaqUNn/61c5h3QhUeaHcvNhVpRd6iYxGRnW2k5tv9IB9SYR8U5LO97jlSX\nCkHXlxmV5FTrvDIiPb8UUTVCORRPDIGhuiB0MMq60IH8T3ftO681QIkE9YBKmQ9w\nkmoU3Ld9qcu8mYUvdzyCVC0CAwEAAQ==\n-----END PUBLIC KEY-----