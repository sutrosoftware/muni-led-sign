#!/bin/bash

if [ "$#" -ne 1 ]; then
	echo "Usage: checksign.sh <hostname>"
	exit 1
fi

if [ -f /home/pi/reset.lock ]; then
	echo "found lock file" >> /home/pi/reset.log
elif ping -q -c 1 $1 &> /dev/null; then
	touch /home/pi/reset.lock
	echo `date` " - starting reset" >> /home/pi/reset.log
	sudo ifconfig wlan0 down
	/home/pi/muni-led-sign/client/clear.pl
	sudo ifconfig wlan0 up
	echo `date` " - finished reset" >> /home/pi/reset.log
	rm /home/pi/reset.lock
fi
