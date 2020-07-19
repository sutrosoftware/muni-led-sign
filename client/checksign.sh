#!/bin/bash

if [ "$#" -ne 1 ]; then
	echo "Usage: checksign.sh <hostname>"
	exit 1
fi

LOG=/home/pi/reset.log
LOCK=/home/pi/reset.lock

if [ -f $LOCK ]; then
	echo "found lock file" 
	echo "found lock file" >> $LOG
	exit
fi

ping -c 1 -w 2 $1 &> /dev/null
ERRORCODE=$?

if [ "$ERRORCODE" -ne 0 ]; then
	touch $LOCK
	echo `date` " - starting reset" >> $LOG
	sudo systemctl stop muni
	sudo ifconfig wlan0 down
	/home/pi/muni-led-sign/client/clear.pl
	sudo ifconfig wlan0 up
	sudo systemctl start muni
	echo `date` " - finished reset" >> $LOG
	rm $LOCK
fi
