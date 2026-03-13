#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/path.sh"

terminator::__module__::load || return 0

function terminator::bun::__enable__ {
  # Standard bun install location (not on PATH by default on Linux)
  if [[ -d "${HOME}/.bun/bin" ]]; then
    terminator::path::prepend "${HOME}/.bun/bin"
  fi

  terminator::command::exists -v bun || return
}

function terminator::bun::__disable__ {
  terminator::path::remove "${HOME}/.bun/bin"
}

function terminator::bun::__export__ {
  :
}

# KCOV_EXCL_START
function terminator::bun::__recall__ {
  :
}
# KCOV_EXCL_STOP

terminator::__module__::export
