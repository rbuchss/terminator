#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/__module__.sh"
source "${HOME}/.terminator/src/dircolors.sh"
source "${HOME}/.terminator/src/homebrew.sh"
source "${HOME}/.terminator/src/os/darwin.sh"
source "${HOME}/.tmux/src/tmuxinator.sh"

terminator::__module__::enable terminator::homebrew

# If not running interactively, don't do anything
if [[ -n "${PS1}" ]]; then
  export BASH_SILENCE_DEPRECATION_WARNING=1

  # We need to reload tmuxinator -> mux alias again since homebrew
  # /usr/local/etc/bash_completion.d/tmuxinator overwrites it
  tmux::tmuxinator::bootstrap

  terminator::cdpath::prepend "${HOME}/Library/Services/"

  terminator::__module__::enable \
    terminator::dircolors \
    terminator::os::darwin
fi
