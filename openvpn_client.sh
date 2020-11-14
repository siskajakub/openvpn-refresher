#!/bin/bash

################################################################################
## Author: Jakub Siska
## Copyright: Copyright 2020, openvpn-refresher
## License: MIT License
## Email:
## Git: https://github.com/siskajakub/openvpn-refresher.git
################################################################################

# variables
TUN_DEVICE="/dev/net/tun" # tun device
PID_FILE="/etc/openvpn/client/openvpn_client.pid" # openvpn pid file
OPENVPN_CONFIG="/etc/openvpn/client/config/" # folder with openvpn config files
OPENVPN_AUTH="/etc/openvpn/client/auth.txt" # openvpn authentication file


# check for tunnel device being present
if [[ -c $TUN_DEVICE ]]
then
	echo "tun device exists."
else
	# create tun device
	echo "tun device does not exist, creating..."
	mkdir /dev/net
	mknod /dev/net/tun c 10 200
	chmod 666 /dev/net/tun
	echo "tun device has been created."
fi


# stop dante service (socks server)
echo "stopping dante service..."
systemctl stop danted
echo "dante service has been stopped."


# check for openvpn process from PID file, if exists, kill
if [[ -f $PID_FILE ]]
then
	PID=$(< $PID_FILE)
	echo "openvpn pid is $PID, now we are going to kill it."
	kill $PID
	while [[ $(kill -0 $PID) ]]
	do
		sleep .1s
	done
	rm $PID_FILE
	echo "openvpn pid $PID has been terminated."
else
	echo "no openvpn pid."
fi


# select random openvpn config file
OPENVPN_CONFIG_FILE=$(ls $OPENVPN_CONFIG -A1 | grep \.ovpn$ | sort -R | head -1)
echo "openvpn configuration $OPENVPN_CONFIG_FILE has been selected."


# start new openvpn connection
echo "starting new openvpn session..."
/usr/sbin/openvpn --config $OPENVPN_CONFIG$OPENVPN_CONFIG_FILE --auth-user-pass $OPENVPN_AUTH & echo $! > $PID_FILE


# wait until openvpn connects and then restart dante (socks server)
for I in {1..300}
do
	if [[ $(ip tuntap show) ]]
	then
		break
	fi
	sleep .1s
	((I--))
done
echo "restarting dante service..."
systemctl restart danted
echo "dante service has been restarted."
