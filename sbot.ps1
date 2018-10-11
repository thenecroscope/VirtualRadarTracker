Function Get-SlackRooms ($words, $channels, $slackApiKey) {

    $roomFound = ""
    $words = $words -split ' '
    $channelName = $words[1]

    $body = @{"token" = $slackApiKey}
    $getRooms = Invoke-RestMethod -Uri "https://slack.com/api/channels.list" -Body $body
    $rooms = $getrooms.channels

    ForEach ($room in $rooms) {
        if ($room.name -eq "flight_" + $channelName) {
            $roomFound = $true
            return $roomFound
        }
        else {
            $roomFound = $false
        }
        
    }
}

Function Send-SlackMsg {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$Text,        
        [Parameter(Mandatory = $true)]$Channel,
        $ID = (get-date).ticks,
        $Timeout = 30
    )
    
    If (!($WS -is [System.Net.WebSockets.ClientWebSocket])) {
        Write-Log  -Level Error 'A WebSocket to Slack is not open via $WS.' -Path $LogPath
        Return
    }

    $Prop = @{'id' = $ID; 'type' = 'message'; 'text' = $Text; 'channel' = $Channel}        
    $Msg = (New-Object –TypeName PSObject –Prop $Prop) | ConvertTo-Json
    $Array = @()
    $Encoding = [System.Text.Encoding]::UTF8
    $Array = $Encoding.GetBytes($Msg)
    $Msg = New-Object System.ArraySegment[byte]  -ArgumentList @(, $Array)
    $Conn = $WS.SendAsync($Msg, [System.Net.WebSockets.WebSocketMessageType]::Text, [System.Boolean]::TrueString, $CT)
    $ConnStart = Get-Date

    While (!$Conn.IsCompleted) { 
        $TimeTaken = ((get-date) - $ConnStart).Seconds
        If ($TimeTaken -gt $Timeout) {
            Write-Log -Level Error "Message $ID took longer than $Timeout seconds and may not have been sent." -Path $LogPath
            Return
        }
        Start-Sleep -Milliseconds 100 
    }
   
}

Function Service-Action ($words, $channel, $slackApiKey) {
    #check if channel is a valid channel
    $validRoom = Get-SlackRooms $words $channel $slackApiKey

    If ($validRoom -eq $true) {
        $words = $words -split ' '

        if ($words[2] -eq "stop" -or $words[2] -eq "start" -or $words[2] -eq "restart") {
            $TextInfo = (Get-Culture).TextInfo
            $PascalCase = $TextInfo.ToTitleCase($words[1])
            if ($words[2] -eq "restart")
            {
                $cmd = "sudo systemctl stop vrt$PascalCase.service"
                Invoke-Expression $cmd
                $cmd = "sudo systemctl start vrt$PascalCase.service"
                Invoke-Expression $cmd
                Send-SlackMsg -Text "Attempting to $($words[2]) the $($words[1]) service" -Channel $RTM.Channel
            }
            else{
                $cmd = "sudo systemctl $($words[2]) vrt$PascalCase.service"
                Invoke-Expression $cmd
                Send-SlackMsg -Text "Attempting to $($words[2]) the $($words[1]) service" -Channel $RTM.Channel
            }
        }
    }
    elseif ($validRoom -eq $true) {
        Send-SlackMsg -Text "Slack Channel Is Not Valid Try Again" -Channel $RTM.Channel
    }
    else {
        Send-SlackMsg -Text "An Error Occured When Processing Service Command" -Channel $RTM.Channel
    }
}

Function IgnoreList-Action  ($words, $channel, $slackApiKey) {
    $fullwords = $words
    $words = $words -split ' '

    #check if channel is a valid channel
    $validRoom = Get-SlackRooms $words $channel $slackApiKey

    If ($validRoom -eq $true) {
        $words = $words -split ' '
        
        if ($fullwords.StartsWith("list")) {
            $importString = "$LogsPath/$($words[1])_ignorelist.csv"
            [string]$list = Import-Csv $importString | Out-String
            Send-SlackMsg -Text $list -Channel $RTM.Channel
        }
            
            
        elseif ($fullwords.StartsWith("add")) {
            if ($words[2] -eq "ICAO" -or $words[2] -eq "TYPE") {
                $importString = "$LogsPath/$($words[1])_ignorelist.csv"
                try{
                    [PSCustomObject[]]$list = Import-Csv $importString
                }
                catch{#File does not exist
                }
                $TextInfo = (Get-Culture).TextInfo
                $commentslower = $words[4..99] -join " "
                $comments = $TextInfo.ToTitleCase($commentslower)
                $obj = New-Object -TypeName PSCustomObject
                $obj | Add-Member -MemberType NoteProperty -Name ValueType -Value $words[2].ToUpper()
                $obj | Add-Member -MemberType NoteProperty -Name Value -Value $words[3].ToUpper()
                $obj | Add-Member -MemberType NoteProperty -Name Comments -Value $comments
                $list += $obj
                $list | Sort-Object ValueType, Value| Export-Csv $importString -Force -NoTypeInformation
                $tot = $list.count
                Send-SlackMsg -Text "Item Added, $tot Item(s) Now In Your Ignore list" -Channel $RTM.Channel
            }
            else {
                Send-SlackMsg -Text "*Cannot Add, Invalid Type Entered*" -Channel $RTM.Channel
            }            
        }
            
                
        elseif ($fullwords.StartsWith("remove")) {
            $importString = "$LogsPath/$($words[1])_ignorelist.csv"
            [PSCustomObject[]]$list = Import-Csv $importString
            [PSCustomObject[]]$listFind = $list | Where-Object {$_.Value -eq ($words[2].ToUpper())}
                
            if ($listFind.count -ge 1 ) {
                [PSCustomObject[]]$list = $list | Where-Object {$_.Value -ne $words[2].ToUpper()}
                $list | Sort-Object ValueType, Value| Export-Csv $importString -Force -NoTypeInformation
                $tot = $list.count
                Send-SlackMsg -Text "*Item Removed, $tot Item(s) Now In Your Ignore list*" -Channel $RTM.Channel
            }
            else { #not in list
                Send-SlackMsg -Text "*Cannot Find Item In Your List*" -Channel $RTM.Channel
            }
        }

    }
}
    
Function Invoke-SlackBot {
    [cmdletbinding()]
    Param(
        [string]$LogPath = "$Env:USERPROFILE\Logs\SlackBot.log",
        [string]$PSSlackConfigPath = "$PSscriptPath\..\PSSlackConfig.xml"
    )
      
    #Web API call starts the session and gets a websocket URL to use.
    $RTMSession = Invoke-RestMethod -Uri https://slack.com/api/rtm.start -Body @{token = $parameter}

    Try {
        Do {
            $WS = New-Object System.Net.WebSockets.ClientWebSocket                                                
            $CT = New-Object System.Threading.CancellationToken                                                   

            $Conn = $WS.ConnectAsync($RTMSession.URL, $CT)                                                  
            While (!$Conn.IsCompleted) { Start-Sleep -Milliseconds 100 }

            $Size = 1024
            $Array = [byte[]] @(, 0) * $Size
            $Recv = New-Object System.ArraySegment[byte] -ArgumentList @(, $Array)

            While ($WS.State -eq 'Open') {

                $RTM = ""

                Do {
                    $Conn = $WS.ReceiveAsync($Recv, $CT)
                    While (!$Conn.IsCompleted) { Start-Sleep -Milliseconds 1000 }

                    $Recv.Array[0..($Conn.Result.Count - 1)] | ForEach-Object { $RTM = $RTM + [char]$_ }

                } Until ($Conn.Result.Count -lt $Size)

                If ($RTM) {
                    try {
                        $RTM = ($RTM | convertfrom-json) 
                    }
                    Catch {
                        Write-Host "Catch bad json string"
                    }

                    Switch ($RTM) {
                        {($_.type -eq 'message')} { 

                            $words = "$($_.text)".ToLower()
                            #$words = $words -split ' '
                                
                            Switch ($words) {
                                {$words.StartsWith("service")} { Service-Action $words $RTM.Channel $parameter }
                                {$words.StartsWith("list")} { IgnoreList-Action $words $RTM.Channel $parameter}
                                {$words.StartsWith("add")} { IgnoreList-Action $words $RTM.Channel $parameter}
                                {$words.StartsWith("remove")} { IgnoreList-Action $words $RTM.Channel $parameter}
                            }
                        }
                        {$_.type -eq 'reconnect_url'} { $RTMSession.URL = $RTM.url }
                    }
                
                }

            }   
        } Until (!$Conn)

    }
    Catch {

        If ($WS) { 
            Write-Verbose "Closing websocket"
            $WS.Dispose()
            Write-Host "oooops"
        }

    }

}



Clear-Host
Write-Host "Starting Up Slackbot..." $(Get-Date)
$parameters = ""
$workingDir = $PSCommandPath | Split-Path -Parent
$workingDir = $workingDir -replace ("\\", "/") #for linux
$LogsPath = $workingDir + "/logs"
$configsPath = $workingDir + "/configs"
$parameter = Get-Content $configsPath/slackbot.csv
Invoke-SlackBot