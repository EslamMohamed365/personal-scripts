#!/usr/bin/env bash
#
# install-searxng.sh
# Installs and runs SearXNG as a rootless Podman Quadlet systemd service.
#
set -Eeuo pipefail

readonly QUADLET_DIR="$HOME/.config/containers/systemd"
readonly SEARXNG_CONFIG_DIR="$HOME/.config/searxng"
readonly SEARXNG_CONFIG_FILE="$SEARXNG_CONFIG_DIR/settings.yml"
readonly CONTAINER_FILE="$QUADLET_DIR/searxng.container"
readonly SERVICE_NAME="searxng.service"
DEFAULT_SEARXNG_PORT="5039"
SEARXNG_PORT="$DEFAULT_SEARXNG_PORT"

log() {
  echo "[$(date +'\%Y-\%m-\%d \%H:\%M:\%S')] INFO:$*"
}

fail() {
  echo "[$(date +'\%Y-\%m-\%d \%H:\%M:\%S')] ERROR:$*" >&2
  exit 1
}

on_error() {
  rm -f "$CONTAINER_FILE" 2>/dev/null || true
  fail "Error on line $1"
}

trap 'on_error $LINENO' ERR

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help      Show help
    -p, --port NUM  SearXNG port (default: ${DEFAULT_SEARXNG_PORT})
EOF
  exit "${1:-0}"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help) usage 0 ;;
    -p | --port)
      [[ "${2:-}" =~ ^[0-9]+$ ]] || fail "Invalid port: ${2:-<missing>}"
      SEARXNG_PORT="$2"
      shift 2
      ;;
    *) fail "Unknown option: $1" ;;
    esac
  done
}

check_deps() {
  local -a missing=()
  for cmd in podman systemctl openssl; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    fail "Missing required commands: ${missing[*]}"
  fi
}

setup_searxng_config() {
  if [[ ! -f "$SEARXNG_CONFIG_FILE" ]]; then
    log "Creating default SearXNG config at $SEARXNG_CONFIG_FILE ..."
    mkdir -p "$SEARXNG_CONFIG_DIR"
    local secret_key
    secret_key=$(openssl rand -hex 32)
    cat <<EOF >"$SEARXNG_CONFIG_FILE"
use_default_settings: true
general:
  debug: false
  instance_name: "SearXNG"
server:
  secret_key: "${secret_key}"
EOF
  else
    log "Existing configuration found at $SEARXNG_CONFIG_FILE, skipping creation."
  fi
}

enable_autoupdate_timer() {
  log "Enabling daily automatic updates via podman-auto-update.timer..."
  if systemctl --user enable --now podman-auto-update.timer &>/dev/null; then
    log "OK: podman-auto-update.timer enabled successfully!"
  else
    log "Warning: Could not enable podman-auto-update.timer automatically."
  fi
}

wait_for_service() {
  local max_attempts=10
  local attempt=1

  while [[ $attempt -le $max_attempts ]]; do
    if systemctl --user is-active --quiet "$SERVICE_NAME"; then
      return 0
    fi
    sleep 1
    ((attempt++))
  done
  return 1
}

main() {
  parse_args "$@"
  check_deps

  if ! systemctl --user status &>/dev/null; then
    fail "systemd user session unavailable. Try: loginctl enable-linger $USER"
  fi

  setup_searxng_config
  mkdir -p "$QUADLET_DIR"

  log "Writing container configuration to $CONTAINER_FILE ..."
  cat <<EOF >"$CONTAINER_FILE"
[Unit]
Description=SearXNG Metasearch Engine Container
After=network-online.target

[Container]
Image=docker.io/searxng/searxng:latest
ContainerName=searxng
Environment=SEARXNG_PORT=${SEARXNG_PORT}
PublishPort=${SEARXNG_PORT}:${SEARXNG_PORT}
AutoUpdate=registry
Volume=%h/.config/searxng/settings.yml:/etc/searxng/settings.yml:Z

[Install]
WantedBy=default.target
EOF

  log "Cleaning up any existing service/container ..."
  systemctl --user stop "$SERVICE_NAME" &>/dev/null || true

  log "Reloading user systemd daemon..."
  systemctl --user daemon-reload

  log "Starting $SERVICE_NAME ..."
  if ! systemctl --user start "$SERVICE_NAME"; then
    fail "Failed to start $SERVICE_NAME. Check: journalctl --user -u $SERVICE_NAME -e"
  fi

  enable_autoupdate_timer

  if wait_for_service; then
    log "OK: SearXNG installed and running!"
    log "Access it at: http://localhost:${SEARXNG_PORT}"
  else
    fail "Service did not start. Check: journalctl --user -u $SERVICE_NAME -e"
  fi
}

main "$@"