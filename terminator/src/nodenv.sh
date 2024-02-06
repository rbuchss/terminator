#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

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

function terminator::nodenv::__recall__ {
  :
}

terminator::__module__::export
