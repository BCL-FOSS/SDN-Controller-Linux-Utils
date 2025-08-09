#!/bin/bash

set -e

SSH_PORT=5050
HOST_IP="your_control_ip"
SUDO_TIMEOUT=60
UFW_LOG="high"

# Get current date
CUR_DATE=$(date +"%Y%m%d")

# Update and upgrade system
echo "[+] Updating package cache..."
apt-get update -y
echo "[+] Upgrading packages..."
apt-get upgrade -y

# Install essential packages
echo "[+] Installing required packages..."
apt-get install -y apt-transport-https build-essential fail2ban pwgen unbound unzip

# Configure systemd-resolved for unbound
echo "[+] Configuring systemd-resolved..."
mkdir -p /etc/systemd/resolved.conf.d
cat <<EOF > /etc/systemd/resolved.conf.d/local.conf
[Resolve]
DNSStubListener=no
DNS=127.0.0.1
EOF

ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl restart systemd-resolved

# Set sudo password timeout
echo "[+] Configuring sudo timeout..."
echo "Defaults env_reset, timestamp_timeout=$SUDO_TIMEOUT" >> /etc/sudoers

# Secure SSH
echo "[+] Hardening SSH configuration..."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

if [[ $(lsb_release -rs) < "22.10" ]]; then
    sed -i "s/^#Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config
    systemctl restart ssh
else
    mkdir -p /etc/systemd/system/ssh.socket.d
    cat <<EOF > /etc/systemd/system/ssh.socket.d/listen.conf
[Socket]
ListenStream=
ListenStream=$SSH_PORT
EOF
    systemctl daemon-reload
    systemctl restart ssh.socket
fi

# Set custom bash prompt
echo "[+] Configuring bash prompt..."
echo "PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\n\$ '" >> ~/.bashrc
echo "PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\n\$ '" >> /root/.bashrc

# Configure UFW
echo "[+] Setting up firewall..."
ufw reset
ufw allow "$SSH_PORT"/tcp
ufw logging "$UFW_LOG"
ufw enable

# Configure fail2ban
echo "[+] Configuring Fail2Ban..."
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 $HOST_IP
findtime = 15m
bantime = 2h
maxretry = 5

[sshd]
enabled = true
maxretry = 3
port = $SSH_PORT
EOF

systemctl enable fail2ban --now

# Create f2bst script for checking fail2ban status
echo "[+] Creating f2bst script..."
cat <<EOF > /usr/local/bin/f2bst
#!/bin/sh
fail2ban-client status \$*
EOF
chmod 750 /usr/local/bin/f2bst

# Check if reboot is needed
if [ -f /var/run/reboot-required ]; then
    echo "[+] System requires a reboot. Rebooting now..."
    reboot
fi

echo "[+] Hardening complete!"
