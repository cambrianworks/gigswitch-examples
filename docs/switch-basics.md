# Switch Basics: Hardware, Filesystem & Capabilities

This document provides an overview of the GigSwitch hardware profile, operating environment, and key capabilities.

---

## 1. Hardware Overview

The GigSwitch from Cambrian Works is a space-hardened, customized Microchip 969x (9698) switch. Key specs:

- **Switch Ports**:
  - 20 × 1 Gbps switch ports (for eval board; Cambrian units include more 10 Gbps ports and less 1 Gbps ports)
  - 4 × 10 Gbps switch ports
  - 1 × 1 Gbps management port
  - 1 × Serial management port
- **Memory**: \~800 MB RAM
- **CPU**:
  - ARM Cortex‑A53 (quad‑core, BogoMIPS ≈ 500)
  - Crypto & vector extensions: AES, SHA‑1/2, CRC32, PMULL, ASIMD

```text
# cat /proc/cpuinfo
processor	: 0
BogoMIPS	: 500.00
Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid
CPU implementer	: 0x41
CPU architecture: 8
CPU variant	: 0x0
CPU part	: 0xd03
CPU revision	: 4
```

---

## 2. Filesystem Layout

The switch runs Buildroot Linux with a minimal, partitioned filesystem. Typical mounts:

```text
Filesystem                Size      Used Available Use% Mounted on
/dev/root                 1.8M      1.8M         0 100% /mnt
devtmpfs                399.6M         0    399.6M   0% /dev
/dev/mmcblk0p5          114.5M     91.4M     14.0M  87% /mnt/mnt
/dev/mapper/dmv_app     104.0M     85.9M      9.1M  90% /
/dev/mmcblk0p7            1.3G     53.0M      1.2G   4% /switch
```

- **/switch**: Primary firmware and application binaries
- **/dev**: Kernel device nodes
- **/mnt**: Temporary mounts (e.g., firmware updates)

Additional `/proc` and `/sys` directories expose runtime metrics and hardware interfaces.

---

## 3. Operating System

```text
# cat /etc/os-release
NAME=Buildroot
VERSION=2024.02
ID=buildroot
VERSION_ID=2024.02
PRETTY_NAME="Buildroot 2024.02"
```

Minimal Linux build optimized for embedded network devices.

---

## 4. Management Interfaces

Configuration and monitoring are available via:

- **Web UI**: GUI access over HTTP(S)
- **SSH CLI**: `ssh admin@GS_IP` (limit: 4 concurrent sessions)
- **JSON‑RPC API**:
  - Raw `curl` calls
  - Vendor `vson` utility
  - `gs-rpc` helper (JSON‑only, bootstrap support)
- **SNMP**: Standard MIBs for polling metrics and stats

---

For detailed configuration recipes and automated workflows, see the `recipes/` directory.

