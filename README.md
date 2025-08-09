# SDN-Linux-Utils

### About ###
A collection of scripts for self hosted Ubiquiti UniFi & TP-Link Omada Network Controllers.

Supporting controllers hosted on Ubuntu & Debian based distros.

SSL script inspired by [Steve Jenkin's unifi-linux-utils unifi_ssl_import.sh](https://github.com/stevejenkins/unifi-linux-utils)

### UniFi ###
* ubnt-install.sh: Installs latest UniFi Network controller & imports letsencrypt SSL cert
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

