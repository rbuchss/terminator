#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::grep::__initialize__() {
  if ! command -v grep > /dev/null 2>&1; then
    terminator::log::warning 'grep is not installed'
    return
  fi

  alias grep='terminator::grep::invoke'
  alias egrep='grep -E'
  alias fgrep='grep -F'
}

function terminator::grep::invoke() {
  command grep --color=auto \
    --exclude-dir='\.git' \
    --exclude-dir='\.svn' \
    "$@"
}
