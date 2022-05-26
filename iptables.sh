#!/bin/sh

# ARE YOU ROOT (or sudo)?
if [[ $EUID -ne 0 ]]; then
	echo -e "\e[91mERROR: This script must be run as root\e[0m"
	exit 1
fi


read -r -p "This will block incomming traffic to port 8899. Continue? [y/N] " response
res=${response,,} # tolower
if ! [[ $res =~ ^(yes|y)$ ]]; then
	echo "Aborted. No firewall installed."
	exit 1
fi


apt install iptables -y


# Create new chain
iptables -N VALIDATORACCESS

# Create "policy rule" as custom chains cannot have policy
iptables -A VALIDATORACCESS -j DROP


# Basic rules in INPUT chain (even if your input chain policy is ACCEPT, this will show you some statistics)
iptables -A INPUT -p tcp --dport 8000:8020 -j ACCEPT
iptables -A INPUT -p udp --dport 8000:8020 -j ACCEPT
iptables -A INPUT -p tcp --dport 8899 -j VALIDATORACCESS
iptables -A INPUT -p udp --dport 8899 -j VALIDATORACCESS
iptables -A INPUT -p tcp --dport 8990 -j VALIDATORACCESS
iptables -A INPUT -p udp --dport 8990 -j VALIDATORACCESS


# Save values to be applied after system reboot
iptables-save


echo -e "\e[34mType 'iptables -I VALIDATORACCESS -s aaaa -p xxx --dport yyyy -j ACCEPT' being aaaa your IP, xxx tcp or udp and yyyy your desired port (8899 or 8900) to allow connections from your IP\e[0m"