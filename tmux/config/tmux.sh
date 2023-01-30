#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.tmux/src/command.sh"
source "${HOME}/.tmux/src/tmuxinator.sh"

alias tmux='tmux::command::invoke'
alias tmuxinator='tmuxinator::command::invoke'
alias mux='tmuxinator::command::invoke'
tmux::tmuxinator::completion::add_alias 'mux'
