#!/bin/bash

function terminator::dircolors::bootstrap() {
  if command -v dircolors > /dev/null 2>&1; then
    eval "$(dircolors "${HOME}/.dir_colors")"
  else
    terminator::log::warning 'dircolors is not installed'
  fi
}
