#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/version.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"

function tmux::config::path() {
  local result="${TMUX_CONFIG_PATH:-${HOME}/.tmux/config}"

  for element in "$@"; do
    result="${result}/${element}"
  done

  echo "${result}"
}

function tmux::config::load() {
  for element in "$@"; do
    source "$(tmux::config::path "${element}")"
  done
}

function tmux::config::version::path() {
  if (( $# == 0 )); then
    tmux::config::path 'version'
    return
  fi

  tmux::config::path 'version' "$@"
}

function tmux::config::current_version::path() {
  local version path
  version="$(tmux::version)"
  path="$(tmux::config::version::path "${version}")"
  echo "${path}"

  if [[ ! -d "${path}" ]]; then
    tmux::log::error \
      "current version ${version} config directory: '${path}' does NOT exist"
    return 1
  fi
}

function tmux::config::rollback_version() {
  local path versions=()
  path="$(tmux::config::version::path)"

  while IFS='' read -r version; do
    versions+=("${version}")
  done < <(find "${path}" -depth 1 -type d -exec basename {} \; | sort -rV)

  tmux::log::debug "available versions: ${versions[*]}"

  for version in "${versions[@]}"; do
    if tmux::version::compare::greater_than "${version}"; then
      tmux::log::debug "selected rollback version: ${version}"
      echo "${version}"
      return
    fi
  done

  tmux::log::error \
    "no eligible rollback versions found (current $(tmux::version) > rollback)"
  return 1
}
