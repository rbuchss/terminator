#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/log.sh"

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

  # We need to export the vim wrapper function for it to be accessible via xargs
  export -f terminator::vim::invoke

  # Sets up completion for git branches
  __git_complete vd _git_checkout
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
  local found_command=0 \
    search_command \
    search_commands=(
      'rg'
      'ag'
      'ack'
      'find'
    )

  for search_command in "${search_commands[@]}"; do
    terminator::log::debug "Trying to search with command: ${search_command}"

    if command -v "${search_command}" > /dev/null 2>&1; then
      terminator::log::debug "Found search command: ${search_command}"

      found_command=1

      # using subshell to invoke exported wrapper function - see shellcheck SC2033.
      # vim expects tty to be attached and will not work without.
      # ${FUNCNAME[0]} is a placeholder for the $0 var and without we'd lose the first file passed to vim.
      "terminator::vim::open::filename_match::${search_command}" "$@" \
        | xargs -0 bash -c 'terminator::vim::invoke -p "$@" < /dev/tty' "${FUNCNAME[0]}"

      break
    fi
  done

  if (( found_command == 0 )); then
    terminator::log::error "No possible search commands found: [${search_commands[*]}]"
    return 1
  fi
}

function terminator::vim::open::filename_match::rg() {
  command rg \
    --files \
    --hidden \
    --null \
    "${2:-./}" \
    | command rg \
      --null-data \
      --smart-case \
      "$1"
}

function terminator::vim::open::filename_match::ag() {
  command ag \
    --hidden \
    --smart-case \
    --null \
    -g "$1" \
    "${2:-./}"
}

function terminator::vim::open::filename_match::ack() {
  command ack \
    --ignore-dir=.git \
    --smart-case \
    --print0 \
    -g "$1" \
    "${2:-./}"
}

function terminator::vim::open::filename_match::find() {
  command find "${2:-.}" \
    -not \( -path "${2:-.}/.git" -prune \) \
    -type f \
    -regex ".*$1.*" \
    -print0
}

function terminator::vim::open::content_match() {
  local found_command=0 \
    search_command \
    search_commands=(
      'rg'
      'ag'
      'ack'
      'grep'
    )

  for search_command in "${search_commands[@]}"; do
    terminator::log::debug "Trying to search with command: ${search_command}"

    if command -v "${search_command}" > /dev/null 2>&1; then
      terminator::log::debug "Found search command: ${search_command}"

      found_command=1

      # using subshell to invoke exported wrapper function - see shellcheck SC2033.
      # vim expects tty to be attached and will not work without.
      # ${FUNCNAME[0]} is a placeholder for the $0 var and without we'd lose the first file passed to vim.
      "terminator::vim::open::content_match::${search_command}" "$@" \
        | xargs -0 bash -c 'terminator::vim::invoke -p "$@" < /dev/tty' "${FUNCNAME[0]}"

      break
    fi
  done

  if (( found_command == 0 )); then
    terminator::log::error "No possible search commands found: [${search_commands[*]}]"
    return 1
  fi
}

function terminator::vim::open::content_match::rg() {
  command rg \
    --hidden \
    --smart-case \
    -l \
    --null \
    "$1" \
    "${2:-./}"
}

function terminator::vim::open::content_match::ag() {
  command ag \
    --hidden \
    --smart-case \
    -l \
    --null \
    "$1" \
    "${2:-./}"
}

function terminator::vim::open::content_match::ack() {
  command ack \
    --ignore-dir=.git \
    --smart-case \
    -l \
    --print0 \
    "$1" \
    "${2:-./}"
}

function terminator::vim::open::content_match::grep() {
  command grep \
    -R \
    --exclude-dir=.git \
    -l \
    --null \
    "$1" \
    "${2:-./}"
}

function terminator::vim::open::git_diff() {
  local found_ref=0 \
    ref \
    refs=("$@") \
    default_refs=(
      'HEAD'
      'HEAD^!'
    )

  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    terminator::log::error "Not in git repo!"
    return 1
  fi

  if (( ${#refs[@]} > 0 )); then
    terminator::log::debug "Using refs specified: [${refs[*]}]"
  else
    terminator::log::debug "No refs specified - Using defaults: [${default_refs[*]}]"
    refs=("${default_refs[@]}")
  fi

  for ref in "${refs[@]}"; do
    terminator::log::debug "Trying to find git diff with ref: ${ref}"

    if ! command git diff --name-only --exit-code "${ref}" > /dev/null 2>&1; then
      terminator::log::debug "Found git diff with ref: ${ref}"

      found_ref=1

      # using subshell to invoke exported wrapper function - see shellcheck SC2033.
      # vim expects tty to be attached and will not work without.
      # ${FUNCNAME[0]} is a placeholder for the $0 var and without we'd lose the first file passed to vim.
      command git diff --name-only -z "${ref}" \
        | xargs -0 bash -c 'terminator::vim::invoke -p "$@" < /dev/tty' "${FUNCNAME[0]}"

      break
    fi
  done

  if (( found_ref == 0 )); then
    terminator::log::error "No possible git diff refs found: [${refs[*]}]"
    return 1
  fi
}
