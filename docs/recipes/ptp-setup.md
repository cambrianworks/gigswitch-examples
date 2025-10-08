# PTP Setup

This document and recipes are to aid in configuring PTP or Precision Time Protocol.

## Background

PTP (IEEE 1588) is a protocol for synchronizing clocks across a network. Unlike simpler methods such as NTP, which usually get you within a second or so, PTP is designed to achieve accuracy in the microsecond (or even nanosecond) range.

The key difference is hardware timestamping: network devices like switches and NICs can mark the exact time a packet enters or leaves the wire. This removes most of the uncertainty caused by software delays and lets clocks stay very tightly aligned.

Many switches and devices can also generate physical timing signals such as 1 PPS (one pulse per second) or 10 MHz outputs, but those are driven by a clock that has already been synchronized with PTP. These signals are used when downstream equipment needs a precise “tick” to count seconds or drive hardware.

The GigSwitch includes dedicated SMA ports for precise timing: PTP_IN (3.3 V PPS input), PTP_OUT (PPS output), and two “station clock” ports (CKSTATION_I/O) that can accept or provide a continuous frequency reference. The PPS signals allow external timing equipment (such as a GPS-disciplined clock) to discipline the switch’s internal PTP clock or, conversely, let the switch provide a stable PPS output to downstream devices. These ports are intended for high-precision phase alignment in applications such as high-speed networking and distributed system synchronization.

## Additional Documentation

PTP is discussed in the following documents for calibration and configuration:

* [AN1294-SW_Configuration_Guide_PTP_Calibration.pdf](https://ww1.microchip.com/downloads/secure/aemDocuments/documents/UNG/ApplicationNotes/ApplicationNotes/AN1294-SW_Configuration_Guide_PTP_Calibration.pdf); [an1294 parent page](https://www.microchip.com/en-us/application-notes/an1294)
* [AN1295-PTP_Configuration_Guide.pdf](https://ww1.microchip.com/downloads/secure/aemDocuments/documents/UNG/ApplicationNotes/ApplicationNotes/AN1295-PTP_Configuration_Guide.pdf); [an1295 parent page](https://www.microchip.com/en-us/application-notes/an1295)

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

For `log` values (some don't have `log` in the parameter name but are described as `log` values in the documentation):
- Generally, for a value V, the interval is 2^V seconds.
- 0 (typical default) → 2^0 = 1 second (1 message per second)
- Positive numbers (e.g. 3) → 2^3 = 8 seconds (1 every 8 seconds)
- Negative numbers (e.g. -3) → 2^−3 = 1/8 second interval (i.e., 8 per second)

Otherwise, time values have a similar interpretation except without log scale:
- 0 typically references the default value
- Positve numbers (e.g. 3) → 3 seconds (1 every 3 seconds)
- Negative numbers (e.g. -3) → 1/3 = 1/3 second interval (i.e., 3 per second)

#### Priority Settings

By default, `priority1` is **128**. Lower values mean higher priority.
To help ensure the network grandmaster wins, either:
- leave `priority1` unset, or
- explicitly set a higher value (e.g. `ptp 0 priority1 200`).

Some profiles/modes might force `priority1` to a fixed value and then, if all other comparisons are equivalent, the `priority2` value will be the tie breaker where, again, lower values have higher priorities.

#### Domain Settings

- Ensure you are on the same **PTP domain number** as your grandmaster (`ptp 0 domain 0` on line by itself).  
- If you want the ability to copy time to the system clock: Ensure your **clock-domain** is also set to `0` (`clock-domain 0` as part of `ptp 0` long config line).
- Documentation also states: It must be noted that DPLL and PHY operate in only clock domain 0.

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

### JSON-RPC / JSONC equivalent

The `ptp-boundary-clock.jsonc` template is reused below to also attach the ptp instance to interfaces but we will simply give illegal names to the interfaces so those last commands will fail here.

Post the **boundary clock** profile (uplink: `Gi 1/25`, downstream: override until later section):

```bash
gs-rpc post --continue --raw --vars ./ptp-template/vars-ptp.yaml -D DOWNSTREAM1_IFNAME="IGN" -D DOWNSTREAM2_IFNAME="IGN" -f ./ptp-template/ptp-boundary-clock.jsonc
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

### JSON-RPC / JSONC equivalent

Copy PTP (clock-domain 0) → system clock.

Supported values for the 2nd argument are: "systemTimeNoSync", "systemTimeSyncSet", "systemTimeSyncGet".

```bash
gs-rpc post --continue --raw -d '{"method":"ptp.config.global.systemTimeSyncMode.set","params":[{"mode":"systemTimeSyncSet"}]}'
```


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

### Check with tcpdump

Above, `GigabitEthernet 1/24` had `ptp 0` added to the interface. In this lab config, the IP addresses are:
`GigSwitch`: `192.168.129.15`
`Time Machine`: `192.168.129.61` (ptp grandmaster)

Here's an example `tcpdump` from a machine directly connected to this port on its `eth0`:

Before configuring ANY ports with `ptp 0`, traffic is seen from the grandmaster (install `tcpdump` and adjust `eth0` as needed):
```
$ sudo tcpdump -i eth0 -nn -e -vv -s 1500 udp port 319 or udp port 320
    192.168.129.61.319 > 224.0.1.129.319: [no cksum] PTPv2, v1 compat : no, msg type : sync msg, length : 44, domain : 0, reserved1 : 0, Flags [two step], NS correction : 0, sub NS correction : 0, reserved2 : 0, clock identity : 0x28b5e8fffe4afda3, port id : 1, seq id : 32733, control : 0 (Sync), log message interval : 254, originTimeStamp : 0 seconds, 0 nanoseconds
19:39:48.438176 28:b5:e8:4a:fd:a3 > 01:00:5e:00:01:81, ethertype IPv4 (0x0800), length 86: (tos 0x0, ttl 1, id 38721, offset 0, flags [DF], proto UDP (17), length 72)
    192.168.129.61.320 > 224.0.1.129.320: [no cksum] PTPv2, v1 compat : no, msg type : follow up msg, length : 44, domain : 0, reserved1 : 0, Flags [none], NS correction : 0, sub NS correction : 0, reserved2 : 0, clock identity : 0x28b5e8fffe4afda3, port id : 1, seq id : 32733, control : 0 (Sync), log message interval : 254, preciseOriginTimeStamp : 1759347625 seconds, 362180062 nanoseconds
```

You'll note above that the destination is multicast address `224.0.1.129`. An alternative `tcpdump` with this in mind is:

```
sudo tcpdump -n -i eth0 -s0 -vv -e host 224.0.1.129
```

If you've configured the `GigSwitch` for ptp and have ONLY enabled your external interface with `ptp 0` then there will be NO PTP TRAFFIC seen emerging on other ports (until/unless you've configured them):

```
$ sudo tcpdump -i eth0 -nn -e -vv -s 1500 udp port 319 or udp port 320
(no output)
```

This is because you've told the switch to pay attention to ptp traffic and it will no longer generate or forward ptp traffic until you've enabled specific interfaces.

Then, after configuring for `ptp 0` on port `GigabitEthernet 1/24`, ptp traffic is seen from the `GigSwitch` instead (since the `GigSwitch` is watching ptp and can run as a master):
```
$ sudo tcpdump -n -i eth0 -s0 -vv -e host 224.0.1.129
    192.168.129.15.319 > 224.0.1.129.319: [no cksum] PTPv2, v1 compat : no, msg type : sync msg, length : 44, domain : 0, reserved1 : 0, Flags [two step], NS correction : 0, sub NS correction : 0, reserved2 : 0, clock identity : 0x8227c7fffe4dae01, port id : 24, seq id : 1, control : 0 (Sync), log message interval : 0, originTimeStamp : 0 seconds, 0 nanoseconds
19:49:52.062774 82:27:c7:4d:ae:01 > 01:00:5e:00:01:81, ethertype IPv4 (0x0800), length 86: (tos 0x0, ttl 128, id 0, offset 0, flags [none], proto UDP (17), length 72)
    192.168.129.15.320 > 224.0.1.129.320: [no cksum] PTPv2, v1 compat : no, msg type : follow up msg, length : 44, domain : 0, reserved1 : 0, Flags [none], NS correction : 0, sub NS correction : 0, reserved2 : 0, clock identity : 0x8227c7fffe4dae01, port id : 24, seq id : 85, control : 2 (Follow_Up), log message interval : 0, preciseOriginTimeStamp : 92 seconds, 637556112 nanoseconds
```

If you don't see any traffic, ensure you have configured ptp with UDP multicast and that your networking path isn't blocking these datagrams. If you (intentionally or) unintentionally configured for raw ethernet instead, you should see these types of messages with `proto 0x88f7`:

```
sudo tcpdump -i eth0 -vv -s0 ether proto 0x88f7
```

### JSON-RPC / JSONC equivalent

Below, this reuses the `ptp-boundary-clock.jsonc` partly configured above but now sets up ptp on two downstream interfaces.

Post the **boundary clock** profile (uplink: `Gi 1/25`, downstream: `Gi 1/24` from vars):

```bash
gs-rpc post --continue --raw --vars ./ptp-template/vars-ptp.yaml -D DOWNSTREAM2_IFNAME="IGN" -f ./ptp-template/ptp-boundary-clock.jsonc
```


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

From `icli`, you can watch for statistics and missed events from debug mode.

```shell
# platform debug allow
# debug ptp pps-tod statistics
one_tod_cnt            :              0
one_pps_cnt            :            145
missed_one_pps_cnt     :              0
missed_tod_rx_cnt      :              0
```

If input pps hasn't been successfully configured (and connected), you'll see 0 for all outputs.

Restart counters at 0 with:
```shell
# debug ptp pps-tod statistics clear
```

### Disable pps in

From `icli` `configure terminal`:
```shell
no ptp 2 virtual-port mode
```

### Configure pps out

Here, we'll use "ptp 3" since we used "ptp 2" for pps-in.

From `icli` `configure terminal`:
```shell
ptp 3 virtual-port mode pps-out 4
```

### Check pps out

You can check the status of pps out by running `show ptp ext`.

If pps out isn't enabled, the output should should show `enabled: False` as below:

```shell
# show ptp ext
PTP External One PPS mode: Output, Clock output enabled: False, frequency : 1,
Preferred adj method     : Auto, PPS clock domain : 0
```

If pps out is enabled, the output should should show `enabled: True` as below:

```shell
# show ptp ext
PTP External One PPS mode: Output, Clock output enabled: True, frequency : 1,
Preferred adj method     : Auto, PPS clock domain : 0 
```

### Disable pps out

From `icli` `configure terminal`:
```shell
no ptp 3 virtual-port mode
```

### JSON-RPC / JSONC equivalent

**PPS IN** (uses a fixed value for pin from vars):

Enable:

```bash
gs-rpc post --continue --raw --vars ./ptp-template/vars-ptp.yaml -D PTP_ID=2 -f ./ptp-template/pps-in-only.jsonc
```

Disable:

```bash
gs-rpc post --continue --raw --vars ./ptp-template/vars-ptp.yaml -D PTP_ID=2 -f ./ptp-template/pps-virtual-port-disable.jsonc
```

**PPS OUT** (uses a fixed value for pin and optional delay from vars):

Enable:

```bash
gs-rpc post --continue --raw --vars ./ptp-template/vars-ptp.yaml -D PTP_ID=3 -f ./ptp-template/pps-out-only.jsonc
```

Disable:

```bash
gs-rpc post --continue --raw --vars ./ptp-template/vars-ptp.yaml -D PTP_ID=3 -f ./ptp-template/pps-virtual-port-disable.jsonc
```

## Recipe: PTP as Standalone Master

This config sets up the switch as a master on the network without having it synchronized to an actual ptp grandmaster with accurate time. Therefore, the usage is limited but can show sending of ptp UDP packets albeit marked with fields indicating low quality and others missing.

### Enable Time Sync with NTP

You'll want to put some reasonable time into your PTP clock. We can get that from system time but let's first make system time accurate with ntp.

`icli`:
```shell
configure terminal
ntp
ntp server 1 ip-address IP_ADDRESS_OF_ACCESSIBLE_SERVER
```

### Configure PTP as Master

Here, we'll use `ptp 2` and `domain 1` just to highlight something other than defaults of 0.

`icli`:
```shell
configure terminal
ptp 2 mode master twostep ip4multi twoway vid 1 0 clock-domain 1
ptp 2 domain 1
```

The following are included for reference but do not appear to affect the actual packets sent:
`icli`:
```shell
configure terminal
ptp 2 time-property utc-offset 37 valid
ptp 2 time-property ptptimescale
ptp 2 time-property time-source 160
ptp 2 virtual-port time-property utc-offset 37 valid ptptimescale time-source 160
```

Since ntp is running, we'll show our ptp clock has the incorrect time then update it.

`icli`:
```shell
# show ptp 0 local-clock
PTP Time (0)    : 1970-01-01T01:14:39+00:00 236,823,444
Clock Adjustment method: Internal Timer
```

Since ntp is setting the system-time, we'll grab from it and copy to ptp 2 then print the value:
`icli`:
```shell
# configure terminal
(config)# ptp system-time get 2
System clock synch mode (Get PTP time from System time)
(config)# exit
# show ptp 2 local-clock
PTP Time (2)    : 2025-10-01T23:03:03+00:00 968,976,017
Clock Adjustment method: Internal Timer
```

**NOTE**: Though the wording is "synch mode" and the `system-time get` command is saved to `running-config` (and copied to `startup-config` if persisted), it looks like this command must be run again after reboot to synch the ptp clock from system time.

Below, you can see that the `Valid` field of `time-property` is False (among other things) but that won't prevent you from sending some test packets out as a master.

`icli`:
```
# show ptp 0 time-property
UtcOffset  Valid  leap59  leap61  TimeTrac  FreqTrac  ptpTimeScale  TimeSource
---------  -----  ------  ------  --------  --------  ------------  ----------
0          False  False   False   False     False     True          160
```

To send on a port, we must enable ptp on that part. Again, we'll use `GigabitEthernet 1/24`:
`icli`:
```shell
configure terminal
interface GigabitEthernet 1/24
ptp 2
```

If everything worked, ptp UDP packets should start flowing on `GigabitEthernet 1/24`.

### Check UDP PTP Packets with tcpdump

Below is an example capture from a device plugged in to `GigabitEthernet 1/24`:

```bash
$ sudo tcpdump -i eth0 -nn -e -vv -s 1500 host IP_ADDRESS_OF_SWITCH
    192.168.129.15.320 > 224.0.1.129.320: [no cksum] PTPv2, v1 compat : no, msg type : announce msg, length : 64, domain : 1, reserved1 : 0, Flags [timescale], NS correction : 0, sub NS correction : 0, reserved2 : 0, clock identity : 0x8227c7fffe4dae01, port id : 24, seq id : 961, control : 5 (Other), log message interval : 1, originTimeStamp : 0 seconds 0 nanoseconds, origin cur utc :0, rsvd : 0, gm priority_1 : 128, gm clock class : 187, gm clock accuracy : 254, gm clock variance : 65535, gm priority_2 : 128, gm clock id : 0x8227c7fffe4dae01, steps removed : 0, time source : 0xa0
```

Since we are demonstrating sending as a master without a true time source, just note that some of the values above are not great for actual ptp synchronization.

* Domain: 1
* Flags: [timescale] only → PTP timescale bit is set, but UTC-offset-valid is not set.
* currentUtcOffset: 0 → needs to be 37.
* GM clockClass: 187 → default "other." For a free-running GM, use 248.
* GM accuracy: 254 (unknown) → fine if you don't want to claim accuracy.
* GM variance: 65535 → fine for "don't claim".
* TimeSource: 0xa0 (= 160, internal osc) → already matches your config.

But, POC for sending PTP without synchronization to a grandmaster is demonstrated.

### JSON-RPC / JSONC equivalent

Run the **master-only POC**:

If you don't have ntp enabled on your machine, configure that first (update to IP of available ntp server):

```bash
gs-rpc call ntp.config.global.set true
gs-rpc post -d '{"method":"ntp.config.servers.set","params":[1, "IP_ADDRESS_OF_ACCESSIBLE_SERVER"]}'
```

**NOTE**: If you are just now enabling ntp, please wait a bit to allow clock to synchronize.

```bash
gs-rpc post --continue --raw --vars ./ptp-template/vars-ptp.yaml -D PTP_ID=2 -D PTP_DOMAIN=1 -D DOWNSTREAM2_IFNAME="IGN" -f ./ptp-template/ptp-master-only-poc.jsonc
```

Above, we had an `icli` command for copying system-time to ptp 2. This doesn't quite appear to be available in json-rpc as there is no id argument. So, you'll need to use `icli` as above to set your clock since below will only work for whatever values are hard-coded for ptp id or clock-domain. It looks like `icli` can specify a ptp id but the json-rpc will tie to whatever ptp is on clock-domain 0.

```bash
gs-rpc post --continue --raw -d '{"method":"ptp.config.global.systemTimeSyncMode.set","params":[{"mode":"systemTimeSyncGet"}]}'
```

---

## gs-rpc Variable Notes

The recipes have equivalent **JSONC** profiles that can be posted with **gs-rpc**.
Variables come from `./ptp-template/vars-ptp.yaml` (you can override with `-D KEY=VALUE`).
Recommended order: `--vars ... [-D KEY=VALUE ...] -f <profile.jsonc>`.

**Variable precedence (later wins):**
1. `--vars FILE` (repeatable; later files override earlier ones)
2. `-D KEY=VALUE` (inline CLI overrides on top of vars files)
3. `${env:NAME}` only if `--allow-env` is used can read variables from environment
