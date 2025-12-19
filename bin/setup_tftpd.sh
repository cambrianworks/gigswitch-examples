#!/bin/bash
# setup_tftpd.sh - Helper script to set up TFTP server for GigSwitch file transfers
#
# Usage:
#   ./setup_tftpd.sh [port] [directory]
#
# Examples:
#   ./setup_tftpd.sh                    # Use defaults (port 6069, ~/tftp-files)
#   ./setup_tftpd.sh 69                 # Standard TFTP port
#   ./setup_tftpd.sh 6069 /tmp/tftp     # Custom port and directory

set -e

# Show help if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << 'EOF'
setup_tftpd.sh - TFTP Server Setup Helper for GigSwitch

USAGE:
    ./setup_tftpd.sh [port] [directory]

ARGUMENTS:
    port        TFTP server port (default: 6069)
    directory   Directory to serve files from (default: /tmp/tftp-files)

EXAMPLES:
    # Use defaults (port 6069, /tmp/tftp-files)
    ./setup_tftpd.sh

    # Use standard TFTP port
    ./setup_tftpd.sh 69

    # Custom port and directory
    ./setup_tftpd.sh 6069 /tmp/tftp

DESCRIPTION:
    This script sets up a TFTP server for transferring files to/from
    GigSwitch devices. It will:
    
    - Create the TFTP directory if needed
    - Set appropriate permissions
    - Kill any existing TFTP server on the port
    - Start a new TFTP server with upload support (--create)
    - Display usage examples for the switch
    
    For non-privileged ports (>=1024), the server runs as your user,
    avoiding permission issues with home directories.
    
    For privileged ports (<1024), the server runs as 'tftp' user
    and requires sudo.

ENVIRONMENT:
    TFTP_USER   User to run TFTP server as (default: tftp)

REQUIREMENTS:
    - tftpd-hpa package installed (sudo apt install tftpd-hpa)
    - sudo access for starting the server

EOF
    exit 0
fi

# Default configuration
DEFAULT_PORT=6069
# Use /tmp for default since tftp user can access it
DEFAULT_DIR="/tmp/tftp-files"
TFTP_USER="${TFTP_USER:-tftp}"

# Parse arguments
PORT="${1:-$DEFAULT_PORT}"
TFTP_DIR="${2:-$DEFAULT_DIR}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Linux
if [[ "$(uname)" != "Linux" ]]; then
    error "This script is designed for Linux systems"
    exit 1
fi

# Check if tftpd is installed
if ! command -v /usr/sbin/in.tftpd &> /dev/null; then
    error "TFTP server not installed"
    echo ""
    echo "Install with:"
    echo "  sudo apt install tftpd-hpa    # Debian/Ubuntu"
    echo "  sudo yum install tftp-server  # RHEL/CentOS"
    exit 1
fi

# Create TFTP directory if it doesn't exist
if [[ ! -d "$TFTP_DIR" ]]; then
    info "Creating TFTP directory: $TFTP_DIR"
    mkdir -p "$TFTP_DIR"
fi

# Set permissions
info "Setting permissions on $TFTP_DIR"

# Set permissions first (while we still own it)
chmod 755 "$TFTP_DIR" 2>/dev/null || sudo chmod 755 "$TFTP_DIR"

# For non-privileged ports (>1024), we can run as current user
# For privileged ports (<1024), we need to use tftp user
if [[ $PORT -lt 1024 ]]; then
    # Privileged port - use tftp user
    if id "$TFTP_USER" &>/dev/null; then
        if sudo chown "$TFTP_USER:$TFTP_USER" "$TFTP_DIR" 2>/dev/null; then
            info "Set ownership to $TFTP_USER:$TFTP_USER (privileged port)"
            USE_TFTP_USER="$TFTP_USER"
        else
            error "Cannot set ownership to $TFTP_USER for privileged port $PORT"
            exit 1
        fi
    else
        error "TFTP user '$TFTP_USER' does not exist (needed for privileged port)"
        exit 1
    fi
else
    # Non-privileged port - can use current user
    warn "Using current user ($USER) since port $PORT is non-privileged"
    info "This avoids permission issues with home directories"
    USE_TFTP_USER="$USER"
fi

# Kill any existing TFTP server on this port
info "Checking for existing TFTP server on port $PORT..."

# Try multiple methods to find existing processes
EXISTING_PIDS=""

# Method 1: lsof on the port
EXISTING_PIDS=$(sudo lsof -i UDP:${PORT} -t 2>/dev/null)

# Method 2: search ps for in.tftpd with this port
if [[ -z "$EXISTING_PIDS" ]]; then
    EXISTING_PIDS=$(ps aux | grep "[i]n.tftpd.*:${PORT}" | awk '{print $2}')
fi

if [[ -n "$EXISTING_PIDS" ]]; then
    warn "Found existing TFTP server(s) on port $PORT:"
    ps -p $EXISTING_PIDS 2>/dev/null || true
    warn "Stopping existing TFTP server(s)..."
    
    for pid in $EXISTING_PIDS; do
        sudo kill $pid 2>/dev/null || kill $pid 2>/dev/null || true
    done
    
    sleep 1
    
    # Force kill if still running
    for pid in $EXISTING_PIDS; do
        if ps -p $pid > /dev/null 2>&1; then
            warn "Force killing PID $pid"
            sudo kill -9 $pid 2>/dev/null || kill -9 $pid 2>/dev/null || true
        fi
    done
    
    sleep 1
fi

# Start TFTP server
info "Starting TFTP server..."
info "  Port: $PORT"
info "  Directory: $TFTP_DIR"
info "  User: $USE_TFTP_USER"

if [[ "$USE_TFTP_USER" == "$USER" && $PORT -ge 1024 ]]; then
    # Non-privileged port, run as current user (no sudo needed)
    /usr/sbin/in.tftpd --listen --user "$USE_TFTP_USER" \
         --address :${PORT} --create --secure "$TFTP_DIR" &
else
    # Privileged port or tftp user - need sudo
    sudo /usr/sbin/in.tftpd --listen --user "$USE_TFTP_USER" \
         --address :${PORT} --create --secure "$TFTP_DIR" &
fi

# Wait for server to start and bind port
sleep 2

# Find the actual TFTP server PID
# Try multiple methods since UDP ports don't always show up immediately
TFTP_PID=""

# Method 1: Try lsof on the UDP port
TFTP_PID=$(sudo lsof -i UDP:${PORT} -t 2>/dev/null | head -1)

# Method 2: If that didn't work, search ps for the process
if [[ -z "$TFTP_PID" ]]; then
    TFTP_PID=$(ps aux | grep "[i]n.tftpd.*:${PORT}" | awk '{print $2}' | head -1)
fi

# Method 3: Just look for any in.tftpd with our directory
if [[ -z "$TFTP_PID" ]]; then
    TFTP_PID=$(ps aux | grep "[i]n.tftpd.*${TFTP_DIR}" | awk '{print $2}' | head -1)
fi

# Verify it's actually running
if [[ -n "$TFTP_PID" ]] && ps -p $TFTP_PID > /dev/null 2>&1; then
    info "TFTP server started successfully (PID: $TFTP_PID)"
else
    error "Failed to start TFTP server"
    echo ""
    echo "Possible issues:"
    echo "  - Port $PORT already in use"
    echo "  - TFTP directory not accessible: $TFTP_DIR"
    if [[ "$USE_TFTP_USER" == "tftp" ]]; then
        echo "  - tftp user can't access $TFTP_DIR (try using /tmp or /srv)"
    fi
    echo ""
    echo "Check manually:"
    echo "  ps aux | grep in.tftpd"
    echo "  sudo lsof -i UDP:${PORT}"
    echo ""
    echo "Check system logs:"
    echo "  sudo journalctl -u tftpd-hpa -n 20"
    exit 1
fi

# Get local IP addresses
info "Server is listening on the following addresses:"
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | while read ip; do
    echo "  - $ip:$PORT"
done

# Show usage examples
echo ""
echo -e "${GREEN}TFTP server is ready!${NC}"
echo ""
echo "Usage examples from GigSwitch:"
echo ""
echo "  # Enter shell from iCLI"
echo "  debug system shell"
echo ""
echo "  # Upload file from switch to TFTP server"
echo "  tftp -p -l /switch/trace-conf -r trace-conf <SERVER_IP> $PORT"
echo ""
echo "  # Download file from TFTP server to switch"
echo "  tftp -g -l /tmp/config.txt -r config.txt <SERVER_IP> $PORT"
echo ""
echo "  # Exit shell"
echo "  exit"
echo ""
echo "Files will be stored in: $TFTP_DIR"
echo ""
echo "To stop the server:"
echo "  sudo kill $TFTP_PID"
echo ""

# Create a PID file for easy management
echo $TFTP_PID > /tmp/tftpd-gigswitch.pid
info "PID file created: /tmp/tftpd-gigswitch.pid"

# Show directory listing
if [[ -n "$(ls -A "$TFTP_DIR" 2>/dev/null)" ]]; then
    echo "Current files in TFTP directory:"
    ls -lh "$TFTP_DIR"
else
    info "TFTP directory is empty"
fi
