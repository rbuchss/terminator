#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

function terminator::pyenv::bootstrap() {
  if command -v pyenv > /dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"

    # pyenv virtualenv uses PROMPT_COMMAND as a hook (_pyenv_virtualenv_hook)
    # and is slow ... ~70-100ms
    # eval "$(pyenv virtualenv-init -)"

    if terminator::homebrew::package::is_installed pyenv; then
      # shellcheck source=/dev/null
      source "$(brew --prefix pyenv)/completions/pyenv.bash"
    fi
  else
    terminator::log::warning 'pyenv is not installed'
  fi
}
