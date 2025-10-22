#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"

terminator::__module__::load || return 0

function terminator::dircolors::__enable__ {
  terminator::command::exists -v dircolors || return

  eval "$(dircolors "${HOME}/.dir_colors")"
}

function terminator::dircolors::__disable__ {
  unset LS_COLORS
}

function terminator::dircolors::__export__ {
  export -f terminator::dircolors::__enable__
}

function terminator::dircolors::__recall__ {
  export -fn terminator::dircolors::__enable__
}

terminator::__module__::export
