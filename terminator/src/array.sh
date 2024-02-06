#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::array::contains {
  local element
  for element in "${@:2}"; do
    if [[ "${element}" == "$1" ]]; then
      return 0
    fi
  done
  return 1
}

function terminator::array::__export__ {
  export -f terminator::array::contains
}

function terminator::array::__recall__ {
  export -fn terminator::array::contains
}

terminator::__module__::export
