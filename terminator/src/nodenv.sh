#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

terminator::__pragma__::once || return 0

function terminator::nodenv::__initialize__() {
  if ! command -v nodenv > /dev/null 2>&1; then
    terminator::log::warning 'nodenv is not installed'
    return
  fi

  eval "$(nodenv init -)"

  if terminator::homebrew::package::is_installed nodenv; then
    # shellcheck source=/dev/null
    source "$(brew --prefix nodenv)/completions/nodenv.bash"
  fi
}
