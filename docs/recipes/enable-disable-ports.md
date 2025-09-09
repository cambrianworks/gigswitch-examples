# Enable and Disable Ports to Save Power

Use these recipes to enable or disable individual ports. Disabling ports lowers PHY power draw when the link is not required. This provides operational flexibility to conserve power during mission operations.

**NOTE:** In the recipes, you'll need to update `{PORT_ID}` with the actual name of the port. You can list all the port ids with:
```bash
gs-rpc call port.config.get | jq '.[]["key"]'
```

To check the full status of an individual port, you can use a call like:
```bash
gs-rpc call port.config.get '"Gi 1/1"'
```

Look for the `Shutdown` line; this port is disabled:
```json
{
  "params": {
    "conf": {
      "Shutdown": true
    }
  }
}
```

## Recipe: Disable port

- **Description**: Disable a specific port.
- **JSONL File**: [examples/disable-port.jsonl](examples/disable-port.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/disable-port.jsonl
  ```

### Alternative CLI Command

**NOTE**: Example is for `GigabitEthernet 1/1` versus `10GigabitEthernet 1/N`. Use `<Tab>` to help expand options or `show running-config | include interface` to see names of configured interfaces.

```
# configure terminal 
# interface GigabitEthernet 
(config)# interface GigabitEthernet 1/1
(config-if)# shutdown
(config-if)# exit
(config)# exit
```

### Alternative Web Interface Config

`Configuration` → `Ports` → `Speed/Configured` → `Disabled`

## Recipe: Enable port

- **Description**: Enable a specific port.
- **JSONL File**: [examples/enable-port.jsonl](examples/enable-port.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/enable-port.jsonl
  ```

### Alternative CLI Command

**NOTE**: Example is for `GigabitEthernet 1/1` versus `10GigabitEthernet 1/N`. Use `<Tab>` to help expand options or `show running-config | include interface` to see names of configured interfaces.

```bash
# configure terminal
# interface GigabitEthernet
(config)# interface GigabitEthernet 1/1
(config-if)# no shutdown
(config-if)# exit
(config)# exit
```

### Alternative Web Interface Config

`Configuration` → `Ports` → `Speed/Configured` → `Enabled`
