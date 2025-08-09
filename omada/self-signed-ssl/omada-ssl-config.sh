#!/bin/bash

OMADA_HOSTNAME=$1

# install openssl
sudo apt-get install openssl

# Generate certificate
openssl req -newkey rsa:2048 -nodes -keyout ${OMADA_HOSTNAME}.key -out ${OMADA_HOSTNAME}.csr

# Create self-signed certificate
openssl x509 -req -days 365 -in ${OMADA_HOSTNAME}.csr -signkey ${OMADA_HOSTNAME}.key -out ${OMADA_HOSTNAME}.crt

# Generate self-signed certificate
sudo mkdir /etc/apache2/ssl

sudo openssl req -newkey rsa:2048 -nodes -keyout /etc/apache2/ssl/apache.key -x509 -days 365 -out /etc/apache2/ssl/apache.crt
