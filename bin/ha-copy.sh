#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Copy a local file to Home Assistant via SSH (scp).

Usage:
  ./bin/ha-copy.sh <local-file> [remote-path]

Examples:
  HA_SSH_HOST=192.168.1.50 ./bin/ha-copy.sh automations.yaml
  HA_SSH_HOST=homeassistant.local HA_SSH_USER=root ./bin/ha-copy.sh helpers/input_select.yaml /config/helpers/input_select.yaml

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
  echo "Example: HA_SSH_HOST=192.168.1.50 ./bin/ha-copy.sh automations.yaml"
  exit 1
fi

local_file="$1"
remote_path="${2:-/config/$(basename "$local_file")}" 

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
