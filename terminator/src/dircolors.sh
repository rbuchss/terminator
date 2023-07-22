#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::dircolors::__initialize__() {
  if ! command -v dircolors > /dev/null 2>&1; then
    terminator::log::warning 'dircolors is not installed'
    return
  fi

  eval "$(dircolors "${HOME}/.dir_colors")"
}
