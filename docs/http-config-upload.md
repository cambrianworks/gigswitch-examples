# HTTP Config Upload Workflow

## General Upload

With the exception of the special `running-config` case, the `config/icfg_conf_upload` endpoint allows upload of a local file to `/switch/icfg`.
You can use the web interface or the `upload-switch-config.sh` helper script in the `bin` directory. The helper script requires
some standard command line tools including `curl`.

The helper script is based around this basic form of `curl` command:

```
SRC_PATH="$1"
FILENAME=$(basename "$SRC_PATH")

curl -u admin:PASSWD -X POST \
  -F "file_name=${FILENAME}" \
  -F "merge=false" \
  -F "source_file=@${SRC_PATH};type=application/octet-stream" \
  -F "file_name_radio=" \
  -F "new_file_name=${FILENAME}" \
  -L "http[s]://{SWITCH_IP}/config/icfg_conf_upload"
```

`merge=true` applies only to the special case of `running-config`.

## Running Config Support

The switch web interface provides HTTP endpoints for config upload **and activation**. This activation of an immediate settings in the **running** config has **two steps** and requires **session cookies**.

## The Two-Step Process

### Step 1: Upload
**Endpoint:** `POST /config/icfg_conf_upload`

**Form data:**
- `file_name` - Source filename
- `new_file_name` - Destination filename (e.g., "running-config", "startup-config", "myconfig.txt")
- `merge` - "true" or "false" (only relevant for "running-config")
- `source_file` - The actual file (multipart)

**Result:** File written to `/switch/icfg/new_file_name`

**Session state saved:** merge setting, filename stored in cookies

### Step 2: Activate (only for "running-config")
**Endpoint:** `GET /config/icfg_conf_activate`

**Requires:** Cookies from upload step

**Result:** Applies `/switch/icfg/running-config` to actual running-config (and erases temp file)

**Status responses:**
- `DONE` - Success
- `RUN` - Still processing (poll again)
- `ERR` - Completed with errors
- `SYNERR` - Syntax errors, not activated
- `IDLE` - No activation pending

## Complimentary Actions with iCLI

### Understanding "flash:" Prefix

In iCLI commands, **`flash:filename`** refers to files in **`/switch/icfg/`** directory.

**Examples:**
- `flash:myconfig.txt` = `/switch/icfg/myconfig.txt`
- `flash:startup-config` = `/switch/icfg/startup-config`

### Safer Way to Activate an Uploaded File

The documented upload script can be used to directly update the `running-config` or `startup-config`. However, it's arguably safer to first copy a config to the switch and then activate it with iCLI.

Below, the `syntax-check` argument will prevent the full `copy` operation if the input doesn't pass a syntax check. If you copy over top of a `running-config` without the `syntax-check` argument then you could apply only part of a config up to the point of the syntax error.

**WARNING:** There are some distinct differences in what is supported via the **iCLI `copy` command** and **http endpoint**.
  1. The `copy` command will ALWAYS use `merge` when the destination is the `running-config`
  2. The `copy` command supports remote files with `tftp`
  3. The `copy` command supports the `syntax-check` argument to help avoid activating a corrupt config

**Usage:**
```bash
# Apply config from flash to running-config (MERGE is implied)
copy flash:myconfig.txt running-config [syntax-check]

# Copy to startup-config
copy flash:myconfig.txt startup-config [syntax-check]
```

## Special Treatment of "running-config"

**Filename "running-config" is special:**
1. Web UI shows Replace/Merge radio buttons (only for this filename)
2. After upload, Web UI auto-redirects to activation page
3. Activation applies the file to actual `running-config`

**merge=true:** Merges commands into existing running-config (additive)
**merge=false:** Replaces running-config (full replacement)

**Other filenames:**
- Upload creates file in `/switch/icfg/new_file_name`
- No automatic activation
- Apply manually (later with iCLI): `copy flash:filename running-config`

## Why Cookies Are Required

The upload and activate are separate HTTP requests. Session state is maintained via cookies:

```
Upload POST → Sets cookie with:
  - filename=running-config
  - merge=true/false
  
Activate GET → Reads cookie to know:
  - What file to activate
  - How to apply it (merge vs replace)
```

**Without cookies, activation doesn't know what to do and is a no-op!**

## Complete curl Example

See the helper script in `../bin/upload-switch-config.sh`.

## Usage Examples

### Upload and merge into running-config
```bash
upload-switch-config.sh changes.txt http://{GS_IP} running-config true
```

Result: Config merged into running-config immediately

### Upload and replace running-config
```bash
upload-switch-config.sh newconfig.txt http://{GS_IP} running-config false
```

Result: Running-config completely replaced

### Upload as regular file
```bash
./upload-switch-config.sh myconfig.txt http://{GS_IP}
```

Result: File at `/switch/icfg/myconfig.txt`, must apply manually or might use for other purposes.

## Comparison with Other Methods

| Method | Steps | Reboot? | Best For |
|--------|-------|---------|----------|
| **HTTP Upload (running-config)** | Upload + Activate | No | Scriptable, immediate application |
| **HTTP Upload (other files)** | Upload + manual copy | No | Staging configs |
| **TFTP direct** | `copy tftp://... running-config` | No | iCLI one-liner but requires tftp |
| **iCLI persist running config** | `copy running-config startup-config` | No | iCLI sets current config as `startup-config` |
| **TFTP + reload** | `copy tftp://... startup-config` + `reload cold` | Yes | iCLI remote setting of `startup-config` |

## Files Created

**For "running-config":**
- Temporary file at `/switch/icfg/running-config` 
- Applied to actual `running-config`
- File removed after activation

**For other filenames:**
- Permanent file at `/switch/icfg/filename`
- Stays until deleted
- Must apply manually

## Summary

**For immediate config changes via HTTP:**
1. Upload to "running-config" with merge=true/false
2. Call activate endpoint with same cookies
3. Check status response
4. Config applied immediately, no reboot needed

**For staging configs:**
1. Upload to custom filename
2. No activation step
3. Apply later with: `copy flash:filename running-config`

The script `upload-switch-config.sh` handles all of this automatically!
