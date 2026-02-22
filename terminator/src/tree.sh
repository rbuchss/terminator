#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"

terminator::__module__::load || return 0

function terminator::tree::__enable__ {
  terminator::command::exists -v tree || return

  alias tree='tree -I "\.git|\.svn|sandcube|node_modules"'
}

function terminator::tree::__disable__ {
  unalias tree
}

function terminator::tree::__export__ {
  :
}

# KCOV_EXCL_START
function terminator::tree::__recall__ {
  :
}
# KCOV_EXCL_STOP

terminator::__module__::export
