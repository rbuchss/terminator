#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

function terminator::nodenv::bootstrap() {
  if command -v nodenv > /dev/null 2>&1; then
    eval "$(nodenv init -)"

    if terminator::homebrew::package::is_installed nodenv; then
      # shellcheck source=/dev/null
      source "$(brew --prefix nodenv)/completions/nodenv.bash"
    fi
  else
    terminator::log::warning 'nodenv is not installed'
  fi
}
