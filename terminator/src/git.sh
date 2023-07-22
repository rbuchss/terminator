#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::git::__initialize__() {
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
