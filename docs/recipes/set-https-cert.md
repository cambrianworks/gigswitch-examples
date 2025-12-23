# Upload Certificate for https

You can use this recipe to customize the https security certificate by uploading your own certificate with optional passphrase.

When you first enable https, the system will automatically use a self-signed certificate, which may be adequate.

Constraints:
1. The certificate must be of `.pem` format (not `.pfx`, for example)
2. The certificate must be available on a `tftp` or web server at install time
3. Web server's `https` must be disabled during install (see [support-https.md](support-https.md) or `icli` config: `no ip http secure-server` or `no ip secure-redirect`)

**NOTE:** In the recipes, you'll need to update `{SERVER_IP}` with the actual ip address of the server (or hostname if you've configured DNS on the switch). (Or change `tftp://` to `http://` and use a web server.)

## Prerequisites

See [save-config.md](save-config.md) if you need to set up a `tftp` server though you may also use a regular web server in this case.

If you go the web server route and simply want a quick web server to host files in your local directory, you can get it directly from Python with:

Option A:

```
sudo python3 -m http.server 80
```

**NOTE:** `sudo` is generally required to listen at a privileged port such as 80. If you don't want to run as `sudo` or need to listen at a different free port, you can try Option B.

Option B - listen at non-privileged port (>=1024):

```
sudo python3 -m http.server 8080
```

## Obtain .pem certificate

You'll need a certificate from a third-party provider or one you've generated on your own. The below section can be used to generate a test certificate in a pinch.

### Generate certificate with openssl

Below is a convenience script that can generate a test certificate on an Ubuntu machine or any machine with `openssl` that can run a `bash` script. Adjust as needed to set the name and passphrase.

`make-cert.sh`

```
#!/bin/bash

IP_OR_HOSTNAME="switchip"
# This must match what browser will have in URL line
ALT_NAME="IP:127.0.0.1"   # Could be "DNS:localhost", "IP:192.168.1.10", etc.
PASSPHRASE=""  # leave blank for no passphrase

# 1) Create key + CSR + self-signed cert
if [[ -n "$PASSPHRASE" ]]; then
  # Generate encrypted private key
  openssl genrsa -aes256 -passout pass:"$PASSPHRASE" -out server.key 2048
else
  # Generate unencrypted private key
  openssl genrsa -out server.key 2048
fi

# Add SAN with -addext (OpenSSL 1.1.1+)
openssl req -new -key server.key \
  -passin pass:"$PASSPHRASE" \
  -subj "/CN=${IP_OR_HOSTNAME}" \
  -addext "subjectAltName=${ALT_NAME}" \
  -out server.csr

openssl x509 -req -in server.csr -signkey server.key \
  -passin pass:"$PASSPHRASE" \
  -days 365 \
  -extfile <(printf "subjectAltName=${ALT_NAME}") \
  -out server.crt

# 2) Combine into PEM
cat server.key server.crt > server.pem

echo "Generated server.pem"
if [[ -n "$PASSPHRASE" ]]; then
  echo "Private key is encrypted with a passphrase."
else
  echo "Private key is unencrypted (no passphrase)."
fi
```

Usage:

```
./make-cert.sh
```

Should create `server.pem` based on how you set variables `IP_OR_HOSTNAME`, `ALT_NAME` and `PASSPHRASE`.

## Recipe: Install certificate from a tftp or web server

- **Description**: Copy running config to tftp server.
- **JSONL File** (must update `{SERVER_IP}`): [examples/https-cert-install.jsonl](examples/https-cert-install.jsonl)
  ```bash
  gs-rpc post -f ${GS_RECIPES}/https-cert-install.jsonl
  ```
- **Options**: Set `Url` and `Pass_phrase` appropriately.

### Alternative CLI Command

If https is currently enabled, you'll need to disable, upload, then re-enable.

Disable: `no ip http secure-server` or `no ip secure-redirect`
Re-enable: `no ip http secure-server` or `no ip secure-redirect`

```bash
configure terminal
<disable https if currently enabled>
ip http secure-certificate upload tftp://{SERVER_IP}/server.pfx [passphrase]
<enable or re-enable https>
```
