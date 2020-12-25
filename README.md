# openvpn-refresher
Script that makes OpenVPN client periodically auto-connect to one of the multiple servers.

# Requirements
Script is using an OpenVPN client to connect to various VPN servers. In addition, Dante is used as a proxy SOCKS server to allow transparent connection of multiple hosts.  
To use the script you need to install OpenVPN and Dante, and configure them properly.

# Install
## 1) OpenVPN + Dante
Install OpenVPN and Dante.
```bash
$ apt update
$ apt install openvpn
$ apt install dante-server
```
Configure OpenVPN and Dante to your needs. How to configure both applications is outside of the scope of this manual.  
Just one remark, make sure that for Dante configuration, `/etc/danted.conf`, tunnel interface is used for all outgoing connections.
```
external: tun0
```

## 2) Script
Import the `openvpn_client.sh` and make it executable.
```bash
$ chmod +x openvpn_client.sh
```

## 3) Cron
Add a job to cron and make sure you have configured the script's variables to reflect your environment.
```bash
$ crontab -e
```
```
# connect openvpn on startup and refresh connection every 10 minutes
@reboot /path/openvpn_client.sh
*/10 * * * * /path/openvpn_client.sh
```

## 4) Dante Service (optional)
In order for Dante service to stop faster, the stop signal can be changed from `SIGTERM` to `SIGKILL` in the configuration file (`/lib/systemd/system/danted.service`).
```
KillSignal=9
```

# Notes
Script was developed and tested in an LXC container running Ubuntu 20.04.
