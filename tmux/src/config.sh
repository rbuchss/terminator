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
    tmux::log::error "current version ${version} config directory: '${path}' does NOT exist"
    return 1
  fi
}

function tmux::config::rollback_version() {
  local path
  path="$(tmux::config::version::path)"
  # TODO fix this
  # shellcheck disable=SC2012
  ls "${path}" | sort -V | tail -1
}

function tmux::config::rollback_version::path() {
  tmux::config::version::path "$(tmux::config::rollback_version)"
}
