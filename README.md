# gigswitch-examples

This repository is a public-facing collection of examples and tools for the **GigSwitch** platform. This includes example configuration documentation, setup recipes, tools and other tips for GigSwitch.

## Getting Started

This repository is best used on a Linux machine with network access to a GigSwitch device and common tools installed such as `Python 3`, `curl`, `jq` and `ssh`. However, any machine with firewall access can connect to the GigSwitch using:
* http(s)://HOSTNAME - general web interface
* ssh admin@HOSTNAME - ICLI (command line) or shell interface
* http(s)://HOSTNAME/json_rpc - JSON RPC interface

To clone this repository to your local machine:

```bash
git clone https://github.com/cambrianworks/gigswitch-examples.git
```

## Documentation

Documentation for configuration, recipes and quick tips are all in the `docs/` subdirectory:

- [Docs README](./docs/README.md): Starting point for navigating the documentation.

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
