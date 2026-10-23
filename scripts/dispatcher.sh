#!/usr/bin/env bash
# Helper for running the AEM dispatcher with the configuration of any AEM project.
#
# Usage:
#   ./scripts/dispatcher.sh load                 Load the dispatcher Docker image from the Dispatcher SDK
#   ./scripts/dispatcher.sh use <project-path>   Point the dispatcher to a project's dispatcher config and restart it
#   ./scripts/dispatcher.sh validate [path]      Validate a dispatcher config with the SDK validator
#   ./scripts/dispatcher.sh reload               Restart the dispatcher to pick up config changes
#   ./scripts/dispatcher.sh current              Show which config is currently used

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

env_value() {
  grep -E "^$1=" "$ENV_FILE" | tail -n 1 | cut -d '=' -f 2-
}

SDK_VERSION="$(env_value DISPATCHER_SDK_VERSION)"
SDK_DIR="$ROOT_DIR/dispatcher/dispatcher-sdk-$SDK_VERSION"

compose() {
  (cd "$ROOT_DIR" && docker compose "$@")
}

require_sdk() {
  if [ ! -d "$SDK_DIR" ]; then
    echo "Dispatcher SDK not found in $SDK_DIR" >&2
    echo "Extract aem-sdk-dispatcher-tools-$SDK_VERSION-unix.sh in ./dispatcher (see README)." >&2
    exit 1
  fi
}

# Resolves a project root, its dispatcher folder or its dispatcher/src folder
# to the folder containing conf.d and conf.dispatcher.d.
resolve_config_dir() {
  local path="$1"
  if [ ! -d "$path" ]; then
    echo "Directory not found: $path" >&2
    exit 1
  fi
  path="$(cd "$path" && pwd)"
  local candidate
  for candidate in "$path" "$path/src" "$path/dispatcher/src"; do
    if [ -d "$candidate/conf.d" ] && [ -d "$candidate/conf.dispatcher.d" ]; then
      echo "$candidate"
      return
    fi
  done
  echo "No dispatcher config (conf.d + conf.dispatcher.d) found in $path, $path/src or $path/dispatcher/src" >&2
  exit 1
}

cmd_load() {
  require_sdk
  local arch
  case "$(uname -m)" in
    arm64|aarch64) arch=arm64 ;;
    *) arch=amd64 ;;
  esac
  local image="$SDK_DIR/lib/dispatcher-publish-$arch.tar.gz"
  if [ ! -f "$image" ]; then
    echo "Dispatcher image not found: $image" >&2
    exit 1
  fi
  docker load --input "$image"
}

cmd_use() {
  local config_dir
  config_dir="$(resolve_config_dir "${1:?Usage: $0 use <project-path>}")"
  if grep -qE '^DISPATCHER_CONFIG_DIR=' "$ENV_FILE"; then
    local tmp
    tmp="$(mktemp)"
    sed "s|^DISPATCHER_CONFIG_DIR=.*|DISPATCHER_CONFIG_DIR=$config_dir|" "$ENV_FILE" > "$tmp"
    cat "$tmp" > "$ENV_FILE"
    rm -f "$tmp"
  else
    echo "DISPATCHER_CONFIG_DIR=$config_dir" >> "$ENV_FILE"
  fi
  echo "Dispatcher config: $config_dir"
  compose up -d --force-recreate --no-deps dispatcher
}

cmd_validate() {
  require_sdk
  local config_dir
  if [ -n "${1:-}" ]; then
    config_dir="$(resolve_config_dir "$1")"
  else
    config_dir="$(cd "$ROOT_DIR" && resolve_config_dir "$(env_value DISPATCHER_CONFIG_DIR)")"
  fi
  "$SDK_DIR/bin/validate.sh" "$config_dir"
}

cmd_reload() {
  compose restart dispatcher
}

cmd_current() {
  env_value DISPATCHER_CONFIG_DIR
}

case "${1:-}" in
  load) cmd_load ;;
  use) shift; cmd_use "$@" ;;
  validate) shift; cmd_validate "$@" ;;
  reload) cmd_reload ;;
  current) cmd_current ;;
  *)
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
