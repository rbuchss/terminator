#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::ag::__enable__() {
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

function terminator::ag::__export__() {
  export -f terminator::ag::invoke
}

function terminator::ag::__recall__() {
  export -fn terminator::ag::invoke
}

terminator::__module__::export
