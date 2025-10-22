#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"

terminator::__module__::load || return 0

function terminator::jenv::__enable__ {
  terminator::command::exists -v jenv || return

  # export PATH="${HOME}/.jenv/bin:$PATH"
  eval "$(jenv init -)"
}

# TODO add support for this
# function terminator::jenv::__disable__ {
#   :
# }

function terminator::jenv::__export__ {
  :
}

function terminator::jenv::__recall__ {
  :
}

terminator::__module__::export
