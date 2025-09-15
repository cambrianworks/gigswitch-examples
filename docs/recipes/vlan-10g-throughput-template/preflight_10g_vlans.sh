#!/usr/bin/env bash
# preflight_10g_vlans.sh
# Ensure TEST_VLAN and PVLAN_1..3 exist in AccessVlans by *unioning* them
# with the current list (preserving CustomSPortEtherType). No jq required.
#
# Usage:
#   preflight_10g_vlans.sh [vars-file.yaml] [--dry-run] [--verbose]
#
# Examples:
#   preflight_10g_vlans.sh vars-10g.yaml
#   preflight_10g_vlans.sh --dry-run
#   preflight_10g_vlans.sh myvars.yaml --verbose
#
set -euo pipefail

vars_file="vars-10g.yaml"
dry_run=0
verbose=0

# Parse args
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    --verbose) verbose=1 ;;
    -* ) echo "Unknown flag: $arg" >&2; exit 2 ;;
    * )
      if [[ -f "$arg" ]]; then
        vars_file="$arg"
      else
        echo "Vars file not found: $arg" >&2
        exit 2
      fi
      ;;
  esac
done

cfg="${HOME}/.gigswitch/config.yaml"
if [[ ! -f "$cfg" ]]; then
  echo "ERROR: gs-rpc config not found: $cfg" >&2
  exit 2
fi

# Tiny YAML reader for top-level keys in the vars file
read_yaml_var() {
  local key="$1"
  local path="$2"
  local line
  line="$(grep -E "^${key}:" "$path" | head -n1 || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return 0
  fi
  line="${line#${key}:}"
  line="$(printf '%s' "$line" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  line="$(printf '%s' "$line" | sed -E 's/^\"(.*)\"$/\1/; s/^\x27(.*)\x27$/\1/')"
  printf '%s' "$line"
}

TEST_VLAN="$(read_yaml_var TEST_VLAN "$vars_file")"
PVLAN_1="$(read_yaml_var PVLAN_1 "$vars_file")"
PVLAN_2="$(read_yaml_var PVLAN_2 "$vars_file")"
PVLAN_3="$(read_yaml_var PVLAN_3 "$vars_file")"

# Defaults if missing
TEST_VLAN="${TEST_VLAN:-28}"
PVLAN_1="${PVLAN_1:-25}"
PVLAN_2="${PVLAN_2:-26}"
PVLAN_3="${PVLAN_3:-27}"

needed=("$TEST_VLAN" "$PVLAN_1" "$PVLAN_2" "$PVLAN_3")
[[ "$verbose" -eq 1 ]] && echo "Needed VLANs: ${needed[*]}" >&2

# Get current globals (gs-rpc prints the 'result' object as valid JSON)
current_json="$(gs-rpc call vlan.config.global.main.get)"
[[ "$verbose" -eq 1 ]] && echo "Current JSON: $current_json" >&2

# Compute union and build a 'set' payload, but only apply if changes are needed.
out="$(printf '%s' "$current_json" | python3 -c '
import sys, json
data = json.load(sys.stdin)  # result object from gs-rpc
existing = set(data.get("AccessVlans", []))
tpid = int(data.get("CustomSPortEtherType", 34984))
needed = set(int(x) for x in sys.argv[1:])
union = sorted(existing | needed)
if sorted(existing) == union:
    print("SKIP")
else:
    payload = {
        "method": "vlan.config.global.main.set",
        "params": [{
            "CustomSPortEtherType": tpid,
            "AccessVlans": union
        }]
    }
    print("APPLY")
    print(json.dumps(payload, separators=(",", ":")))
' "${TEST_VLAN}" "${PVLAN_1}" "${PVLAN_2}" "${PVLAN_3}")"

action="$(printf '%s\n' "$out" | head -n1)"
payload="$(printf '%s\n' "$out" | tail -n +2)"

if [[ "$action" == "SKIP" ]]; then
  echo "Preflight: AccessVlans already include: ${needed[*]}"
  exit 0
fi

echo "Preflight: will add missing VLANs via vlan.config.global.main.set"
[[ "$verbose" -eq 1 ]] && echo "Payload: $payload" >&2

if [[ "$dry_run" -eq 1 ]]; then
  echo "(dry-run) Skipping apply"
  exit 0
fi

# Apply using gs-rpc post with inline -d
gs-rpc post -d "$payload" --raw | sed -n 's/^Response: //p'
echo "Preflight: VLAN list updated."
