#!/bin/sh

# ARE YOU ROOT (or sudo)?
if [[ $EUID -ne 0 ]]; then
	echo -e "\e[91mERROR: This script must be run as root\e[0m"
	exit 1
fi

apt install nginx -y


# Remove all enabled sites:
rm -f /etc/nginx/sites-enabled/*.conf

# Copy the template to sites-available:
\cp nginx-site.sh /etc/nginx/sites-available/solana.conf

read -r -p "What (sub)domain would you like to use? Do not write 'http' or 'www' (e.g. domain.com): " domain
domain=${domain,,} # tolower

# Customize nginx file with domain name:
sed -i "s|CHANGE_THIS_DOMAIN_NAME|$domain|g" /etc/nginx/sites-available/solana.conf


# Installation of snap and snapd to install Let's Encrypt certbot:
apt install snap snapd -y
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
certbot certonly --nginx # just get the certificate


# Symbolic link from available to enabled (to enable the config file):
ln -s /etc/nginx/sites-available/solana.conf /etc/nginx/sites-enabled/solana.conf


systemctl enable nginx
systemctl restart nginx