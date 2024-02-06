#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"
source "${BASH_SOURCE[0]%/*}/path.sh"

terminator::__module__::load || return 0

function terminator::go::__enable__ {
  terminator::command::exists -v go || return

  GOPATH="$(go env GOPATH)"
  export GOPATH
  export GOBIN="${GOPATH}/bin"

  terminator::path::prepend "${GOBIN}"
}

function terminator::go::__disable__ {
  unset GOPATH
  unset GOBIN

  terminator::path::remove "${GOBIN}"
}

function terminator::go::__export__ {
  :
}

function terminator::go::__recall__ {
  :
}

terminator::__module__::export
