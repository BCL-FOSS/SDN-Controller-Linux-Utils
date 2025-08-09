# SDN-Controller-Linux-Utils

## About 
A collection of scripts for self hosting Ubiquiti UniFi & TP-Link Omada Network Controllers.

Supports Ubuntu & Debian based distros. Tested on Ubuntu 22.04 LTS

UniFi SSL script(s) inspired by [Steve Jenkin's unifi-linux-utils unifi_ssl_import.sh](https://github.com/stevejenkins/unifi-linux-utils)

### UniFi
* ubnt-install.sh: Installs latest UniFi Network controller & imports letsencrypt SSL cert. Replace {{ controller-fqdn }} with your FQDN
```bash
    sudo chmod +x ubnt-install.sh 
    sudo ./ubnt-install.sh {{ email }} {{ controller-fqdn }}
```
* ubnt-ssl-config.sh: Imports letsencrypt SSL cert on UniFi controller
```bash
    # Run ubnt ssl configuration
    sudo chmod +x ubnt-ssl-config.sh
    sudo ./ubnt-ssl-config.sh {{ controller-fqdn }}
```

### Omada
* Retrieve .deb download link from [Omada Software Controller site](https://support.omadanetworks.com/us/product/omada-software-controller/?resourceType=download)
```bash
    wget https://static.tp-link.com/upload/software/2025/202508/20250802/omada_v5.15.24.19_linux_x64_20250724152622.deb

    sudo chmod +x omada_v5.15.24.19_linux_x64_20250724152622.deb

    sudo dpkg -i omada_v5.15.24.19_linux_x64_20250724152622.deb
```

* Run omada-le-ssl-config.sh to install LetsEncrypt cert on Omada controller. Replace {{ controller-fqdn }} with your FQDN
```bash
    sudo chmod +x omada-le-ssl-config.sh
    sudo ./omada-le-ssl.config.sh {{ controller-fqdn }}
```

* For self signed certificates on Omada controllers visit omada->self-signed-ssl and follow the instructions in the included README


#!/usr/bin/env bash






