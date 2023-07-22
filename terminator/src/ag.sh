#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::ag::__initialize__() {
  if ! command -v ag > /dev/null 2>&1; then
    terminator::log::warning 'ag is not installed'
    return
  fi

  alias ag='terminator::ag::invoke'
}

function terminator::ag::invoke() {
  local less_options=(
    --quit-if-one-screen
    --RAW-CONTROL-CHARS
    --no-init
  )
  command ag \
    --hidden \
    --pager="less ${less_options[*]}" \
    "$@"
}
