#!/bin/bash

# Check for Boomi and Eyer environment variables
if [ -z "$BOOMI_USERNAME" ] || [ -z "$BOOMI_TOKEN" ] || [ -z "$BOOMI_ACCOUNT_ID" ] || [ -z "$EYER_PUSH_TOKEN" ]; then
    echo "[!] One or more required environment variables are missing:"
    [ -z "$BOOMI_USERNAME" ] && echo "    - BOOMI_USERNAME is not set."
    [ -z "$BOOMI_TOKEN" ] && echo "    - BOOMI_TOKEN is not set."
    [ -z "$BOOMI_ACCOUNT_ID" ] && echo "    - BOOMI_ACCOUNT_ID is not set."
    [ -z "$EYER_PUSH_TOKEN" ] && echo "    - EYER_PUSH_TOKEN is not set."
    exit 1
fi

# Log Boomi credentials for confirmation (omit sensitive values in real scenarios)
echo "[>_] Using Boomi and Eyer credentials:"
echo "    Boomi Username: $BOOMI_USERNAME"
echo "    Boomi Account ID: $BOOMI_ACCOUNT_ID"
echo "    Boomi Atom IP: ${BOOMI_ATOM_IP:-(empty)}"

if [ -z "$BOOMI_ATOM_IP" ]; then
    echo "[!] BOOMI_ATOM_IP is not set. Starting monitoring-only services."
    supervisord_config="/opt/supervisord_monitoring_only.conf"
else
    echo "[>_] BOOMI_ATOM_IP is set. Starting full services."
    supervisord_config="/opt/supervisord.conf"
fi
supervisord -c "$supervisord_config"

# Keep container running
tail -f /dev/null