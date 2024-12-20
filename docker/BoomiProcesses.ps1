#Set your Boomi API credentials and path to Telegraf
$TelegrafPath = $Env:TELEGRAF_HOME + "/"
$boomi_username = $Env:BOOMI_USERNAME
$boomi_token = $Env:BOOMI_TOKEN
$boomi_accountId = $Env:BOOMI_ACCOUNT_ID

#--------------------------------------------------------------------------------

function RegularProcess {

    $Remove = $TelegrafPath + 'regularx*.json'
    Remove-Item $Remove
    $Time = Get-Date
    $UTC = $Time.ToUniversalTime()
    $UTCMinus = $UTC.AddMinutes(-1)
    $UTC_Final = $UTCMinus.ToString("yyyy-MM-ddTHH:mm:00Z")

    $Method = "POST"
    $URI = "https://api.boomi.com/api/rest/v1/" + $boomi_accountId + "/ExecutionRecord/query"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $boomi_username, $boomi_token)))
    $headers = @{
        Authorization  = ("Basic {0}" -f $base64AuthInfo)
        'Accept'       = 'application/json'
        'Content-Type' = 'application/json'
    }
    $Body = @"
{
    "QueryFilter":
    {
    "expression":
    {
    "argument": ["$UTC_Final"],
    "operator": "GREATER_THAN_OR_EQUAL",
    "property": "recordedDate"
        }
    }
}
"@
    #Fetch initial 100 transactions
    $Response = Invoke-RestMethod -Headers $headers -Method $Method -URI $URI -Body $Body
    $json = $Response | ConvertTo-Json -Depth 2
    $json = $json.Replace("Long ", "")
    $json = $json -replace '"(\d+)"', '$1'
    $WriteResponseInitial = $TelegrafPath + 'regular0.json'
    $json | Out-File -FilePath $WriteResponseInitial

    #Check for more transactions from Boomi
    if ($Response.queryToken.Length -gt 0) {
        $URI = "https://api.boomi.com/api/rest/v1/" + $boomi_accountId + "/ExecutionRecord/queryMore"
        $Number = 1

        while ($Response.queryToken.Length -gt 0) {
            $Token = $Response.queryToken | ConvertTo-Json
            $Body = @"
    $Token
"@

            $Response = Invoke-RestMethod -Headers $headers -Method $Method -URI $URI -Body $Body
            $json = $Response | ConvertTo-Json -Depth 2
            $json = $json.Replace("Long ", "")
            $json = $json -replace '"(\d+)"', '$1' 
            $WriteResponse = $TelegrafPath + 'regularx' + $Number
            $json | Out-File -FilePath ($WriteResponse + '.json')
            $Number++
        }   
    }
}

#--------------------------------------------------------------------------------

function LowLatencyProcess {

    $Remove = $TelegrafPath + 'lowLatencyx*.json'
    Remove-Item $Remove
    $Time = Get-Date
    $UTC = $Time.ToUniversalTime()
    $UTCOffset = $UTC.AddMinutes(-6)
    $UTC_Final1 = $UTCOffset.ToString("yyyy-MM-ddTHH:mm:00Z")
    $UTC_Final2 = $UTCOffset.ToString("yyyy-MM-ddTHH:mm:59Z")

    $Method = "POST"
    $URI = "https://api.boomi.com/api/rest/v1/" + $boomi_accountId + "/ExecutionSummaryRecord/query"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $boomi_username, $boomi_token)))
    $headers = @{
        Authorization  = ("Basic {0}" -f $base64AuthInfo)
        'Accept'       = 'application/json'
        'Content-Type' = 'application/json'
    }
    $Body = @"
{
    "QueryFilter":
    {
    "expression":
    {
    "argument": ["$UTC_Final1","$UTC_Final2"],
    "operator": "BETWEEN",
    "property": "timeBlock"
        }
    }
}
"@
    #Fetch initial 100 transactions
    $Response = Invoke-RestMethod -Headers $headers -Method $Method -URI $URI -Body $Body
    $json = $Response | ConvertTo-Json -Depth 2
    #$json = $json.Replace("Long ","")
    #$json = $json -replace '"(\d+)"', '$1'
    $WriteResponseInitial = $TelegrafPath + 'lowLatency0.json'
    $json | Out-File -FilePath $WriteResponseInitial

    #Check for more transactions from Boomi
    if ($Response.queryToken.Length -gt 0) {
        $URI = "https://api.boomi.com/api/rest/v1/" + $boomi_accountId + "/ExecutionSummaryRecord/queryMore"
        $Number = 1

        while ($Response.queryToken.Length -gt 0) {
            $Token = $Response.queryToken | ConvertTo-Json
            $Body = @"
    $Token
"@

            $Response = Invoke-RestMethod -Headers $headers -Method $Method -URI $URI -Body $Body
            $json = $Response | ConvertTo-Json -Depth 2
            $json = $json.Replace("Long ", "")
            $json = $json -replace '"(\d+)"', '$1' 
            $WriteResponse = $TelegrafPath + 'lowLatencyx' + $Number
            $json | Out-File -FilePath ($WriteResponse + '.json')
            $Number++
        }   
    }
}
 

