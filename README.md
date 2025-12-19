# gigswitch-examples

This repository is a public-facing collection of examples and tools for the **GigSwitch** platform. This includes example configuration documentation, setup recipes, tools and other tips for GigSwitch.

## Getting Started

This repository is best used on a Linux machine with network access to a GigSwitch device and common tools installed such as `Python 3`, `curl`, `jq` and `ssh`. However, any machine with firewall access can connect to the GigSwitch using:
* http(s)://{GS_IP} - general web interface
* ssh admin@{GS_IP} - ICLI (command line) or shell interface
* http(s)://{GS_IP}/json_rpc - JSON RPC interface

To clone this repository to your local machine:

```bash
git clone https://github.com/cambrianworks/gigswitch-examples.git
```

## Documentation

Documentation for configuration, recipes and quick tips are all in the `docs/` subdirectory.

**Start here:** [docs/README.md](./docs/README.md) - Complete documentation index and navigation guide.

## Helper Scripts

The `bin/` directory contains useful scripts:

- **`gs-rpc`**: JSON-RPC helper tool for switch configuration (see [docs/helper-tool-gs-rpc.md](./docs/helper-tool-gs-rpc.md))
- **`gs-grab-running-config`**: Grab running config from switch
- **`gs-grab-running-config-wrapper`**: Wrapper for config grabbing
- **`setup_tftpd.sh`**: Automated TFTP server setup for file transfers
- **`debug_trace_capture.exp`**: Automated debug trace capture via serial console

Example usage:
```bash
# Set up TFTP server for file transfers
./bin/setup_tftpd.sh 6069 ~/tftp-files

# Capture debug traces via serial console
# (assumes GigSwitch serial port connected to /dev/ttyUSB0)
./bin/debug_trace_capture.exp /dev/ttyUSB0
```

## License

Licensed under either of

 * Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
   http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or
   http://opensource.org/licenses/MIT)

at your option.

### Contributing

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall
be dual licensed as above, without any additional terms or conditions.
