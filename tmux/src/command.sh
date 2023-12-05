#!/bin/bash

function tmux::command::invoke() {
  local recalled=0

  if (( $# == 0 )) && [[ -z "${TMUX_PATH_INITIALIZED}" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.tmux/bin/session-create"

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
