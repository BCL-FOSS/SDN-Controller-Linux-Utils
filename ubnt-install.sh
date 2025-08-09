#!/usr/bin/env bash

ssl_config() {
    # CONFIGURATION OPTIONS
    UNIFI_HOSTNAME=$1
    UNIFI_SERVICE=unifi

    UNIFI_DIR=/var/lib/unifi
    JAVA_DIR=/usr/lib/unifi
    KEYSTORE=${UNIFI_DIR}/keystore

    # FOR LET'S ENCRYPT SSL CERTIFICATES ONLY
    # Generate your Let's Encrtypt key & cert with certbot before running this script
    LE_MODE=yes
    LE_LIVE_DIR=/etc/letsencrypt/live

    # THE FOLLOWING OPTIONS NOT REQUIRED IF LE_MODE IS ENABLED
    PRIV_KEY=/etc/ssl/private/${UNIFI_HOSTNAME}.key
    SIGNED_CRT=/etc/ssl/certs/${UNIFI_HOSTNAME}.crt
    CHAIN_FILE=/etc/ssl/certs/startssl-chain.crt

    # CONFIGURATION OPTIONS YOU PROBABLY SHOULDN'T CHANGE
    ALIAS=unifi
    PASSWORD=aircontrolenterprise

    #### SHOULDN'T HAVE TO TOUCH ANYTHING PAST THIS POINT ####

    printf "\nStarting UniFi Controller SSL Import...\n"

    # Check to see whether Let's Encrypt Mode (LE_MODE) is enabled

    if [[ ${LE_MODE} == "YES" || ${LE_MODE} == "yes" || ${LE_MODE} == "Y" || ${LE_MODE} == "y" || ${LE_MODE} == "TRUE" || ${LE_MODE} == "true" || ${LE_MODE} == "ENABLED" || ${LE_MODE} == "enabled" || ${LE_MODE} == 1 ]] ; then
        LE_MODE=true
        printf "\nRunning in Let's Encrypt Mode...\n"
        PRIV_KEY=${LE_LIVE_DIR}/${UNIFI_HOSTNAME}/privkey.pem
        CHAIN_FILE=${LE_LIVE_DIR}/${UNIFI_HOSTNAME}/fullchain.pem
    else
        LE_MODE=false
        printf "\nRunning in Standard Mode...\n"
    fi

    if [[ ${LE_MODE} == "true" ]]; then
        # Check to see whether LE certificate has changed
        printf "\nInspecting current SSL certificate...\n"
        if md5sum -c "${LE_LIVE_DIR}/${UNIFI_HOSTNAME}/privkey.pem.md5" &>/dev/null; then
            # MD5 remains unchanged, exit the script
            printf "\nCertificate is unchanged, no update is necessary.\n"
            exit 0
        else
        # MD5 is different, so it's time to get busy!
        printf "\nUpdated SSL certificate available. Proceeding with import...\n"
        fi
    fi

    # Verify required files exist
    if [[ ! -f ${PRIV_KEY} ]] || [[ ! -f ${CHAIN_FILE} ]]; then
        printf "\nMissing one or more required files. Check your settings.\n"
        exit 1
    else
        # Everything looks OK to proceed
        printf "\nImporting the following files:\n"
        printf "Private Key: %s\n" "$PRIV_KEY"
        printf "CA File: %s\n" "$CHAIN_FILE"
    fi

    # Create temp files
    P12_TEMP=$(mktemp)

    # Stop the UniFi Controller
    printf "\nStopping UniFi Controller...\n"
    service "${UNIFI_SERVICE}" stop

    if [[ ${LE_MODE} == "true" ]]; then
        
        # Write a new MD5 checksum based on the updated certificate	
        printf "\nUpdating certificate MD5 checksum...\n"

        md5sum "${PRIV_KEY}" > "${LE_LIVE_DIR}/${UNIFI_HOSTNAME}/privkey.pem.md5"
        
    fi

    # Create double-safe keystore backup
    if [[ -s "${KEYSTORE}.orig" ]]; then
        printf "\nBackup of original keystore exists!\n"
        printf "\nCreating non-destructive backup as keystore.bak...\n"
        cp "${KEYSTORE}" "${KEYSTORE}.bak"
    else
        cp "${KEYSTORE}" "${KEYSTORE}.orig"
        printf "\nNo original keystore backup found.\n"
        printf "\nCreating backup as keystore.orig...\n"
    fi
        
    # Export your existing SSL key, cert, and CA data to a PKCS12 file
    printf "\nExporting SSL certificate and key data into temporary PKCS12 file...\n"

    #If there is a signed crt we should include this in the export
    if [[ -f ${SIGNED_CRT} ]]; then
        openssl pkcs12 -export \
        -in "${CHAIN_FILE}" \
        -in "${SIGNED_CRT}" \
        -inkey "${PRIV_KEY}" \
        -out "${P12_TEMP}" -passout pass:"${PASSWORD}" \
        -name "${ALIAS}"
    else
        openssl pkcs12 -export \
        -in "${CHAIN_FILE}" \
        -inkey "${PRIV_KEY}" \
        -out "${P12_TEMP}" -passout pass:"${PASSWORD}" \
        -name "${ALIAS}"
    fi
        
    # Delete the previous certificate data from keystore to avoid "already exists" message
    printf "\nRemoving previous certificate data from UniFi keystore...\n"
    keytool -delete -alias "${ALIAS}" -keystore "${KEYSTORE}" -deststorepass "${PASSWORD}"
        
    # Import the temp PKCS12 file into the UniFi keystore
    printf "\nImporting SSL certificate into UniFi keystore...\n"
    keytool -importkeystore \
    -srckeystore "${P12_TEMP}" -srcstoretype PKCS12 \
    -srcstorepass "${PASSWORD}" \
    -destkeystore "${KEYSTORE}" \
    -deststorepass "${PASSWORD}" \
    -destkeypass "${PASSWORD}" \
    -alias "${ALIAS}" -trustcacerts

    # Clean up temp files
    printf "\nRemoving temporary files...\n"
    rm -f "${P12_TEMP}"
        
    # Restart the UniFi Controller to pick up the updated keystore
    printf "\nRestarting UniFi Controller to apply new Let's Encrypt SSL certificate...\n"
    service "${UNIFI_SERVICE}" start

    # That's all, folks!
    printf "\nDone!\n"

}

# Ansible Installation
sudo apt-get install -y python3-pip
pip install ansible

# Unifi Repo
sudo apt-get update && sudo apt-get install -y ca-certificates && sudo apt-get install -y apt-transport-https
echo 'deb [ arch=amd64,arm64 ] https://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg

# Mongo Repo
sudo apt-get install -y gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc |    sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg    --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Allow necessary ports/Install MongoDB & UniFi Network Controller
ufw allow 8080
ufw allow 8443
ufw allow 80

sudo apt-get update
sudo apt-get install -y mongodb-org
sudo apt-get update && sudo apt-get install -y unifi

# Request SSL Cert
sudo apt-get update &&  sudo apt-get install -y certbot && sudo apt-get install -y python3-certbot-apache

# Request SSL certs
certbot --apache --email "$1" --no-eff-email --agree-tos -n -d "$2" --quiet

# Grant app user permissions to letsencrypt directory
TARGET_DIR=/etc/letsencrypt/live
USER=srvradmin
sudo chown -R $USER $TARGET_DIR
sudo chmod -R 770 $TARGET_DIR

# Verify changes
sudo ls -ld $TARGET_DIR

# View letsencrypt directory
sudo ls $TARGET_DIR

ssl_config $2

systemctl status unifi



