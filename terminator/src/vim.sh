#!/bin/bash

function terminator::vim::bootstrap() {
  if ! command -v nvim > /dev/null 2>&1 \
      && ! command -v vim > /dev/null 2>&1; then
    terminator::log::warning 'vim and nvim are not installed'
    return
  fi

  alias vi='terminator::vim::invoke'
  alias vim='terminator::vim::invoke'
  alias vf='terminator::vim::open::filename_match'
  alias vg='terminator::vim::open::content_match'
  alias vd='terminator::vim::open::git_diff'
}

function terminator::vim::invoke() {
  local found_command=0 \
    vim_command \
    vim_commands=(
      nvim
      vim
    )

  for vim_command in "${vim_commands[@]}"; do
    if command -v "${vim_command}" > /dev/null 2>&1; then
      found_command=1
      command "${vim_command}" "$@"
      break
    fi
  done

  if (( found_command == 0 )); then
    terminator::log::error "No possible vim commands found: [${vim_commands[*]}]"
    return 1
  fi
}

function terminator::vim::open::filename_match() {
  # shellcheck disable=SC2046
  vim -p $(ag -g "$1" "${2:-./}")
}

function terminator::vim::open::content_match() {
  # shellcheck disable=SC2046
  vim -p $(ag -l "$1" "${2:-./}")
}

function terminator::vim::open::git_diff() {
  # shellcheck disable=SC2046
  vim -p $(git diff --name-only "${1:-HEAD}")
}
