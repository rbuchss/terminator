#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/os/darwin.sh"
source "${HOME}/.terminator/src/homebrew.sh"

# using GNU for coreutils vs BSD
terminator::homebrew::add_paths \
  'coreutils' \
  'gnu-sed'

terminator::cdpath::prepend "${HOME}/Library/Services/"

terminator::source \
  "$(brew --prefix)/etc/bash_completion" \
  "$(brew --prefix grc)/etc/grc.bashrc"

# If not running interactively, don't do anything
if [[ -n "${PS1}" ]]; then
  # gotta have dircolors
  eval "$(dircolors "${HOME}/.dir_colors")"

  alias show-files='terminator::os::darwin::finder::show_hidden_files'
  alias hide-files='terminator::os::darwin::finder::hide_hidden_files'
  alias brew-cleaner='terminator::homebrew::clean'
  alias brew-cask-cleaner='terminator::homebrew::cask::clean'
fi
