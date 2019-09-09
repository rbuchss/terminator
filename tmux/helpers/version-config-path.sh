#!/bin/bash

tmux_version=$(tmux -V | grep -E -o '([0-9.]+)')
echo "$HOME/.tmux/config/version/$tmux_version"
