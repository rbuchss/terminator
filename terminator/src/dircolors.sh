#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::dircolors::__enable__() {
  if ! command -v dircolors > /dev/null 2>&1; then
    terminator::log::warning 'dircolors is not installed'
    return
  fi

  eval "$(dircolors "${HOME}/.dir_colors")"
}

function terminator::dircolors::__export__() {
  export -f terminator::dircolors::__enable__
}

function terminator::dircolors::__recall__() {
  export -fn terminator::dircolors::__enable__
}

terminator::__module__::export
