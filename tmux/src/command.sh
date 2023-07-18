#!/bin/bash

function tmux::command::invoke() {
  local deinitialize_called=0

  if (( $# == 0 )) && [[ -z "${TMUX_PATH_INITIALIZED}" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.tmux/bin/session-create"

    # We need to remove exported log functions otherwise tmux will not be happy.
    terminator::log::__deinitialize__
    deinitialize_called=1
  fi

  command tmux "$@"
  local exit_status=$?

  if (( deinitialize_called == 1 )); then
    # Re-init removed exported log functions.
    terminator::log::__initialize__
  fi

  return "${exit_status}"
}
