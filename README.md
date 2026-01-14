# Docker ClamAV

[![Release Build](https://github.com/jloehel/docker-clamav/actions/workflows/release-build.yml/badge.svg)](https://github.com/jloehel/docker-clamav/actions/workflows/release-build.yml)
[![Weekly Build](https://github.com/jloehel/docker-clamav/actions/workflows/weekly-build.yml/badge.svg)](https://github.com/jloehel/docker-clamav/actions/workflows/weekly-build.yml)

Docker image for ClamAV with unofficial signatures via [fangfrisch](https://github.com/rseichter/fangfrisch).

## Features

- **Multi-OS Support**: Alpine Linux and Ubuntu
- **Multi-Architecture**: amd64 and arm64
- **Unofficial Signatures**: Integrated fangfrisch for extended malware detection
- **Rootless Support**: NSS wrapper for OpenShift/Kubernetes compatibility
- **Docker Secrets**: Support for sensitive configuration via `_FILE` environment variables
- **Weekly Rebuilds**: Automated weekly builds via GitHub Actions
- **Dynamic Configuration**: Fangfrisch config generated at runtime via Jinja2 templates

## Supported Tags

| Tag | OS | Description |
|-----|-----|-------------|
| `latest` | Alpine 3.23 | Latest stable Alpine build |
| `alpine-latest` | Alpine 3.23 | Latest Alpine build |
| `alpine-3.23-1.4.3-1.9.2-1` | Alpine 3.23 | Versioned Alpine build |
| `1.4.3-alpine` | Alpine | ClamAV version specific |
| `ubuntu-latest` | Ubuntu 24.04 | Latest Ubuntu build |
| `ubuntu-24.04-1.4.3-1.9.2-1` | Ubuntu 24.04 | Versioned Ubuntu build |
| `1.4.3-ubuntu` | Ubuntu | ClamAV version specific |

### Git Tag Format

Git tags use `/` as separator for clarity with version numbers containing `-`:

```text
<os_flavor>/<os_version>/<clamav_version>/<fangfrisch_version>/<build>
```

Examples:

- `alpine/3.23/1.4.3/1.9.2/1`
- `ubuntu/24.04/1.4.3/1.9.2/1`

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
      # Optional: Adjust log level
      - FANGFRISCH_LOG_LEVEL=INFO
      # Optional: SecuriteInfo credentials
      # - SECURITEINFO_CUSTOMER_ID=your_customer_id
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
services:
  clamav:
    image: ghcr.io/jloehel/clamav:latest
    volumes:
      - clamav_data:/clamav/data
    networks:
      - internal
    secrets:
      - securiteinfo_customer_id
    environment:
      - SECURITEINFO_CUSTOMER_ID_FILE=/run/secrets/securiteinfo_customer_id
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

secrets:
  securiteinfo_customer_id:
    external: true
```

## Environment Variables

### General Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `DISABLE_WELCOME_MESSAGE` | `false` | Disable welcome banner |
| `BASH_DEBUG` | `false` | Enable debug output |

### Fangfrisch General Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `FANGFRISCH_LOG_LEVEL` | `INFO` | Log level: DEBUG, INFO, WARNING, ERROR, FATAL |
| `FANGFRISCH_MAX_SIZE` | `10MB` | Default maximum file size |
| `FANGFRISCH_ON_UPDATE_EXEC` | `clamdscan --reload` | Command to run after signature updates |
| `FANGFRISCH_ON_UPDATE_TIMEOUT` | `60` | Timeout for on_update_exec in seconds |
| `FANGFRISCH_CONNECTION_TIMEOUT` | *(not set)* | Network connection timeout in seconds |
| `FANGFRISCH_DB_PATH` | `/var/lib/fangfrisch/db.sqlite` | SQLite database path |
| `FANGFRISCH_LOCAL_DIRECTORY` | `/clamav/data/unofficial` | Directory for unofficial signatures |

### Free Signature Providers

These providers are enabled by default and do not require credentials.

#### Sanesecurity

Community-maintained signatures with broad coverage.

| Variable | Default | Description |
|----------|---------|-------------|
| `SANESECURITY_ENABLED` | `true` | Enable/disable provider |
| `SANESECURITY_INTERVAL` | `1h` | Update interval |
| `SANESECURITY_PREFIX` | *(fangfrisch default)* | Custom mirror URL |

#### URLhaus

Abuse.ch malware URL database - frequently updated.

| Variable | Default | Description |
|----------|---------|-------------|
| `URLHAUS_ENABLED` | `true` | Enable/disable provider |
| `URLHAUS_INTERVAL` | `10m` | Update interval |
| `URLHAUS_MAX_SIZE` | `5MB` | Maximum file size |

#### InterServer

InterServer security signatures.

| Variable | Default | Description |
|----------|---------|-------------|
| `INTERSERVER_ENABLED` | `true` | Enable/disable provider |
| `INTERSERVER_INTERVAL` | `1h` | Update interval |

### Premium Signature Providers

These providers require credentials. They are enabled by default but will only be activated if credentials are provided.

#### MalwarePatrol

Commercial malware signature database.

| Variable | Default | Description |
|----------|---------|-------------|
| `MALWAREPATROL_ENABLED` | `true` | Enable/disable provider |
| `MALWAREPATROL_RECEIPT` | *(required)* | MalwarePatrol receipt code |
| `MALWAREPATROL_PRODUCT` | `8` | MalwarePatrol product code |
| `MALWAREPATROL_INTERVAL` | `1d` | Update interval |

#### SecuriteInfo

Commercial security signatures with extended coverage.

| Variable | Default | Description |
|----------|---------|-------------|
| `SECURITEINFO_ENABLED` | `true` | Enable/disable provider |
| `SECURITEINFO_CUSTOMER_ID` | *(required)* | SecuriteInfo customer ID |
| `SECURITEINFO_INTERVAL` | `1h` | Update interval |
| `SECURITEINFO_MAX_SIZE` | `20MB` | Maximum file size |

### Docker Secrets

All credential variables support the `_FILE` suffix for Docker secrets:

```yaml
services:
  clamav:
    secrets:
      - securiteinfo_customer_id
      - malwarepatrol_receipt
    environment:
      - SECURITEINFO_CUSTOMER_ID_FILE=/run/secrets/securiteinfo_customer_id
      - MALWAREPATROL_RECEIPT_FILE=/run/secrets/malwarepatrol_receipt

secrets:
  securiteinfo_customer_id:
    external: true
  malwarepatrol_receipt:
    external: true
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

The volume contains:

- `/clamav/data/official/` - Official ClamAV signatures (freshclam)
- `/clamav/data/unofficial/` - Unofficial signatures (fangfrisch)

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
export OS_VERSION=3.23
export APP_VERSION=1.4.3
export FANGFRISCH_VERSION=1.9.2
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
│   ├── opt/
│   │   ├── base/functions
│   │   └── fangfrisch/
│   │       ├── fangfrisch.conf.j2
│   │       └── generate_config.py
│   └── run.sh
└── ubuntu/
    └── etc/clamav/
        ├── clamd.conf
        └── freshclam.conf
```

## Configuration Architecture

The fangfrisch configuration is generated at container startup using a Jinja2 template. This allows:

1. **Dynamic configuration** based on environment variables
2. **Docker Secrets support** for sensitive credentials
3. **Extensibility** for future ClamAV configuration templating

The template is located at `/opt/fangfrisch/fangfrisch.conf.j2` and can be replaced via volume mount for advanced customization.

## Migration from clamav-unofficial-sigs

This image previously used [clamav-unofficial-sigs](https://github.com/extremeshok/clamav-unofficial-sigs).
It has been migrated to [fangfrisch](https://github.com/rseichter/fangfrisch) because:

- fangfrisch is actively maintained (last update 2025)
- clamav-unofficial-sigs was last updated in 2021
- fangfrisch uses efficient digest-based downloads
- fangfrisch has cleaner state management via SQLite

### Breaking Changes

If you're upgrading from a version using clamav-unofficial-sigs:

| Old Variable | New Variable |
|--------------|--------------|
| `SECURITEINFO_AUTHORISATION_SIGNATURE` | `SECURITEINFO_CUSTOMER_ID` |
| `MALWAREPATROL_RECEIPT_CODE` | `MALWAREPATROL_RECEIPT` |
| `MALWAREPATROL_PRODUCT_CODE` | `MALWAREPATROL_PRODUCT` |

Additional changes:

- Whitelist functionality is not yet available
- The unofficial signatures directory structure has changed
- Configuration is now generated via Jinja2 template

## License

MIT License - See [LICENSE](LICENSE) for details.

## Credits

- [ClamAV](https://www.clamav.net/)
- [fangfrisch](https://github.com/rseichter/fangfrisch) by Ralph Seichter
