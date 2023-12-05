#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::grep::__enable__() {
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

function terminator::grep::__export__() {
  export -f terminator::grep::invoke
}

function terminator::grep::__recall__() {
  export -fn terminator::grep::invoke
}

terminator::__module__::export
