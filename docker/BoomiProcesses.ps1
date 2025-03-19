#Set your Boomi API credentials and path to Telegraf
$TelegrafPath = $Env:TELEGRAF_HOME + "/"
$boomi_username = $Env:BOOMI_USERNAME
$boomi_token = $Env:BOOMI_TOKEN
$boomi_accountId = $Env:BOOMI_ACCOUNT_ID
$selected_atom_ids = $Env:SELECTED_ATOM_IDS -split "`r?`n" | Where-Object { $_ -match "\S" }

#--------------------------------------------------------------------------------

function BuildQueryBody {
    param (
        [Parameter(Mandatory=$true)][string]$property,
        [Parameter(Mandatory=$true)][string]$operator,
        [Parameter(Mandatory=$true)][array]$arguments,
        [Parameter(Mandatory=$false)][array]$atomIds = @()
    )
    
    $mainCondition = @{
        "argument" = $arguments
        "operator" = $operator
        "property" = $property
    }
    
    if ($atomIds.Count -gt 0) {
        $atomExpressions = @()
        foreach ($atomId in $atomIds) {
            $atomExpressions += @{
                "argument" = @($atomId)
                "operator" = "EQUALS"
                "property" = "atomId"
            }
        }

        $body = @{
            "QueryFilter" = @{
                "expression" = @{
                    "operator" = "and"
                    "nestedExpression" = @(
                        $mainCondition,
                        @{
                "operator" = "or"
                            "nestedExpression" = $atomExpressions
                        }
                    )
                }
            }
        }
    } else {
        # If no atomIds, use a simpler structure with just the main condition
        $body = @{
            "QueryFilter" = @{
                "expression" = $mainCondition
            }
        }
    }
    
    return $body | ConvertTo-Json -Depth 10
}

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

    $BodyJson = BuildQueryBody `
        -property "recordedDate" `
        -operator "GREATER_THAN_OR_EQUAL" `
        -arguments @($UTC_Final) `
        -atomIds $selected_atom_ids

    #Fetch initial 100 transactions
    $Response = Invoke-RestMethod -Headers $headers -Method $Method -URI $URI -Body $BodyJson
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

    $BodyJson = BuildQueryBody `
        -property "timeBlock" `
        -operator "BETWEEN" `
        -arguments @($UTC_Final1, $UTC_Final2) `
        -atomIds $selected_atom_ids

    #Fetch initial 100 transactions
    $Response = Invoke-RestMethod -Headers $headers -Method $Method -URI $URI -Body $BodyJson
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


