# Standard Tools Overview

This guide compares the primary management interfaces and tools for the GigSwitch, using placeholders `${GS_IP}` and `${GS_PASS}` for hostname/IP and admin password.

---

## 1. Introduction

An at-a-glance comparison of available management methods and their use cases:

- **Web UI**: Graphical interface best for one-off tasks and visual monitoring.
- **SSH CLI**: Interactive CLI for manual configuration and troubleshooting.
- **curl (JSON‑RPC)**: Raw API calls for scripting that requires all fields for authentication, headers, etc.
- **Vendor **``** Utility**: Vencor JSON‑RPC wrapper with vendor-specific formatting and convenient subcommands.
- `gs-rpc` Utility: Cambrian's JSON‑RPC client with credential bootstrapping (see `helper-tool.md`).

---

## 2. Placeholders

- `${GS_IP}`: Management IP or hostname of the switch.
- `${GS_PASS}`: Admin password.

---

## 3. Web UI (HTTP/HTTPS)

- **Access**: `http://${GS_IP}` or `https://${GS_IP}`
- **Features**:
  - Dashboard for general status, configuration, monitoring and system health.
  - Sections for `Configuration`, `Monitor`, `Diagnostics` and `Maintenance`
- **Limitations**:
  - Not ideal for automation or bulk changes.
  - GUI-based workflows only.

---

## 4. CLI over SSH (icli)

- **Connect**:
  ```bash
  ssh admin@${GS_IP}
  ```
  Enter `${GS_PASS}` when prompted.
- **Context Help**: Tab completion and `?` to expand options with brief descriptions.
- **Session Limit**: Up to 4 concurrent SSH connections.
- **Common Commands**:
  - `help`
  - `show running-config`
  - `copy running-config startup-config` (copy `running-config` into `startup-config`)
  - `reload cold` (reboot)
  - `reload defaults` (load defaults without rebooting)
  - `show vlan`
  - `ping IP-ADDRESS`
  - `platform debug allow` (allow certain debug commands)
    - `debug system shell` (root shell when debug mode allowed)
  - `exit`
- **Filtering Output**: Using `|` can process command output through `begin`, `exclude` (like `grep -v`) and `include` (like `grep`); leveraging context-help with brief descriptions:
  ```
  # show running-config | ?
      begin      Begin with the line that matches
      exclude    Exclude lines that match
      include    Include lines that match
  ```

  Example using `include`:
  ```
  # show running-config | include ntp   
  ntp
  ntp server 1 ip-address pool.ntp.org
  ntp server 2 ip-address time.google.com
  ```
- **Disabling Paged Output**: Commands like `show running config` can span many pages with `<Space>` to advance but you can disable this by setting the number of terminal lines to 0:
  ```bash
  terminal length 0
  ```

---

## 5. curl (JSON‑RPC)

- **Endpoint**: `https://${GS_IP}/json_rpc`
- **Headers**: `Content-Type: application/json`
- **Authentication**: Basic auth with `admin:${GS_PASS}`.
- **Version**: Uses json-rpc 1.0 so ignores parameters `{"jsonrpc": "2.0"}`; both `"error"` and `"result"` should be returned with 1 null (versus omitted in 2.0)
- **Use Cases**: Scripting, integration with orchestration tools.

### Sample: Check if https is configured

```bash
curl -s -k -u admin:${GS_PASS} http://${GS_IP}/json_rpc \
  -H 'Content-Type: application/json' \
  -d '{"method":"https.config.global.get", "params":[], "id":1}'
```

Might respond:

```
{"id":1,"error":null,"result":{"Mode":true,"RedirectToHttps":false}}
```

Above indicates that `https` is enabled and that `http` is not automatically forwarded to `https`.

**Note:** If the command fails completely, then try replacing `http` with `https` as `"RedirectToHttps"` might be `true`.

### Sample: Fetch JSON-RPC Spec

Method 1 - obtain generic spec simply with URL:

```bash
curl -s -k -u admin:${GS_PASS} http://${GS_IP}/json_spec -o json_spec_generic.json
---

Method 2 - use `specific` version `generic` to filter out unsupported commands; use `jq` to grab only `result` portion of response:

```bash
curl -s -k -u admin:${GS_PASS} http://${GS_IP}/json_rpc \
  -H 'Content-Type: application/json' \
  -d '{"method":"jsonRpc.status.introspection.specific.inventory.get", "params":[""], "id":1}' \
  | jq '.result' > json_spec_specific.json
```

## 6. Vendor `vson` Utility

- **Purpose**: Simplifies JSON‑RPC calls with vendor-specific aliases and format conversions.
- **Examples**:
  ```bash
  vson -c -d ${GS_IP} -u admin -p "${GS_PASS}" grep https
  vson -c -d ${GS_IP} -u admin -p "${GS_PASS}" spec https.config.global.get
  vson -c -d ${GS_IP} -u admin -p "${GS_PASS}" call https.config.global.get
  ```
- **Considerations**:
  - Outputs change json output format for arguably better readability but can't be easily updated to serve as new input.
  - Doesn't save credentials; must be input on command line each time.
  - Need to use `-c` on each call to avoid redownloading spec file.
  - Uses hard-coded ports 80 and 443 which can be a hassle if port forwarding.
  - Requires `ruby` which is arguably less common than `curl`, `jq` and `python3`

## 7. Cambrian `gs-rpc` Utility

- **Purpose**: Similar functionality to `vson` but supports `bootstrap` command to set up credentials, saves credentials, adds support to `post` the body of a json-rpc call, adds `type` to look up a type, and defaults to reporting results in native json that can either be reused as an input or processed with tools like `jq`.
- **Examples**:
  ```bash
  gs-rpc bootstrap
  gs-rpc grep https
  gs-rpc spec https.config.global.get
  gs-rpc call https.config.global.get
  gs-rpc type 
  gs-rpc post -d '{"method": "https.config.global.get", "params": [], "id": 1}'
  gs-rpc post -d '{"method": "https.config.global.set", "params": [{"Mode": true, "RedirectToHttps": false}], "id": 1}'
  ```
- **Considerations**:
  - Requires Python3 and a couple libraries.
  - Supports sub-commands that are a super-set of `vson`.
  - Reuses credentials after running `bootstrap`.
  - Outputs in native json for reuse where possible.
  - The `post` variant also supports `-f` to read multiple json lines from a file input.
