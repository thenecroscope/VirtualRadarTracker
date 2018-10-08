Function Send-SlackMsg {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true)][string]$Text,        
        [Parameter(Mandatory=$true)]$Channel,
        $ID = (get-date).ticks,
        $Timeout = 30
    )
    
    If (!($WS -is [System.Net.WebSockets.ClientWebSocket])){
        Write-Log  -Level Error 'A WebSocket to Slack is not open via $WS.' -Path $LogPath
        Return
    }

    $Prop = @{'id'      = $ID; 'type' = 'message'; 'text' = $Text; 'channel' = $Channel}        
    $Msg = (New-Object –TypeName PSObject –Prop $Prop) | ConvertTo-Json
    $Array = @()
    $Encoding = [System.Text.Encoding]::UTF8
    $Array = $Encoding.GetBytes($Msg)
    $Msg = New-Object System.ArraySegment[byte]  -ArgumentList @(,$Array)
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

Function Service-Action ($words, $channel)
{
    if ($words[0] -eq "service")
        {
            if ($words[1] -eq "stop")
                {
                    if ($words[2] -eq "interesting")
                    {
                        systemctl stop vrtInteresting.service
                        Send-SlackMsg -Text "$words[1] $words[2]" -Channel $RTM.Channel
                    }
                    elseif ($words[2] -eq "military")
                    {
                        systemctl stop vrtMilitary.service
                        Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel
                    }
                    elseif ($words[2] -eq "local")
                    {
                        systemctl stop vrtLocaly.service
                        Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel

                    }
                    elseif ($words[2] -eq "worldwar")
                    {
                        systemctl stop vrtWorldWar.service
                        Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel
                    }
                }
            


            elseif($words[1] -eq "restart")
            {
                if ($words[2] -eq "interesting")
                {
                    systemctl restart vrtInteresting.service
                    Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel
                }
                elseif ($words[2] -eq "military")
                {
                    systemctl restart vrtMilitary.service
                    Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel
              }
                elseif ($words[2] -eq "local")
                {
                    systemctl restart vrtLocaly.service
                    Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel
                }
                elseif ($words[2] -eq "worldwar")
                {
                    systemctl restart vrtWorldWar.service
                    Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel
                }
            }
            
            elseif($words[1] -eq "start")
            {
                if ($words[2] -eq "interesting")
                {
                    systemctl start vrtInteresting.service
                    Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel

                }
                elseif ($words[2] -eq "military")
                {
                    systemctl start vrtMilitary.service
                    Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel
                }
                elseif ($words[2] -eq "local")
                {
                    systemctl start vrtLocaly.service
                    Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel
                }
                elseif ($words[2] -eq "worldwar")
                {
                    systemctl start vrtWorldWar.service
                    Send-SlackMsg -Text "Attempting to $($words[1]) $($words[2]) service" -Channel $RTM.Channel
                }
                else
                {

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
    $RTMSession = Invoke-RestMethod -Uri https://slack.com/api/rtm.start -Body @{token=$parameter}

    Try{
        Do{
            $WS = New-Object System.Net.WebSockets.ClientWebSocket                                                
            $CT = New-Object System.Threading.CancellationToken                                                   

            $Conn = $WS.ConnectAsync($RTMSession.URL, $CT)                                                  
            While (!$Conn.IsCompleted) { Start-Sleep -Milliseconds 100 }

            $Size = 1024
            $Array = [byte[]] @(,0) * $Size
            $Recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$Array)

            While ($WS.State -eq 'Open') {

                $RTM = ""

                Do {
                    $Conn = $WS.ReceiveAsync($Recv, $CT)
                    While (!$Conn.IsCompleted) { Start-Sleep -Milliseconds 100 }

                    $Recv.Array[0..($Conn.Result.Count - 1)] | ForEach-Object { $RTM = $RTM + [char]$_ }

                } Until ($Conn.Result.Count -lt $Size)

                If ($RTM){
                    $RTM = ($RTM | convertfrom-json) 

                    Switch ($RTM){
                        {($_.type -eq 'message')} { 

                                $words = "$($_.text)".ToLower()
                                $words = $words -split ' '
                                
                                Switch ($words){
                                    {@("hey","hello","hi") -contains $_} { Send-SlackMsg -Text 'Hello!' -Channel $RTM.Channel }
                                    {@("bye","cya") -contains $_} { Send-SlackMsg -Text 'Goodbye!' -Channel $RTM.Channel }
                                    {@("service") -contains $_} { Service-Action $words $RTM.Channel }

                                }
                        }
                        {$_.type -eq 'reconnect_url'} { $RTMSession.URL = $RTM.url }
                    }
                }
            }   
        } Until (!$Conn)

    }Finally{

        If ($WS) { 
            Write-Verbose "Closing websocket"
            $WS.Dispose()
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