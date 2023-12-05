#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::git::__enable__() {
  if ! command -v git > /dev/null 2>&1; then
    terminator::log::warning 'git is not installed'
    return
  fi

  alias git='terminator::git::invoke'
  alias g='terminator::git::invoke'

  __git_complete g __git_main
}

function terminator::git::invoke() {
  if command -v hub > /dev/null 2>&1; then
    command hub "$@"
    return
  fi

  command git "$@"
}

function terminator::git::__export__() {
  export -f terminator::git::invoke
}

function terminator::git::__recall__() {
  export -fn terminator::git::invoke
}

terminator::__module__::export
