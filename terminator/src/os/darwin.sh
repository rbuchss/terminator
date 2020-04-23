#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/source.sh"
source "${HOME}/.terminator/src/path.sh"

function terminator::os::darwin::add_brew_paths() {
  local prefix

  for element in "$@"; do
    prefix="$(brew --prefix "${element}")"
    terminator::log::debug "'${prefix}'"
    terminator::path::prepend "${prefix}/libexec/gnubin"
    terminator::manpath::prepend "${prefix}/libexec/gnuman"
  done
}
