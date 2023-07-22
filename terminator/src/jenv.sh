#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::jenv::__initialize__() {
  if ! command -v jenv > /dev/null 2>&1; then
    terminator::log::warning 'jenv is not installed'
    return
  fi

  # export PATH="${HOME}/.jenv/bin:$PATH"
  eval "$(jenv init -)"
}
