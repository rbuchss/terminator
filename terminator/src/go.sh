#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/path.sh"

terminator::__module__::load || return 0

function terminator::go::__enable__ {
  # Well-known Go install locations not on PATH by default
  local __go_path__
  for __go_path__ in '/usr/local/go/bin' "${HOME}/go/bin"; do
    if [[ -d "${__go_path__}" ]]; then
      terminator::path::prepend "${__go_path__}"
    fi
  done

  terminator::command::exists -v go || return

  GOPATH="$(go env GOPATH)"
  export GOPATH
  export GOBIN="${GOPATH}/bin"

  terminator::path::prepend "${GOBIN}"
}

function terminator::go::__disable__ {
  terminator::path::remove "${GOBIN}"
  terminator::path::remove '/usr/local/go/bin'
  terminator::path::remove "${HOME}/go/bin"

  unset GOPATH
  unset GOBIN
}

function terminator::go::__export__ {
  :
}

# KCOV_EXCL_START
function terminator::go::__recall__ {
  :
}
# KCOV_EXCL_STOP

terminator::__module__::export
