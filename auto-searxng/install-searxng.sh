#!/usr/bin/env bash
#
# install-searxng.sh
# Installs and runs SearXNG as a rootless Podman Quadlet systemd service.
#
set -Eeuo pipefail

readonly QUADLET_DIR="$HOME/.config/containers/systemd"
readonly CONTAINER_FILE="$QUADLET_DIR/searxng.container"
readonly SERVICE_NAME="searxng.service"
DEFAULT_SEARXNG_PORT="5039"
SEARXNG_PORT="$DEFAULT_SEARXNG_PORT"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*"
}

success() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] OK: $*"
}

fail() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
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
  for cmd in podman systemctl; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    fail "Missing required commands: ${missing[*]}"
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

[Install]
WantedBy=default.target
EOF

  log "Cleaning up any existing service/container ..."
  systemctl --user stop "$SERVICE_NAME" &>/dev/null || true
  podman stop searxng &>/dev/null || true
  podman rm -f searxng &>/dev/null || true

  log "Reloading user systemd daemon..."
  systemctl --user daemon-reload

  log "Enabling and starting $SERVICE_NAME ..."
  if ! systemctl --user enable --now "$SERVICE_NAME"; then
    fail "Failed to start $SERVICE_NAME. Check: journalctl --user -u $SERVICE_NAME -e"
  fi

  if wait_for_service; then
    success "SearXNG installed and running!"
    log "Access it at: http://localhost:${SEARXNG_PORT}"
  else
    fail "Service did not start. Check: journalctl --user -u $SERVICE_NAME -e"
  fi
}

main "$@"
