#!/bin/bash
# shellcheck source=/dev/null
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/__module__.sh"
source "${TERMINATOR_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/logger.sh"

terminator::__module__::load || return 0

function terminator::tmux::logger::path {
  # TODO make pid match session
  # ex: TMUX=/private/tmp/tmux-501/default,66097,0
  echo "/tmp/tmux-session.$$.log"
}

function terminator::tmux::logger::debug {
  local caller_level=4
  terminator::tmux::logger::file::debug -c "${caller_level}" "$@"
  terminator::tmux::logger::console::debug -c "${caller_level}" "$@"
}

function terminator::tmux::logger::info {
  local caller_level=4
  terminator::tmux::logger::file::info -c "${caller_level}" "$@"
  terminator::tmux::logger::console::info -c "${caller_level}" "$@"
}

function terminator::tmux::logger::warning {
  local caller_level=4
  terminator::tmux::logger::file::warning -c "${caller_level}" "$@"
  terminator::tmux::logger::console::warning -c "${caller_level}" "$@"
}

function terminator::tmux::logger::error {
  local caller_level=4
  terminator::tmux::logger::file::error -c "${caller_level}" "$@"
  terminator::tmux::logger::console::error -c "${caller_level}" "$@"
}

function terminator::tmux::logger::fatal {
  local caller_level=4
  terminator::tmux::logger::file::fatal -c "${caller_level}" "$@"
  terminator::tmux::logger::console::fatal -c "${caller_level}" "$@"
}

function terminator::tmux::logger::console::debug {
  # TODO make caller_level work for direct calls
  terminator::tmux::logger::wrapper \
    terminator::logger::debug "$@"
}

function terminator::tmux::logger::console::info {
  terminator::tmux::logger::wrapper \
    terminator::logger::info "$@"
}

function terminator::tmux::logger::console::warning {
  terminator::tmux::logger::wrapper \
    terminator::logger::warning "$@"
}

function terminator::tmux::logger::console::error {
  terminator::tmux::logger::wrapper \
    terminator::logger::error "$@"
}

function terminator::tmux::logger::console::fatal {
  terminator::tmux::logger::wrapper \
    terminator::logger::fatal "$@"
}

function terminator::tmux::logger::file::debug {
  terminator::tmux::logger::wrapper \
    terminator::logger::debug -o "$(terminator::tmux::logger::path)" "$@"
}

function terminator::tmux::logger::file::info {
  terminator::tmux::logger::wrapper \
    terminator::logger::info -o "$(terminator::tmux::logger::path)" "$@"
}

function terminator::tmux::logger::file::warning {
  terminator::tmux::logger::wrapper \
    terminator::logger::warning -o "$(terminator::tmux::logger::path)" "$@"
}

function terminator::tmux::logger::file::error {
  terminator::tmux::logger::wrapper \
    terminator::logger::error -o "$(terminator::tmux::logger::path)" "$@"
}

function terminator::tmux::logger::file::fatal {
  terminator::tmux::logger::wrapper \
    terminator::logger::fatal -o "$(terminator::tmux::logger::path)" "$@"
}

function terminator::tmux::logger::wrapper {
  if (( $# < 1 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]}: invalid number of arguments"
    >&2 echo "usage: ${FUNCNAME[0]}: log_command log_arguments"
    return 1
  fi

  declare callback="$1"
  terminator::logger::silence::set_variable 'TMUX_LOG_SILENCE'
  terminator::logger::level::set_variable 'TMUX_LOG_LEVEL'
  "${callback}" "${@:2}"
  terminator::logger::level::unset_variable
  terminator::logger::silence::unset_variable
}

function terminator::tmux::logger::__export__ {
  export -f terminator::tmux::logger::path
  export -f terminator::tmux::logger::debug
  export -f terminator::tmux::logger::info
  export -f terminator::tmux::logger::warning
  export -f terminator::tmux::logger::error
  export -f terminator::tmux::logger::fatal
  export -f terminator::tmux::logger::console::debug
  export -f terminator::tmux::logger::console::info
  export -f terminator::tmux::logger::console::warning
  export -f terminator::tmux::logger::console::error
  export -f terminator::tmux::logger::console::fatal
  export -f terminator::tmux::logger::file::debug
  export -f terminator::tmux::logger::file::info
  export -f terminator::tmux::logger::file::warning
  export -f terminator::tmux::logger::file::error
  export -f terminator::tmux::logger::file::fatal
  export -f terminator::tmux::logger::wrapper
}

function terminator::tmux::logger::__recall__ {
  export -fn terminator::tmux::logger::path
  export -fn terminator::tmux::logger::debug
  export -fn terminator::tmux::logger::info
  export -fn terminator::tmux::logger::warning
  export -fn terminator::tmux::logger::error
  export -fn terminator::tmux::logger::fatal
  export -fn terminator::tmux::logger::console::debug
  export -fn terminator::tmux::logger::console::info
  export -fn terminator::tmux::logger::console::warning
  export -fn terminator::tmux::logger::console::error
  export -fn terminator::tmux::logger::console::fatal
  export -fn terminator::tmux::logger::file::debug
  export -fn terminator::tmux::logger::file::info
  export -fn terminator::tmux::logger::file::warning
  export -fn terminator::tmux::logger::file::error
  export -fn terminator::tmux::logger::file::fatal
  export -fn terminator::tmux::logger::wrapper
}

terminator::__module__::export
