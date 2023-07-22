#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::go::__initialize__() {
  if ! command -v go > /dev/null 2>&1; then
    terminator::log::warning 'go is not installed'
    return
  fi

  GOPATH="$(go env GOPATH)"
  export GOPATH
  export GOBIN="${GOPATH}/bin"
  terminator::path::prepend "${GOBIN}"
}
