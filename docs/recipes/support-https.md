# Support https

Use these recipes to configure https on the switch.

## Recipe: Enable https

- **Description**: Enable https on switch.
- **JSONL File**: [examples/enable-https.jsonl](examples/enable-https.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/enable-https.jsonl
  ```

### Alternative CLI Command

```bash
configure terminal
ip http secure-server
```

## Recipe: Enable https and force http to forward to https

- **Description**: Enable https and forward http to https on switch.
- **JSONL File**: [examples/forward-https.jsonl](examples/forward-https.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/forward-https.jsonl
  ```

### Alternative CLI Command

```bash
configure terminal
ip http secure-redirect
```

## Recipe: Disable https

- **Description**: Disable https on switch (leaving http on by default).
- **JSONL File**: [examples/disable-https.jsonl](examples/disable-https.jsonl)
- **Usage**:
  ```bash
  gs-rpc post -f ${GS_RECIPES}/disable-https.jsonl
  ```

### Alternative CLI Command

```bash
configure terminal
no ip http secure-redirect
no ip http secure-server
```
