#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

function terminator::rbenv::bootstrap() {
  if command -v rbenv > /dev/null 2>&1; then
    eval "$(rbenv init -)" > /dev/null

    if terminator::homebrew::package::is_installed rbenv; then
      # shellcheck source=/dev/null
      source "$(brew --prefix rbenv)/completions/rbenv.bash"
    fi
  else
    terminator::log::warning 'rbenv is not installed'
  fi
}
