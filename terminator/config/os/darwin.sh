#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/source.sh"
source "${HOME}/.terminator/src/path.sh"

# using GNU for coreutils vs BSD
terminator::bootstrap::os::darwin::add_brew_paths coreutils gnu-sed

# gotta have dircolors
eval "$(dircolors "${HOME}/.dir_colors")"

export my_services="${HOME}/Library/Services/"
terminator::cdpath::prepend "$my_services"

terminator::source "$(brew --prefix)/etc/bash_completion"
terminator::source "$(brew --prefix grc)/etc/grc.bashrc"
