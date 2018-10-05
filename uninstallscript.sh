#!/bin/bash
myhome=$HOME

cd $myhome
echo "Note this will remove your local configuration files"



read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	sudo systemctl stop vrtInteresting.service
	sudo systemctl stop vrtMilitary.service
	sudo systemctl disable vrtInteresting.service
	sudo systemctl disable vrtMilitary.service
	sudo systemctl daemon-reload
	sudo rm $myhome/repos/VirtualRadarTracker/ -R    
	sudo rm /etc/systemd/system/vrt*.*
	sudo rm /opt/VirtualRadarTracker/ -R
fi
