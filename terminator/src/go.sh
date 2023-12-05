#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::go::__enable__() {
  if ! command -v go > /dev/null 2>&1; then
    terminator::log::warning 'go is not installed'
    return
  fi

  GOPATH="$(go env GOPATH)"
  export GOPATH
  export GOBIN="${GOPATH}/bin"
  terminator::path::prepend "${GOBIN}"
}

function terminator::go::__export__() {
  :
}

function terminator::go::__recall__() {
  :
}

terminator::__module__::export
