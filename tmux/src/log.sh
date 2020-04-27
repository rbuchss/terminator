#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.terminator/src/log.sh"

function tmux::log::path() {
  # TODO make pid match session
  # ex: TMUX=/private/tmp/tmux-501/default,66097,0
  echo "/tmp/tmux-session.$$.log"
}

function tmux::log::debug() {
  local caller_level=4
  tmux::log::file::debug -c "${caller_level}" "$@"
  tmux::log::console::debug -c "${caller_level}" "$@"
}

function tmux::log::info() {
  local caller_level=4
  tmux::log::file::info -c "${caller_level}" "$@"
  tmux::log::console::info -c "${caller_level}" "$@"
}

function tmux::log::warning() {
  local caller_level=4
  tmux::log::file::warning -c "${caller_level}" "$@"
  tmux::log::console::warning -c "${caller_level}" "$@"
}

function tmux::log::error() {
  local caller_level=4
  tmux::log::file::error -c "${caller_level}" "$@"
  tmux::log::console::error -c "${caller_level}" "$@"
}

function tmux::log::console::debug() {
  # TODO make caller_level work for direct calls
  tmux::log::wrapper \
    terminator::log::debug "$@"
}

function tmux::log::console::info() {
  tmux::log::wrapper \
    terminator::log::info "$@"
}

function tmux::log::console::warning() {
  tmux::log::wrapper \
    terminator::log::warning "$@"
}

function tmux::log::console::error() {
  tmux::log::wrapper \
    terminator::log::error "$@"
}

function tmux::log::file::debug() {
  tmux::log::wrapper \
    terminator::log::debug -o "$(tmux::log::path)" "$@"
}

function tmux::log::file::info() {
  tmux::log::wrapper \
    terminator::log::info -o "$(tmux::log::path)" "$@"
}

function tmux::log::file::warning() {
  tmux::log::wrapper \
    terminator::log::warning -o "$(tmux::log::path)" "$@"
}

function tmux::log::file::error() {
  tmux::log::wrapper \
    terminator::log::error -o "$(tmux::log::path)" "$@"
}

function tmux::log::wrapper() {
  if (( $# < 1 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]}: invalid number of arguments"
    >&2 echo "usage: ${FUNCNAME[0]}: log_command log_arguments"
    return 1
  fi

  declare callback="$1"
  terminator::log::silence::set_variable 'TMUX_LOG_SILENCE'
  terminator::log::level::set_variable 'TMUX_LOG_LEVEL'
  "${callback}" "${@:2}"
  terminator::log::level::unset_variable
  terminator::log::silence::unset_variable
}
