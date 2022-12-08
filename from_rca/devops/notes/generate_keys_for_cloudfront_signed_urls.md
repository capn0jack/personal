# How to generate a key pair for CloudFront URL signing.
## CloudFront supports signed URLs, making it so only your designated app can pull from the CDN.  To do that, you have to generate a key pair and upload the public key to CF.

For the script to do this, see [generate_passport_and_cloudfront_keys.ps1](../deployment/generate_passport_and_cloudfront_keys.ps1)

## Generate the key pair:

    cmccabe@RCA4593:~/.ssh/so-prod-profiles$ openssl genrsa -des3 -out so-prod-profiles.pem 2048
    Generating RSA private key, 2048 bit long modulus (2 primes)
    ......................................................................+++++
    .......................................................+++++
    e is 65537 (0x010001)
    Enter pass phrase for so-prod-profiles.pem:
    Verifying - Enter pass phrase for so-prod-profiles.pem:

## Export just the public key:

    cmccabe@RCA4593:~/.ssh/so-prod-profiles$ openssl rsa -in so-prod-profiles.pem -outform PEM -pubout -out so-prod-profiles-pub.pem
    Enter pass phrase for so-prod-profiles.pem:
    writing RSA key

## Export the unencrypted private key:

    cmccabe@RCA4593:~/.ssh/so-prod-profiles$ openssl rsa -in so-prod-profiles.pem -out so-prod-profiles-private-unencrypted.pem -outform PEM
    Enter pass phrase for so-prod-profiles.pem:
    writing RSA key
