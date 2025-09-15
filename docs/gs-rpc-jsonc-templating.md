# gs-rpc — Advanced Usage (JSONC, Vars, JSONL Emitter, Snapshots)

This doc explains all the “advanced” features now available in `gs-rpc`:
- Relaxed **JSONC** input (comments, trailing commas, multi-object formats)
- **Variables** from files, CLI overrides, and environment
- **JSONL emitter** that can resequence or inject `id`s
- **Running‑config snapshots** (before/after + unified diff) via `snapshot_cmd`

> **Compatibility promise:** Aside from these additions (flags and the snapshot callout), the rest of `gs-rpc` behavior stays as-is.

---

## Install / Update

On a Debian machine with Cambrian package access, install the latest stable version:

```bash
sudo apt install gs-rpc
```

Or, the bleeding edge version is mainted in this repository in the `bin` directory and from that directory can be installed (or replace your existing script) with:
```bash
sudo install -m 0755 ./gs-rpc /usr/local/bin/gs-rpc
```

Bootstrap (or re-bootstrap) your config and fetch the RPC spec cache (it should default to your current settings and let you add the new `snapshot_cmd`):
```bash
gs-rpc bootstrap
```

An example for `snapshot_cmd` is given in [../bin/gs-grab-running-config-wrapper](../bin/gs-grab-running-config-wrapper). This script requires the tool `expect` and `python3` to be present on your machine. To use these scripts as-is, you can copy them to any directory in your path (such as using `~/bin` to keep these local and ensure `~/bin` is in your path). Or, you could copy these to a more global path. From the `bin` directory in this repository:
```bash
sudo install -m 0755 ./gs-grab-running-config-wrapper /usr/local/bin
sudo install -m 0755 ./gs-grab-running-config /usr/local/bin
```

Your config lives at `~/.gigswitch/config.yaml`.

---

## Config (`~/.gigswitch/config.yaml`)

Minimum keys:
```yaml
json_url: "http://microchip:80/json_rpc"
username: "admin"
password: ""
json_spec_cache: "/home/you/.gigswitch/json_spec.json"
# Optional: a shell command run for snapshots (see Snapshots section)
snapshot_cmd: "gs-grab-running-config-wrapper [host_override]"
```

### Snapshot placeholders
If `snapshot_cmd` is set, it supports these placeholders:
- `{host}` — hostname parsed from `json_url`
- `{user}` — `username` in your YAML
- `{password}` — `password` in your YAML
- `{json_url}` — the full URL

Examples:
```yaml
snapshot_cmd: "gs-grab-running-config-wrapper"
# or override hostname (for example, if json_url uses localhost and a port-forward)
snapshot_cmd: "gs-grab-running-config-wrapper microchip2"
```

---

## Subcommands

- `gs-rpc call <method> [params…] [--raw]`
- `gs-rpc post  [-f FILE | -d JSON] [--jsonc] [--vars VARS.yml] [-D K=V] [--allow-env] [--emit-jsonl path] [--snapshot BASE] [--continue] [--raw]`
- `gs-rpc grep <needle>` — search cached spec method names
- `gs-rpc type <type-name>` — print a type from cached spec
- `gs-rpc spec <method-name>` — print full schema entries for a method
- `gs-rpc update-spec` — refresh the cached spec

---

## JSONC (Relaxed JSON Input)

Enable via either:
- `--jsonc`, or
- file name ending in `.jsonc`

Supported relaxations:
- **Comments:** `// line` and `/* block */`
- **Trailing commas** in objects/arrays
- **Concatenated objects**: `{..}{..}{..}` (no separators)
- **JSON Lines (JSONL)**: one object per line
- **BOM** at top is ignored

To require strict JSON (even with `.jsonc`), pass `--strict-json`.

### Example `.jsonc`
```jsonc
// vlan batch
{"method": "vlan.config.global.main.set", "params": [{"AccessVlans":[1,10,20,28]}]}

{
  "method": "vlan.config.interface.set",
  "params": ["Gi 1/1", {"Mode":"access","AccessVlan": 10}], // trailing comma OK,
}
{
  "method": "vlan.config.interface.set",
  "params": ["Gi 1/2", {"Mode":"access","AccessVlan": 10}]
}
```

Run:
```bash
gs-rpc post -f plan.jsonc --jsonc
```

---

## Variables

You can inject variables into JSONC using `${VAR}` tokens.

Sources (later wins):
1. `--vars FILE` (may repeat). Supports **YAML**, **JSON**, and **.env/.sh** (`KEY=VALUE` lines).
2. `-D KEY=VALUE` (may repeat) — inline overrides.
3. Optional **environment** via `--allow-env` and `${env:NAME}` tokens.

If `--allow-undefined` is **not** set, unknown `${VAR}` produces an error. With it, unknown tokens are left as-is.

### Example: vars file and CLI define

**vars.yml**
```yaml
VLAN_A: 10
VLAN_B: 20
```

**plan.jsonc**
```jsonc
{
  "method": "vlan.config.interface.set",
  "params": ["Gi 1/1", {"Mode":"access","AccessVlan": ${VLAN_A}}]
}
{
  "method": "vlan.config.interface.set",
  "params": ["Gi 1/2", {"Mode":"access","AccessVlan": ${VLAN_B}}]
}
// Use an env var (only with --allow-env)
{
  "method": "vlan.config.interface.set",
  "params": ["Gi 1/3", {"Mode":"access","AccessVlan": ${env:VLAN_C}}]
}
```

Run:
```bash
VLAN_C=101 gs-rpc post -f plan.jsonc --jsonc --vars vars.yml -D VLAN_B=28 --allow-env
```

---

## JSONL Emitter (with `id` injection)

Normalize any accepted input (JSONC/JSON/JSONL/concatenated) to **JSONL**:
```bash
gs-rpc post -f plan.jsonc --jsonc \
  --emit-jsonl /tmp/plan.jsonl \
  --emit-add-id --emit-id-start 1 \
  --emit-only
```

Flags:
- `--emit-jsonl PATH` — write JSON Lines to `PATH`
- `--emit-add-id` — inject sequential `id` only where missing
- `--emit-reseq` — resequence **all** `id` fields
- `--emit-id-start N` — starting id (default `1`)
- `--emit-only` — write file and exit without posting

> **Note:** The emitter intentionally **does not** add `jsonrpc: "2.0"`.

---

## Snapshots (running-config before/after + diff)

If `snapshot_cmd` is present in your config, you can ask `gs-rpc` to take snapshots automatically around a `post`:

```bash
gs-rpc post -f plan.jsonc --jsonc --snapshot ./snap/plan
```

This will:
- Run: `{snapshot_cmd} (expanded placeholders)` → save to `./snap/plan.before.txt`
- Post your JSON
- Run again → save to `./snap/plan.after.txt`
- Produce unified diff → `./snap/plan.diff.txt`

**Default template** (set by `bootstrap`):  
`snapshot_cmd: "gs-grab-running-config-wrapper {host}"`

If you renamed your wrapper, customized it or want extra args:
```yaml
snapshot_cmd: "gs-grab-running-config-wrapper {host} extraArg"
```

### Suggested wrapper

- **`gs-grab-running-config`** — Expect script that SSHes to the switch, runs:
  - `terminal length 0`
  - `show running-config`
- **`gs-grab-running-config-wrapper`** — reads `~/.gigswitch/config.yaml`, resolves host/user/pass, and calls the Expect script.
  - First CLI arg (if present) can override host (useful if SSH port‑forwarding from `localhost`).

Example invocation (host override):
```bash
gs-grab-running-config-wrapper hostname_override > /tmp/running-config.txt
```

---

## `call` vs `post` (quick refresher)

- `call` is for one RPC:
  ```bash
  gs-rpc call vlan.config.global.main.get
  gs-rpc call vlan.config.interface.set '["Gi 1/1", {"Mode":"access", "AccessVlan":10}]'
  ```
- `post` can take many requests in a single input:
  - **JSONL**: one object per line
  - **Concatenated**: `{..}{..}{..}`
  - **Array**: `[ {..}, {..} ]`
  - **Single object**

Pass `--continue` to keep going after an error; `--raw` to echo request/response pairs.

---

## Troubleshooting

- `JSONC processing error: ...`
  - Use `--strict-json` to narrow scope.
  - Check for unquoted keys or single quotes; both are invalid.
- `Invalid params` / `No such method`
  - Confirm with `gs-rpc grep <word>` then `gs-rpc spec <exact.method.name>`.
- Snapshots didn’t appear
  - Ensure `snapshot_cmd` is set and executable in your PATH.
  - Try running the command printed in your config by hand.
  - Make sure both the wrapper and command are in the same directory and in your path.

---

## Examples

### Minimal VLAN patch with comments + variables and snapshot
**vlan_plan.jsonc**
```jsonc
// grant VLANs
{"method":"vlan.config.global.main.set","params":[{"AccessVlans":[1, ${VLAN_A}, ${VLAN_B}]}]}
// assign ports
{"method":"vlan.config.interface.set","params":["Gi 1/1",{"Mode":"access","AccessVlan": ${VLAN_A}}]}
{"method":"vlan.config.interface.set","params":["Gi 1/2",{"Mode":"access","AccessVlan": ${VLAN_B}}]}
```

**vars.yml**
```yaml
VLAN_A: 10
VLAN_B: 20
```

Run:
```bash
gs-rpc post -f vlan_plan.jsonc --jsonc --vars vars.yml --snapshot ./snap/vlan
```

Emit an archive copy with ids:
```bash
gs-rpc post -f vlan_plan.jsonc --jsonc --vars vars.yml \
  --emit-jsonl ./archive/vlan_plan.jsonl --emit-add-id --emit-only
```
