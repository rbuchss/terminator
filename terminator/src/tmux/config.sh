#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/logger.sh"
source "${BASH_SOURCE[0]%/*}/version.sh"

terminator::__module__::load || return 0

function terminator::tmux::config::path {
  local result="${TMUX_CONFIG_PATH:-${HOME}/.config/tmux}"

  for element in "$@"; do
    result="${result}/${element}"
  done

  echo "${result}"
}

function terminator::tmux::config::load {
  for element in "$@"; do
    source "$(terminator::tmux::config::path "${element}")"
  done
}

function terminator::tmux::config::version::path {
  if (( $# == 0 )); then
    terminator::tmux::config::path 'version'
    return
  fi

  terminator::tmux::config::path 'version' "$@"
}

function terminator::tmux::config::current_version::path {
  local version path
  version="$(terminator::tmux::version)"
  path="$(terminator::tmux::config::version::path "${version}")"
  echo "${path}"

  if [[ ! -d "${path}" ]]; then
    terminator::tmux::logger::error \
      "current version ${version} config directory: '${path}' does NOT exist"
    return 1
  fi
}

function terminator::tmux::config::rollback_version {
  local path versions=()
  path="$(terminator::tmux::config::version::path)"

  while IFS='' read -r version; do
    versions+=("${version}")
  done < <(find "${path}" -depth 1 -type d -exec basename {} \; | sort -rV)

  terminator::tmux::logger::debug "available versions: ${versions[*]}"

  for version in "${versions[@]}"; do
    if terminator::tmux::version::compare::greater_than "${version}"; then
      terminator::tmux::logger::debug "selected rollback version: ${version}"
      echo "${version}"
      return
    fi
  done

  terminator::tmux::logger::error \
    "no eligible rollback versions found (current $(terminator::tmux::version) > rollback)"
  return 1
}

function terminator::tmux::config::__export__ {
  export -f terminator::tmux::config::path
  export -f terminator::tmux::config::load
  export -f terminator::tmux::config::version::path
  export -f terminator::tmux::config::current_version::path
  export -f terminator::tmux::config::rollback_version
}

function terminator::tmux::config::__recall__ {
  export -fn terminator::tmux::config::path
  export -fn terminator::tmux::config::load
  export -fn terminator::tmux::config::version::path
  export -fn terminator::tmux::config::current_version::path
  export -fn terminator::tmux::config::rollback_version
}

terminator::__module__::export
