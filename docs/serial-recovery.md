# Emergency Config Restore via Serial Console

When the switch network is misconfigured but you have serial console access, use this guide to restore a working configuration.

## When to Use This

**Use serial config restore when:**
- ❌ Network is misconfigured (can't access switch remotely)
- ✅ You have serial console access
- ✅ You have a backup config file

**Don't use this when:**
- ✅ Network is working (use HTTP upload or TFTP instead - faster and more straightforward)
- See [file-transfers.md](file-transfers.md) for network-based methods

## Quick Start

**Restore config via serial with default credentials (admin, empty password):**
```bash
serial-config-restore.exp /dev/ttyUSB0 backup-config.txt
```

**With custom credentials:**
```bash
serial-config-restore.exp /dev/ttyUSB0 backup-config.txt myuser mypassword
```

The script will:
1. Connect to serial console
2. Login to icli with provided credentials
3. Copy config to `/switch/icfg/startup-config`
4. Prompt you to reload

## Prerequisites

- Serial console cable connected
- Backup config file
- `expect` installed (`sudo apt install expect`)
- Serial device permissions (`sudo usermod -a -G dialout $USER`)

## Usage

```bash
serial-config-restore.exp <serial-device> <config-file> [username] [password]
```

**Arguments:**
- `serial-device` - Serial port (e.g., `/dev/ttyUSB0`)
- `config-file` - Path to backup config file
- `username` - Optional username (default: `admin`)
- `password` - Optional password (default: empty string)

**Examples:**
```bash
# Default credentials (admin with empty password)
serial-config-restore.exp /dev/ttyUSB0 switch-backup.txt

# Custom username, empty password
serial-config-restore.exp /dev/ttyUSB0 switch-backup.txt myuser

# Custom username and password
serial-config-restore.exp /dev/ttyUSB0 switch-backup.txt myuser mypassword
```

## What It Does

1. **Connects** to serial console (115200 baud)
2. **Logs in** to iCLI (admin with empty password)
3. **Enters shell** with `debug system shell`
4. **Transfers config** to `/switch/icfg/startup-config`
5. **Prompts** to reload switch

## After Restore

Once config is transferred:

**Option 1: Reload immediately**
```
Reload switch now? (y/n): y
```
Switch reboots with new config

**Option 2: Verify first**
```
Reload switch now? (y/n): n
```
Then manually:
```bash
show startup-config  # Verify it looks correct
reload cold          # Apply new config
```

## Finding Your Serial Device

```bash
# List serial devices
ls -l /dev/ttyUSB* /dev/ttyACM*

# Common devices:
/dev/ttyUSB0  # USB-to-serial adapter
/dev/ttyACM0  # Built-in USB serial
```

## Troubleshooting

### Permission Denied

```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER

# Log out and back in, or:
sudo serial-config-restore.exp /dev/ttyUSB0 config.txt
```

### Device Not Found

```bash
# Check if device exists
ls -l /dev/ttyUSB*

# Check dmesg for USB serial devices
dmesg | grep -i tty
```

### Transfer Seems Slow

This is normal! Serial transfers are slow (~1KB/sec). A typical config takes:
- 10KB config → ~10 seconds
- 50KB config → ~50 seconds

Network methods are 100x faster - use them when possible!

### Config Not Applied After Reload

**Check if file was written:**
```bash
# From iCLI
show file /switch/icfg/startup-config

# From shell
debug system shell
ls -lh /switch/icfg/startup-config
cat /switch/icfg/startup-config
exit
```

**Verify it's the right file:**
```bash
show startup-config
# Should show your backup config contents
```

## Alternative: Manual Serial Paste (Small Configs Only)

For **very small configs** (<1KB), you can manually paste:

```bash
# Connect to serial
microcom -s 115200 -p /dev/ttyUSB0

# Login
Username: admin
Password: [Enter]

# Enable debug mode
platform debug allow

# Enter shell
debug system shell

# Start writing config
cat > /switch/icfg/startup-config
[Paste config content from clipboard]
[Press Ctrl-D when done]

# Verify
cat /switch/icfg/startup-config

# Exit shell
exit

# Reload
reload cold
```

**Warning:** Manual paste can lose data on large configs. Use the script for anything >1KB!

## See Also

- [file-transfers.md](file-transfers.md) - Network-based transfer methods (preferred when network works)
- [scripting-with-expect.md](scripting-with-expect.md) - Learn expect scripting
- Helper script: `../bin/serial-config-restore.exp`
