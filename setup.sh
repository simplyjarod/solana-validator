#!/bin/sh

# ARE YOU ROOT (or sudo)?
if [[ $EUID -ne 0 ]]; then
	echo -e "\e[91mERROR: This script must be run as root\e[0m"
	exit 1
fi

cd # will be /root

# Installation of Solana and devnet choice
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
solana-install update

choosen_net='devnet'

read -r -p "Which net would you like to use? [main/DEV] " response
res=${response,,} # tolower
if [[ $res =~ ^(main)$ ]]; then
	choosen_net='mainnet-beta'
fi

if [ "$choosen_net" == "mainnet-beta" ]; then
	solana config set --url https://api.mainnet-beta.solana.com
else
	solana config set --url https://api.devnet.solana.com
fi

solana transaction-count


# Creation of systuner.service
cat > /etc/systemd/system/systuner.service <<EOF
[Unit]
Description=Solana System Tuner
After=network.target

[Service]
Type=simple
Restart=on-failure
RestartSec=1
LogRateLimitIntervalSec=0
ExecStart=/root/.local/share/solana/install/active_release/bin/solana-sys-tuner --user root

[Install]
WantedBy=multi-user.target
EOF


# Creation of validator-start.sh
if [ "$choosen_net" == "mainnet-beta" ]; then
cat > validator-start.sh <<EOF
#!/bin/sh
exec solana-validator \\
	--identity /root/validator-keypair.json \\
	--vote-account /root/vote-account-keypair.json \\
	--dynamic-port-range 8000-8020 \\
	--rpc-port 8899 \\
	--full-rpc-api \\
	--entrypoint entrypoint.${choosen_net}.solana.com:8001 \\
	--entrypoint entrypoint2.${choosen_net}.solana.com:8001 \\
	--entrypoint entrypoint3.${choosen_net}.solana.com:8001 \\
	--entrypoint entrypoint4.${choosen_net}.solana.com:8001 \\
	--entrypoint entrypoint5.${choosen_net}.solana.com:8001 \\
	--known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \\
	--known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \\
	--known-validator DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ \\
	--known-validator CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S \\
	--only-known-rpc \\
	--expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \\
	--wal-recovery-mode skip_any_corrupted_record \\
	--ledger /root/ledger-${choosen-net}/ \\
	--limit-ledger-size 600000000 \\
	--accounts /mnt/solana-accounts \\
	--log /root/log/solana-validator.log \\
	--no-port-check
EOF
else
cat > validator-start.sh <<EOF
#!/bin/sh
exec solana-validator \\
	--identity /root/validator-keypair.json \\
	--vote-account /root/vote-account-keypair.json \\
	--dynamic-port-range 8000-8020 \\
	--rpc-port 8899 \\
	--full-rpc-api \\
	--entrypoint entrypoint.${choosen_net}.solana.com:8001 \\
	--entrypoint entrypoint2.${choosen_net}.solana.com:8001 \\
	--entrypoint entrypoint3.${choosen_net}.solana.com:8001 \\
	--entrypoint entrypoint4.${choosen_net}.solana.com:8001 \\
	--entrypoint entrypoint5.${choosen_net}.solana.com:8001 \\
	--ledger /root/ledger-${choosen-net}/ \\
	--limit-ledger-size 600000000 \\
	--accounts /mnt/solana-accounts \\
	--log /root/log/solana-validator.log 
EOF
fi
chmod +x validator-start.sh
mkdir log


# Creation of validator.service
cat > /etc/systemd/system/validator.service <<EOF
[Unit]
Description=Solana Validator
After=network.target
Wants=systuner.service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=on-failure
RestartSec=1
LimitNOFILE=1000000
LogRateLimitIntervalSec=0
User=root
Environment=PATH=/bin:/usr/bin:/root/.local/share/solana/install/active_release/bin
Environment=SOLANA_METRICS_CONFIG=host=https://metrics.solana.com:8086,db=${choosen_net},u=scratch_writer,p=topsecret
ExecStart=/root/validator-start.sh

[Install]
WantedBy=multi-user.target
EOF

# New services have to be applied
systemctl daemon-reload


# Creation of RAMdisk for the accounts DB (to reduce SSD wear)
mkdir /mnt/solana-accounts
echo "tmpfs /mnt/solana-accounts tmpfs rw,size=300G,user=root 0 0" >> /etc/fstab

# Creation of RAMdisk swap (used when more RAM is needed)
# with "swapon --show" we can see swap files (usually 4GB in partition 1)
# we should disable it by commenting its line in /etc/fstab, because we are going to use a bigger swap
# with "fdisk -l" see disks and partitions
# use an extra/empty disk to create a partition (e.g. "fdisk /dev/nvme0n1p1" and type n, p, enter, enter and w or whatever you need)
mkswap /dev/nvme0n1p1
echo "/dev/nvme0n1p1 swap swap defaults 0 0" >> /etc/fstab
swapon -a
mount /mnt/solana-accounts
free -g # see total/used/free/available mem and swap (g for GB)


# Keys generation
solana-keygen new -o validator-keypair.json
solana config set --keypair validator-keypair.json
solana airdrop 1 # in devnet we can ask for 1 SOL
solana-keygen new -o authorized-withdrawer-keypair.json
solana-keygen new -o vote-account-keypair.json

# Vote account creation
solana create-vote-account vote-account-keypair.json validator-keypair.json authorized-withdrawer-keypair.json

echo "YOU SHOULD EXPORT/DOWNLOAD authorized-withdrawer-keypair.json NOW AND REMOVE IT FROM DISK!!!"

# Config of logrotate, to avoid huge log files
cat > /etc/logrotate.d/root <<EOF
/root/log/solana-validator.log {
	rotate 7
	daily
	missingok
	postrotate
		systemctl kill -s USR1 validator.service
	endscript
}
EOF
systemctl restart logrotate.service


# Finally, we enable and start validator
systemctl enable systuner
systemctl enable validator
systemctl start systuner
systemctl start validator
