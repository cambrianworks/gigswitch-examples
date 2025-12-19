# Quick Tips

Below are some quick tips useful for working with the GigSwitch.

Additional tips will be added over time but initial tips are for obtaining a root shell on the GigSwitch device and viewing the configuration.

---

## Tip 1: Manually Obtain a Root Shell from the ssh CLI

1. SSH into the switch as the `admin` user (**or any user with sufficient privileges**):

   ```bash
   ssh admin@<SWITCH_IP>
   ```

   Enter the admin password when prompted.

2. Enable debug mode:

   ```bash
   platform debug allow
   ```

3. Enter the debug system shell:

   ```bash
   debug system shell
   ```

4. (optional) Launch any particular shell variant:

   ```bash
   exec /bin/sh -l
   ```

5. When finished, exit the shell:

   ```bash
   exit
   ```

6. And exit the CLI:

   ```bash
   exit
   ```

---

## Tip 2: Scripted Root Shell via `expect`

This `expect` script automates the above steps. **You must inline the actual IP and password**—do **not** use variables as they would need to be interpreted by the `expect` script. Save as `gs-root-shell` to some directory in your path.

```tcl
#!/usr/bin/env expect
set timeout 10
# Replace the following with literal values
spawn ssh admin@<GS_IP>
expect "assword:"
send "<GS_PASS>\r"
expect "#"
send "platform debug allow\r"
expect "#"
send "debug system shell\r"
expect "#"
send "exec /bin/sh -l\r"
expect "#"
interact
```

### Requirements

- Install `expect` (Debian/Ubuntu):

  ```bash
  sudo apt update && sudo apt install -y expect
  ```

- Ensure the script is executable:

  ```bash
  chmod +x gs-root-shell
  ```

---

## Tip 3: Manually review the configs

Examples below assume you've logged in to the GigSwitch device and have shell access (`debug system shell`).

### Review default-config

You can review how the default config is stored by executing:

```
cat /switch/icfg/default-config
```

**Note:** Above is actually just a soft-link: `default-config` -> `/etc/mscc/icfg/default-config`

The output should look something like this:

```
! Default configuration file
! --------------------------
!
! This file is read and applied immediately after the system configuration is
! reset to default. The file is read-only and cannot be modified.

vlan 1
 name default

voice vlan oui 00-01-E3 description Siemens AG phones
voice vlan oui 00-03-6B description Cisco phones
voice vlan oui 00-0F-E2 description H3C phones
voice vlan oui 00-60-B9 description Philips and NEC AG phones
voice vlan oui 00-D0-1E description Pingtel phones
voice vlan oui 00-E0-75 description Polycom phones
voice vlan oui 00-E0-BB description 3Com phones

interface vlan 1
 ip address dhcp fallback 192.0.2.1 255.255.255.0 timeout 120

end
```

### Review startup-config

You can review how the current startup config is stored by executing:

From icli:

```
show startup-config
```

From shell:

```
cat /switch/icfg/startup-config
```

The output will vary based on your config but might have customizations such as:

```

...

ip dhcp server
!
vlan 1,10,20
!
!
!
!
ip name-server 0 8.8.8.8
ip dhcp snooping
ntp
ntp server 1 ip-address pool.ntp.org
ntp server 2 ip-address time.google.com
ip http secure-server

...

```

### Review running-config

The `running-config` will contain recent changes not yet saved to `startup-config` but will be equivalent if you haven't made changes since booting.

The `running-config` is best reviewed from icli:

```
show running-config
```

**TIP:** Add the `all-defaults` argument to see a more complete config that includes applying the default values.

```
show running-config all-defaults
```

If you are having to step through multiple pages, you can turn off pagination from icli with:

```
terminal length 0
```
