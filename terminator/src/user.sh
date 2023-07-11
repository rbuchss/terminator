#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::user::is_root() {
  (( EUID == 0 ))
}
