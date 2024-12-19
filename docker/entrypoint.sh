#!/bin/bash

if [ -f "$TELEGRAF_HOME/telegraf.conf" ]; then
    echo "[>_] Found Telegraf configuration: telegraf.conf"
else
    echo "[>_] Telegraf configuration is missing."
    echo "[!] Please ensure that the Telegraf configuration file is passed to the container."
    echo "[!] Use a volume mount or another method to provide the file at the path: $TELEGRAF_HOME/telegraf.conf"
    exit 1
fi

# Check for Boomi and Eyer environment variables
if [ -z "$BOOMI_USERNAME" ] || [ -z "$BOOMI_TOKEN" ] || [ -z "$BOOMI_ACCOUNT_ID" ] || [ -z "$EYER_PUSH_TOKEN" ] || [ -z "$BOOMI_ATOM_IP" ]; then
    echo "[!] One or more required environment variables are missing:"
    [ -z "$BOOMI_USERNAME" ] && echo "    - BOOMI_USERNAME is not set."
    [ -z "$BOOMI_TOKEN" ] && echo "    - BOOMI_TOKEN is not set."
    [ -z "$BOOMI_ACCOUNT_ID" ] && echo "    - BOOMI_ACCOUNT_ID is not set."
    [ -z "$EYER_PUSH_TOKEN" ] && echo "    - EYER_PUSH_TOKEN is not set."
    [ -z "$BOOMI_ATOM_IP" ] && echo "    - BOOMI_ATOM_IP is not set."
    exit 1
fi

# Log Boomi credentials for confirmation (omit sensitive values in real scenarios)
echo "[>_] Using Boomi and Eyer credentials:"
echo "    Boomi Username: $BOOMI_USERNAME"
echo "    Boomi Account ID: $BOOMI_ACCOUNT_ID"
echo "    Boomi Atom IP: $BOOMI_ATOM_IP"

# Start Jetty
echo "[>_] Starting Jetty..."
cd $JETTY_BASE
java -jar $JETTY_HOME/start.jar

# Start Telegraf
echo "[>_] Starting Telegraf..."
$TELEGRAF_HOME/telegraf --config $TELEGRAF_HOME/telegraf.conf &
$TELEGRAF_HOME/telegraf --config $TELEGRAF_HOME/telegraf_boomi_processes.conf &

# Keep container running
tail -f /dev/null