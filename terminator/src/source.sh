#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/log.sh"

function terminator::source() {
  for element in "$@"; do
    if [[ -s "${element}" ]]; then
      terminator::log::debug "'${element}'"
      # TODO add guard here?
      # shellcheck source=/dev/null
      source "${element}"
    else
      terminator::log::warning "'${element}' NOT found!"
    fi
  done
}
