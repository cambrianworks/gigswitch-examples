# Scripting with Expect

This guide covers automating switch interactions using expect scripts, both over serial console and SSH.

## Table of Contents

- [Overview](#overview)
- [Installing Expect](#installing-expect)
- [Basic Expect Concepts](#basic-expect-concepts)
- [Simple Examples](#simple-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

**Why use expect?**
- Automate repetitive iCLI tasks over SSH or serial
- Capture debug output reliably
- Handle login sequences automatically
- Save output to files

**When to use expect:**
- ✅ Capturing debug traces (especially over serial)
- ✅ Automating configuration tasks
- ✅ Running tests that require iCLI access
- ✅ Grabbing running config programmatically

**When NOT to use expect:**
- ❌ Simple one-off commands (just use terminal)
- ❌ Tasks that can be done via available APIs (use API directly)

**Connection Methods:**
- **SSH**: Use `spawn ssh admin@hostname` - Good for remote automation
- **Serial**: Use `spawn microcom -s 115200 -p /dev/ttyUSB0` - Required for network issues

## Installing Expect

### Debian/Ubuntu

```bash
sudo apt install expect
```

### Verify Installation

```bash
which expect
expect -v
```

Should show: `expect version 5.x`

## Basic Expect Concepts

### Script Structure

**SSH connection:**
```bash
#!/usr/bin/expect -f

set timeout 30
spawn ssh admin@192.168.1.10

expect "Password:"
send "\r"

expect "#"
send "show version\r"

expect "#"
send "exit\r"

expect eof
```

**Serial connection:**
```bash
#!/usr/bin/expect -f

set timeout 30
spawn microcom -s 115200 -p /dev/ttyUSB0

sleep 2
send "\r"

expect "Username:"
send "admin\r"

expect "Password:"
send "\r"

expect "#"
send "show running-config\r"

expect "#"
send "exit\r"

expect eof
```

### Key Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `spawn` | Start a program | `spawn ssh admin@switch` |
| `expect` | Wait for pattern | `expect "Password:"` |
| `send` | Send text | `send "admin\r"` |
| `sleep` | Delay (seconds) | `sleep 2` |
| `after` | Delay (milliseconds) | `after 1000` |
| `set` | Variables | `set username "admin"` |
| `interact` | Hand control to user | `interact` |

### Pattern Matching

**Simple string:**
```bash
expect "Username:"
```

**Regex:**
```bash
expect -re "#\\s*$"  # Match # at end of line
```

**Multiple patterns:**
```bash
expect {
    "Username:" { send "admin\r" }
    "Password:" { send "\r" }
    timeout {
        puts "Timeout!"
        exit 1
    }
}
```

**Wait for prompt with timeout:**
```bash
expect {
    "#" { 
        # Got prompt, wait for output to settle
        sleep 0.5
    }
    timeout {
        puts "Timeout!"
        exit 1
    }
}
```

## Simple Examples

### Example 1: Grab Running Config via SSH

This is what `gs-grab-running-config` roughly does:

```bash
#!/usr/bin/expect -f

set timeout 30

spawn ssh admin@192.168.1.10

expect "Password:"
send "\r"

expect "#"

# Disable paging
send "terminal length 0\r"
expect "#"

# Capture config
send "show running-config\r"

# Wait for output to finish
set timeout 10
expect "#"

send "exit\r"
expect eof
```

### Example 2: Simple Debug Trace Capture via Serial

```bash
#!/usr/bin/expect -f

set timeout 30

spawn microcom -s 115200 -p /dev/ttyUSB0

# Login
sleep 2
send "\r"
expect "Username:"; send "admin\r"
expect "Password:"; send "\r"
expect "#"

# Setup
send "terminal length 0\r"
expect "#"

send "platform debug allow\r"
expect "#"

# Capture traces
send "debug trace ringbuffer print\r"

# Wait for output
set timeout 10
expect "#"

send "exit\r"
expect eof
```

Save output: `./capture.exp > traces.log 2>&1`

### Example 3: Interactive Mode After Setup

```bash
#!/usr/bin/expect -f

set timeout 30

spawn ssh admin@192.168.1.10

expect "Password:"
send "\r"

expect "#"

# Do automated setup
send "terminal length 0\r"
expect "#"

send "platform debug allow\r"
expect "#"

# Hand control to user
puts "\n=== Setup complete, now interactive ===\n"

interact
```

### Example 4: Apply Commands from File

```bash
#!/usr/bin/expect -f

if {[llength $argv] < 2} {
    puts "Usage: $argv0 <switch-ip> <commands-file>"
    exit 1
}

set switch [lindex $argv 0]
set cmdfile [lindex $argv 1]

set timeout 30

spawn ssh admin@$switch

expect "Password:"
send "\r"

expect "#"

# Read and send each command
set fp [open $cmdfile r]
while {[gets $fp line] >= 0} {
    send "$line\r"
    expect "#"
    sleep 0.5
}
close $fp

send "exit\r"
expect eof
```

**Usage:**
```bash
./apply-commands.exp 192.168.1.10 commands.txt
```

## Best Practices

### 1. Always Set Timeouts

```bash
set timeout 30  # Global default

# Or per-command
expect -timeout 60 "#"
```

### 2. Use Proper Line Endings

```bash
# Correct - use \r for serial/terminal
send "command\r"

# Wrong - \n doesn't work on serial
send "command\n"
```

### 3. Wait for Prompt After Commands

```bash
send "show version\r"
expect "#"
sleep 0.5  # Let output settle
```

### 4. Add Delays for Serial Stability

```bash
spawn microcom -s 115200 -p /dev/ttyUSB0
sleep 2  # Let port stabilize
send "\r"
```

### 5. Handle Multiple Outcomes

```bash
expect {
    "Password:" { send "\r" }
    "already logged in" { }
    timeout {
        puts "ERROR: Timeout"
        exit 1
    }
}
```

### 6. Use Variables for Reusability

```bash
set username "admin"
set password ""
set switch "192.168.1.10"

spawn ssh $username@$switch
expect "Password:"
send "$password\r"
```

## Troubleshooting

### Script Hangs on expect

**Debug with:**
```bash
#!/usr/bin/expect -f

exp_internal 1  # Enable debug output

spawn ssh admin@switch
expect "Username:"
```

Shows exactly what expect is matching.

### Characters Get Scrambled

**Cause**: Sending too fast

**Solution**: Add delays
```bash
foreach line $commands {
    send "$line\r"
    after 100  # 100ms delay
}
```

### Can't Find Serial Device

```bash
# Find devices
ls -l /dev/ttyUSB* /dev/ttyACM*

# Fix permissions
sudo usermod -a -G dialout $USER
# Log out and back in
```

### Output Cut Off

**Increase timeout:**
```bash
set timeout 60
send "debug trace ringbuffer print\r"
expect "#"
```

## Complex Examples

For more complex scripting patterns, see the actual scripts in `../bin/`:

- **`gs-grab-running-config`** - Grab running config via SSH
- **`debug_trace_capture.exp`** - Advanced debug trace capture with login state detection
- **`serial-config-restore.exp`** - Restore config via serial console

These show advanced techniques like:
- Robust state detection
- Multi-file logging
- Error handling
- Conditional logic based on output

## See Also

- [debugging.md](debugging.md) - What debug traces to capture
- [file-transfers.md](file-transfers.md) - Transferring files
- [serial-recovery.md](serial-recovery.md) - Emergency config recovery
- Helper scripts in `../bin/` directory
