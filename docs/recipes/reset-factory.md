# Reset Factory

Use this recipe to revert switch’s saved configuration to the default configuration without a reboot.

To then reboot with the updated configuration, see [reboot.md](reboot.md).

## Recipe: Reset Factory

- **Description**: Saves the default configuration to the startup configuration.
- **JSONL File**: [examples/reset-factory.jsonl](examples/reset-factory.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/reset-factory.jsonl
  ```

### Alternative CLI Command

```bash
reload defaults
```

### Web UI Save Backup

The Web UI gives options to save the various configs under Maintenance -> Configuration -> Download. Choose any of: `running-config`, `default-config` or `startup-config`.

