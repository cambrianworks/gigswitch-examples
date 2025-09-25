#!/bin/bash
# Usage: ./make_port_file.sh <port_number 1-29> <power_mode 0|1>

MANAGEMENT_PORT=29

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <port_number 1-29> <power_mode 0|1>"
    exit 1
fi

port_num=$1
power_mode=$2

# Validate input
if ! [[ "$port_num" =~ ^[0-9]+$ ]] || (( port_num < 1 || port_num > 29 )); then
    echo "Error: port number must be between 1 and 29"
    exit 1
fi

if [[ "$power_mode" != "0" && "$power_mode" != "1" ]]; then
    echo "Error: power mode must be 0 or 1"
    exit 1
fi

# List of ports
ports=(
"Gi 1/1"
"Gi 1/2"
"Gi 1/3"
"Gi 1/4"
"Gi 1/5"
"Gi 1/6"
"Gi 1/7"
"Gi 1/8"
"Gi 1/9"
"Gi 1/10"
"Gi 1/11"
"Gi 1/12"
"Gi 1/13"
"Gi 1/14"
"Gi 1/15"
"Gi 1/16"
"Gi 1/17"
"Gi 1/18"
"Gi 1/19"
"Gi 1/20"
"Gi 1/21"
"Gi 1/22"
"Gi 1/23"
"Gi 1/24"
"10G 1/1"
"10G 1/2"
"10G 1/3"
"10G 1/4"
"Gi 1/25"
)

# Pick correct port (subtract 1 because arrays are 0-based)
port_name="${ports[$((port_num-1))]}"

# Output file name
fname="request.jsonl"

# Shutdown true if power_mode=1, false if 0
if [[ "$power_mode" == "1" ]]; then
    shutdown="false"
else
    shutdown="true"
fi

# Create JSON
jq -n --arg port "$port_name" --argjson shutdown "$shutdown" \
   '{method:"port.config.set", params:[$port, {Shutdown:$shutdown}], id:1}' \
   > "$fname"

if [[ "$port_num" == $MANAGEMENT_PORT ]]; then
  echo "Warning, do not modify the management port power mode"
  echo "If you really want to turn of the management port, type:"
  echo "     gs-rpc post -f $fname"
else
  gs-rpc post -f $fname
fi
