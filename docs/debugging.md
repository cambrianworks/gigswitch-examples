# Debug Logging on GigSwitch

This guide covers how to enable and capture debug traces from the switch.

## Quick Start

```bash
# 1. Enable platform debug
platform debug allow

# 2. Disable pagination
terminal length 0

# 3. Enable trace module
debug trace module ringbuffer main board enable

# 4. Set log level
debug trace module level main board info

# 5. Do your test/reproduce issue

# 6. View traces
debug trace ringbuffer print

# 7. Save configuration (persists across reboots)
debug trace configuration write
```

## Overview

The switch uses an in-memory ringbuffer for debug traces:

- **Ringbuffer**: Traces stored in RAM, circular buffer (old messages overwritten)
- **Not auto-printed**: Must explicitly print with `debug trace ringbuffer print`
- **Persistent config**: Saved to `/switch/trace-conf` (auto-loaded on boot)
- **Independent**: Not in `show running-config`

**Log levels** (least to most verbose):
```
error < warning < info < debug < noise < racket
```

## Essential Commands

```bash
# Platform debug (required first!)
platform debug allow

# Disable pagination
terminal length 0

# List available modules
debug trace module level

# Enable module to ringbuffer
debug trace module ringbuffer <module> <group> enable

# Set log level
debug trace module level <module> <group> <level>

# View traces
debug trace ringbuffer print

# View and clear
debug trace ringbuffer print clear

# Save config to /switch/trace-conf
debug trace configuration write
```

## Example: Enable Board Debug

```bash
# Enable and configure
platform debug allow
terminal length 0
debug trace module ringbuffer main board enable
debug trace module level main board info

# Do your test...

# View output
debug trace ringbuffer print

# Save settings
debug trace configuration write
```

## Persistence

**Trace config file:** `/switch/trace-conf`
- JSON format
- Auto-loaded on boot
- Created/updated by `debug trace configuration write`

**Verify persistence:**
```bash
# Save settings
debug trace configuration write

# Check file exists
debug system shell
ls -l /switch/trace-conf
exit

# Reboot
reload cold

# After boot, verify settings restored
debug trace module level
```

**Remove persistent debug:**
```bash
# Option 1: Disable modules and save
debug trace module ringbuffer main board disable
debug trace configuration write

# Option 2: Delete file and reboot
debug system shell
rm /switch/trace-conf
exit
reload cold
```

## Best Practices

### ⚠️ Don't Enable Too Much!

**Problem:** Too many modules at `debug` level can crash the switch (lock contention in trace system)

**Good:**
```bash
# Enable ONE module at debug level
debug trace module ringbuffer main board enable
debug trace module level main board info
```

**Bad:**
```bash
# Too many modules + debug level = crash!
debug trace module ringbuffer main board enable
debug trace module ringbuffer main alloc enable
debug trace module ringbuffer main default enable
debug trace module level main board debug
debug trace module level main alloc debug
debug trace module level main default debug
```

### Tips

1. **Start conservative** - Use `info` level, not `debug`
2. **Be selective** - Only enable modules you need
3. **Clear buffer** - Use `print clear` to prevent overflow
4. **Always disable paging** - Run `terminal length 0` first

## Finding Modules

```bash
debug trace module level
```

Output shows all available modules:
```
Module           Group            Level    Usec  Ring Buf  Description
---------------  ---------------  -------  ----  --------  -----------
main             board            error    no    no        Board initialization
main             alloc            error    no    no        Memory allocation
...
```

**Note:** The `*` wildcard does NOT work here; enable each module individually.

## Common Issues

### No Traces Appearing

**Check:**
1. Did you run `platform debug allow`?
2. Is module enabled? Check `debug trace module level`
3. Is `Ring Buf` column showing `yes`?
4. Is log level appropriate? Try `info` or `debug`

### Switch Crashes When Printing

**Cause:** Too many traces at debug level or paging through output (lock contention)

**Symptom:** Check `/switch/icfg/crashfile`:
```bash
show file /switch/icfg/crashfile
```

Look for traces system deadlock.

**Solution:**
- Reboot switch
- Be more selective (fewer modules, lower log levels)
- Don't page output (`terminal length 0`)

### Buffer Overflow (Missing Early Traces)

**Solution:** Print and clear more frequently:
```bash
debug trace ringbuffer print clear
```

## Crash File Analysis

If switch crashes, check crashfile:

```bash
cat /switch/icfg/crashfile
```

Or download it:
```bash
[Local] ./bin/download-switch-config.sh http://{GS_IP} crashfile
```

Look for:
- **Locked mutexes** - Deadlock
- **Assertion failures** - Where crash occurred
- **Backtraces** - Call stack

## See Also

- [file-transfers.md](file-transfers.md) - Transfer debug files off switch
- [scripting-with-expect.md](scripting-with-expect.md) - Help for automating trace captures
- Helper script: `../bin/debug_trace_capture.exp`
