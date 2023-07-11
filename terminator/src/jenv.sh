#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::jenv::bootstrap() {
  if command -v jenv > /dev/null 2>&1; then
    # export PATH="${HOME}/.jenv/bin:$PATH"
    eval "$(jenv init -)"
  else
    terminator::log::warning 'jenv is not installed'
  fi
}
