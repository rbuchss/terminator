#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/source.sh"
source "${BASH_SOURCE[0]%/*}/path.sh"

function terminator::homebrew::add_paths() {
  local prefix

  for element in "$@"; do
    prefix="$(brew --prefix "${element}")"
    terminator::log::debug "'${prefix}'"
    terminator::path::prepend "${prefix}/libexec/gnubin"
    terminator::manpath::prepend "${prefix}/libexec/gnuman"
  done
}

function terminator::homebrew::clean() {
  brew update && brew cleanup
}

function terminator::homebrew::cask::clean() {
  brew upgrade brew-cask && brew cask cleanup
}
