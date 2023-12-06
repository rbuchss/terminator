#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::tree::__enable__() {
  if ! command -v tree > /dev/null 2>&1; then
    terminator::log::warning 'tree is not installed'
    return
  fi

  alias tree='tree -I "\.git|\.svn|sandcube|node_modules"'
}

function terminator::tree::__export__() {
  :
}

function terminator::tree::__recall__() {
  :
}

terminator::__module__::export
