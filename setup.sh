#!/bin/sh

# based on https://docs.solana.com/running-validator/validator-start
# for Ubuntu 20.04

# as root
cd /root
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

solana-install update

solana config set --url https://api.devnet.solana.com

solana transaction-count


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


cat > /root/validator-start.sh <<EOF
#!/bin/sh
exec solana-validator \
  --identity /root/validator-keypair.json \
  --vote-account /root/vote-account-keypair.json \
  --rpc-port 8899 \
  --entrypoint entrypoint.devnet.solana.com:8001 \
  --entrypoint entrypoint2.devnet.solana.com:8001 \
  --entrypoint entrypoint3.devnet.solana.com:8001 \
  --entrypoint entrypoint4.devnet.solana.com:8001 \
  --entrypoint entrypoint5.devnet.solana.com:8001 \
  --ledger /root/ledger/ \
  --limit-ledger-size 600000000 \
  --log /root/log/solana-validator.log \
  --no-port-check
EOF
chmod +x /root/validator-start.sh
mkdir log


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
Environment=SOLANA_METRICS_CONFIG=host=https://metrics.solana.com:8086,db=devnet,u=scratch_writer,p=topsecret
ExecStart=/root/validator-start.sh

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload



solana-keygen new -o validator-keypair.json
solana config set --keypair validator-keypair.json

solana airdrop 1

solana-keygen new -o authorized-withdrawer-keypair.json
solana-keygen new -o vote-account-keypair.json

solana create-vote-account vote-account-keypair.json validator-keypair.json authorized-withdrawer-keypair.json

echo "YOU SHOULD EXPORT/DOWNLOAD authorized-withdrawer-keypair.json NOW AND REMOVE IT FROM DISK!!!"


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


systemctl enable systuner
systemctl enable validator

systemctl start systuner
systemctl start validator
