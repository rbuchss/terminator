#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/log.sh"

function terminator::source() {
  for element in "$@"; do
    if [[ -s "${element}" ]]; then
      terminator::log::debug "${FUNCNAME[0]}: '${element}'"
      # TODO add guard here?
      # shellcheck source=/dev/null
      source "${element}"
    else
      terminator::log::warning "${FUNCNAME[0]}: '${element}' not found"
    fi
  done
}
