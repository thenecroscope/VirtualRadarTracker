#!/bin/bash
myhome=$HOME

cd $myhome
echo "Note this will remove your local configuration files"



read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	sudo systemctl stop AircraftInteresting.service
	sudo systemctl stop AircraftMilitary.service
	sudo systemctl disable AircraftInteresting.service
	sudo systemctl disable AircraftMilitary.service
	sudo systemctl daemon-reload
	sudo rm $myhome/repos/VirtualRadarTracker/ -R    
	sudo rm /etc/systemd/system/Aircraft*.*
	sudo rm /opt/VirtualRadarTracker/ -R
fi
