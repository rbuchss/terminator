#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::tree::__enable__() {
  terminator::command::exists -v tree || return

  alias tree='tree -I "\.git|\.svn|sandcube|node_modules"'
}

function terminator::tree::__disable__() {
  unalias tree
}

function terminator::tree::__export__() {
  :
}

function terminator::tree::__recall__() {
  :
}

terminator::__module__::export
