#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/log.sh"

terminator::__pragma__::once || return 0

function terminator::source() {
  for element in "$@"; do
    if [[ -s "${element}" ]]; then
      terminator::log::debug "'${element}'"
      # shellcheck source=/dev/null
      source "${element}"
    else
      terminator::log::warning "'${element}' NOT found!"
    fi
  done
}
