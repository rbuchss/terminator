#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.tmux/src/command.sh"
source "${HOME}/.tmux/src/tmuxinator.sh"

alias tmux='tmux::command::invoke'

tmux::tmuxinator::bootstrap
