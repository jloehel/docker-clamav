# Docker ClamAV

[![Docker Weekly Build](https://github.com/jloehel/docker-clamav/actions/workflows/docker-weekly-build.yml/badge.svg)](https://github.com/jloehel/docker-clamav/actions/workflows/docker-weekly-build.yml)
[![Docker Build](https://github.com/jloehel/docker-clamav/actions/workflows/docker-build.yml/badge.svg)](https://github.com/jloehel/docker-clamav/actions/workflows/docker-build.yml)

Docker image for ClamAV with unofficial signatures from [eXtremeSHOK.com](https://github.com/extremeshok/clamav-unofficial-sigs).

## Features

- **Multi-OS Support**: Alpine Linux and Ubuntu
- **Multi-Architecture**: amd64 and arm64
- **Unofficial Signatures**: Integrated clamav-unofficial-sigs for extended malware detection
- **Rootless Support**: NSS wrapper for OpenShift/Kubernetes compatibility
- **Docker Secrets**: Support for sensitive configuration via `_FILE` environment variables
- **Weekly Rebuilds**: Automated weekly builds via GitHub Actions
- **Whitelist Management**: Dynamic whitelist configuration via environment variables

## Supported Tags

| Tag | OS | Description |
|-----|-----|-------------|
| `latest` | Alpine 3.23 | Latest stable Alpine build |
| `alpine-latest` | Alpine 3.23 | Latest Alpine build |
| `alpine-3.23-1.4.3-7.2.5-1` | Alpine 3.23 | Versioned Alpine build |
| `1.4.3-alpine` | Alpine | ClamAV version specific |
| `ubuntu-latest` | Ubuntu 24.04 | Latest Ubuntu build |
| `ubuntu-24.04-1.4.3-7.2.5-1` | Ubuntu 24.04 | Versioned Ubuntu build |
| `1.4.3-ubuntu` | Ubuntu | ClamAV version specific |

### Git Tag Format

Git tags use `/` as separator for clarity with version numbers containing `-`:

```text
<os_flavor>/<os_version>/<clamav_version>/<unofficial_sigs_version>/<build>
```

Examples:

- `alpine/3.23/1.4.3/7.2.5/1`
- `ubuntu/24.04/1.4.3/7.2.5/1`

Docker tags convert `/` to `-`:

- `alpine-3.23-1.4.3-7.2.5-1`
- `ubuntu-24.04-1.4.3-7.2.5-1`

## Quick Start

```bash
docker run -d \
  --name clamav \
  -p 3310:3310 \
  -v clamav_data:/clamav/data \
  ghcr.io/jloehel/clamav:latest
```

## Docker Compose

```yaml
version: '3.8'

services:
  clamav:
    image: ghcr.io/jloehel/clamav:latest
    container_name: clamav
    restart: unless-stopped
    volumes:
      - clamav_data:/clamav/data
    ports:
      - "127.0.0.1:3310:3310"
    environment:
      # Optional: Disable welcome message
      - DISABLE_WELCOME_MESSAGE=false
      # Optional: SecuriteInfo credentials
      # - SECURITEINFO_AUTHORISATION_SIGNATURE=your_signature
      # - SECURITEINFO_PREMIUM=no
    healthcheck:
      test: ["CMD", "/healthcheck.sh"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s

volumes:
  clamav_data:
```

## Docker Swarm Stack

```yaml
version: '3.8'

services:
  clamav:
    image: ghcr.io/jloehel/clamav:latest
    volumes:
      - clamav_data:/clamav/data
    networks:
      - internal
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 512M
    healthcheck:
      test: ["CMD", "/healthcheck.sh"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s

volumes:
  clamav_data:

networks:
  internal:
    driver: overlay
```

## Environment Variables

### General

| Variable | Default | Description |
|----------|---------|-------------|
| `DISABLE_WELCOME_MESSAGE` | `false` | Disable welcome banner |
| `BASH_DEBUG` | `false` | Enable debug output |

### Unofficial Signatures (Optional)

| Variable | Description |
|----------|-------------|
| `MALWAREPATROL_RECEIPT_CODE` | MalwarePatrol receipt code |
| `MALWAREPATROL_PRODUCT_CODE` | MalwarePatrol product code |
| `MALWAREPATROL_LIST` | MalwarePatrol list |
| `MALWAREEXPERT_SERIAL_KEY` | MalwareExpert serial key |
| `SECURITEINFO_AUTHORISATION_SIGNATURE` | SecuriteInfo auth signature |
| `SECURITEINFO_PREMIUM` | SecuriteInfo premium status |

### Docker Secrets

All variables above support the `_FILE` suffix for Docker secrets:

```yaml
services:
  clamav:
    secrets:
      - securiteinfo_auth
    environment:
      - SECURITEINFO_AUTHORISATION_SIGNATURE_FILE=/run/secrets/securiteinfo_auth

secrets:
  securiteinfo_auth:
    external: true
```

### Whitelist

Add whitelist entries via environment variables prefixed with `WHITELIST`:

```yaml
environment:
  - WHITELIST_1=Sanesecurity.Foxhole.Zip_js.UNOFFICIAL
  - WHITELIST_2=Example.Signature.Name
```

## Integration with ownCloud OCIS

```yaml
services:
  ocis:
    environment:
      ANTIVIRUS_SCANNER_TYPE: "clamav"
      ANTIVIRUS_CLAMAV_SOCKET: "tcp://clamav:3310"
```

## Volumes

| Path | Description |
|------|-------------|
| `/clamav/data` | Database directory (official + unofficial signatures) |

## Ports

| Port | Description |
|------|-------------|
| `3310/tcp` | ClamAV daemon TCP socket |

## Building Locally

### Alpine (default)

```bash
./docker_build.sh
```

### Ubuntu

```bash
OS_FLAVOR=ubuntu OS_VERSION=24.04 ./docker_build.sh
```

### With specific versions

```bash
export OS_FLAVOR=alpine
export OS_VERSION=3.21
export APP_VERSION=1.4.2
export UNOFFICIAL_SIGS_VERSION=7.2.5
./docker_build.sh
```

## Directory Structure

```text
overlay/
├── alpine/
│   └── etc/clamav/
│       ├── clamd.conf
│       └── freshclam.conf
├── base/
│   ├── build/
│   │   ├── clean.sh
│   │   ├── dependencies/
│   │   ├── install-app.sh
│   │   ├── install-dependencies.sh
│   │   └── update.sh
│   ├── clamav/data/
│   ├── entrypoint.sh
│   ├── healthcheck.sh
│   ├── opt/base/functions
│   └── run.sh
└── ubuntu/
    └── etc/clamav/
        ├── clamd.conf
        └── freshclam.conf
```

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

- [ClamAV](https://www.clamav.net/)
- [clamav-unofficial-sigs](https://github.com/extremeshok/clamav-unofficial-sigs) by eXtremeSHOK.com
