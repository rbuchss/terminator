#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/source.sh"

function terminator::config::path() {
  local result="${HOME}/.terminator/config"

  for element in "$@"; do
    result="${result}/${element}"
  done

  echo "${result}"
}

function terminator::config::load() {
  for element in "$@"; do
    terminator::source "$(terminator::config::path "${element}")"
  done
}
