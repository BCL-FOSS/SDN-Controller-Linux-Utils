#!/bin/bash

DOMAIN=$1

snap install core; sudo snap refresh core
snap install --classic certbot

ln -s /snap/bin/certbot /usr/bin/certbot

certbot certonly --standalone --preferred-challenges http -d ${DOMAIN}

systemctl stop omada.service

rm /opt/tplink/EAPController/keystore/eap.cer
rm /opt/tplink/EAPController/keystore/eap.keystore

cp /etc/letsencrypt/live/${DOMAIN}/cert.pem /opt/tplink/EAPController/keystore/eap.cer

openssl pkcs12 -export -inkey /etc/letsencrypt/live/${DOMAIN}/privkey.pem \
-in /etc/letsencrypt/live/${DOMAIN}/cert.pem \
-certfile /etc/letsencrypt/live/${DOMAIN}/chain.pem \
-name eap -out patrick.p12 -password pass:tplink

keytool -importkeystore -deststorepass tplink \
   -destkeystore /opt/tplink/EAPController/keystore/eap.keystore \
   -srckeystore patrick.p12 -srcstoretype PKCS12 -srcstorepass tplink

systemctl start omada.service

#tpeap stop
#certbot certonly --standalone --preferred-challenges http -d example.com
#openssl pkcs12 -export -inkey /etc/letsencrypt/live/example.com/privkey.pem -in /etc/letsencrypt/live/example.com/fullchain.pem -certfile /etc/letsencrypt/live/example.com/chain.pem -name eap -out omada.p12 -password pass:tplink
#cp /etc/letsencrypt/live/example.com/fullchain.pem /opt/tplink/EAPController/data/keystore/eap.cer
#keytool -importkeystore -deststorepass tplink -destkeystore /opt/tplink/EAPController/data/keystore/eap.keystore -srckeystore omada.p12 -srcstoretype PKCS12 -srcstorepass tplink
#tpeap start