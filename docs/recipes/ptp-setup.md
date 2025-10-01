# PTP Setup

This document and recipes are to aid in configuring PTP or Precision Time Protocol.

## Background

PTP (IEEE 1588) is a protocol for synchronizing clocks across a network. Unlike simpler methods such as NTP, which usually get you within a second or so, PTP is designed to achieve accuracy in the microsecond (or even nanosecond) range.

The key difference is hardware timestamping: network devices like switches and NICs can mark the exact time a packet enters or leaves the wire. This removes most of the uncertainty caused by software delays and lets clocks stay very tightly aligned.

Many switches and devices can also generate physical timing signals such as 1 PPS (one pulse per second) or 10 MHz outputs, but those are driven by a clock that has already been synchronized with PTP. These signals are used when downstream equipment needs a precise “tick” to count seconds or drive hardware.

The GigSwitch includes dedicated SMA ports for precise timing: PTP_IN (3.3 V PPS input), PTP_OUT (PPS output), and two “station clock” ports (CKSTATION_I/O) that can accept or provide a continuous frequency reference. The PPS signals allow external timing equipment (such as a GPS-disciplined clock) to discipline the switch’s internal PTP clock or, conversely, let the switch provide a stable PPS output to downstream devices. These ports are intended for high-precision phase alignment in applications such as high-speed networking and distributed system synchronization.

## Recipe: Getting PTP from a Network Grandmaster

If you have a PTP grandmaster sending multicast UDP on **domain 0** (the most common setup), you can configure PTP as follows. This example also assumes the default VLAN 1 (`vid 1 0` = VLAN 1, PCP 0).

### Configure

Connect to `icli` then:

```shell
configure terminal

ptp 0 mode boundary twostep ip4multi twoway vid 1 0
 # likely see below created automatically
 # ptp 0 filter-type aci-basic-phase-low

# Select the interface that connects the switch to the outside world (the grandmaster source)
interface GigabitEthernet 1/25
 ptp 0

end
```

The following settings will usually autopopulate, and you normally don’t need to modify them. On `interface GigabitEthernet 1/25`:

```shell
 ptp 0 announce interval 1 timeout 3
 ptp 0 sync-interval 0
 ptp 0 delay-mechanism e2e
 ptp 0 delay-req interval 0
 ptp 0 delay-asymmetry 0
 ptp 0 ingress-latency 0
 ptp 0 egress-latency 0
```

#### Interval Values
- `0` = default, typically **1 per second**
- Positive numbers = interval in **seconds** (e.g. `3 = 1 every 3 seconds`)
- Negative numbers = **rate per second** (e.g. `-3 = 3 per second`)

#### Priority Settings

By default, `priority1` is **128**. Lower values mean higher priority.
To help ensure the network grandmaster wins, either:
- leave `priority1` unset, or
- explicitly set a higher value (e.g. `ptp 0 priority1 200`).

#### Domain Settings

- Ensure you are on the same **PTP domain number** as your grandmaster (`ptp 0 domain 0` on line by itself).  
- If you want the ability to copy time to the system clock: Ensure your **clock-domain** is also set to `0` (`clock-domain 0` as part of `ptp 0` long config line).

### Verifying PTP Status

Check your clock state (from `icli`):

```shell
show ptp 0 local-clock
```

Example output:

```
PTP Time (0)    : 2025-09-29T23:18:16+00:00 211,071,204
Clock Adjustment method: PTP DPLL
```

A valid date and time confirm clock is set.

Check time properties:

```shell
show ptp 0 time-property
```

Example output:

```
UtcOffset  Valid  leap59  leap61  TimeTrac  FreqTrac  ptpTimeScale  TimeSource
---------  -----  ------  ------  --------  --------  ------------  ----------
37         True   False   False   True      True      True          32
```

`Valid=True` confirms synchronization.

### Persist settings

If you're happy with ptp settings, you can persist them from `icli` by copying to your startup-config:

```shell
copy running-config startup-config
```

## Recipe: Copying PTP to System Time

From `icli` `configure terminal` mode, run:

```shell
ptp system-time set
```

This copies time from **clock-domain 0** to the system clock **if clock-domain 0 has a valid time**.  

**Important caveats:**  
- Only **clock-domain 0** is supported for setting system clock from ptp.
- `ptp system-time set` will cause an entry in the running-config (`ptp system-time set 0`) but DOES NOT appear to take effect after reboot, even if you save it to your `startup-config` with:

```shell
copy running-config startup-config
```

- Interim workaround: re-run `ptp system-time set` after each reboot, or set system time with NTP.

## Recipe: Serving PTP on Network Interfaces

### Configure

For each interface where you want to send PTP downstream (`GigabitEthernet 1/N` or `10GigabitEthernet 1/N`):

```shell
configure terminal

interface GigabitEthernet 1/N
 ptp 0
 exit

interface GigabitEthernet 1/M
 ptp 0
 exit
...

end
```

On these ports, the switch will usually act as **master**, while remaining a **slave** on the uplink (e.g. port 1/25) where it receives grandmaster time.

### Check

You can verify interface status (master/slave/etc.) using:

```shell
# show ptp 0 port-state interface GigabitEthernet 1/25
Port  Enabled  PTP-State  Internal  Link  Port-Timer  Vlan-forw  Phy-timestamper  Peer-delay
----  -------  ---------  --------  ----  ----------  ---------  ---------------  ----------
  29  TRUE     slve       FALSE     Up    In Sync     Forward    FALSE            OK
VirtualPort  Enabled  PTP-State  Io-pin
-----------  -------  ---------  ------
         30  FALSE    dsbl        99999
```

And, if enabled on 1/24:
```shell
# show ptp 0 port-state interface GigabitEthernet 1/24
Port  Enabled  PTP-State  Internal  Link  Port-Timer  Vlan-forw  Phy-timestamper  Peer-delay
----  -------  ---------  --------  ----  ----------  ---------  ---------------  ----------
  24  TRUE     mstr       FALSE     Up    In Sync     Forward    FALSE            OK
VirtualPort  Enabled  PTP-State  Io-pin
-----------  -------  ---------  ------
         30  FALSE    dsbl        99999
```

Or, `show ptp 0 port-state` to output for all ports.

## Recipe: PPS Input/Output (SMA Ports)

This section discusses use of the SMA coax ports for PPS in and out.

### Configure pps in

From `icli` `configure terminal`:
```shell
ptp 2 virtual-port mode pps-in 5
```

**Tip**: If you use `<Tab>` in `icli`, you'll see `5` is the only allowed value for `pps-in` (or `4` for `pps-out`).

**Known issue**: setting PPS input on the same PTP instance for network ptp (`ptp 0` here) can cause loss of sync with the network grandmaster. Use another instance (e.g. `ptp 2 ...`).

### Check pps in

TODO

### Configure pps out

From `icli` `configure terminal`:
```shell
ptp 2 virtual-port mode pps-out 4
```

### Check pps out

TODO
