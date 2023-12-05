#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/homebrew.sh"

terminator::__module__::load || return 0

function terminator::pyenv::__enable__() {
  if ! command -v pyenv > /dev/null 2>&1; then
    terminator::log::warning 'pyenv is not installed'
    return
  fi

  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"

  # pyenv virtualenv uses PROMPT_COMMAND as a hook (_pyenv_virtualenv_hook)
  # and is slow ... ~70-100ms
  # eval "$(pyenv virtualenv-init -)"

  if terminator::homebrew::package::is_installed pyenv; then
    # shellcheck source=/dev/null
    source "$(brew --prefix pyenv)/completions/pyenv.bash"
  fi
}

function terminator::pyenv::__export__() {
  :
}

function terminator::pyenv::__recall__() {
  :
}

terminator::__module__::export
