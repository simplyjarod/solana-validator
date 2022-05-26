# solana-validator setup for Ubuntu

1. [Requirements](#requirements)
2. [Installation and setup process](#installation-and-setup-process)
3. [Firewall: block TCP & UDP traffic to 8899 & 8990 ports](#firewall-block-tcp-&-udp-traffic-to-8899-&-8990-ports) (optional)
3. [Nginx proxy and SSL certificates for RPC API](#nginx-proxy-and-ssl-certificates-for-rpc-api) (optional)
4. [Where to find more info](#where-to-find-more-info)


## Requirements
### Hardware
- Disk 1: SSD disk (as fast as possible) of -at least- 1.5 TB. Install OS here. Ledger will be able to use as much as 1.2 TB in this disk.
- Disk 2: SSD disk (as fast as possible) of -at least- 500 GB.
- 256 GB RAM. A tmpfs of 300 GB will be created in RAM (with swap to disk 2).  
- 16 cores / 32 threads of -at least- 2.8 GHz.

For testing purposes (on devnet) you can use almost "any" hardware. For mainnet, at least the above requirements are needed.  
_For best performance, use disk 1 for OS, disk 2 for accounts (swap), disk 3 for ledger (this script does not set this configuration)._
### Software
- You will need to have Ubuntu installed (no special setup is needed).
### Network
- Unlimited traffic usage.
- Public Internet connection of -at least- 300 Mbps symmetric (1 Gbps preferred).
- Ports 8000 to 8020 open (TCP and UDP).
- Ports 8899 and 8900 open (TCP).  

Only if you are going to use Nginx+SSL:  
- Ports 80 and 443 open (TCP).
- A domain or subdomain pointing to the server.
### My setup (as a reference)
_Following data is my configuration (tested and working)_  
- AMD's EPYC 7502P 32 cores / 64 threads. Using about ~26 cores load average.
- Disk 1: 1.92 TB NVMe SSD. Using about ~1.7 TB.
- Disk 2: 960 GB NVMe SSD. Using under 100 GB (due to tmpfs RAMdisk).
- 8 x 32 GB (256 GB total) of DDR4 ECC RAM. Using almost 100%.
- Ubuntu 20.04.
- solana-validator 1.9.25.
- 1 Gbps public connection. Using about ~250 Mbps continuously and 1 Gbps peaks.
- Average internet usage: about 3 TB/day (incoming + outgoing).

## Installation and setup process
All commands should be executed as root. Official documentation and some people recommend creating a "sol" non-root user, but some difficulties were found from my side.  
Please, **download _all files_ before executing any script**. There are several dependencies between them. You can use:
```bash
sudo apt install wget unzip -y
wget https://github.com/simplyjarod/solana-validator/archive/refs/heads/main.zip
unzip main.zip && cd solana-validator-main && rm -rf ../main.zip
chmod u+x *.sh -R
```

```diff
! Please, change lines 141-142 from setup.sh accordingly to your disks configuration.
```
Run `./setup.sh` as **root** from the folder this file is placed.  

The script will prompt you for the net to use (devnet or mainnet-beta).  
```diff
! ONLY if mainnet-beta is chosen, you will need to transfer -at least- 0.3 SOL during the setup (1.1 SOL recommended) in order to create the vote account properly.
```

This script will:
- Install the [Solana Tool Suite](https://docs.solana.com/cli/install-solana-cli-tools) on its latest stable release.
- Set the [cluster](https://docs.solana.com/clusters) (network) to work on (devnet or mainnet-beta based on your choice).
- Create the [systemd systuner.service](https://docs.solana.com/running-validator/validator-start).
- Create the `validator-start.sh` script to [connect the validator](https://docs.solana.com/running-validator/validator-start).
- Create the [systemd validator.service](https://docs.solana.com/running-validator/validator-start).
- Create the RAMdisk for the accounts DB (to reduce SSD wear) and RAMdisk swap (to move RAM data to SSD when more RAM is needed).


## Firewall: block TCP & UDP traffic to 8899 & 8990 ports
By executing `setup.sh` you will be prompted wether install and config firewall (iptables) or not. If you type 'yes' (or simply 'y'), the `./iptables.sh` script will start.  
If you want to stop here and resume this installation later, you can do so by typing 'no' or 'n'. To install and config firewall (iptables) at any moment, execute `./iptables.sh` as **root** from the folder this file is placed.  
This script will:
- Install iptables firewall
- Create a new chain called VALIDATORACCESS, with a rule to DROP all requests.
- ACCEPT TCP and UDP requests to ports 8000-8020.
- Send TCP and UDP requests to ports 8899 and 8900 to VALIDATORACCESS chain.  
To allow any IP to access these blocked ports, just execute `iptables -I VALIDATORACCESS -s aaaa -p xxx --dport yyyy -j ACCEPT` being aaaa the IP, xxx any of *tcp* or *udp* and yyyy your desired port (8899 or 8900).  


## Nginx proxy and SSL certificates for RPC API
By executing `setup.sh` you will be prompted wether install and config nginx+SSL or not. If you type 'yes' (or simply 'y'), the `./nginx-ssl.sh` script will start. **If you don't know what this means or you are not sure if you need it, do not install it.**  
```diff
! In order to correctly generate the SSL certificates, the (sub)domain has to be already pointing to the server before executing this script.
```
If you want to stop here and resume this installation later, you can do so by typing 'no' or 'n'. To install and config nginx+SSL at any moment, execute `./nginx-ssl.sh` as **root** from the folder this file is placed.  

The script will prompt you for the (sub)domain to use.  

This script will:
- Install nginx.
- Remove all enabled sites (in /etc/nginx/sites-enabled)
- Create a new site that redirects http traffic (port 80) to https (443) and proxies POST traffic (RPC) from port 443 to 127.0.0.1:8899 and GET traffic (WS) to 127.0.0.1:8900.
- Install snap, snapd and Let's Encrypt certbot.
- Generate SSL certificates for the specified (sub)domain.


## Where to find more info
- [Solana Documentation - Command Line](https://docs.solana.com/cli/install-solana-cli-tools)
- [Solana Documentation - Validating](https://docs.solana.com/running-validator/validator-start)
- [Setting up a Solana devnet validator](https://github.com/agjell/sol-tutorials/blob/master/setting-up-a-solana-devnet-validator.md)
- [Nginx .conf file used for everstake.one](https://gist.github.com/everstake/b0621e6e1db778c0efaac0df1291e6e4)
- [Securing Solana validator RPC with Nginx](https://everstake.one/blog/securing-solana-validator-rpc-with-nginx-server)
- [Let's Encrypt certbot](https://certbot.eff.org/)
