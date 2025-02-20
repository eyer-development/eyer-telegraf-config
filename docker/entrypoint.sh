#!/bin/bash

if [ -z "$BOOMI_USERNAME" ] || [ -z "$BOOMI_TOKEN" ] || [ -z "$BOOMI_ACCOUNT_ID" ] || [ -z "$EYER_PUSH_TOKEN" ]; then
    echo "[!] One or more required environment variables are missing:"
    [ -z "$BOOMI_USERNAME" ] && echo "    - BOOMI_USERNAME is not set."
    [ -z "$BOOMI_TOKEN" ] && echo "    - BOOMI_TOKEN is not set."
    [ -z "$BOOMI_ACCOUNT_ID" ] && echo "    - BOOMI_ACCOUNT_ID is not set."
    [ -z "$EYER_PUSH_TOKEN" ] && echo "    - EYER_PUSH_TOKEN is not set."
    exit 1
fi

# Log Boomi credentials for confirmation (skip sensitive EYER_PUSH_TOKEN)
echo "[>_] Using Boomi and Eyer credentials:"
echo "    Boomi Username: $BOOMI_USERNAME"
echo "    Boomi Account ID: $BOOMI_ACCOUNT_ID"
echo "    Boomi Atom IP: $(echo "$BOOMI_ATOM_IP" | awk '{printf "%s, ", $0} END {print ""}' | sed 's/, $//')"

# Validate BOOMI_ATOM_IP format to contain
# - IP address (required) 
# - Optional port separated by colon
# - Optional name separated by pipe
if [ -n "$BOOMI_ATOM_IP" ]; then
    IFS=$'\n'
    for atom_entry in $BOOMI_ATOM_IP; do
        if [[ ! "$atom_entry" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(:[0-9]+)?(\|[a-zA-Z0-9_-]+)?$ ]]; then
            echo "[!] Invalid BOOMI_ATOM_IP entry: $atom_entry"
            exit 1
        fi
    done
fi

if [ -z "$BOOMI_ATOM_IP" ]; then
    echo "[!] BOOMI_ATOM_IP is not set. Starting monitoring-only services."
    supervisord_config="/opt/supervisord_monitoring_only.conf"
else
    echo "[>_] BOOMI_ATOM_IP is set. Parsing services and creating telegraf configuration."
    supervisord_config="/opt/supervisord.conf"
    
    rm -f $TELEGRAF_HOME/telegraf.conf
    cat /opt/telegraf-base.conf.template > $TELEGRAF_HOME/telegraf.conf
    
    # Parse BOOMI_ATOM_IP and append input configurations
    IFS=$'\n'
    for atom_entry in $BOOMI_ATOM_IP; do
        if [ -z "$atom_entry" ]; then
            continue
        fi
        
        ip_port=${atom_entry%%|*}
        name=${atom_entry##*|}

        # Default port to 5002 if not defined
        if [[ ! "$ip_port" =~ : ]]; then
            ip_port="$ip_port:5002"
        fi

        # Default name to IP:PORT if not defined
        if [[ "$atom_entry" == *"|"* ]]; then
            name="${atom_entry#*|}"
        else
            name="${ip_port}"
        fi

        echo "[>_] Adding input configuration for $ip_port as '$name'"
        
        sed "s/{{ NAME }}/$name/g; s/{{ IP_WITH_PORT }}/$ip_port/g" /opt/telegraf-input.conf.template >> $TELEGRAF_HOME/telegraf.conf
    done
fi

supervisord -c "$supervisord_config"

tail -f /dev/null