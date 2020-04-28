#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.tmux/src/command.sh"
source "${HOME}/.tmux/src/tmuxinator.sh"

alias tmux='tmux::command::invoke'
alias mux='tmuxinator'
tmux::tmuxinator::completion::add_alias 'mux'
