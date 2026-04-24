#!/usr/bin/env bash
set -euo pipefail

# Extract device registry from Home Assistant via REST API
# Usage: ./bin/ha-export-devices.sh

usage() {
  cat <<'EOF'
Export device registry from Home Assistant to YAML.

Usage:
  ./bin/ha-export-devices.sh

Environment variables:
  HA_SSH_HOST    Home Assistant hostname/IP (required)
  HA_SSH_USER    SSH user (default: root)
  HA_SSH_KEY     SSH private key path (optional)
  HA_SSH_PORT    SSH port (default: 22)

This script retrieves the device registry from Home Assistant and formats it as YAML
for use in automations. Requires SSH access to Home Assistant.

The devices are exported from /config/.storage/core.device_registry and formatted
as a reference list.
The exporter prefers UI-assigned names (`name_by_user`) when available.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "${HA_SSH_HOST:-}" ]]; then
  echo "Error: HA_SSH_HOST is required."
  exit 1
fi

ssh_user="${HA_SSH_USER:-root}"
ssh_port="${HA_SSH_PORT:-22}"
ssh_key_arg=()
if [[ -n "${HA_SSH_KEY:-}" ]]; then
  ssh_key_arg=( -i "$HA_SSH_KEY" )
fi

ssh_host="${HA_SSH_HOST#http://}"
ssh_host="${ssh_host#https://}"
ssh_host="${ssh_host%%/*}"

echo "Fetching device registry from ${ssh_user}@${ssh_host}..."

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

device_registry_file="$tmp_dir/core.device_registry.json"
area_registry_file="$tmp_dir/core.area_registry.json"

# Fetch registries from Home Assistant
ssh -p "$ssh_port" "${ssh_key_arg[@]}" \
  "${ssh_user}@${ssh_host}" \
  "cat /config/.storage/core.device_registry" > "$device_registry_file" 2>/dev/null

# Area registry is optional; fall back to empty mapping if unavailable.
if ! ssh -p "$ssh_port" "${ssh_key_arg[@]}" \
  "${ssh_user}@${ssh_host}" \
  "cat /config/.storage/core.area_registry" > "$area_registry_file" 2>/dev/null; then
  echo '{"data":{"areas":[]}}' > "$area_registry_file"
fi

if [[ ! -s "$device_registry_file" ]]; then
  echo "Error: Could not retrieve device registry. Check SSH access."
  exit 1
fi

# Output as YAML reference (using Python to convert JSON to YAML-like format)
cat > helpers/devices.yaml <<'YAML_EOF'
# Device Registry Reference
# Auto-exported from Home Assistant core.device_registry
# DO NOT edit manually; regenerate with: ./bin/ha-export-devices.sh
# 
# Used for device_id references in automations.yaml
# Plug usage mapping for automations:
# - Fruehbeet Kruemel:
#   - left plug -> lighting
#   - right plug -> heating
# - Fruehbeet Sternies:
#   - left plug -> heating
#   - right plug -> heating
# - Terrarium:
#   - vorne plug -> lamps (2 lamps via multi-plug)
#   - hinten plug -> lamps (2 lamps via multi-plug)
#   - heizung plug -> heating
#   - led plug -> power monitoring only (not used for control)
# Automation rule:
# - Always use device_id values from this file.
# - Prefer device_id over entity_id in automations for stable references.
# `name` is the effective display name (prefers UI custom name if set).

YAML_EOF

# Convert JSON to YAML format
python3 - "$device_registry_file" "$area_registry_file" >> helpers/devices.yaml <<'PYTHON_EOF'
import json
import sys

try:
    with open(sys.argv[1], encoding='utf-8') as f:
        data = json.load(f)
    with open(sys.argv[2], encoding='utf-8') as f:
        area_data = json.load(f)

    devices = data.get('data', {}).get('devices', [])
    areas = area_data.get('data', {}).get('areas', [])
    area_names_by_id = {a.get('id'): a.get('name') for a in areas if a.get('id')}

    def y(val):
        if val is None:
            return "null"
        return json.dumps(str(val), ensure_ascii=False)

    print("devices:")
    for device in devices:
        area_id = device.get('area_id')
        area_name = area_names_by_id.get(area_id)
        manufacturer = device.get('manufacturer')
        model = device.get('model')
        technical_name = device.get('name')
        user_name = device.get('name_by_user')
        effective_name = user_name or technical_name or 'Unnamed'

        print(f"  # {manufacturer or 'unknown'} - {model or 'unknown'}")
        print(f"  # Area ID: {area_id}")
        if area_name:
            print(f"  # Area Name: {area_name}")
        print(f"  - id: {device.get('id')}")
        print(f"    name: {y(effective_name)}")
        print(f"    name_by_user: {y(user_name)}")
        print(f"    technical_name: {y(technical_name)}")
        print(f"    manufacturer: {y(manufacturer)}")
        print(f"    model: {y(model)}")
        print(f"    area_id: {y(area_id)}")
        print(f"    area_name: {y(area_name)}")
        print()

except Exception as e:
    print(f"# Error parsing device registry: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_EOF

echo "✓ Exported to helpers/devices.yaml"
