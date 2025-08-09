# Self Signed OpenSSL Cert Configuration for TP-Link Omada Controllers

* Once Omada controller software is installed, run self-signed SSL certification configuration
```bash
    # omada-ssl-config.sh: Configures OpenSSL certs for import within Omada GUI, replace yourdomain.com with your FQDN

    sudo chmod +x omada-ssl-config.sh
    sudo ./omada-ssl-config.sh yourdomain.com

    # Add SSL cert to Apache Airflow
    nano /etc/apache2/sites-available/airflow.conf

    # Add following lines to config file (replace yourdomain.com with your FQDN or IP Address) then save and close the file
    <VirtualHost *:8043> ServerName yourdomain.com SSLEngine on SSLCertificateFile /etc/apache2/ssl/apache.crt SSLCertificateKeyFile /etc/apache2/ssl/apache.key </VirtualHost>

    # Enable new Apache Airflow config
    sudo a2ensite airflow

    # Reload Apache web server
    sudo systemctl reload apache2

    # Verify HTTPS is configured correctly by visiting https://yourdomain.com:8043
```
* Self-signed SSL cert renewal automation script
```bash
    # Clone omada-ssl-renewal.sh and replace $DOMAIN variable with your FQDN

    # make script executable
    chmod +x omada-ssl-renewal.sh

    # Edit crontab
    crontab -e

    # Runs the script at 3am on the 1st of the 11th month (November)
    0 3 1 11 * /path_to_script/renew_cert.sh

    # Save crontab
```