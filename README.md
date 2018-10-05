# VirtualRadarTracker
This a Powershell script to send notification to either Slack or Twitter, depending on which parameters within the configuration file.  
The script works with Powershell 6.1 on both Windows and Ubuntu/Pi



## Revisions
v2 - Refactored, removed hardcoded values and all configuration is now managed by a single file
v1 - First attempt at using PS and ADSBExchange, with hardcoded values


## User Guide
This script is designed to talk to the API service of a Virtual Radar instance, the script has been setup to use ADSBExchange.
I have created 5 functions within the script that can easily be tweaked depending on the requirements.


## Parameters
### The 1st parameter defines which configuration will be called when the script is run. Mandatory filed.
The SHORTNAME in the config file is the value that is looked up with your config file for processing.



## Other Files
configs/configs.csv
This file define all the configuration details for the call to your VirtualRadar Service

## config.csv
SHORTNAME,This is what is called as a parameter
SLACKCHANNEL,Name of the slack channel (need to include the #)
ADSBAPIQUERY,The VR API query
PSEXCLUDEQUERY,Exclude entries returned from the query. (Need to include {})
FREQUENCY,How oftent the script will run
SENDSLACK,Set this to TRUE if you want to send your alerts
SENDTWITTER,Set this to TRUE if you want to send your alerts	
REMOTEIGNORELOCATION,The Onedrive remote location for your ignore files
SLACKURL,Slack API URL
LAT,Latitude (not currently used)
LONG,Longitude (not currently used)	
RANGE,Range for the API called (not currently used)
TWITTERCOSUMBERKEY,	Your Twitter details
TWITTERCONSUMBERSECRET,	Your Twitter details
TWITTERTOKEN,Your Twitter details
TWITTERTOKENSECRET,	Your Twitter details
POLLPERIOD,Your Twitter details
CACHECLEANUP,Your Twitter details

## Examples
### Windows Examples
.\vrt.ps1 military


### Linux Examples
./vrt.ps1 military & (This will start the process as a background job)
 

## Installing on Linux

### Prereqs
Install PowerShell 6.x and create the Symbolic Link as detailed here  
https://docs.microsoft.com/en-gb/powershell/scripting/setup/installing-powershell-core-on-linux?view=powershell-6#raspbian  
sudo apt install acl

### One line install script
```
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/thenecroscope/VirtualRadarTracker/master/installscript.sh)"
```


### Uninstalling on Linux
```
sudo bash -c "$(wget -O - https://raw.githubusercontent.com/thenecroscope/VirtualRadarTracker/master/uninstallscript.sh)"
````
* NB: Uninstalling will delete your configuration files!


## Setting Up Slack ##
* Create an account with Slack
* Go to https://gajek.slack.com/apps/manage/custom-integrations
* Add a custom webhook
* Make a note of your "Webhook URL" i.e. "https://hooks.slack.com/services/XXXXXXXX/XXXXXXXXX/XXXXXXXXXXXXXXXX"
* Paste your code into Security/Slack.csv i.e. "XXXXXXXX/XXXXXXXXX/XXXXXXXXXXXXXXXX"
* Restart the app/service


## Setting Up Remote Onedrive Ignore Files
* Create a text file on your Onedrive account
* Create an embded link within Onedrive from the file that you have just created (file name does not matter as the link is the important part
* Paste the embedded link into Security/IgnorePlanesURL.csv e.g.

```
filter, sourceurl
emergency,https://onedrive.live.com/download?cid=XXXXXXXXXXXXXXXx&resid=XXXXXXXXXXXXXXX%XXXXXXXXXXX&authkey=XXXXXXXX
military,https://onedrive.live.com/download?cid=XXXXXXXXXXXXXXXx&resid=XXXXXXXXXXXXXXX%XXXXXXXXXXX&authkey=XXXXXXXX
```

* remember to change the word embeded to download (see above) otherwise the file will not work
* The file will overwrite your local ignore files every x minutes (depending what has been defined within the script)
* You will need to have the "Remote" parameter set (parameter 3)


## Updating to the latest version
* Simply run ```git update``` from the folder were you installed the application