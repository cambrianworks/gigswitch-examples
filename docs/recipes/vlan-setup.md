# VLAN Setup

This recipe contains information on setting up VLANs.

TODO: The lease times should be updated from 0.

TODO: Support `-c` option for `gs-rpc` that will "continue" if a jsonl line errored out but still continue to apply remaining lines.

## IMPORTANT

This recipe should be carefully reviewed since it sets AccessVlans and assumes your current list simply has `[1]` as the list. The setting is below which updates to `[1, 10, 20]` but assumes your default VLAN is 1 and would **remove any other VLANS in use**:

```
{"method":"vlan.config.global.main.set","params":[{ "CustomSPortEtherType": 34984, "AccessVlans": [ 1, 10, 20 ] }],"id":10}
```

You can review your current settings with the following to see if your current list contains more than just `[1]`:

```
gs-rpc call vlan.config.global.main.get
```

## Recipe: VLAN Setup

- **Description**: This recipe sets up VLAN 10 and 20 using ports 1-10, sets up a DHCP server to assign addresses for VLAN 10 as 192.168.10.* and VLAN 20 as 192.168.20.*.
- **JSONL File**: [examples/vlan-dhcp-ports-1-through-10.jsonl](examples/vlan-dhcp-ports-1-through-10.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/vlan-dhcp-ports-1-through-10.jsonl
  ```

## Notes

The jsonl lines `"id":99` are getters that could be omitted. They are intended to show some before and after values to see that change was applied and/or what the value for a setting was before being updated.
