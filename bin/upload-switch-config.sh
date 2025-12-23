#!/usr/bin/env bash
# upload-switch-config.sh - Upload config file to switch via HTTP
#
# Usage:
#   ./upload-switch-config.sh [OPTIONS] <local-file> <switch-url> [remote-name] [merge]
#
# Arguments:
#   local-file    Local file to upload
#   switch-url    Switch URL (e.g., http://192.168.1.10 or http://192.168.1.10:8080)
#   remote-name   Optional: Destination filename (default: basename of local-file)
#   merge         Optional: true|false (default: false, only applies to running-config)
#
# Options:
#   -c, --creds USER:PASS    Credentials (default: admin:)
#   -h, --help               Show this help
#
# Examples:
#   # Upload to /switch/icfg/ with same name
#   ./upload-switch-config.sh config.txt http://192.168.1.10
#
#   # Upload to running-config with merge
#   ./upload-switch-config.sh config.txt http://192.168.1.10 running-config true
#
#   # Upload with custom credentials
#   ./upload-switch-config.sh -c admin:mypass config.txt http://192.168.1.10
#
#   # Upload with different name
#   ./upload-switch-config.sh local.txt http://192.168.1.10 switch-config.txt
#
# Notes:
#   - flash:filename refers to /switch/icfg/filename
#   - running-config is special - activates immediately after upload

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
Usage: upload-switch-config.sh [OPTIONS] <local-file> <switch-url> [remote-name] [merge]

Arguments:
  local-file    Local file to upload
  switch-url    Switch URL (e.g., http://192.168.1.10 or http://192.168.1.10:8080)
  remote-name   Optional: Destination filename (default: basename of local-file)
  merge         Optional: true|false (default: false)
                NOTE: merge only applies when remote-name is "running-config"

Options:
  -c, --creds USER:PASS    Credentials (default: admin:)
  -h, --help               Show this help

Examples:
  # Upload config as new file
  ./upload-switch-config.sh myconfig.txt http://192.168.1.10

  # Upload and merge into running-config
  ./upload-switch-config.sh changes.txt http://192.168.1.10 running-config true

  # Upload with custom credentials
  ./upload-switch-config.sh -c admin:mypass config.txt http://192.168.1.10

  # Upload and replace running-config
  ./upload-switch-config.sh newconfig.txt http://192.168.1.10 running-config false

Notes:
  - Files are uploaded to /switch/icfg/ directory on switch
  - "flash:filename" in iCLI refers to /switch/icfg/filename
  - If remote-name is "running-config", config is automatically activated
  - For other files, use: copy flash:filename running-config
  - Credentials default to admin with empty password (admin:)
EOF
    exit 0
}

# Default credentials
USERNAME="admin"
PASSWORD=""

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
CREDS="${USERNAME}:${PASSWORD}"

# Parse positional arguments
if [[ $# -lt 2 ]]; then
    error "Missing required arguments"
    echo ""
    show_help
fi

LOCAL_FILE="$1"
LOCAL_BASE_FILE=$(basename "$LOCAL_FILE")
SWITCH_URL="$2"
REMOTE_NAME="${3:-$LOCAL_BASE_FILE}"
MERGE="${4:-false}"

# Validate local file
if [[ ! -f "$LOCAL_FILE" ]]; then
    error "Local file not found: $LOCAL_FILE"
    exit 1
fi

# Validate merge parameter
if [[ "$MERGE" != "true" && "$MERGE" != "false" ]]; then
    error "merge must be 'true' or 'false', got: $MERGE"
    exit 1
fi

# Warn if merge is used with non-running-config
if [[ "$MERGE" == "true" && "$REMOTE_NAME" != "running-config" ]]; then
    warn "merge=true only applies to 'running-config', will be ignored for '$REMOTE_NAME'"
fi

# Remove trailing slash from URL
SWITCH_URL="${SWITCH_URL%/}"

# Build endpoint URL
UPLOAD_ENDPOINT="${SWITCH_URL}/config/icfg_conf_upload"
ACTIVATE_ENDPOINT="${SWITCH_URL}/config/icfg_conf_activate"

# Create temporary cookie file
COOKIES=$(mktemp)
trap "rm -f '$COOKIES'" EXIT

info "Uploading '${LOCAL_FILE}' to ${SWITCH_URL}"
if [[ "$REMOTE_NAME" == "running-config" ]]; then
    info "Mode: merge=${MERGE}"
    info "Destination: live running-config"
else
    info "Destination: /switch/icfg/${REMOTE_NAME}"
fi

# Execute upload - notes:
# 1. Argument order is IMPORTANT
# 2. Web UI always sets file_name same as new_file_name (not file_name=${LOCAL_BASE_FILE})
#    (effectively, new_file_name is ignored)
set +e
UPLOAD_RESPONSE=$(curl -u "${USERNAME}:${PASSWORD}" -X POST \
    -F "file_name=${REMOTE_NAME}" \
    -F "merge=${MERGE}" \
    -F "source_file=@${LOCAL_FILE};type=application/octet-stream" \
    -F "file_name_radio=" \
    -F "new_file_name=${REMOTE_NAME}" \
    -c "$COOKIES" -b "$COOKIES" \
    "${UPLOAD_ENDPOINT}" \
    --silent --show-error 2>&1)
CURL_EXIT=$?
set -e

# Check for curl failure
if [[ $CURL_EXIT -ne 0 ]]; then
    error "Upload failed (curl error $CURL_EXIT)"
    echo ""
    echo "$UPLOAD_RESPONSE"
    echo ""
    echo "Check endpoint: ${UPLOAD_ENDPOINT}"
    exit 1
fi

# Check if response is HTML (server returned error page instead of success)
if [[ "$UPLOAD_RESPONSE" =~ ^[[:space:]]*\< ]]; then
    error "Upload failed (server returned error)"
    echo ""
    echo "$UPLOAD_RESPONSE"
    echo ""
    echo "Check parameters and switch URL: ${SWITCH_URL}"
    exit 1
fi

info "Upload successful!"

# If filename is "running-config", activate it
if [[ "$REMOTE_NAME" == "running-config" ]]; then
    info "Activating configuration..."

    # Poll activation endpoint (it's async, may take several seconds)
    MAX_ATTEMPTS=10
    ATTEMPT=1
    STATUS=""

    while [[ $ATTEMPT -le $MAX_ATTEMPTS ]]; do
	set +e
        RESPONSE=$(curl -u "${USERNAME}:${PASSWORD}" \
            -b "$COOKIES" \
            "${ACTIVATE_ENDPOINT}" \
            --max-time 10 \
            --silent --show-error 2>&1)
	CURL_EXIT=$?
	set -e

        # Check for curl errors (like timeout/empty reply)
        if [[ $CURL_EXIT -ne 0 ]]; then
            if [[ $ATTEMPT -eq $MAX_ATTEMPTS ]]; then
                warn "Activation status check failed after $MAX_ATTEMPTS attempts"
                echo "Last error: $RESPONSE"
                echo ""
                info "Config may still be applying."
                break
            fi
            warn "Attempt $ATTEMPT/$MAX_ATTEMPTS: Waiting for activation to complete..."
            ((ATTEMPT++))
            continue
        fi

        STATUS=$(echo "$RESPONSE" | head -1)
        OUTPUT=$(echo "$RESPONSE" | tail -n +2)

        case "$STATUS" in
            DONE)
                info "Configuration activated successfully!"
                if [[ -n "$OUTPUT" && "$OUTPUT" != "(No output was generated.)" ]]; then
                    echo ""
                    echo "Output:"
                    echo "$OUTPUT"
                fi
                break
                ;;
            RUN)
                if [[ $ATTEMPT -eq $MAX_ATTEMPTS ]]; then
                    warn "Activation still in progress after $MAX_ATTEMPTS attempts"
                    echo ""
                    info "Check status later with:"
                    echo "  curl -u ${CREDS} -b cookies.txt ${ACTIVATE_ENDPOINT}"
                    break
                fi
                info "Attempt $ATTEMPT/$MAX_ATTEMPTS: Activation in progress..."
                sleep 2
                ((ATTEMPT++))
                continue
                ;;
            ERR)
                error "Activation completed with errors!"
                echo ""
                echo "Output:"
                echo "$OUTPUT"
                exit 1
                ;;
            SYNERR)
                error "Syntax check failed - configuration NOT activated!"
                echo ""
                echo "Output:"
                echo "$OUTPUT"
                exit 1
                ;;
            IDLE)
                warn "No activation started"
                info "This shouldn't happen - upload may have failed"
                break
                ;;
            *)
                if [[ $ATTEMPT -eq $MAX_ATTEMPTS ]]; then
                    warn "Unknown status after $MAX_ATTEMPTS attempts: $STATUS"
                    echo "Response:"
                    echo "$RESPONSE"
                    break
                fi
                warn "Attempt $ATTEMPT/$MAX_ATTEMPTS: Unknown status, retrying..."
                sleep 2
                ((ATTEMPT++))
                continue
                ;;
        esac
    done

    echo ""
    info "To verify changes:"
    echo "  use script: download-switch-config.sh"
    echo "or:"
    echo "  ssh ${USERNAME}@switch"
    echo "  show running-config"
    echo ""
    info "To set as startup config (persist after reboot):"
    echo "  copy running-config startup-config"
else
    # Regular file upload
    echo ""
    info "File uploaded to: /switch/icfg/${REMOTE_NAME}"
    echo ""
    echo "To apply this config:"
    echo "  # From iCLI (merge into running-config):"
    echo "  copy flash:${REMOTE_NAME} running-config"
    echo ""
    echo "  # From iCLI (replace startup-config + reload):"
    echo "  copy flash:${REMOTE_NAME} startup-config"
    echo "  reload cold"
fi

exit 0
