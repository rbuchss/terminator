#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

terminator::__module__::load || return 0

function terminator::rbenv::__enable__() {
  terminator::command::exists -v rbenv || return

  eval "$(rbenv init -)" > /dev/null

  if terminator::homebrew::package::is_installed rbenv; then
    # shellcheck source=/dev/null
    source "$(brew --prefix rbenv)/completions/rbenv.bash"
  fi
}

# TODO add support for this
# function terminator::rbenv::__disable__() {
#   :
# }

function terminator::rbenv::__export__() {
  :
}

function terminator::rbenv::__recall__() {
  :
}

terminator::__module__::export
