#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::array::contains() {
  local element
  for element in "${@:2}"; do
    if [[ "${element}" == "$1" ]]; then
      return 0
    fi
  done
  return 1
}
