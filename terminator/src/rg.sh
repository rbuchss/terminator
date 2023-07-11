#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::rg::bootstrap() {
  if command -v rg > /dev/null 2>&1; then
    alias rg='terminator::rg::invoke'
  else
    terminator::log::warning 'rg is not installed'
  fi
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