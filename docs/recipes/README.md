# Configuration Recipes

This directory contains short README files for various switch configuration or utility routines. Typically, these README files reference JSONL files for applying JSON‑RPC. These JSONL files are designed to be applied using the `gs-rpc` helper tool.

> **Note:** Ensure you have bootstrapped credentials via `gs-rpc bootstrap` before applying any recipe.

You can also make use of referenced `${GS_RECIPES}` environment variable by setting the following in your environment, such as in `~/.bashrc`:

```
export GS_RECIPES=/path/to/recipes/examples
```

## Recipes Index

- [X filesystem-capabilities.md](filesystem-capabilities.md)   Filesystem & capabilities
- [persist-changes.md](persist-changes.md)   Persist current changes
- [X compare-configs.md](compare-configs.md)   View changes vs defaults
- [reset-factory.md](reset-factory.md)   Reset to factory defaults
- [X reset-saved-state.md](reset-saved-state.md)   Reset to saved state
- [reboot.md](reboot.md)   Reboot commands
- [save-config.md](save-config.md)   Save config commands
- [support-https.md](support-https.md)   Enable https web access
- [set-https-cert.md](set-https-cert.md)   Set custom certificate for https
- [X network-setup.md](network-setup.md)   DNS/NTP/DHCP setup
- [X logging.md](logging.md)   Enable & review logging
- [X ports-list.md](ports-list.md)   List ports & capabilities
- [enable-disable-ports.md](enable-disable-ports.md)   Enable and disable individual ports
- [vlan-setup.md](vlan-setup.md)   VLAN configuration
- [daisy-chain-vlan-10g-throughput.md](daisy-chain-vlan-10g-throughput.md)   Daisy chain 10G ports with VLANs to measure or verify throughput
- [X snmp-setup.md](snmp-setup.md)   SNMP configuration
- [ptp-setup.md](ptp-setup.md)   PTP configuration
- [X broadcast-storm.md](broadcast-storm.md)   Broadcast storm control

## Applying a Recipe

To apply a JSONL recipe:

```bash
gs-rpc post -f ${GS_RECIPES}/<recipe-name>.jsonl
```

## Examples Directory

The `examples/` subdirectory contains standalone `.jsonl` example files that can be used directly with `gs-rpc` though you should typically make a copy and customize for your needs:

```plaintext
recipes/examples/
└── *.jsonl
```

Use these examples as templates or for quick-start configurations.
