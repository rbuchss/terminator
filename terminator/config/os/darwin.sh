#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/os/darwin.sh"
source "${HOME}/.terminator/src/dircolors.sh"
source "${HOME}/.terminator/src/homebrew.sh"

terminator::homebrew::bootstrap

# If not running interactively, don't do anything
if [[ -n "${PS1}" ]]; then
  terminator::cdpath::prepend "${HOME}/Library/Services/"

  terminator::dircolors::bootstrap

  alias show-files='terminator::os::darwin::finder::show_hidden_files'
  alias hide-files='terminator::os::darwin::finder::hide_hidden_files'
fi
