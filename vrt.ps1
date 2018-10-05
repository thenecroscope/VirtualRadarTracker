Param(
    [parameter(Mandatory = $true, ValueFromPipeline = $true)] $PlaneFilter
)

function Parameters($findShortName) {
    #Function to return all the parameters from config file
    # Read in values from csv configuration file ################
    $configs = Import-CSV $configsPath/configs.csv
    $findArrayIndex = [array]::IndexOf($configs.SHORTNAME, $findShortName)
                                    
    if ($findArrayIndex -eq -1) {
        write-host "Failed To Find A Valid Entry In Your Config File..." -ForegroundColor Red
        $params = "ERROR"
    }
    else {
        $params = $configs[$findArrayIndex]
    }
    return $params
}


function SendToTwitter($aircraftsToSend, $params) {
    [Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
    [Reflection.Assembly]::LoadWithPartialName("System.Net") | Out-Null

    ForEach ($aircraft in $aircraftsToSend) {  
        # Define Message
        $linkToSend_Photo = "http://www.airport-data.com/aircraft/" + $aircraft.REG
        $aircraft_Model = ($aircraft).MDL
        $imageToSearch = $aircraft_Model -replace (" ", "+")
        $linkToSend_Bing = "https://www.bing.com/images/search?q=$ImageToSearch"
        $aircraft_Model2 = ($aircraft).MDL
        $aircraft_Operator = ($aircraft).Op
        $aircraft_Operator = $aircraft_Operator -replace (" ", "%20")
        $aircraft_Model_Map = $aircraft_Model2 -replace (" ", "%20")
        $aircraft_Inrequest_Map = $aircraft.ICAO
        $lat = $aircraft.LAT
        $long = $aircraft.LONG
        $linkToSend_Maps = "http://www.bing.com/maps/?v=2&cp=$lat~$long&lvl=10&dir=0&sty=r&sp=point." + $lat + "_" + $long + "_" + $aircraft_InRequest_Map 
        
        $oauth_consumer_key = $params.TWITTERCOSUMBERKEY
        $oauth_consumer_secret = $params.TWITTERCONSUMBERSECRET
        $oauth_token = $params.TWITTERTOKEN
        $oauth_token_secret = $params.TWITTERTOKENSECRET
        
        [string]$PropTweet = "Is Airborne:$aircraft_Model2 `n $linkToSend_Maps"    
        
        $status = [System.Uri]::EscapeDataString($PropTweet)
        $oauth_nonce = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))
        $ts = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null).ToUniversalTime()
        $oauth_timestamp = [System.Convert]::ToInt64($ts.TotalSeconds).ToString()
        
        $signature = "POST&"
        $signature += [System.Uri]::EscapeDataString("https://api.twitter.com/1.1/statuses/update.json") + "&";
        $signature += [System.Uri]::EscapeDataString("oauth_consumer_key=" + $oauth_consumer_key + "&");
        $signature += [System.Uri]::EscapeDataString("oauth_nonce=" + $oauth_nonce + "&"); 
        $signature += [System.Uri]::EscapeDataString("oauth_signature_method=HMAC-SHA1&");
        $signature += [System.Uri]::EscapeDataString("oauth_timestamp=" + $oauth_timestamp + "&");
        $signature += [System.Uri]::EscapeDataString("oauth_token=" + $oauth_token + "&");
        $signature += [System.Uri]::EscapeDataString("oauth_version=1.0&");
        $signature += [System.Uri]::EscapeDataString("status=" + $status);

        $signature_key = [System.Uri]::EscapeDataString($oauth_consumer_secret) + "&" + [System.Uri]::EscapeDataString($oauth_token_secret);
        
        $hmacsha1 = new-object System.Security.Cryptography.HMACSHA1;
        $hmacsha1.Key = [System.Text.Encoding]::ASCII.GetBytes($signature_key);
        $oauth_signature = [System.Convert]::ToBase64String($hmacsha1.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($signature)));
        
        $oauth_authorization = 'OAuth ';
        $oauth_authorization += 'oauth_consumer_key="' + [System.Uri]::EscapeDataString($oauth_consumer_key) + '",';
        $oauth_authorization += 'oauth_nonce="' + [System.Uri]::EscapeDataString($oauth_nonce) + '",';
        $oauth_authorization += 'oauth_signature="' + [System.Uri]::EscapeDataString($oauth_signature) + '",';
        $oauth_authorization += 'oauth_signature_method="HMAC-SHA1",'
        $oauth_authorization += 'oauth_timestamp="' + [System.Uri]::EscapeDataString($oauth_timestamp) + '",'
        $oauth_authorization += 'oauth_token="' + [System.Uri]::EscapeDataString($oauth_token) + '",';
        $oauth_authorization += 'oauth_version="1.0"';
        
        $post_body = [System.Text.Encoding]::ASCII.GetBytes("status=" + $status); 
        [System.Net.HttpWebRequest] $request = [System.Net.WebRequest]::Create("https://api.twitter.com/1.1/statuses/update.json");
        $request.Method = "POST";
        $request.Headers.Add("Authorization", $oauth_authorization);
        $request.ContentType = "application/x-www-form-urlencoded";
        
        
        try {
            $body = $request.GetRequestStream();
        }
        
        catch {
            # Dig into the exception to get the Response details.
            # Note that value__ is not a typo.
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        }
        
        $body.write($post_body, 0, $post_body.length);
        $body.flush();
        $body.close();
        $response = $request.GetResponse();
        $response.Close()
    }
}


function SendToSlack($action, $params, $textToSend, $aircraftsToSend) {
    #Function to Send requests to Slack  
    If ($action -eq "StartUp") {
        try {
            $payload = @{"channel" = $params.SLACKCHANNEL; "icon_emoji" = ":small_airplane:"; "text" = $textToSend}
            $slackResult = Invoke-WebRequest -Body (ConvertTo-Json -Compress -InputObject $payload) -Method Post -Uri $params.SLACKURL 
        }
            
        Catch {
            Write-Host "Error Response From ADSB Exchange"
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        }
        return $slackResult
    }
    ElseIf ($action -eq "UpdateIgnoreList") {
        try {
            $payload = @{"channel" = $params.SLACKCHANNEL; "icon_emoji" = ":small_airplane:"; "text" = $textToSend}
            $slackResult = Invoke-WebRequest -Body (ConvertTo-Json -Compress -InputObject $payload) -Method Post -Uri $params.SLACKURL 
        }
            
        Catch {
            Write-Host "Error Response From ADSB Exchange"
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        }
        return $slackResult
    }
    ElseIf ($action -eq "AircraftsToSend") {    
        ForEach ($aircraft in $aircraftsToSend) {  
            # Define text to send to Slack
            $LinkToSend_OS = "<https://opensky-network.org/network/explorer?icao24=" + $ADDAIRCRAFT.ICAO + "|OS>"
            $LinkToSend_FR = "<https://www.flightradar24.com/" + $ADDAIRCRAFT.CALL + "|FR>"
            $LinkToSend_FA = "<https://flightaware.com/live/flight/" + $ADDAIRCRAFT.CALL + "|FA>"
            $LinkToSend_RB = "<https://www.radarbox24.com/flight/" + $ADDAIRCRAFT.CALL + "|RB>"
            $LinkToSend_PF = "<https://planefinder.net/flight/" + $ADDAIRCRAFT.CALL + "|PF>"
            #$LinkToSend_Maps  = "https://maps.google.com/?q=$lat,$long&ll=$lat,$long&z=12"

            $lat = ($aircraft).Lat
            $long = ($aircraft).Long
            $aircraft_MODEL = "*" + ($aircraft).MDL + "*"
            $aircraft_TYPE = "*" + ($aircraft).TYPE + "*"
            $aircraft_ICAO = "*" + ($aircraft).ICAO + "*"
            $aircraft_ICAO2 = ($aircraft).ICAO
            $aircraft_REG = "*" + ($aircraft).REG + "*"
            $aircraft_REG2 = ($aircraft).REG
            $ImageToSearch = $aircraft_MODEL -replace (" ", "+")
            $LinkToSend_Bing = "<https://www.bing.com/images/search?q=$ImageToSearch|Bing Images>"
            $aircraft_MODEL2 = ($aircraft).MDL
            $aircraft_OPERATOR = ($aircraft).Op
            $aircraft_OPERATOR = $aircraft_OPERATOR -replace (" ", "%20")
            $aircraft_OPERATOR2 = ($aircraft).Op
            $aircraft_OPERATOR2 = "*" + $aircraft_OPERATOR2 + "*"
            $aircraft_MODEL_MAP = $aircraft_MODEL2 -replace (" ", "%20")
            $aircraft_INREQUEST_MAP = $aircraft.ICAO
            $LinkToSend_Maps = "<http://www.bing.com/maps/?v=2&cp=$lat~$long&lvl=10&dir=0&sty=r&sp=point." + $lat + "_" + $long + "_" + $aircraft_MODEL_MAP + $aircraft_OPERATOR + "_" + $aircraft_INREQUEST_MAP + "|Bing Maps>"
            $FlightHistory = "<https://flight-data.adsbexchange.com/activity?inputSelect=icao&icao=" + $aircraft_ICAO2 + "|Logs>"
            $MYVIRTUALRADAR = "<http://vr1.westeurope.cloudapp.azure.com/virtualradar/desktop.html?icao=" + $aircraft_ICAO2 + "|MYVR>"
        
            #Grab a thumbnail
            try {
                $PictureRequest = Invoke-RestMethod "http://www.airport-data.com/api/ac_thumb.json?m=$aircraft_ICAO2&n=1"
            }
        
            catch {
                Write-Host "Error Response From airport-data.com (Picture Generator)"
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
            }
        
            If ($PictureRequest.Data.Count -eq 1) {
                $ImageLink = "<" + $PictureRequest.Data.Image + "|Airport-Data Image>"
                $FullLink = "<" + $PictureRequest.Data.Link + "|Airport-Data>" 
            }
            else {
                $PictureRequest = ""
                $ImageLink = ""
                $FullLink = ""
            }
                  
            $payload = @{"channel" = $params.SLACKCHANNEL; "icon_emoji" = ":small_airplane:"; "text" = "MODEL:$aircraft_MODEL`n OPERATOR:$aircraft_OPERATOR2 || TYPE:$aircraft_TYPE || ICAO:$aircraft_ICAO || REG:$aircraft_REG `n $ImageLink || $FullLink || $LinkToSend_Bing || $LinkToSend_Maps || $FlightHistory `n $MYVIRTUALRADAR || $LinkToSend_OS || $LinkToSend_FR || $LinkToSend_FA || $LinkToSend_RB || $LinkToSend_PF `n ---------------------------------------------------------"                                        
            }
        
            Invoke-WebRequest -Body (ConvertTo-Json -Compress -InputObject $payload) -Method Post -Uri $params.SLACKURL | Out-Null
        }       
    }
}


function UpdateLocalIgnoreFile {
    #Function to get a remote file if one exists and always overwrite on startup
    $fileName = $parameters.SHORTNAME + "_" + "ignorelist.csv"

    #1, Check to see if a remote file exists
    #2, Check to see if local file exists
    #3, If local file exists and it matches remote do not overwrite or update 

    #Check to see if remote file exists                           
    try {
        $remoteIgnoreListString = Invoke-RestMethod $parameters.REMOTEIGNORELOCATION
    }

    catch {
        Write-Host "Failed To Fetch Remote ignore list" -ForegroundColor Red
        Write-Host "Failed To Fetch Remote Ignore List or Find A Valid Format" -ForegroundColor Red
    }
    
    if (($remoteIgnoreListString -match "ValueType") -eq $true) {
        #Export the string to a temp file,import it as an object and delete temp file
        $tempFile = (Get-Date).ticks
        $remoteIgnoreListString | Out-File ./$tempfile
        $remoteIgnoreList = Import-Csv ./$tempfile
        Remove-Item ./$tempfile

        
        #Try and Import the existing local file
        try {
            $localIgnoreList = Import-Csv $LogsPath\$fileName 
        }
        catch {
            #local file does not exists, supress error if not exist
        }

        if ($localIgnoreList.count -eq $remoteIgnoreList.count) {
            #As the local count matches we will not export it
            return $remoteIgnoreList
        }
        else {
            #They do not match
            Write-Host " Updating Local Ignore List" -ForegroundColor Green
            $remoteIgnoreList | Export-Csv $LogsPath\$fileName -NoTypeInformation
            $slackResults = SendToSlack "UpdateIgnoreList" $parameters "*UPDATED IGNORE LIST: $ignoreListCount  ------*"
            return $remoteIgnoreList
        }
    }
    else {
        Write-Host "Failed To Fetch Remote Ignore List or Find A Valid Format" -ForegroundColor Red
        try {
            $IgnoreListObjects = Import-Csv $LogsPath\$fileName
        }
        catch {
            Write-Host " No Local Ignore File Exists" -ForegroundColor Magenta
        }
        return $IgnoreListObjects
    }
}
###############################


function SendRequestToVRS ($parameters, $IgnoreListObjects) {
    #ADSB Exchange
    $aircraftsToSendArray = @()
    $IgnoreListCount = $IgnoreListObjects.count
    Write-Host "---- Starting A New Request, Looking For $($parameters.SHORTNAME) Planes. Ignoring $IgnoreListCount ----" -ForegroundColor Green                
    $restAPI = $parameters.ADSBAPIQUERY
    
    try {
        [PSCustomObject[]]$adsbRequest = Invoke-RestMethod $RESTAPI
        $psExcludeQuery = '$adsbRequest.acList | Where-Object ' + $($parameters.PSEXCLUDEQUERY)
        [PSCustomObject[]]$aircraftObjects = Invoke-Expression $psExcludeQuery
    }

    catch {
        Write-Host "Error Response From ADSB Exchange"
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        Continue
    }
     
    If (($aircraftObjects).count -ge 1) {
        ForEach ($aircraftInRequest in $aircraftObjects) {
            If ($aircraftInrequest.Mdl -eq "Miscoded Hex" -or $aircraftInRequest.Mdl -eq "Misocded Hex") {
                #Exclude these entries   
            }
            else {
                If ($global:aircraftArray.ICAO -contains $aircraftInRequest.Icao) {         
                    $findRowInArray = [array]::IndexOf($global:aircraftArray.ICAO, $aircraftInRequest.Icao)
                    $dateNow = Get-Date
                    $global:aircraftArray[$findRowInArray].Timeadded = $DateNow
                    Write-Host "  Found:" $aircraftInRequest.MDL"- Updated Time Last Seen " "-" $aircraftInRequest.REG"-" $aircraftInRequest.ICAO -ForegroundColor Magenta
                } 
            
                else {
                    Write-Host " New Aircraft:" $aircraftInRequest.MDL "-" $aircraftInRequest.REG "-" $aircraftInRequest.ICAO  "- Sending Alert (If Enabled)" -ForegroundColor Yellow
                    $dateNow = Get-Date           

                    $addAircraft = New-Object -TypeName PSObject -Property @{
                        Alt          = [int]$aircraftInRequest.Alt           # NumberYesThe altitude in feet at standard pressure.
                        AltT         = [int]$aircraftInRequest.AltT          # NumberYesThe type of altitude transmitted by the aircraft: 0 = standard pressure altitude, 1 = indicated altitude (above mean sea level). Default to standard pressure altitude until told otherwise.
                        Bad          = [bool]$aircraftInRequest.Bad          # BooleanYesTrue if the ICAO is known to be invalid. This information comes from the local BaseStation.sqb database.
                        Brng         = [int]$aircraftInRequest.Brng          # NumberYesThe bearing from the browser to the aircraft clockwise from 0° north.
                        Call         = [string]$aircraftInRequest.Call       # StringYesThe callsign.
                        CallSus      = [bool]$aircraftInRequest.CallSus      # BooleanYesTrue if the callsign may not be correct.
                        CMsgs        = [int]$aircraftInRequest.CMsgs         # NumberYesThe count of messages received for the aircraft.
                        CNum         = [string]$aircraftInRequest.CNum       # StringYesThe aircraft's construction or serial number.
                        Cos          = [array]$aircraftInRequest.Cos         # ArrayYesShort trails - see note 1.
                        Cot          = [array]$aircraftInRequest.Cot         # ArrayYesFull trails - see note 2.
                        Cou          = [string]$aircraftInRequest.Cou        # StringYesThe country that the aircraft is registered to.
                        Dst          = [int]$aircraftInRequest.Dst           # NumberYesThe distance to the aircraft in kilometres.
                        Engines      = [int]$aircraftInRequest.Engines       # StringYesThe number of engines the aircraft has. Usually '1', '2' etc. but can also be a string - see ICAO documentation.
                        EngMount     = [int]$aircraftInRequest.EngMount      # EnumYesThe placement of engines on the aircraft - see enums.js for values.
                        EngType      = [int]$aircraftInRequest.EngType       # EnumYesThe type of engine the aircraft uses - see enums.js for values.
                        FlightsCount = [int]$aircraftInRequest.FlightsCount  # NumberYesThe number of Flights records the aircraft has in the database.
                        From         = [string]$aircraftInRequest.From       # StringYesThe code and name of the departure airport.
                        Fseen        = [datetime]$aircraftInRequest.Fseen    # Custom field, when script first saw aircraft
                        GAlt         = [int]$aircraftInRequest.GAlt          # NumberYesThe altitude adjusted for local air pressure, should be roughly the height above mean sea level.
                        Gnd          = [bool]$aircraftInRequest.Gnd          # BooleanYesTrue if the aircraft is on the ground.
                        HasPic       = [bool]$aircraftInRequest.HasPic       # BooleanYesTrue if the aircraft has a picture associated with it.
                        HasSig       = [bool]$aircraftInRequest.HasSig       # BooleanYesTrue if the aircraft has a signal level associated with it.
                        Help         = [bool]$aircraftInRequest.Help         # BooleanYesTrue if the aircraft is transmitting an emergency squawk.
                        Icao         = [string]$aircraftInRequest.Icao       # StringYesThe ICAO of the aircraft.
                        Id           = [int]$aircraftInRequest.Id            # NumberNoThe unique identifier of the aircraft.
                        InHg         = [int]$aircraftInRequest.InHg          # NumberYesThe air pressure in inches of mercury that was used to calculate the AMSL altitude from the standard pressure altitude.
                        Interested   = [bool]$aircraftInRequest.Interested   # BooleanYesTrue if the aircraft is flagged as interesting in the BaseStation.sqb local database.
                        IsTisb       = [bool]$aircraftInRequest.IsTisb       # BooleanYesTrue if the last message received for the aircraft was from a TIS-B source.
                        Lat          = [decimal]$aircraftInRequest.Lat       # FloatYesThe aircraft's latitude over the ground.
                        Long         = [decimal]$aircraftInRequest.Long      # FloatYesThe aircraft's longitude over the ground.
                        Man          = [string]$aircraftInRequest.Man        # StringYesThe manufacturer's name.
                        Mdl          = [string]$aircraftInRequest.Mdl        # StringYesA description of the aircraft's model. Usually also includes the manufacturer's name.
                        Mil          = [bool]$aircraftInRequest.Mil          # BooleanYesTrue if the aircraft appears to be operated by the military.
                        Mlat         = [bool]$aircraftInRequest.Mlat         # BooleanYesTrue if the latitude and longitude appear to have been calculated by an MLAT server and were not transmitted by the aircraft.
                        Op           = [string]$aircraftInRequest.Op         # StringYesThe name of the aircraft's operator.
                        OpCode       = [string]$aircraftInRequest.OpCode     # StringYesThe operator's ICAO code.
                        OpIcao       = [string]$aircraftInRequest.OpIcao     # 
                        PicX         = [int]$aircraftInRequest.Picx          # NumberYesThe width of the picture in pixels.
                        PicY         = [int]$aircraftInRequest.Picy          # NumberYesThe height of the picture in pixels.
                        PosStale     = [bool]$aircraftInRequest.PosStale     # BooleanYesTrue if the last position update is older than the display timeout value - usually only seen on MLAT aircraft in merged feeds.
                        PosTime      = [long]$aircraftInRequest.PosTime      # NumberYesThe time (at UTC in JavaScript ticks) that the position was last reported by the aircraft.
                        Rcvr         = [int]$aircraftInRequest.Rcvr          # NumberNoThe ID of the feed that last supplied information about the aircraft. Will be different to srcFeed if the source is a merged feed.
                        Reg          = [string]$aircraftInRequest.Reg        # StringYesThe registration.
                        ResetTrail   = [bool]$aircraftInRequest.ResetTrail   # BooleanYesTrue if the entire trail has been sent and the JavaScript should discard any existing trail history it's built up for the aircraft.
                        Sat          = [bool]$aircraftInRequest.Sat          # BooleanYesTrue if the aircraft has been seen on a SatCom ACARS feed (e.g. a JAERO feed).
                        Sig          = [int]$aircraftInRequest.Sig           # NumberYesThe signal level for the last message received from the aircraft, as reported by the receiver. Not all receivers pass signal levels. The value's units are receiver-dependent.
                        Source       = [string]$($PlaneFilter)                # Custom field detailing which API request to run
                        Spd          = [int]$aircraftInRequest.Spd           # NumberYesThe ground speed in knots.
                        SpdTyp       = [int]$aircraftInRequest.SpdTyp        # NumberYesThe type of speed that Spd represents. Only used with raw feeds. 0/missing = ground speed, 1 = ground speed reversing, 2 = indicated air speed, 3 = true air speed.
                        Species      = [int]$aircraftInRequest.Species       # EnumYesThe species of the aircraft (helicopter, jet etc.) - see enums.js for values.
                        Sqk          = [int]$aircraftInRequest.Sqk           # NumberYesThe squawk as a decimal number (e.g. a squawk of 7654 is passed as 7654, not 4012).
                        Stops        = [array]$aircraftInRequest.Stops       # String[]YesAn array of strings, each being a stopover on the route.
                        Tag          = [string]$aircraftInRequest.Tag        # StringYesThe user tag found for the aircraft in the BaseStation.sqb local database.
                        TAlt         = [int]$aircraftInRequest.TAlt          # NumberYesThe target altitude, in feet, set on the autopilot / FMS etc.
                        TimeAdded    = [datetime]$DATENOW                     # 
                        Tisb         = [bool]$aircraftInRequest.Tisb         # 
                        To           = [string]$aircraftInRequest.To         # StringYesThe code and name of the arrival airport.
                        Trak         = [int]$aircraftInRequest.Trak          # NumberYesAircraft's track angle across the ground clockwise from 0° north.
                        TrkH         = [bool]$aircraftInRequest.TrkH         # BooleanYesTrue if Trak is the aircraft's heading, false if it's the ground track. Default to ground track until told otherwise.
                        Trt          = [int]$aircraftInRequest.Trt           # NumberYesTransponder type - 0=Unknown, 1=Mode-S, 2=ADS-B (unknown version), 3=ADS-B 0, 4=ADS-B 1, 5=ADS-B 2.
                        TSecs        = [int]$aircraftInRequest.TSecs         # NumberNoThe number of seconds that the aircraft has been tracked for.
                        TT           = [string]$aircraftInRequest.TT         # StringYesTrail type - empty for plain trails, 'a' for trails that include altitude, 's' for trails that include speed.
                        TTrk         = [int]$aircraftInRequest.TTrk          # NumberYesThe track or heading currently set on the aircraft's autopilot or FMS.
                        Type         = [string]$aircraftInRequest.Type       # StringYesThe aircraft model's ICAO type code.
                        Vsi          = [int]$aircraftInRequest.Vsi           # NumberYesVertical speed in feet per minute.
                        VsiT         = [int]$aircraftInRequest.VsiT          # NumberYes0 = vertical speed is barometric, 1 = vertical speed is geometric. Default to barometric until told otherwise.
                        WTC          = [int]$aircraftInRequest.WTC           # EnumYesThe wake turbulence category of the aircraft - see enums.js for values.
                        Year         = [int]$aircraftInRequest.Year          # StringYesThe year that the aircraft was manufactured.
                    } 
                    $datestring = (Get-Date).ToString("yyyy-MM-dd")
                    $global:aircraftArray += $addAircraft
                    $addAircraft | Export-Csv -NoTypeInformation -Append $LogsPath/$($parameters.SHORTNAME)"_history-$datestring.csv" #Generate a list of aircraft seen

                    $Notify = ""
                    #Now compile a list of aircraft that we should send
                    ForEach ($IgnorePlane in $IgnoreListObjects) {
                        If ( ($addAircraft.TYPE -eq $IgnorePlane.Value) -or ($addAircraft.ICAO -eq $IgnorePlane.Value) ) {
                            Write-Host "  Ignoring: $($addAircraft.MDL) Found In Local Ignore File Not Sending Notification" -ForegroundColor DarkYellow #  For Model:"$($addAircraft.MDL) 
                            $Notify = "DoNotSend"
                            Break
                        }
                    }
                    If ($Notify -eq "DoNotSend") {
                    }
                    else {
                        $aircraftsToSendArray += $addAircraft 
                    }                        
                }
            }                 
        }
    }
    return $aircraftsToSendArray
}



function ClearAirCraftSeenCache ($Duration) {
    If (($global:aircraftArray).count -ge 1) {
        Write-Host " Cleaning out stale aircraft from array"
        ForEach ($aircraftArray_Item in $global:aircraftArray) {
            [datetime]$dateNow = Get-Date
            [datetime]$lastSeen = ($aircraftArray_Item).TimeAdded

            If (($dateNow - $LastSeen).Minutes -ge $Duration) {
                [PSCustomObject[]]$global:aircraftArray = $global:aircraftArray | Where-Object {$_.Icao -ne ($aircraftArray_Item).Icao} 
                Write-Host " Stale Aircraft Removed: " ($aircraftArray_Item).ICAO ($aircraftArray_Item).TimeAdded
            }
        }
    }
}###Needs testing (need to define time variable (i.e. 20)


# Setup environment/variables ####################################
Clear-Host
Write-Host "Starting To Locate Aircraft Now..." $(Get-Date)
$parameters = ""
$global:aircraftArray = @()
$workingDir = $PSCommandPath | Split-Path -Parent
$workingDir = $workingDir -replace ("\\", "/") #for linux
$LogsPath = $workingDir + "/logs"
$configsPath = $workingDir + "/configs"
$cleanUpTimer = $false
$readIgnoreFileTimer = $false 
##################################################################

[PSCustomObject[]]$parameters = Parameters $PlaneFilter
if ($parameters -eq "ERROR") {exit}
$ignoreListObjects = UpdateLocalIgnoreFile; $ignoreListCount = $ignoreListObjects.count
$slackResults = SendToSlack "StartUp" $parameters "*--------- Starting Up Monitoring, Ignore List: $($ignoreListObjects.count) ---------*"

# Main part of script ############################################
# Setup Environment for the for loop to process
While ($true) {
    if ($cleanUpTimer.IsRunning -eq $false -or $cleanUpTimer -eq $false ) {$cleanUpTimer = [system.diagnostics.stopwatch]::StartNew()}
    if ($readIgnoreFileTimer.IsRunning -eq $false -or $readIgnoreFileTimer -eq $false ) {$readIgnoreFileTimer = [system.diagnostics.stopwatch]::StartNew()}

    $aircraftsToSendArray = SendRequestToVRS $parameters $IgnoreListObjects
    if ($parameters.SENDSLACK -eq "TRUE") {SendToSlack "AircraftsToSend" $parameters  "" $aircraftsToSendArray}
    if ($parameters.SENDTWITTER -eq "TRUE") {SendToTwitter $aircraftsToSendArray $parameters}
    [int]$cacheCleanup = $($parameters.CACHECLEANUP)
    if ($cleanUpTimer.Elapsed.Minutes -ge $cacheCleanup) {ClearAirCraftSeenCache $cacheCleanup; $cleanUpTimer.Reset()}
    if ($readIgnoreFileTimer.Elapsed.Minutes -ge 5) {$ignoreListObjects = UpdateLocalIgnoreFile; $ignoreListCount = $ignoreListObjects.count; $readIgnoreFileTimer.Reset()}
    Write-Host "Pausing For $($parameters.POLLPERIOD) Seconds Before Starting Next Iteration..."
    [int]$pollPeriod = $($parameters.POLLPERIOD)
    Start-Sleep $pollPeriod
    Write-Host " "
}