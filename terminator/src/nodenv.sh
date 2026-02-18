#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/command.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/homebrew.sh"

terminator::__module__::load || return 0

function terminator::nodenv::__enable__ {
  terminator::command::exists -v nodenv || return

  eval "$(nodenv init -)"

  if terminator::homebrew::package::is_installed nodenv; then
    # shellcheck source=/dev/null
    source "$(brew --prefix nodenv)/completions/nodenv.bash"
  fi
}

# TODO add support for this
# function terminator::nodenv::__disable__ {
#   :
# }

function terminator::nodenv::__export__ {
  :
}

# KCOV_EXCL_START
function terminator::nodenv::__recall__ {
  :
}
# KCOV_EXCL_STOP

terminator::__module__::export
