# Copy Config to or from GigSwitch

Use these recipes to copy the running/startup config to an sftp server or copy a running/startup config from sftp server to device (you can't overwrite the default config and calls below don't allow obtaining default config).

**Common use case:** It's common that you'll be updating the live or `running-config` and want to take periodic snapshots without necessarily committing to replacing the `startup-config`.

**Other common use cases:**

* Replace running or startup config with a saved config
* Save a copy of the running or startup config
* See [persist-changes.md](persist-changes) and [reset-factory.md](reset-factory) for examples that copy `running-config` to `startup-config` and `default-config` to `startup-config`

**NOTE:** In the recipes, you'll need to update `{TFTP_SERVER_IP}` with the actual ip address of the server (or hostname if you've configured DNS on the switch).

## Prerequisites

You must have an sftp running at the default port and that your routing and firewall can connect to this machine at UDP port 69.

### Example tftp server setup

Below is a convenience script that should help set this up on an accessible Ubuntu machine. Adjust as needed or use an existing available tftp server.

`setup-tftp.sh`

```bash
sudo apt-get update
sudo apt-get install -y atftpd
sudo mkdir -p /srv/tftp
sudo chmod -R a+rwX /srv/tftp

sudo tee /etc/systemd/system/atftpd.service >/dev/null <<'EOF'
[Unit]
Description=Advanced TFTP server
After=network.target
[Service]
ExecStart=/usr/sbin/atftpd --daemon --no-fork --verbose=5 --maxthread 100 /srv/tftp
Restart=always
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now atftpd
```

### Test tftp server

Make sure service is running:

```bash
systemctl status atftpd.service
```

Test local installation (localhost):

Ensure `tftp` and/or `curl` is installed:

```bash
sudo apt install tftp curl
```

Copy a file back and forth to sftp server:

With `tftp` (note that local ip should also work but `localhost` was problematic):

```bash
echo "Hello test tftp" > test-tftp.txt
tftp 127.0.0.1 -v -m binary -c put test-tftp.txt
tftp 127.0.0.1 -v -m binary -c get test-tftp.txt test-tftp-download.txt
diff test-tftp.txt test-tftp-download.txt
```

With `curl`:

```bash
echo "Hello test curl" > test-curl.txt
curl -v -T test-curl.txt tftp://127.0.0.1
curl -v tftp://127.0.0.1/test-curl.txt -o test-curl-download.txt
diff test-curl.txt test-curl-download.txt
```

## Recipe: Get a copy of the running config and save to tftp server

- **Description**: Copy running config to tftp server.
- **JSONL File** (must update `{TFTP_SERVER_IP}`): [examples/get-running-config.jsonl](examples/get-running-config.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/get-running-config.jsonl
  ```
- **Options**: Change `runningConfig` to `startupConfig` to obtain the startup config. (Value `defaultConfig` is not supported.)
- **Note**: The `id` `99` line is optional and simply retrieves status of last copy.
- **Note**: The argument `"Merge": false` is selectively used. (When you view the switch config files, they typically only show what settings are different from the default config, thus highlighting only your overrides.) These are the docs from the json spec:
  > This flag works only if DestinationConfigType is runningConfig(1). true is to merge the source configuration into the current running configuration. false is to replace the current running configuration with the source configuration.

### Alternative CLI Command

```bash
copy running-config tftp://{TFTP_SERVER_IP}:69/running-config
```

Or:

```bash
copy startup-config tftp://{TFTP_SERVER_IP}:69/startup-config
```

**Note:** These are the same names used on the switch filesystem at `/switch/icfg/{running,startup,default}-config`

**Note:** In the `icli` case, you can specify the port (`:69`) of the `tftp` server but, in practice, any port override using the `json-rpc` call is ignored.

## Recipe: Upload a config from a tftp server to the switch

You can copy from the tftp to an active switch config by swapping the source and destination parameters.

- **Description**: Copy from tftp server to running config.
- **JSONL File** (must update `{TFTP_SERVER_IP}`): [examples/set-running-config.jsonl](examples/set-running-config.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/set-running-config.jsonl
  ```
- **Options**: Change `runningConfig` to `startupConfig` so update startup config instead. (The `defaultConfig` is read-only and can't be updated.)
- **Note**: The `id` `99` line is optional and simply retrieves status of last copy.
- **Note**: The argument `"Merge": false` is selectively used. (When you view the switch config files, they typically only show what settings are different from the default config, thus highlighting only your overrides.) These are the docs from the json spec:
  > This flag works only if DestinationConfigType is runningConfig(1). true is to merge the source configuration into the current running configuration. false is to replace the current running configuration with the source configuration.
  In other words, when updating `runningConfig`, you could create a config file that only contains changes to apply and any other changes in `runningConfig` that differ from `defaultConfig` should be preserved.

### Alternative CLI Command

```bash
copy tftp://{TFTP_SERVER_IP}:69/running-config running-config
```

Or:

```bash
copy tftp://{TFTP_SERVER_IP}:69/startup-config startup-config
```
