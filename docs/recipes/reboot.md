# Reboot

Use this recipe to reboot the switch.

**WARNING:** If you've made configuration changes that you don't want to lose, see [persist-changes.md](persist-changes.md). On the other hand, if you made problematic changes and want to reboot with a previously saved sane state, this could be the command for you.

## Recipe: Reboot Switch

- **Description**: Reboot switch and initialize from startup-config.
- **JSONL File**: [examples/reboot-cold.jsonl](examples/reboot-cold.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/reboot-cold.jsonl
  ```

### Alternative CLI Command

```bash
reload cold
```

### Alternative Web UI Approach

Maintenance -> Restart Device
