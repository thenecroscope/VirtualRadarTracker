#!/bin/bash

# Stop on first error
set -e

myhome=$HOME

echo "Setting up Git Repo...."
echo "-----------------------"
cd $myhome

if [ ! -d "repos" ]; then
	mkdir repos
fi

cd repos
git clone https://github.com/thenecroscope/VirtualRadarTracker.git
cd $myhome/repos/VirtualRadarTracker/
git update-index --assume-unchanged Security/Slack.csv
git update-index --assume-unchanged Security/Twitter.csv
git update-index --assume-unchanged Security/MyLocation.csv
git update-index --assume-unchanged Security/IgnorePlanesURL.csv

sudo bash -c "$(wget -O - https://raw.githubusercontent.com/thenecroscope/VirtualRadarTracker/master/InstallScript.sh)"

echo "-------------------------------"
echo "--- Setting Up VirtualRadar ---"
echo "-------------------------------"
apt install acl
mkdir /opt/VirtualRadarTracker/ServiceStarters -p
chmod -R 777 /opt/VirtualRadarTracker/ServiceStarters/
chown -R nobody:nogroup /opt/VirtualRadarTracker/ServiceStarters/
setfacl -d -m user:nobody:rw /opt/VirtualRadarTracker/ServiceStarters/

mkdir /tmp/VirtualRadarTracker -p
chmod -R 777 /tmp/VirtualRadarTracker/
chown -R nobody:nogroup /tmp/VirtualRadarTracker
setfacl -d -m user:nobody:rw /tmp/VirtualRadarTracker/

echo -e '#!/usr/bin/env pwsh' | sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsInteresting.ps1
echo -e $myhome'/repos/VirtualRadarTracker/AircraftAlerts.ps1 interesting Slack Remote' | sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsInteresting.ps1
echo -e '#!/usr/bin/env pwsh' | sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsWorldWar.ps1
echo -e $myhome'/repos/VirtualRadarTracker/AircraftAlerts.ps1' worldwar Twitter Remote| sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsWorldWar.ps1
echo -e '#!/usr/bin/env pwsh' | sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsMilitary.ps1
echo -e $myhome'/repos/VirtualRadarTracker/AircraftAlerts.ps1' military Slack Remote| sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsMilitary.ps1
echo -e '#!/usr/bin/env pwsh' | sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsLocal.ps1
echo -e $myhome'/repos/VirtualRadarTracker/AircraftAlerts.ps1' local Slack Remote| sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsLocal.ps1
chmod +x /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsInteresting.ps1
chmod +x /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsWorldWar.ps1
chmod +x /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsMilitary.ps1
chmod +x /opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsLocal.ps1

echo -e "[Service]\nExecStart=/opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsInteresting.ps1\n[Install]\nWantedBy=default.target" | sudo tee --append /etc/systemd/system/AircraftAlertsInteresting.service
echo -e "[Service]\nExecStart=/opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsWorldWar.ps1\n[Install]\nWantedBy=default.target" | sudo tee --append /etc/systemd/system/AircraftAlertsWorldWar.service
echo -e "[Service]\nExecStart=/opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsMilitary.ps1\n[Install]\nWantedBy=default.target" | sudo tee --append /etc/systemd/system/AircraftAlertsMilitary.service
echo -e "[Service]\nExecStart=/opt/VirtualRadarTracker/ServiceStarters/AircraftAlertsLocal.ps1\n[Install]\nWantedBy=default.target" | sudo tee --append /etc/systemd/system/AircraftAlertsLocal.service
systemctl enable AircraftAlertsInteresting.service
systemctl enable AircraftAlertsWorldWar.service
systemctl enable AircraftAlertsMilitary.service
systemctl enable AircraftAlertsLocal.service
systemctl daemon-reload

echo "----------------------------------"
echo "---- Install Script Finsished ----"
echo "----------------------------------"
echo "Update Your Config Files HERE (cd $myhome/repos/VirtualRadarTracker/Security)"
echo "To start your services now run the following commands:"
echo "sudo systemctl start AircraftAlertsInteresting"
echo "sudo systemctl start AircraftAlertsWorldWar"
echo "sudo systemctl start AircraftAlertsMilitary"
echo "sudo systemctl start AircraftAlertsLocal"
exit