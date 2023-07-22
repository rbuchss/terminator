#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

terminator::__pragma__::once || return 0

function terminator::rbenv::__initialize__() {
  if ! command -v rbenv > /dev/null 2>&1; then
    terminator::log::warning 'rbenv is not installed'
    return
  fi

  eval "$(rbenv init -)" > /dev/null

  if terminator::homebrew::package::is_installed rbenv; then
    # shellcheck source=/dev/null
    source "$(brew --prefix rbenv)/completions/rbenv.bash"
  fi
}
