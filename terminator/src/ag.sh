#!/bin/bash

function terminator::ag::bootstrap() {
  if command -v ag > /dev/null 2>&1; then
    alias ag='terminator::ag::invoke'
  else
    terminator::log::warning 'ag is not installed'
  fi
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
