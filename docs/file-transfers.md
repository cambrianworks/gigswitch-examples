# File Transfers on GigSwitch

This guide covers methods for transferring files to and from the GigSwitch.

## Context Markers

Commands are marked with their execution context:
- **[Local]** - Your local machine / companion Pi  
- **[iCLI]** - Switch iCLI prompt (`#`)
- **[Shell]** - Linux shell on switch (after `debug system shell`)
- **[Web]** - Browser or curl to web interface

## Transfer Methods by Interface

### iCLI Transfer Options

**Command:** `copy`

The `copy` command supports TFTP and HTTP/HTTPS transfers.

`copy <src> <dest> [

**[iCLI] Full command help:**
```
# copy ?
    <url_file>        File in USB, FLASH or on remote server. Syntax:
                      <usb:filename> | <flash:filename> |
                      <protocol>://[<username>[:<password>]@]<host>[:<port>][/<path>]>.
                      A valid file name is a text string drawn from alphabet
                      (A-Za-z), digits (0-9), dot (.), hyphen (-), under score
                      (_). The maximum length is 63 and hyphen must not be
                      first character. The file name content that only contains
                      '.' is not allowed.
    running-config    Currently running configuration
    startup-config    Startup configuration

# copy <src> running-config syntax-check
    syntax-check    Perform syntax check on source configuration
** The copy will still take place unless the syntax-check fails.
   Without syntax-check, a partial copy could take place up to point of error.
```

**[iCLI] Examples:**
```bash
# Download config from TFTP server
copy tftp://{EXTERNAL_IP}/config.txt running-config syntax-check
copy tftp://{EXTERNAL_IP}:6069/config.txt flash:staged-config.txt

# Upload config to TFTP server
copy startup-config tftp://{EXTERNAL_IP}/backup.txt
copy flash:myconfig.txt tftp://{EXTERNAL_IP}:6069/backup.txt

# Try HTTP/HTTPS
copy http://{EXTERNAL_IP}:8000/config.txt running-config
copy https://{EXTERNAL_IP}/config.txt flash:staged-config.txt
```

**Notes:**
- `flash:filename` = `/switch/icfg/filename`
- `syntax-check` validates config before applying (recommended!)
- `copy ... running-config` MERGES into existing running-config
- For full replacement, use `copy ... startup-config` then `reload cold`

### Switch Shell Transfer Options

These commands run **in the Linux shell on the switch** after `debug system shell`.

#### TFTP (Bidirectional)

**[Shell] Command syntax:**
```bash
tftp [OPTIONS] <server_ip> [port]

Options:
  -g    Get file (download from server)
  -p    Put file (upload to server)
  -l    Local filename
  -r    Remote filename
```

**[Shell] Examples:**
```bash
# Download from TFTP server
tftp -g -l /switch/icfg/new-config.txt -r config.txt {EXTERNAL_IP}
tftp -g -l /tmp/firmware.bin -r firmware.bin {EXTERNAL_IP} 6069

# Upload to TFTP server
tftp -p -l /switch/icfg/crashfile -r crashfile.txt {EXTERNAL_IP}
tftp -p -l /switch/trace-conf -r trace-conf-backup.txt {EXTERNAL_IP} 6069
```

#### wget (Download Only)

**[Shell] Examples:**
```bash
# Download from HTTP server
wget http://{EXTERNAL_IP}:8000/myfile.txt -O /tmp/myfile.txt
wget http://{EXTERNAL_IP}:8000/config.txt -O /switch/icfg/staged-config.txt

# HTTPS (at custom port; allow self-signed certificate)
wget https://{EXTERNAL_IP}:8443/file.txt -O /tmp/file.txt --no-check-certificate
```

#### scp (Bidirectional)

**[Shell] Copy FROM switch TO remote host:**
```bash
# Upload files to remote SSH server
scp /switch/config/startup-config user@{EXTERNAL_IP}:/backups/config.txt
scp /switch/icfg/crashfile user@{EXTERNAL_IP}:/tmp/crashfile.txt
```

**[Shell] Copy FROM remote host TO switch:**
```bash
# Download files from remote SSH server
scp user@{EXTERNAL_IP}:/configs/new-config.txt /switch/icfg/staged-config.txt
scp user@{EXTERNAL_IP}:/firmware/update.bin /tmp/firmware.bin
```

**Note:** Switch must be able to reach the remote SSH server. The remote host must run an SSH server (sshd).

#### cat (Manual Paste)

**[Shell] For very small files (<1KB):**
```bash
# Start writing file
cat > /switch/icfg/small-config.txt
# Paste content from clipboard
# Press Ctrl-D when done

# Verify
cat /switch/icfg/small-config.txt
```

**Warning:** Manual paste can lose data on large files. Use TFTP, wget, HTTP download instead, or HTTP endpoints from Web UI or external curl.

### Web UI Transfer Options

Access the web interface at `http://{GS_IP}` or `https://{GS_IP}`.

**Upload:**
- Navigate to Maintenance → Configuration → Upload
- Select file from local machine
- Choose destination (special `running-config`, existing filename from list or custom filename)
- For `running-config`: choose Merge or Replace mode

**Download:**
- Navigate to Maintenance → Configuration → Download
- Select file to download (`startup-config`, `running-config`, etc.)
- File downloads to local machine

### External curl Transfer Options (HTTP Endpoints)

These run on your **local machine** using the switch's HTTP API.

For detailed HTTP workflow documentation, see [http-config-upload.md](http-config-upload.md).

**[Local] Upload config:**
```bash
# Using helper script
./bin/upload-switch-config.sh config.txt http://{GS_IP} running-config true
```

**[Local] Download config:**
```bash
# Using helper script
./bin/download-switch-config.sh http://{GS_IP} startup-config backup.txt

# List available files
./bin/download-switch-config.sh --list http://{GS_IP}
```

See [http-config-upload.md](http-config-upload.md) for:
- Two-step upload/activate workflow for `running-config`
- Cookie-based session management
- Status checking
- Complete examples

## Setting Up File Transfer Servers

### TFTP Server Setup

**[Local] Debian/Ubuntu:**
```bash
# Install
sudo apt install tftpd-hpa

# Create directory
sudo mkdir -p /srv/tftp
sudo chown tftp:tftp /srv/tftp
sudo chmod 755 /srv/tftp

# Start server
sudo systemctl start tftpd-hpa
sudo systemctl enable tftpd-hpa
```

**[Local] Custom port (6069):**
```bash
mkdir -p ~/tftp-files
chmod 755 ~/tftp-files

sudo /usr/sbin/in.tftpd --listen --user $USER --address :6069 \
     --create --secure ~/tftp-files
```

Helper script: `../bin/setup_tftpd.sh`

### HTTP Server Setup

**[Local] Python (simplest):**
```bash
# Create directory
mkdir -p ~/switch-files
cd ~/switch-files

# Start HTTP server
python3 -m http.server 8000
```

Files in `~/switch-files/` are now accessible at `http://{YOUR_IP}:8000/`

## Common Workflows

### Deploy Config via HTTP

**[Local] Upload and apply (merge):**
```bash
./bin/upload-switch-config.sh config.txt http://{GS_IP} running-config true
```

**[iCLI] Verify and persist:**
```bash
show running-config
copy running-config startup-config

# optional - to reboot with new config
reload cold
```

### Deploy Config via TFTP (iCLI)

**[Local] Start TFTP server and copy file:**
```bash
./bin/setup_tftpd.sh 6069 ~/tftp-files
cp new-config.txt ~/tftp-files/
```

**[iCLI] Apply from switch:**
```bash
copy tftp://{EXTERNAL_IP}:6069/new-config.txt running-config syntax-check
copy running-config startup-config
```

### Deploy Config via TFTP (Shell)

**[iCLI] Enter shell:**
```bash
debug system shell
```

**[Shell] Download and stage:**
```bash
tftp -g -l /switch/icfg/new-config.txt -r config.txt {EXTERNAL_IP} 6069
exit
```

**[iCLI] Apply and persist:**
```bash
copy flash:new-config.txt running-config syntax-check
copy running-config startup-config
```

### Backup Configs

**[Local] Via HTTP:**
```bash
./bin/download-switch-config.sh http://{GS_IP} startup-config backup.txt
```

**[iCLI] Via TFTP:**
```bash
copy startup-config tftp://{EXTERNAL_IP}/backup.txt
```

**[Shell] Via SCP:**
```bash
debug system shell
scp /switch/config/startup-config user@{EXTERNAL_IP}:/backups/config.txt
exit
```

### Extract Debug Logs

**[iCLI] Capture trace ringbuffer to stdout:**
```bash
terminal length 0
debug trace ringbuffer print
# Copy output from terminal, or...
```

**[Shell] Copy debug file to external machine:**
```bash
debug system shell
# Manually redirect or use "script" to capture
# Then transfer via TFTP/SCP
tftp -p -l /switch/icfg/crashfile -r crashfile.txt {EXTERNAL_IP}
scp /switch/icfg/crashfile user@{EXTERNAL_IP}:/tmp/
exit
```

**[Local] Download via HTTP:**
```bash
# If you saved traces to /switch/icfg ("flash") first as "/switch/icfg/debug-output.txt"
./bin/download-switch-config.sh http://{GS_IP} debug-output.txt
```

## Emergency Recovery

### Serial Console (No Network)

When network is misconfigured and serial console is available:

**[Local] Restore config via serial:**
```bash
./bin/serial-config-restore.exp /dev/ttyUSB0 backup-config.txt
```

See [serial-recovery.md](serial-recovery.md) for details.

### U-Boot Recovery

If you need bootloader-level recovery, U-Boot provides these commands (verified from help):

```
loadx     - load binary file over serial line (xmodem mode)
loady     - load binary file over serial line (ymodem mode)  
loadb     - load binary file over serial line (kermit mode)
```

**Access U-Boot:**
1. Connect serial console (115200 baud, 8N1)
2. Power cycle switch
3. Press any key when "Hit any key to stop autoboot" appears
4. You'll see `=>` prompt

**Transfer speed:** Very slow (~1-3KB/sec). Only use for emergency firmware recovery. Consult U-Boot documentation for exact procedures.

## See Also

- [http-config-upload.md](http-config-upload.md) - Complete HTTP workflow
- [serial-recovery.md](serial-recovery.md) - Emergency recovery
- [debugging.md](debugging.md) - Debug trace capture
- Helper scripts in `../bin/`
