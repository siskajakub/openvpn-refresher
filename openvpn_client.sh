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
LOG_FILE="/etc/openvpn/client/openvpn_client.log" # openvpn log file
OPENVPN_CONFIG="/etc/openvpn/client/config/" # folder with openvpn config files
OPENVPN_AUTH="/etc/openvpn/client/auth.txt" # openvpn authentication file

# reset log file
echo "INFO: log has been initiated." |& tee $LOG_FILE

# check for tunnel device being present
if [[ -c $TUN_DEVICE ]]
then
	echo "INFO: tun device exists." |& tee -a $LOG_FILE
else
	# create tun device
	echo "INFO: tun device does not exist, creating..." |& tee -a $LOG_FILE
	mkdir /dev/net
	mknod /dev/net/tun c 10 200
	chmod 666 /dev/net/tun
	echo "INFO: tun device has been created." |& tee -a $LOG_FILE
fi


# stop dante service (socks server)
echo "INFO: stopping dante service..." |& tee -a $LOG_FILE
systemctl kill danted
echo "INFO: dante service has been stopped." |& tee -a $LOG_FILE
systemctl status danted |& tee -a $LOG_FILE


# check for openvpn process from PID file, if exists, kill
if [[ -f $PID_FILE ]]
then
	PID=$(< $PID_FILE)
	echo "INFO: openvpn pid is $PID, now we are going to kill it." |& tee -a $LOG_FILE
	kill $PID
	while [[ $(kill -0 $PID) ]]
	do
		sleep .1s
	done
	rm $PID_FILE
	echo "INFO: openvpn pid $PID has been terminated." |& tee -a $LOG_FILE
else
	echo "INFO: no openvpn pid file." |& tee -a $LOG_FILE
fi


# select random openvpn config file
OPENVPN_CONFIG_FILE=$(ls $OPENVPN_CONFIG -A1 | grep \.ovpn$ | sort -R | head -1)
echo "INFO: openvpn configuration $OPENVPN_CONFIG_FILE has been selected." |& tee -a $LOG_FILE


# start new openvpn connection
echo "INFO: starting new openvpn session..." |& tee -a $LOG_FILE
/usr/sbin/openvpn --config $OPENVPN_CONFIG$OPENVPN_CONFIG_FILE --auth-user-pass $OPENVPN_AUTH --writepid $PID_FILE --log-append $LOG_FILE &


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
echo "INFO: restarting dante service..." |& tee -a $LOG_FILE
systemctl restart danted
echo "INFO: dante service has been restarted." |& tee -a $LOG_FILE
systemctl status danted |& tee -a $LOG_FILE
