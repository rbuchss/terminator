#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/__module__.sh"
source "${BASH_SOURCE[0]%/*}/command.sh"

terminator::__module__::load || return 0

function terminator::tmux::__enable__ {
  terminator::command::exists -v tmux || return

  alias tmux='terminator::tmux::invoke'
}

function terminator::tmux::__disable__ {
  unset TMUX_CONFIG_PATH

  unalias tmux
}

function terminator::tmux::invoke {
  local recalled=0

  if (( $# == 0 )) && [[ -z "${TMUX_PATH_INITIALIZED}" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.terminator/bin/tmux-session-create"

    # We need to remove exported log functions otherwise tmux will not be happy.
    terminator::__module__::recall terminator::log
    recalled=1
  fi

  command tmux "$@"
  local exit_status=$?

  if (( recalled == 1 )); then
    # Re-init removed exported log functions.
    terminator::__module__::export terminator::log
  fi

  return "${exit_status}"
}

function terminator::tmux::__export__ {
  export -f terminator::tmux::invoke
}

function terminator::tmux::__recall__ {
  export -fn terminator::tmux::invoke
}

terminator::__module__::export
