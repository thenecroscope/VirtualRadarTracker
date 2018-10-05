# VirtualRadarTracker
This a Powershell script to send notification to either Slack or Twitter, depending on which parameters are supplied.  
The script works with Powershell 6.1 on both Windows and Ubuntu/Pi



## Revisions

* Changed the ignore files to ignore both a Type of aircraft and also now a specific ICAO value
* Created un/install script for Pi 
* Bug fixes for not reading external file correctly
* Added a method to update the ignored plane list from a URL. The URL is then read in occasionally to update the local ignore list. This allows updating the ignore list from my phone when I'm not near a PC.
* Updated README to include 1st draft script to install as a service on Linux
* Corrected minor bug where first loop would not pick up any values. Made some changes to enable working on Ubuntu (tested on 18.04/Powershell Core)
* Bug fixes and updating documentation
* Initial Commit of PS Flight Tracker


## User Guide
This script is designed to talk to the API service of a Virtual Radar instance, the script has been setup to use ADSBExchange.
I have created 5 functions within the script that can easily be tweaked depending on the requirements.


## Parameters
### The 1st parameter defines which function will be called within the script. Options are as follows:

* emergency (looks for any flights with ($_.Sqk -eq 7500 -or $_.Sqk -eq 7700 -or $_.help -eq $TRUE ) within the British Isles
* interesting (looks for flights that have been set as interesting  within the British Isles.
* local (looks for local flights only. Up to 6km range from the point that has been defined MyLocation.csv file)
* worldwar (Looks for spitfires, hurricanes and Lancasters within the British Isles)
* military (Looks for any flights that have been clasified as military within the British Isles)


### The 2nd Parameter defines which communication channel to use, options are:
* Slack (Will send all notifications to Slack. The channels names are the same as the 1st parameter options.
* Twitter (Will send all notifications to Twitter)
* [Not stated] (This will only log all the flights found to a csv file)

### The 3rd Parameter if set, will download your ignore files from a remote cloud location
* Remote  
Leaving this blank will not download any files


## Other Files
* MyLocation.csv (A simple text file that has your Long and Lat details. Only used for the local parameter)
* Slack.csv (A simple text file where to store your Slack API channel details)
* Twitter.csv ((A simple text file where to store your Twitter API channel details)
* IgnorePlanesURL.csv (A simple text file to store your URLs to download ignore files)

## Examples
### Windows Examples
.\AircraftAlerts.ps1 military Slack
.\AircraftAlerts.ps1 local Twitter
.\AircraftAlerts.ps1 emergency


### Linux Examples
./AircraftAlerts.ps1 military Slack & (This will start the process as a background job)
 

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