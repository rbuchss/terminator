#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

terminator::__module__::load || return 0

function terminator::nodenv::__enable__() {
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

function terminator::nodenv::__export__() {
  :
}

function terminator::nodenv::__recall__() {
  :
}

terminator::__module__::export
