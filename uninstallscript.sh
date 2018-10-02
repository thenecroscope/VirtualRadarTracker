#!/bin/bash
myhome=$HOME

cd $myhome
echo "Note this will remove your local configuration files"



read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	sudo systemctl stop AircraftAlertsInteresting.service
	sudo systemctl stop AircraftAlertsWorldWar.service
	sudo systemctl stop AircraftAlertsMilitary.service
	sudo systemctl stop AircraftAlertsLocal.service
	sudo systemctl disable AircraftAlertsInteresting.service
	sudo systemctl disable AircraftAlertsWorldWar.service
	sudo systemctl disable AircraftAlertsMilitary.service
	sudo systemctl disable AircraftAlertsLocal.service
	sudo systemctl daemon-reload
	sudo rm $myhome/repos/VirtualRadarTracker/ -R    
	sudo rm /etc/systemd/system/AircraftAlerts*.*
	sudo rm /opt/VirtualRadarTracker/ -R
fi
