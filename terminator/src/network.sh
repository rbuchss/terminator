#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::network::__enable__() {
  alias expand_url='terminator::network::expand_url'
}

function terminator::network::expand_url() {
  curl -sIL "$1" | grep ^Location:
}

function terminator::network::__export__() {
  export -f terminator::network::expand_url
}

function terminator::network::__recall__() {
  export -fn terminator::network::expand_url
}

terminator::__module__::export
