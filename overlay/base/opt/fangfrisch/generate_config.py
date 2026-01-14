#!/usr/bin/env python3
"""
Generate fangfrisch configuration from environment variables and Jinja2 template.

Environment Variables:
----------------------
General Settings:
    FANGFRISCH_LOG_LEVEL        - Log level (default: INFO)
    FANGFRISCH_MAX_SIZE         - Default max file size (default: 10MB)
    FANGFRISCH_ON_UPDATE_EXEC   - Command to run after updates (default: clamdscan --reload)
    FANGFRISCH_ON_UPDATE_TIMEOUT - Timeout for on_update_exec (default: 60)
    FANGFRISCH_CONNECTION_TIMEOUT - Network connection timeout (default: not set)
    FANGFRISCH_DB_PATH          - SQLite database path (default: /var/lib/fangfrisch/db.sqlite)
    FANGFRISCH_LOCAL_DIRECTORY  - Directory for signatures (default: /clamav/data/unofficial)

Free Providers:
    SANESECURITY_ENABLED        - Enable Sanesecurity (default: true)
    SANESECURITY_INTERVAL       - Update interval (default: 1h)
    SANESECURITY_PREFIX         - Custom mirror URL (default: not set, uses fangfrisch default)

    URLHAUS_ENABLED             - Enable URLhaus (default: true)
    URLHAUS_INTERVAL            - Update interval (default: 10m)
    URLHAUS_MAX_SIZE            - Max file size (default: 5MB)

    INTERSERVER_ENABLED         - Enable InterServer (default: true)
    INTERSERVER_INTERVAL        - Update interval (default: 1h)

Premium Providers (require credentials):
    MALWAREPATROL_ENABLED       - Enable MalwarePatrol (default: false, but requires receipt)
    MALWAREPATROL_RECEIPT       - MalwarePatrol receipt code (required to enable)
    MALWAREPATROL_PRODUCT       - MalwarePatrol product code (default: 8)
    MALWAREPATROL_INTERVAL      - Update interval (default: 1d)

    SECURITEINFO_ENABLED        - Enable SecuriteInfo (default: false, but requires customer_id)
    SECURITEINFO_CUSTOMER_ID    - SecuriteInfo customer ID (required to enable)
    SECURITEINFO_INTERVAL       - Update interval (default: 1h)
    SECURITEINFO_MAX_SIZE       - Max file size (default: 20MB)
"""

import os
import sys
from pathlib import Path

try:
    from jinja2 import Environment, FileSystemLoader
except ImportError:
    print("Error: jinja2 is required. Install with: pip install jinja2", file=sys.stderr)
    sys.exit(1)


def get_bool_env(name: str, default: bool = False) -> bool:
    """Get boolean from environment variable."""
    value = os.environ.get(name, "").lower()
    if value in ("true", "yes", "1", "on"):
        return True
    if value in ("false", "no", "0", "off"):
        return False
    return default


def get_env(name: str, default: str = "") -> str:
    """Get string from environment variable, supporting _FILE suffix for secrets."""
    # Check for _FILE variant first (Docker secrets)
    file_var = f"{name}_FILE"
    if file_var in os.environ:
        file_path = os.environ[file_var]
        try:
            with open(file_path, "r") as f:
                return f.read().strip()
        except IOError as e:
            print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)

    return os.environ.get(name, default)


def main():
    # Determine paths
    template_dir = os.environ.get("FANGFRISCH_TEMPLATE_DIR", "/opt/fangfrisch")
    template_file = os.environ.get("FANGFRISCH_TEMPLATE_FILE", "fangfrisch.conf.j2")
    output_file = os.environ.get("FANGFRISCH_CONFIG_OUTPUT", "/etc/fangfrisch/fangfrisch.conf")

    # Check template exists
    template_path = Path(template_dir) / template_file
    if not template_path.exists():
        print(f"Error: Template not found: {template_path}", file=sys.stderr)
        sys.exit(1)

    # Setup Jinja2
    env = Environment(
        loader=FileSystemLoader(template_dir),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    template = env.get_template(template_file)

    # Collect configuration from environment
    config = {
        # General settings
        "db_path": get_env("FANGFRISCH_DB_PATH", "/var/lib/fangfrisch/db.sqlite"),
        "local_directory": get_env("FANGFRISCH_LOCAL_DIRECTORY", "/clamav/data/unofficial"),
        "log_level": get_env("FANGFRISCH_LOG_LEVEL", "INFO"),
        "max_size": get_env("FANGFRISCH_MAX_SIZE", "10MB"),
        "on_update_exec": get_env("FANGFRISCH_ON_UPDATE_EXEC", "clamdscan --reload"),
        "on_update_timeout": get_env("FANGFRISCH_ON_UPDATE_TIMEOUT", "60"),
        "connection_timeout": get_env("FANGFRISCH_CONNECTION_TIMEOUT", ""),

        # Sanesecurity (free)
        "sanesecurity_enabled": get_bool_env("SANESECURITY_ENABLED", True),
        "sanesecurity_interval": get_env("SANESECURITY_INTERVAL", "1h"),
        "sanesecurity_prefix": get_env("SANESECURITY_PREFIX", ""),

        # URLhaus (free)
        "urlhaus_enabled": get_bool_env("URLHAUS_ENABLED", True),
        "urlhaus_interval": get_env("URLHAUS_INTERVAL", "10m"),
        "urlhaus_max_size": get_env("URLHAUS_MAX_SIZE", "5MB"),

        # InterServer (free)
        "interserver_enabled": get_bool_env("INTERSERVER_ENABLED", True),
        "interserver_interval": get_env("INTERSERVER_INTERVAL", "1h"),

        # MalwarePatrol (premium)
        "malwarepatrol_enabled": get_bool_env("MALWAREPATROL_ENABLED", False),
        "malwarepatrol_receipt": get_env("MALWAREPATROL_RECEIPT", ""),
        "malwarepatrol_product": get_env("MALWAREPATROL_PRODUCT", "8"),
        "malwarepatrol_interval": get_env("MALWAREPATROL_INTERVAL", "1d"),

        # SecuriteInfo (premium)
        "securiteinfo_enabled": get_bool_env("SECURITEINFO_ENABLED", False),
        "securiteinfo_customer_id": get_env("SECURITEINFO_CUSTOMER_ID", ""),
        "securiteinfo_interval": get_env("SECURITEINFO_INTERVAL", "1h"),
        "securiteinfo_max_size": get_env("SECURITEINFO_MAX_SIZE", "20MB"),
    }

    # Render template
    rendered = template.render(**config)

    # Write output
    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(rendered)

    print(f"Configuration written to: {output_file}")

    # Print summary of enabled providers
    print("\nEnabled providers:")
    if config["sanesecurity_enabled"]:
        print("  - Sanesecurity (free)")
    if config["urlhaus_enabled"]:
        print("  - URLhaus (free)")
    if config["interserver_enabled"]:
        print("  - InterServer (free)")
    if config["malwarepatrol_enabled"] and config["malwarepatrol_receipt"]:
        print("  - MalwarePatrol (premium)")
    elif config["malwarepatrol_enabled"]:
        print("  - MalwarePatrol (disabled - no receipt configured)")
    if config["securiteinfo_enabled"] and config["securiteinfo_customer_id"]:
        print("  - SecuriteInfo (premium)")
    elif config["securiteinfo_enabled"]:
        print("  - SecuriteInfo (disabled - no customer_id configured)")


if __name__ == "__main__":
    main()
