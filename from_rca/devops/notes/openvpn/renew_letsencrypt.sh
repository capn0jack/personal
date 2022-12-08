#!/bin/bash

#CPM 21Dec2021 The purpose of this script is to automate the renewal 
# of the Let's Encrypt certificate used by OpenVPN.  It is scheduled as 
# a cron job.  The basic process is to 
# - do a bunch of sanity checks, 
# - try to correct env deficiencies, 
# - open HTTP inbound so LE can do it's ACME auth, 
# - request the cert, 
# - close HTTP inbound, 
# - backup the existing cert, and then 
# - symlink the new cert into OpenVPN.

DOMAIN=vpn.shoutout.com

SG=sg-0e1868ed385e21f0f

OPENVPNCERTDIR=/usr/local/openvpn_as/etc/web-ssl/

LETSENCRYPTCERTDIR=/etc/letsencrypt/live/$DOMAIN/

TIMESTAMP=`date "+%Y%m%d-%H%M%S"`

#Make sure we're running as root.
WHO=`whoami`
if [ ! "$WHO" == "root" ]; then
    echo "Not running as root.  Exiting."
    exit
fi

#Make sure we have unzip.
UNZIP=`which unzip`
if [ "$UNZIP" == "" ]; then
    apt install unzip
    UNZIP=`which unzip`
    if [ "$UNZIP" == "" ]; then
        echo "unzip doesn't appear to be installed.  Exiting."
        exit
    fi
fi

#Make sure we have the AWS CLI.
AWS=`which aws`
if [ "$AWS" == "" ]; then
    mkdir /root/temp$TIMESTAMP
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/root/temp$TIMESTAMP/awscliv2.zip"
    cd /root/temp$TIMESTAMP
    unzip awscliv2.zip
    ./aws/install
    AWS=`which aws`
    if [ "$AWS" == "" ]; then
        echo "AWS CLI doesn't appear to be installed.  Exiting."
        exit
    fi
fi

#Open TCP/80 for LE's ACME authentication.
aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 80 --cidr 0.0.0.0/0 || exit

#Make sure we have certbot.
CERTBOT=`which certbot`
if [ "$CERTBOT" == "" ]; then
    install certbot
    CERTBOT=`which certbot`
    if [ "$CERTBOT" == "" ]; then
        echo "certbot doesn't appear to be installed.  Exiting."
        exit
    fi
fi

#Generate the new Lets Encrypt cert.  Exit if it errors out.
EXIT=0
OUTPUT=`certbot certonly -n -d $DOMAIN --standalone`
if [ $? -ne 0 ]; then $EXIT=$?; fi

#Close TCP/80 for LE's ACME authentication, even if certbot failed.
aws ec2 revoke-security-group-ingress --group-id $SG --protocol tcp --port 80 --cidr 0.0.0.0/0

if [ $EXIT -ne 0 ]; then
    echo "certbot failed with error: $EXIT.  Exiting."
    exit
fi

if [[ "$OUTPUT" == *"no action taken"* ]]; then
    echo "$OUTPUT. Exiting."
    exit
fi

#Back up the existing certs or symlinks to certs.  Exit if any of these commands error out.
BAKDIR=$OPENVPNCERTDIR/backup$TIMESTAMP/
mkdir $BAKDIR || exit
mv $OPENVPNCERTDIR/ca.crt $BAKDIR || exit
mv $OPENVPNCERTDIR/server.crt $BAKDIR || exit
mv $OPENVPNCERTDIR/server.key $BAKDIR || exit

#Symlink the new certs into the OpenVPN directory structure.
ln -f -s $LETSENCRYPTCERTDIR/fullchain.pem $OPENVPNCERTDIR/ca.crt
ln -f -s $LETSENCRYPTCERTDIR/cert.pem $OPENVPNCERTDIR/server.crt
ln -f -s $LETSENCRYPTCERTDIR/privkey.pem $OPENVPNCERTDIR/server.key

#Can probably just restart an OpenVPN service, but this will do, too.
reboot