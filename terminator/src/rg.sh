#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::rg::__enable__() {
  if ! command -v rg > /dev/null 2>&1; then
    terminator::log::warning 'rg is not installed'
    return
  fi

  alias rg='terminator::rg::invoke'
}

function terminator::rg::invoke() {
  # STDOUT is attached to a pipe: -p /dev/stdout
  # STDOUT is attached to a redirection: ! -t 1 && ! -p /dev/stdout
  if [[ -p /dev/stdout || (! -t 1 && ! -p /dev/stdout) ]]; then
    command rg \
      --hidden \
      --smart-case \
      --line-number \
      "$@"
    return
  fi

  # STDOUT is attached to TTY
  command rg \
    --hidden \
    --smart-case \
    --pretty \
    "$@" \
    | less \
      --quit-if-one-screen \
      --RAW-CONTROL-CHARS \
      --no-init
}

function terminator::rg::__export__() {
  export -f terminator::rg::invoke
}

function terminator::rg::__recall__() {
  export -fn terminator::rg::invoke
}

terminator::__module__::export
