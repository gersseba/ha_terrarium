#!/usr/bin/env bash
set -euo pipefail

declare -a SHORTCUTS_LIST=(
  "input_number:helpers/input_number.yaml"
  "input_select:helpers/input_select.yaml"
  "input_datetime:helpers/input_datetime.yaml"
  "automations:automations.yaml"
  "config:configuration.yaml"
  "scripts:scripts.yaml"
  "scenes:scenes.yaml"
  "view_kroeten:lovelace/views/kroeten.yaml"
  "view_steuerung:lovelace/views/steuerung.yaml"
  "view_meta:lovelace/views/meta.yaml"
)

usage() {
  cat <<'EOF'
Copy a local file to Home Assistant via SSH (scp).

Usage:
  ./bin/ha-copy.sh <shortcut|local-file> [remote-path]

Shortcuts (commonly synced files):
  input_number       helpers/input_number.yaml
  input_select       helpers/input_select.yaml
  input_datetime     helpers/input_datetime.yaml
  automations        automations.yaml
  config             configuration.yaml
  scripts            scripts.yaml
  scenes             scenes.yaml
  view_kroeten       lovelace/views/kroeten.yaml
  view_steuerung     lovelace/views/steuerung.yaml
  view_meta          lovelace/views/meta.yaml

Examples:
  ./bin/ha-copy.sh input_number
  ./bin/ha-copy.sh automations
  ./bin/ha-copy.sh helpers/input_select.yaml
  ./bin/ha-copy.sh automations.yaml /config/automations.yaml

Environment variables:
  HA_SSH_HOST   Required. Hostname or IP of Home Assistant (URL is also accepted).
  HA_SSH_USER   Optional. SSH user. Default: root
  HA_SSH_PORT   Optional. SSH port. Default: 22
  HA_SSH_KEY    Optional. Path to private key for SSH auth.

Notes:
  - If [remote-path] is omitted, the file is copied to /config/<basename(local-file)>.
  - Run this script from the repository root.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

if [[ -z "${HA_SSH_HOST:-}" ]]; then
  echo "Error: HA_SSH_HOST is required."
  echo "Example: ./bin/ha-copy.sh input_number"
  exit 1
fi

# Resolve shortcut names to file paths
local_file="$1"
case "$local_file" in
  input_number)   local_file="helpers/input_number.yaml" ;;
  input_select)   local_file="helpers/input_select.yaml" ;;
  input_datetime) local_file="helpers/input_datetime.yaml" ;;
  automations)    local_file="automations.yaml" ;;
  config)         local_file="configuration.yaml" ;;
  scripts)        local_file="scripts.yaml" ;;
  scenes)         local_file="scenes.yaml" ;;
  view_kroeten)   local_file="lovelace/views/kroeten.yaml" ;;
  view_steuerung) local_file="lovelace/views/steuerung.yaml" ;;
  view_meta)      local_file="lovelace/views/meta.yaml" ;;
esac
remote_path="${2:-/config/$local_file}" 

if [[ ! -f "$local_file" ]]; then
  echo "Error: Local file not found: $local_file"
  exit 1
fi

ssh_user="${HA_SSH_USER:-root}"
ssh_port="${HA_SSH_PORT:-22}"
# Accept values like http://homeassistant.local/ and convert to host form for scp.
ssh_host="${HA_SSH_HOST#http://}"
ssh_host="${ssh_host#https://}"
ssh_host="${ssh_host%%/*}"

if [[ -z "$ssh_host" ]]; then
  echo "Error: HA_SSH_HOST is invalid after normalization: ${HA_SSH_HOST}"
  exit 1
fi

scp_cmd=(scp -P "$ssh_port" -o StrictHostKeyChecking=accept-new)
if [[ -n "${HA_SSH_KEY:-}" ]]; then
  scp_cmd+=( -i "$HA_SSH_KEY" )
fi

echo "Copying $local_file -> ${ssh_user}@${ssh_host}:${remote_path}"
"${scp_cmd[@]}" "$local_file" "${ssh_user}@${ssh_host}:${remote_path}"

echo "Done."
