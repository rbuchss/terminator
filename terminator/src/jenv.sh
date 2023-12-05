#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"

terminator::__module__::load || return 0

function terminator::jenv::__enable__() {
  if ! command -v jenv > /dev/null 2>&1; then
    terminator::log::warning 'jenv is not installed'
    return
  fi

  # export PATH="${HOME}/.jenv/bin:$PATH"
  eval "$(jenv init -)"
}

function terminator::jenv::__export__() {
  :
}

function terminator::jenv::__recall__() {
  :
}

terminator::__module__::export
