#!/bin/bash
# Usage: ./get_running_config <tftp_server_ip>  <config>

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <tftp_server_ip> <config>"
    exit 1
fi

# Create JSON
TFTP_SERVER_IP=$1

# strip leading "/" from CONFIG if present
# CONFIG=${2#/}
# just the filename (file must be in the tftp dir
CONFIG=$(basename "$2")

# Output file name
fname="request.jsonl"

echo '{ "method": "icfg.control.copy.set", "params": [{ "Copy": true, "SourceConfigType": "runningConfig", "SourceConfigFile": "", "DestinationConfigType": "configFile", "DestinationConfigFile": "tftp://'"$TFTP_SERVER_IP"'/'"$CONFIG"'", "Merge": false }], "id": 1 }' > "$fname"
gs-rpc post -f $fname
