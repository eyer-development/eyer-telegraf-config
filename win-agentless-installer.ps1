function PrepareFolder {
    param (
        [string]$folderPath
    )

    if (!(Test-Path $folderPath)) {
        Write-Host "[>_] Creating folder: $folderPath"
        New-Item -ItemType Directory -Path $folderPath | Out-Null
    }
}

function Download {
    param (
        [string]$url,
        [string]$destinationPath,
        [string]$md5Checksum
    )

    if (!(Test-Path $destinationPath)) {
        Write-Host "[>_] Downloading $url to $destinationPath..."
        $progresspreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $using:url -Outfile $using:destinationPath -UseBasicParsing
    }

    if ($md5Checksum) {
        $actualChecksum = Get-FileHash -Algorithm MD5 -Path $destinationPath | Select-Object -ExpandProperty Hash
        if ($actualChecksum -eq $md5Checksum) {
            Write-Host "[>_] Hash check passed."
        }
        else {
            Write-Host "[>_] Hash check failed. Please check the download URL or try again later." -ForegroundColor Red
            exit
        }
    }
}

function SetupJetty {
    param (
        [string]$jettyHome,
        [string]$jettyBase
    )

    Write-Host "[>_] Setting up Jetty..."

    $jettyZipPath = "$env:APPDATA\eyer\downloads\jetty-home-12.0.9.zip"
    $jettyExtractPath = "$env:APPDATA\eyer\downloads"

    # Download and extract Jetty
    Write-Host "[>_] Downloading and extracting Jetty..."
    Download "https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-home/12.0.9/jetty-home-12.0.9.zip" `
        $jettyZipPath `
        "838E1DD769C8021C6DAA431770878E3B"

    Write-Host "[>_] Downloading Jolokia agent..."
    Download "https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-agent-war-unsecured/2.0.2/jolokia-agent-war-unsecured-2.0.2.war" `
        "$env:APPDATA\eyer\downloads\jolokia-agent-war-unsecured-2.0.2.war" `
        "6678B95AECFA61215DECA4128A5AAA9B"

    Expand-Archive -Force -Path $jettyZipPath -DestinationPath $jettyExtractPath

    # Copy Jetty files to the specified locations
    Write-Host "[>_] Copying Jetty files to $jettyHome..."
    Copy-Item -Path "$jettyExtractPath\jetty-home-12.0.9\*" -Destination $jettyHome -Recurse -Force
}

function SetupTelegraf {
    param (
        [string]$eyerTelegrafPath
    )

    Write-Host "[>_] Setting up Telegraf..."

    $telegrafPath = "C:\Program Files\InfluxData"

    $telegrafZipPath = "$env:APPDATA\eyer\downloads\telegraf-1.30.3_windows_amd64.zip"
    $telegrafExtractPath = "$env:APPDATA\eyer\downloads"
    $telegrafConfigPath = "$env:APPDATA\eyer\downloads\eyer_agentless_telegraf.conf"

    Write-Host "[>_] Downloading and extracting Telegraf..."
    Download "https://dl.influxdata.com/telegraf/releases/telegraf-1.30.3_windows_amd64.zip" `
        $telegrafZipPath `
        "E3F606029E8B691489820E54BC629ED4"

    Expand-Archive -Force -Path $telegrafZipPath -DestinationPath $telegrafExtractPath
    Copy-Item -Path "$telegrafExtractPath\telegraf-1.30.3\*" -Destination $eyerTelegrafPath -Recurse -Force
    
    Write-Host "[>_] Downloading Telegraf Eyer config..."
    Download "https://raw.githubusercontent.com/eyer-development/public-boomi-scripts/master/eyer_agentless_telegraf.conf" $telegrafConfigPath
    Write-Host "[>_] Patching Telegraf config..."
    Move-Item -Path "$telegrafConfigPath" -Destination "$eyerTelegrafPath\telegraf.conf" -Force

    # Create a symbolic link to the Telegraf installation
    if (!(Test-Path "$telegrafPath\telegraf")) {
        Write-Host "[>_] Creating symbolic link to Telegraf installation..."
        PrepareFolder $telegrafPath
        New-Item -ItemType SymbolicLink -Path "$telegrafPath\telegraf" -Target $eyerTelegrafPath # | Out-Null
    }
    else {
        Write-Host "[>_] Symbolic link already exists."
    }
}

function Test-Jetty {
    param ()

    $process = Start-Process powershell -ArgumentList '-NoExit', '-Command', 'java -jar $env:JETTY_HOME\start.jar' -PassThru

    # Define the end time for the test (15 seconds from now)
    $endTime = (Get-Date).AddSeconds(30)
    $url = "http://localhost:8080/jolokia"
    # Variable to track success
    
    Write-Host "[>_] Testing Jetty" -NoNewline
    
    $success = $false
    # Test the URL every second for the specified duration
    while ((Get-Date) -lt $endTime) {
        try {
            $webRequest = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2
            if ($webRequest.StatusCode -eq 200) {
                $success = $true
                break
            }
            else {
                $success = $false
            }
        }
        catch {
            $success = $false
        }
        Write-Host "."  -NoNewline
        Start-Sleep -Seconds 2
    }
    
    # Stop the process
    Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $process.Id } | ForEach-Object { Stop-Process -Id $_.ProcessId }
    Stop-Process -Id $process.Id
    
    # Check success and report
    if ($success) {
        Write-Host " success"
    }
    else {
        Write-Host " fail"
    }
}

function Test-Telegraf {
    param ()

    $telegrafPath = "C:\Program Files\InfluxData\telegraf\telegraf.exe"
    $configPath = "C:\Program Files\InfluxData\telegraf\telegraf.conf"
    $command = "--config '$configPath' --test"

    Write-Host "[>_] Testing Telegraf..." -NoNewline
    $process = Start-Process -FilePath "$telegrafPath" -ArgumentList "$command" -PassThru
    $process.WaitForExit()
    
    $success = $false
    if ($process.ExitCode -eq 0) {
        # Collect output from the console (stdout)
        $output = & $command

        # Check if the output contains metrics
        if ($output) {
            $success = $true
        }
    }

    # Check success and report
    if ($success) {
        Write-Host " success"
    }
    else {
        Write-Host " fail"
    }
}

# Check if Java is installed
$javaVersion = (Get-Command java).Version
if ($javaVersion -eq $null) {
    Write-Host "Java is required to run this script."
    exit
}

Write-Host "[>_] Java version found: $javaVersion"

# Prepare required folders
Write-Host "[>_] Preparing required folders..."
PrepareFolder "$env:APPDATA\eyer"
PrepareFolder "$env:APPDATA\eyer\downloads"
PrepareFolder "$env:APPDATA\eyer\telegraf"
PrepareFolder "$env:APPDATA\eyer\jetty\home"
PrepareFolder "$env:APPDATA\eyer\jetty\base"

# Download and setup Jetty
SetupJetty "$env:APPDATA\eyer\jetty\home" "$env:APPDATA\eyer\jetty\base"

# Download and setup Telegraf
SetupTelegraf "$env:APPDATA\eyer\telegraf"

# Start Jetty
Write-Host "[>_] Starting Jetty..."
$env:JETTY_HOME = "$env:APPDATA\eyer\jetty\home"
$env:JETTY_BASE = "$env:APPDATA\eyer\jetty\base"

cd $env:JETTY_BASE

java -jar $env:JETTY_HOME\start.jar --add-modules=server,http,ee10-deploy
java -jar $env:JETTY_HOME\start.jar --add-module=demos
cp "$env:APPDATA\eyer\downloads\jolokia-agent-war-unsecured-2.0.2.war" "$env:JETTY_BASE\webapps"
Move-Item -Path "$env:JETTY_BASE\webapps\jolokia-agent-war-unsecured-2.0.2.war" -Destination "$env:JETTY_BASE\webapps\jolokia.war" -Force

Test-Jetty

# Start Telegraf
Write-Host "[>_] Installing Telegraf..."
$telegrafPath = "C:\Program Files\InfluxData\telegraf\telegraf.exe"
$configPath = "C:\Program Files\InfluxData\telegraf\telegraf.conf"
$command = "--service install --config '$configPath'"
$process = Start-Process -FilePath "$telegrafPath" -ArgumentList "$command" -PassThru
$process.WaitForExit()

Write-Host "[>_] Installation completed"

explorer "%AppData%\eyer\telegraf"