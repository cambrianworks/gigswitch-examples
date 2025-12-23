# GigSwitch User Documentation

Welcome to the GigSwitch user documentation repository. This master guide will help you navigate background, available tools and configuration.

**Note:** Throughout these docs, `${GS_IP}` and `${GS_PASS}` are used as placeholders for hostname/IP and admin password. The initial password for user `admin` is `""` (empty password).

## Table of Contents

1. [Introduction & Scope](#introduction--scope)
2. [Prerequisites](#prerequisites)
3. [Navigation Tips](#navigation-tips)
4. [Available Guides](#available-guides)

---

## Introduction & Scope

This documentation covers:

- Understanding switch basics including hardware, fileystem and capabilities
- Standard management methods (Web UI, CLI, vson, curl)
- Helper tool (`gs-rpc`) usage
- Configuration recipes using JSONL files

This document is designed for end users working with the GigSwitch.

---

## Prerequisites

- Access to the switch’s management interface (SSH or API)
- Credentials for switch admin user
- `gs-rpc` installed and bootstrapped (see `helper-tool.md`)
- Standard Debian/Ubuntu Linux machine recommended with `apt` installed packages
  - `sudo apt install curl jq python3 python3-requests python3-yaml`

---

## Navigation Tips

- Search for keywords in the `recipes/` folder to find specific configurations.
- Use the `grep` command for `gs-rpc` or `vson` or search in the `json-spec.json` downloaded JSON-RPC spec file.

---

## Available Guides

### Getting Started
- **Quick Tips**: Quick tips such as basic login - see [quick-tips.md](quick-tips.md)
- **Switch Basics**: General capabilities - see [switch-basics.md](switch-basics.md)
- **Standard Tools**: Overview of management interfaces - see [standard-tools.md](standard-tools.md)
- **Helper Tool**: Installation & commands - see [helper-tool-gs-rpc.md](helper-tool-gs-rpc.md)

### Configuration & Management
- **Recipes**: Detailed configuration examples - in `recipes/` directory - see [recipes/README.md](recipes/README.md)
- **HTTP Config Upload**: Upload and apply configs via HTTP/curl - see [http-config-upload.md](http-config-upload.md)
- **File Transfers**: HTTP, TFTP, wget, SCP, and serial transfer methods - see [file-transfers.md](file-transfers.md)

### Emergency Recovery
- **Serial Config Restore**: Restore config when network is down - see [serial-config-restore.md](serial-config-restore.md)
