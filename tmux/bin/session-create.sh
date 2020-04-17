#!/bin/bash

export TMUX_CONFIG_PATH="$HOME/.tmux/config"

# shellcheck source=/dev/null
source "$HOME/.tmux/src/bootstrap.sh"

tmux::bootstrap::session_create
