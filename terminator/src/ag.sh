#!/bin/bash

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
