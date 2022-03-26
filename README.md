# solana-validator setup for Ubuntu
_Tested on Ubuntu 20.04 & solana-validator 1.9.14_  
_More info at [Solana Documentation - Command Line](https://docs.solana.com/cli/install-solana-cli-tools) and [Solana Documentation - Validating](https://docs.solana.com/running-validator/validator-start)_ 

Please, **download _all files_ before executing any script**. There are several dependencies between them. You can use:
```bash
sudo apt install wget unzip -y
wget https://github.com/simplyjarod/solana-validator/archive/refs/heads/main.zip
unzip main.zip && cd solana-validator-main && rm -rf ../main.zip
chmod u+x *.sh -R
```

## 0. Requirements
### Hardware
- Disk 1: SSD disk (as fast as possible) of -at least- 1 TB. Install OS here. Ledger will be able to use as much as 600 GB in this disk.
- Disk 2: SSD disk (as fast as possible) of -at least- 500 GB.
- 256 GB RAM. A tmpfs of 300 GB will be created in RAM (with swap to disk 2).  

For testing purposes (on devnet) you can use almost "any" hardware. For mainnet, at least the above requirements are needed.  
_For best performance, use disk 1 for OS, disk 2 for accounts (swap), disk 3 for ledger (this script does not set this configuration)._

### Network
- Ports 8000 to 8020 open (TCP and UDP).
- Ports 8899 and 8900 open (TCP).


## 1. Installation and setup process
All commands should be executed as root. Official documentation and some people recommend creating a "sol" non-root user, but some difficulties were found from my side.  
The script will prompt you for the net to use (devnet or mainnet-beta).

This script will:
- Install the [Solana Tool Suite](https://docs.solana.com/cli/install-solana-cli-tools) on its latest stable release.
- Set the [cluster](https://docs.solana.com/clusters) (network) to work on (devnet or mainnet-beta based on your choice).
- Create the [systemd systuner.service](https://docs.solana.com/running-validator/validator-start).
- Create the `validator-start.sh` script to [connect the validator](https://docs.solana.com/running-validator/validator-start).
- Create the [systemd validator.service](https://docs.solana.com/running-validator/validator-start).
- Create the RAMdisk for the accounts DB (to reduce SSD wear) and RAMdisk swap (to move RAM data to SSD when more RAM is needed).

Please, change lines 138-139 from setup.sh accordingly to your disks configuration.  
Run `./setup.sh` as **root** from the folder this file is placed.


## 2. Nginx proxy and SSL certificates for RPC API
