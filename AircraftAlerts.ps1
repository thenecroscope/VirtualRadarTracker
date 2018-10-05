Param(
    [parameter(Mandatory = $true,  ValueFromPipeline = $true)][ValidateSet('interesting','military','worldwar','local','emergency')] $PlaneFilter,
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]$CommsChannel,
    [parameter(Mandatory = $true, ValueFromPipeline = $true)]$SourceFileLocation
)

Function WatchAircraft ($PlaneFilter, $CommsChannel, $SourceFileLocation) {

    $IgnorePlaneListPath = "$env:temp" + "/VirtualRadarTracker/ignorelist_" + $PlaneFilter + ".csv"
    $IgnorePlaneListPath = $IgnorePlaneListPath -replace ("\\","/")
    if (!(Test-Path $IgnorePlaneListPath)) {
        New-Item -path $IgnorePlaneListPath | Out-Null
    }
    else {
        $IgnorePlaneLists = Import-Csv $IgnorePlaneListPath
    }

    $CleanUpCounter = 1
    $AIRCRAFTARRAY = @()

    While ($true) {
        If ($PlaneFilter -eq "worldwar") {
            $RESTAPI = "https://public-api.adsbexchange.com/VirtualRadar/AircraftList.json"
            Write-Host "---- Starting a new request, looking for $($PlaneFilter) Planes. Ignoring $($IgnorePlaneLists.count) ----" -ForegroundColor Green                
                
            try {
                [PSCustomObject[]]$ADSB_REQUEST = Invoke-RestMethod $RESTAPI
                [PSCustomObject[]]$AIRCRAFTOBJECTS = $ADSB_REQUEST.acList | Where-Object {($_.Type -eq "HURI" -or $_.Type -eq "SPIT" -or $_.Type -eq "LANC") -AND ($_.LAT -ne 0 -or $_.LONG -ne 0) }            
            }
            catch {
                # Dig into the exception to get the Response details.
                # Note that value__ is not a typo.
                Write-Host "Error Response From ADSB Exchange"
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
                Continue
            }            
            [int]$SleepBetweenLoops = 60
            [int]$LoopCounter = 20
            [int]$CleanUpTime = 20
        }
        elseif ($PlaneFilter -eq "emergency") {
            $RESTAPI = "https://public-api.adsbexchange.com/VirtualRadar/AircraftList.json"
            Write-Host "---- Starting a new Request, looking for emergency Sqk 7500 and 7700. Ignoring $($IgnorePlaneLists.count) ----" -ForegroundColor Green
            
            try {
                [PSCustomObject[]]$ADSB_REQUEST = Invoke-RestMethod $RESTAPI
                [PSCustomObject[]]$AIRCRAFTOBJECTS = $ADSB_REQUEST.acList | Where-Object {($_.Sqk -eq 7500 -or $_.Sqk -eq 7700 -or $_.help -eq $TRUE ) -AND ($_.LAT -ne 0 -or $_.LONG -ne 0)}         
            }
            catch {
                # Dig into the exception to get the Response details.
                # Note that value__ is not a typo.
                Write-Host "Error Response From ADSB Exchange"
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
                Continue
            }            
            [int]$SleepBetweenLoops = 60
            [int]$LoopCounter = 20
            [int]$CleanUpTime = 20
        }
        elseif ($PlaneFilter -eq "military") {
            $RESTAPI = "https://public-api.adsbexchange.com/VirtualRadar/AircraftList.json?fMilQ=1&lat=54.23955&lng=-4.39453&fDstL=0&fDstU=600"
            Write-Host "---- Starting a new request, looking for $($PlaneFilter) Planes. Ignoring $($IgnorePlaneLists.count) ----" -ForegroundColor Green                
            
            try {
                [PSCustomObject[]]$ADSB_REQUEST = Invoke-RestMethod $RESTAPI
                [PSCustomObject[]]$AIRCRAFTOBJECTS = $ADSB_REQUEST.acList | Where-Object {($_.LAT -ne 0 -AND $_.LONG -ne 0) -AND ($_.Type -ne "HURI" -or $_.Type -ne "SPIT" -or $_.Type -ne "LANC")}            
            }
            catch {
                # Dig into the exception to get the Response details.
                # Note that value__ is not a typo.
                Write-Host "Error Response From ADSB Exchange"
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
                Continue
            }            
            [int]$SleepBetweenLoops = 60
            [int]$LoopCounter = 20
            [int]$CleanUpTime = 20
        } 
        elseif ($PlaneFilter -eq "interesting") {
            $RESTAPI = "https://public-api.adsbexchange.com/VirtualRadar/AircraftList.json?fIntQ=1&lat=54.23955&lng=-4.39453&fDstL=0&fDstU=600"
            Write-Host "---- Starting a new request, looking for $($PlaneFilter) Planes. Ignoring $($IgnorePlaneLists.count) ----" -ForegroundColor Green
            
            try {
                [PSCustomObject[]]$ADSB_REQUEST = Invoke-RestMethod $RESTAPI
                [PSCustomObject[]]$AIRCRAFTOBJECTS = $ADSB_REQUEST.acList | Where-Object {$_.LAT -ne 0 -or $_.LONG -ne 0}            
            }
            catch {
                # Dig into the exception to get the Response details.
                # Note that value__ is not a typo.
                Write-Host "Error Response From ADSB Exchange"
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
                Continue
            }            
            [int]$SleepBetweenLoops = 60
            [int]$LoopCounter = 20
            [int]$CleanUpTime = 20
        } 
        elseif ($PlaneFilter -eq "local") {
            $RESTAPI = "https://public-api.adsbexchange.com/VirtualRadar/AircraftList.json?lat=$myLat&lng=$MyLng&fDstL=0&fDstU=6&fAltL=0&fAltU=2000"
            Write-Host "---- Starting a new request, looking for $($PlaneFilter) Planes. Ignoring $($IgnorePlaneLists.count) ----" -ForegroundColor Green                
            
            try {
                [PSCustomObject[]]$ADSB_REQUEST = Invoke-RestMethod $RESTAPI
                [PSCustomObject[]]$AIRCRAFTOBJECTS = $ADSB_REQUEST.acList | Where-Object {($_.LAT -ne 0 -or $_.LONG -ne 0)} 
            }
            catch {
                # Dig into the exception to get the Response details.
                # Note that value__ is not a typo.
                Write-Host "Error Response From ADSB Exchange"
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
                Continue
            } 
            [int]$SleepBetweenLoops = 5
            [int]$LoopCounter = 180
            [int]$CleanUpTime = 15
        }
        try {
            [PSCustomObject[]]$ADSB_REQUEST = Invoke-RestMethod $RESTAPI            
        }
        catch {
            # Dig into the exception to get the Response details.
            # Note that value__ is not a typo.
            Write-Host "Error Response From airport-data.com (Picture Generator)"
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
            Continue
        }            
    
        If (($AIRCRAFTOBJECTS).count -ge 1) {
            ForEach ($AIRCRAFT_INREQUEST in $AIRCRAFTOBJECTS) {
                If ($AIRCRAFT_INREQUEST.Mdl -eq "Miscoded Hex" -or $AIRCRAFT_INREQUEST.Mdl -eq "Misocded Hex") {
                    #Exclude these entries   
                }
                else {
                    If ($AIRCRAFTARRAY.ICAO -contains $AIRCRAFT_INREQUEST.Icao) {
            
                        $FINDROWINARRAY = [array]::IndexOf($AIRCRAFTARRAY.ICAO, $AIRCRAFT_INREQUEST.Icao)
                        $DATENOW = Get-Date
                        $AIRCRAFTARRAY[$FINDROWINARRAY].Timeadded = $DATENOW

                        Write-Host " Found:" $AIRCRAFT_INREQUEST.MDL"- Updated Time Last Seen " "-" $AIRCRAFT_INREQUEST.REG"-" $AIRCRAFT_INREQUEST.ICAO -ForegroundColor Yellow
                    } 
            
                    else {
                        Write-Host " Not Found:" $AIRCRAFT_INREQUEST.MDL "-" $AIRCRAFT_INREQUEST.REG "-" $AIRCRAFT_INREQUEST.ICAO  "- Sending Alert (If Enabled)" -ForegroundColor DarkYellow
                        $DATENOW = Get-Date           

                        $ADDAIRCRAFT = New-Object -TypeName PSObject -Property @{
                            Alt          = [int]$AIRCRAFT_INREQUEST.Alt           # NumberYesThe altitude in feet at standard pressure.
                            AltT         = [int]$AIRCRAFT_INREQUEST.AltT          # NumberYesThe type of altitude transmitted by the aircraft: 0 = standard pressure altitude, 1 = indicated altitude (above mean sea level). Default to standard pressure altitude until told otherwise.
                            Bad          = [bool]$AIRCRAFT_INREQUEST.Bad          # BooleanYesTrue if the ICAO is known to be invalid. This information comes from the local BaseStation.sqb database.
                            Brng         = [int]$AIRCRAFT_INREQUEST.Brng          # NumberYesThe bearing from the browser to the aircraft clockwise from 0° north.
                            Call         = [string]$AIRCRAFT_INREQUEST.Call       # StringYesThe callsign.
                            CallSus      = [bool]$AIRCRAFT_INREQUEST.CallSus      # BooleanYesTrue if the callsign may not be correct.
                            CMsgs        = [int]$AIRCRAFT_INREQUEST.CMsgs         # NumberYesThe count of messages received for the aircraft.
                            CNum         = [string]$AIRCRAFT_INREQUEST.CNum       # StringYesThe aircraft's construction or serial number.
                            Cos          = [array]$AIRCRAFT_INREQUEST.Cos         # ArrayYesShort trails - see note 1.
                            Cot          = [array]$AIRCRAFT_INREQUEST.Cot         # ArrayYesFull trails - see note 2.
                            Cou          = [string]$AIRCRAFT_INREQUEST.Cou        # StringYesThe country that the aircraft is registered to.
                            Dst          = [int]$AIRCRAFT_INREQUEST.Dst           # NumberYesThe distance to the aircraft in kilometres.
                            Engines      = [int]$AIRCRAFT_INREQUEST.Engines       # StringYesThe number of engines the aircraft has. Usually '1', '2' etc. but can also be a string - see ICAO documentation.
                            EngMount     = [int]$AIRCRAFT_INREQUEST.EngMount      # EnumYesThe placement of engines on the aircraft - see enums.js for values.
                            EngType      = [int]$AIRCRAFT_INREQUEST.EngType       # EnumYesThe type of engine the aircraft uses - see enums.js for values.
                            FlightsCount = [int]$AIRCRAFT_INREQUEST.FlightsCount  # NumberYesThe number of Flights records the aircraft has in the database.
                            From         = [string]$AIRCRAFT_INREQUEST.From       # StringYesThe code and name of the departure airport.
                            Fseen        = [datetime]$AIRCRAFT_INREQUEST.Fseen    # Custom field, when script first saw aircraft
                            GAlt         = [int]$AIRCRAFT_INREQUEST.GAlt          # NumberYesThe altitude adjusted for local air pressure, should be roughly the height above mean sea level.
                            Gnd          = [bool]$AIRCRAFT_INREQUEST.Gnd          # BooleanYesTrue if the aircraft is on the ground.
                            HasPic       = [bool]$AIRCRAFT_INREQUEST.HasPic       # BooleanYesTrue if the aircraft has a picture associated with it.
                            HasSig       = [bool]$AIRCRAFT_INREQUEST.HasSig       # BooleanYesTrue if the aircraft has a signal level associated with it.
                            Help         = [bool]$AIRCRAFT_INREQUEST.Help         # BooleanYesTrue if the aircraft is transmitting an emergency squawk.
                            Icao         = [string]$AIRCRAFT_INREQUEST.Icao       # StringYesThe ICAO of the aircraft.
                            Id           = [int]$AIRCRAFT_INREQUEST.Id            # NumberNoThe unique identifier of the aircraft.
                            InHg         = [int]$AIRCRAFT_INREQUEST.InHg          # NumberYesThe air pressure in inches of mercury that was used to calculate the AMSL altitude from the standard pressure altitude.
                            Interested   = [bool]$AIRCRAFT_INREQUEST.Interested   # BooleanYesTrue if the aircraft is flagged as interesting in the BaseStation.sqb local database.
                            IsTisb       = [bool]$AIRCRAFT_INREQUEST.IsTisb       # BooleanYesTrue if the last message received for the aircraft was from a TIS-B source.
                            Lat          = [decimal]$AIRCRAFT_INREQUEST.Lat       # FloatYesThe aircraft's latitude over the ground.
                            Long         = [decimal]$AIRCRAFT_INREQUEST.Long      # FloatYesThe aircraft's longitude over the ground.
                            Man          = [string]$AIRCRAFT_INREQUEST.Man        # StringYesThe manufacturer's name.
                            Mdl          = [string]$AIRCRAFT_INREQUEST.Mdl        # StringYesA description of the aircraft's model. Usually also includes the manufacturer's name.
                            Mil          = [bool]$AIRCRAFT_INREQUEST.Mil          # BooleanYesTrue if the aircraft appears to be operated by the military.
                            Mlat         = [bool]$AIRCRAFT_INREQUEST.Mlat         # BooleanYesTrue if the latitude and longitude appear to have been calculated by an MLAT server and were not transmitted by the aircraft.
                            Op           = [string]$AIRCRAFT_INREQUEST.Op         # StringYesThe name of the aircraft's operator.
                            OpCode       = [string]$AIRCRAFT_INREQUEST.OpCode     # StringYesThe operator's ICAO code.
                            OpIcao       = [string]$AIRCRAFT_INREQUEST.OpIcao     # 
                            PicX         = [int]$AIRCRAFT_INREQUEST.Picx          # NumberYesThe width of the picture in pixels.
                            PicY         = [int]$AIRCRAFT_INREQUEST.Picy          # NumberYesThe height of the picture in pixels.
                            PosStale     = [bool]$AIRCRAFT_INREQUEST.PosStale     # BooleanYesTrue if the last position update is older than the display timeout value - usually only seen on MLAT aircraft in merged feeds.
                            PosTime      = [long]$AIRCRAFT_INREQUEST.PosTime      # NumberYesThe time (at UTC in JavaScript ticks) that the position was last reported by the aircraft.
                            Rcvr         = [int]$AIRCRAFT_INREQUEST.Rcvr          # NumberNoThe ID of the feed that last supplied information about the aircraft. Will be different to srcFeed if the source is a merged feed.
                            Reg          = [string]$AIRCRAFT_INREQUEST.Reg        # StringYesThe registration.
                            ResetTrail   = [bool]$AIRCRAFT_INREQUEST.ResetTrail   # BooleanYesTrue if the entire trail has been sent and the JavaScript should discard any existing trail history it's built up for the aircraft.
                            Sat          = [bool]$AIRCRAFT_INREQUEST.Sat          # BooleanYesTrue if the aircraft has been seen on a SatCom ACARS feed (e.g. a JAERO feed).
                            Sig          = [int]$AIRCRAFT_INREQUEST.Sig           # NumberYesThe signal level for the last message received from the aircraft, as reported by the receiver. Not all receivers pass signal levels. The value's units are receiver-dependent.
                            Source       = [string]$($PlaneFilter)                # Custom field detailing which API request to run
                            Spd          = [int]$AIRCRAFT_INREQUEST.Spd           # NumberYesThe ground speed in knots.
                            SpdTyp       = [int]$AIRCRAFT_INREQUEST.SpdTyp        # NumberYesThe type of speed that Spd represents. Only used with raw feeds. 0/missing = ground speed, 1 = ground speed reversing, 2 = indicated air speed, 3 = true air speed.
                            Species      = [int]$AIRCRAFT_INREQUEST.Species       # EnumYesThe species of the aircraft (helicopter, jet etc.) - see enums.js for values.
                            Sqk          = [int]$AIRCRAFT_INREQUEST.Sqk           # NumberYesThe squawk as a decimal number (e.g. a squawk of 7654 is passed as 7654, not 4012).
                            Stops        = [array]$AIRCRAFT_INREQUEST.Stops       # String[]YesAn array of strings, each being a stopover on the route.
                            Tag          = [string]$AIRCRAFT_INREQUEST.Tag        # StringYesThe user tag found for the aircraft in the BaseStation.sqb local database.
                            TAlt         = [int]$AIRCRAFT_INREQUEST.TAlt          # NumberYesThe target altitude, in feet, set on the autopilot / FMS etc.
                            TimeAdded    = [datetime]$DATENOW                     # 
                            Tisb         = [bool]$AIRCRAFT_INREQUEST.Tisb         # 
                            To           = [string]$AIRCRAFT_INREQUEST.To         # StringYesThe code and name of the arrival airport.
                            Trak         = [int]$AIRCRAFT_INREQUEST.Trak          # NumberYesAircraft's track angle across the ground clockwise from 0° north.
                            TrkH         = [bool]$AIRCRAFT_INREQUEST.TrkH         # BooleanYesTrue if Trak is the aircraft's heading, false if it's the ground track. Default to ground track until told otherwise.
                            Trt          = [int]$AIRCRAFT_INREQUEST.Trt           # NumberYesTransponder type - 0=Unknown, 1=Mode-S, 2=ADS-B (unknown version), 3=ADS-B 0, 4=ADS-B 1, 5=ADS-B 2.
                            TSecs        = [int]$AIRCRAFT_INREQUEST.TSecs         # NumberNoThe number of seconds that the aircraft has been tracked for.
                            TT           = [string]$AIRCRAFT_INREQUEST.TT         # StringYesTrail type - empty for plain trails, 'a' for trails that include altitude, 's' for trails that include speed.
                            TTrk         = [int]$AIRCRAFT_INREQUEST.TTrk          # NumberYesThe track or heading currently set on the aircraft's autopilot or FMS.
                            Type         = [string]$AIRCRAFT_INREQUEST.Type       # StringYesThe aircraft model's ICAO type code.
                            Vsi          = [int]$AIRCRAFT_INREQUEST.Vsi           # NumberYesVertical speed in feet per minute.
                            VsiT         = [int]$AIRCRAFT_INREQUEST.VsiT          # NumberYes0 = vertical speed is barometric, 1 = vertical speed is geometric. Default to barometric until told otherwise.
                            WTC          = [int]$AIRCRAFT_INREQUEST.WTC           # EnumYesThe wake turbulence category of the aircraft - see enums.js for values.
                            Year         = [int]$AIRCRAFT_INREQUEST.Year          # StringYesThe year that the aircraft was manufactured.
                        } 

                        try {
                            $AIRCRAFTARRAY += $ADDAIRCRAFT
                        }
                        catch {
                            #Capture bad data
                            Write-host "FAILED TO ADD RECORD" $AIRCRAFT_INREQUEST -ForegroundColor Red
                            Continue
                        }
                       
                        $LinkToSend_OS = "<https://opensky-network.org/network/explorer?icao24=" + $ADDAIRCRAFT.ICAO+"|OS>"
                        $LinkToSend_FR = "<https://www.flightradar24.com/" + $ADDAIRCRAFT.CALL+"|FR>"
                        $LinkToSend_FA = "<https://flightaware.com/live/flight/" + $ADDAIRCRAFT.CALL+"|FA>"
                        $LinkToSend_RB = "<https://www.radarbox24.com/flight/" + $ADDAIRCRAFT.CALL+"|RB>"
                        $LinkToSend_PF = "<https://planefinder.net/flight/" + $ADDAIRCRAFT.CALL+"|PF>"
                        #$LinkToSend_Maps  = "https://maps.google.com/?q=$lat,$long&ll=$lat,$long&z=12"

                        $datestring = (Get-Date).ToString("yyyy-MM-dd")
                        
                        $ADDAIRCRAFT | Export-Csv -NoTypeInformation -Append $LogsPath
                        $Notify = ""

                        #If the Aircraft is in this list, ignore sending it as not interested. We will export it to a file for stats above though
                        ForEach ($IgnorePlane in $IgnorePlaneLists) {
                            If ( ($ADDAIRCRAFT.TYPE -eq $IgnorePlane.Type) -or ($ADDAIRCRAFT.ICAO -eq $IgnorePlane.ICAO) ) {
                                Write-Host "Not Sending Notification For Model:"$($ADDAIRCRAFT.MDL) -ForegroundColor Yellow
                                $Notify = "DoNotSend"
                                Break
                            }
                        }
                        If ($Notify -ne "DoNotSend") {
                            $lat = ($ADDAIRCRAFT).Lat
                            $long = ($ADDAIRCRAFT).Long
                            $AIRCRAFT_MODEL = "*" + ($ADDAIRCRAFT).MDL + "*"
                            $AIRCRAFT_TYPE = "*" + ($ADDAIRCRAFT).TYPE + "*"
                            $AIRCRAFT_ICAO = "*" + ($ADDAIRCRAFT).ICAO + "*"
                            $AIRCRAFT_ICAO2 = ($ADDAIRCRAFT).ICAO
                            $ImageToSearch = $AIRCRAFT_MODEL -replace (" ", "+")
                            $LinkToSend_Bing = "<https://www.bing.com/images/search?q=$ImageToSearch|Bing Images>"
                            $AIRCRAFT_MODEL2 = ($ADDAIRCRAFT).MDL
                            $AIRCRAFT_OPERATOR = ($ADDAIRCRAFT).Op
                            $AIRCRAFT_OPERATOR = $AIRCRAFT_OPERATOR -replace (" ", "%20")
                            $AIRCRAFT_OPERATOR2 = ($ADDAIRCRAFT).Op
                            $AIRCRAFT_OPERATOR2 = "*" + $AIRCRAFT_OPERATOR2 + "*"
                            $AIRCRAFT_MODEL_MAP = $AIRCRAFT_MODEL2 -replace (" ", "%20")
                            $AIRCRAFT_INREQUEST_MAP = $ADDAIRCRAFT.ICAO
                            $LinkToSend_Maps = "<http://www.bing.com/maps/?v=2&cp=$lat~$long&lvl=10&dir=0&sty=r&sp=point." + $lat + "_" + $long + "_" + $AIRCRAFT_MODEL_MAP + $AIRCRAFT_OPERATOR + "_" + $AIRCRAFT_INREQUEST_MAP + "|Bing Maps>"
                            $FlightHistory = "<https://flight-data.adsbexchange.com/activity?inputSelect=icao&icao=" + $AIRCRAFT_ICAO2 + "|Logs>"
                            $MYVIRTUALRADAR = "<http://vr1.westeurope.cloudapp.azure.com/virtualradar/desktop.html?icao=" + $AIRCRAFT_ICAO2 + "|MYVR>"
                            #Grab a thumbnail
                            try {
                                $PictureRequest = Invoke-RestMethod "http://www.airport-data.com/api/ac_thumb.json?m=$($ADDAIRCRAFT.ICAO)&n=1"
                            }

                            catch {
                                # Dig into the exception to get the Response details.
                                # Note that value__ is not a typo.
                                Write-Host "Error Response From airport-data.com (Picture Generator)"
                                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
                            }

                            If ($PictureRequest.Data.Count -eq 1) {
                                If ($CommsChannel -eq "Slack") {
                                    $ImageLink = "<" + $PictureRequest.Data.Image+"|Airport-Data Image>"
                                    $FullLink = "<" + $PictureRequest.Data.Link+"|Airport-Data>" 
                                }
                                elseif ($CommsChannel -eq "Twitter") {
                                    $ImageLink = $PictureRequest.Data.Image
                                    $FullLink = $PictureRequest.Data.Link
                                }
                                else{
                                    Continue
                                }
                            }
                            else {
                                $PictureRequest = ""
                                $ImageLink = ""
                                $FullLink = ""
                            }
            
                            $ChannelToSend = "#flight_"+$($PlaneFilter)
                            If ($CommsChannel -eq "Slack") {      
                                $payload = @{
                                    "channel"    = $ChannelToSend
                                    "icon_emoji" = ":small_airplane:"
                                    "text"       = "MODEL:$AIRCRAFT_MODEL`n OPERATOR:$AIRCRAFT_OPERATOR2 || TYPE:$AIRCRAFT_TYPE || ICAO:$AIRCRAFT_ICAO || REG:$AIRCRAFT_ICAO `n $ImageLink || $FullLink || $LinkToSend_Bing || $LinkToSend_Maps || $FlightHistory `n $MYVIRTUALRADAR || $LinkToSend_OS || $LinkToSend_FR || $LinkToSend_FA || $LinkToSend_RB || $LinkToSend_PF `n ---------------------------------------------------------"                                        
                                }

                                Invoke-WebRequest `
                                    -Body (ConvertTo-Json -Compress -InputObject $payload) `
                                    -Method Post `
                                    -Uri $SlackURI | Out-Null
                            }
                            elseif ($CommsChannel -eq "Twitter") {
                                # Define Message
                                $LinkToSend_Photo = "http://www.airport-data.com/aircraft/" + $ADDAIRCRAFT.REG
                                $AIRCRAFT_MODEL = ($ADDAIRCRAFT).MDL
                                $ImageToSearch = $AIRCRAFT_MODEL -replace (" ", "+")
                                $LinkToSend_Bing = "https://www.bing.com/images/search?q=$ImageToSearch"
                                $AIRCRAFT_MODEL2 = ($ADDAIRCRAFT).MDL
                                $AIRCRAFT_OPERATOR = ($ADDAIRCRAFT).Op
                                $AIRCRAFT_OPERATOR = $AIRCRAFT_OPERATOR -replace (" ", "%20")
                                $AIRCRAFT_MODEL_MAP = $AIRCRAFT_MODEL2 -replace (" ", "%20")
                                $AIRCRAFT_INREQUEST_MAP = $ADDAIRCRAFT.ICAO
                                $LinkToSend_Maps = "http://www.bing.com/maps/?v=2&cp=$lat~$long&lvl=10&dir=0&sty=r&sp=point." + $lat + "_" + $long + "_" + $AIRCRAFT_MODEL_MAP + $AIRCRAFT_OPERATOR + "_" + $AIRCRAFT_INREQUEST_MAP 

                                #
                                $oauth_consumer_key = ($MyTwitterCreds | where item -eq "consumer_key").key
                                $oauth_consumer_secret = ($MyTwitterCreds | where item -eq "consumer_secret").key
                                $oauth_token = ($MyTwitterCreds | where item -eq "token").key
                                $oauth_token_secret = ($MyTwitterCreds | where item -eq "token_secret").key
								
                                [string]$PropTweet = "$FullLink `n $AIRCRAFT_MODEL `n $LinkToSend_Bing `n $LinkToSend_Maps"    
								
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
                    }
                } 
            }
        }


        Start-Sleep $SleepBetweenLoops


        If ($CleanUpCounter -ge $LoopCounter) {

            If (($AIRCRAFTARRAY).count -ge 1) {
                ForEach ($AIRCRAFTARRAY_ITEM in $AIRCRAFTARRAY) {
                    [datetime]$DATENOW = Get-Date
                    [datetime]$LASTSEEN = ($AIRCRAFTARRAY_ITEM).TimeAdded

                    If (($DATENOW - $LASTSEEN).Minutes -ge $CleanUpTime) {
                        [PSCustomObject[]]$AIRCRAFTARRAY = $AIRCRAFTARRAY | Where-Object {$_.Icao -ne ($AIRCRAFTARRAY_ITEM).Icao} 
                        Write-Host "Stale Aircraft Removed: " ($AIRCRAFTARRAY_ITEM).ICAO ($AIRCRAFTARRAY_ITEM).TimeAdded
                    }
                    $CleanUpCounter = 1
                }
            }
            # Read in Airplane exclude list from external link
                            if ($SourceFileLocation -eq "Remote") {
                                $FINDROWINARRAY = 0
                                $ignoreurllist          = Import-csv $ignoreurllistPath
                                $FINDROWINARRAY         = [array]::IndexOf($ignoreurllist.filter,$PlaneFilter)
                                
                                if ($FINDROWINARRAY -eq -1){
                                    write-host "Failed to find an entry in your IgnorePlanesURL file, will not attempt to download..." -ForegroundColor Red
                                continue
                                }
                                
                                try{
                                $url                    = $ignoreurllist.sourceurl[$FINDROWINARRAY]
                                $flightignoreliststring = Invoke-RestMethod $url
                                }
                                catch
                                {
                                    write-host "Failed to fetch remote ignore list" -ForegroundColor Red
                                    continue
                                }
                                $tempfile = (Get-Date).ticks
                                $flightignoreliststring | out-file ./$tempfile
                                $flightlistremote = Get-Content ./$tempfile
                                Remove-Item ./$tempfile
                                
                                $remotefilecount = ($flightlistremote).count
                                

                                $IgnorePlaneLists = Get-Content $IgnorePlaneListPath
                                $localignorecount = $IgnorePlaneLists.count

                                Write-Host "Remote File Count:"$remotefilecount
                                Write-Host "Local File Count:"$IgnorePlaneLists.count
                    
                                #get local count
                                
                                if (($remotefilecount -ne $localignorecount) -and ($remotefilecount -ne 0))
                                {
                                    #overwrite local file 
                                    Write-host "I will over write your local file"
                                    $IgnorePlaneLists = Get-Content $IgnorePlaneListPath
                                    $flightlistremote | Out-File $IgnorePlaneListPath
                                    $IgnorePlaneLists = Get-Content $IgnorePlaneListPath    
                                    $slackmessage = "*Updating your local exclude list!* Old Count:$localignorecount New Count:$remotefilecount"
                                    $payload = @{
                                    "channel"    = $ChannelToSend
                                    "icon_emoji" = ":small_airplane:"
                                    "text"       = $slackmessage                                        
                                    }
                    
                                    Invoke-WebRequest `
                                    -Body (ConvertTo-Json -Compress -InputObject $payload) `
                                    -Method Post `
                                    -Uri $SlackURI | Out-Null       
                                }
                                else
                                {
                                    #Dont update the local ignore file
                                    Write-host "I will not overwrite your file as count matches"
                                }
                            }
                            ###############################
            else {
                $CleanUpCounter = 1
            }
        }
        else {
            Write-host "Loop:$CleanUpCounter @ $(Get-Date)"
            $CleanUpCounter += 1
        }
    }
}
Clear-Host

#Import Files
[Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("System.Net") | Out-Null


$CurrentWorkingDir = $PSCommandPath | Split-Path -Parent
$CurrentWorkingDir = $CurrentWorkingDir -replace ("\\","/")
$MySlackCreds    = Get-Content $($CurrentWorkingDir + "/Security/" + "Slack.csv")
$MyTwitterCreds  = Import-CSV $($CurrentWorkingDir + "/Security/" + "Twitter.csv")
$MyGPSLocation = Import-Csv $($CurrentWorkingDir + "/Security/" + "MyLocation.csv")
$ignoreurllistPath = $($CurrentWorkingDir + "/Security/" + "IgnorePlanesURL.csv")
$MyLat = ($MyGPSLocation | Where-Object Position -eq lat).Value
$MyLng = ($MyGPSLocation | Where-Object Position -eq lng).Value
$SlackURI = "https://hooks.slack.com/services/"+$MySlackCreds


if ($IsLinux -eq $true){
    $env:temp = "/tmp"
}

$ParentLogsPath = "$env:temp/VirtualRadarTracker"
$ParentLogsPath = $ParentLogsPath -replace ("\\","/")


    if (!(Test-Path $ParentLogsPath)) {
        New-Item -path $ParentLogsPath -ItemType Directory
        Write-Host "Create logs path..." -ForegroundColor Yellow}

$datestring = (Get-Date).ToString("yyyy-MM-dd")
$LogsPath = "$ParentLogsPath/flighthistory_$($PlaneFilter)_$($datestring).csv"


$CommsChannel = $CommsChannel
$PlaneFilter = $PlaneFilter
$IgnoreSourceFile = $IgnoreSourceFile


$IgnorePlaneListPath = "$env:temp" + "/VirtualRadarTracker/ignorelist_" + $PlaneFilter + ".csv"
$IgnorePlaneListPath = $IgnorePlaneListPath -replace ("\\","/")
if (!(Test-Path $IgnorePlaneListPath)) {
    New-Item -path $IgnorePlaneListPath | Out-Null
}
else {
    $IgnorePlaneLists = Get-Content $IgnorePlaneListPath
}
$IgnorePlaneListsCount = $IgnorePlaneLists.Count

            
 $ChannelToSend = "#flight_"+$($PlaneFilter)
 If ($CommsChannel -eq "Slack") {      
     $payload = @{
         "channel"    = $ChannelToSend
         "icon_emoji" = ":small_airplane:"
         "text"       = "*STARTING SCRIPT, LOCAL IGNORE FILE:$IgnorePlaneListsCount*"
     }

     Invoke-WebRequest `
         -Body (ConvertTo-Json -Compress -InputObject $payload) `
         -Method Post `
         -Uri $SlackURI | Out-Null

}


WatchAircraft $PlaneFilter $CommsChannel $SourceFileLocation




#####################
#WatchAircraft "#military" "Twitter" "Remote"
#Get full Long and Lat details
#$v = Invoke-RestMethod https://public-api.adsbexchange.com/VirtualRadar/AircraftList.json?trFmt=ss