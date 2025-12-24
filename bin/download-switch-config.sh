#!/bin/bash
# download-switch-config.sh - Download config file from switch
#
# Usage:
#   ./download-switch-config.sh [OPTIONS] <switch-url> <remote-file> [local-file]
#
# Arguments:
#   switch-url    Switch URL (e.g., http://192.168.1.10 or http://192.168.1.10:8080)
#   remote-file   Config file on switch (e.g., startup-config, running-config)
#   local-file    Optional: Local filename (default: same as remote-file)
#
# Options:
#   -c, --creds USER:PASS    Credentials (default: admin:)
#   -l, --list               List available files on switch
#   -h, --help               Show this help

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    cat << 'EOF'
Usage: download-switch-config.sh [OPTIONS] <switch-url> <remote-file> [local-file]

Arguments:
  switch-url    Switch URL (e.g., http://192.168.1.10 or http://192.168.1.10:8080)
  remote-file   Config file on switch (e.g., startup-config, running-config)
  local-file    Optional: Local filename (default: same as remote-file)

Options:
  -c, --creds USER:PASS    Credentials (default: admin:)
  -l, --list               List available files on switch
  -h, --help               Show this help

Examples:
  # List files on switch
  ./download-switch-config.sh --list http://192.168.1.10

  # Download startup-config (saves as startup-config locally)
  ./download-switch-config.sh http://192.168.1.10 startup-config

  # Download and rename locally
  ./download-switch-config.sh http://192.168.1.10 startup-config backup.txt

  # With custom credentials
  ./download-switch-config.sh -c admin:mypass http://192.168.1.10 startup-config

  # Download to stdout
  ./download-switch-config.sh http://192.168.1.10 startup-config -

Notes:
  - Downloads from /switch/icfg/ directory on switch
  - "flash:filename" in iCLI refers to /switch/icfg/filename
  - Common files: startup-config, running-config, default-config
  - Use --list to see all available files
EOF
    exit 0
}

# Default credentials
USERNAME="admin"
PASSWORD=""
DO_LIST=false

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--creds)
            if [[ -z "$2" || "$2" == -* ]]; then
                error "Option $1 requires an argument (USER:PASS)"
                exit 1
            fi
            CREDS="$2"
            if [[ "$CREDS" =~ ^([^:]+):(.*)$ ]]; then
                USERNAME="${BASH_REMATCH[1]}"
                PASSWORD="${BASH_REMATCH[2]}"
            else
                error "Credentials must be in format USER:PASS, got: $CREDS"
                exit 1
            fi
            shift 2
            ;;
        -l|--list)
            DO_LIST=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        -*)
            error "Unknown option: $1"
            show_help
            ;;
        *)
            break
            ;;
    esac
done

# Parse positional arguments
if [[ $DO_LIST == true ]]; then
    # List mode - only need switch URL
    if [[ $# -lt 1 ]]; then
        error "Missing switch URL"
        show_help
    fi
    SWITCH_URL="$1"
else
    # Download mode - need switch URL and remote file
    if [[ $# -lt 2 ]]; then
        error "Missing required arguments"
        echo ""
        show_help
    fi
    SWITCH_URL="$1"
    REMOTE_FILE="$2"
    LOCAL_FILE="${3:-$REMOTE_FILE}"  # Default: same name
fi

# Remove trailing slash from URL
SWITCH_URL="${SWITCH_URL%/}"

# List mode
if [[ $DO_LIST == true ]]; then
    info "Listing files on ${SWITCH_URL}..."
    
    RESPONSE=$(curl -u "${USERNAME}:${PASSWORD}" \
        "${SWITCH_URL}/config/icfg_conf_get_file_list?op=upload" \
        --silent --show-error --fail)
    
    STATUS=$(echo "$RESPONSE" | cut -d'*' -f1)
    
    if [[ "$STATUS" == "OK" ]]; then
        echo ""
        echo "Available files in /switch/icfg/ (flash:):"
        echo "$RESPONSE" | tr '*' '\n' | tail -n +2 | while read -r file; do
            if [[ -n "$file" ]]; then
                echo "  - $file"
            fi
        done
        echo ""
        info "Download with: ./download-switch-config.sh ${SWITCH_URL} <filename>"
    else
        error "Failed to list files: $STATUS"
        exit 1
    fi
    exit 0
fi

# Download mode
info "Downloading '${REMOTE_FILE}' from ${SWITCH_URL}"

# Build endpoint URL
ENDPOINT="${SWITCH_URL}/config/icfg_conf_download"

# Download
if [[ "$LOCAL_FILE" == "-" ]]; then
    # To stdout
    if curl -u "${USERNAME}:${PASSWORD}" -X POST \
        --data-urlencode "file_name=${REMOTE_FILE}" \
        -L "${ENDPOINT}" \
        --fail --silent --show-error; then
        exit 0
    else
        error "Download failed!" >&2
        exit 1
    fi
else
    # To file
    if curl -u "${USERNAME}:${PASSWORD}" -X POST \
        --data-urlencode "file_name=${REMOTE_FILE}" \
        -L "${ENDPOINT}" \
        -o "${LOCAL_FILE}" \
        --fail --silent --show-error; then
        
        FILE_SIZE=$(du -h "$LOCAL_FILE" | cut -f1)
        LINE_COUNT=$(wc -l < "$LOCAL_FILE" 2>/dev/null || echo "N/A")
        
        info "Download successful!"
        echo "  Remote: /switch/icfg/${REMOTE_FILE} (flash:${REMOTE_FILE})"
        echo "  Local:  ${LOCAL_FILE}"
        echo "  Size:   ${FILE_SIZE}"
        echo "  Lines:  ${LINE_COUNT}"
        exit 0
    else
        error "Download failed!"
        echo "  Check that file '${REMOTE_FILE}' exists on switch"
        echo "  Try: ./download-switch-config.sh --list ${SWITCH_URL}"
        exit 1
    fi
fi
