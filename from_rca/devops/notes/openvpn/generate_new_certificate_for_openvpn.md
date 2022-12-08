# This process generates a new certificate (e.g. for a hostname change) for OpenVPN.

## Allow TCP/80 in from 0.0.0.0/0.

## SSH to the OpenVPN instance (might have/want to allow SSH to the EIP from your external IP and use that, since the session to the internal IP will be broken when the VPN is down):

    ssh -i .\.ssh\cmccaberecoverycoacom.pem openvpnas@13.58.145.195

### Just for convenience, this is the SSH command with the internal IP:

    ssh -i .\.ssh\cmccaberecoverycoacom.pem openvpnas@10.0.1.15
    
## Generate the cert:

    sudo su -
    install certbot
    certbot certonly --standalone

### Sample interaction with the script:

    Saving debug log to /var/log/letsencrypt/letsencrypt.log
    Plugins selected: Authenticator standalone, Installer None
    Please enter in your domain name(s) (comma and/or space separated)  (Enter 'c'
    to cancel): vpn.shoutout.com
    Obtaining a new certificate
    Performing the following challenges:
    http-01 challenge for vpn.shoutout.com
    Waiting for verification...
    Cleaning up challenges

    IMPORTANT NOTES:
    - Congratulations! Your certificate and chain have been saved at:
    /etc/letsencrypt/live/vpn.shoutout.com/fullchain.pem
    Your key file has been saved at:
    /etc/letsencrypt/live/vpn.shoutout.com/privkey.pem
    Your cert will expire on 2021-12-27. To obtain a new or tweaked
    version of this certificate in the future, simply run certbot
    again. To non-interactively renew *all* of your certificates, run
    "certbot renew"
    - If you like Certbot, please consider supporting our work by:

    Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
    Donating to EFF:                    https://eff.org/donate-le



## Back up the existing certs:

    cd /usr/local/openvpn_as/etc/web-ssl/
    mkdir backup
    mv ca.crt backup/
    mv server.crt backup/
    mv server.key backup/



## Symlink the generated cert files into the OpenVPN configuration:

    ln -f -s /etc/letsencrypt/live/vpn.shoutout.com/fullchain.pem /usr/local/openvpn_as/etc/web-ssl/ca.crt
    ln -f -s /etc/letsencrypt/live/vpn.shoutout.com/cert.pem /usr/local/openvpn_as/etc/web-ssl/server.crt
    ln -f -s /etc/letsencrypt/live/vpn.shoutout.com/privkey.pem /usr/local/openvpn_as/etc/web-ssl/server.key

## Reboot.