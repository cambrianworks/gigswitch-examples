# Persist Current Changes

Use this recipe to save the switch’s running configuration to the startup configuration, ensuring changes survive a reboot.

## Recipe: Copy Running to Startup Config

- **Description**: Saves the current running configuration as the startup configuration.
- **JSONL File**: [examples/copy-running-config-to-startup-config.jsonl](examples/copy-running-config-to-startup-config.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/copy-running-config-to-startup-config.jsonl
  ```

### Alternative CLI Command

```bash
copy running-config startup-config
```
