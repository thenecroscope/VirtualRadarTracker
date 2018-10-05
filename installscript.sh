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
git update-index --assume-unchanged configs/configs.csv

sudo bash -c "$(wget -O - https://raw.githubusercontent.com/thenecroscope/VirtualRadarTracker/master/InstallScript.sh)"

echo "-------------------------------"
echo "--- Setting Up VirtualRadar ---"
echo "-------------------------------"
apt install acl
mkdir /opt/VirtualRadarTracker/ServiceStarters -p
chmod -R 777 /opt/VirtualRadarTracker/ServiceStarters/
chown -R nobody:nogroup /opt/VirtualRadarTracker/ServiceStarters/
setfacl -d -m user:nobody:rw /opt/VirtualRadarTracker/ServiceStarters/

chmod -R 777 $myhome/repos/VirtualRadarTracker/logs
chown -R nobody:nogroup $myhome/repos/VirtualRadarTracker/logs
setfacl -d -m user:nobody:rw $myhome/repos/VirtualRadarTracker/logs

echo -e '#!/usr/bin/env pwsh' | sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/vrtMilitary.ps1
echo -e $myhome'/repos/VirtualRadarTracker/vrt.ps1 military' | sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/vrtMilitary.ps1

echo -e '#!/usr/bin/env pwsh' | sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/vrtInteresting.ps1
echo -e $myhome'/repos/VirtualRadarTracker/vrt.ps1 interesting' | sudo tee --append /opt/VirtualRadarTracker/ServiceStarters/vrtInteresting.ps1

chmod +x /opt/VirtualRadarTracker/ServiceStarters/vrtMilitary.ps1
chmod +x /opt/VirtualRadarTracker/ServiceStarters/vrtInteresting.ps1


echo -e "[Service]\nExecStart=/opt/VirtualRadarTracker/ServiceStarters/vrtMilitary.ps1\n[Install]\nWantedBy=default.target" | sudo tee --append /etc/systemd/system/vrtMilitary.service
echo -e "[Service]\nExecStart=/opt/VirtualRadarTracker/ServiceStarters/vrtInteresting.ps1\n[Install]\nWantedBy=default.target" | sudo tee --append /etc/systemd/system/vrtInteresting.service
systemctl enable vrtMilitary.service
systemctl enable vrtInteresting.service
systemctl daemon-reload

echo "----------------------------------"
echo "---- Install Script Finsished ----"
echo "----------------------------------"
echo "Update Your Config Files HERE (cd $myhome/repos/VirtualRadarTracker/Configs)"
echo "To start your services now run the following commands:"
echo "sudo systemctl start vrtMilitary"
echo "sudo systemctl start vrtInteresting"
exit