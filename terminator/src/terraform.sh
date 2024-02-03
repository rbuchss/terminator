#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

terminator::__module__::load || return 0

function terminator::terraform::__enable__() {
  terminator::command::exists -v terraform || return

  if terminator::homebrew::package::is_installed terraform; then
    # shellcheck source=/dev/null
    complete -C "$(brew --prefix)/bin/terraform" terraform
    complete -C "$(brew --prefix)/bin/terraform" tf
  fi

  alias tf='terraform'
}

function terminator::terraform::__disable__() {
  complete -r terraform
  complete -r tf

  unalias tf
}

function terminator::terraform::__export__() {
  :
}

function terminator::terraform::__recall__() {
  :
}

terminator::__module__::export
