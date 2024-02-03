#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::grep::__enable__() {
  terminator::command::exists -v grep || return

  alias grep='terminator::grep::invoke'
  alias egrep='grep -E'
  alias fgrep='grep -F'
}

function terminator::grep::__disable__() {
  unalias grep
  unalias egrep
  unalias fgrep
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
