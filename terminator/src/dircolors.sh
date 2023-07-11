#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::dircolors::bootstrap() {
  if command -v dircolors > /dev/null 2>&1; then
    eval "$(dircolors "${HOME}/.dir_colors")"
  else
    terminator::log::warning 'dircolors is not installed'
  fi
}
