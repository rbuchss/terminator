#!/bin/bash

# This prevents duplicated path/cdpath/manpath/PROMPT_COMMAND created when using tmux
# by clearing out the old path and then rebuilding it like a brand new login shell.
# It will not do this if bash_login has already been run.
if [[ -n "${TMUX}" ]] && [[ -z "${TMUX_PATH_INITIALIZED}" ]]; then
  terminator::log::debug 'Initializing tmux - resetting PATHs and PROMPT_COMMAND'
  terminator::paths::clear
  PROMPT_COMMAND=''
  export TMUX_PATH_INITIALIZED=1
fi

terminator::source "${HOME}/.tmux/config/tmux.sh"
