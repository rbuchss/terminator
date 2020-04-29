#!/bin/bash

function tmux::command::invoke() {
  if (( $# == 0 )) && [[ -z "${TMUX_PATH_INITIALIZED}" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.tmux/bin/session-create"
  fi
  command tmux "$@"
}
