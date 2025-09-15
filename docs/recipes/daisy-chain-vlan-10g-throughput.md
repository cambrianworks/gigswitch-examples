# Daisy Chain 4x 10G Ports to Measure Throughput

This is a template example (jsonc) to daisy chain the 10G ports using VLANs to measure throughput.

The files for this template are in subdirectory [vlan-10g-throughput-template](./vlan-10g-throughput-template).

As a template example, the main `jsonc` config references variables that can be set in a parallel `yaml` file. There's an additional helper script to configure the initial starting point list of VLANs. In short, you'll need to find your existing list of VLANs and any of the new VLAN ids to this list.

## 10G Throughput Test - Isolated VLAN Profile

This mini-profile isolates the four 10G ports in a single access VLAN **and disables spanning tree on them**, so you can drive traffic end-to-end and verify each port can sustain its rated throughput **without mixed saturation**. Private VLAN groups keep A/B/C traffic pointed only at the aggregation port.

> **Safety:** Disabling spanning-tree can cause loops. Use in an isolated bench environment only.

## What it does

1. **Assigns 10G ports to one VLAN** (`TEST_VLAN`, default **28**).
2. **Disables MSTP** on those 10G ports so test loops aren't blocked (lab-only).
3. **Creates three Private VLAN groups**, pairing each member port with the aggregation port:
   - `${PVLAN_1}`: `${PORT_A}` ↔ `${PORT_AGG}`
   - `${PVLAN_2}`: `${PORT_B}` ↔ `${PORT_AGG}`
   - `${PVLAN_3}`: `${PORT_C}` ↔ `${PORT_AGG}`
   - This avoids A↔B↔C cross-traffic and keeps streams independent.

## Prerequisites / Preflight (No Assumptions)

This template requires the VLANs being assigned to ports to exist in your global list of VLANs. Before applying, make sure the following VLAN IDs are present in the switch's global list of allowed VLANs
(`AccessVlans`):

- `TEST_VLAN` (default **28**)
- `PVLAN_1`, `PVLAN_2`, `PVLAN_3` (defaults **25/26/27**)

### Quick manual check

Show current list and TPID:
```bash
gs-rpc call vlan.config.global.main.get
```
You should see something like:
```json
{
  "CustomSPortEtherType": 34984,
  "AccessVlans": [1,10,20,25,26,27,28,...]
}
```

### Add any missing VLAN IDs

To set (or expand) the list, **preserving** the current TPID, post the union of your
current `AccessVlans` plus the missing IDs. Example (edit the `AccessVlans` to match
your environment):

```bash
# Example only - replace AccessVlans with the union you want and magic `34984` must match your existing number if different.
gs-rpc post -d '{"method":"vlan.config.global.main.set","params":[{"CustomSPortEtherType":34984,"AccessVlans":[1,10,20,25,26,27,28]}]}'
```

> **Tip:** You can always read the current TPID/VLANs and construct the union dynamically.
> See the preflight script below for an automated way.

### Automated preflight (recommended)

Use the included helper to **read** current globals, **union** them with the IDs in your
vars file, and **apply changes only if needed**:

```bash
# optional: --dry-run to preview, --verbose for details
./preflight_10g_vlans.sh vars-10g.yaml --verbose
```

The script:
- Reads `TEST_VLAN`, `PVLAN_1/2/3` from your vars (defaults to 28, 25/26/27).
- Calls `vlan.config.global.main.get` to fetch the current list and TPID.
- If anything is missing, posts a single `vlan.config.global.main.set` with the union.
# (If you are using the defaults, you are checking for VLANS 25-28 in list.)

## Files

- `10g_throughput_profile.jsonc` - the JSONC with references to variables.
- `vars-10g.yaml` - example variables file.
- `preflight_10g_vlans.sh` - helper to ensure VLAN IDs exist (no assumptions).

## Apply

Recommended with snapshots and an archive of exactly what got sent:

```bash
gs-rpc post --raw \
  -f 10g_throughput_profile.jsonc \
  --jsonc --vars vars-10g.yaml \
  --snapshot snaps_10g \
  --emit-jsonl sentcmds_10g.jsonl --emit-add-id \
  | tee snaps_10g.log
```

- `--snapshot snaps_10g` saves:
  - `snaps_10g.before.txt`
  - `snaps_10g.after.txt`
  - `snaps_10g.diff.txt`
- `--emit-jsonl sentcmds_10g.jsonl` writes a normalized JSONL copy with injected `id`s.

## Verify

Use your snapshot diff, or check manually:

- Interfaces should show:
  - `switchport access vlan ${TEST_VLAN}`
  - `no spanning-tree` on `${PORT_A}`, `${PORT_B}`, `${PORT_C}`, `${PORT_AGG}`
- Private VLAN membership:
  - `${PVLAN_1}` includes `${PORT_A}` and `${PORT_AGG}`
  - `${PVLAN_2}` includes `${PORT_B}` and `${PORT_AGG}`
  - `${PVLAN_3}` includes `${PORT_C}` and `${PORT_AGG}`

If you need to reset, re-apply your full baseline (or use the revert profile below).

---

## Revert / Undo

Use `10g_throughput_revert.jsonc` with the **same** `vars-10g.yaml` to clear isolation
and optionally **re-enable spanning tree**:

```bash
gs-rpc post --raw \
  -f 10g_throughput_revert.jsonc \
  --jsonc --vars vars-10g.yaml \
  --snapshot snaps_10g-revert \
  --emit-jsonl sentcmds_10g-revert.jsonl --emit-add-id \
  --continue \
  | tee snaps_10g-revert.log
```

What it does:

1. **Clears** the PVLAN groups `${PVLAN_1}`, `${PVLAN_2}`, `${PVLAN_3}` (empty `PortList`).
   - If the groups don't exist you'll see *Entry not found*; `--continue` keeps going.
2. Provides lines to **re-enable MSTP** on `${PORT_A}`, `${PORT_B}`, `${PORT_C}`, `${PORT_AGG}`.
   - *Comment out if MSTP was already disabled originally.*
3. Provides **commented lines** to restore previous access VLANs if you changed them during the test.
   - Define `PREV_VLAN_A/B/C/AGG` in your vars to use those lines.
   - By default, these are commented out and assume you either have no initial config for these or don't care to restore it.
