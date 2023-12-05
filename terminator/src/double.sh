#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::double::compare() {
  if (( $# != 2 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]}: invalid number of arguments"
    >&2 echo "usage: ${FUNCNAME[0]} rhs lhs"
    return 4
  fi

  awk -v lhs="$1" -v rhs="$2" 'BEGIN {
    if (lhs == rhs) {
      exit 0
    } else if (lhs > rhs) {
      exit 1
    } else if (lhs < rhs) {
      exit 2
    }
    exit 3
  }'
}

function terminator::double::__export__() {
  export -f terminator::double::compare
}

function terminator::double::__recall__() {
  export -fn terminator::double::compare
}

terminator::__module__::export
