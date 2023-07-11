#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__pragma__.sh"

terminator::__pragma__::once || return 0

function terminator::help() {
  if ! command -v "$1" > /dev/null 2>&1; then
    >&2 echo "ERROR: ${FUNCNAME[0]}: command '$1' not found"
    return 1
  fi

  # terminator::help::command::info "$@" \
  terminator::help::command::man "$@" \
    || terminator::help::command::bash_help "$@" \
    || terminator::help::command::help_flag "$@" \
    || {
      >&2 echo "ERROR: ${FUNCNAME[0]}: help for '$1' command not found"
      return 1
    }
}

function terminator::help::command::info() {
  if info --where "$@" > /dev/null 2>&1; then
    info "$@"
    return
  fi

  return 1
}

function terminator::help::command::man() {
  local location
  if location="$(man -w "$@" 2>&1)"; then
    [[ "${location}" =~ \/builtin ]] && return 1
    man "$@"
    return
  fi

  return 1
}

function terminator::help::command::bash_help() {
  help "$@" 2>/dev/null
}

function terminator::help::command::help_flag() {
  local cmd="$1"

  if (( $# > 1 )); then
    local subcommands=("${@:2}")
    command "${cmd}" "${subcommands[@]}" --help
    return
  fi

  command "${cmd}" --help
}

function terminator::help::command::help_subcommand() {
  local cmd="$1"

  if (( $# > 1 )); then
    local subcommands=("${@:2:$#-2}")
    local subcommand="${*:$#}"
    command "${cmd}" "${subcommands[@]}" help "${subcommand}"
    return
  fi

  command "${cmd}" help
}

function terminator::help::paged() {
  terminator::help "$@" | less -R
}
