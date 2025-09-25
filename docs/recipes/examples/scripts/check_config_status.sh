#!/bin/bash
# Usage: ./check_config_status.sh

if [[ $# -ne 0 ]]; then
    echo "Usage: $0"
    exit 1
fi

# Output file name
fname="request.jsonl"

echo '{ "method": "icfg.status.copy.get", "params": [], "id": 99 }' > "$fname"

gs-rpc post -f $fname
