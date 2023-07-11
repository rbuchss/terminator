#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/source.sh"

terminator::__pragma__::once || return 0

function terminator::config::path() {
  local result="${HOME}/.terminator/config"

  for element in "$@"; do
    result="${result}/${element}"
  done

  echo "${result}"
}

function terminator::config::load() {
  for element in "$@"; do
    terminator::source "$(terminator::config::path "${element}")"
  done
}
