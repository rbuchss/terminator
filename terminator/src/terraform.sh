#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

terminator::__pragma__::once || return 0

function terminator::terraform::bootstrap() {
  if command -v terraform > /dev/null 2>&1; then
    if terminator::homebrew::package::is_installed terraform; then
      # shellcheck source=/dev/null
      complete -C "$(brew --prefix)/bin/terraform" terraform
      complete -C "$(brew --prefix)/bin/terraform" tf
    fi

    alias tf='terraform'
  else
    terminator::log::warning 'terraform is not installed'
  fi
}
