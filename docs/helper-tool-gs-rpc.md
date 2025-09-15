# gs-rpc

Command line tool for sending json-rpc commands to GigSwitch, modeled after `vson` but extended to support jsonl for multiple inputs, jsonc for templating inputs with comments and variables, and support to snapshot the `running-config` before and after updates.

This document shows how to install `gs-rpc` and gives some example commands as well as compares to the `vson` tool.

For more advanced templating with `jsonc`, see: [gs-rpc-jsonc-templating](gs-rpc-jsonc-templating.md).

## Install

On a Debian machine with Cambrian package access, install:

```
sudo apt install gs-rpc
```

## vson

The default CLI tool for sending json-rpc is called `vson` and is available via `git` here: [json-rpc-util](https://github.com/vtss/json-rpc-util.git)

## gs-rpc versus vson

### vson limitations and behaviors

The `vson` CLI tool

1. Requires `-d ADDRESS` in each call as well as `-c` to indicate to use saved spec file.
1. Doesn't allow arguments for alternative ports (port 80 for http and 443 for https are hard-coded; not ideal for port forwarding).
1. Reformats json outputs often to `name: value` pairs thus introducing a new format versus ability to leverage json

### gs-rpc differences

1. Adds `bootstrap` option and preserves login and port information in `~/.gigswitch/config.yaml`
1. Inputs and outputs leverage consistent json where appropriate

### Sub-commands

Both `vson` and `gs-rpc` include the following sub-commands:

**call:** Call a json-rpc method on command line

**grep:** Look for methods matching the input string

**spec:** For a specified method, look up information on arguments and return value

**update-spec:** Updated the cached json-rpc spec file

`gs-rpc` adds the following:

**post:** Post given json body as json-rpc input (`{"method": "method-name", "params": [PARAMS], "id": SOME_ID}`). Will create arbitrary `id` if omitted and will set `params` to `[]` if omitted. Can specify a file file with jsonl calls to apply with `-f`, pass on command line with `-d` or omit and read jsonl from `stdin`. Auto-detects and allows multi-line json input also (whereas each jsonl structure would be on a single line).

**type:** Look up type information for the specified type.

## Example calls

Below are some examples using both `vson` and `gs-rpc`.

**grep acl**

```
$ vson -c -d HOSTNAME grep acl
acl.config.ace.config.get
acl.config.ace.config.get
acl.config.ace.config.set
acl.config.ace.config.add
acl.config.ace.config.del
acl.config.ace.precedence.get
acl.config.ace.precedence.get
acl.config.ratelimiter.get
acl.config.ratelimiter.get
acl.config.ratelimiter.set
acl.config.interface.get
acl.config.interface.get
acl.config.interface.set
acl.status.ace.status.get
acl.status.ace.status.get
acl.status.ace.hitCount.get
acl.status.ace.hitCount.get
acl.status.ace.crossedThreshold.get
acl.status.ace.crossedThreshold.get
acl.status.interface.hitCount.get
acl.status.interface.hitCount.get
acl.control.global.set
acl.control.interface.get
acl.control.interface.get
acl.control.interface.set
acl.capabilities.get
```

```
$ gs-rpc grep acl
acl.capabilities.get
acl.config.ace.config.add
acl.config.ace.config.del
acl.config.ace.config.get
acl.config.ace.config.get
acl.config.ace.config.set
acl.config.ace.precedence.get
acl.config.ace.precedence.get
acl.config.interface.get
acl.config.interface.get
acl.config.interface.set
acl.config.ratelimiter.get
acl.config.ratelimiter.get
acl.config.ratelimiter.set
acl.control.global.set
acl.control.interface.get
acl.control.interface.get
acl.control.interface.set
acl.status.ace.crossedThreshold.get
acl.status.ace.crossedThreshold.get
acl.status.ace.hitCount.get
acl.status.ace.hitCount.get
acl.status.ace.status.get
acl.status.ace.status.get
acl.status.interface.hitCount.get
acl.status.interface.hitCount.get
```

**spec acl.capabilities.get**

```
$ vson -c -d HOSTNAME spec acl.capabilities.get
Method name:
  acl.capabilities.get
Parameters:

Results:
  Result #0 {"name"=>"Argument1", "type"=>"vtss_appl_acl_capabilities_t"}
            {"type-name"=>"vtss_appl_acl_capabilities_t", "class"=>"Struct", "description"=>"", "encoding-type"=>"Object", "elements"=>[{"name"=>"AceIdMax", "type"=>"uint32_t", "description"=>"Maximum ID of ACE."}, {"name"=>"PolicyIdMax", "type"=>"uint32_t", "description"=>"Maximum ID of policy."}, {"name"=>"RateLimiterIdMax", "type"=>"uint32_t", "description"=>"Maximum ID of rate limiter."}, {"name"=>"EvcPolicerIdMax", "type"=>"uint32_t", "description"=>"Maximum ID of EVC policer (obsolete. Always 0)."}, {"name"=>"RateLimiterBitRateSupported", "type"=>"vtss_bool_t", "description"=>"If true, the rate limiter can be configured by bit rate."}, {"name"=>"EvcPolicerSupported", "type"=>"vtss_bool_t", "description"=>"If true, EVC policer can be configured (obsolete. Always false)."}, {"name"=>"MirrorSupported", "type"=>"vtss_bool_t", "description"=>"If true, mirror action is supported."}, {"name"=>"MultipleRedirectPortsSupported", "type"=>"vtss_bool_t", "description"=>"If true, redirect port list can be configured with multiple ports. If false, redirect port list can be configured with only one single port."}, {"name"=>"SecondLookupSupported", "type"=>"vtss_bool_t", "description"=>"If true, second lookup can be configured."}, {"name"=>"MultipleIngressPortsSupported", "type"=>"vtss_bool_t", "description"=>"If true, ingress port list can be configured with multiple ports. If false, ingress port list can be configured with only one single port."}, {"name"=>"EgressPortSupported", "type"=>"vtss_bool_t", "description"=>"If true, egress port list can be configured."}, {"name"=>"VlanTaggedSupported", "type"=>"vtss_bool_t", "description"=>"If true, VLAN tagged can be configured."}, {"name"=>"StackableAceSupported", "type"=>"vtss_bool_t", "description"=>"If true, stackable ACE is supported. The 'switch' and 'switchport' ACE ingress type can be configured. Otherwize, only 'any' and 'specific' ACE ingress type can be configured."}]}
```

```
$ gs-rpc spec acl.capabilities.get
Instance 1, 0 parameters
{
  "method-name": "acl.capabilities.get",
  "web-privilege": {
    "id": "Security(network)",
    "type": "STATUS_RO"
  },
  "params": [],
  "result": [
    {
      "name": "Argument1",
      "type": "vtss_appl_acl_capabilities_t"
    }
  ]
}
```

**type vtss_appl_acl_capabilities_t** (`gs-rpc` only)

```
$ gs-rpc type vtss_appl_acl_capabilities_t
{
  "type-name": "vtss_appl_acl_capabilities_t",
  "class": "Struct",
  "description": "",
  "encoding-type": "Object",
  "elements": [
    {
      "name": "AceIdMax",
      "type": "uint32_t",
      "description": "Maximum ID of ACE."
    },
    {
      "name": "PolicyIdMax",
      "type": "uint32_t",
      "description": "Maximum ID of policy."
    },
    {
      "name": "RateLimiterIdMax",
      "type": "uint32_t",
      "description": "Maximum ID of rate limiter."
    },
    {
      "name": "EvcPolicerIdMax",
      "type": "uint32_t",
      "description": "Maximum ID of EVC policer (obsolete. Always 0)."
    },
    {
      "name": "RateLimiterBitRateSupported",
      "type": "vtss_bool_t",
      "description": "If true, the rate limiter can be configured by bit rate."
    },
    {
      "name": "EvcPolicerSupported",
      "type": "vtss_bool_t",
      "description": "If true, EVC policer can be configured (obsolete. Always false)."
    },
    {
      "name": "MirrorSupported",
      "type": "vtss_bool_t",
      "description": "If true, mirror action is supported."
    },
    {
      "name": "MultipleRedirectPortsSupported",
      "type": "vtss_bool_t",
      "description": "If true, redirect port list can be configured with multiple ports. If false, redirect port list can be configured with only one single port."
    },
    {
      "name": "SecondLookupSupported",
      "type": "vtss_bool_t",
      "description": "If true, second lookup can be configured."
    },
    {
      "name": "MultipleIngressPortsSupported",
      "type": "vtss_bool_t",
      "description": "If true, ingress port list can be configured with multiple ports. If false, ingress port list can be configured with only one single port."
    },
    {
      "name": "EgressPortSupported",
      "type": "vtss_bool_t",
      "description": "If true, egress port list can be configured."
    },
    {
      "name": "VlanTaggedSupported",
      "type": "vtss_bool_t",
      "description": "If true, VLAN tagged can be configured."
    },
    {
      "name": "StackableAceSupported",
      "type": "vtss_bool_t",
      "description": "If true, stackable ACE is supported. The 'switch' and 'switchport' ACE ingress type can be configured. Otherwize, only 'any' and 'specific' ACE ingress type can be configured."
    }
  ]
}
```

**call acl.capabilities.get**

```
$ vson -c -d HOSTNAME call acl.capabilities.get
Calling acl.capabilities.get:
    AceIdMax:                         512
    PolicyIdMax:                      255
    RateLimiterIdMax:                  16
    EvcPolicerIdMax:                    0
    RateLimiterBitRateSupported:     true
    EvcPolicerSupported:            false
    MirrorSupported:                 true
    MultipleRedirectPortsSupported:  true
    SecondLookupSupported:          false
    MultipleIngressPortsSupported:   true
    EgressPortSupported:             true
    VlanTaggedSupported:             true
    StackableAceSupported:          false
```

```
$ gs-rpc call acl.capabilities.get
{
  "AceIdMax": 512,
  "PolicyIdMax": 255,
  "RateLimiterIdMax": 16,
  "EvcPolicerIdMax": 0,
  "RateLimiterBitRateSupported": true,
  "EvcPolicerSupported": false,
  "MirrorSupported": true,
  "MultipleRedirectPortsSupported": true,
  "SecondLookupSupported": false,
  "MultipleIngressPortsSupported": true,
  "EgressPortSupported": true,
  "VlanTaggedSupported": true,
  "StackableAceSupported": false
}
```

**call vlan.status.interface.get "Gi 1/1" "combined"**

```
$ vson -c -d HOSTNAME call vlan.status.interface.get "Gi 1/1" "combined"
Calling vlan.status.interface.get:
    Pvid:                    10
    Uvid:                    10
    PortType:                 c
    IngressFiltering:      true
    IngressAcceptance:      all
    EgressTagging:     untagAll
```

```
$ gs-rpc call vlan.status.interface.get "Gi 1/1" "combined"
{
  "Pvid": 10,
  "Uvid": 10,
  "PortType": "c",
  "IngressFiltering": true,
  "IngressAcceptance": "all",
  "EgressTagging": "untagAll"
}
```

**post -d '{"method": "vlan.status.interface.get", "params":["Gi 1/1","combined"]}'** (`gs-rpc` only)

```
$ gs-rpc post -d '{"method": "vlan.status.interface.get", "params":["Gi 1/1","combined"]}'
{
  "Pvid": 10,
  "Uvid": 10,
  "PortType": "c",
  "IngressFiltering": true,
  "IngressAcceptance": "all",
  "EgressTagging": "untagAll"
}
```

**post MULTIPLE LINES FROM FILE** (`gs-rpc` only)

```
$ cat show-config.jsonl
{"method":"dhcpServer.config.global.get","params":[],"id":1}
{"method":"dhcpServer.config.pool.get","params":[],"id":2}
{"method":"dhcpServer.status.binding.get","params":[],"id":3}
{"method":"vlan.config.get","params":[],"id":4}
```

```
$ gs-rpc post -f show-config.jsonl
{
  "Mode": true
}
[
  {
    "key": "VLAN 10",
    "val": {
      "PoolType": "network",
      "Ipv4Address": "192.168.10.0",
      "SubnetMask": "255.255.255.0",
      "SubnetBroadcast": "192.168.10.255",
      "LeaseDay": 0,
      "LeaseHour": 0,
      "LeaseMinute": 0,
      "DomainName": "",
      "DefaultRouter1": "192.168.10.1",
      "DefaultRouter2": "0.0.0.0",
      "DefaultRouter3": "0.0.0.0",
      "DefaultRouter4": "0.0.0.0",
      "DnsServer1": "8.8.8.8",
      "DnsServer2": "8.8.4.4",
      "DnsServer3": "0.0.0.0",
      "DnsServer4": "0.0.0.0",
      "NtpServer1": "0.0.0.0",
      "NtpServer2": "0.0.0.0",
      "NtpServer3": "0.0.0.0",
      "NtpServer4": "0.0.0.0",
      "NetbiosNodeType": "nodeNone",
      "NetbiosScope": "",
      "NetbiosNameServer1": "0.0.0.0",
      "NetbiosNameServer2": "0.0.0.0",
      "NetbiosNameServer3": "0.0.0.0",
      "NetbiosNameServer4": "0.0.0.0",
      "NisDomainName": "",
      "NisServer1": "0.0.0.0",
      "NisServer2": "0.0.0.0",
      "NisServer3": "0.0.0.0",
      "NisServer4": "0.0.0.0",
      "ClientIdentifierType": "none",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "00:00:00:00:00:00",
      "ClientHardwareAddress": "00:00:00:00:00:00",
      "ClientName": "",
      "VendorClassId1": "",
      "VendorSpecificInfo1": "",
      "VendorClassId2": "",
      "VendorSpecificInfo2": "",
      "VendorClassId3": "",
      "VendorSpecificInfo3": "",
      "VendorClassId4": "",
      "VendorSpecificInfo4": "",
      "ReservedOnly": false
    }
  },
  {
    "key": "VLAN 20",
    "val": {
      "PoolType": "network",
      "Ipv4Address": "192.168.20.0",
      "SubnetMask": "255.255.255.0",
      "SubnetBroadcast": "192.168.20.255",
      "LeaseDay": 0,
      "LeaseHour": 0,
      "LeaseMinute": 0,
      "DomainName": "",
      "DefaultRouter1": "192.168.20.1",
      "DefaultRouter2": "0.0.0.0",
      "DefaultRouter3": "0.0.0.0",
      "DefaultRouter4": "0.0.0.0",
      "DnsServer1": "8.8.8.8",
      "DnsServer2": "8.8.4.4",
      "DnsServer3": "0.0.0.0",
      "DnsServer4": "0.0.0.0",
      "NtpServer1": "0.0.0.0",
      "NtpServer2": "0.0.0.0",
      "NtpServer3": "0.0.0.0",
      "NtpServer4": "0.0.0.0",
      "NetbiosNodeType": "nodeNone",
      "NetbiosScope": "",
      "NetbiosNameServer1": "0.0.0.0",
      "NetbiosNameServer2": "0.0.0.0",
      "NetbiosNameServer3": "0.0.0.0",
      "NetbiosNameServer4": "0.0.0.0",
      "NisDomainName": "",
      "NisServer1": "0.0.0.0",
      "NisServer2": "0.0.0.0",
      "NisServer3": "0.0.0.0",
      "NisServer4": "0.0.0.0",
      "ClientIdentifierType": "none",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "00:00:00:00:00:00",
      "ClientHardwareAddress": "00:00:00:00:00:00",
      "ClientName": "",
      "VendorClassId1": "",
      "VendorSpecificInfo1": "",
      "VendorClassId2": "",
      "VendorSpecificInfo2": "",
      "VendorClassId3": "",
      "VendorSpecificInfo3": "",
      "VendorClassId4": "",
      "VendorSpecificInfo4": "",
      "ReservedOnly": false
    }
  }
]
[
  {
    "key": "192.168.10.2",
    "val": {
      "State": "committed",
      "Type": "automatic",
      "PoolName": "VLAN 10",
      "ServerId": "192.168.10.1",
      "VlanId": 10,
      "SubnetMask": "255.255.255.0",
      "ClientIdentifierType": "mac",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "E4:5F:01:EF:69:C1",
      "MacAddress": "E4:5F:01:EF:69:C1",
      "Lease": "infinite",
      "TimeToExpire": "-"
    }
  },
  {
    "key": "192.168.10.3",
    "val": {
      "State": "committed",
      "Type": "automatic",
      "PoolName": "VLAN 10",
      "ServerId": "192.168.10.1",
      "VlanId": 10,
      "SubnetMask": "255.255.255.0",
      "ClientIdentifierType": "mac",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "E4:5F:01:EF:69:6F",
      "MacAddress": "E4:5F:01:EF:69:6F",
      "Lease": "infinite",
      "TimeToExpire": "-"
    }
  },
  {
    "key": "192.168.10.4",
    "val": {
      "State": "committed",
      "Type": "automatic",
      "PoolName": "VLAN 10",
      "ServerId": "192.168.10.1",
      "VlanId": 10,
      "SubnetMask": "255.255.255.0",
      "ClientIdentifierType": "mac",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "E4:5F:01:EF:69:54",
      "MacAddress": "E4:5F:01:EF:69:54",
      "Lease": "infinite",
      "TimeToExpire": "-"
    }
  },
  {
    "key": "192.168.10.5",
    "val": {
      "State": "committed",
      "Type": "automatic",
      "PoolName": "VLAN 10",
      "ServerId": "192.168.10.1",
      "VlanId": 10,
      "SubnetMask": "255.255.255.0",
      "ClientIdentifierType": "mac",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "E4:5F:01:EF:67:17",
      "MacAddress": "E4:5F:01:EF:67:17",
      "Lease": "infinite",
      "TimeToExpire": "-"
    }
  },
  {
    "key": "192.168.10.6",
    "val": {
      "State": "committed",
      "Type": "automatic",
      "PoolName": "VLAN 10",
      "ServerId": "192.168.10.1",
      "VlanId": 10,
      "SubnetMask": "255.255.255.0",
      "ClientIdentifierType": "mac",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "E4:5F:01:EF:67:39",
      "MacAddress": "E4:5F:01:EF:67:39",
      "Lease": "infinite",
      "TimeToExpire": "-"
    }
  },
  {
    "key": "192.168.20.2",
    "val": {
      "State": "committed",
      "Type": "automatic",
      "PoolName": "VLAN 20",
      "ServerId": "192.168.20.1",
      "VlanId": 20,
      "SubnetMask": "255.255.255.0",
      "ClientIdentifierType": "mac",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "E4:5F:01:EF:5D:0C",
      "MacAddress": "E4:5F:01:EF:5D:0C",
      "Lease": "infinite",
      "TimeToExpire": "-"
    }
  },
  {
    "key": "192.168.20.3",
    "val": {
      "State": "committed",
      "Type": "automatic",
      "PoolName": "VLAN 20",
      "ServerId": "192.168.20.1",
      "VlanId": 20,
      "SubnetMask": "255.255.255.0",
      "ClientIdentifierType": "mac",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "E4:5F:01:EF:69:7B",
      "MacAddress": "E4:5F:01:EF:69:7B",
      "Lease": "infinite",
      "TimeToExpire": "-"
    }
  },
  {
    "key": "192.168.20.4",
    "val": {
      "State": "committed",
      "Type": "automatic",
      "PoolName": "VLAN 20",
      "ServerId": "192.168.20.1",
      "VlanId": 20,
      "SubnetMask": "255.255.255.0",
      "ClientIdentifierType": "mac",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "E4:5F:01:EF:69:12",
      "MacAddress": "E4:5F:01:EF:69:12",
      "Lease": "infinite",
      "TimeToExpire": "-"
    }
  },
  {
    "key": "192.168.20.5",
    "val": {
      "State": "committed",
      "Type": "automatic",
      "PoolName": "VLAN 20",
      "ServerId": "192.168.20.1",
      "VlanId": 20,
      "SubnetMask": "255.255.255.0",
      "ClientIdentifierType": "mac",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "E4:5F:01:EF:69:B4",
      "MacAddress": "E4:5F:01:EF:69:B4",
      "Lease": "infinite",
      "TimeToExpire": "-"
    }
  },
  {
    "key": "192.168.20.6",
    "val": {
      "State": "committed",
      "Type": "automatic",
      "PoolName": "VLAN 20",
      "ServerId": "192.168.20.1",
      "VlanId": 20,
      "SubnetMask": "255.255.255.0",
      "ClientIdentifierType": "mac",
      "ClientIdentifierName": "",
      "ClientIdentifierMac": "E4:5F:01:EF:69:8D",
      "MacAddress": "E4:5F:01:EF:69:8D",
      "Lease": "infinite",
      "TimeToExpire": "-"
    }
  }
]
```
