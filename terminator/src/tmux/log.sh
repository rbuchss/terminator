#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*/*}/log.sh"

terminator::__module__::load || return 0

function terminator::tmux::log::path() {
  # TODO make pid match session
  # ex: TMUX=/private/tmp/tmux-501/default,66097,0
  echo "/tmp/tmux-session.$$.log"
}

function terminator::tmux::log::debug() {
  local caller_level=4
  terminator::tmux::log::file::debug -c "${caller_level}" "$@"
  terminator::tmux::log::console::debug -c "${caller_level}" "$@"
}

function terminator::tmux::log::info() {
  local caller_level=4
  terminator::tmux::log::file::info -c "${caller_level}" "$@"
  terminator::tmux::log::console::info -c "${caller_level}" "$@"
}

function terminator::tmux::log::warning() {
  local caller_level=4
  terminator::tmux::log::file::warning -c "${caller_level}" "$@"
  terminator::tmux::log::console::warning -c "${caller_level}" "$@"
}

function terminator::tmux::log::error() {
  local caller_level=4
  terminator::tmux::log::file::error -c "${caller_level}" "$@"
  terminator::tmux::log::console::error -c "${caller_level}" "$@"
}

function terminator::tmux::log::console::debug() {
  # TODO make caller_level work for direct calls
  terminator::tmux::log::wrapper \
    terminator::log::debug "$@"
}

function terminator::tmux::log::console::info() {
  terminator::tmux::log::wrapper \
    terminator::log::info "$@"
}

function terminator::tmux::log::console::warning() {
  terminator::tmux::log::wrapper \
    terminator::log::warning "$@"
}

function terminator::tmux::log::console::error() {
  terminator::tmux::log::wrapper \
    terminator::log::error "$@"
}

function terminator::tmux::log::file::debug() {
  terminator::tmux::log::wrapper \
    terminator::log::debug -o "$(terminator::tmux::log::path)" "$@"
}

function terminator::tmux::log::file::info() {
  terminator::tmux::log::wrapper \
    terminator::log::info -o "$(terminator::tmux::log::path)" "$@"
}

function terminator::tmux::log::file::warning() {
  terminator::tmux::log::wrapper \
    terminator::log::warning -o "$(terminator::tmux::log::path)" "$@"
}

function terminator::tmux::log::file::error() {
  terminator::tmux::log::wrapper \
    terminator::log::error -o "$(terminator::tmux::log::path)" "$@"
}

function terminator::tmux::log::wrapper() {
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

function terminator::tmux::log::__export__() {
  export -f terminator::tmux::log::path
  export -f terminator::tmux::log::debug
  export -f terminator::tmux::log::info
  export -f terminator::tmux::log::warning
  export -f terminator::tmux::log::error
  export -f terminator::tmux::log::console::debug
  export -f terminator::tmux::log::console::info
  export -f terminator::tmux::log::console::warning
  export -f terminator::tmux::log::console::error
  export -f terminator::tmux::log::file::debug
  export -f terminator::tmux::log::file::info
  export -f terminator::tmux::log::file::warning
  export -f terminator::tmux::log::file::error
  export -f terminator::tmux::log::wrapper
}

function terminator::tmux::log::__recall__() {
  export -fn terminator::tmux::log::path
  export -fn terminator::tmux::log::debug
  export -fn terminator::tmux::log::info
  export -fn terminator::tmux::log::warning
  export -fn terminator::tmux::log::error
  export -fn terminator::tmux::log::console::debug
  export -fn terminator::tmux::log::console::info
  export -fn terminator::tmux::log::console::warning
  export -fn terminator::tmux::log::console::error
  export -fn terminator::tmux::log::file::debug
  export -fn terminator::tmux::log::file::info
  export -fn terminator::tmux::log::file::warning
  export -fn terminator::tmux::log::file::error
  export -fn terminator::tmux::log::wrapper
}

terminator::__module__::export
