#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::grep::bootstrap() {
  if command -v grep > /dev/null 2>&1; then
    alias grep='terminator::grep::invoke'
    alias egrep='grep -E'
    alias fgrep='grep -F'
  else
    terminator::log::warning 'grep is not installed'
  fi
}

function terminator::grep::invoke() {
  command grep --color=auto \
    --exclude-dir='\.git' \
    --exclude-dir='\.svn' \
    "$@"
}
