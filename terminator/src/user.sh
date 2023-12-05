#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::user::is_root() {
  (( EUID == 0 ))
}

function terminator::user::__export__() {
  export -f terminator::user::is_root
}

function terminator::user::__recall__() {
  export -fn terminator::user::is_root
}

terminator::__module__::export
