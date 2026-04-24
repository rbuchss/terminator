#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"

terminator::__module__::load || return 0

function terminator::mise::__enable__ {
  terminator::command::exists -v mise || return

  eval "$(mise activate bash)"
  eval "$(mise completion bash)"
}

# TODO add support for this
# function terminator::mise::__disable__ {
#   :
# }

function terminator::mise::__export__ {
  :
}

# KCOV_EXCL_START
function terminator::mise::__recall__ {
  :
}
# KCOV_EXCL_STOP

terminator::__module__::export
