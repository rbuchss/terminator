#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/bootstrap.sh"

# using GNU for coreutils vs BSD
terminator::bootstrap::os::darwin::add_brew_paths \
  'coreutils' \
  'gnu-sed'

# gotta have dircolors
eval "$(dircolors "${HOME}/.dir_colors")"

terminator::cdpath::prepend "${HOME}/Library/Services/"

terminator::source \
  "$(brew --prefix)/etc/bash_completion" \
  "$(brew --prefix grc)/etc/grc.bashrc"
