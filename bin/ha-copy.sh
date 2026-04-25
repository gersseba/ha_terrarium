#!/usr/bin/env bash
set -euo pipefail

declare -a SHORTCUTS_LIST=(
  "all:__ALL__"
  "input_number:helpers/input_number.yaml"
  "input_select:helpers/input_select.yaml"
  "input_datetime:helpers/input_datetime.yaml"
  "template:helpers/template.yaml"
  "sensor:helpers/sensor.yaml"
  "utility_meter:helpers/utility_meter.yaml"
  "devices:helpers/devices.yaml"
  "automations:automations.yaml"
  "config:configuration.yaml"
  "scripts:scripts.yaml"
  "scenes:scenes.yaml"
  "view_kroeten:lovelace/views/kroeten.yaml"
  "view_steuerung:lovelace/views/steuerung.yaml"
  "view_strom:lovelace/views/strom.yaml"
  "view_geraete:lovelace/views/geraete.yaml"
  "views:lovelace/views/*.yaml"
)

usage() {
  cat <<'EOF'
Copy a local file to Home Assistant via SSH (scp).

Usage:
  ./bin/ha-copy.sh <shortcut|local-file> [remote-path]

Shortcuts (commonly synced files):
  all                all files listed below
  input_number       helpers/input_number.yaml
  input_select       helpers/input_select.yaml
  input_datetime     helpers/input_datetime.yaml
  template           helpers/template.yaml
  sensor             helpers/sensor.yaml
  utility_meter      helpers/utility_meter.yaml
  devices            helpers/devices.yaml
  automations        automations.yaml
  config             configuration.yaml
  scripts            scripts.yaml
  scenes             scenes.yaml
  view_kroeten       lovelace/views/kroeten.yaml
  view_steuerung     lovelace/views/steuerung.yaml
  view_strom         lovelace/views/strom.yaml
  view_geraete       lovelace/views/geraete.yaml
  views              lovelace/views/*.yaml

Examples:
  ./bin/ha-copy.sh input_number
  ./bin/ha-copy.sh views
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

shortcut="$1"

# Bulk copy all lovelace view files.
if [[ "$shortcut" == "views" ]]; then
  remote_base="${2:-/config/lovelace/views}"
  remote_base="${remote_base%/}"

  shopt -s nullglob
  view_files=(lovelace/views/*.yaml)
  shopt -u nullglob

  if (( ${#view_files[@]} == 0 )); then
    echo "Error: No view files found in lovelace/views"
    exit 1
  fi

  for view_file in "${view_files[@]}"; do
    remote_target="${remote_base}/$(basename "$view_file")"
    echo "Copying $view_file -> ${ssh_user}@${ssh_host}:${remote_target}"
    "${scp_cmd[@]}" "$view_file" "${ssh_user}@${ssh_host}:${remote_target}"
  done

  echo "Done."
  exit 0
fi

# Bulk copy all files that have explicit shortcut mappings.
if [[ "$shortcut" == "all" ]]; then
  remote_root="${2:-/config}"
  remote_root="${remote_root%/}"

  for entry in "${SHORTCUTS_LIST[@]}"; do
    key="${entry%%:*}"
    path="${entry#*:}"

    # Skip meta and wildcard shortcuts.
    if [[ "$key" == "all" || "$key" == "views" ]]; then
      continue
    fi

    if [[ ! -f "$path" ]]; then
      echo "Error: Local file not found: $path"
      exit 1
    fi

    remote_target="${remote_root}/${path}"
    echo "Copying $path -> ${ssh_user}@${ssh_host}:${remote_target}"
    "${scp_cmd[@]}" "$path" "${ssh_user}@${ssh_host}:${remote_target}"
  done

  echo "Done."
  exit 0
fi

# Resolve shortcut names to file paths
local_file="$shortcut"
case "$local_file" in
  input_number)   local_file="helpers/input_number.yaml" ;;
  input_select)   local_file="helpers/input_select.yaml" ;;
  input_datetime) local_file="helpers/input_datetime.yaml" ;;
  template)       local_file="helpers/template.yaml" ;;
  sensor)         local_file="helpers/sensor.yaml" ;;
  utility_meter)  local_file="helpers/utility_meter.yaml" ;;
  devices)        local_file="helpers/devices.yaml" ;;
  automations)    local_file="automations.yaml" ;;
  config)         local_file="configuration.yaml" ;;
  scripts)        local_file="scripts.yaml" ;;
  scenes)         local_file="scenes.yaml" ;;
  view_kroeten)   local_file="lovelace/views/kroeten.yaml" ;;
  view_steuerung) local_file="lovelace/views/steuerung.yaml" ;;
  view_strom)     local_file="lovelace/views/strom.yaml" ;;
  view_geraete)   local_file="lovelace/views/geraete.yaml" ;;
esac

# Generic view shortcut: view_<name> -> lovelace/views/<name>.yaml
if [[ "$local_file" == "$shortcut" && "$shortcut" == view_* ]]; then
  candidate="lovelace/views/${shortcut#view_}.yaml"
  if [[ -f "$candidate" ]]; then
    local_file="$candidate"
  fi
fi
remote_path="${2:-/config/$local_file}" 

if [[ ! -f "$local_file" ]]; then
  echo "Error: Local file not found: $local_file"
  exit 1
fi

echo "Copying $local_file -> ${ssh_user}@${ssh_host}:${remote_path}"
"${scp_cmd[@]}" "$local_file" "${ssh_user}@${ssh_host}:${remote_path}"

echo "Done."
