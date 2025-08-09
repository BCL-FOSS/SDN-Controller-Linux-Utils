#!/bin/bash

# Define the domain
DOMAIN="yourdomain.com"

# Generate a new private key and certificate signing request
openssl req -newkey rsa:2048 -nodes -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.csr

# Create a self-signed certificate
openssl x509 -req -days 365 -in /etc/apache2/ssl/apache.csr -signkey /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt

# Reload the Apache web server to use the new certificate
systemctl reload apache2